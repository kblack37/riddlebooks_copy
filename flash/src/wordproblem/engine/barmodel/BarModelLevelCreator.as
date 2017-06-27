package wordproblem.engine.barmodel
{
    import flash.text.TextFormat;
    
    import dragonbox.common.util.PM_PRNG;
    import dragonbox.common.util.TextToNumber;
    import dragonbox.common.util.XColor;
    import dragonbox.common.util.XString;
    
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
    public class BarModelLevelCreator
    {
        [Embed(source="barmodel_level_template.xml", mimeType="application/octet-stream")]
        public static const barmodel_level_template:Class;
        
        private var m_gameServerRequester:GameServerRequester;
        
        /**
         * A call to fetch a problem remotely will most likely take several frames, need to remember
         * the callback that gets triggered after the request has finished.
         */
        private var m_loadCompleteCallback:Function;
        private var m_lastLevelIdRequested:int;
        
        private var m_backgroundToStyle:BarModelBackgroundToStyle;
        
        /**
         * Key: problem/level id
         * Value: Array of hint data objects
         */
        private var m_customHintJsonData:Object;
        
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
        public function BarModelLevelCreator(gameServerRequester:GameServerRequester, customHintJsonData:Object=null)
        {
            m_gameServerRequester = gameServerRequester;
            m_backgroundToStyle = new BarModelBackgroundToStyle();
            
            // Preprocess the hinting information so that it is keyed 
            m_customHintJsonData = {};
            if (customHintJsonData != null)
            {
                var hintsList:Array = customHintJsonData.hints;
                var numHints:int = hintsList.length;
                var i:int;
                for (i = 0; i < numHints; i++)
                {
                    var hintData:Object = hintsList[i];
                    var problemId:int = hintData.id;
                    if (!m_customHintJsonData.hasOwnProperty(problemId))
                    {
                        m_customHintJsonData[problemId] = [];
                    }
                    
                    var listForId:Array = m_customHintJsonData[problemId];
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
        public function loadLevelFromId(levelId:int, 
                                        onLoadComplete:Function, 
                                        customHintGenerator:CustomHintGenerator=null):void
        {
            m_lastLevelIdRequested = levelId;
            m_loadCompleteCallback = onLoadComplete;
            
            m_gameServerRequester.getLevelDataFromId(levelId + "", function onProblemDataRequestComplete(success:Boolean, data:Object):void
            {
                if (success)
                {
                    if (m_loadCompleteCallback != null)
                    {
                        var barModelType:String = data.bar_model_type;
                        var backgroundId:String = data.background_id;
                        var problemContext:String = data.context;
                        var problemText:String = data.problem_text;
                        
                        var rawDetails:String = data.additional_details;
                        var additionalDetails:Object = (rawDetails != null && rawDetails != "") ? JSON.parse(data.additional_details) : null;
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
        public function generateLevelFromData(levelId:int,
                                              barModelType:String, 
                                              problemContext:String, 
                                              problemText:String, 
                                              backgroundId:String, 
                                              additionalDetails:Object, 
                                              customHintGenerator:CustomHintGenerator=null):XML
        {
            // Have a default background style
            if (backgroundId == null)
            {
                backgroundId = "general_a";
            }
            
            var levelTemplateXml:XML = new XML(new barmodel_level_template());
            levelTemplateXml.@id = levelId;
            levelTemplateXml.@barModelType = barModelType;
            levelTemplateXml.@name = "Bar model " + levelId;
            
            var problemTextXml:XML = new XML("<p>" + problemText + "</p>");
            
            var documentIdToExpressionNameMap:Object = {};
            var documentIdToExpressionNumericValue:Object = {};
            var taggedElements:Vector.<XML> = new Vector.<XML>();
            _getTaggedElements(problemTextXml, taggedElements);
            for each (var taggedElement:XML in taggedElements)
            {
                // First rewrite the problem to take care of fraction, iterate through every relevant span
                convertFractionToTwoNumbers(taggedElement);
            }
            
            // Attach the problem text.
            var problemTextRoot:XML = levelTemplateXml.wordproblem[0].page[0].div[0];
            problemTextRoot.appendChild(problemTextXml);
            
            // We assume the document ids in the text have a specific role in how they fit in the
            // given bar model type. Using this information, we can determine what values compose
            // both the reference bar model and the reference equation model
            taggedElements.length = 0;
            _getTaggedElements(problemTextXml, taggedElements);
            
            // Collect all the information about an alias that is used to later create special card
            // properties for that element
            var tagIdToAliasMap:Object = {};
            for each (taggedElement in taggedElements)
            {
                if (taggedElement.hasOwnProperty("@alias") && taggedElement.hasOwnProperty("@id"))
                {
                    taggedId = taggedElement.attribute("id");
                    aliasValue = taggedElement.attribute("alias");
                    
                    if (additionalDetails != null && additionalDetails.hasOwnProperty("symbol_data"))
                    {
                        var symbols:Array = additionalDetails["symbol_data"];
                        for each (var symbolData:Object in symbols)
                        {
                            if (symbolData.value == aliasValue)
                            {
                                tagIdToAliasMap[taggedId] = symbolData;
                                break;
                            }
                        }
                    }
                    
                    // Alias has no extra data, so set up the default values
                    if (!tagIdToAliasMap.hasOwnProperty(taggedId))
                    {
                        tagIdToAliasMap[taggedId] = {value: aliasValue};
                    }
                }
            }
            
            // Figure out the backing values each tagged element represents
            var textToNumber:TextToNumber = new TextToNumber();
            for each (taggedElement in taggedElements)
            {
                var taggedId:String = taggedElement.attribute("id");
                
                // Note that multiple elements might point to the same tag id, for example text
                // representing the unknown appears in two separate phrases. Avoid doing any duplicate
                // logic.
                if (!documentIdToExpressionNameMap.hasOwnProperty(taggedId))
                {
                    var taggedValueUnmodified:String = taggedElement.toString();
                    
                    // The tagged value can either be a string if it is an unknown or
                    // a variable OR it can be a numeric value.
                    // The document ids that bind to the first case are always assumed to
                    // be 'unk' or 'c'
                    
                    // An alias means we use a different value, do not use the raw text
                    var aliasValue:String = null;
                    if (tagIdToAliasMap.hasOwnProperty(taggedId))
                    {
                        aliasValue = tagIdToAliasMap[taggedId].value;
                        taggedValueUnmodified = aliasValue;
                    }
    
                    // Tagged elements are supposed to either indicate numbers or
                    // unknowns that are just words.
                    // We use the assumption that tagged elements with ids that
                    // begin with 'a' or 'b' should always be numbers
                    // Everything else is a word.
                    if (taggedId.charAt(0) == "a" || taggedId.charAt(0) == "b")
                    {
                        var numberFromText:Number = textToNumber.textToNumber(taggedValueUnmodified); 
                        documentIdToExpressionNameMap[taggedId] = numberFromText;
                        
                        // Numbers do not need an alias in the tag
                        if (additionalDetails != null && additionalDetails.hasOwnProperty("symbol_data"))
                        {
                            symbols = additionalDetails["symbol_data"];
                            for each (symbolData in symbols)
                            {
                                if (symbolData.value == numberFromText.toString())
                                {
                                    var symbolElement:XML = <symbol/>;
                                    symbolElement.@name = (symbolData.hasOwnProperty("name")) ? 
                                        symbolData.name : numberFromText;
                                    // Zoran wanted to remove the words from the tiles
                                    //symbolElement.@abbreviatedName = (symbolData.hasOwnProperty("abbreviated")) ?
                                    //    symbolData.abbreviated : numberFromText;
                                    symbolElement.@value = numberFromText;
                                    symbolElement.@backgroundTexturePositive = "card_background_square"
                                    levelTemplateXml.elements("symbols")[0].appendChild(symbolElement);   
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        // Strip out spaces for variable names, the expression compiler cannot detect that
                        // tokens with spaces should be a single part.
                        var taggedValueNoSpaces:String = taggedValueUnmodified.replace(" ", "_");
                        
                        // Remove any special characters that might mess up the expression compiler,
                        // this includes anything that can be confused as an operator, parenthesis, '?', and '='
                        taggedValueNoSpaces = taggedValueNoSpaces.replace(/[\?\+=\-\*\(\)]/g, "");
                        symbolElement = <symbol/>;
                        symbolElement.@name = (aliasValue != null && tagIdToAliasMap[taggedId].hasOwnProperty("name")) ? 
                            tagIdToAliasMap[taggedId].name : taggedValueUnmodified;
                        symbolElement.@abbreviatedName = (aliasValue != null && tagIdToAliasMap[taggedId].hasOwnProperty("abbreviated")) ?
                            tagIdToAliasMap[taggedId].abbreviated : taggedValueUnmodified;
                        symbolElement.@value = taggedValueNoSpaces;
                        symbolElement.@backgroundTexturePositive = "card_background_square"
                        levelTemplateXml.elements("symbols")[0].appendChild(symbolElement);
                        
                        documentIdToExpressionNameMap[taggedId] = taggedValueNoSpaces;
                    }
                }
            }
            
            var smallestNumericValue:Number = int.MAX_VALUE;
            var defaultNormalizingFactor:int = 1;
            
            // Used to assign unique bar model colors to each terms. Across all plays of this level, the
            // color of the boxes in the bar model should be consistent, for example '3' is always a blue box.
            var uniqueTermValues:Array = [];
            
            // Attach the mapping from ids in the text to actual expression values
            var codeRoot:XML = levelTemplateXml.script[0].scriptedActions[0].code[0];
            for (var documentId:String in documentIdToExpressionNameMap)
            {
                var documentToTermElement:XML = <documentToCard />;
                documentToTermElement.@documentId = documentId;
                documentToTermElement.@value = documentIdToExpressionNameMap[documentId];
                codeRoot.appendChild(documentToTermElement);
                
                // The reference models require having relative numerical proportions for bar segments.
                // For example, we need to know before hand how much larger the unknown should be than
                // the parts represented by numbers so we know how big to make the default box for
                // that unknown
                var numericValueForDocument:Number = parseFloat(documentIdToExpressionNameMap[documentId]);
                if (!isNaN(numericValueForDocument))
                {
                    // Values that are not numbers need to be calculated based on the bar model type
                    documentIdToExpressionNumericValue[documentId] = numericValueForDocument;
                }
                
                if (documentId.charAt(0) == "a" || documentId.charAt(0) == "b")
                {
                    smallestNumericValue = Math.min(numericValueForDocument, smallestNumericValue);
                }
                
                // For each unique term value, make sure a <symbol> tag is created for it and that a
                // unique color is assigned to it.
                var termValue:String = documentToTermElement.@value;
                if (uniqueTermValues.indexOf(termValue) < 0)
                {
                    uniqueTermValues.push(termValue);
                }
            }
            
            var sortedUniqueTermValues:Array = uniqueTermValues.sort();
            var colorPicker:PM_PRNG = new PM_PRNG(levelId);
            var barColors:Vector.<uint> = XColor.getCandidateColorsForSession();
            for each (termValue in sortedUniqueTermValues)
            {
                var symbolsBlock:XML = levelTemplateXml.elements("symbols")[0];
                var matchingSymbolElement:XML = null;
                for each (symbolElement in symbolsBlock.children())
                {
                    if (symbolElement.@value == termValue)
                    {
                        matchingSymbolElement = symbolElement;
                        break;
                    }
                }
                
                // If could not find matching element, create a new one for that term
                if (matchingSymbolElement == null)
                {
                    matchingSymbolElement = <symbol/>;
                    matchingSymbolElement.@value = termValue;
                    symbolsBlock.appendChild(matchingSymbolElement);
                }
                
                // To make sure colors look distinct, we pick from a list of predefined list and avoid duplicates
                if (barColors.length > 0)
                {
                    var colorIndex:int = colorPicker.nextIntRange(0, barColors.length - 1);
                    matchingSymbolElement.@customBarColor = "0x" + barColors[colorIndex].toString(16).toUpperCase();
                    barColors.splice(colorIndex, 1);
                }
                else
                {
                    // In the unlikely case we have too many terms that use up all the colors, we just randomly
                    // pick one from a palette.
                    matchingSymbolElement.@customBarColor = "0x" + XColor.getDistributedHsvColor(colorPicker.nextDouble()).toString(16).toUpperCase();
                }
                matchingSymbolElement.@useCustomBarColor = true;
            }
            
            codeRoot.appendChild(createBasicSubelementWithValue("barNormalizingFactor", smallestNumericValue.toString()));
            
            function addNumericValueForUnknown(unknownDocId:String):void
            {
                var termValueToBarValue:XML = <termValueToBarValue/>;
                termValueToBarValue.@termValue = documentIdToExpressionNameMap[unknownDocId];
                termValueToBarValue.@barValue = documentIdToExpressionNumericValue[unknownDocId];
                codeRoot.appendChild(termValueToBarValue);
            }
            
            // Level rules defining allowable actions in the level
            var allowAddNewSegments:Boolean = true;
            var allowAddUnitBar:Boolean = true;
            var allowSplitBar:Boolean = true;
            var allowCopyBar:Boolean = true;
            var allowCreateCard:Boolean = false;
            var allowSubtract:Boolean = true;
            var allowMultiply:Boolean = true;
            var allowDivide:Boolean = true;
            var allowResizeBrackets:Boolean = false;
            var allowParenthesis:Boolean = false;
            
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
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", null, "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_1A)
            {
                allowAddUnitBar = false;
                allowSplitBar = false;
                allowCopyBar = false;
                allowSubtract = false;
                allowMultiply = false;
                allowDivide = false;
                
                documentIdToExpressionNumericValue["unk"] = calculateSum("a", "b", documentIdToExpressionNumericValue);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
                
                // Travis' experiement requires explicitly having a separate model using two rows
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, true));
                
                var referenceEquation:XML = <equation/>;
                referenceEquation.@value = calculateSumEquation(documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_1B)
            {
                allowAddUnitBar = false;
                allowSplitBar = false;
                allowCopyBar = false;
                allowMultiply = false;
                allowDivide = false;
                
                documentIdToExpressionNumericValue["unk"] = calculateDifference("b", "a", documentIdToExpressionNumericValue);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("b", "a", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // Allow a1 to be a difference if it is made up of just one part
                var numTermsWithSmallerPrefix:int = 0;
                for (docId in documentIdToExpressionNumericValue)
                {
                    if (docId.charAt(0) == "a")
                    {
                        numTermsWithSmallerPrefix++;
                    }
                }
                
                if (numTermsWithSmallerPrefix == 1)
                {
                    codeRoot.appendChild(getSumAndDifferenceReferenceModel("b", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_2A)
            {
                allowAddUnitBar = false;
                allowSplitBar = false;
                allowCopyBar = false;
                allowMultiply = false;
                allowDivide = false;
                
                documentIdToExpressionNumericValue["unk"] = calculateDifference("b", "a", documentIdToExpressionNumericValue);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("b", "a", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // Allow a1 to be a difference if it is made up of just one part
                numTermsWithSmallerPrefix = 0;
                for (docId in documentIdToExpressionNumericValue)
                {
                    if (docId.charAt(0) == "a")
                    {
                        numTermsWithSmallerPrefix++;
                    }
                }
                
                if (numTermsWithSmallerPrefix == 1)
                {
                    codeRoot.appendChild(getSumAndDifferenceReferenceModel("b", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                
                // Allow for subtraction to be solved with addition as long as the larger part of the difference is represented by just one term
                // Just make sure there are not multiple parts with the same prefix
                var numTermsWithLargerPrefix:int = 0;
                for (var docId:String in documentIdToExpressionNumericValue)
                {
                    if (docId.charAt(0) == "b")
                    {
                        numTermsWithLargerPrefix++;
                    }
                }
                
                if (numTermsWithLargerPrefix == 1)
                {
                    codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_2B)
            {
                allowAddUnitBar = false;
                allowSplitBar = false;
                allowCopyBar = false;
                allowMultiply = false;
                allowDivide = false;
                
                documentIdToExpressionNumericValue["unk"] = calculateSum("a", "b", documentIdToExpressionNumericValue);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, true));
                
                // Travis' experiement requires explicitly having a separate model using two rows
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue, false));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateSumEquation(documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_2C)
            {
                allowAddUnitBar = false;
                allowSplitBar = false;
                allowCopyBar = false;
                allowMultiply = false;
                allowDivide = false;
                
                documentIdToExpressionNumericValue["unk"] = calculateDifference("b", "a", documentIdToExpressionNumericValue);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("b", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("b", "a1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                numTermsWithLargerPrefix = 0;
                for (docId in documentIdToExpressionNumericValue)
                {
                    if (docId.charAt(0) == "b")
                    {
                        numTermsWithLargerPrefix++;
                    }
                }
                
                if (numTermsWithLargerPrefix == 1)
                {
                    codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_2D)
            {
                allowAddUnitBar = false;
                allowSplitBar = false;
                allowCopyBar = false;
                allowMultiply = false;
                allowDivide = false;
                
                documentIdToExpressionNumericValue["unk"] = calculateSum("b", "a", documentIdToExpressionNumericValue);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("unk", "a", null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "b", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // Allow a1 to be a difference if it is made up of just one part
                numTermsWithSmallerPrefix = 0;
                for (docId in documentIdToExpressionNumericValue)
                {
                    if (docId.charAt(0) == "a")
                    {
                        numTermsWithSmallerPrefix++;
                    }
                }
                
                if (numTermsWithSmallerPrefix == 1)
                {
                    codeRoot.appendChild(getSumAndDifferenceReferenceModel("unk", "b", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateSumEquation(documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_2E)
            {
                allowAddUnitBar = false;
                allowSplitBar = false;
                allowCopyBar = false;
                allowMultiply = false;
                allowDivide = false;
                
                documentIdToExpressionNumericValue["unk"] = calculateDifference("b", "a", documentIdToExpressionNumericValue);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("b", "a", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // Allow a1 to be a difference if it is made up of just one part
                numTermsWithSmallerPrefix = 0;
                for (docId in documentIdToExpressionNumericValue)
                {
                    if (docId.charAt(0) == "a")
                    {
                        numTermsWithSmallerPrefix++;
                    }
                }
                
                if (numTermsWithSmallerPrefix == 1)
                {
                    codeRoot.appendChild(getSumAndDifferenceReferenceModel("b1", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateDifferenceEquation("b", "a", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_3A)
            {
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] * documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSimpleMultiplicationReferenceModel("b1", "a1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // Only allow reverse if the numbers are small enough
                if (documentIdToExpressionNumericValue["a1"] <= 30)
                {
                    codeRoot.appendChild(getSimpleMultiplicationReferenceModel("a1", "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateMultiplicationEquation("b1", "a1", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_3B)
            {
                var dividend:int = documentIdToExpressionNumericValue["b1"];
                var divisor:int = documentIdToExpressionNumericValue["a1"];
                documentIdToExpressionNumericValue["unk"] = dividend / divisor;
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getSimpleMultiplicationReferenceModel("a1", "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateDivisionEquation("b1", "a1", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_4A)
            {
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] * documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "a1", "unk", null, null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                codeRoot.appendChild(getSimpleMultiplicationReferenceModel("b1", "a1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // Only allow reverse if the numbers are small enough
                if (documentIdToExpressionNumericValue["a1"] <= 30)
                {
                    codeRoot.appendChild(getSimpleMultiplicationReferenceModel("a1", "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateMultiplicationEquation("b1", "a1", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_4B)
            {
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] / documentIdToExpressionNumericValue["b1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "unk", "a1", null, null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                if (documentIdToExpressionNumericValue["b1"] <= 30)
                {
                    codeRoot.appendChild(getSimpleMultiplicationReferenceModel("b1", "unk", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                }
                    
                referenceEquation = <equation/>;
                referenceEquation.@value = calculateDivisionEquation("a1", "b1", documentIdToExpressionNameMap);
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_4C)
            {
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] * documentIdToExpressionNumericValue["a1"] - documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "a1", null, null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "*" + 
                    documentIdToExpressionNameMap["a1"] + "-" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_4D)
            {
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] * documentIdToExpressionNumericValue["a1"] + documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "a1", null, "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "*" + 
                    documentIdToExpressionNameMap["a1"] + "+" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_4E)
            {
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] / (documentIdToExpressionNumericValue["b1"] - 1);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "unk", null, null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "/(" + documentIdToExpressionNameMap["b1"] + "-1)";
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_4F)
            {
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] / (documentIdToExpressionNumericValue["b1"] + 1);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "unk", null, "a1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "/(" + documentIdToExpressionNameMap["b1"] + "+1)";
                codeRoot.appendChild(referenceEquation);
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
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] + (documentIdToExpressionNumericValue["a1"] - documentIdToExpressionNumericValue["b1"]);
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] - documentIdToExpressionNumericValue["b1"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "c", "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a+(a-b)
                // unk=a+c
                // c=a-b
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + 
                    "+(" + documentIdToExpressionNameMap["a1"] + "-" + documentIdToExpressionNameMap["b1"] + ")";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "+" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["a1"] + "-" + documentIdToExpressionNameMap["b1"];
                codeRoot.appendChild(referenceEquation);
                
                var equationSetElement:XML;
                var equationSets:Vector.<XML> = createEquationCombinationPairs(["1", "2", "3"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5B)
            {
                allowParenthesis = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] + (documentIdToExpressionNumericValue["a1"] + documentIdToExpressionNumericValue["b1"]);
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] + documentIdToExpressionNumericValue["b1"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("c", "a", "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a+(a+b)
                // unk=a+c
                // c=a+b
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + 
                    "+(" + documentIdToExpressionNameMap["a1"] + "+" + documentIdToExpressionNameMap["b1"] + ")";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "+" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["a1"] + "+" + documentIdToExpressionNameMap["b1"];
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5C)
            {
                allowParenthesis = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] - (documentIdToExpressionNumericValue["b1"] - documentIdToExpressionNumericValue["a1"]);
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["b1"] - documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("a", "c", "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a-(b-a)
                // c=b-a
                // unk=a-c
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + 
                    "-(" + documentIdToExpressionNameMap["b1"] + "-" + documentIdToExpressionNameMap["a1"] + ")";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "-" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["b1"] + "-" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5D)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = (documentIdToExpressionNumericValue["b1"] - documentIdToExpressionNumericValue["a1"]) / 2;
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] + documentIdToExpressionNumericValue["unk"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("c", "unk", "b1", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=(b-a)/2
                // unk=b-c
                // unk=c-a
                // c=a+(b-a)/2
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=(" + documentIdToExpressionNameMap["b1"] + "-" + documentIdToExpressionNameMap["a1"] + ")/2";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "-" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["c"] + "-" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
                
                var aValue:String = documentIdToExpressionNameMap["a1"];
                var bValue:String = documentIdToExpressionNameMap["b1"];
                referenceEquation = <equation id="4"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + aValue + "+" + "(" + bValue + "-" + aValue + ")/2";
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5E)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = (documentIdToExpressionNumericValue["b1"] + documentIdToExpressionNumericValue["a1"]) / 2;
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["b1"] - documentIdToExpressionNumericValue["unk"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getSumAndDifferenceReferenceModel("unk", "c", "b1", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                //unk=(b+a)/2
                //unk=c+a
                //unk=b-c
                //c=(b-a)/2
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=(" + documentIdToExpressionNameMap["b1"] + "-" + documentIdToExpressionNameMap["a1"] + ")/2";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "-" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["c"] + "+" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
                
                aValue = documentIdToExpressionNameMap["a1"];
                bValue = documentIdToExpressionNameMap["b1"];
                referenceEquation = <equation id="4"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=(" + bValue + "-" + aValue + ")/2";
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5F)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] - documentIdToExpressionNumericValue["a1"] / documentIdToExpressionNumericValue["b1"];
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] / documentIdToExpressionNumericValue["b1"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "c", "a1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a-a/b
                // unk=a-c
                // c=a/b
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "-" + 
                    documentIdToExpressionNameMap["a1"] + "/" + documentIdToExpressionNameMap["b1"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "-" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["a1"] + "/" + documentIdToExpressionNameMap["b1"];
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5G)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] + documentIdToExpressionNumericValue["a1"] / documentIdToExpressionNumericValue["b1"];
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] / documentIdToExpressionNumericValue["b1"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "c", "a1", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a+a/b
                // unk=a+c
                // c=a/b
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "+" + 
                    documentIdToExpressionNameMap["a1"] + "/" + documentIdToExpressionNameMap["b1"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "+" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["a1"] + "/" + documentIdToExpressionNameMap["b1"];
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5H)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] / (1 - 1 / documentIdToExpressionNumericValue["b1"]);
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["unk"] / documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "c", "unk", null, "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a/(1-1/b)
                // unk=c+a
                // unk=b*c
                // c=a/(b-1)
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "/(1-1/" + documentIdToExpressionNameMap["b1"] + ")";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["c"] + "+" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "*" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                aValue = documentIdToExpressionNameMap["a1"];
                bValue = documentIdToExpressionNameMap["b1"];
                referenceEquation = <equation id="4"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + aValue + "/(" + bValue + "-1)";
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5I)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] * (documentIdToExpressionNumericValue["b1"] + 1) / 
                    (documentIdToExpressionNumericValue["b1"] - 1);
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] / (documentIdToExpressionNumericValue["b1"] - 1);
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "c", null, "unk", "a1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a*(b+1)/(b-1)
                // unk=c*b+c
                // c=a/(b-1)
                // unk=a+2*c
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=(" + documentIdToExpressionNameMap["a1"] + "*(" + documentIdToExpressionNameMap["b1"] + "+1))/(" +
                    documentIdToExpressionNameMap["b1"] + "-1)";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["c"] + "*" + 
                    documentIdToExpressionNameMap["b1"] + "+" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["a1"] + "/(" + documentIdToExpressionNameMap["b1"] + "-1)";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="4"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "+2*" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5J)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] * documentIdToExpressionNumericValue["a1"] / 
                    (documentIdToExpressionNumericValue["b1"] + 1);
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] / (documentIdToExpressionNumericValue["b1"] - 1);
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "c", "unk", "a1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=b*a/(b+1)
                // unk=b*c
                // c=a-unk
                // c=a/(b+1)
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "*" + documentIdToExpressionNameMap["a1"] + "/(" +
                    documentIdToExpressionNameMap["b1"] + "+1)";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["c"] + "*" + documentIdToExpressionNameMap["b1"];
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["a1"] + "-" + documentIdToExpressionNameMap["unk"];
                codeRoot.appendChild(referenceEquation);
                
                aValue = documentIdToExpressionNameMap["a1"];
                bValue = documentIdToExpressionNameMap["b1"];
                referenceEquation = <equation id="4"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + aValue + "/(" + bValue +"+1)";
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_5K)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["a1"] * (documentIdToExpressionNumericValue["b1"] - 1) / 
                    (documentIdToExpressionNumericValue["b1"] + 1);
                documentIdToExpressionNumericValue["c"] = documentIdToExpressionNumericValue["a1"] / (documentIdToExpressionNumericValue["b1"] + 1);
                addNumericValueForUnknown("unk");
                addNumericValueForUnknown("c");
                codeRoot.appendChild(getMultiplierReferenceModel("b1", "c", null, "a1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // unk=a*(b-1)/(b+1)
                // unk=c*(b-1)
                // c=a/(b+1)
                // unk=a-2*c
                referenceEquation = <equation id="1"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "*(" + documentIdToExpressionNameMap["b1"] + "-1)/(" +
                    documentIdToExpressionNameMap["b1"] + "+1)";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="2"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["c"] + "*(" + documentIdToExpressionNameMap["b1"] + "-1)";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="3"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["c"] + "=" + documentIdToExpressionNameMap["a1"] + "/(" + documentIdToExpressionNameMap["b1"] + "+1)";
                codeRoot.appendChild(referenceEquation);
                
                referenceEquation = <equation id="4"/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["a1"] + "-2*" + documentIdToExpressionNameMap["c"];
                codeRoot.appendChild(referenceEquation);
                
                equationSets = createEquationCombinationPairs(["1", "2", "3", "4"]);
                for each (equationSetElement in equationSets)
                {
                    codeRoot.appendChild(equationSetElement);
                }
            }
            else if (barModelType == BarModelTypes.TYPE_6A)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / documentIdToExpressionNumericValue["a2"] * documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionReferenceModel("a1", "a2", "unk", null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/a2*a1
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/" + 
                    documentIdToExpressionNameMap["a2"] + "*" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_6B)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / documentIdToExpressionNumericValue["a2"] * 
                    (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"]);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionReferenceModel("a1", "a2", null, "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/a2*(a2-a1)
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/" + documentIdToExpressionNameMap["a2"] + 
                    "*(" + documentIdToExpressionNameMap["a2"] + "-" + documentIdToExpressionNameMap["a1"] + ")";
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_6C)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / documentIdToExpressionNumericValue["a1"] * documentIdToExpressionNumericValue["a2"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionReferenceModel("a1", "a2", "b1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/a1*a2
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/" + 
                    documentIdToExpressionNameMap["a1"] + "*" + documentIdToExpressionNameMap["a2"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_6D)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / documentIdToExpressionNumericValue["a1"] * 
                    (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"]);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionReferenceModel("a1", "a2", "b1", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/a1*(a2-a1)
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/" + documentIdToExpressionNameMap["a1"] + 
                    "*(" + documentIdToExpressionNameMap["a2"] + "-" + documentIdToExpressionNameMap["a1"] + ")";
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7A)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / documentIdToExpressionNumericValue["a1"] * documentIdToExpressionNumericValue["a2"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", "unk", "b1", null, null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/a1*a2
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/" +
                    documentIdToExpressionNameMap["a1"] + "*" + documentIdToExpressionNameMap["a2"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7B)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / documentIdToExpressionNumericValue["a1"] * 
                    (documentIdToExpressionNumericValue["a2"] + documentIdToExpressionNumericValue["a1"]);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", null, "b1", null, "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                //b/a1*(a1+a2)
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/" + documentIdToExpressionNameMap["a1"] + 
                    "*(" + documentIdToExpressionNameMap["a2"] + "+" + documentIdToExpressionNameMap["a1"] + ")";
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7C)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / documentIdToExpressionNumericValue["a1"] * 
                    (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"]);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", null, "b1", "unk", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/a1*(a2-a1)
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/" + documentIdToExpressionNameMap["a1"] + 
                    "*(" + documentIdToExpressionNameMap["a2"] + "-" + documentIdToExpressionNameMap["a1"] + ")";
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7D_1)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"])
                    * documentIdToExpressionNumericValue["a2"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", "unk", null, null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/(a1+a2)*a2
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/(" + documentIdToExpressionNameMap["a2"] + 
                    "+" + documentIdToExpressionNameMap["a1"] + ")*" + documentIdToExpressionNameMap["a2"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7D_2)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"])
                    * documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", null, "unk", null, "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/(a1+a2)*a1
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + "/(" + documentIdToExpressionNameMap["a2"] + 
                    "+" + documentIdToExpressionNameMap["a1"] + ")*" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7E)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / (documentIdToExpressionNumericValue["a1"] + documentIdToExpressionNumericValue["a2"])
                    * (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"]);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", null, null, "unk", "b1", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/(a1+a2)*(a2-a1)
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + 
                    "/(" + documentIdToExpressionNameMap["a2"] + "+" + documentIdToExpressionNameMap["a1"] + ")*(" + 
                    documentIdToExpressionNameMap["a2"] + "-" + documentIdToExpressionNameMap["a1"] +")";
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7F_1)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"])
                    * documentIdToExpressionNumericValue["a2"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", "unk", null, "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/(a2-a1)*a2
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + 
                    "/(" + documentIdToExpressionNameMap["a2"] + "-" + documentIdToExpressionNameMap["a1"] + ")*" + documentIdToExpressionNameMap["a2"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7F_2)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"])
                    * documentIdToExpressionNumericValue["a1"];
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", null, "unk", "b1", null, documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/(a2-a1)*a1
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + 
                    "/(" + documentIdToExpressionNameMap["a2"] + "-" + documentIdToExpressionNameMap["a1"] + ")*" + documentIdToExpressionNameMap["a1"];
                codeRoot.appendChild(referenceEquation);
            }
            else if (barModelType == BarModelTypes.TYPE_7G)
            {
                allowParenthesis = true;
                allowCreateCard = true;
                allowResizeBrackets = true;
                
                documentIdToExpressionNumericValue["unk"] = documentIdToExpressionNumericValue["b1"] / (documentIdToExpressionNumericValue["a2"] - documentIdToExpressionNumericValue["a1"])
                    * (documentIdToExpressionNumericValue["a2"] + documentIdToExpressionNumericValue["a1"]);
                addNumericValueForUnknown("unk");
                codeRoot.appendChild(getFractionOfWholeReferenceModel("a1", "a2", null, null, "b1", "unk", documentIdToExpressionNameMap, documentIdToExpressionNumericValue));
                
                // b/(a2-a1)*(a2+a1)
                referenceEquation = <equation/>;
                referenceEquation.@value = documentIdToExpressionNameMap["unk"] + "=" + documentIdToExpressionNameMap["b1"] + 
                    "/(" + documentIdToExpressionNameMap["a2"] + "-" + documentIdToExpressionNameMap["a1"] + ")*(" + 
                    documentIdToExpressionNameMap["a2"] + "+" + documentIdToExpressionNameMap["a1"] +")";
                codeRoot.appendChild(referenceEquation);
            }
            
            // Append custom hints if available
            if (m_customHintJsonData.hasOwnProperty(levelId))
            {
                var customHintsElementList:XML = <customHints/>;
                var customHintsData:Array = m_customHintJsonData[levelId];
                for each (var customHintData:Object in customHintsData)
                {
                    var customHintElement:XML = <hint/>;
                    customHintElement.@step = customHintData.step;
                    if (customHintData.bar != null && customHintData.bar != "")
                    {
                        customHintElement.@existingBar = customHintData.bar;
                    }
                    
                    customHintElement.appendChild(customHintData.hint);
                    customHintsElementList.appendChild(customHintElement);
                }
                codeRoot.appendChild(customHintsElementList);
            }
            else if (customHintGenerator && additionalDetails != null && additionalDetails.hasOwnProperty("hintData"))
            {
                customHintsElementList = customHintGenerator.generateHintsForLevel(barModelType, documentIdToExpressionNumericValue, additionalDetails["hintData"]);
                if (customHintsElementList != null)
                {
                    codeRoot.appendChild(customHintsElementList);
                }
            }
            
            // Add background music tags. The music type depends on the problem context
            var extraResourcesElement:XML = <resources/>;
            var backgroundMusicElement:XML = <audio/>;
            backgroundMusicElement.@type = "streaming";
            var candidateBgMusicNames:Vector.<String> = new Vector.<String>();
            if (problemContext == "fantasy")
            {
                candidateBgMusicNames.push("bg_music_fantasy_1", "bg_music_fantasy_2");
            }
            else if (problemContext == "science fiction")
            {
                candidateBgMusicNames.push("bg_music_science_fiction_1", "bg_music_science_fiction_2", "bg_music_science_fiction_3");
            }
            else if (problemContext == "mystery")
            {
                candidateBgMusicNames.push("bg_music_mystery_1");
            }
            else
            {
                candidateBgMusicNames.push("bg_music_fantasy_1", "bg_music_fantasy_2", "bg_home_music");
            }
            
            var bgMusicIndex:int = Math.floor(Math.random() * candidateBgMusicNames.length);
            var audioSourceName:String = candidateBgMusicNames[bgMusicIndex];
            backgroundMusicElement.@src = audioSourceName;
            extraResourcesElement.appendChild(backgroundMusicElement);
            levelTemplateXml.appendChild(extraResourcesElement);
            
            //Attach rules after we figured out what type it is
            var rulesElement:XML = levelTemplateXml.elements("rules")[0];
            rulesElement.appendChild(createBasicSubelementWithValue("allowAddNewSegments", allowAddNewSegments.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowAddUnitBar", allowAddUnitBar.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowSplitBar", allowSplitBar.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowCopyBar", allowCopyBar.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowCreateCard", allowCreateCard.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowParenthesis", allowParenthesis.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowSubtract", allowSubtract.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowMultiply", allowMultiply.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowDivide", allowDivide.toString()));
            rulesElement.appendChild(createBasicSubelementWithValue("allowResizeBrackets", allowResizeBrackets.toString()));
            
            var overrideLayoutElement:XML = levelTemplateXml.elements("overrideLayoutAttributes")[0];
            var textAreaElement:XML = <textArea/>;
            textAreaElement.@id = "textArea";
            var backgroundName:String = m_backgroundToStyle.getBackgroundNameFromId(backgroundId);
            textAreaElement.@src = "url(../assets/level_images/" + backgroundName + ".jpg)";
            overrideLayoutElement.appendChild(textAreaElement);
            
            // Need to determine appropriate font size (how big is the text area, can we poll the dimensions from the xml)
            // We need to know what the allowable width and height for the text in order to pick the corr
            var measuringTextField:MeasuringTextField = new MeasuringTextField();
            var textStyleElement:XML = levelTemplateXml.elements("style")[0];
            var customTextStyleData:Object = m_backgroundToStyle.getTextStyleFromId(backgroundId);
            var maxAllowedFontSize:int = customTextStyleData.fontSize;
            
            // Place an upper limit on how big a font can be
            var maxAllowedWidth:Number = 550;
            var maxAllowedHeight:Number = 200;
            
            measuringTextField.width = maxAllowedWidth;
            measuringTextField.height = maxAllowedHeight;
            var textFormat:TextFormat = new TextFormat(customTextStyleData.fontName, customTextStyleData.fontSize);
            measuringTextField.defaultTextFormat = textFormat;
            measuringTextField.multiline = true;
            measuringTextField.wordWrap = true;
            measuringTextField.htmlText = problemText;
            
            var textWithoutTags:String = measuringTextField.text.replace("\n", "");
            var targetFontSize:Number = measuringTextField.resizeToDimensions(maxAllowedWidth, maxAllowedHeight, textWithoutTags);
            targetFontSize = Math.min(targetFontSize, maxAllowedFontSize);
            
            // Inject the new style block into the empty space
            var textStyleToPutInLevel:Object = {
                'p': {
                    'color': customTextStyleData.color,
                    'fontName': customTextStyleData.fontName,
                    'fontSize': targetFontSize
                }
            };
            textStyleElement.setChildren(JSON.stringify(textStyleToPutInLevel));
            
            return levelTemplateXml;
        }
        
        private function createEquationCombinationPairs(equationIds:Array):Vector.<XML>
        {
            var equationSets:Vector.<XML> = new Vector.<XML>();
            var i:int;
            var j:int;
            var numIds:int = equationIds.length;
            for (i = 0; i < numIds; i++)
            {
                for (j = i + 1; j < numIds; j++)
                {
                    var equationSetElement:XML = <equationSet/>;
                    var firstId:String = equationIds[i];
                    var secondId:String = equationIds[j];
                    var firstEquationElement:XML = <equation/>;
                    firstEquationElement.@id = firstId;
                    equationSetElement.appendChild(firstEquationElement);
                    
                    var secondEquationElement:XML = <equation/>;
                    secondEquationElement.@id = secondId;
                    equationSetElement.appendChild(secondEquationElement);
                    equationSets.push(equationSetElement);
                }
            }
            
            return equationSets;
        }
        
        private function createBasicSubelementWithValue(name:String, value:String):XML
        {
            var ruleSubelement:XML = new XML("<" + name + "/>");
            ruleSubelement.@value = value;
            return ruleSubelement;
        }
        
        /**
         * Recursively search for all spans in the target text that have been tagged as a term,
         * meaning it should be assoicated with part of an expression.
         */
        private function _getTaggedElements(element:XML, 
                                            taggedElements:Vector.<XML>):void
        {
            if (element.name() == "span" && element.hasOwnProperty("@class") && element.attribute("class") == "term")
            {
                taggedElements.push(element);
            }
            else
            {
                for each (var childElement:XML in element.children())
                {
                    _getTaggedElements(childElement, taggedElements);
                }
            }
        }
        
        /**
         * A handful of bar model types deal with fractions in which both the numerator and denominator
         * are important, however the problem is that the fraction has not been separated so we need to
         * do that manually
         */
        private function convertFractionToTwoNumbers(originalTaggedElement:XML):void
        {
            // If a tagged part has a do not split attribute then do not try splitting fractions
            if (originalTaggedElement.hasOwnProperty("@nosplit"))
            {
                var noSplit:Boolean = XString.stringToBool(originalTaggedElement.@nosplit);
                if (noSplit)
                {
                    return;
                }
            }
            
            // The fraction is of a form <digit> / <digit>
            // The digit is a number of any length.
            var fractionText:String = originalTaggedElement.toString();
            var fractionRegex:RegExp = /\d+\/\d+/;
            var matches:Array = fractionText.match(fractionRegex);
            if (matches != null && matches.length == 1)
            {
                var parentElement:XML = originalTaggedElement.parent();
                
                // Split the original part into the numerator and denominator
                var fractionParts:Array = fractionText.split("/");
                originalTaggedElement.replace("*", fractionParts[0]);
                var originalTaggedId:String = originalTaggedElement.attribute("id");
                
                // Need to create a new a new span AFTER
                var newDenominatorElement:XML = <span></span>;
                newDenominatorElement["@class"] = "term";
                newDenominatorElement["@id"] = originalTaggedId.charAt(0) + (parseInt(originalTaggedId.charAt(1)) + 1);
                newDenominatorElement.appendChild(fractionParts[1]);
                parentElement.insertChildAfter(originalTaggedElement, newDenominatorElement);
                parentElement.insertChildBefore(newDenominatorElement, "/");
            }
        }
        
        private function calculateSumEquation(docIdToExpressionMap:Object):String
        {
            // Equation for this is unk = all parts added
            var equation:String = docIdToExpressionMap["unk"] + "=";
            var counter:int = 0;
            for (var documentId:String in docIdToExpressionMap)
            {
                if (documentId.indexOf("a") == 0 || documentId.indexOf("b") == 0)
                {
                    if (counter > 0)
                    {
                        equation += "+";
                    }
                    equation += docIdToExpressionMap[documentId];
                    counter++;
                }
            }
            return equation;
        }
        
        private function calculateMultiplicationEquation(multiplierAId:String, multiplierBId:String, docIdToExpressionMap:Object):String
        {
            return docIdToExpressionMap["unk"] + "=" + docIdToExpressionMap[multiplierAId] + "*" + docIdToExpressionMap[multiplierBId];
        }
        
        private function calculateDivisionEquation(dividendId:String, divisorId:String, docIdToExpressionMap:Object):String
        {
            return docIdToExpressionMap["unk"] + "=" + docIdToExpressionMap[dividendId] + "/" + docIdToExpressionMap[divisorId];
        }
        
        private function calculateDifferenceEquation(largerPrefix:String, 
                                                     smallerPrefix:String, 
                                                     docIdToExpressionMap:Object):String
        {
            var equation:String = docIdToExpressionMap["unk"] + "=(";
            var counter:int = 0;
            for (var documentId:String in docIdToExpressionMap)
            {
                if (documentId.indexOf(largerPrefix) == 0)
                {
                    if (counter > 0)
                    {
                        equation += "+";
                    }
                    equation += docIdToExpressionMap[documentId];
                    counter++;
                }
            }
            equation += ")-(";
            
            counter = 0;
            for (documentId in docIdToExpressionMap)
            {
                if (documentId.indexOf(smallerPrefix) == 0)
                {
                    if (counter > 0)
                    {
                        equation += "+";
                    }
                    equation += docIdToExpressionMap[documentId];
                    counter++;
                }
            }
            
            equation += ")";
            
            return equation;
        }
        
        private function calculateSum(prefixA:String, 
                                      prefixB:String,
                                      docIdToNumericValue:Object):Number
        {
            var sum:Number = 0;
            for (var documentId:String in docIdToNumericValue)
            {
                if (documentId.indexOf(prefixA) == 0 || documentId.indexOf(prefixB) == 0)
                {
                    sum += docIdToNumericValue[documentId];
                }
            }
            return sum;
        }
        
        private function calculateDifference(largerPrefix:String, smallerPrefix:String, docIdToNumericValue:Object):Number
        {
            var largerValue:Number = 0;
            var smallerValue:Number = 0;
            for (var documentId:String in docIdToNumericValue)
            {
                if (documentId.indexOf(largerPrefix) == 0)
                {
                    largerValue += docIdToNumericValue[documentId];
                }
                
                if (documentId.indexOf(smallerPrefix) == 0)
                {
                    smallerValue += docIdToNumericValue[documentId];
                }
            }
            return largerValue - smallerValue;
        }
        
        // The unknown needs to have its value calculated from the other parts
        // What we want to do is create a mapping from document id to actual value
        private function getSumAndDifferenceReferenceModel(prefixLargerId:String, 
                                                           prefixSmallerId:String,
                                                           sumId:String,
                                                           differenceId:String, 
                                                           docIdToExpressionName:Object, 
                                                           docIdToNumericValue:Object, 
                                                           largerAndSmallerSeparateBars:Boolean = true):XML
        {
            var referenceModel:XML = <referenceModel/>;
            
            var barWholeLarger:XML = <barWhole/>;
            barWholeLarger.@id = prefixLargerId;
            var barWholeSmaller:XML = barWholeLarger;
            var totalSegments:int = 0;
            if (largerAndSmallerSeparateBars)
            {
                barWholeSmaller = <barWhole/>;
                barWholeSmaller.@id = prefixSmallerId;
            }
            
            for (var documentId:String in docIdToExpressionName)
            {
                if (documentId.indexOf(prefixLargerId) == 0)
                {
                    var segment:XML = <barSegment />;
                    segment.@value = docIdToNumericValue[documentId];
                    segment.@label = docIdToExpressionName[documentId];
                    barWholeLarger.appendChild(segment);
                    totalSegments++;
                }
                
                if (documentId.indexOf(prefixSmallerId) == 0)
                {
                    segment = <barSegment />;
                    segment.@value = docIdToNumericValue[documentId];
                    segment.@label = docIdToExpressionName[documentId];
                    barWholeSmaller.appendChild(segment);
                    totalSegments++;
                }
            }
            
            // If one bar, the sum should be a horizontally oriented bracket
            if (sumId != null)
            {
                if (!largerAndSmallerSeparateBars)
                {
                    var label:XML = <bracket/>;
                    label.@value = docIdToExpressionName[sumId];
                    label.@start = 0;
                    label.@end = totalSegments - 1;
                    barWholeLarger.appendChild(label); 
                }
                else
                {
                    var verticalBracket:XML = <verticalBracket/>;
                    verticalBracket.@value = docIdToExpressionName[sumId];
                    verticalBracket.@start = 0;
                    verticalBracket.@end = 1;
                    referenceModel.appendChild(verticalBracket);
                }
            }
            
            if (differenceId != null && largerAndSmallerSeparateBars)
            {
                var barComparison:XML = <barCompare/>;
                barComparison.@value = docIdToExpressionName[differenceId];
                barComparison.@compTo = barWholeLarger.@id;
                barWholeSmaller.appendChild(barComparison);
            }
            
            referenceModel.appendChild(barWholeLarger);
            
            if (largerAndSmallerSeparateBars)
            {
                referenceModel.appendChild(barWholeSmaller);
            }
            
            return referenceModel;
        }
        
        private function getSimpleMultiplicationReferenceModel(numPartsId:String, 
                                                               singlePartValueId:String, 
                                                               sumId:String, 
                                                               docIdToExpressionName:Object, 
                                                               docIdToNumericValue:Object):XML
        {
            var referenceModel:XML = <referenceModel/>;
            var barWhole:XML = <barWhole/>
            var numSegments:int = docIdToNumericValue[numPartsId];
            var i:int;
            for (i = 0; i < numSegments; i++)
            {
                var segment:XML = <barSegment />;
                segment.@value = docIdToNumericValue[singlePartValueId];
                
                // Just need one label for the equal sized parts
                // (when displaying reference results in copilot having labels on every equal
                // group looks cluttered)
                if (i == 0)
                {
                    segment.@label = docIdToExpressionName[singlePartValueId];
                }
                barWhole.appendChild(segment);
            }
            
            var label:XML = <bracket/>;
            label.@value = docIdToExpressionName[sumId];
            label.@start = 0;
            label.@end = numSegments - 1;
            barWhole.appendChild(label);
            referenceModel.appendChild(barWhole);
            
            return referenceModel;
        }
        
        private function getMultiplierReferenceModel(numPartsId:String, 
                                                     singlePartValueId:String, 
                                                     sumOfGroupsId:String,
                                                     sumOfAllId:String,
                                                     differenceId:String,
                                                     docIdToExpressionName:Object, 
                                                     docIdToNumericValue:Object):XML
        {
            var referenceModel:XML = <referenceModel/>;
            
            var barWhole:XML = <barWhole/>;
            barWhole.@id = numPartsId;
            var numSegments:int = docIdToNumericValue[numPartsId];
            var i:int;
            for (i = 0; i < numSegments; i++)
            {
                var segment:XML = <barSegment/>;
                segment.@value = docIdToNumericValue[singlePartValueId];
                barWhole.appendChild(segment);
            }
            
            if (sumOfGroupsId != null)
            {
                var label:XML = <bracket/>;
                label.@value = docIdToExpressionName[sumOfGroupsId];
                label.@start = 0;
                label.@end = numSegments - 1;
                barWhole.appendChild(label);
            }
            
            var barWholeForUnit:XML = <barWhole/>;
            segment = <barSegment/>;
            segment.@value = docIdToNumericValue[singlePartValueId];
            segment.@label = docIdToExpressionName[singlePartValueId];
            barWholeForUnit.appendChild(segment);
            
            referenceModel.appendChild(barWhole);
            referenceModel.appendChild(barWholeForUnit);

            if (sumOfAllId != null)
            {
                var verticalBracket:XML = <verticalBracket/>;
                verticalBracket.@value = docIdToExpressionName[sumOfAllId];
                verticalBracket.@start = 0;
                verticalBracket.@end = 1;
                referenceModel.appendChild(verticalBracket);
            }
            
            if (differenceId != null)
            {
                var barComparison:XML = <barCompare/>;
                barComparison.@value = docIdToExpressionName[differenceId];
                barComparison.@compTo = barWhole.@id;
                barWholeForUnit.appendChild(barComparison);
            }
            
            return referenceModel;
        }
        
        private function getFractionReferenceModel(numeratorId:String, 
                                                   denominatorId:String,
                                                   shadedLabelId:String, 
                                                   unshadedLabelId:String,
                                                   sumId:String,
                                                   docIdToExpressionName:Object, 
                                                   docIdToNumericValue:Object):XML
        {
            var referenceModel:XML = <referenceModel/>;
            
            var barWhole:XML = <barWhole/>;
            barWhole.@id = denominatorId;
            var numSegments:int = docIdToNumericValue[denominatorId];
            var i:int;
            for (i = 0; i < numSegments; i++)
            {
                var segment:XML = <barSegment/>;
                segment.@value = 1;
                barWhole.appendChild(segment);
            }
            
            if (shadedLabelId != null)
            {
                var label:XML = <bracket/>;
                label.@value = docIdToExpressionName[shadedLabelId];
                label.@start = 0;
                label.@end = docIdToNumericValue[numeratorId] - 1;
                barWhole.appendChild(label);
            }
            
            if (unshadedLabelId != null)
            {
                label = <bracket/>;
                label.@value = docIdToExpressionName[unshadedLabelId];
                label.@start = 0;
                label.@end = docIdToNumericValue[denominatorId] - docIdToNumericValue[numeratorId] - 1;
                barWhole.appendChild(label);
            }
            
            if (sumId != null)
            {
                label = <bracket/>;
                label.@value = docIdToExpressionName[sumId];
                label.@start = 0;
                label.@end = numSegments - 1;
                barWhole.appendChild(label);
            }
            referenceModel.appendChild(barWhole);
            
            return referenceModel;
        }
        
        private function getFractionOfWholeReferenceModel(numeratorId:String, 
                                                          denominatorId:String,
                                                          wholeLabelId:String, 
                                                          fractionLabelId:String, 
                                                          differenceId:String, 
                                                          sumOfAllId:String, 
                                                          docIdToExpressionName:Object, 
                                                          docIdToNumericValue:Object):XML
        {
            var referenceModel:XML = <referenceModel/>;
            
            var numPartsInWhole:int = docIdToNumericValue[denominatorId];
            var barForWhole:XML = <barWhole/>;
            barForWhole.@id = denominatorId;
            var i:int = 0;
            for (i = 0; i < numPartsInWhole; i++)
            {
                // What is the value of the segment
                var segment:XML = <barSegment/>;
                segment.@value = 1;
                barForWhole.appendChild(segment);
            }
            
            if (wholeLabelId != null)
            {
                var label:XML = <bracket/>;
                label.@value = docIdToExpressionName[wholeLabelId];
                label.@start = 0;
                label.@end = numPartsInWhole - 1;
                barForWhole.appendChild(label);
            }
            
            var numPartsInFraction:int = docIdToNumericValue[numeratorId];
            var barForFraction:XML = <barWhole/>;
            for (i = 0; i < numPartsInFraction; i++)
            {
                segment = <barSegment/>;
                segment.@value = 1;
                barForFraction.appendChild(segment);
            }
            
            if (fractionLabelId != null)
            {
                label = <bracket/>;
                label.@value = docIdToExpressionName[fractionLabelId];
                label.@start = 0;
                label.@end = numPartsInFraction - 1;
                barForFraction.appendChild(label);
            }
            
            referenceModel.appendChild(barForWhole);
            referenceModel.appendChild(barForFraction);
            
            if (sumOfAllId != null)
            {
                var verticalBracket:XML = <verticalBracket/>;
                verticalBracket.@value = docIdToExpressionName[sumOfAllId];
                verticalBracket.@start = 0;
                verticalBracket.@end = 1;
                referenceModel.appendChild(verticalBracket);
            }
            
            if (differenceId != null)
            {
                var barComparison:XML = <barCompare/>;
                barComparison.@value = docIdToExpressionName[differenceId];
                barComparison.@compTo = barForWhole.@id;
                barForFraction.appendChild(barComparison);
            }
            
            return referenceModel;
        }
    }
}