package wordproblem.hints;

import haxe.xml.Fast;
import wordproblem.hints.HintScript;
import wordproblem.hints.HintScriptWithProcesses;

import flash.geom.Point;
import flash.text.TextFormat;

import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.DecomposedBarModelData;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextParserUtil;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.hints.processes.DismissCharacterOnClickProcess;
import wordproblem.hints.processes.DismissQuestionProcess;
import wordproblem.hints.processes.HighlightBarModelThenTextProcess;
import wordproblem.hints.processes.HighlightTextProcess;
import wordproblem.hints.processes.HighlightUiElementProcess;
import wordproblem.hints.processes.MoveCharacterToProcess;
import wordproblem.hints.processes.ShowCharacterTextProcess;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.ValidateBarModelArea;

/**
 * Hack class for common code logic used by hint scripts
 */
class HintCommonUtil
{
    public function new()
    {
    }
    
    public static function getLevelStillNeedsBarModelToSolve(gameEngine : IGameEngine) : Bool
    {
        // Any hints closely related to just the bar model are no
        // longer useful if the player has already submitted a correct model
        // (This logic is re-used in several hints, need to detect when a player
        // is done with a model)
        var playerStillNeedsToValidateBarModel : Bool = false;
        var levelScriptRoot : ScriptNode = gameEngine.getCurrentLevel().getScriptRoot();
        var validateBarModelScript : ValidateBarModelArea = try cast(levelScriptRoot.getNodeById("ValidateBarModelArea"), ValidateBarModelArea) catch(e:Dynamic) null;
        if (validateBarModelScript != null) 
        {
            playerStillNeedsToValidateBarModel = !validateBarModelScript.getAtLeastOneSetComplete();
        }
        return playerStillNeedsToValidateBarModel;
    }
    
    /*
    Mismatch types
    */
    public static inline var MISSING_COMPARE : String = "miss_compare";
    public static inline var MISSING_LABEL : String = "miss_label";
    public static inline var INCORRECT_COMPARE : String = "incorrect_compare";
    public static inline var INCORRECT_NAME : String = "incorrect_name";
    public static inline var INCORRECT_EXTRA_NAME : String = "incorrect_extra_name";
    public static inline var LABEL_TOO_MUCH : String = "label_too_much";
    public static inline var LABEL_TOO_LITTLE : String = "label_too_little";
    public static inline var LABEL_RATIO_INCORRECT : String = "label_ratio_incorrect";
    public static inline var SEGMENT_TALLY_DIFFERENT : String = "segment_tally_different";
    public static inline var SEGMENT_UNIQUE_RATIOS_DIFFERENT : String = "segment_unique_ratio_different";
    
