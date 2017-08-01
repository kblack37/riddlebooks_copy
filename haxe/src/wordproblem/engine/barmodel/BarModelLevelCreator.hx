package wordproblem.engine.barmodel;

//import wordproblem.engine.barmodel.BarmodelLevelTemplate;
import dragonbox.common.util.PMPRNG;
import haxe.xml.Fast;

import flash.text.TextFormat;

import dragonbox.common.util.PMPRNG;
import dragonbox.common.util.TextToNumber;
import dragonbox.common.util.XColor;
import dragonbox.common.util.XString;

import haxe.Constraints.Function;

import wordproblem.engine.text.MeasuringTextField;
import wordproblem.hints.CustomHintGenerator;
import wordproblem.log.GameServerRequester;

/**
 * The application normally reads in a xml file to play a level.
 * However, it may not always be the case that we will have a pre-fabricated xml level
 * file ready at any given time but do have the raw data representing the most important
 * parts of the level. This situation is applicable for user created problems, which need
 * to be saved in a database. We do not want the server to have to recreate an xml file
 * every time an application requests a level.
 * 
 * This class is so the client application can convert stored data about a problem into
 * a usuable xml formatted level.
 */
class BarModelLevelCreator
{
    @:meta(Embed(source="barmodel_level_template.xml",mimeType="application/octet-stream"))

    public static var barmodel_level_template : Class<Dynamic>;
    
    private var m_gameServerRequester : GameServerRequester;
    
    /**
     * A call to fetch a problem remotely will most likely take several frames, need to remember
     * the callback that gets triggered after the request has finished.
     */
    private var m_loadCompleteCallback : Function;
    private var m_lastLevelIdRequested : Int;
    
    private var m_backgroundToStyle : BarModelBackgroundToStyle;
    
    /**
     * Key: problem/level id
     * Value: Array of hint data objects
     */
    private var m_customHintJsonData : Dynamic;
    
    /**
     * @param customHintJsonData
     *      This is simply an array of hint objects that looks like
     * {
     *   "hint":"There are two groups here, what are they and how many are there total?",
     *   "bar":null,
     *   "id":510,
     *   "step":1,
     *   "model":"1a"
     * }
     */
    public function new(gameServerRequester : GameServerRequester, customHintJsonData : Dynamic = null)
    {
        m_gameServerRequester = gameServerRequester;
        m_backgroundToStyle = new BarModelBackgroundToStyle();
        
        // Preprocess the hinting information so that it is keyed
        m_customHintJsonData = { };
        if (customHintJsonData != null) 
        {
            var hintsList : Array<Dynamic> = customHintJsonData.hints;
            var numHints : Int = hintsList.length;
            var i : Int = 0;
            for (i in 0...numHints){
                var hintData : Dynamic = hintsList[i];
                var problemId : Int = hintData.id;
                if (!m_customHintJsonData.exists(problemId)) 
                {
                    m_customHintJsonData[problemId] = [];
                }
                
                var listForId : Array<Dynamic> = m_customHintJsonData[problemId];
                listForId.push(hintData);
            }
        }
    }
    
    /**
     * Load a bar model level
     * 
     * @param levelId
     *      This is the quest id unique to any given problem.
     * @param onLoadComplete
     *      Callback triggered once the request has been satisfied
     *      signature callback(problemXml:XML):void
     */
    public function loadLevelFromId(levelId : Int,
            onLoadComplete : Function,
            customHintGenerator : CustomHintGenerator = null) : Void
    {
        m_lastLevelIdRequested = levelId;
        m_loadCompleteCallback = onLoadComplete;
        
        m_gameServerRequester.getLevelDataFromId(levelId + "", function onProblemDataRequestComplete(success : Bool, data : Dynamic) : Void
                {
                    if (success) 
                    {
                        if (m_loadCompleteCallback != null) 
                        {
                            var barModelType : String = data.bar_model_type;
                            var backgroundId : String = data.background_id;
                            var problemContext : String = data.context;
                            var problemText : String = data.problem_text;
                            
                            var rawDetails : String = data.additional_details;
                            var additionalDetails : Dynamic = ((rawDetails != null && rawDetails != "")) ? haxe.Json.parse(data.additional_details) : null;
                            m_loadCompleteCallback(generateLevelFromData(m_lastLevelIdRequested,
                                            barModelType, problemContext, problemText, backgroundId, additionalDetails, customHintGenerator));
                        }
                    }
                    
                    m_lastLevelIdRequested = -1;
                    m_loadCompleteCallback = null;
                });
    }
    
