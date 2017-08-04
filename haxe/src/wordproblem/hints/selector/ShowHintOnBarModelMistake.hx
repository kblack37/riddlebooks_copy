package wordproblem.hints.selector;


import haxe.xml.Fast;
import starling.display.DisplayObject;
import starling.events.Event;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.BarModelTypes;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.model.DecomposedBarModelData;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.hints.HintCommonUtil;
import wordproblem.hints.HintScript;
import wordproblem.hints.HintSelectorNode;
import wordproblem.hints.scripts.TipsViewer;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.ValidateBarModelArea;

/**
 * This script handles showing various hints when the player incorrectly submits an answer for the bar model.
 * Note that the logic is hardwired to only work with levels that are of the generic bar model type,
 * the custom tutorial levels cannot re-use this structure.
 */
class ShowHintOnBarModelMistake extends HintSelectorNode
{
    /**
     * Each part of the code where a hint should be generated has a label id.
     * External hint data has no knowledge of these labels, instead they are based on
     * a separate id denoting.
     * 
     * This mapping is necessary because several of the hint logic flows re-used blocks of
     * code. Label ids are not unique.
     */
    private var m_labelToStepMap : Dynamic;
    
    private var m_defaultHintStorage : HintXMLStorage;
    private var m_customHintStorage : HintXMLStorage;
    
    /**
     * Have a dependency on the validate bar model script, as it contains the decomposed bar models to
     * compare against
     */
    private var m_validateBarModelArea : ValidateBarModelArea;
    
    private var m_barModelArea : BarModelAreaWidget;
    
    /**
     * As part of the player preferences, they can toggle on and off whether hints after a mistake
     * automatically show up
     */
    private var m_doShowHintsAfterMistake : Bool;
    
    /**
     * Need to read this to determine whether the hints this script is supposed to show should
     * even be displayed.
     */
    private var m_playerStatsAndSaveData : PlayerStatsAndSaveData;
    
    /**
     * Need to keep a reference to this because on disposal the game engine purges itself of widgets.
     * Still want to properly clean up the components attached to it though.
     */
    private var m_textArea : TextAreaWidget;
    
    private var m_characterController : HelperCharacterController;
    private var m_gameEngine : IGameEngine;
    private var m_assetManager : AssetManager;
    private var m_textParser : TextParser;
    private var m_textViewFactory : TextViewFactory;
    
    /**
     * Mapping from document id to an expression/term value
     * Relies on fact that document ids in a level can be directly mapped to elements in a
     * template of a bar model type. For example the doc id 'b1' refers to the number of
     * groups in any type 3a model.
     */
    private var m_documentIdToExpressionMap : Dynamic;
    
    /**
     * Per level we keep track of the names of actions performed by the player to adjust
     * hint content if we guess the user simply forgot how to perform an action.
     * 
     * Key is name of the action event, value is the times the player performed it.
     * The frequency is never reset while a level is running.
     * If a key does not exist, it means that action was never performed.
     */
    private var m_gestureToFrequencyPerformed : Dynamic;
    
    /**
     * Keep track of the number of times they submit an incorrect bar model.
     * The idea is that more incorrect submissions should lead to more specific hints.
     */
    private var m_numTimesSubmittedIncorrectModel : Int;
    
    // Similar to how the counter keeping track of times an incorrect model was submitted,
    // we break down mistake types into finer grain counters.
    // The purpose is if the user is frequently entering an incorrect pathway we want to gradually give them
    // more specific hints
    private var m_missingSumPartCounter : Int;
    private var m_missingSumLabelCounter : Int;
    private var m_missingLargerDifferencePartCounter : Int;
    private var m_missingSmallerDifferencePartCounter : Int;
    private var m_incorrectDifferenceCounter : Int;
    private var m_incorrectFractionLabel : Int;
    private var m_missingUnitCounter : Int;
    private var m_incorrectUnitAmountCounter : Int;
    private var m_wrongGroupsCounter : Int;
    private var m_incorrectGroupSumCounter : Int;
    
    /**
     * Count if the player has not discovered the second unknown in the two step problem
     */
    private var m_intermediateUnknownNotFoundCounter : Int;
    
    /**
     * Per level, there is a special super general hint that shows up if no bar model action
     * has been performed. Only should get shown once per level.
     */
    private var m_firstNoActionHintShown : Bool;
    