    public static function getHighestPriorityShallowMismatch(modelDataSnapshot : BarModelData,
            decomposedPlayerBarModel : DecomposedBarModelData,
            referenceModels : Array<BarModelData>,
            decomposedReferenceModels : Array<DecomposedBarModelData>) : Dynamic
    {
        var pickedMismatch : Dynamic = null;
        if (decomposedPlayerBarModel.detectedLabelValueConflict.length == 0) 
        {
            var mismatchesFound : Array<Array<Dynamic>> = new Array<Array<Dynamic>>();
            var i : Int = 0;
            var numReferenceModels : Int = referenceModels.length;
            var smallestMismatchSet : Array<Dynamic> = null;
            for (i in 0...numReferenceModels){
                var mismatchSet : Array<Dynamic> = findMismatches(
                        referenceModels[i],
                        decomposedReferenceModels[i],
                        modelDataSnapshot,
                        decomposedPlayerBarModel
                        );
                mismatchesFound.push(mismatchSet);
                
                // Since the player got the answer wrong, the smallest mismatch still needs
                // to have at least one element in it
                if ((smallestMismatchSet == null && mismatchSet.length > 0) ||
                    (smallestMismatchSet != null && smallestMismatchSet.length > mismatchSet.length && mismatchSet.length > 0)) 
                {
                    smallestMismatchSet = mismatchSet;
                }
            }  // the fewest mismatches as the one to base the hints off of    // If we have multiple reference models, then we should pick the one with  
            
            
            
            
            
            if (smallestMismatchSet != null && smallestMismatchSet.length > 0) 
            {
                pickedMismatch = smallestMismatchSet[0];
            }
        }
        else 
        {
            // A conflict with one of the labels should trigger a tip explaining the label is incorrectly saying something
            // is equal to more than one amount
            // The label value producing the conflict can only be detected while the model is being built
            var labelWithAConflict : String = decomposedPlayerBarModel.detectedLabelValueConflict[0];
            pickedMismatch = {
                        descriptionContent : "You used '" + labelWithAConflict + "' too many times!"

                    };
        }  // Stuff the picked mismatch with extra data  
        
        
        
        if (pickedMismatch != null) 
        {
            var mismatchType : String = pickedMismatch.type;
            var descriptionContent : String = "";
            var highlightTextExpressionValue : String = null;
            if (mismatchType == MISSING_COMPARE) 
            {
                pickedMismatch.descriptionContent = "'" + pickedMismatch.value + "' is missing, it is the difference.";
                pickedMismatch.highlightTextExpressionValue = pickedMismatch.value;
            }
            else if (mismatchType == MISSING_LABEL) 
            {
                pickedMismatch.descriptionContent = "You forgot to put '" + pickedMismatch.value + "' somewhere.";
                pickedMismatch.highlightTextExpressionValue = pickedMismatch.value;
            }
            else if (mismatchType == INCORRECT_COMPARE || mismatchType == INCORRECT_NAME) 
            {
                pickedMismatch.descriptionContent = "'" + pickedMismatch.value + "' is used in the wrong way.";
            }
            else if (mismatchType == INCORRECT_EXTRA_NAME) 
            {
                pickedMismatch.descriptionContent = "You have an extra name you do not need.";
            }
            else if (mismatchType == LABEL_TOO_LITTLE) 
            {
                pickedMismatch.descriptionContent = "'" + pickedMismatch.value + "' equals too small an amount.";
            }
            else if (mismatchType == LABEL_TOO_MUCH) 
            {
                pickedMismatch.descriptionContent = "'" + pickedMismatch.value + "' equals too large an amount.";
            }
            else if (mismatchType == LABEL_RATIO_INCORRECT) 
            {
                pickedMismatch.descriptionContent = "'" + pickedMismatch.value + "' does not equal the right amount in the answer.";
            }
            else if (mismatchType == SEGMENT_TALLY_DIFFERENT) 
            {
                var expectedTotalTally : Int = pickedMismatch.expected;
                var actualTotalTally : Int = pickedMismatch.actual;
                var tallyDifference : Int = Std.int(Math.abs(expectedTotalTally - actualTotalTally));
                var box : String = ((tallyDifference > 1)) ? "boxes" : "box";
                pickedMismatch.descriptionContent = ((expectedTotalTally > actualTotalTally)) ? 
                        "You have " + tallyDifference + " " + box + " fewer than one of the answers." : 
                        "You have " + tallyDifference + " " + box + " more than one of the answers.";
            }
            else if (mismatchType == SEGMENT_UNIQUE_RATIOS_DIFFERENT) 
            {
                var expectedUniqueCount : Int = pickedMismatch.expected;
                var actualUniqueCount : Int = pickedMismatch.actual;
                var uniqueCountDifference : Int = Std.int(Math.abs(expectedUniqueCount - actualUniqueCount));
                var box = ((uniqueCountDifference > 1)) ? "boxes" : "box";
                pickedMismatch.descriptionContent = ((expectedUniqueCount > actualUniqueCount)) ? 
                        "You may need to add more boxes of a different size" : "You may have too many different sized boxes. Try removing one.";
            }
        }
        
        return pickedMismatch;
    }
    
