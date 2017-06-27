package wordproblem.hints.selector
{
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
    import wordproblem.engine.expression.SymbolData;
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
    public class ShowHintOnBarModelMistake extends HintSelectorNode
    {
        [Embed(source="/../assets/strings/default_barmodel_hints.xml", mimeType="application/octet-stream")]
        public static const default_barmodel_hints:Class;
        
        /**
         * Each part of the code where a hint should be generated has a label id.
         * External hint data has no knowledge of these labels, instead they are based on
         * a separate id denoting a 'step' in the hint picking process for a particular
         * bar model pattern.
         * 
         * This mapping is necessary because several of the hint logic flows re-used blocks of
         * code. Label ids are not unique, used across different bar model patterns.
         */
        private var m_labelToStepMap:Object;
        
        /**
         * All bar model levels can fallback onto a default hint content, the text for those defaults are
         * located in the above embedded xml file. This object stores all those default content, which is worded
         * so that it can fit any problem matching a particular type.
         */
        private var m_defaultHintStorage:HintXMLStorage;
        
        /**
         * If a level has specific hints (usually baked into the level xml file), those hints are stored in this
         * object.
         */
        private var m_customHintStorage:HintXMLStorage;
        
        /**
         * Have a dependency on the validate bar model script, as it contains the decomposed bar models to
         * compare against
         */
        private var m_validateBarModelArea:ValidateBarModelArea;
        
        private var m_barModelArea:BarModelAreaWidget;
        
        /**
         * As part of the player preferences, they can toggle on and off whether hints after a mistake
         * automatically show up
         */
        private var m_doShowHintsAfterMistake:Boolean;
        
        /**
         * Need to read this to determine whether the hints this script is supposed to show should
         * even be displayed.
         */
        private var m_playerStatsAndSaveData:PlayerStatsAndSaveData;
        
        /**
         * Need to keep a reference to this because on disposal the game engine purges itself of widgets.
         * Still want to properly clean up the components attached to it though.
         */
        private var m_textArea:TextAreaWidget;
        
        private var m_characterController:HelperCharacterController;
        private var m_gameEngine:IGameEngine;
        private var m_assetManager:AssetManager;
        private var m_textParser:TextParser;
        private var m_textViewFactory:TextViewFactory;
        
        /**
         * Mapping from document id to an expression/term value
         * Relies on fact that document ids in a level can be directly mapped to elements in a
         * template of a bar model type. For example the doc id 'b1' refers to the number of
         * groups in any type 3a model.
         */
        private var m_documentIdToExpressionMap:Object;
        
        /**
         * Per level we keep track of the names of actions performed by the player to adjust
         * hint content if we guess the user simply forgot how to perform an action.
         * 
         * Key is name of the action event, value is the times the player performed it.
         * The frequency is never reset while a level is running.
         * If a key does not exist, it means that action was never performed.
         */
        private var m_gestureToFrequencyPerformed:Object;
        
        /**
         * Keep track of the number of times they submit an incorrect bar model.
         * The idea is that more incorrect submissions should lead to more specific hints.
         */
        private var m_numTimesSubmittedIncorrectModel:int;
        
        // Similar to how the counter keeping track of times an incorrect model was submitted,
        // we break down mistake types into finer grain counters.
        // The purpose is if the user is frequently entering an incorrect pathway we want to gradually give them
        // more specific hints
        private var m_missingSumPartCounter:int;
        private var m_missingSumLabelCounter:int;
        private var m_missingLargerDifferencePartCounter:int;
        private var m_missingSmallerDifferencePartCounter:int;
        private var m_incorrectDifferenceCounter:int;
        private var m_incorrectFractionLabel:int
        private var m_missingUnitCounter:int;
        private var m_incorrectUnitAmountCounter:int;
        private var m_wrongGroupsCounter:int;
        private var m_incorrectGroupSumCounter:int;
        private var m_incorrectGroupsForFractionCounter:int;
        private var m_differenceBetweenPartsCounter:int;
        private var m_incorrectTallyOfLabeledBoxesCounter:int;
        private var m_fractionOfLargerAmountCounter:int;
        private var m_intermediateNoBarCount:int;
        
        /**
         * Count if the player has not discovered the second unknown in the two step problem
         */
        private var m_intermediateUnknownNotFoundCounter:int;
        
        /**
         * Count of the number of times the bar model specific hint that shows up when the area
         * is completely empty has be shown. The count lets us know when to stop showing that hint are to change what it says.
         */
        private var m_firstEmptyBarModelHintCounter:int;
        
        public function ShowHintOnBarModelMistake(gameEngine:IGameEngine,
                                                  assetManager:AssetManager,
                                                  playerStatesAndSaveData:PlayerStatsAndSaveData,
                                                  validateBarModelArea:ValidateBarModelArea,
                                                  characterController:HelperCharacterController,
                                                  textParser:TextParser,
                                                  textViewFactory:TextViewFactory, 
                                                  barModelType:String, 
                                                  customHintData:XML)
        {
            // Load up the dummy xml, which should contain ALL the hint logic paths
            // The bar model type governs which part of the xml should be loaded
            // Create a mapping from label id to the actual hint elements
            var defaultHintsXml:XML = new XML(new default_barmodel_hints());
            var barModelHintBlocks:XMLList = defaultHintsXml.elements("barmodelhints");
            var labelIdToHintXmlElement:Object = {};
            var i:int;
            for (i = 0; i < barModelHintBlocks.length(); i++)
            {
                var barModelHintBlock:XML = barModelHintBlocks[i];
                var hintElements:XMLList = barModelHintBlock.elements("hint");
                var j:int;
                for (j = 0; j < hintElements.length(); j++)
                {
                    // Create the mapping from label to step based on the selected block
                    var hintElement:XML = hintElements[j];
                    labelId = hintElement.attribute("labelId");
                    labelIdToHintXmlElement[labelId] = hintElement;
                }
            }
            
            // Mapping from label id to step is based on the bar model type.
            // Look through the xml data file to figure out what mapping is appropriate.
            // This mapping will also allow us to rebuild a dummy xml representing default hint that looks like
            // any external hinting structure
            var defaultHintXmlToBuild:XML = <barmodelhints/>;
            var labelToStepMappings:XMLList = defaultHintsXml.elements("mapping");
            m_labelToStepMap = {};
            for (i = 0; i < labelToStepMappings.length(); i++)
            {
                var labelToStepMapping:XML = labelToStepMappings[i];
                var mappingBarModelTypes:String = labelToStepMapping.attribute("type");
                var typesInMapping:Array = mappingBarModelTypes.split(",");
                if (typesInMapping.indexOf(barModelType) > -1)
                {
                    var labelToStepElements:XMLList = labelToStepMapping.elements("label");
                    for (j = 0; j < labelToStepElements.length(); j++)
                    {
                        var labelToStepElement:XML = labelToStepElements[j];
                        var labelId:String = labelToStepElement.attribute("id");
                        var stepId:int = parseInt(labelToStepElement.attribute("step"));
                        m_labelToStepMap[labelId] = stepId;
                        
                        var hintXmlCopy:XML = (labelIdToHintXmlElement[labelId] as XML).copy();
                        hintXmlCopy.@step = stepId;
                        defaultHintXmlToBuild.appendChild(hintXmlCopy);
                    }
                    break;
                }
            }
            
            m_defaultHintStorage = new HintXMLStorage(defaultHintXmlToBuild);
            
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
            m_barModelArea = gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_textArea = gameEngine.getUiEntity("textArea") as TextAreaWidget;
            m_gestureToFrequencyPerformed = {};
            
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
            m_incorrectGroupsForFractionCounter = 0;
            m_differenceBetweenPartsCounter = 0;
            m_incorrectTallyOfLabeledBoxesCounter = 0;
            m_fractionOfLargerAmountCounter = 0;
            m_intermediateNoBarCount = 0
            
            m_firstEmptyBarModelHintCounter = 0;
            
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, onBarModelCorrect);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, onBarModelIncorrect);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, smoothlyRemovePreviousHint);
        }
        
        override public function getHint():HintScript
        {
            var hintData:Object = generateBarModelMistakeHint();
            if (hintData == null)
            {
                hintData = {
                    descriptionContent: "If you think you have the right answer, press the check!"  
                };
            }
            
            var hintToRun:HintScript = HintCommonUtil.createHintFromMismatchData(
                hintData, 
                m_characterController, 
                m_assetManager, 
                m_gameEngine.getMouseState(),
                m_textParser, m_textViewFactory, m_textArea, m_gameEngine,
                200, 300
            );
            return hintToRun;
        }
        
        override public function dispose():void
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
        
        private function onBarModelGesturePerformed(event:Event):void
        {
            var gestureName:String = event.type;
            if (!m_gestureToFrequencyPerformed.hasOwnProperty(gestureName))
            {
                m_gestureToFrequencyPerformed[gestureName] = 0;
            }
            m_gestureToFrequencyPerformed[gestureName]++;
        }
        
        private function onBarModelCorrect():void
        {
            // If a correct bar model was selected, clear the hint as well
            smoothlyRemovePreviousHint();
        }
        
        private function smoothlyRemovePreviousHint():void
        {
            m_gameEngine.dispatchEventWith(GameEvent.REMOVE_HINT, false, {smoothlyRemove: true});
        }
        
        private function onBarModelIncorrect():void
        {
            m_numTimesSubmittedIncorrectModel++;
        }
        
        // In this mapping we want variables values to match the name on the card the player drags
        // Numbers are kept strictly as numbers, so '3 apples' on a card still should be replaced with '3'
        // in the hint, where as 'total apples' on a card should replace 'total_apples' if that was
        // the backing value.
        private function convertValueToAbbreviatedName(value:String):String
        {
            if (isNaN(parseFloat(value)))
            {
                var symbolData:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(value);
                if (symbolData.abbreviatedName != null && symbolData.abbreviatedName != "")
                {
                    value = symbolData.abbreviatedName;
                }
            }
            return value;
        }
        
        private function generateBarModelMistakeHint():Object
        {
            if (m_documentIdToExpressionMap == null)
            {
                m_documentIdToExpressionMap = m_textArea.getDocumentIdToExpressionMap();
            }
            
            // Do not not try to create a hint if the bar model is correct
            var playerBarModelSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
            if (playerBarModelSnapshot != null && !m_validateBarModelArea.getCurrentModelMatchesReference())
            {
                // Relace alias values in the given model (treat a set of values as one common one)
                playerBarModelSnapshot.replaceAllAliasValues(m_validateBarModelArea.getAliasValuesToTerms());
                var decomposedPlayerBarModel:DecomposedBarModelData = new DecomposedBarModelData(playerBarModelSnapshot);
                
                // If the user has not performed any relavant bar model action
                var numBarModelGesturesPerformed:int = 0;
                for (var gestureName:String in m_gestureToFrequencyPerformed)
                {
                    numBarModelGesturesPerformed += m_gestureToFrequencyPerformed[gestureName] as int;
                }
                

                var nextMismatchToShow:Object = getHighestPriorityDeepMismatch(playerBarModelSnapshot, decomposedPlayerBarModel);
                if (nextMismatchToShow == null)
                {
                    nextMismatchToShow = HintCommonUtil.getHighestPriorityShallowMismatch(
                        playerBarModelSnapshot,
                        decomposedPlayerBarModel,
                        m_validateBarModelArea.getReferenceModels(),
                        m_validateBarModelArea.getDecomposedReferenceModels());
                }
            }
            
            return nextMismatchToShow;
        }

		/*
		Common condition checks
        
        The trick to reduce code duplication, any type that looks the same except for the names
        being rearranged can use the same logic block
		*/
        private function getHighestPriorityDeepMismatch(userBarModelData:BarModelData,
                                                        userDecomposedModel:DecomposedBarModelData):Object
        {
            
            
            // TODO:
            // Some types can be represented with multiple target templates.
            // Have a single fixed template to compare against is not ideal in all situations.
            // The might have a different role in mind for a term than what is expected in a particular answer and
            // that role that might not match with one answer may work perfectly fine for another answer
            
            // All comments are the implicit mapping from doc id in the level
            // an element in the matching bar model template (see pictures used to make the reference model)
            var mistmatchData:Object = null;
            var barModelType:String = m_gameEngine.getCurrentLevel().getBarModelType();
            if (barModelType == BarModelTypes.TYPE_1A)
            {
                // b1 = b (part of sum), a1 = a (part of sum), unk = ? (total)
                mistmatchData = validatePartsAddToSum(m_documentIdToExpressionMap["unk"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_1B || barModelType == BarModelTypes.TYPE_2E)
            {
                // b1 = b (total), a1 = a (part of sum), unk = ? (part of sum)
                mistmatchData = validateDifferenceBetweenParts("b", "a", m_documentIdToExpressionMap["unk"], userBarModelData, userDecomposedModel);
            }
            // All Type2 problems can be changed to a sum model or have the smaller value and difference swapped out
            else if (barModelType == BarModelTypes.TYPE_2A)
            {
                // b1 = b (larger value), a1 = a (smaller value), unk = ? (difference)
                mistmatchData = validateDifferenceBetweenParts("b", "a", m_documentIdToExpressionMap["unk"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_2B)
            {
                // b1 = b (part of sum), a1 = a (part of sum), unk = ? (total)
                mistmatchData = validatePartsAddToSum(m_documentIdToExpressionMap["unk"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_2C)
            {
                // b1 = b (larger value), a1 = a (difference), unk = ? (smaller value)
                mistmatchData = validateDifferenceBetweenParts("b", "unk", m_documentIdToExpressionMap["a1"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_2D)
            {
                // b1 = b (difference), a1 = a (smaller value), unk = ? (larger value)
                mistmatchData = validateDifferenceBetweenParts("unk", "a", m_documentIdToExpressionMap["b1"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_3A)
            {
                // b1 = b (num groups), a1 = a (value one groups), unk = ? (sum of group)
                // Check if equal sized groups
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["a1"], false, true, null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_3B)
            {
                // b1 = b (sum of groups), a1 = a (num groups), unk = ? (value one group)
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["a1"]),
                    m_documentIdToExpressionMap["b1"],
                    m_documentIdToExpressionMap["unk"], 
                    false, true, null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_4A)
            {
                // unk = ? (sum of groups), a1 = a (value of unit), b1 = b (num groups)
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["a1"], 
                    false, false, null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_4B)
            {
                // unk = ? (value of unit), a1 = a (sum of groups), b1 = b (num groups)
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["unk"], 
                    false, false, null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_4C)
            {
                // unk = ? (difference), a1 = a (value of unit), b1 = b (num groups)
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["b1"]), 
                    null,
                    m_documentIdToExpressionMap["a1"],
                    true, false,
                    m_documentIdToExpressionMap["unk"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_4D)
            {
                // unk = ? (sum of group), a1 = a (value of unit), b1 = b (num groups)
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["unk"], 
                    m_documentIdToExpressionMap["a1"],
                    true, true, null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_4E)
            {
                // unk = ? (value of unit), a1 = a (difference), b1 = b (num groups)
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["b1"]),
                    null,
                    m_documentIdToExpressionMap["unk"],
                    true, false,
                    m_documentIdToExpressionMap["a1"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_4F)
            {
                // unk = ? (value of unit), a1 = a (total), b1 = b (num groups)
                mistmatchData = validateGroupsEqualSum(parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["a1"], 
                    true, true, null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5A)
            {
                // unk = ? (total), a1 = a (larger part), b1 = b (difference) c = c (smaller part)
                mistmatchData = validateSumAndDifferenceWithIntermediate(m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["b1"],
                    m_documentIdToExpressionMap["unk"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5B)
            {
                // unk = ? (total), a1 = a (smaller part), b1 = b (difference) c = c (larger part)
                mistmatchData = validateSumAndDifferenceWithIntermediate(m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["b1"],
                    m_documentIdToExpressionMap["unk"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5C)
            {
                // unk = ? (difference), a1 = a (larger part), b1 = b (total) c = c (smaller part)
                mistmatchData = validateSumAndDifferenceWithIntermediate(m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["b1"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5D)
            {
                // unk = ? (smaller part), a1 = a (difference), b1 = b (total) c = c (larger part)
                mistmatchData = validateSumAndDifferenceWithIntermediate(m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["b1"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5E)
            {
                // unk = ? (larger part), a1 = a (difference), b1 = b (total) c = c (smaller part)
                mistmatchData = validateSumAndDifferenceWithIntermediate(m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["b1"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5F)
            {
                // unk = ? (difference), a1 = a (sum of groups), b1 = b (number of groups) c = c (unit value)
                mistmatchData = validateSumOfGroupsWithIntermediate(parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["a1"], null,
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["unk"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5G)
            {
                // unk = ? (total), a1 = a (sum of groups), b1 = b (number of groups) c = c (unit value)
                mistmatchData = validateSumOfGroupsWithIntermediate(parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["unk"], null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5H)
            {
                // unk = ? (sum of groups), a1 = a (difference), b1 = b (number of groups) c = c (unit value)
                mistmatchData = validateSumOfGroupsWithIntermediate(parseInt(
                    m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["unk"], 
                    null,
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["a1"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5I)
            {
                // unk = ? (total), a1 = a (difference), b1 = b (number of groups) c = c (unit value)
                mistmatchData = validateSumOfGroupsWithIntermediate(
                    parseInt(m_documentIdToExpressionMap["b1"]),
                    null, 
                    m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["a1"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5J)
            {
                // unk = ? (sum of groups), a1 = a (total), b1 = b (number of groups) c = c (unit value)
                mistmatchData = validateSumOfGroupsWithIntermediate(
                    parseInt(m_documentIdToExpressionMap["b1"]),
                    m_documentIdToExpressionMap["unk"],
                    m_documentIdToExpressionMap["a1"], 
                    m_documentIdToExpressionMap["c"],
                    null,
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_5K)
            {
                // unk = ? (difference), a1 = a (total), b1 = b (number of groups) c = c (unit value)
                mistmatchData = validateSumOfGroupsWithIntermediate(
                    parseInt(m_documentIdToExpressionMap["b1"]),
                    null, 
                    m_documentIdToExpressionMap["a1"],
                    m_documentIdToExpressionMap["c"],
                    m_documentIdToExpressionMap["unk"],
                    userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_6A)
            {
                // unk = ? (sum of shaded), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (total)
                var numGroupsTotal:int = parseInt(m_documentIdToExpressionMap["a2"]);
                var numGroupsShaded:int = parseInt(m_documentIdToExpressionMap["a1"]);
                var numGroupsUnshaded:int = numGroupsTotal - numGroupsShaded;
                mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["b1"], m_documentIdToExpressionMap["unk"], null, null, userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_6B)
            {
                // unk = ? (sum of unshaded), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (total) 
                numGroupsTotal = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = numGroupsTotal - numGroupsShaded;
                mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["b1"], null, m_documentIdToExpressionMap["unk"], null, userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_6C)
            {
                // unk = ? (total), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (sum of shaded)
                numGroupsTotal = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = numGroupsTotal - numGroupsShaded;
                mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["unk"], m_documentIdToExpressionMap["b1"], null, null, userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_6D)
            {
                // unk = ? (sum of unshaded), a1 = a (num groups shaded), a2 = c (num groups total), b1 = b (sum of shaded)
                numGroupsTotal = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = numGroupsTotal - numGroupsShaded;
                mistmatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, m_documentIdToExpressionMap["b1"], m_documentIdToExpressionMap["unk"], null, userBarModelData, userDecomposedModel);
            }
            // An important distinguishing factor between type 6 and type 7 problems is that in type 7
            // there are two different types of objects, one of which represents the 'whole' and the other type a fraction of that 'whole'
            // Thus the total number of groups is not as clear, it is the numerator of the sum of fraction + whole with the fixed denomator
            else if (barModelType == BarModelTypes.TYPE_7A)
            {
                // unk = ? (sum of unshaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (sum of shaded)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, m_documentIdToExpressionMap["b1"], m_documentIdToExpressionMap["unk"], null, userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7B)
            {
                // unk = ? (total), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (sum of shaded)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["unk"], m_documentIdToExpressionMap["b1"], null, null, userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7C)
            {
                // unk = ? (difference), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (sum of shaded)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, m_documentIdToExpressionMap["b1"], null, m_documentIdToExpressionMap["unk"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7D_1)
            {
                // unk = ? (sum of unshaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (total) 
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["b1"], null, m_documentIdToExpressionMap["unk"], null, userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7D_2)
            {
                // unk = ? (sum of shaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (total)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["b1"], m_documentIdToExpressionMap["unk"], null, null, userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7E)
            {
                // unk = ? (difference), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (total)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["b1"], null, null, m_documentIdToExpressionMap["unk"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7F_1)
            {
                // unk = ? (sum of unshaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (difference)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, null, m_documentIdToExpressionMap["unk"], m_documentIdToExpressionMap["b1"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7F_2)
            {
                // unk = ? (sum of shaded), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (difference)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, null, m_documentIdToExpressionMap["unk"], null, m_documentIdToExpressionMap["b1"], userBarModelData, userDecomposedModel);
            }
            else if (barModelType == BarModelTypes.TYPE_7G)
            {
                // unk = ? (total), a1 = a (numerator of whole shaded), a2 = c (denominator of whole shaded), b1 = b (difference)
                numGroupsShaded = parseInt(m_documentIdToExpressionMap["a1"]);
                numGroupsUnshaded = parseInt(m_documentIdToExpressionMap["a2"]);
                numGroupsTotal =  numGroupsShaded + numGroupsUnshaded;
                mistmatchData = validateFractionOfLargerAmount(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, m_documentIdToExpressionMap["unk"], null, null, m_documentIdToExpressionMap["b1"], userBarModelData, userDecomposedModel);
            }
            
            return mistmatchData;
        }
        
        /**
         * Bar model types based on several different sized parts equaling a sum value
         */
        private function validatePartsAddToSum(sumValue:String,
                                               userBarModelData:BarModelData,
                                               userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            if (userDecomposedModel.numBarWholes == 0)
            {
                var labelName:String = "PartsAddToSumA";
                mismatchData = getHintFromLabel(labelName, null);
            }
            
            // Assume parts of the sum are all other expression values not equal to the sum value
            var partsInSumValues:Vector.<String> = new Vector.<String>();
            for (var documentId:String in m_documentIdToExpressionMap)
            {
                var expressionValue:String = m_documentIdToExpressionMap[documentId];
                if (expressionValue != sumValue)
                {
                    partsInSumValues.push(expressionValue);
                }
            }
            
            // For the sum related model the hints we care about relate to making sure the user understands
            // what are all the parts being added together AND what value represents the sum.
            
            // Are all parts in the sum present?
            // If not the user needs to add them.
            var missingLabelInSum:String = getFirstMissingLabelFromModel(partsInSumValues, userDecomposedModel);
            if (missingLabelInSum != null && mismatchData == null)
            {
                // For custom hints, we are interested in what bar model doc ids have been added
                // Some hints will need to know the missing part to target
                var docIdsExistingAsPartOfSum:Array = [];
                for (var existingLabelValue:String in userDecomposedModel.labelValueToType)
                {
                    var labelType:String = userDecomposedModel.labelValueToType[existingLabelValue];
                    if (labelType == "n")
                    {
                        for (var docId:String in m_documentIdToExpressionMap)
                        {
                            if (existingLabelValue == m_documentIdToExpressionMap[docId])
                            {
                                docIdsExistingAsPartOfSum.push(docId);
                            }
                        }
                    }
                }
                var targetDocId:String = getDocIdRelatedToValue(missingLabelInSum)
                var filterData:Object = {targetMissingDocId: targetDocId};
                
                m_missingSumPartCounter++;
                
                if (m_missingSumPartCounter > 2)
                {
                    labelName = "PartsAddToSumB";
                    mismatchData = getHintFromLabel(labelName, [convertValueToAbbreviatedName(missingLabelInSum)], filterData);
                }
                else if (m_missingSumPartCounter > 1)
                {
                    labelName = "PartsAddToSumC";
                    mismatchData = getHintFromLabel(labelName, [convertValueToAbbreviatedName(missingLabelInSum)], filterData);
                }
                else
                {
                    labelName = "PartsAddToSumD";
                    mismatchData = getHintFromLabel(labelName, [convertValueToAbbreviatedName(missingLabelInSum)], filterData);
                }
            }
            
            // Check if the number of boxes with labels matches the first reference model to check against
            if (mismatchData == null)
            {
                mismatchData = generateIncorrectCountOfSingleLabeledBoxes(userBarModelData);
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
                var labelAmountMuliplier:Vector.<int> = new Vector.<int>();
                for each (var partInSum:String in partsInSumValues)
                {
                    labelAmountMuliplier.push(1);
                }
                
                if (!checkLabelSumOfOtherLabels(sumValue, partsInSumValues, labelAmountMuliplier, userDecomposedModel))
                {
                    labelName = "PartsAddToSumE";
                    mismatchData = getHintFromLabel(labelName, [convertValueToAbbreviatedName(sumValue)]);

                }
            }
            
            return mismatchData;
        }
        
        private function generateIncorrectCountOfSingleLabeledBoxes(userBarModelData:BarModelData):Object
        {
            var mismatchData:Object = null;
            if (m_validateBarModelArea.getReferenceModels().length > 0)
            {
                var targetReferenceModel:BarModelData = m_validateBarModelArea.getReferenceModels()[0];
                var referenceTally:Object = this.getBarSegmentCountPerExpressionValue(targetReferenceModel);
                var userTally:Object = this.getBarSegmentCountPerExpressionValue(userBarModelData);
                for (var barLabelValue:String in referenceTally)
                {
                    var referenceCountForValue:int = referenceTally[barLabelValue];
                    var userCountForValue:int = (userTally.hasOwnProperty(barLabelValue)) ? userTally[barLabelValue] : 0;
                    if (userCountForValue != referenceCountForValue)
                    {
                        var description:String;
                        if (m_incorrectTallyOfLabeledBoxesCounter == 0)
                        {
                            if (userCountForValue > referenceCountForValue)
                            {
                                description = "You used the value \'" + barLabelValue + "\' in too many boxes!";
                            }
                            else
                            {
                                description = "You need to make more boxes using the value \'" + barLabelValue + "\'!";
                            }
                        }
                        else
                        {
                            if (referenceCountForValue == 1)
                            {
                                description = "You should make just one box using the value \'" + barLabelValue + "\'!";
                            }
                            else
                            {
                                description = "You should make " + referenceCountForValue + " boxes using the value \'" + barLabelValue + "\'!";
                            }
                        }
                        
                        mismatchData = {
                            descriptionContent: description  
                        };
                    }
                }
            }
            
            if (mismatchData != null)
            {
                m_incorrectTallyOfLabeledBoxesCounter++;
            }
            
            // These extra hints should only be used with the customized hints baked into level xml
            return (m_playerStatsAndSaveData.useCustomHints) ? mismatchData : null;
        }
        
        /**
         * Since each larger or smaller piece can be composed of several parts, a prefix is necessary
         * to figure out what composes each piece
         */
        private function validateDifferenceBetweenParts(largerValuePrefix:String, 
                                                        smallerValuePrefix:String, 
                                                        differenceValue:String,
                                                        userBarModelData:BarModelData,
                                                        userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            // Figure out the values that compose both the larger and smaller parts
            var partsInLarger:Vector.<String> = new Vector.<String>();
            var partsInSmaller:Vector.<String> = new Vector.<String>();
            for (var documentId:String in m_documentIdToExpressionMap)
            {
                var expressionValue:String = m_documentIdToExpressionMap[documentId];
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
                var labelId:String = "DifferenceBetweenPartsA";
                if (m_differenceBetweenPartsCounter > 0)
                {
                    labelId = "DifferenceBetweenPartsB";
                }
                mismatchData = getHintFromLabel(labelId, null);
                
                m_differenceBetweenPartsCounter++;
            }
            
            // For simple difference related models we care about asking for the larger and smaller values
            // and then identifying the differences between them.
            // Make sure the larger values have been added
            // Make sure the smaller values have been added
            if (mismatchData == null)
            {
                var missingLabelInSmaller:String = getFirstMissingLabelFromModel(partsInSmaller, userDecomposedModel);
                var missingLabelInLarger:String = getFirstMissingLabelFromModel(partsInLarger, userDecomposedModel);
                mismatchData = generateGenericMissingPartsOfDifference(missingLabelInLarger, missingLabelInSmaller, userDecomposedModel);
            }
            
            // Check if the number of boxes with labels matches the first reference model to check against
            if (mismatchData == null)
            {
                mismatchData = generateIncorrectCountOfSingleLabeledBoxes(userBarModelData);
            }
            
            // Make sure a difference with the specified value has been added
            // Due to game mechanics, it necessary for the values to be on separate lines
            // The player needs to know how the difference gesture looks like
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
        private function generateGenericMissingSumHints(totalValue:String, 
                                                        userDecomposedModel:DecomposedBarModelData, 
                                                        useHorizontalLabelForSum:Boolean=true):Object
        {
            var mismatchData:Object = null;
            if (!userDecomposedModel.labelValueToType.hasOwnProperty(totalValue))
            {
                // Have tried to add a label spanning a sum of boxes
                var timesAddedHorizontalLabel:int = (m_gestureToFrequencyPerformed.hasOwnProperty(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL))
                    ? m_gestureToFrequencyPerformed[AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL] : 0;
                var timesAddedVerticalLabel:int = (m_gestureToFrequencyPerformed.hasOwnProperty(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL))
                    ? m_gestureToFrequencyPerformed[AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL] : 0;
                if (timesAddedHorizontalLabel + timesAddedVerticalLabel == 0 && m_missingSumLabelCounter > 0)
                {
                    var labelName:String = "GenericMissingSumHintsA";
                    if (useHorizontalLabelForSum)
                    {
                        var hintParams:Array = [TipsViewer.NAME_MANY_BOXES];
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
                    
                    hintParams = null;
                    if (m_missingSumLabelCounter > 2)
                    {
                        labelName = "GenericMissingSumHintsB";
                        hintParams = [convertValueToAbbreviatedName(totalValue)];
                    }
                    else if (m_missingSumLabelCounter > 1)
                    {
                        labelName = "GenericMissingSumHintsC";
                    }
                    else
                    {
                        if (m_documentIdToExpressionMap["unk"] == totalValue)
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
        
        private function generateGenericMissingPartsOfDifference(missingLargerValue:String, 
                                                                 missingSmallerValue:String, 
                                                                 userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;

            if (missingLargerValue != null && !userDecomposedModel.labelValueToType.hasOwnProperty(missingLargerValue))
            {
                var docIdForLargerValue:String = getDocIdRelatedToValue(missingLargerValue);
                m_missingLargerDifferencePartCounter++;
                
                if (m_missingLargerDifferencePartCounter > 2)
                {
                    var labelId:String = "GenericMissingPartsOfDifferenceA";
                    mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(missingLargerValue), docIdForLargerValue], {targetMissingDocId: docIdForLargerValue});
                }
                else if (m_missingLargerDifferencePartCounter > 1)
                {
                    labelId = "GenericMissingPartsOfDifferenceB";
                    mismatchData = getHintFromLabel(labelId, [docIdForLargerValue]);
                }
                else
                {
                    labelId = "GenericMissingPartsOfDifferenceC";
                    mismatchData = getHintFromLabel(labelId, [docIdForLargerValue]);
                }
            }
            
            if (mismatchData == null && missingSmallerValue != null && !userDecomposedModel.labelValueToType.hasOwnProperty(missingSmallerValue))
            {
                var docIdForSmallerValue:String = getDocIdRelatedToValue(missingSmallerValue);
                m_missingSmallerDifferencePartCounter++;
                
                if (m_missingSmallerDifferencePartCounter > 2)
                {
                    labelId = "GenericMissingPartsOfDifferenceD";
                    mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(missingSmallerValue), docIdForSmallerValue], {targetMissingDocId: docIdForSmallerValue});
                }
                else if (m_missingSmallerDifferencePartCounter > 1)
                {
                    labelId = "GenericMissingPartsOfDifferenceE";
                    mismatchData = getHintFromLabel(labelId, [docIdForSmallerValue]);
                }
                else
                {
                    labelId = "GenericMissingPartsOfDifferenceF";
                    mismatchData = getHintFromLabel(labelId, [docIdForSmallerValue]);
                }
            }
            
            return mismatchData;
        }
        
        private function generateGenericDifferenceHints(differenceValue:String, 
                                                        userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            // Check that any difference exists and also
            // if a difference with the desired value exists
            var anyDifferenceExists:Boolean = false;
            var correctDifferenceExists:Boolean = false;
            var labelValueToType:Object = userDecomposedModel.labelValueToType;
            for (var labelValue:String in labelValueToType)
            {
                if (labelValueToType[labelValue] == "c")
                {
                    anyDifferenceExists = true;
                    if (labelValue == differenceValue)
                    {
                        correctDifferenceExists = true;
                    }
                }
            }

            var mistakeFound:Boolean = false;
            if (!anyDifferenceExists || !correctDifferenceExists)
            {
                // If never performed the add difference command AND the user has attempted some amount
                // of moves and/or incorrect submission we guess they do not know how to perform the action
                var timesPeformedAddDifference:int = (m_gestureToFrequencyPerformed.hasOwnProperty(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON)) ?
                    m_gestureToFrequencyPerformed[AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON] : 0;
                
                // Special case to point out the unknown as the difference is missing
                if (!userDecomposedModel.labelValueToType.hasOwnProperty(differenceValue) && m_documentIdToExpressionMap["unk"] == differenceValue)
                {
                    mistakeFound = true;
                    var labelId:String = "GenericDifferenceHintsA";
                    mismatchData = getHintFromLabel(labelId, null);
                }
                else if (userDecomposedModel.labelValueToType.hasOwnProperty(differenceValue))
                {
                    mistakeFound = true;
                    labelId = "GenericDifferenceHintsB";
                    mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(differenceValue)]);
                }
                else if (timesPeformedAddDifference < 1 && m_incorrectDifferenceCounter > 0)
                {
                    mistakeFound = true;
                    labelId = "GenericDifferenceHintsC";
                    mismatchData = getHintFromLabel(labelId, [TipsViewer.SUBTRACT_WITH_BOXES]);
                }
                else
                {
                    mistakeFound = true;
                    
                    // Gradually reveal more information about the hint as the user continues to input wrong answers
                    var missingDifferenceContent:String;
                    m_incorrectDifferenceCounter++;
                    
                    if (m_incorrectDifferenceCounter > 2)
                    {
                        labelId = "GenericDifferenceHintsD";
                        mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(differenceValue)]);
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
            
            if (mistakeFound)
            {
                
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
        private function generateGenericEqualGroupsHints(groupsExpected:int,
                                                         separateUnitGroup:Boolean,
                                                         userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            // If the unit group is a separate entity then we need to also account for when the player includes
            // the unit as a separate piece
            var correctNumberOfGroupsWithoutUnit:Boolean = checkEqualSizedGroupsExists(groupsExpected, userDecomposedModel);
            var doShowHintsWithoutUnit:Boolean = !correctNumberOfGroupsWithoutUnit;
            if (separateUnitGroup)
            {
                // The unit hint only shows up in the edge case where the user has created the right number of parts
                // on line but is missing the extra unit on a separate line.
                var correctNumberOfGroupsWithUnit:Boolean = checkEqualSizedGroupsExists(groupsExpected + 1, userDecomposedModel);
                if (!correctNumberOfGroupsWithUnit && correctNumberOfGroupsWithoutUnit)
                {
                    var labelName:String = "GenericEqualGroupsHintsA";
                    mismatchData = getHintFromLabel(labelName, null);
                }
                
                // DO NOT show the general unit hints if we have already picked on in this branch
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
                var timesAttemptedAddUnit:int = 0;
                if (m_gestureToFrequencyPerformed.hasOwnProperty(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR))
                {
                    timesAttemptedAddUnit = m_gestureToFrequencyPerformed[AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR];
                }
                
                var timesAttemptedMultiply:int = 0;
                if (m_gestureToFrequencyPerformed.hasOwnProperty(AlgebraAdventureLoggingConstants.MULTIPLY_BAR))
                {
                    timesAttemptedMultiply = m_gestureToFrequencyPerformed[AlgebraAdventureLoggingConstants.MULTIPLY_BAR];
                }
                
                if (timesAttemptedAddUnit + timesAttemptedMultiply < 1 && m_wrongGroupsCounter > 0)
                {
                    // If the user has never tried to use one of the gestures to make equal sized boxes, point
                    // out the tip in the help section to tell them how it is done.
                    labelName = "GenericEqualGroupsHintsB";
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
                        labelName = "GenericEqualGroupsHintsC";
                        mismatchData = getHintFromLabel(labelName, [groupsExpected]);
                    }
                    else if (m_wrongGroupsCounter > 1)
                    {
                        labelName = "GenericEqualGroupsHintsD";
                        mismatchData = getHintFromLabel(labelName, null);
                    }
                    else
                    {
                        labelName = "GenericEqualGroupsHintsD";
                        mismatchData = getHintFromLabel(labelName, null);
                    }
                    
                    // TODO: Make a guess about how many equal sized groups the user has and figure out how many more they actually need
                }
            }
            
            return mismatchData;
        }
        
        // Helper used by the validate functions
        private function getFirstMissingLabelFromModel(labelNames:Vector.<String>, 
                                                       decomposedModel:DecomposedBarModelData):String
        {
            var firstMissingLabel:String = null;
            for each (var labelName:String in labelNames)
            {
                if (!decomposedModel.labelValueToType.hasOwnProperty(labelName))
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
        private function validateGroupsEqualSum(groupsExpected:int,
                                                sumValue:String,
                                                unitValue:String,
                                                isUnitSeparate:Boolean,
                                                doesSumIncludeUnit:Boolean,
                                                differenceValue:String, 
                                                userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            if (userDecomposedModel.numBarWholes == 0 && m_firstEmptyBarModelHintCounter < 1)
            {
                var labelId:String = "GroupsEqualSumA";
                mismatchData = getHintFromLabel(labelId, null);
                m_firstEmptyBarModelHintCounter++;
            }
            
            if (mismatchData == null)
            {
                mismatchData = generateGenericEqualGroupsHints(groupsExpected, isUnitSeparate, userDecomposedModel);
            }
            
            // Is the unit value added somewhere, important to indicate that this is the size
            // on one of the groups.
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
                    var numGroupsInSum:int = (isUnitSeparate && doesSumIncludeUnit) ? groupsExpected + 1 : groupsExpected;
                    var sumLabelCorrect:Boolean = checkLabelSumOfOtherLabels(sumValue, Vector.<String>([unitValue]), Vector.<int>([numGroupsInSum]), userDecomposedModel);
                    if (!sumLabelCorrect)
                    {
                        m_incorrectGroupSumCounter++;
                        if (m_incorrectGroupSumCounter == 1)
                        {
                            labelId = "GroupsEqualSumB";
                            mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(sumValue)]);
                        }
                        else
                        {
                            if (doesSumIncludeUnit)
                            {
                                labelId = "GroupsEqualSumC";
                                mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(sumValue)]);
                            }
                            else
                            {
                                labelId = "GroupsEqualSumD";
                                mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(sumValue), groupsExpected]);
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
        private function validateSumAndDifferenceWithIntermediate(largerPart:String, 
                                                                  smallerPart:String, 
                                                                  difference:String, 
                                                                  sum:String, 
                                                                  userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            // Understanding that there is a second unknown is the critical piece to knowing how
            // to solve this problem.
            if (mismatchData == null)
            {
                var intermediateValue:String = m_documentIdToExpressionMap["c"];
                mismatchData = generateIntermediateValueNotDiscoveredHint(intermediateValue);
            }
            
            if (mismatchData == null && userDecomposedModel.numBarWholes == 0 && m_intermediateNoBarCount == 0)
            {
                var labelId:String = "SumAndDifferenceWithIntermediateA";
                mismatchData = getHintFromLabel(labelId, null);
                m_intermediateNoBarCount++;
            }
            
            if (mismatchData == null)
            {
                mismatchData = generateGenericMissingPartsOfDifference(largerPart, smallerPart, userDecomposedModel);
            }
            
            // Make sure the user has placed the sum
            if (mismatchData == null)
            {
                mismatchData = generateGenericMissingSumHints(sum, userDecomposedModel, false)
                if (mismatchData == null && 
                    userDecomposedModel.labelValueToType.hasOwnProperty(sum) && 
                    !checkLabelSumOfOtherLabels(sum, Vector.<String>([largerPart, smallerPart]), Vector.<int>([1, 1]), userDecomposedModel))
                {
                    labelId = "SumAndDifferenceWithIntermediateB";
                    mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(sum)]);
                }
            }
            
            // Make sure the user has placed the difference
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
        private function validateSumOfGroupsWithIntermediate(groupsExpected:int, 
                                                             sumOfGroups:String,
                                                             total:String,
                                                             unitValue:String, 
                                                             difference:String, 
                                                             userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            // Check if missing the second unknown
            var intermediateValue:String = m_documentIdToExpressionMap["c"];
            mismatchData = generateIntermediateValueNotDiscoveredHint(intermediateValue);
            
            if (mismatchData == null && userDecomposedModel.numBarWholes == 0 && m_intermediateNoBarCount == 0)
            {
                var labelId:String = "SumOfGroupsWithIntermediateA";
                mismatchData = getHintFromLabel(labelId, null);
                m_intermediateNoBarCount++;
            }
            
            // Get hints related to incorrect number of groups for the fraction
            if (mismatchData == null)
            {
                mismatchData = generateGenericEqualGroupsHints(groupsExpected, true, userDecomposedModel);
            }
            
            if (mismatchData == null)
            {
                // Missing the intermediate value
                if (!userDecomposedModel.labelValueToType.hasOwnProperty(intermediateValue))
                {
                    labelId = "SumOfGroupsWithIntermediateB";
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
        
        private function generateIntermediateValueNotDiscoveredHint(intermediateValue:String):Object
        {
            var mismatchData:Object = null;
            var deckWidgets:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(DeckWidget);
            if (deckWidgets.length > 0)
            {
                var intermediateValueNotDiscovered:Boolean = true;
                var deckWidget:DeckWidget = deckWidgets[0] as DeckWidget;
                var expressionsInDeck:Vector.<Component> = deckWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                for each (var expressionInDeck:ExpressionComponent in expressionsInDeck)
                {
                    if (expressionInDeck.expressionString == intermediateValue)
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
                        var labelId:String = "IntermediateValueNotDiscoveredHintA";
                        mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(intermediateValue)]);
                    }
                    else if (m_intermediateUnknownNotFoundCounter > 1)
                    {
                        labelId = "IntermediateValueNotDiscoveredHintB";
                        mismatchData = getHintFromLabel(labelId, null);
                    }
                    else
                    {
                        labelId = "IntermediateValueNotDiscoveredHintC";
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
        private function validateSumsOfFraction(numGroupsTotal:int, 
                                                numGroupsShaded:int, 
                                                numGroupsUnshaded:int,
                                                total:String,
                                                sumOfShaded:String, 
                                                sumOfUnshaded:String,
                                                difference:String,
                                                userBarModel:BarModelData,
                                                userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            if (userDecomposedModel.numBarWholes == 0 && m_firstEmptyBarModelHintCounter < 1)
            {
                var labelId:String = "SumsOfFractionA";
                mismatchData = getHintFromLabel(labelId, null);
                m_firstEmptyBarModelHintCounter++;
            }
            
            // Check that the user has created the right number of total groups
            if (mismatchData == null && checkEqualSizedGroupsExists(numGroupsTotal, userDecomposedModel))
            {
                if (m_incorrectGroupsForFractionCounter == 0)
                {
                    labelId = "FractionEqualGroupsHintA";
                }
                else if (m_incorrectGroupsForFractionCounter == 1)
                {
                    labelId = "FractionEqualGroupsHintB";
                }
                else if (m_incorrectGroupsForFractionCounter == 2)
                {
                    labelId = "FractionEqualGroupsHintC";
                }
                else
                {
                    labelId = "FractionEqualGroupsHintD";
                }
                mismatchData = getHintFromLabel(labelId, null);
                m_incorrectGroupsForFractionCounter++;
            }
            
            // There are multiple points where a label needs to exist AND the label needs to cover
            // the correct number of equal sized groups
            if (sumOfShaded != null && mismatchData == null)
            {
                mismatchData = validateFractionLabel(sumOfShaded, numGroupsShaded, numGroupsTotal, userBarModel, userDecomposedModel);
            }
            
            if (sumOfUnshaded != null && mismatchData == null)
            {
                mismatchData = validateFractionLabel(sumOfUnshaded, numGroupsUnshaded, numGroupsTotal, userBarModel, userDecomposedModel);
            }
            
            // TODO: This gives a bad hint if there is an additional different sized box
            // and the total actually covers what looks like the right number of groups
            if (total != null && mismatchData == null)
            {
                mismatchData = generateGenericMissingSumHints(total, userDecomposedModel, false);
                
                if (mismatchData == null && !checkLabelSpanCorrectNumGroups(total, numGroupsTotal, userBarModel, userDecomposedModel))
                {
                    labelId = "SumsOfFractionB";
                    mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(total)]);
                }
            }
            
            if (difference != null && mismatchData == null)
            {
                mismatchData = generateGenericDifferenceHints(difference, userDecomposedModel);
            }
            
            return mismatchData;
        }
        
        private function validateFractionOfLargerAmount(numGroupsTotal:int, 
                                                        numGroupsShaded:int, 
                                                        numGroupsUnshaded:int,
                                                        total:String,
                                                        sumOfShaded:String, 
                                                        sumOfUnshaded:String,
                                                        difference:String,
                                                        userBarModel:BarModelData,
                                                        userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            if (userDecomposedModel.numBarWholes == 0 && m_firstEmptyBarModelHintCounter < 1)
            {
                var labelId:String = "FractionOfLargerAmountA";
                mismatchData = getHintFromLabel(labelId, null);
                m_firstEmptyBarModelHintCounter++;
            }
            
            // Check if the user has the correct number of equal sized groups
            // The correct total is the combination of parts of the whole and the fraction of the whole
            if (mismatchData == null && !checkEqualSizedGroupsExists(numGroupsTotal, userDecomposedModel))
            {
                // User has made the correct number of groups representing the shaded objects,
                // now they need to represent the unshaded
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
                    if (m_fractionOfLargerAmountCounter == 0)
                    {
                        labelId = "FractionOfLargerAmountD";
                        mismatchData = getHintFromLabel(labelId, null);
                    }
                    else if (m_fractionOfLargerAmountCounter == 1)
                    {
                        labelId = "FractionOfLargerAmountE";
                        mismatchData = getHintFromLabel(labelId, null);
                    }
                    else if (m_fractionOfLargerAmountCounter == 2)
                    {
                        labelId = "FractionOfLargerAmountF";
                        mismatchData = getHintFromLabel(labelId, [numGroupsShaded, numGroupsUnshaded, numGroupsTotal]);
                    }
                    else
                    {
                        labelId = "FractionOfLargerAmountG";
                        mismatchData = getHintFromLabel(labelId, [numGroupsUnshaded, numGroupsShaded]);

                        //labelId = "FractionOfLargerAmountH";
                        //mismatchData = getHintFromLabel(labelId, [numGroupsTotal, numGroupsUnshaded, numGroupsShaded]);
                    }
                    
                    m_fractionOfLargerAmountCounter++;
                }
            }
            
            // TODO: This may not be the best solution for the Type 7 problems,
            // The grouping hints this part talks about may not make sense
            if (mismatchData == null)
            {
                mismatchData = validateSumsOfFraction(numGroupsTotal, numGroupsShaded, numGroupsUnshaded, total, sumOfShaded, sumOfUnshaded, difference, userBarModel, userDecomposedModel);
            }
            
            return mismatchData;
        }
        
        private function validateUnitLabel(groupsExpected:int,
                                           unitValue:String,
                                           isUnitSeparate:Boolean,
                                           userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            // Make sure the unit is added somewhere and refers to just one group
            if (!userDecomposedModel.labelValueToType.hasOwnProperty(unitValue))
            {
                // After enough mistakes where the unit is missing, we should just give the answer
                m_missingUnitCounter++;
                
                if (m_missingUnitCounter < 2)
                {
                    var labelId:String = "UnitLabelA";
                    mismatchData = getHintFromLabel(labelId, null);
                }
                else
                {
                    labelId = "UnitLabelB";
                    mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(unitValue)]);
                }
            }
            else
            {
                // The unit should be spanning a fixed percentage of the total bar placed in the model
                // Also should be flexible enough to expand to handle cases where the unit value is a comletely separate
                var expectedUnitRatio:Number = 1 / groupsExpected;
                var expectedUnitRatioIfSeparate:Number = 1 / (groupsExpected + 1);
                const error:Number = 0.00001;
                if (isUnitSeparate && Math.abs(userDecomposedModel.labelToRatioOfTotalBoxes[unitValue] - expectedUnitRatioIfSeparate) > error ||
                    !isUnitSeparate && Math.abs(userDecomposedModel.labelToRatioOfTotalBoxes[unitValue] - expectedUnitRatio) > error)
                {
                    // The actual problem we are trying to detect is that the label on the unit is not on the correct proportion of box
                    // Any additional boxes will cause this to fail however, even if visually it looks like a label is on the correct
                    // looking group.
                    // Solution that will catch some of the cases (if the number of equal groups exactly equals the expected amount):
                    // Check if the model contains a tally of same sized boxes equal to the expected number of groups.
                    // Find the size of one of those groups and see if it matches the size of spanned by the unit value label.
                    var expectedNumberOfGroups:int = (isUnitSeparate) ? groupsExpected + 1 : groupsExpected;
                    var groupTallyIndex:int = userDecomposedModel.normalizedBarSegmentValueTally.indexOf(expectedNumberOfGroups);
                    if (groupTallyIndex != -1)
                    {   
                        var normalizedValueOfGroup:Number = userDecomposedModel.normalizedBarSegmentValuesList[groupTallyIndex];
                        if (Math.abs(userDecomposedModel.labelValueToNormalizedSegmentValue[unitValue] - normalizedValueOfGroup) > error)
                        {
                            if (m_incorrectUnitAmountCounter == 0)
                            {
                                labelId = "UnitLabelC";
                                mismatchData = getHintFromLabel(labelId, null);
                            }
                            else if (m_incorrectUnitAmountCounter == 1)
                            {
                                labelId = "UnitLabelD";
                                mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(unitValue)]);
                            }
                            else
                            {
                                labelId = "UnitLabelE";
                                mismatchData = getHintFromLabel(labelId, [convertValueToAbbreviatedName(unitValue), groupsExpected]);
                            }
                            m_incorrectUnitAmountCounter++;
                        }
                        // Here, it looks like the user has labeled the right group, it is just that there may be extra boxes
                        // that mess up the total ratio
                        else
                        {
                            labelId = "UnitLabelF";
                            mismatchData = getHintFromLabel(labelId, null);
                        }
                    }
                    else
                    {
                        labelId = "UnitLabelG";
                        mismatchData = getHintFromLabel(labelId, null);
                    }
                }
            }
            
            return mismatchData;
        }
        
        private function validateFractionLabel(fractionLabel:String, 
                                               numerator:int, 
                                               denominator:int,
                                               userModel:BarModelData,
                                               userDecomposedModel:DecomposedBarModelData):Object
        {
            var mismatchData:Object = null;
            
            // Check that the fraction label exists and is spanning the right number of groups
            if (!userDecomposedModel.labelValueToType.hasOwnProperty(fractionLabel) ||
                !checkLabelSpanCorrectNumGroups(fractionLabel, numerator, userModel, userDecomposedModel))
            {
                var docIdForFractionLabel:String = getDocIdRelatedToValue(fractionLabel);
                
                if (m_incorrectFractionLabel >= 2)
                {
                    var labelId:String = "FractionLabelA";
                    mismatchData = getHintFromLabel(labelId, 
                        [convertValueToAbbreviatedName(fractionLabel), numerator, denominator], {targetMissingDocId: docIdForFractionLabel});
                }
                else if (m_incorrectFractionLabel == 1)
                {
                    labelId = "FractionLabelB";
                    mismatchData = getHintFromLabel(labelId, [numerator, denominator], {targetMissingDocId: docIdForFractionLabel});
                }
                else
                {
                    labelId = "FractionLabelC";
                    mismatchData = getHintFromLabel(labelId, null, {targetMissingDocId: docIdForFractionLabel});
                }
                m_incorrectFractionLabel++;
            }
            
            return mismatchData;
        }
        
		/**     
		 * Condition to check that a specified number of equally sized boxes exist
         * in the model submitted by the user.
		 */
		private function checkEqualSizedGroupsExists(expectedNumGroups:int, 
													 actualModel:DecomposedBarModelData):Boolean
		{
			// Look through the box tally in the user submitted model,
            // as long as one of those equals the expected value then this
            // condition passes.
            var equalSizedGroupsExist:Boolean = false;
            var barRatioTallies:Vector.<int> = actualModel.normalizedBarSegmentValueTally;
            for each (var tally:int in barRatioTallies)
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
        private function checkLabelSpanCorrectNumGroups(labelValue:String, 
                                                        expectedNumGroups:int,
                                                        userModel:BarModelData,
                                                        userModelDecomposed:DecomposedBarModelData):Boolean
        {
            // Check if label exists
            var labelSpansCorrectAmount:Boolean = false;
            var continueSearch:Boolean = true;
            if (userModelDecomposed.labelValueToType.hasOwnProperty(labelValue))
            {
                // If so check that it is covering the correct amount of equal sized groups
                // This is a structural detail, we need to look through all the labels
                // Check if they span the correct number of boxes AND that all those boxes
                // are equal sizes
                var i:int;
                var barWholes:Vector.<BarWhole> = userModel.barWholes;
                for (i = 0; i < barWholes.length; i++)
                {
                    var barWhole:BarWhole = barWholes[i];
                    var barLabels:Vector.<BarLabel> = barWhole.barLabels;
                    var barSegments:Vector.<BarSegment> = barWhole.barSegments;
                    var j:int;
                    for (j = 0; j < barLabels.length; j++)
                    {
                        var barLabel:BarLabel = barLabels[j];
                        if (barLabel.value == labelValue && (barLabel.endSegmentIndex - barLabel.startSegmentIndex + 1) == expectedNumGroups)
                        {
                            // Make sure all the segments this bar covers have the same value
                            var segmentIndex:int;
                            var referenceSegmentAmount:Number = -1;
                            var allSegmentsEqualSize:Boolean = true;
                            for (segmentIndex = barLabel.startSegmentIndex; segmentIndex <= barLabel.endSegmentIndex; segmentIndex++)
                            {
                                var currentSegmentValue:Number = barSegments[segmentIndex].getValue();
                                
                                // First segment provides the value to compare against
                                if (referenceSegmentAmount < 0)
                                {
                                    referenceSegmentAmount = currentSegmentValue;
                                }
                                
                                // Boxes are not all equal size, this should fail
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
                            }
                            
                            // Stop after the first match
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
                    var verticalLabels:Vector.<BarLabel> = userModel.verticalBarLabels;
                    for (i = 0; i < verticalLabels.length; i++)
                    {
                        var verticalLabel:BarLabel = verticalLabels[i];
                        
                        if (verticalLabel.value == labelValue)
                        {
                            var numSegmentsPartOfLabel:int = 0;
                            referenceSegmentAmount = -1;
                            for (var barIndex:int = verticalLabel.startSegmentIndex; barIndex <= verticalLabel.endSegmentIndex; barIndex++)
                            {
                                barWhole = userModel.barWholes[barIndex];
                                barSegments = barWhole.barSegments;
                                numSegmentsPartOfLabel += barSegments.length;
                                allSegmentsEqualSize = true;
                                for (segmentIndex = 0; segmentIndex < barSegments.length; segmentIndex++)
                                {
                                    currentSegmentValue = barSegments[segmentIndex].getValue();
                                    if (referenceSegmentAmount < 0)
                                    {
                                        referenceSegmentAmount = currentSegmentValue;
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
                            }
                            
                            // Stop after first match
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
        private function checkLabelSumOfOtherLabels(totalLabelName:String, 
                                                    otherLabelNames:Vector.<String>,
                                                    otherLabelRatioMultiplier:Vector.<int>,
                                                    decomposedModel:DecomposedBarModelData):Boolean
        {
            // Go through the other labels and check the amount
            var isTotalTheSum:Boolean = false;
            
            var labelToValue:Object = decomposedModel.labelValueToNormalizedSegmentValue;
            if (labelToValue.hasOwnProperty(totalLabelName))
            {
                var numOtherLabels:int = otherLabelNames.length;
                var i:int;
                var otherLabelSum:Number = 0;
                for (i = 0; i < numOtherLabels; i++)
                {
                    var otherLabel:String = otherLabelNames[i];
                    if (labelToValue.hasOwnProperty(otherLabel))
                    {
                        otherLabelSum += otherLabelRatioMultiplier[i] * labelToValue[otherLabel];
                    }
                }
                
                var allowedError:Number = 0.001;
                if (Math.abs(labelToValue[totalLabelName] - otherLabelSum) < allowedError)
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
        private function isSumRepresentedAsBox(sumValue:String, userBarModel:BarModelData):Boolean
        {
            var isSumABox:Boolean = false;
            for each (var barWhole:BarWhole in userBarModel.barWholes)
            {
                for each (var barLabel:BarLabel in barWhole.barLabels)
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
        
        private function getDocIdRelatedToValue(value:String):String
        {
            var docIdRelatedToValue:String = null;
            for (var docId:String in m_documentIdToExpressionMap)
            {
                if (m_documentIdToExpressionMap[docId] == value)
                {
                    docIdRelatedToValue = docId;
                    break;
                }
            }
            
            return docIdRelatedToValue;
        }
        
        /**
         * For some hints, we want to point out the user should create more bar segments
         * using a particular value or indicate they have too many segments with a particular
         * value. Keep a tally of the number of times a segment with a label on top appears
         * to compare usage of a value between a reference model and the user model
         */
        private function getBarSegmentCountPerExpressionValue(barModelData:BarModelData):Object
        {
            var valueToBarSegmentCountMap:Object = {};
            for each (var barWhole:BarWhole in barModelData.barWholes)
            {
                for each (var barLabel:BarLabel in barWhole.barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_NONE)
                    {
                        if (!valueToBarSegmentCountMap.hasOwnProperty(barLabel.value))
                        {
                            valueToBarSegmentCountMap[barLabel.value] = 0;
                        }
                        
                        valueToBarSegmentCountMap[barLabel.value]++;
                    }
                }
            }
            
            return valueToBarSegmentCountMap;
        }
        
        private function getHintFromLabel(hintLabel:String, params:Array, filterData:Object=null):Object
        {
            // Convert the hint label to a 'step' within a particular type
            var hintData:Object = null;
            if (m_labelToStepMap.hasOwnProperty(hintLabel))
            {
                var generatedStepId:int = parseInt(m_labelToStepMap[hintLabel]);
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
}