    /**
     * Count of the number of times the bar model specific hint that shows up when the area
     * is completely empty has be shown. The count lets us know when to stop showing that hint are to change what it says.
     */
    private var m_firstEmptyBarModelHintCounter : Int;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            playerStatesAndSaveData : PlayerStatsAndSaveData,
            validateBarModelArea : ValidateBarModelArea,
            characterController : HelperCharacterController,
            textParser : TextParser,
            textViewFactory : TextViewFactory,
            barModelType : String,
            customHintData : Fast)
    {
        super();
        // TODO: Load up the dummy xml, which should contain ALL the hint logic paths
        // The bar model type governs which part of the xml should be loaded
        // Create a mapping from label id to the actual hint elements
        var defaultHintsXml : Xml = assetManager.getXml("default_barmodel_hints");
		var labelIdToHintXmlElement : Dynamic = { };
		if (defaultHintsXml != null) {
			var barModelHintBlocks = defaultHintsXml.elementsNamed("barmodelhints");
			for (barModelHintBlock in barModelHintBlocks) {
				var hintElements = barModelHintBlock.elementsNamed("hint");
				for (hintElement in hintElements) {
					// Create the mapping from label to step based on the selected block
					var labelId = hintElement.get("labelId");
					Reflect.setField(labelIdToHintXmlElement, labelId, hintElement);
				}
			}
		}
		
		// TODO:  
		// New strategy.
		// Mapping from label id to step is based on the bar model type.
		// Look through the xml data file to figure out what mapping is appropriate.
		// This mapping will also allow us to rebuild a dummy xml representing default hint that looks like
        // any external hinting structure
        var defaultHintXmlToBuild : Xml = Xml.parse("<barmodelhints/>");
		if (defaultHintsXml != null) {
			var labelToStepMappings = defaultHintsXml.elementsNamed("mapping");
			m_labelToStepMap = { };
			for (labelToStepMapping in labelToStepMappings) {
				var mappingBarModelTypes : String = labelToStepMapping.get("type");
				var typesInMapping : Array<String> = mappingBarModelTypes.split(",");
				if (Lambda.indexOf(typesInMapping, barModelType) > -1) 
				{
					var labelToStepElements = labelToStepMapping.elementsNamed("label");
					for (labelToStepElement in labelToStepElements) {
						var labelId : String = labelToStepElement.get("id");
						var stepId : Int = Std.parseInt(labelToStepElement.get("step"));
						Reflect.setField(m_labelToStepMap, labelId, stepId);
						
						var hintXmlCopy : Xml = Xml.parse((try cast(Reflect.field(labelIdToHintXmlElement, labelId), Fast) catch(e:Dynamic) null).x.toString());
						hintXmlCopy.set("step", Std.string(stepId));
						defaultHintXmlToBuild.addChild(hintXmlCopy);
					}
					break;
				}
			}
		}
        
        m_defaultHintStorage = new HintXMLStorage(new Fast(defaultHintXmlToBuild));
        
        // Create custom hint block if given that data
        if (customHintData != null) 
        {
            m_customHintStorage = new HintXMLStorage(customHintData);
        }
        
        m_gameEngine = gameEngine;
        m_assetManager = assetManager;
        m_characterController = characterController;
        m_playerStatsAndSaveData = playerStatesAndSaveData;
        m_validateBarModelArea = validateBarModelArea;
        m_textParser = textParser;
        m_textViewFactory = textViewFactory;
        m_barModelArea = try cast(gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_textArea = try cast(gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_gestureToFrequencyPerformed = { };
        
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, smoothlyRemovePreviousHint);
        
        // HACK:
        // This is assuming that the level has already been constructed.
        // Bind listeners to view the frequency of the type of actions performed by the player
        // this can be used by some hints to guess if the user simply doesn't know HOW to do something
        // and adjust the content to explain the gesture
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, onBarModelGesturePerformed);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR, onBarModelGesturePerformed);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.MULTIPLY_BAR, onBarModelGesturePerformed);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL, onBarModelGesturePerformed);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL, onBarModelGesturePerformed);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR, onBarModelGesturePerformed);
        m_numTimesSubmittedIncorrectModel = 0;
        
        m_missingSumPartCounter = 0;
        m_missingSumLabelCounter = 0;
        m_missingLargerDifferencePartCounter = 0;
        m_missingSmallerDifferencePartCounter = 0;
        m_incorrectDifferenceCounter = 0;
        m_incorrectFractionLabel = 0;
        m_missingUnitCounter = 0;
        m_incorrectUnitAmountCounter = 0;
        m_wrongGroupsCounter = 0;
        m_intermediateUnknownNotFoundCounter = 0;
        m_incorrectGroupSumCounter = 0;
        
        m_firstNoActionHintShown = false;
        m_firstEmptyBarModelHintCounter = 0;
        
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, onBarModelCorrect);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, onBarModelIncorrect);
        
        // Assume that current level data has been set up
        restoreTempHintState();
    }
    
    public static inline var SAVE_KEY_SHOW_HINT_SAVED_COUNTERS : String = "show_hint_saved_counters";
    
    // Save the counters that are used to pick different hints in a level
    private function saveTempHintState() : Void
    {
        var saveDataCounters : Dynamic = {
            levelId : m_gameEngine.getCurrentLevel().getId(),
            missingSumPart : m_missingSumPartCounter,
            missingSumLabel : m_missingSumLabelCounter,
            missingLargerDifferencePart : m_missingLargerDifferencePartCounter,
            missingSmallerDifferencePart : m_missingSmallerDifferencePartCounter,
            incorrectDifference : m_incorrectDifferenceCounter,
            incorrectFractionLabel : m_incorrectFractionLabel,
            missingUnit : m_missingUnitCounter,
            incorrectUnitAmount : m_incorrectUnitAmountCounter,
            wrongGroups : m_wrongGroupsCounter,
            intermediateUnknownNotFound : m_intermediateUnknownNotFoundCounter,
            incorrectGroupSum : m_incorrectGroupSumCounter,
            numTimesSubmittedIncorrect : m_numTimesSubmittedIncorrectModel,
            firstNoActionHint : m_firstNoActionHintShown,
            firstEmptyBarModelHintCounter : m_firstEmptyBarModelHintCounter,

        };
        m_playerStatsAndSaveData.setPlayerDecision(SAVE_KEY_SHOW_HINT_SAVED_COUNTERS, saveDataCounters);
    }
    
    // Restore the counters at the start of the level
    private function restoreTempHintState() : Void
    {
        var saveCounters : Dynamic = m_playerStatsAndSaveData.getPlayerDecision(SAVE_KEY_SHOW_HINT_SAVED_COUNTERS);
        if (saveCounters != null) 
        {
            if (saveCounters.levelId == m_gameEngine.getCurrentLevel().getId()) 
            {
                m_missingSumPartCounter = saveCounters.missingSumPart;
                m_missingSumLabelCounter = saveCounters.missingSumLabel;
                m_missingLargerDifferencePartCounter = saveCounters.missingLargerDifferencePart;
                m_missingSmallerDifferencePartCounter = saveCounters.missingSmallerDifferencePart;
                m_incorrectDifferenceCounter = saveCounters.incorrectDifference;
                m_incorrectFractionLabel = saveCounters.incorrectFractionLabel;
                m_missingUnitCounter = saveCounters.missingUnit;
                m_incorrectUnitAmountCounter = saveCounters.incorrectUnitAmount;
                m_wrongGroupsCounter = saveCounters.wrongGroups;
                m_intermediateUnknownNotFoundCounter = saveCounters.intermediateUnknownNotFound;
                m_incorrectGroupSumCounter = saveCounters.incorrectGroupSum;
                m_numTimesSubmittedIncorrectModel = saveCounters.numTimesSubmittedIncorrect;
                m_firstNoActionHintShown = saveCounters.firstNoActionHint;
                m_firstEmptyBarModelHintCounter = saveCounters.firstEmptyBarModelHintCounter;
            }
            else 
            {
                // If level changed from the previous one then clear state
                m_playerStatsAndSaveData.setPlayerDecision(SAVE_KEY_SHOW_HINT_SAVED_COUNTERS, null);
            }
        }
    }
    
    override public function getHint() : HintScript
    {
        var hintData : Dynamic = generateBarModelMistakeHint();
        if (hintData == null) 
        {
            hintData = {
                        descriptionContent : "If you think you have the right answer, press the check!"

                    };
        }
        
        var hintToRun : HintScript = HintCommonUtil.createHintFromMismatchData(
                hintData,
                m_characterController,
                m_assetManager,
                m_gameEngine.getMouseState(),
                m_textParser, m_textViewFactory, m_textArea, m_gameEngine,
                200, 300
                );
        return hintToRun;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        // Delete all the action listeners
        m_gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, onBarModelGesturePerformed);
        m_gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR, onBarModelGesturePerformed);
        m_gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.MULTIPLY_BAR, onBarModelGesturePerformed);
        m_gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL, onBarModelGesturePerformed);
        m_gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL, onBarModelGesturePerformed);
        m_gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR, onBarModelGesturePerformed);
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, onBarModelCorrect);
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, onBarModelIncorrect);
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, smoothlyRemovePreviousHint);
    }
    
    private function onBarModelGesturePerformed(event : Event) : Void
    {
        var gestureName : String = event.type;
        if (!m_gestureToFrequencyPerformed.exists(gestureName)) 
        {
            Reflect.setField(m_gestureToFrequencyPerformed, gestureName, 0);
        }
		Reflect.setField(m_gestureToFrequencyPerformed, gestureName, Reflect.field(m_gestureToFrequencyPerformed, gestureName) + 1);
    }
    
    private function onBarModelCorrect() : Void
    {
        // If a correct bar model was selected, clear the hint as well
        smoothlyRemovePreviousHint();
    }
    
    private function smoothlyRemovePreviousHint() : Void
    {
        m_gameEngine.dispatchEventWith(GameEvent.REMOVE_HINT, false, {
                    smoothlyRemove : true
                });
    }
    
    private function onBarModelIncorrect() : Void
    {
        m_numTimesSubmittedIncorrectModel++;
    }
    
    public static function getDocumentIdToExpressionMap(textArea : TextAreaWidget) : Dynamic
    {
        var expressionComponents : Array<Component> = textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var i : Int = 0;
        var documentIdToExpressionMap : Dynamic = { };
        for (i in 0...expressionComponents.length){
            var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
			Reflect.setField(documentIdToExpressionMap, expressionComponent.entityId, expressionComponent.expressionString);
        }
        
        return documentIdToExpressionMap;
    }
    
    private function generateBarModelMistakeHint() : Dynamic
    {
        if (m_documentIdToExpressionMap == null) 
        {
            m_documentIdToExpressionMap = getDocumentIdToExpressionMap(m_textArea);
        }  // Do not not try to create a hint if the bar model is correct  
        
        
        
        var playerBarModelSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
		var nextMismatchToShow : Dynamic = { };
        if (playerBarModelSnapshot != null && !m_validateBarModelArea.getCurrentModelMatchesReference()) 
        {
            // Relace alias values in the given model (treat a set of values as one common one)
            playerBarModelSnapshot.replaceAllAliasValues(m_validateBarModelArea.getAliasValuesToTerms());
            var decomposedPlayerBarModel : DecomposedBarModelData = new DecomposedBarModelData(playerBarModelSnapshot);
            
            // If the user has not performed any relavant bar model action
            var numBarModelGesturesPerformed : Int = 0;
            for (gestureName in Reflect.fields(m_gestureToFrequencyPerformed))
            {
                numBarModelGesturesPerformed += Std.parseInt(Reflect.field(m_gestureToFrequencyPerformed, gestureName));
            }
            
            if (numBarModelGesturesPerformed == 0 && !m_firstNoActionHintShown) 
            {
                m_firstNoActionHintShown = true;
                nextMismatchToShow = {
                            descriptionContent : "Is this problem about addition, subtraction, multiplication, or division?"
                        };
            }
            else 
            {
                var nextMismatchToShow : Dynamic = getHighestPriorityDeepMismatch(playerBarModelSnapshot, decomposedPlayerBarModel);
                if (nextMismatchToShow == null) 
                {
                    nextMismatchToShow = HintCommonUtil.getHighestPriorityShallowMismatch(
                                    playerBarModelSnapshot,
                                    decomposedPlayerBarModel,
                                    m_validateBarModelArea.getReferenceModels(),
                                    m_validateBarModelArea.getDecomposedReferenceModels());
                }
            }
        }
		
		// HACKY: Save counter state after every request  
        saveTempHintState();
        
        return nextMismatchToShow;
    }
    
    /*
		Common condition checks
    
    The trick to reduce code duplication, any type that looks the same except for the names
    being rearranged can use the same logic block
		*/
    private function getHighestPriorityDeepMismatch(userBarModelData : BarModelData,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        // TODO:
        // Some types can be represented with multiple target templates.
        // Have a single fixed template to compare against is not ideal in all situations.
        // The might have a different role in mind for a term than what is expected in a particular answer and
        // that role that might not match with one answer may work perfectly fine for another answer
        
        // All comments are the implicit mapping from doc id in the level
        // an element in the matching bar model template (see pictures used to make the reference model)
        var mistmatchData : Dynamic = null;
        var barModelType : String = m_gameEngine.getCurrentLevel().getBarModelType();
        if (barModelType == BarModelTypes.TYPE_1A) 
        {
            // b1 = b (part of sum), a1 = a (part of sum), unk = ? (total)
            mistmatchData = validatePartsAddToSum(Reflect.field(m_documentIdToExpressionMap, "unk"), userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_1B || barModelType == BarModelTypes.TYPE_2E) 
        {
            // b1 = b (total), a1 = a (part of sum), unk = ? (part of sum)
            mistmatchData = validateDifferenceBetweenParts("b", "a", Reflect.field(m_documentIdToExpressionMap, "unk"), userBarModelData, userDecomposedModel);
        }
        // All Type2 problems can be changed to a sum model or have the smaller value and difference swapped out
        else if (barModelType == BarModelTypes.TYPE_2A) 
        {
            // b1 = b (larger value), a1 = a (smaller value), unk = ? (difference)
            mistmatchData = validateDifferenceBetweenParts("b", "a", Reflect.field(m_documentIdToExpressionMap, "unk"), userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_2B) 
        {
            // b1 = b (part of sum), a1 = a (part of sum), unk = ? (total)
            mistmatchData = validatePartsAddToSum(Reflect.field(m_documentIdToExpressionMap, "unk"), userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_2C) 
        {
            // b1 = b (larger value), a1 = a (difference), unk = ? (smaller value)
            mistmatchData = validateDifferenceBetweenParts("b", "unk", Reflect.field(m_documentIdToExpressionMap, "a1"), userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_2D) 
        {
            // b1 = b (difference), a1 = a (smaller value), unk = ? (larger value)
            mistmatchData = validateDifferenceBetweenParts("unk", "a", Reflect.field(m_documentIdToExpressionMap, "b1"), userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_3A) 
        {
            // b1 = b (num groups), a1 = a (value one groups), unk = ? (sum of group)
            // Check if equal sized groups
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"), false, true, null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_3B) 
        {
            // b1 = b (sum of groups), a1 = a (num groups), unk = ? (value one group)
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1")),
                            Reflect.field(m_documentIdToExpressionMap, "b1"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            false, true, null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_4A) 
        {
            // unk = ? (sum of groups), a1 = a (value of unit), b1 = b (num groups)
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            true, false, null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_4B) 
        {
            // unk = ? (value of unit), a1 = a (sum of groups), b1 = b (num groups)
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            true, false, null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_4C) 
        {
            // unk = ? (difference), a1 = a (value of unit), b1 = b (num groups)
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            null,
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            true, false,
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_4D) 
        {
            // unk = ? (sum of group), a1 = a (value of unit), b1 = b (num groups)
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            true, true, null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_4E) 
        {
            // unk = ? (value of unit), a1 = a (difference), b1 = b (num groups)
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            null,
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            true, false,
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_4F) 
        {
            // unk = ? (value of unit), a1 = a (total), b1 = b (num groups)
            mistmatchData = validateGroupsEqualSum(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            true, true, null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5A) 
        {
            // unk = ? (total), a1 = a (larger part), b1 = b (difference) c = c (smaller part)
            mistmatchData = validateSumAndDifferenceWithIntermediate(Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "b1"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5B) 
        {
            // unk = ? (total), a1 = a (smaller part), b1 = b (difference) c = c (larger part)
            mistmatchData = validateSumAndDifferenceWithIntermediate(Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "b1"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5C) 
        {
            // unk = ? (difference), a1 = a (larger part), b1 = b (total) c = c (smaller part)
            mistmatchData = validateSumAndDifferenceWithIntermediate(Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "b1"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5D) 
        {
            // unk = ? (smaller part), a1 = a (difference), b1 = b (total) c = c (larger part)
            mistmatchData = validateSumAndDifferenceWithIntermediate(Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "b1"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5E) 
        {
            // unk = ? (larger part), a1 = a (difference), b1 = b (total) c = c (smaller part)
            mistmatchData = validateSumAndDifferenceWithIntermediate(Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "b1"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5F) 
        {
            // unk = ? (difference), a1 = a (sum of groups), b1 = b (number of groups) c = c (unit value)
            mistmatchData = validateSumOfGroupsWithIntermediate(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "a1"), null,
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5G) 
        {
            // unk = ? (total), a1 = a (sum of groups), b1 = b (number of groups) c = c (unit value)
            mistmatchData = validateSumOfGroupsWithIntermediate(Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"), null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5H) 
        {
            // unk = ? (sum of groups), a1 = a (difference), b1 = b (number of groups) c = c (unit value)
            mistmatchData = validateSumOfGroupsWithIntermediate(Std.parseInt(
                                    Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            null,
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5I) 
        {
            // unk = ? (total), a1 = a (difference), b1 = b (number of groups) c = c (unit value)
            mistmatchData = validateSumOfGroupsWithIntermediate(
                            Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            null,
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5J) 
        {
            // unk = ? (sum of groups), a1 = a (total), b1 = b (number of groups) c = c (unit value)
            mistmatchData = validateSumOfGroupsWithIntermediate(
                            Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            null,
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_5K) 
        {
            // unk = ? (difference), a1 = a (total), b1 = b (number of groups) c = c (unit value)
            mistmatchData = validateSumOfGroupsWithIntermediate(
                            Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "b1")),
                            null,
                            Reflect.field(m_documentIdToExpressionMap, "a1"),
                            Reflect.field(m_documentIdToExpressionMap, "c"),
                            Reflect.field(m_documentIdToExpressionMap, "unk"),
                            userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_6A) 
        {
            // unk = ? (sum of shaded), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (total)
            var numGroupsTotal : Int = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsShaded : Int = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded : Int = numGroupsTotal - numGroupsShaded;
            mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "b1"), Reflect.field(m_documentIdToExpressionMap, "unk"), null, null, userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_6B) 
        {
            // unk = ? (sum of unshaded), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (total)
            var numGroupsTotal = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = numGroupsTotal - numGroupsShaded;
            mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "b1"), null, Reflect.field(m_documentIdToExpressionMap, "unk"), null, userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_6C) 
        {
            // unk = ? (total), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (sum of shaded)
            var numGroupsTotal = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = numGroupsTotal - numGroupsShaded;
            mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "unk"), Reflect.field(m_documentIdToExpressionMap, "b1"), null, null, userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_6D) 
        {
            // unk = ? (sum of unshaded), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (sum of shaded)
            var numGroupsTotal = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = numGroupsTotal - numGroupsShaded;
            mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, Reflect.field(m_documentIdToExpressionMap, "b1"), Reflect.field(m_documentIdToExpressionMap, "unk"), null, userBarModelData, userDecomposedModel);
        }
        // An important distinguishing factor between type 6 and type 7 problems is that in type 7
        // there are two different types of objects, one of which represents the 'whole' and the other type a fraction of that 'whole'
        // Thus the total number of groups is not as clear, it is the numerator of the sum of fraction + whole with the fixed denomator
        else if (barModelType == BarModelTypes.TYPE_7A) 
        {
            // unk = ? (sum of unshaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (sum of shaded)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, Reflect.field(m_documentIdToExpressionMap, "b1"), Reflect.field(m_documentIdToExpressionMap, "unk"), null, userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7B) 
        {
            // unk = ? (total), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (sum of shaded)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "unk"), Reflect.field(m_documentIdToExpressionMap, "b1"), null, null, userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7C) 
        {
            // unk = ? (difference), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (sum of shaded)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, Reflect.field(m_documentIdToExpressionMap, "b1"), null, Reflect.field(m_documentIdToExpressionMap, "unk"), userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7D_1) 
        {
            // unk = ? (sum of unshaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (total)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "b1"), null, Reflect.field(m_documentIdToExpressionMap, "unk"), null, userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7D_2) 
        {
            // unk = ? (sum of shaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (total)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "b1"), Reflect.field(m_documentIdToExpressionMap, "unk"), null, null, userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7E) 
        {
            // unk = ? (difference), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (total)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "b1"), null, null, Reflect.field(m_documentIdToExpressionMap, "unk"), userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7F_1) 
        {
            // unk = ? (sum of unshaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (difference)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, null, Reflect.field(m_documentIdToExpressionMap, "unk"), Reflect.field(m_documentIdToExpressionMap, "b1"), userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7F_2) 
        {
            // unk = ? (sum of shaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (difference)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, Reflect.field(m_documentIdToExpressionMap, "unk"), null, Reflect.field(m_documentIdToExpressionMap, "b1"), userBarModelData, userDecomposedModel);
        }
        else if (barModelType == BarModelTypes.TYPE_7G) 
        {
            // unk = ? (total), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (difference)
            var numGroupsShaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a1"));
            var numGroupsUnshaded = Std.parseInt(Reflect.field(m_documentIdToExpressionMap, "a2"));
            var numGroupsTotal = numGroupsShaded + numGroupsUnshaded;
            mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, Reflect.field(m_documentIdToExpressionMap, "unk"), null, null, Reflect.field(m_documentIdToExpressionMap, "b1"), userBarModelData, userDecomposedModel);
        }
        
        return mistmatchData;
    }
    
    /**
     * Bar model types based on several different sized parts equaling a sum value
     */
    private function validatePartsAddToSum(sumValue : String,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        if (userDecomposedModel.numBarWholes == 0) 
        {
            var labelName : String = "PartsAddToSumA";
            mismatchData = getHintFromLabel(labelName, null);
        }  // Assume parts of the sum are all other expression values not equal to the sum value  
        
        
        
        var partsInSumValues : Array<String> = new Array<String>();
        for (documentId in Reflect.fields(m_documentIdToExpressionMap))
        {
            var expressionValue : String = Reflect.field(m_documentIdToExpressionMap, documentId);
            if (expressionValue != sumValue) 
            {
                partsInSumValues.push(expressionValue);
            }
        }  // If not the user needs to add them.    // Are all parts in the sum present?    // what are all the parts being added together AND what value represents the sum.    // For the sum related model the hints we care about relate to making sure the user understands  
        
        
        
        
        
        
        
        
        
        
        var missingLabelInSum : String = getFirstMissingLabelFromModel(partsInSumValues, userDecomposedModel);
        if (missingLabelInSum != null && mismatchData == null) 
        {
            // For custom hints, we are interested in what bar model doc ids have been added
            var docIdsExistingAsPartOfSum : Array<Dynamic> = [];
            for (existingLabelValue in Reflect.fields(userDecomposedModel.labelValueToType))
            {
                var labelType : String = Reflect.field(userDecomposedModel.labelValueToType, existingLabelValue);
                if (labelType == "n") 
                {
                    for (docId in Reflect.fields(m_documentIdToExpressionMap))
                    {
                        if (existingLabelValue == Reflect.field(m_documentIdToExpressionMap, docId)) 
                        {
                            docIdsExistingAsPartOfSum.push(docId);
                        }
                    }
                }
            }
            var filterData : Dynamic = {
                existingLabelParts : docIdsExistingAsPartOfSum

            };
            
            m_missingSumPartCounter++;
            
			var labelName : String = null;
            if (m_missingSumPartCounter > 2) 
            {
                labelName = "PartsAddToSumB";
                mismatchData = getHintFromLabel(labelName, [missingLabelInSum], filterData);
            }
            else if (m_missingSumPartCounter > 1) 
            {
                labelName = "PartsAddToSumC";
                mismatchData = getHintFromLabel(labelName, [missingLabelInSum], filterData);
            }
            else 
            {
                labelName = "PartsAddToSumD";
                mismatchData = getHintFromLabel(labelName, [missingLabelInSum], filterData);
            }
        }
		
		// The sum should be a label spanning across all the added values, first check that exists  
        // If it does, also check that it spans the value 
        if (mismatchData == null) 
        {
            mismatchData = generateGenericMissingSumHints(sumValue, userDecomposedModel);
        }  
		
		// Generate hint if the total is present but is used in the wrong way  
        if (mismatchData == null) 
        {
            var labelAmountMuliplier : Array<Int> = new Array<Int>();
            for (partInSum in partsInSumValues)
            {
                labelAmountMuliplier.push(1);
            }
            
            if (!checkLabelSumOfOtherLabels(sumValue, partsInSumValues, labelAmountMuliplier, userDecomposedModel)) 
            {
                var labelName = "PartsAddToSumE";
                mismatchData = getHintFromLabel(labelName, [sumValue]);
            }
        }
        
        return mismatchData;
    }
    
    /**
     * Since each larger or smaller piece can be composed of several parts, a prefix is necessary
     * to figure out what composes each piece
     */
    private function validateDifferenceBetweenParts(largerValuePrefix : String,
            smallerValuePrefix : String,
            differenceValue : String,
            userBarModelData : BarModelData,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        // Figure out the values that compose both the larger and smaller parts
        var partsInLarger : Array<String> = new Array<String>();
        var partsInSmaller : Array<String> = new Array<String>();
        for (documentId in Reflect.fields(m_documentIdToExpressionMap))
        {
            var expressionValue : String = Reflect.field(m_documentIdToExpressionMap, documentId);
            if (documentId.indexOf(largerValuePrefix) == 0) 
            {
                partsInLarger.push(expressionValue);
            }
            else if (documentId.indexOf(smallerValuePrefix) == 0) 
            {
                partsInSmaller.push(expressionValue);
            }
        }
        
        if (userDecomposedModel.numBarWholes == 0) 
        {
            var labelId : String = "DifferenceBetweenPartsA";
            mismatchData = getHintFromLabel(labelId, null);
        }  // Make sure the smaller values have been added    // Make sure the larger values have been added    // and then identifying the differences between them.    // For simple difference related models we care about asking for the larger and smaller values  
        
        
        
        
        
        
        
        
        
        if (mismatchData == null) 
        {
            var missingLabelInSmaller : String = getFirstMissingLabelFromModel(partsInSmaller, userDecomposedModel);
            var missingLabelInLarger : String = getFirstMissingLabelFromModel(partsInLarger, userDecomposedModel);
            mismatchData = generateGenericMissingPartsOfDifference(missingLabelInLarger, missingLabelInSmaller, userDecomposedModel);
        }  // The player needs to know how the difference gesture looks like    // Due to game mechanics, it necessary for the values to be on separate lines    // Make sure a difference with the specified value has been added  
        
        
        
        
        
        
        
        if (mismatchData == null) 
        {
            mismatchData = generateGenericDifferenceHints(differenceValue, userDecomposedModel);
        }
        
        return mismatchData;
    }
    
    // Helper used by the validate functions
    /**
     *
     * @param useHorizontalLabelForSum
     *      If true, hints should recommend creating a label spanning horizontally to indicate a sum
     *      where applicable. If false a vertical label should be recommended.
     */
    private function generateGenericMissingSumHints(totalValue : String,
            userDecomposedModel : DecomposedBarModelData,
            useHorizontalLabelForSum : Bool = true) : Dynamic
    {
        var mismatchData : Dynamic = null;
        if (!userDecomposedModel.labelValueToType.exists(totalValue)) 
        {
            // Have tried to add a label spanning a sum of boxes
            var timesAddedHorizontalLabel : Int = ((m_gestureToFrequencyPerformed.exists(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL))) ? Reflect.field(m_gestureToFrequencyPerformed, AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL) : 0;
            var timesAddedVerticalLabel : Int = ((m_gestureToFrequencyPerformed.exists(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL))) ? Reflect.field(m_gestureToFrequencyPerformed, AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL) : 0;
            if (timesAddedHorizontalLabel + timesAddedVerticalLabel == 0 && m_missingSumLabelCounter > 0) 
            {
                var labelName : String = "GenericMissingSumHintsA";
				var hintParams : Array<Dynamic> = null;
                if (useHorizontalLabelForSum) 
                {
                    hintParams = [TipsViewer.NAME_MANY_BOXES];
                }
                else 
                {
                    hintParams = [TipsViewer.NAME_MANY_BOXES_LINES];
                }
                mismatchData = getHintFromLabel(labelName, hintParams);
            }
            
            if (mismatchData == null) 
            {
                m_missingSumLabelCounter++;
                
                var hintParams = null;
				var labelName : String = null;
                if (m_missingSumLabelCounter > 2) 
                {
                    labelName = "GenericMissingSumHintsB";
                    hintParams = [totalValue];
                }
                else if (m_missingSumLabelCounter > 1) 
                {
                    labelName = "GenericMissingSumHintsC";
                }
                else 
                {
                    if (Reflect.field(m_documentIdToExpressionMap, "unk") == totalValue) 
                    {
                        labelName = "GenericMissingSumHintsD";
                    }
                    else 
                    {
                        labelName = "GenericMissingSumHintsE";
                    }
                }
                
                mismatchData = getHintFromLabel(labelName, hintParams);
            }
        }
        
        return mismatchData;
    }
    
    private function generateGenericMissingPartsOfDifference(missingLargerValue : String,
            missingSmallerValue : String,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        if (missingLargerValue != null && !userDecomposedModel.labelValueToType.exists(missingLargerValue)) 
        {
            m_missingLargerDifferencePartCounter++;
            
            if (m_missingLargerDifferencePartCounter > 2) 
            {
                var labelId : String = "GenericMissingPartsOfDifferenceA";
                mismatchData = getHintFromLabel(labelId, [missingLargerValue]);
            }
            else if (m_missingLargerDifferencePartCounter > 1) 
            {
                var labelId = "GenericMissingPartsOfDifferenceB";
                mismatchData = getHintFromLabel(labelId, null);
            }
            else 
            {
                var labelId = "GenericMissingPartsOfDifferenceC";
                mismatchData = getHintFromLabel(labelId, null);
            }
        }
        
        if (mismatchData == null && missingSmallerValue != null && !userDecomposedModel.labelValueToType.exists(missingSmallerValue)) 
        {
            m_missingSmallerDifferencePartCounter++;
            
            if (m_missingSmallerDifferencePartCounter > 2) 
            {
                var labelId = "GenericMissingPartsOfDifferenceD";
                mismatchData = getHintFromLabel(labelId, [missingSmallerValue]);
            }
            else if (m_missingSmallerDifferencePartCounter > 1) 
            {
                var labelId = "GenericMissingPartsOfDifferenceE";
                mismatchData = getHintFromLabel(labelId, null);
            }
            else 
            {
                var labelId = "GenericMissingPartsOfDifferenceF";
                mismatchData = getHintFromLabel(labelId, null);
            }
        }
        
        return mismatchData;
    }
    
    private function generateGenericDifferenceHints(differenceValue : String,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        // Check that any difference exists and also
        // if a difference with the desired value exists
        var anyDifferenceExists : Bool = false;
        var correctDifferenceExists : Bool = false;
        var labelValueToType : Dynamic = userDecomposedModel.labelValueToType;
        for (labelValue in Reflect.fields(labelValueToType))
        {
            if (Reflect.field(labelValueToType, labelValue) == "c") 
            {
                anyDifferenceExists = true;
                if (labelValue == differenceValue) 
                {
                    correctDifferenceExists = true;
                }
            }
        }
        
        if (!anyDifferenceExists || !correctDifferenceExists) 
        {
            // If never performed the add difference command AND the user has attempted some amount
            // of moves and/or incorrect submission we guess they do not know how to perform the action
            var timesPeformedAddDifference : Int = ((m_gestureToFrequencyPerformed.exists(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON))) ? 
				Reflect.field(m_gestureToFrequencyPerformed, AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON) : 0;
            
            // Special case to point out the unknown as the difference is missing
            if (!userDecomposedModel.labelValueToType.exists(differenceValue) && Reflect.field(m_documentIdToExpressionMap, "unk") == differenceValue) 
            {
                var labelId : String = "GenericDifferenceHintsA";
                mismatchData = getHintFromLabel(labelId, null);
            }
            else if (userDecomposedModel.labelValueToType.exists(differenceValue)) 
            {
                var labelId = "GenericDifferenceHintsB";
                mismatchData = getHintFromLabel(labelId, [differenceValue]);
            }
            else if (timesPeformedAddDifference < 1 && m_incorrectDifferenceCounter > 0) 
            {
                var labelId = "GenericDifferenceHintsC";
                mismatchData = getHintFromLabel(labelId, [TipsViewer.SUBTRACT_WITH_BOXES]);
            }
            else 
            {
                // Gradually reveal more information about the hint as the user continues to input wrong answers
                var missingDifferenceContent : String = null;
				var labelId : String = null;
                m_incorrectDifferenceCounter++;
                
                if (m_incorrectDifferenceCounter > 2) 
                {
                    labelId = "GenericDifferenceHintsD";
                    mismatchData = getHintFromLabel(labelId, [differenceValue]);
                }
                else if (!anyDifferenceExists) 
                {
                    labelId = "GenericDifferenceHintsE";
                    mismatchData = getHintFromLabel(labelId, null);
                }
                else if (!correctDifferenceExists) 
                {
                    labelId = "GenericDifferenceHintsF";
                    mismatchData = getHintFromLabel(labelId, null);
                }
            }
        }
        
        return mismatchData;
    }
    
    /**
     * Common hints and checks for creating 'n' number of equal sized groups.
     * If the unit is on a different line, the number of groups of the same size is actual n+1, however the
     * check for groups would be misleasing if missing the unit value counted against the tally.
     * 
     * The common function accepts the total describing
     * 
     * Several problems types will have a group on a separate line, with another line
     * 
     * @param separateUnitGroup
     *      If true then there is a separate unit group that acts like a multiplier. The groupsExpected value
     *      is saying there are that many groups not including the unit itsel
     */
    private function generateGenericEqualGroupsHints(groupsExpected : Int,
            separateUnitGroup : Bool,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        // If the unit group is a separate entity then we need to also account for when the player includes
        // the unit as a separate piece
        var correctNumberOfGroupsWithoutUnit : Bool = checkEqualSizedGroupsExists(groupsExpected, userDecomposedModel);
        var doShowHintsWithoutUnit : Bool = !correctNumberOfGroupsWithoutUnit;
        if (separateUnitGroup) 
        {
            // The unit hint only shows up in the edge case where the user has created the right number of parts
            // on line but is missing the extra unit on a separate line.
            var correctNumberOfGroupsWithUnit : Bool = checkEqualSizedGroupsExists(groupsExpected + 1, userDecomposedModel);
            if (!correctNumberOfGroupsWithUnit && correctNumberOfGroupsWithoutUnit) 
            {
                var labelName : String = "GenericEqualGroupsHintsA";
                mismatchData = getHintFromLabel(labelName, null);
            }  // DO NOT show the general unit hints if we have already picked on in this branch  
            
            
            
            doShowHintsWithoutUnit = doShowHintsWithoutUnit && mismatchData == null;
            
            if (correctNumberOfGroupsWithUnit) 
            {
                doShowHintsWithoutUnit = false;
            }
        }
        
        if (doShowHintsWithoutUnit) 
        {
            // Generating equal groups can be done through splitting or adding a unit bar.
            // In nearly every case, there is no good reason to use one over the other
            var timesAttemptedAddUnit : Int = 0;
            if (m_gestureToFrequencyPerformed.exists(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR)) 
            {
                timesAttemptedAddUnit = Reflect.field(m_gestureToFrequencyPerformed, AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR);
            }
            
            var timesAttemptedMultiply : Int = 0;
            if (m_gestureToFrequencyPerformed.exists(AlgebraAdventureLoggingConstants.MULTIPLY_BAR)) 
            {
                timesAttemptedMultiply = Reflect.field(m_gestureToFrequencyPerformed, AlgebraAdventureLoggingConstants.MULTIPLY_BAR);
            }
            
            if (timesAttemptedAddUnit + timesAttemptedMultiply < 1 && m_wrongGroupsCounter > 0) 
            {
                // If the user has never tried to use one of the gestures to make equal sized boxes, point
                // out the tip in the help section to tell them how it is done.
                var labelName = "GenericEqualGroupsHintsB";
                mismatchData = getHintFromLabel(labelName, [TipsViewer.MULTIPLY_WITH_BOXES]);
            }
            // Assuming they have tried the gesture to create groups, the confusion is related to the
            // number of groups that need to be created
            else 
            {
                m_wrongGroupsCounter++;
                // After enough incorrect submissions we should just tell them what the right
                // number of groups is
                if (m_wrongGroupsCounter > 2) 
                {
                    var labelName = "GenericEqualGroupsHintsC";
                    mismatchData = getHintFromLabel(labelName, [groupsExpected]);
                }
                // TODO: Make a guess about how many equal sized groups the user has and figure out how many more they actually need
                else if (m_wrongGroupsCounter > 1) 
                {
                    var labelName = "GenericEqualGroupsHintsD";
                    mismatchData = getHintFromLabel(labelName, null);
                }
                else 
                {
                    var labelName = "GenericEqualGroupsHintsD";
                    mismatchData = getHintFromLabel(labelName, null);
                }
            }
        }
        
        return mismatchData;
    }
    
    // Helper used by the validate functions
    private function getFirstMissingLabelFromModel(labelNames : Array<String>,
            decomposedModel : DecomposedBarModelData) : String
    {
        var firstMissingLabel : String = null;
        for (labelName in labelNames)
        {
            if (!decomposedModel.labelValueToType.exists(labelName)) 
            {
                firstMissingLabel = labelName;
                break;
            }
        }
        return firstMissingLabel;
    }
    
    /**
     * Bar model type based on groups of equal size that equal a single sum with a unit defined
     * as a particular value.
     * 
     * Flag to modify the check to handle cases where the labeled unit is a different category of object
     * 
     * There is also a difference value that can be null if not used
     * 
     * @param sumValue
     *      The expression value used to indicate parts should be collected, null if it doesn't exist 
     * @param unitValue
     *      The expression value of just one of the groups
     * @param isUnitSeparate
     *      Is the unit value a separate box from the rest of the groups
     * @param doesSumIncludeUnit
     *      True if the sum value should include the unit value that is present in a separate line.
     * @param differenceValue
     *      If not null this is the value of the comparison part in between the unit and regular groups
     */
    private function validateGroupsEqualSum(groupsExpected : Int,
            sumValue : String,
            unitValue : String,
            isUnitSeparate : Bool,
            doesSumIncludeUnit : Bool,
            differenceValue : String,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        if (userDecomposedModel.numBarWholes == 0 && m_firstEmptyBarModelHintCounter < 1) 
        {
            var labelId : String = "GroupsEqualSumA";
            mismatchData = getHintFromLabel(labelId, null);
            m_firstEmptyBarModelHintCounter++;
        }
        
        if (mismatchData == null) 
        {
            mismatchData = generateGenericEqualGroupsHints(groupsExpected, isUnitSeparate, userDecomposedModel);
        }  // on one of the groups.    // Is the unit value added somewhere, important to indicate that this is the size  
        
        
        
        
        
        if (mismatchData == null) 
        {
            mismatchData = validateUnitLabel(groupsExpected, unitValue, isUnitSeparate, userDecomposedModel);
        }
        
        if (sumValue != null && mismatchData == null) 
        {
            // Check if the sum value exists as a label somewhere in the model
            mismatchData = generateGenericMissingSumHints(sumValue, userDecomposedModel);
            if (mismatchData == null) 
            {
                // HACK: For this hint to work we assume the user has correctly placed the unit value
                // If the sum does exist, check that it covers the correct proportion. For this problem type, the sum value
                // is some multiple of the unit value. Whether or not the unit is part of the sum affects this multiple.
                var numGroupsInSum : Int = ((isUnitSeparate && doesSumIncludeUnit)) ? groupsExpected + 1 : groupsExpected;
                var sumLabelCorrect : Bool = checkLabelSumOfOtherLabels(sumValue, [unitValue], [numGroupsInSum], userDecomposedModel);
                if (!sumLabelCorrect) 
                {
					var labelId : String = null;
                    m_incorrectGroupSumCounter++;
                    if (m_incorrectGroupSumCounter == 1) 
                    {
                        labelId = "GroupsEqualSumB";
                        mismatchData = getHintFromLabel(labelId, [sumValue]);
                    }
                    else 
                    {
                        if (doesSumIncludeUnit) 
                        {
                            labelId = "GroupsEqualSumC";
                            mismatchData = getHintFromLabel(labelId, [sumValue]);
                        }
                        else 
                        {
                            labelId = "GroupsEqualSumD";
                            mismatchData = getHintFromLabel(labelId, [sumValue, groupsExpected]);
                        }
                    }
                }
            }
        }
        
        if (differenceValue != null && mismatchData == null) 
        {
            // If there is a difference in this situation, the unit must be added on a separate line
            mismatchData = generateGenericDifferenceHints(differenceValue, userDecomposedModel);
        }
        
        return mismatchData;
    }
    
    /**
     * These are the classes of problems with the intermediate values and have a sum and difference.
     * Assuming the intermediate is always either the larger or smaller part.
     * 
     * @param largerPart
     *      Name of the larger value in a difference
     * @param smallerPart
     *      Name of the smaller value in a difference
     * @param difference
     * @param sum
     *      Name of the combined value of the larger and smaller parts
     */
    private function validateSumAndDifferenceWithIntermediate(largerPart : String,
            smallerPart : String,
            difference : String,
            sum : String,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        // Understanding that there is a second unknown is the critical piece to knowing how
        // to solve this problem.
        if (mismatchData == null) 
        {
            var intermediateValue : String = Reflect.field(m_documentIdToExpressionMap, "c");
            mismatchData = generateIntermediateValueNotDiscoveredHint(intermediateValue);
        }
        
        if (mismatchData == null && userDecomposedModel.numBarWholes == 0) 
        {
            var labelId : String = "SumAndDifferenceWithIntermediateA";
            mismatchData = getHintFromLabel(labelId, null);
        }
        
        if (mismatchData == null) 
        {
            mismatchData = generateGenericMissingPartsOfDifference(largerPart, smallerPart, userDecomposedModel);
        }  // Make sure the user has placed the sum  
        
        
        
        if (mismatchData == null) 
        {
            mismatchData = generateGenericMissingSumHints(sum, userDecomposedModel, false);
            if (mismatchData == null &&
                userDecomposedModel.labelValueToType.exists(sum) &&
                !checkLabelSumOfOtherLabels(sum, [largerPart, smallerPart], [1, 1], userDecomposedModel)) 
            {
                var labelId = "SumAndDifferenceWithIntermediateB";
                mismatchData = getHintFromLabel(labelId, [sum]);
            }
        }  // Make sure the user has placed the difference  
        
        
        
        if (mismatchData == null) 
        {
            mismatchData = generateGenericDifferenceHints(difference, userDecomposedModel);
        }
        
        return mismatchData;
    }
    
    /**
     * These are classes of problems with an intermediate value in addition to using groups
     * 
     * @param groupsExpected
     * @param sumOfGroups
     *      If null, then no sum of all the groups exists
     * @param total
     *      Can be null if not used
     * @param unitValue
     *      The amount in one of the groups
     * @param difference 
     *      Can be null if not used
     */
    private function validateSumOfGroupsWithIntermediate(groupsExpected : Int,
            sumOfGroups : String,
            total : String,
            unitValue : String,
            difference : String,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        // Check if missing the second unknown
        var intermediateValue : String = Reflect.field(m_documentIdToExpressionMap, "c");
        mismatchData = generateIntermediateValueNotDiscoveredHint(intermediateValue);
        
        if (mismatchData == null && userDecomposedModel.numBarWholes == 0) 
        {
            var labelId : String = "SumOfGroupsWithIntermediateA";
            mismatchData = getHintFromLabel(labelId, null);
        }
        
        if (mismatchData == null) 
        {
            mismatchData = generateGenericEqualGroupsHints(groupsExpected, true, userDecomposedModel);
        }
        
        if (mismatchData == null) 
        {
            // Missing the intermediate value
            if (!userDecomposedModel.labelValueToType.exists(intermediateValue)) 
            {
                var labelId = "SumOfGroupsWithIntermediateB";
                mismatchData = getHintFromLabel(labelId, null);
            }
            else 
            {
                mismatchData = validateUnitLabel(groupsExpected, unitValue, true, userDecomposedModel);
            }
        }
        
        if (total != null && mismatchData == null) 
        {
            mismatchData = generateGenericMissingSumHints(total, userDecomposedModel, false);
        }
        
        if (difference != null && mismatchData == null) 
        {
            mismatchData = generateGenericDifferenceHints(difference, userDecomposedModel);
        }
        
        return mismatchData;
    }
    
    private function generateIntermediateValueNotDiscoveredHint(intermediateValue : String) : Dynamic
    {
        var mismatchData : Dynamic = null;
        var deckWidgets : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(DeckWidget);
        if (deckWidgets.length > 0) 
        {
            var intermediateValueNotDiscovered : Bool = true;
            var deckWidget : DeckWidget = try cast(deckWidgets[0], DeckWidget) catch(e:Dynamic) null;
            var expressionsInDeck : Array<Component> = deckWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            for (expressionInDeck in expressionsInDeck)
            {
				var castedExpressionInDeck : ExpressionComponent = try cast(expressionInDeck, ExpressionComponent) catch (e : Dynamic) null;
                if (castedExpressionInDeck.expressionString == intermediateValue) 
                {
                    intermediateValueNotDiscovered = false;
                    break;
                }
            }
            
            if (intermediateValueNotDiscovered) 
            {
                m_intermediateUnknownNotFoundCounter++;
                if (m_intermediateUnknownNotFoundCounter > 2) 
                {
                    var labelId : String = "IntermediateValueNotDiscoveredHintA";
                    mismatchData = getHintFromLabel(labelId, [intermediateValue]);
                }
                else if (m_intermediateUnknownNotFoundCounter > 1) 
                {
                    var labelId = "IntermediateValueNotDiscoveredHintB";
                    mismatchData = getHintFromLabel(labelId, null);
                }
                else 
                {
                    var labelId = "IntermediateValueNotDiscoveredHintC";
                    mismatchData = getHintFromLabel(labelId, null);
                }
            }
        }
        return mismatchData;
    }
    
    /**
     * A null label can be passed in if a particular label value does not exist
     * 
     * A difference can optionally be included if needed
     */
    private function validateSumsOfFraction(numGroupsTotal : Int,
            numGroupsShaded : Int,
            numGroupsUnshaded : Int,
            total : String,
            sumOfShaded : String,
            sumOfUnshaded : String,
            difference : String,
            userBarModel : BarModelData,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        if (userDecomposedModel.numBarWholes == 0 && m_firstEmptyBarModelHintCounter < 1) 
        {
            var labelId : String = "SumsOfFractionA";
            mismatchData = getHintFromLabel(labelId, null);
            m_firstEmptyBarModelHintCounter++;
        }  // Check that the user has created the right number of total groups  
        
        
        
        if (mismatchData == null) 
        {
            mismatchData = generateGenericEqualGroupsHints(numGroupsTotal, false, userDecomposedModel);
        }  // the correct number of equal sized groups    // There are multiple points where a label needs to exist AND the label needs to cover  
        
        
        
        
        
        if (sumOfShaded != null && mismatchData == null) 
        {
            mismatchData = validateFractionLabel(sumOfShaded, numGroupsShaded, numGroupsTotal, userBarModel, userDecomposedModel);
        }
        
        if (sumOfUnshaded != null && mismatchData == null) 
        {
            mismatchData = validateFractionLabel(sumOfUnshaded, numGroupsUnshaded, numGroupsTotal, userBarModel, userDecomposedModel);
        }  // and the total actually covers what looks like the right number of groups    // TODO: This gives a bad hint if there is an additional different sized box  
        
        
        
        
        
        if (total != null && mismatchData == null) 
        {
            mismatchData = generateGenericMissingSumHints(total, userDecomposedModel, false);
            
            if (mismatchData == null && !checkLabelSpanCorrectNumGroups(total, numGroupsTotal, userBarModel, userDecomposedModel)) 
            {
                var labelId = "SumsOfFractionB";
                mismatchData = getHintFromLabel(labelId, [total]);
            }
        }
        
        if (difference != null && mismatchData == null) 
        {
            mismatchData = generateGenericDifferenceHints(difference, userDecomposedModel);
        }
        
        return mismatchData;
    }
    
    private function validateFractionOfLargerAmount(numGroupsTotal : Int,
            numGroupsShaded : Int,
            numGroupsUnshaded : Int,
            total : String,
            sumOfShaded : String,
            sumOfUnshaded : String,
            difference : String,
            userBarModel : BarModelData,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        if (userDecomposedModel.numBarWholes == 0 && m_firstEmptyBarModelHintCounter < 1) 
        {
            var labelId : String = "FractionOfLargerAmountA";
            mismatchData = getHintFromLabel(labelId, null);
            m_firstEmptyBarModelHintCounter++;
        }
		
		// Check if the user has the correct number of equal sized groups  
        // The correct total is the combination of parts of the whole and the fraction of the whole
        if (mismatchData == null && !checkEqualSizedGroupsExists(numGroupsTotal, userDecomposedModel)) 
        {
            // User has made the correct number of groups representing the shaded objects,
            // now they need to represent the unshaded
			var labelId : String = null;
			if (checkEqualSizedGroupsExists(numGroupsShaded, userDecomposedModel)) 
            {
                labelId = "FractionOfLargerAmountB";
                mismatchData = getHintFromLabel(labelId, null);
            }
            // Correctly represented unshaded parts, now need to represent shaded
            else if (checkEqualSizedGroupsExists(numGroupsUnshaded, userDecomposedModel)) 
            {
                labelId = "FractionOfLargerAmountC";
                mismatchData = getHintFromLabel(labelId, null);
            }
            // The number of equal groups does not match anything currently
            else 
            {
                // Should guide player to creating right now of groups for the whole and then the fraction of the whole
                labelId = "FractionOfLargerAmountD";
                mismatchData = getHintFromLabel(labelId, null);
            }
        }
        
        if (mismatchData == null) 
        {
            mismatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, total, sumOfShaded, sumOfUnshaded, difference, userBarModel, userDecomposedModel);
        }
        
        return mismatchData;
    }
    
    private function validateUnitLabel(groupsExpected : Int,
            unitValue : String,
            isUnitSeparate : Bool,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        // Make sure the unit is added somewhere and refers to just one group
        if (!userDecomposedModel.labelValueToType.exists(unitValue)) 
        {
            // After enough mistakes where the unit is missing, we should just give the answer
            m_missingUnitCounter++;
            
            if (m_missingUnitCounter <= 2) 
            {
                var labelId : String = "UnitLabelA";
                mismatchData = getHintFromLabel(labelId, null);
            }
            else 
            {
                var labelId = "UnitLabelB";
                mismatchData = getHintFromLabel(labelId, [unitValue]);
            }
        }
        else 
        {
            // The unit should be spanning a fixed percentage of the total bar placed in the model
            // Also should be flexible enough to expand to handle cases where the unit value is a comletely separate
            var expectedUnitRatio : Float = 1 / groupsExpected;
            var expectedUnitRatioIfSeparate : Float = 1 / (groupsExpected + 1);
            var error : Float = 0.00001;
            if (isUnitSeparate && Math.abs(Reflect.field(userDecomposedModel.labelToRatioOfTotalBoxes, unitValue) - expectedUnitRatioIfSeparate) > error ||
                !isUnitSeparate && Math.abs(Reflect.field(userDecomposedModel.labelToRatioOfTotalBoxes, unitValue) - expectedUnitRatio) > error) 
            {
                // The actual problem we are trying to detect is that the label on the unit is not on the correct proportion of box
                // Any additional boxes will cause this to fail however, even if visually it looks like a label is on the correct
                // looking group.
                // Solution that will catch some of the cases (if the number of equal groups exactly equals the expected amount):
                // Check if the model contains a tally of same sized boxes equal to the expected number of groups.
                // Find the size of one of those groups and see if it matches the size of spanned by the unit value label.
                var expectedNumberOfGroups : Int = ((isUnitSeparate)) ? groupsExpected + 1 : groupsExpected;
                var groupTallyIndex : Int = userDecomposedModel.normalizedBarSegmentValueTally.indexOf(expectedNumberOfGroups);
                if (groupTallyIndex != -1) 
                {
                    
                    var normalizedValueOfGroup : Float = userDecomposedModel.normalizedBarSegmentValuesList[groupTallyIndex];
                    if (Math.abs(Reflect.field(userDecomposedModel.labelValueToNormalizedSegmentValue, unitValue) - normalizedValueOfGroup) > error) 
                    {
                        var labelId : String = null;
                        if (m_incorrectUnitAmountCounter == 0) 
                        {
                            labelId = "UnitLabelC";
                            mismatchData = getHintFromLabel(labelId, null);
                        }
                        else if (m_incorrectUnitAmountCounter == 1) 
                        {
                            labelId = "UnitLabelD";
                            mismatchData = getHintFromLabel(labelId, [unitValue]);
                        }
                        else 
                        {
                            labelId = "UnitLabelE";
                            mismatchData = getHintFromLabel(labelId, [unitValue, groupsExpected]);
                        }
                        m_incorrectUnitAmountCounter++;
                    }
                    // Here, it looks like the user has labeled the right group, it is just that there may be extra boxes
                    // that mess up the total ratio
                    else 
                    {
                        var labelId = "UnitLabelF";
                        mismatchData = getHintFromLabel(labelId, null);
                    }
                }
                else 
                {
                    var labelId = "UnitLabelG";
                    mismatchData = getHintFromLabel(labelId, null);
                }
            }
        }
        
        return mismatchData;
    }
    
    private function validateFractionLabel(fractionLabel : String,
            numerator : Int,
            denominator : Int,
            userModel : BarModelData,
            userDecomposedModel : DecomposedBarModelData) : Dynamic
    {
        var mismatchData : Dynamic = null;
        
        // Check that the fraction label exists and is spanning the right number of groups
        if (!userDecomposedModel.labelValueToType.exists(fractionLabel) ||
            !checkLabelSpanCorrectNumGroups(fractionLabel, numerator, userModel, userDecomposedModel)) 
        {
            m_incorrectFractionLabel++;
            
            if (m_incorrectFractionLabel > 2) 
            {
                var labelId : String = "FractionLabelA";
                mismatchData = getHintFromLabel(labelId, [fractionLabel, numerator, denominator]);
            }
            else 
            {
                var labelId = "FractionLabelB";
                mismatchData = getHintFromLabel(labelId, [fractionLabel]);
            }
        }
        
        return mismatchData;
    }
    
    /**     
		 * Condition to check that a specified number of equally sized boxes exist
     * in the model submitted by the user.
		 */
    private function checkEqualSizedGroupsExists(expectedNumGroups : Int,
            actualModel : DecomposedBarModelData) : Bool
    {
        // Look through the box tally in the user submitted model,
        // as long as one of those equals the expected value then this
        // condition passes.
        var equalSizedGroupsExist : Bool = false;
        var barRatioTallies : Array<Int> = actualModel.normalizedBarSegmentValueTally;
        for (tally in barRatioTallies)
        {
            if (tally == expectedNumGroups) 
            {
                equalSizedGroupsExist = true;
                break;
            }
        }
        
        return equalSizedGroupsExist;
    }
    
    /**
     * Condition to check that a specified label value exists and is covering
     * the correct amount of EQUAL sized boxes.
     */
    private function checkLabelSpanCorrectNumGroups(labelValue : String,
            expectedNumGroups : Int,
            userModel : BarModelData,
            userModelDecomposed : DecomposedBarModelData) : Bool
    {
        // Check if label exists
        var labelSpansCorrectAmount : Bool = false;
        var continueSearch : Bool = true;
        if (userModelDecomposed.labelValueToType.exists(labelValue)) 
        {
            // If so check that it is covering the correct amount of equal sized groups
            // This is a structural detail, we need to look through all the labels
            // Check if they span the correct number of boxes AND that all those boxes
            // are equal sizes
            var i : Int = 0;
            var barWholes : Array<BarWhole> = userModel.barWholes;
            for (i in 0...barWholes.length){
                var barWhole : BarWhole = barWholes[i];
                var barLabels : Array<BarLabel> = barWhole.barLabels;
                var barSegments : Array<BarSegment> = barWhole.barSegments;
                var j : Int = 0;
                for (j in 0...barLabels.length){
                    var barLabel : BarLabel = barLabels[j];
                    if (barLabel.value == labelValue && (barLabel.endSegmentIndex - barLabel.startSegmentIndex + 1) == expectedNumGroups) 
                    {
                        // Make sure all the segments this bar covers have the same value
                        var segmentIndex : Int = 0;
                        var referenceSegmentAmount : Float = -1;
                        var allSegmentsEqualSize : Bool = true;
                        for (segmentIndex in barLabel.startSegmentIndex...barLabel.endSegmentIndex + 1){
                            var currentSegmentValue : Float = barSegments[segmentIndex].getValue();
                            
                            // First segment provides the value to compare against
                            if (referenceSegmentAmount < 0) 
                            {
                                referenceSegmentAmount = currentSegmentValue;
                            }  // Boxes are not all equal size, this should fail  
                            
                            
                            
                            if (referenceSegmentAmount != currentSegmentValue) 
                            {
                                allSegmentsEqualSize = false;
                            }
                        }
                        
                        
                        if (allSegmentsEqualSize) 
                        {
                            // Success
                            labelSpansCorrectAmount = true;
                        }
                        else 
                        {
                            // this label failed
                            
                        }  // Stop after the first match  
                        
                        
                        
                        continueSearch = false;
                    }
                    
                    if (!continueSearch) 
                    {
                        break;
                    }
                }
                
                if (!continueSearch) 
                {
                    break;
                }
            }
            
            if (continueSearch) 
            {
                // Vertical labels also can provide the answer
                var verticalLabels : Array<BarLabel> = userModel.verticalBarLabels;
                for (i in 0...verticalLabels.length){
                    var verticalLabel : BarLabel = verticalLabels[i];
                    
                    if (verticalLabel.value == labelValue) 
                    {
                        var numSegmentsPartOfLabel : Int = 0;
                        var referenceSegmentAmount = -1;
						var allSegmentsEqualSize : Bool = true;
                        for (barIndex in verticalLabel.startSegmentIndex...verticalLabel.endSegmentIndex + 1){
                            var barWhole = userModel.barWholes[barIndex];
                            var barSegments = barWhole.barSegments;
                            numSegmentsPartOfLabel += barSegments.length;
                            for (segmentIndex in 0...barSegments.length){
                                var currentSegmentValue = barSegments[segmentIndex].getValue();
                                if (referenceSegmentAmount < 0) 
                                {
                                    referenceSegmentAmount = Std.int(currentSegmentValue);
                                }
								
								// If segment  
                                if (referenceSegmentAmount != currentSegmentValue) 
                                {
                                    allSegmentsEqualSize = false;
                                    break;
                                }
                            }
                        }
                        
                        if (allSegmentsEqualSize && numSegmentsPartOfLabel == expectedNumGroups) 
                        {
                            // Success
                            labelSpansCorrectAmount = true;
                        }
                        else 
                        {
                            // This particular label failed
                            
                        }  // Stop after first match  
                        
                        
                        
                        continueSearch = false;
                    }
                    
                    if (!continueSearch) 
                    {
                        break;
                    }
                }
            }
        }
        
        return labelSpansCorrectAmount;
    }
    
    /**
     * @param otherLabelRatioMultiplier
     *      The number of times a ratio covered by a label occurs within the total
     */
    private function checkLabelSumOfOtherLabels(totalLabelName : String,
            otherLabelNames : Array<String>,
            otherLabelRatioMultiplier : Array<Int>,
            decomposedModel : DecomposedBarModelData) : Bool
    {
        // Go through the other labels and check the amount
        var isTotalTheSum : Bool = false;
        
        var labelToValue : Dynamic = decomposedModel.labelValueToNormalizedSegmentValue;
        if (labelToValue.exists(totalLabelName)) 
        {
            var numOtherLabels : Int = otherLabelNames.length;
            var i : Int = 0;
            var otherLabelSum : Float = 0;
            for (i in 0...numOtherLabels){
                var otherLabel : String = otherLabelNames[i];
                if (labelToValue.exists(otherLabel)) 
                {
                    otherLabelSum += otherLabelRatioMultiplier[i] * Reflect.field(labelToValue, otherLabel);
                }
            }
            
            var allowedError : Float = 0.001;
            if (Math.abs(Reflect.field(labelToValue, totalLabelName) - otherLabelSum) < allowedError) 
            {
                isTotalTheSum = true;
            }
        }
        
        return isTotalTheSum;
    }
    
    /**
     * This helper function is for the situation where a bar model has multiple possible answers that all have
     * a final equation of the form  (a1+...+an) + (b1+...+bn) = c.
     * The 'c' term can be a sum of the 'a' and 'b' terms or it is its own box with the 'a' and 'b' terms being the
     * smaller box and the difference.
     * Based on the user's current model
     */
    private function isSumRepresentedAsBox(sumValue : String, userBarModel : BarModelData) : Bool
    {
        var isSumABox : Bool = false;
        for (barWhole/* AS3HX WARNING could not determine type for var: barWhole exp: EField(EIdent(userBarModel),barWholes) type: null */ in userBarModel.barWholes)
        {
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
            {
                // The sum value is found, if it is its own box then we presume the user wants to create a model
                // with a difference
                if (barLabel.value == sumValue) 
                {
                    isSumABox = (barLabel.startSegmentIndex == barLabel.endSegmentIndex);
                }
            }
        }
        
        return isSumABox;
    }
    
    private function getHintFromLabel(hintLabel : String, params : Array<Dynamic>, filterData : Dynamic = null) : Dynamic
    {
        // Convert the hint label to a 'step' within a particular type
        var hintData : Dynamic = null;
        if (m_labelToStepMap.exists(hintLabel)) 
        {
            var generatedStepId : Int = Std.parseInt(Reflect.field(m_labelToStepMap, hintLabel));
            if (m_customHintStorage != null) 
            {
                hintData = m_customHintStorage.getHintFromStepId(generatedStepId, params, filterData);
            }
            
            if (hintData == null) 
            {
                hintData = m_defaultHintStorage.getHintFromStepId(generatedStepId, params, filterData);
            }
        }
        
        return hintData;
    }
}