    /**
     * Mistakes are determined by comparing both the decomposed structures as well as the
     * regular structures (regular structures provide insight into the number of boxes a label
     * spans, which can more clearly be expressed to the user as a mistake)
     * 
     * @return
     *      List of mismatch objects with details about the difference
     */
    public static function findMismatches(expected : BarModelData,
            expectedDecomposed : DecomposedBarModelData,
            actual : BarModelData,
            actualDecomposed : DecomposedBarModelData) : Array<Dynamic>
    {
        // The way bar models are built with numbers appearing on new boxes,
        // Missing name or those spanning the incorrect amounts should take precedence
        // over something like wrong number of boxes
        var mismatchData : Array<Dynamic> = new Array<Dynamic>();
        
        // To sort the different types of mistakes we take multiple buffers, each buffer represents
        // a category of hints with the same priority level.
        // After populating each buffer, at the end we
        var missingLabelBuffer : Array<Dynamic> = new Array<Dynamic>();
        var missingComparisonBuffer : Array<Dynamic> = new Array<Dynamic>();
        var incorrectLabelTypeBuffer : Array<Dynamic> = new Array<Dynamic>();
        var incorrectLabelRatioBuffer : Array<Dynamic> = new Array<Dynamic>();
        var incorrectSegmentsCountBuffer : Array<Dynamic> = new Array<Dynamic>();
        
        var ERROR : Float = 0.0001;
        var expectedLabelToType : Dynamic = expectedDecomposed.labelValueToType;
        var actualLabelToType : Dynamic = actualDecomposed.labelValueToType;
        for (expectedLabelValue in Reflect.fields(expectedLabelToType))
        {
            var expectedLabelType : String = Reflect.field(expectedLabelToType, expectedLabelValue);
            
            // The submitted model is missing a label
            if (!actualLabelToType.exists(expectedLabelValue)) 
            {
                // Should prompt user that they need have not used a particular label value
                // How that new label should be used is another issue (i.e. how much
                // box should it cover or whether it is a comparison part)
                if (expectedLabelType == "c") 
                {
                    // The missing difference should appear after all other labels have been expressed properly
                    missingComparisonBuffer.push({
                                type : MISSING_COMPARE,
                                value : expectedLabelValue,

                            });
                }
                else 
                {
                    missingLabelBuffer.push({
                                type : MISSING_LABEL,
                                value : expectedLabelValue,

                            });
                }
            }
            else 
            {
                // If the label is present, check if it is used a way that is incorrect.
                // Most notably, is a term used as a comparison when it shouldn't (or vis-versa)
                // Horizontal and vertical labels are marked as different types but are sematically the same
                var actualLabelType : String = Reflect.field(actualLabelToType, expectedLabelValue);
                if (actualLabelType != "c" && expectedLabelType != "c") 
                {
                    // Compare the amount of box the labels
                    var expectedLabelAmount : Float = Reflect.field(expectedDecomposed.labelValueToNormalizedSegmentValue, expectedLabelValue);
                    var actualLabelAmount : Float = Reflect.field(actualDecomposed.labelValueToNormalizedSegmentValue, expectedLabelValue);
                    if (Math.abs(expectedLabelAmount - actualLabelAmount) > ERROR) 
                    {
                        // A mismatch of the amount might be related to the number of boxes a label spans
                        // to check this, we search for the label in each bar model structure and just check the number
                        // of label indices it spans
                        // (We only care about the first label with a given value)
                        var expectedBarLabel : BarLabel = ((expectedLabelType == "h" || expectedLabelType == "n")) ? 
                        expected.getHorizontalBarLabelsByValue(expectedLabelValue)[0] : expected.getVerticalBarLabelsByValue(expectedLabelValue)[0];
                        var actualBarLabel : BarLabel = ((actualLabelType == "h" || actualLabelType == "n")) ? 
                        actual.getHorizontalBarLabelsByValue(expectedLabelValue)[0] : actual.getVerticalBarLabelsByValue(expectedLabelValue)[0];
                        
						var segmentsInExpected : Int = 0;
						var segmentsInActual : Int = 0;
                        if (actualLabelType == "h" || actualLabelType == "n") 
                        {
                            segmentsInExpected = expectedBarLabel.endSegmentIndex - expectedBarLabel.startSegmentIndex + 1;
                            segmentsInActual = actualBarLabel.endSegmentIndex - actualBarLabel.startSegmentIndex + 1;
                        }
                        else if (actualLabelType == "v") 
                        {
							function getNumSegmentsCoveredByVerticalLabel(label : BarLabel, barModelData : BarModelData) : Int
                            {
                                var i : Int = 0;
                                var numSegments : Int = 0;
                                for (i in label.startSegmentIndex...label.endSegmentIndex + 1){
                                    var segmentsInBarWhole : Int = barModelData.barWholes[i].barSegments.length;
                                    numSegments += segmentsInBarWhole;
                                }
                                return numSegments;
                            };
                            segmentsInExpected = getNumSegmentsCoveredByVerticalLabel(expectedBarLabel, expected);
                            segmentsInActual = getNumSegmentsCoveredByVerticalLabel(actualBarLabel, actual);
                        }
                        
                        if (segmentsInExpected > segmentsInActual) 
                        {
                            // The answer from the user appears to cover too few boxes
                            incorrectLabelRatioBuffer.push({
                                        type : LABEL_TOO_LITTLE,
                                        value : expectedLabelValue,
                                    });
                        }
                        else if (segmentsInExpected < segmentsInActual) 
                        {
                            // The answer from the user appears to cover too many boxes
                            incorrectLabelRatioBuffer.push({
                                        type : LABEL_TOO_MUCH,
                                        value : expectedLabelValue,
                                    });
                        }
                    }
					
					// Check if the overall ratio of a label matches with that of the reference  
                    var expectedTotalRatio : Float = Reflect.field(expectedDecomposed.labelToRatioOfTotalBoxes, expectedLabelValue);
                    var actualTotalRatio : Float = Reflect.field(actualDecomposed.labelToRatioOfTotalBoxes, expectedLabelValue);
                    if (Math.abs(expectedTotalRatio - actualTotalRatio) > ERROR) 
                    {
                        incorrectLabelRatioBuffer.push({
                                    type : LABEL_RATIO_INCORRECT,
                                    value : expectedLabelValue,
                                });
                    }
                }
                // User incorrectly used term as comparison
                else if (actualLabelType == "c" || expectedLabelType == "c") 
                {
                    incorrectLabelTypeBuffer.push({
                                type : INCORRECT_COMPARE,
                                value : expectedLabelValue,
                            });
                }
            }
        }
		
		// Checking for unexected label. This occurs primarily for bar model problems dealing with groups where the number of  
        // groups is incorrectly used a label.
        for (actualLabelName in Reflect.fields(actualLabelToType))
        {
            if (!expectedLabelToType.exists(actualLabelName)) 
            {
                incorrectLabelTypeBuffer.push({
                            type : INCORRECT_EXTRA_NAME,
                            value : actualLabelName,
                        });
            }
        }
		
		// Checking for the tallies of the number of boxes  
		// Purely checking for too many or too few boxes
		// The hint would need to be able to find the box that matches the normalized
		// value, we can highlight that piece to explain there are too few or too many 
		// of that value
		function getTotalSegmentTally(segmentTally : Array<Int>) : Int
        {
            var total : Int = 0;
            for (tally in segmentTally)
            {
                total += tally;
            }
            return total;
        };
        var expectedTotalSegments : Int = getTotalSegmentTally(expectedDecomposed.normalizedBarSegmentValueTally);
        var expectedDifferentSegmentValues : Int = expectedDecomposed.normalizedBarSegmentValueTally.length;
        var actualTotalSegments : Int = getTotalSegmentTally(actualDecomposed.normalizedBarSegmentValueTally);
        var actualDifferentSegmentValues : Int = actualDecomposed.normalizedBarSegmentValueTally.length;
        
        if (expectedTotalSegments != actualTotalSegments) 
        {
            incorrectSegmentsCountBuffer.push({
                        type : SEGMENT_TALLY_DIFFERENT,
                        expected : expectedTotalSegments,
                        actual : actualTotalSegments,
                    });
        }
        
        if (expectedDifferentSegmentValues != actualDifferentSegmentValues) 
        {
            incorrectSegmentsCountBuffer.push({
                        type : SEGMENT_UNIQUE_RATIOS_DIFFERENT,
                        expected : expectedDifferentSegmentValues,
                        actual : actualDifferentSegmentValues,
                    });
        }
		
		// Iterate through each buffer  
        function addToMismatch(itemObject : Dynamic) : Void
        {
            mismatchData.push(itemObject);
        };
        
		Lambda.iter(missingLabelBuffer, addToMismatch);
		Lambda.iter(missingComparisonBuffer, addToMismatch);
		Lambda.iter(incorrectSegmentsCountBuffer, addToMismatch);
		Lambda.iter(incorrectLabelTypeBuffer, addToMismatch);
		Lambda.iter(incorrectLabelRatioBuffer, addToMismatch);
		
		// Each mismatch goes into an output list. The model with the fewest in the list is the
		// one we should target.
		// When processing the list we need a rule to determine which errors should be displayed
		// before others (one that will apply to all the models)
        return mismatchData;
    }
    