    /**
     *
     * @return
     *      The xml object representing
     */
    public function generateLevelFromData(levelId : Int,
            barModelType : String,
            problemContext : String,
            problemText : String,
            backgroundId : String,
            additionalDetails : Dynamic,
            customHintGenerator : CustomHintGenerator = null) : Xml
    {
        // Have a default background style
        if (backgroundId == null) 
        {
            backgroundId = "general_a";
        }
        
        var levelTemplateXml : Xml = Xml.parse(Type.createInstance(barmodel_level_template, []));
        levelTemplateXml.set("id", Std.string(levelId));
        levelTemplateXml.set("barModelType", barModelType);
        levelTemplateXml.set("name", "Bar model " + levelId);
        
        var problemTextXml : Xml = Xml.parse("<p>" + problemText + "</p>");
        
        var documentIdToExpressionNameMap : Dynamic = { };
        var documentIdToExpressionNumericValue : Dynamic = { };
        var taggedElements : Array<Xml> = new Array<Xml>();
        _getTaggedElements(problemTextXml, taggedElements);
        for (taggedElement in taggedElements)
        {
            // First rewrite the problem to take care of fraction, iterate through every relevant span
            convertFractionToTwoNumbers(taggedElement);
        }
		
		// Attach the problem text.  
		var problemTextRoot : Xml = (new Fast(levelTemplateXml)).nodes.wordproblem.first().node.page.node.div.x;
        problemTextRoot.addChild(problemTextXml);
        
        // We assume the document ids in the text have a specific role in how they fit in the
        // given bar model type. Using this information, we can determine what values compose
        // both the reference bar model and the reference equation model
		taggedElements = new Array<Xml>();
        _getTaggedElements(problemTextXml, taggedElements);
        
        // Collect all the information about an alias that is used to later create special card
        // properties for that element
        var tagIdToAliasMap : Dynamic = { };
        for (taggedElement in taggedElements)
        {
			var fastTaggedElement = new Fast(taggedElement);
            if (fastTaggedElement.has.alias && fastTaggedElement.has.id) 
            {
                var taggedId = fastTaggedElement.att.id;
                var aliasValue = fastTaggedElement.att.alias;
                
                if (additionalDetails != null && additionalDetails.exists("symbol_data")) 
                {
                    var symbols : Array<Dynamic> = Reflect.field(additionalDetails, "symbol_data");
                    for (symbolData in symbols)
                    {
                        if (symbolData.value == aliasValue) 
                        {
							Reflect.setField(tagIdToAliasMap, taggedId, symbolData);
                            break;
                        }
                    }
                }  // Alias has no extra data, so set up the default values  
                
                
                
                if (!tagIdToAliasMap.exists(taggedId)) 
                {
					Reflect.setField(tagIdToAliasMap, taggedId, { value : aliasValue });
                }
            }
        }  // Figure out the backing values each tagged element represents  
        
        
        
        var textToNumber : TextToNumber = new TextToNumber();
        for (taggedElement in taggedElements)
        {
			var fastTaggedElement = new Fast(taggedElement);
            var taggedId : String = fastTaggedElement.att.id;
            
            // Note that multiple elements might point to the same tag id, for example text
            // representing the unknown appears in two separate phrases. Avoid doing any duplicate
            // logic.
            if (!documentIdToExpressionNameMap.exists(taggedId)) 
            {
                var taggedValueUnmodified : String = Std.string(taggedElement);
                
                // The tagged value can either be a string if it is an unknown or
                // a variable OR it can be a numeric value.
                // The document ids that bind to the first case are always assumed to
                // be 'unk' or 'c'
                
                // An alias means we use a different value, do not use the raw text
                var aliasValue : String = null;
                if (tagIdToAliasMap.exists(taggedId)) 
                {
                    aliasValue = Reflect.field(tagIdToAliasMap, taggedId).value;
                    taggedValueUnmodified = aliasValue;
                }				
				
				// Tagged elements are supposed to either indicate numbers or  
				// unknowns that are just words.
				// We use the assumption that tagged elements with ids that
				// begin with 'a' or 'b' should always be numbers
                // Everything else is a word.
                if (taggedId.charAt(0) == "a" || taggedId.charAt(0) == "b") 
                {
                    var numberFromText : Float = textToNumber.textToNumber(taggedValueUnmodified);
                    Reflect.setField(documentIdToExpressionNameMap, taggedId, numberFromText);
                    
                    // Numbers do not need an alias in the tag
                    if (additionalDetails != null && additionalDetails.exists("symbol_data")) 
                    {
                        var symbols = try cast(Reflect.field(additionalDetails, "symbol_data"), Array<Dynamic>) catch (e : Dynamic) null;
                        for (symbolData in symbols)
                        {
                            if (symbolData.value == Std.string(numberFromText)) 
                            {
                                var symbolElement : Xml = Xml.parse("<symbol/>");
                                symbolElement.set("name", symbolData.exists("name") ? 
									symbolData.name : Std.string(numberFromText));
								// Zoran wanted to remove the words from the tiles
                                //symbolElement.@abbreviatedName = (symbolData.hasOwnProperty("abbreviated")) ?
                                //    symbolData.abbreviated : numberFromText;
                                symbolElement.set("value", Std.string(numberFromText));
                                symbolElement.set("backgroundTexturePositive", "card_background_square");
								levelTemplateXml.elementsNamed("symbols").next().addChild(symbolElement);
                                break;
                            }
                        }
                    }
                }
                else 
                {
                    // Strip out spaces for variable names, the expression compiler cannot detect that
                    // tokens with spaces should be a single part.
                    var taggedValueNoSpaces : String = StringTools.replace(taggedValueUnmodified, " ", "_");
                    
                    // Remove any special characters that might mess up the expression compiler,
                    // this includes anything that can be confused as an operator, parenthesis, '?', and '='
					taggedValueNoSpaces = (new EReg('[\\?\\+=\\-\\*\\(\\)]', "g")).replace(taggedValueNoSpaces, "");
                    var symbolElement = Xml.parse("<symbol/>");
                    symbolElement.set("name", ((aliasValue != null && Reflect.field(tagIdToAliasMap, taggedId).exists("name"))) ? 
						Reflect.field(tagIdToAliasMap, taggedId).name : taggedValueUnmodified);
                    symbolElement.set("abbreviatedName", ((aliasValue != null && Reflect.field(tagIdToAliasMap, taggedId).exists("abbreviated"))) ? 
						Reflect.field(tagIdToAliasMap, taggedId).abbreviated : taggedValueUnmodified);
                    symbolElement.set("value", taggedValueNoSpaces);
                    symbolElement.set("backgroundTexturePositive", "card_background_square");
                    levelTemplateXml.elementsNamed("symbols").next().addChild(symbolElement);
                    
                    Reflect.setField(documentIdToExpressionNameMap, taggedId, taggedValueNoSpaces);
                }
            }
        }
        
        var smallestNumericValue : Float = Math.pow(2, 30);
        var defaultNormalizingFactor : Int = 1;
        
        // Used to assign unique bar model colors to each terms. Across all plays of this level, the
        // color of the boxes in the bar model should be consistent, for example '3' is always a blue box.
        var uniqueTermValues : Array<Dynamic> = [];
        
        // Attach the mapping from ids in the text to actual expression values
		var codeRoot : Xml = (new Fast(levelTemplateXml)).nodes.script.first().node.scriptedActions.node.code.x;
        for (documentId in Reflect.fields(documentIdToExpressionNameMap))
        {
            var documentToTermElement : Xml = Xml.parse("<documentToCard />");
            documentToTermElement.set("documentId", documentId);
            documentToTermElement.set("value", Reflect.field(documentIdToExpressionNameMap, documentId));
            codeRoot.addChild(documentToTermElement);
            
            // The reference models require having relative numerical proportions for bar segments.
            // For example, we need to know before hand how much larger the unknown should be than
            // the parts represented by numbers so we know how big to make the default box for
            // that unknown
            var numericValueForDocument : Float = Std.parseFloat(Reflect.field(documentIdToExpressionNameMap, documentId));
            if (!Math.isNaN(numericValueForDocument)) 
            {
                // Values that are not numbers need to be calculated based on the bar model type
                Reflect.setField(documentIdToExpressionNumericValue, documentId, numericValueForDocument);
            }
            
            if (documentId.charAt(0) == "a" || documentId.charAt(0) == "b") 
            {
                smallestNumericValue = Math.min(numericValueForDocument, smallestNumericValue);
            }  // unique color is assigned to it.    // For each unique term value, make sure a <symbol> tag is created for it and that a  
            
            
            
            
            
            var termValue : String = documentToTermElement.get("value");
            if (Lambda.indexOf(uniqueTermValues, termValue) < 0) 
            {
                uniqueTermValues.push(termValue);
            }
        }
        
		uniqueTermValues.sort(
			function(a, b) {
				if (a.termValue < b.termValue) return -1;
				else if (a.termValue > b.termValue) return 1;
				else return 0;
			}
		);
        var sortedUniqueTermValues : Array<Dynamic> = [];
		sortedUniqueTermValues.concat(uniqueTermValues);
		
        var colorPicker : PMPRNG = new PMPRNG(levelId);
        var barColors : Array<Int> = XColor.getCandidateColorsForSession();
        for (termValue in sortedUniqueTermValues)
        {
            var symbolsBlock : Xml = levelTemplateXml.elementsNamed("symbols").next();
            var matchingSymbolElement : Xml = null;
            for (symbolElement in symbolsBlock.elements())
            {
                if (symbolElement.get("value") == termValue) 
                {
                    matchingSymbolElement = symbolElement;
                    break;
                }
            }
			
			// If could not find matching element, create a new one for that term  
            if (matchingSymbolElement == null) 
            {
                matchingSymbolElement = Xml.parse("<symbol/>");
                matchingSymbolElement.set("value", termValue);
                symbolsBlock.addChild(matchingSymbolElement);
            }
			
			// To make sure colors look distinct, we pick from a list of predefined list and avoid duplicates  
            if (barColors.length > 0) 
            {
                var colorIndex : Int = colorPicker.nextIntRange(0, barColors.length - 1);
                matchingSymbolElement.set("customBarColor", "0x" + Std.string(barColors[colorIndex]).toUpperCase());
                barColors.splice(colorIndex, 1);
            }
            else 
            {
                // In the unlikely case we have too many terms that use up all the colors, we just randomly
                // pick one from a palette.
                matchingSymbolElement.set("customBarColor", "0x" + Std.string(XColor.getDistributedHsvColor(colorPicker.nextDouble())).toUpperCase());
            }
            matchingSymbolElement.set("useCustomBarColor", "true");
        }
        
        codeRoot.addChild(createBasicSubelementWithValue("barNormalizingFactor", Std.string(smallestNumericValue)));
        
        function addNumericValueForUnknown(unknownDocId : String) : Void
        {
            var termValueToBarValue : Xml = Xml.parse("<termValueToBarValue/>");
            termValueToBarValue.set("termValue", Reflect.field(documentIdToExpressionNameMap, unknownDocId));
            termValueToBarValue.set("barValue", Reflect.field(documentIdToExpressionNumericValue, unknownDocId));
            codeRoot.addChild(termValueToBarValue);
        }; 
		
		// Level rules defining allowable actions in the level
        var allowAddNewSegments : Bool = true;
        var allowAddUnitBar : Bool = true;
        var allowSplitBar : Bool = true;
        var allowCopyBar : Bool = true;
        var allowCreateCard : Bool = false;
        var allowSubtract : Bool = true;
        var allowMultiply : Bool = true;
        var allowDivide : Bool = true;
        var allowResizeBrackets : Bool = false;
        var allowParenthesis : Bool = false;
        
        // Each bar model type will have its own unique set of reference models, equations, rules
        // Set those properties here.
        if (barModelType == BarModelTypes.TYPE_0A) 
        {
            allowAddNewSegments = false;
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowSubtract = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", null, "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
            
            var referenceEquation = Xml.parse("<equation/>");
			// TODO: not sure if this is a correct conversion (did Reflect.setField or what it was
			// converted from used to return the new/old value?)
            //referenceEquation.set("value", Reflect.setField(documentIdToExpressionNameMap, "unk", "="));
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_1A) 
        {
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowSubtract = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", calculateSum("a", "b", documentIdToExpressionNumericValue));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
            
            // Travis' experiement requires explicitly having a separate model using two rows
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, true));
            