    // TODO: Fold this into pick mismatch function
    private static var MEASURING_TEXTFIELD : MeasuringTextField;
    public static function createHintFromMismatchData(pickedMismatch : Dynamic,
            characterController : HelperCharacterController,
            assetManager : AssetManager,
            mouseState : MouseState,
            textParser : TextParser,
            textViewFactory : TextViewFactory,
            textArea : TextAreaWidget,
            gameEngine : IGameEngine,
            characterStopX : Float,
            characterStopY : Float) : HintScript
    {
        // Check if this hint should be shown as a question.
        var showQuestion : Bool = pickedMismatch.exists("question") && pickedMismatch.question != null;
        if (showQuestion) 
        {
            pickedMismatch.descriptionContent = pickedMismatch.question.text;
        }
        
        var fontSize : Float = 16;
        var fontName : String = "Verdana";  //GameFonts.DEFAULT_FONT_NAME;  
        
        // Create the description
        // Add callout to the character
        var calloutBackgroundName : String = "thought_bubble";
        var measuringTexture : Texture = assetManager.getTexture(calloutBackgroundName);
        var paddingSide : Float = 20;
        var maxTextWidth : Float = measuringTexture.width - 2 * paddingSide;
        var paddingTop : Float = 50;
        var maxTextHeight : Float = measuringTexture.height - 2 * paddingTop;
        var contentXML : Xml = Xml.parse("<p></p>");
        contentXML.addChild(Xml.createPCData(pickedMismatch.descriptionContent));
        
        // Measure the text so we can set a font size that will cause everything to fit into the speech bubble
        // texture.
        if (MEASURING_TEXTFIELD == null) 
        {
            MEASURING_TEXTFIELD = new MeasuringTextField();
            MEASURING_TEXTFIELD.defaultTextFormat = new TextFormat(fontName, Std.int(fontSize), 0);
            MEASURING_TEXTFIELD.width = maxTextWidth;
            MEASURING_TEXTFIELD.height = maxTextHeight;
            MEASURING_TEXTFIELD.wordWrap = true;
        }
        
        MEASURING_TEXTFIELD.text = pickedMismatch.descriptionContent;
        if (MEASURING_TEXTFIELD.textWidth > MEASURING_TEXTFIELD.width || MEASURING_TEXTFIELD.textHeight > MEASURING_TEXTFIELD.height) 
        {
            fontSize = MEASURING_TEXTFIELD.resizeToDimensions(maxTextWidth, maxTextHeight, pickedMismatch.descriptionContent);
        }  // 'invisible' space so no stretching is needed.    // HACK: It appears the callout will always try to stretch to fit contents, we need to create  
        
        
        
        
        
        var calloutContent : DisplayObject = TextParserUtil.createTextViewFromXML(
                new Fast(contentXML),
                {
                    p : {
                        color : "0x000000",
                        fontName : fontName,
                        fontSize : fontSize,
                    }
                },
                maxTextWidth,
                textParser,
                textViewFactory
                );
        
        // If the hint data has been marked that it should link to a tip replay, we'll
        // need to add an extra button to the callout that goes to the tip
        var helpButton : Button = null;
		var tipName : String = null;
        if (pickedMismatch.exists("linkToTip")) 
        {
            tipName = pickedMismatch.linkToTip;
            
            var helpButtonTexture : Texture = assetManager.getTexture("help_icon");
            helpButton = new Button(helpButtonTexture);
            helpButton.scaleWhenOver = 1.1;
            helpButton.scaleWhenDown = 0.9;
            helpButton.x = (calloutContent.width - helpButtonTexture.width) * 0.5;
            helpButton.y = calloutContent.height;
            (try cast(calloutContent, DisplayObjectContainer) catch(e:Dynamic) null).addChild(helpButton);
        }
        
        function onLinkToTip() : Void
        {
            gameEngine.dispatchEventWith(GameEvent.LINK_TO_TIP, false, {
                        tipName : tipName
                    });
        };
        
        var outAnswerButtons : Array<Button> = new Array<Button>();
        if (showQuestion) 
        {
            calloutContent = HintCommonUtil.bindAnswersButtonsToCallout(
                            pickedMismatch.question.answers,
                            assetManager,
                            calloutContent,
                            outAnswerButtons);
        }  // All hints show the character  
        
        
        
        var pixelPerSecondVelocity : Float = 600;
        var characterId : String = ((Math.random() > 0.5)) ? "Cookie" : "Taco";
        var characterStopPoint : Point = new Point(characterStopX, characterStopY);
        var hintScriptToRun : HintScriptWithProcesses = new HintScriptWithProcesses(null, null, null, true);
        var moveProcess : MoveCharacterToProcess = new MoveCharacterToProcess(
        characterController, characterId, -100, 0, characterStopPoint.x, characterStopPoint.y, pixelPerSecondVelocity);
        hintScriptToRun.addProcess(moveProcess);
        var showCharacterTextProcess : ShowCharacterTextProcess = new ShowCharacterTextProcess(calloutContent, characterController, 
        characterId, assetManager);
        hintScriptToRun.addProcess(showCharacterTextProcess);
        if (showQuestion) 
        {
            var showQuestionProcess : DismissQuestionProcess = new DismissQuestionProcess(assetManager, gameEngine.getSprite(), 
            pickedMismatch.question, outAnswerButtons);
            hintScriptToRun.addProcess(showQuestionProcess);
        }
        else 
        {
            var dismissOnClickProcess : DismissCharacterOnClickProcess = new DismissCharacterOnClickProcess(characterController, 
            characterId, mouseState, helpButton, onLinkToTip);
            hintScriptToRun.addProcess(dismissOnClickProcess);
        }
        var removeDialogProcess : CustomVisitNode = new CustomVisitNode(characterController.removeDialogForCharacter, {
            id : characterId

        });
        hintScriptToRun.addProcess(removeDialogProcess);
        var moveAwayProcess : MoveCharacterToProcess = new MoveCharacterToProcess(
        characterController, characterId, Math.NaN, Math.NaN, -100, 380, pixelPerSecondVelocity);
        hintScriptToRun.addProcess(moveAwayProcess);
        var visibleProcess : CustomVisitNode = new CustomVisitNode(characterController.setCharacterVisible, {
            id : characterId,
            visible : false,

        });
        hintScriptToRun.addProcess(visibleProcess);
        
        // Create the process to smoothly delete this hint
        hintScriptToRun.addInterruptProcess(new CustomVisitNode(characterController.removeDialogForCharacter, {
                    id : characterId

                }));
        hintScriptToRun.addInterruptProcess(new MoveCharacterToProcess(
                characterController, characterId, Math.NaN, Math.NaN, -100, 380, 400));
        hintScriptToRun.addInterruptProcess(new CustomVisitNode(characterController.setCharacterVisible, {
                    id : characterId,
                    visible : false,

                }));
        
        // Make sure all these other process are added to index 1, otherwise the processes controlling the dismissal of
        // the character will block it and prevent them from being executed
        if (pickedMismatch.exists("highlightTextExpressionValue")) 
        {
            // translate the expression value to document ids
            // Also highlight the spot the text area with the missing label
            var expressionComponents : Array<Component> = textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var i : Int = 0;
            var documentIds : Array<String> = new Array<String>();
            for (i in 0...expressionComponents.length){
                var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                
                // Highlight the portion of the text matching a given expression value
                if (expressionComponent.expressionString == pickedMismatch.highlightTextExpressionValue) 
                {
                    documentIds.push(expressionComponent.entityId);
                }
            }  // Hack fit the highlight after the process to move the character into view is done.  
            
            
            
            var highlightTextProcess : HighlightTextProcess = new HighlightTextProcess(textArea, documentIds, 0x00FF00);
            hintScriptToRun.addProcess(highlightTextProcess, 1);
        }
        
        if (pickedMismatch.exists("highlightDocIds")) 
        {
            var docIdsToHighlight : Array<Dynamic> = pickedMismatch.highlightDocIds;
            var documentIds = new Array<String>();
            for (docId in docIdsToHighlight)
            {
                documentIds.push(docId);
            }
            var highlightTextProcess = new HighlightTextProcess(textArea, documentIds, 0x00FF00);
            hintScriptToRun.addProcess(highlightTextProcess, 1);
        }
        
        if (pickedMismatch.exists("highlightBarsThenTextFromDocIds")) 
        {
            var highlightColor : Int = ((pickedMismatch.exists("highlightBarsThenTextColor"))) ? 
            pickedMismatch.highlightBarsThenTextColor : 0x00FF00;
            var docIdsToHighlight = try cast(pickedMismatch.highlightBarsThenTextFromDocIds, Array<Dynamic>) catch (e : Dynamic) null;
            var documentIds = new Array<String>();
            for (docId in docIdsToHighlight)
            {
                documentIds.push(docId);
            }
            hintScriptToRun.addProcess(new HighlightBarModelThenTextProcess(textArea, 
                    try cast(gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null, 
                    documentIds, highlightColor), 1
                    );
        }
        
        if (pickedMismatch.exists("highlightBarModelArea") && pickedMismatch.highlightBarModelArea) 
        {
            var highlightColor = ((pickedMismatch.exists("highlightBarModelAreaColor"))) ? 
                    pickedMismatch.highlightBarModelAreaColor : 0x00FF00;
            hintScriptToRun.addProcess(new HighlightUiElementProcess(gameEngine, "barModelArea", highlightColor), 1);
        }
        
        if (pickedMismatch.exists("highlightValidateButton") && pickedMismatch.highlightValidateButton) 
        {
            var highlightColor = ((pickedMismatch.exists("highlightValidateButtonColor"))) ? 
                    pickedMismatch.highlightValidateButtonColor : 0x00FF00;
            hintScriptToRun.addProcess(new HighlightUiElementProcess(gameEngine, "validateButton", highlightColor), 1);
        }
		
		// Set serialized data so the hint details can be logged  
        hintScriptToRun.serializedHintData = pickedMismatch;
        
        return hintScriptToRun;
    }
    
    private static function bindAnswersButtonsToCallout(answersData : Array<Dynamic>,
            assetManager : AssetManager,
            originalDisplayContent : DisplayObject,
            outButtons : Array<Button>) : DisplayObject
    {
        var wrapper : Sprite = new Sprite();
        wrapper.addChild(originalDisplayContent);
        
        // Add buttons for each of the potential answers
        var measuringTextField : MeasuringTextField = new MeasuringTextField();
        var buttonTextFormat : TextFormat = new TextFormat("Verdana", 12, 0xFFFFFF);
        measuringTextField.defaultTextFormat = buttonTextFormat;
        var gap : Float = 10;
        var sidePadding : Float = 15;
        var buttonHeight : Float = 0.0;
        var buttonWidth : Float = 0.0;
        var totalButtonWidthOfRow : Float = 0;
        
        var buttonContainer : Sprite = new Sprite();
        var buttonXOffset : Float = 0;
        var answerIndex : Int = 0;
        for (answer in answersData)
        {
            measuringTextField.text = answer.name;
            buttonWidth = measuringTextField.textWidth + 2 * sidePadding;
            buttonHeight = measuringTextField.textHeight + sidePadding;
            
            var button : Button = WidgetUtil.createGenericColoredButton(assetManager, XColor.ROYAL_BLUE, answer.name,
                    buttonTextFormat);
            button.x = buttonXOffset;
            button.y = 0;
            button.width = buttonWidth;
            button.height = buttonHeight;
            buttonContainer.addChild(button);
            buttonXOffset += buttonWidth + gap;
            answerIndex++;
            
            totalButtonWidthOfRow += buttonWidth;
            outButtons.push(button);
        }
        totalButtonWidthOfRow += (answersData.length - 1) * gap;
        
        if (originalDisplayContent.width > totalButtonWidthOfRow) 
        {
            buttonContainer.x = (originalDisplayContent.width - totalButtonWidthOfRow) * 0.5;
        }
        else 
        {
            originalDisplayContent.x = (totalButtonWidthOfRow - originalDisplayContent.width) * 0.5;
        }
        buttonContainer.y = originalDisplayContent.height + gap;
        wrapper.addChild(buttonContainer);
        
        return wrapper;
    }
}