            var referenceEquation : Xml = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateSumEquation(documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_1B) 
        {
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", calculateDifference("b", "a", documentIdToExpressionNumericValue));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("b", "a", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // Allow a1 to be a difference if it is made up of just one part
            var numTermsWithSmallerPrefix : Int = 0;
            for (docId in Reflect.fields(documentIdToExpressionNumericValue))
            {
                if (docId.charAt(0) == "a") 
                {
                    numTermsWithSmallerPrefix++;
                }
            }
            
            if (numTermsWithSmallerPrefix == 1) 
            {
                codeRoot.addChild(getSumAndDifferenceReferenceModel("b", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_2A) 
        {
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", calculateDifference("b", "a", documentIdToExpressionNumericValue));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("b", "a", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // Allow a1 to be a difference if it is made up of just one part
            var numTermsWithSmallerPrefix = 0;
            for (docId in Reflect.fields(documentIdToExpressionNumericValue))
            {
                if (docId.charAt(0) == "a") 
                {
                    numTermsWithSmallerPrefix++;
                }
            }
            
            if (numTermsWithSmallerPrefix == 1) 
            {
                codeRoot.addChild(getSumAndDifferenceReferenceModel("b", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }  // Just make sure there are not multiple parts with the same prefix    // Allow for subtraction to be solved with addition as long as the larger part of the difference is represented by just one term  
            
            
            
            
            
            var numTermsWithLargerPrefix : Int = 0;
            for (docId in Reflect.fields(documentIdToExpressionNumericValue))
            {
                if (docId.charAt(0) == "b") 
                {
                    numTermsWithLargerPrefix++;
                }
            }
            
            if (numTermsWithLargerPrefix == 1) 
            {
                codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_2B) 
        {
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", calculateSum("a", "b", documentIdToExpressionNumericValue));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, true));
            
            // Travis' experiement requires explicitly having a separate model using two rows
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateSumEquation(documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_2C) 
        {
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", calculateDifference("b", "a", documentIdToExpressionNumericValue));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("b", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            codeRoot.addChild(getSumAndDifferenceReferenceModel("b", "a1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            var numTermsWithLargerPrefix = 0;
            for (docId in Reflect.fields(documentIdToExpressionNumericValue))
            {
                if (docId.charAt(0) == "b") 
                {
                    numTermsWithLargerPrefix++;
                }
            }
            
            if (numTermsWithLargerPrefix == 1) 
            {
                codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_2D) 
        {
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", calculateSum("b", "a", documentIdToExpressionNumericValue));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("unk", "a", null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // Allow a1 to be a difference if it is made up of just one part
            var numTermsWithSmallerPrefix = 0;
            for (docId in Reflect.fields(documentIdToExpressionNumericValue))
            {
                if (docId.charAt(0) == "a") 
                {
                    numTermsWithSmallerPrefix++;
                }
            }
            
            if (numTermsWithSmallerPrefix == 1) 
            {
                codeRoot.addChild(getSumAndDifferenceReferenceModel("unk", "b", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateSumEquation(documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_2E) 
        {
            allowAddUnitBar = false;
            allowSplitBar = false;
            allowCopyBar = false;
            allowMultiply = false;
            allowDivide = false;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", calculateDifference("b", "a", documentIdToExpressionNumericValue));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("b", "a", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // Allow a1 to be a difference if it is made up of just one part
            var numTermsWithSmallerPrefix = 0;
            for (docId in Reflect.fields(documentIdToExpressionNumericValue))
            {
                if (docId.charAt(0) == "a") 
                {
                    numTermsWithSmallerPrefix++;
                }
            }
            
            if (numTermsWithSmallerPrefix == 1) 
            {
                codeRoot.addChild(getSumAndDifferenceReferenceModel("b1", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_3A) 
        {
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") * Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSimpleMultiplicationReferenceModel("b1", "a1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // Only allow reverse if the numbers are small enough
            if (Reflect.field(documentIdToExpressionNumericValue, "a1") <= 30) 
            {
                codeRoot.addChild(getSimpleMultiplicationReferenceModel("a1", "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateMultiplicationEquation("b1", "a1", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_3B) 
        {
            var dividend : Int = Reflect.field(documentIdToExpressionNumericValue, "b1");
            var divisor : Int = Reflect.field(documentIdToExpressionNumericValue, "a1");
            Reflect.setField(documentIdToExpressionNumericValue, "unk", dividend / divisor);
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getSimpleMultiplicationReferenceModel("a1", "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateDivisionEquation("b1", "a1", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_4A) 
        {
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") * Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "a1", "unk", null, null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            codeRoot.addChild(getSimpleMultiplicationReferenceModel("b1", "a1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // Only allow reverse if the numbers are small enough
            if (Reflect.field(documentIdToExpressionNumericValue, "a1") <= 30) 
            {
                codeRoot.addChild(getSimpleMultiplicationReferenceModel("a1", "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateMultiplicationEquation("b1", "a1", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_4B) 
        {
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") / Reflect.field(documentIdToExpressionNumericValue, "b1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "unk", "a1", null, null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            if (Reflect.field(documentIdToExpressionNumericValue, "b1") <= 30) 
            {
                codeRoot.addChild(getSimpleMultiplicationReferenceModel("b1", "unk", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            }
            
            var referenceEquation = Xml.parse("<equation/>");
            referenceEquation.set("value", calculateDivisionEquation("a1", "b1", documentIdToExpressionNameMap));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_4C) 
        {
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") * Reflect.field(documentIdToExpressionNumericValue, "a1") - Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "a1", null, null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_4D) 
        {
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") * Reflect.field(documentIdToExpressionNumericValue, "a1") + Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "a1", null, "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_4E) 
        {
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") / (Reflect.field(documentIdToExpressionNumericValue, "b1") - 1));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "unk", null, null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_4F) 
        {
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") / (Reflect.field(documentIdToExpressionNumericValue, "b1") + 1));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "unk", null, "a1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        // Need to create a set of equations for all type 5 problems, allow user to create multiple combos.
        // IMPORTANT:
        // What was initially expected for these systems of equations was for users to create two of them where each equation used
        // both unknown values as this is the simplest way to translate them.
        // However, it is possible for the person to also create just a single one or do calculations to figure out the number.
        // Example:
        // unknowns a and b
        // a = some number
        // b = some other number
        // This should be acceptable. One of these should also be accepted in combination with an equation that includes both unknonws
        else if (barModelType == BarModelTypes.TYPE_5A) 
        {
            allowParenthesis = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") + (Reflect.field(documentIdToExpressionNumericValue, "a1") - Reflect.field(documentIdToExpressionNumericValue, "b1")));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") - Reflect.field(documentIdToExpressionNumericValue, "b1"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "c", "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a+(a-b)
            // unk=a+c
            // c=a-b
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSetElement : Xml = null;
            var equationSets : Array<Xml> = createEquationCombinationPairs(["1", "2", "3"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5B) 
        {
            allowParenthesis = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") + (Reflect.field(documentIdToExpressionNumericValue, "a1") + Reflect.field(documentIdToExpressionNumericValue, "b1")));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") + Reflect.field(documentIdToExpressionNumericValue, "b1"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("c", "a", "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a+(a+b)
            // unk=a+c
            // c=a+b
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5C) 
        {
            allowParenthesis = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") - (Reflect.field(documentIdToExpressionNumericValue, "b1") - Reflect.field(documentIdToExpressionNumericValue, "a1")));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "b1") - Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("a", "c", "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a-(b-a)
            // c=b-a
            // unk=a-c
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5D) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", (Reflect.field(documentIdToExpressionNumericValue, "b1") - Reflect.field(documentIdToExpressionNumericValue, "a1")) / 2);
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") + Reflect.field(documentIdToExpressionNumericValue, "unk"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("c", "unk", "b1", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=(b-a)/2
            // unk=b-c
            // unk=c-a
            // c=a+(b-a)/2
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=(");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            var aValue : String = Reflect.field(documentIdToExpressionNameMap, "a1");
            var bValue : String = Reflect.field(documentIdToExpressionNameMap, "b1");
            referenceEquation = Xml.parse("<equation id=\"4\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5E) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", (Reflect.field(documentIdToExpressionNumericValue, "b1") + Reflect.field(documentIdToExpressionNumericValue, "a1")) / 2);
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "b1") - Reflect.field(documentIdToExpressionNumericValue, "unk"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getSumAndDifferenceReferenceModel("unk", "c", "b1", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            //unk=(b+a)/2
            //unk=c+a
            //unk=b-c
            //c=(b-a)/2
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=(");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            var aValue = Reflect.field(documentIdToExpressionNameMap, "a1");
            var bValue = Reflect.field(documentIdToExpressionNameMap, "b1");
            referenceEquation = Xml.parse("<equation id=\"4\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=(");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5F) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") - Reflect.field(documentIdToExpressionNumericValue, "a1") / Reflect.field(documentIdToExpressionNumericValue, "b1"));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") / Reflect.field(documentIdToExpressionNumericValue, "b1"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "c", "a1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a-a/b
            // unk=a-c
            // c=a/b
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5G) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") + Reflect.field(documentIdToExpressionNumericValue, "a1") / Reflect.field(documentIdToExpressionNumericValue, "b1"));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") / Reflect.field(documentIdToExpressionNumericValue, "b1"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "c", "a1", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a+a/b
            // unk=a+c
            // c=a/b
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5H) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") / (1 - 1 / Reflect.field(documentIdToExpressionNumericValue, "b1")));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "unk") / Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "c", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a/(1-1/b)
            // unk=c+a
            // unk=b*c
            // c=a/(b-1)
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            var aValue = Reflect.field(documentIdToExpressionNameMap, "a1");
            var bValue = Reflect.field(documentIdToExpressionNameMap, "b1");
            referenceEquation = Xml.parse("<equation id=\"4\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5I) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") * (Reflect.field(documentIdToExpressionNumericValue, "b1") + 1) /
            (Reflect.field(documentIdToExpressionNumericValue, "b1") - 1));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") / (Reflect.field(documentIdToExpressionNumericValue, "b1") - 1));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "c", null, "unk", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a*(b+1)/(b-1)
            // unk=c*b+c
            // c=a/(b-1)
            // unk=a+2*c
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=(");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"4\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5J) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") * Reflect.field(documentIdToExpressionNumericValue, "a1") /
            (Reflect.field(documentIdToExpressionNumericValue, "b1") + 1));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") / (Reflect.field(documentIdToExpressionNumericValue, "b1") - 1));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "c", "unk", "a1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=b*a/(b+1)
            // unk=b*c
            // c=a-unk
            // c=a/(b+1)
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var aValue = Reflect.field(documentIdToExpressionNameMap, "a1");
            var bValue = Reflect.field(documentIdToExpressionNameMap, "b1");
            referenceEquation = Xml.parse("<equation id=\"4\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_5K) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "a1") * (Reflect.field(documentIdToExpressionNumericValue, "b1") - 1) /
            (Reflect.field(documentIdToExpressionNumericValue, "b1") + 1));
            Reflect.setField(documentIdToExpressionNumericValue, "c", Reflect.field(documentIdToExpressionNumericValue, "a1") / (Reflect.field(documentIdToExpressionNumericValue, "b1") + 1));
            addNumericValueForUnknown("unk");
            addNumericValueForUnknown("c");
            codeRoot.addChild(getMultiplierReferenceModel("b1", "c", null, "a1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // unk=a*(b-1)/(b+1)
            // unk=c*(b-1)
            // c=a/(b+1)
            // unk=a-2*c
            var referenceEquation = Xml.parse("<equation id=\"1\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"2\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"3\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "c", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "c"));
            codeRoot.addChild(referenceEquation);
            
            referenceEquation = Xml.parse("<equation id=\"4\"/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
            
            var equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
            for (equationSetElement in equationSets)
            {
                codeRoot.addChild(equationSetElement);
            }
        }
        else if (barModelType == BarModelTypes.TYPE_6A) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / Reflect.field(documentIdToExpressionNumericValue, "a2") * Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionReferenceModel("a1", "a2", "unk", null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/a2*a1
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_6B) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / Reflect.field(documentIdToExpressionNumericValue, "a2") *
            (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionReferenceModel("a1", "a2", null, "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/a2*(a2-a1)
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_6C) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / Reflect.field(documentIdToExpressionNumericValue, "a1") * Reflect.field(documentIdToExpressionNumericValue, "a2"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionReferenceModel("a1", "a2", "b1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/a1*a2
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_6D) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / Reflect.field(documentIdToExpressionNumericValue, "a1") *
            (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionReferenceModel("a1", "a2", "b1", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/a1*(a2-a1)
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7A) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / Reflect.field(documentIdToExpressionNumericValue, "a1") * Reflect.field(documentIdToExpressionNumericValue, "a2"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", "unk", "b1", null, null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/a1*a2
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7B) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / Reflect.field(documentIdToExpressionNumericValue, "a1") *
            (Reflect.field(documentIdToExpressionNumericValue, "a2") + Reflect.field(documentIdToExpressionNumericValue, "a1")));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", null, "b1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            //b/a1*(a1+a2)
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7C) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / Reflect.field(documentIdToExpressionNumericValue, "a1") *
            (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", null, "b1", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/a1*(a2-a1)
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7D_1) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")) * Reflect.field(documentIdToExpressionNumericValue, "a2"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", "unk", null, null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/(a1+a2)*a2
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7D_2) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")) * Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", null, "unk", null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/(a1+a2)*a1
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7E) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / (Reflect.field(documentIdToExpressionNumericValue, "a1") + Reflect.field(documentIdToExpressionNumericValue, "a2")) * (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", null, null, "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/(a1+a2)*(a2-a1)
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7F_1) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")) * Reflect.field(documentIdToExpressionNumericValue, "a2"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", "unk", null, "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/(a2-a1)*a2
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        else if (barModelType == BarModelTypes.TYPE_7F_2) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")) * Reflect.field(documentIdToExpressionNumericValue, "a1"));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", null, "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/(a2-a1)*a1
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        // Append custom hints if available
        else if (barModelType == BarModelTypes.TYPE_7G) 
        {
            allowParenthesis = true;
            allowCreateCard = true;
            allowResizeBrackets = true;
            
            Reflect.setField(documentIdToExpressionNumericValue, "unk", Reflect.field(documentIdToExpressionNumericValue, "b1") / (Reflect.field(documentIdToExpressionNumericValue, "a2") - Reflect.field(documentIdToExpressionNumericValue, "a1")) * (Reflect.field(documentIdToExpressionNumericValue, "a2") + Reflect.field(documentIdToExpressionNumericValue, "a1")));
            addNumericValueForUnknown("unk");
            codeRoot.addChild(getFractionOfWholeReferenceModel("a1", "a2", null, null, "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
            
            // b/(a2-a1)*(a2+a1)
            var referenceEquation = Xml.parse("<equation/>");
			Reflect.setField(documentIdToExpressionNameMap, "unk", "=");
            referenceEquation.set("value", Reflect.field(documentIdToExpressionNameMap, "unk"));
            codeRoot.addChild(referenceEquation);
        }
        
        
        
        if (m_customHintJsonData.exists(levelId)) 
        {
            var customHintsElementList : Xml = Xml.parse("<customHints/>");
            var customHintsData : Array<Dynamic> = m_customHintJsonData[levelId];
            for (customHintData in customHintsData)
            {
                var customHintElement : Xml = Xml.parse("<hint/>");
                customHintElement.set("step", customHintData.step);
                if (customHintData.bar != null && customHintData.bar != "") 
                {
                    customHintElement.set("existingBar", customHintData.bar);
                }
                
                customHintElement.addChild(customHintData.hint);
                customHintsElementList.addChild(customHintElement);
            }
            codeRoot.addChild(customHintsElementList);
        }
        // Add background music tags. The music type depends on the problem context
        else if (customHintGenerator != null && additionalDetails != null && additionalDetails.exists("hintData")) 
        {
            var customHintsElementList = customHintGenerator.generateHintsForLevel(barModelType, documentIdToExpressionNumericValue, Reflect.field(additionalDetails, "hintData"));
            if (customHintsElementList != null) 
            {
                codeRoot.addChild(customHintsElementList.x);
            }
        }
        
        
        
        var extraResourcesElement : Xml = Xml.parse("<resources/>");
        var backgroundMusicElement : Xml = Xml.parse("<audio/>");
        backgroundMusicElement.set("type", "streaming");
        var candidateBgMusicNames : Array<String> = new Array<String>();
        if (problemContext == "fantasy") 
        {
            candidateBgMusicNames.push("bg_music_fantasy_1");
            candidateBgMusicNames.push("bg_music_fantasy_2");
            
        }
        else if (problemContext == "science fiction") 
        {
            candidateBgMusicNames.push("bg_music_science_fiction_1");
            candidateBgMusicNames.push("bg_music_science_fiction_2");
            candidateBgMusicNames.push("bg_music_science_fiction_3");
            
        }
        else if (problemContext == "mystery") 
        {
            candidateBgMusicNames.push("bg_music_mystery_1");
        }
        else 
        {
            candidateBgMusicNames.push("bg_music_fantasy_1");
            candidateBgMusicNames.push("bg_music_fantasy_2");
            candidateBgMusicNames.push("bg_home_music");
            
        }
        
        var bgMusicIndex : Int = Math.floor(Math.random() * candidateBgMusicNames.length);
        var audioSourceName : String = candidateBgMusicNames[bgMusicIndex];
        backgroundMusicElement.set("src", audioSourceName);
        extraResourcesElement.addChild(backgroundMusicElement);
        levelTemplateXml.addChild(extraResourcesElement);
        
        //Attach rules after we figured out what type it is
        var rulesElement : Xml = levelTemplateXml.elementsNamed("rules").next();
        rulesElement.addChild(createBasicSubelementWithValue("allowAddNewSegments", Std.string(allowAddNewSegments)));
        rulesElement.addChild(createBasicSubelementWithValue("allowAddUnitBar", Std.string(allowAddUnitBar)));
        rulesElement.addChild(createBasicSubelementWithValue("allowSplitBar", Std.string(allowSplitBar)));
        rulesElement.addChild(createBasicSubelementWithValue("allowCopyBar", Std.string(allowCopyBar)));
        rulesElement.addChild(createBasicSubelementWithValue("allowCreateCard", Std.string(allowCreateCard)));
        rulesElement.addChild(createBasicSubelementWithValue("allowParenthesis", Std.string(allowParenthesis)));
        rulesElement.addChild(createBasicSubelementWithValue("allowSubtract", Std.string(allowSubtract)));
        rulesElement.addChild(createBasicSubelementWithValue("allowMultiply", Std.string(allowMultiply)));
        rulesElement.addChild(createBasicSubelementWithValue("allowDivide", Std.string(allowDivide)));
        rulesElement.addChild(createBasicSubelementWithValue("allowResizeBrackets", Std.string(allowResizeBrackets)));
        
        var overrideLayoutElement : Xml = levelTemplateXml.elementsNamed("overrideLayoutAttributes").next();
        var textAreaElement : Xml = Xml.parse("<textArea/>");
        textAreaElement.set("id", "textArea");
        var backgroundName : String = m_backgroundToStyle.getBackgroundNameFromId(backgroundId);
        textAreaElement.set("src", "url(../assets/level_images/" + backgroundName + ".jpg)");
        overrideLayoutElement.addChild(textAreaElement);
        
        // Need to determine appropriate font size (how big is the text area, can we poll the dimensions from the xml)
        // We need to know what the allowable width and height for the text in order to pick the corr
        var measuringTextField : MeasuringTextField = new MeasuringTextField();
        var textStyleElement : Xml = levelTemplateXml.elementsNamed("style").next();
        var customTextStyleData : Dynamic = m_backgroundToStyle.getTextStyleFromId(backgroundId);
        var maxAllowedFontSize : Int = customTextStyleData.fontSize;
        
        // Place an upper limit on how big a font can be
        var maxAllowedWidth : Float = 550;
        var maxAllowedHeight : Float = 200;
        
        measuringTextField.width = maxAllowedWidth;
        measuringTextField.height = maxAllowedHeight;
        var textFormat : TextFormat = new TextFormat(customTextStyleData.fontName, customTextStyleData.fontSize);
        measuringTextField.defaultTextFormat = textFormat;
        measuringTextField.multiline = true;
        measuringTextField.wordWrap = true;
        measuringTextField.htmlText = problemText;
        
        var textWithoutTags : String = StringTools.replace(measuringTextField.text, "\n", "");
        var targetFontSize : Float = measuringTextField.resizeToDimensions(maxAllowedWidth, maxAllowedHeight, textWithoutTags);
        targetFontSize = Math.min(targetFontSize, maxAllowedFontSize);
        
        // Inject the new style block into the empty space
        var textStyleToPutInLevel : Dynamic = {
            p : {
                color : customTextStyleData.color,
                fontName : customTextStyleData.fontName,
                fontSize : targetFontSize,
            }
        };
        textStyleElement.addChild(Xml.createPCData(haxe.Json.stringify(textStyleToPutInLevel)));
        
        return levelTemplateXml;
    }
    
    private function createEquationCombinationPairs(equationIds : Array<Dynamic>) : Array<Xml>
    {
        var equationSets : Array<Xml> = new Array<Xml>();
        var i : Int = 0;
        var j : Int = 0;
        var numIds : Int = equationIds.length;
        for (i in 0...numIds){
            for (j in i + 1...numIds){
                var equationSetElement : Xml = Xml.parse("<equationSet/>");
                var firstId : String = equationIds[i];
                var secondId : String = equationIds[j];
                var firstEquationElement : Xml = Xml.parse("<equation/>");
                firstEquationElement.set("id", firstId);
                equationSetElement.addChild(firstEquationElement);
                
                var secondEquationElement : Xml = Xml.parse("<equation/>");
                secondEquationElement.set("id", secondId);
                equationSetElement.addChild(secondEquationElement);
                equationSets.push(equationSetElement);
            }
        }
        
        return equationSets;
    }
    
    private function createBasicSubelementWithValue(name : String, value : String) : Xml
    {
        var ruleSubelement : Xml = Xml.parse("<" + name + "/>");
        ruleSubelement.set("value", value);
        return ruleSubelement;
    }
    
    /**
     * Recursively search for all spans in the target text that have been tagged as a term,
     * meaning it should be assoicated with part of an expression.
     */
    private function _getTaggedElements(element : Xml,
            taggedElements : Array<Xml>) : Void
    {
		var fastElement = new Fast(element);
        if (fastElement.name == "span" && fastElement.has.resolve("class") && fastElement.att.resolve("class") == "term") 
        {
            taggedElements.push(element);
        }
        else 
        {
            for (childElement in fastElement.elements)
            {
                _getTaggedElements(childElement.x, taggedElements);
            }
        }
    }
    
    /**
     * A handful of bar model types deal with fractions in which both the numerator and denominator
     * are important, however the problem is that the fraction has not been separated so we need to
     * do that manually
     */
    private function convertFractionToTwoNumbers(originalTaggedElement : Xml) : Void
    {
		var fastOriginalTaggedElement = new Fast(originalTaggedElement);
        // If a tagged part has a do not split attribute then do not try splitting fractions
        if (fastOriginalTaggedElement.has.nosplit) 
        {
            var noSplit : Bool = XString.stringToBool(fastOriginalTaggedElement.att.nosplit);
            if (noSplit) 
            {
                return;
            }
        }
		
		// The fraction is of a form <digit> / <digit>  
        // The digit is a number of any length.
        var fractionText : String = Std.string(originalTaggedElement.firstChild);
        var fractionRegex : EReg = new EReg('\\d+\\/\\d+', "");
		var match : String = null;
		if (fractionRegex.match(fractionText)) {
			match = fractionRegex.matched(0);
		}
        if (match != null) 
        {
            var parentElement : Xml = fastOriginalTaggedElement.x.parent;
            
            // Split the original part into the numerator and denominator
            var fractionParts : Array<Dynamic> = fractionText.split("/");
			// TODO: not sure if this is a correct conversion
            //fastOriginalTaggedElement.node.replace.innerData("*", fractionParts[0]);
			fastOriginalTaggedElement.x.firstChild().nodeValue = fractionParts[0];
            var originalTaggedId : String = fastOriginalTaggedElement.att.id;
            
            // Need to create a new a new span AFTER
            var newDenominatorElement : Xml = Xml.parse("<span></span>");
            newDenominatorElement.set("class", "term");
            newDenominatorElement.set("id", originalTaggedId.charAt(0) + Std.parseInt(originalTaggedId.charAt(1)) + 1);
            newDenominatorElement.addChild(Xml.createPCData(fractionParts[1]));
			
			// TODO: not sure if this is a correct conversion
			//parentElement.node.insertChildAfter.innerData(originalTaggedElement, newDenominatorElement);
            //parentElement.node.insertChildBefore.innerData(newDenominatorElement, "/");
			parentElement.addChild(newDenominatorElement);			
        }
    }
    
    private function calculateSumEquation(docIdToExpressionMap : Dynamic) : String
    {
        // Equation for this is unk = all parts added
        var equation : String = Reflect.field(docIdToExpressionMap, "unk") + "=";
        var counter : Int = 0;
        for (documentId in Reflect.fields(docIdToExpressionMap))
        {
            if (documentId.indexOf("a") == 0 || documentId.indexOf("b") == 0) 
            {
                if (counter > 0) 
                {
                    equation += "+";
                }
                equation += Reflect.field(docIdToExpressionMap, documentId);
                counter++;
            }
        }
        return equation;
    }
    
    private function calculateMultiplicationEquation(multiplierAId : String, multiplierBId : String, docIdToExpressionMap : Dynamic) : String
    {
        return Reflect.field(docIdToExpressionMap, "unk") + "=" + Reflect.field(docIdToExpressionMap, multiplierAId) + "*" + Reflect.field(docIdToExpressionMap, multiplierBId);
    }
    
    private function calculateDivisionEquation(dividendId : String, divisorId : String, docIdToExpressionMap : Dynamic) : String
    {
        return Reflect.field(docIdToExpressionMap, "unk") + "=" + Reflect.field(docIdToExpressionMap, dividendId) + "/" + Reflect.field(docIdToExpressionMap, divisorId);
    }
    
    private function calculateDifferenceEquation(largerPrefix : String,
            smallerPrefix : String,
            docIdToExpressionMap : Dynamic) : String
    {
        var equation : String = Reflect.field(docIdToExpressionMap, "unk") + "=(";
        var counter : Int = 0;
        for (documentId in Reflect.fields(docIdToExpressionMap))
        {
            if (documentId.indexOf(largerPrefix) == 0) 
            {
                if (counter > 0) 
                {
                    equation += "+";
                }
                equation += Reflect.field(docIdToExpressionMap, documentId);
                counter++;
            }
        }
        equation += ")-(";
        
        counter = 0;
        for (documentId in Reflect.fields(docIdToExpressionMap))
        {
            if (documentId.indexOf(smallerPrefix) == 0) 
            {
                if (counter > 0) 
                {
                    equation += "+";
                }
				Reflect.setField(docIdToExpressionMap, documentId, Reflect.field(docIdToExpressionMap, documentId) + 1);
                counter++;
            }
        }
        
        equation += ")";
        
        return equation;
    }
    
    private function calculateSum(prefixA : String,
            prefixB : String,
            docIdToNumericValue : Dynamic) : Float
    {
        var sum : Float = 0;
        for (documentId in Reflect.fields(docIdToNumericValue))
        {
            if (documentId.indexOf(prefixA) == 0 || documentId.indexOf(prefixB) == 0) 
            {
                sum += Reflect.field(docIdToNumericValue, documentId);
            }
        }
        return sum;
    }
    
    private function calculateDifference(largerPrefix : String, smallerPrefix : String, docIdToNumericValue : Dynamic) : Float
    {
        var largerValue : Float = 0;
        var smallerValue : Float = 0;
        for (documentId in Reflect.fields(docIdToNumericValue))
        {
            if (documentId.indexOf(largerPrefix) == 0) 
            {
                largerValue += Reflect.field(docIdToNumericValue, documentId);
            }
            
            if (documentId.indexOf(smallerPrefix) == 0) 
            {
                smallerValue += Reflect.field(docIdToNumericValue, documentId);
            }
        }
        return largerValue - smallerValue;
    }
    
    // The unknown needs to have its value calculated from the other parts
    // What we want to do is create a mapping from document id to actual value
    private function getSumAndDifferenceReferenceModel(prefixLargerId : String,
            prefixSmallerId : String,
            sumId : String,
            differenceId : String,
            docIdToExpressionName : Dynamic,
            docIdToNumericValue : Dynamic,
            largerAndSmallerSeparateBars : Bool = true) : Xml
    {
        var referenceModel : Xml = Xml.parse("<referenceModel/>");
        
        var barWholeLarger : Xml = Xml.parse("<barWhole/>");
        barWholeLarger.set("id", prefixLargerId);
        var barWholeSmaller : Xml = barWholeLarger;
        var totalSegments : Int = 0;
        if (largerAndSmallerSeparateBars) 
        {
            barWholeSmaller = Xml.parse("<barWhole/>");
            barWholeSmaller.set("id", prefixSmallerId);
        }
        
        for (documentId in Reflect.fields(docIdToExpressionName))
        {
            if (documentId.indexOf(prefixLargerId) == 0) 
            {
                var segment : Xml = Xml.parse("<barSegment />");
                segment.set("value", Reflect.field(docIdToNumericValue, documentId));
                segment.set("label", Reflect.field(docIdToExpressionName, documentId));
                barWholeLarger.addChild(segment);
                totalSegments++;
            }
            
            if (documentId.indexOf(prefixSmallerId) == 0) 
            {
                var segment = Xml.parse("<barSegment />");
                segment.set("value", Reflect.field(docIdToNumericValue, documentId));
                segment.set("label", Reflect.field(docIdToExpressionName, documentId));
                barWholeSmaller.addChild(segment);
                totalSegments++;
            }
        }
		
		// If one bar, the sum should be a horizontally oriented bracket  
        if (sumId != null) 
        {
            if (!largerAndSmallerSeparateBars) 
            {
                var label : Xml = Xml.parse("<bracket/>");
                label.set("value", Reflect.field(docIdToExpressionName, sumId));
                label.set("start", "0");
                label.set("end", Std.string(totalSegments - 1));
                barWholeLarger.addChild(label);
            }
            else 
            {
                var verticalBracket : Xml = Xml.parse("<verticalBracket/>");
                verticalBracket.set("value", Reflect.field(docIdToExpressionName, sumId));
                verticalBracket.set("start", "0");
                verticalBracket.set("end", "1");
                referenceModel.addChild(verticalBracket);
            }
        }
        
        if (differenceId != null && largerAndSmallerSeparateBars) 
        {
            var barComparison : Xml = Xml.parse("<barCompare/>");
            barComparison.set("value", Reflect.field(docIdToExpressionName, differenceId));
            barComparison.set("compTo", barWholeLarger.get("id"));
            barWholeSmaller.addChild(barComparison);
        }
        
        referenceModel.addChild(barWholeLarger);
        
        if (largerAndSmallerSeparateBars) 
        {
            referenceModel.addChild(barWholeSmaller);
        }
        
        return referenceModel;
    }
    
    private function getSimpleMultiplicationReferenceModel(numPartsId : String,
            singlePartValueId : String,
            sumId : String,
            docIdToExpressionName : Dynamic,
            docIdToNumericValue : Dynamic) : Xml
    {
        var referenceModel : Xml = Xml.parse("<referenceModel/>");
        var barWhole : Xml = Xml.parse("<barWhole/>");
        var numSegments : Int = Reflect.field(docIdToNumericValue, numPartsId);
        var i : Int = 0;
        for (i in 0...numSegments){
            var segment : Xml = Xml.parse("<barSegment />");
            segment.set("value", Reflect.field(docIdToNumericValue, singlePartValueId));
            
            // Just need one label for the equal sized parts
            // (when displaying reference results in copilot having labels on every equal
            // group looks cluttered)
            if (i == 0) 
            {
                segment.set("label", Reflect.field(docIdToExpressionName, singlePartValueId));
            }
            barWhole.addChild(segment);
        }
        
        var label : Xml = Xml.parse("<bracket/>");
        label.set("value", Reflect.field(docIdToExpressionName, sumId));
        label.set("start", "0");
        label.set("end", Std.string(numSegments - 1));
        barWhole.addChild(label);
        referenceModel.addChild(barWhole);
        
        return referenceModel;
    }
    
    private function getMultiplierReferenceModel(numPartsId : String,
            singlePartValueId : String,
            sumOfGroupsId : String,
            sumOfAllId : String,
            differenceId : String,
            docIdToExpressionName : Dynamic,
            docIdToNumericValue : Dynamic) : Xml
    {
        var referenceModel : Xml = Xml.parse("<referenceModel/>");
        
        var barWhole : Xml = Xml.parse("<barWhole/>");
        barWhole.set("id", numPartsId);
        var numSegments : Int = Reflect.field(docIdToNumericValue, numPartsId);
        var i : Int = 0;
        for (i in 0...numSegments){
            var segment : Xml = Xml.parse("<barSegment/>");
            segment.set("value", Reflect.field(docIdToNumericValue, singlePartValueId));
            barWhole.addChild(segment);
        }
        
        if (sumOfGroupsId != null) 
        {
            var label : Xml = Xml.parse("<bracket/>");
            label.set("value", Reflect.field(docIdToExpressionName, sumOfGroupsId));
            label.set("start", "0");
            label.set("end", Std.string(numSegments - 1));
            barWhole.addChild(label);
        }
        
        var barWholeForUnit : Xml = Xml.parse("<barWhole/>");
        var segment = Xml.parse("<barSegment/>");
        segment.set("value", Reflect.field(docIdToNumericValue, singlePartValueId));
        segment.set("label", Reflect.field(docIdToExpressionName, singlePartValueId));
        barWholeForUnit.addChild(segment);
        
        referenceModel.addChild(barWhole);
        referenceModel.addChild(barWholeForUnit);
        
        if (sumOfAllId != null) 
        {
            var verticalBracket : Xml = Xml.parse("<verticalBracket/>");
            verticalBracket.set("value", Reflect.field(docIdToExpressionName, sumOfAllId));
            verticalBracket.set("start", "0");
            verticalBracket.set("end", "1");
            referenceModel.addChild(verticalBracket);
        }
        
        if (differenceId != null) 
        {
            var barComparison : Xml = Xml.parse("<barCompare/>");
            barComparison.set("value", Reflect.field(docIdToExpressionName, differenceId));
            barComparison.set("compTo", barWhole.get("id"));
            barWholeForUnit.addChild(barComparison);
        }
        
        return referenceModel;
    }
    
    private function getFractionReferenceModel(numeratorId : String,
            denominatorId : String,
            shadedLabelId : String,
            unshadedLabelId : String,
            sumId : String,
            docIdToExpressionName : Dynamic,
            docIdToNumericValue : Dynamic) : Xml
    {
        var referenceModel : Xml = Xml.parse("<referenceModel/>");
        
        var barWhole : Xml = Xml.parse("<barWhole/>");
        barWhole.set("id", denominatorId);
        var numSegments : Int = Reflect.field(docIdToNumericValue, denominatorId);
        var i : Int = 0;
        for (i in 0...numSegments){
            var segment : Xml = Xml.parse("<barSegment/>");
            segment.set("value", "1");
            barWhole.addChild(segment);
        }
        
        if (shadedLabelId != null) 
        {
            var label : Xml = Xml.parse("<bracket/>");
            label.set("value", Reflect.field(docIdToExpressionName, shadedLabelId));
            label.set("start", "0");
			Reflect.setField(docIdToNumericValue, numeratorId, 1);
            label.set("end", "1");
            barWhole.addChild(label);
        }
        
        if (unshadedLabelId != null) 
        {
            var label = Xml.parse("<bracket/>");
            label.set("value", Reflect.field(docIdToExpressionName, unshadedLabelId));
            label.set("start", "0");
			Reflect.setField(docIdToNumericValue, denominatorId, Reflect.field(docIdToNumericValue, numeratorId));
            label.set("end", Reflect.field(docIdToNumericValue, numeratorId));
            barWhole.addChild(label);
        }
        
        if (sumId != null) 
        {
            var label = Xml.parse("<bracket/>");
            label.set("value", Reflect.field(docIdToExpressionName, sumId));
            label.set("start", "0");
            label.set("end", Std.string(numSegments - 1));
            barWhole.addChild(label);
        }
        referenceModel.addChild(barWhole);
        
        return referenceModel;
    }
    
    private function getFractionOfWholeReferenceModel(numeratorId : String,
            denominatorId : String,
            wholeLabelId : String,
            fractionLabelId : String,
            differenceId : String,
            sumOfAllId : String,
            docIdToExpressionName : Dynamic,
            docIdToNumericValue : Dynamic) : Xml
    {
        var referenceModel : Xml = Xml.parse("<referenceModel/>");
        
        var numPartsInWhole : Int = Reflect.field(docIdToNumericValue, denominatorId);
        var barForWhole : Xml = Xml.parse("<barWhole/>");
        barForWhole.set("id", denominatorId);
        var i : Int = 0;
        for (i in 0...numPartsInWhole){
            // What is the value of the segment
            var segment : Xml = Xml.parse("<barSegment/>");
            segment.set("value", "1");
            barForWhole.addChild(segment);
        }
        
        if (wholeLabelId != null) 
        {
            var label : Xml = Xml.parse("<bracket/>");
            label.set("value", Reflect.field(docIdToExpressionName, wholeLabelId));
            label.set("start", "0");
            label.set("end", Std.string(numPartsInWhole - 1));
            barForWhole.addChild(label);
        }
        
        var numPartsInFraction : Int = Reflect.field(docIdToNumericValue, numeratorId);
        var barForFraction : Xml = Xml.parse("<barWhole/>");
        for (i in 0...numPartsInFraction){
            var segment = Xml.parse("<barSegment/>");
            segment.set("value", "1");
            barForFraction.addChild(segment);
        }
        
        if (fractionLabelId != null) 
        {
            var label = Xml.parse("<bracket/>");
            label.set("value", Reflect.field(docIdToExpressionName, fractionLabelId));
            label.set("start", "0");
            label.set("end", Std.string(numPartsInFraction - 1));
            barForFraction.addChild(label);
        }
        
        referenceModel.addChild(barForWhole);
        referenceModel.addChild(barForFraction);
        
        if (sumOfAllId != null) 
        {
            var verticalBracket : Xml = Xml.parse("<verticalBracket/>");
            verticalBracket.set("value", Reflect.field(docIdToExpressionName, sumOfAllId));
            verticalBracket.set("start", "0");
            verticalBracket.set("end", "1");
            referenceModel.addChild(verticalBracket);
        }
        
        if (differenceId != null) 
        {
            var barComparison : Xml = Xml.parse("<barCompare/>");
            barComparison.set("value", Reflect.field(docIdToExpressionName, differenceId));
            barComparison.set("compTo", barForWhole.get("id"));
            barForFraction.addChild(barComparison);
        }
        
        return referenceModel;
    }
}
