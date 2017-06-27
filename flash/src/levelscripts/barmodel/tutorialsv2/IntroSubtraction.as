package levelscripts.barmodel.tutorialsv2
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import starling.display.DisplayObject;
    
    import wordproblem.callouts.CalloutCreator;
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.component.HighlightComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.GroupTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.CustomFillLogicHint;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.hints.selector.SimpleSubtractionHint;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewBarComparison;
    import wordproblem.scripts.barmodel.AddNewBarSegment;
    import wordproblem.scripts.barmodel.CardOnSegmentEdgeRadialOptions;
    import wordproblem.scripts.barmodel.RemoveBarComparison;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.ResetBarModelArea;
    import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.expression.PressToChangeOperator;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.text.DragText;
    import wordproblem.scripts.text.TextToCard;
    
    public class IntroSubtraction extends BaseCustomLevelScript
    {
        private var m_progressControl:ProgressControl;
        private var m_textReplacementControl:TextReplacementControl;
        private var m_temporaryTextureControl:TemporaryTextureControl;
        
        /**
         * Script controlling swapping between bar model and equation model.
         */
        private var m_switchModelScript:SwitchBetweenBarAndEquationModel;
        private var m_validateBarModel:ValidateBarModelArea;
        private var m_validateEquation:ModelSpecificEquation;
        
        private var m_textAreaWidget:TextAreaWidget;
        private var m_barModelArea:BarModelAreaWidget;
        
        private var m_differenceDocId:String = "part_a_difference";
        private var m_differenceValue:String = "diff_a";
        
        private var m_hintController:HelpController;
        private var m_addFirstNumberHint:HintScript;
        private var m_addSecondNumberHint:HintScript;
        private var m_addComparisonHint:HintScript;
        private var m_wrongAddHint:HintScript;
        private var m_equationSubtractionHint:HintScript;
        private var m_submitBarModelHint:HintScript;
        private var m_submitEquationHint:HintScript;
        private var m_isRadialMenuOpen:Boolean = false;
        
        // This problem deals with solving two diagrams.
        // The name of the 'total' in each diagram differs depending on the job
        // Create mapping from job to what the name of the total should be
        private var m_jobToTotalMapping:Object = {
            ninja: {diff_a_name: "more theft than sabatoge", diff_a_abbr: "mission difference", numeric_unit_larger_a: "theft", numeric_unit_smaller_a: "sabatoge",
                diff_b_name: "more scrolls than artifacts", diff_b_abbr: "item difference"},
            zombie: {diff_a_name: "more research than guard", diff_a_abbr: "more research",  numeric_unit_larger_a: "research", numeric_unit_smaller_a: "guard",
                diff_b_name: "more banana than flower", diff_b_abbr: "parts difference"},
            basketball: {diff_a_name: "difference in points", diff_a_abbr: "points difference",  numeric_unit_larger_a: "points", numeric_unit_smaller_a: "points",
                diff_b_name: "difference in points", diff_b_abbr: "points difference"},
            fairy: {diff_a_name: "more left than stayed", diff_a_abbr: "Pygmy difference",  numeric_unit_larger_a: "left", numeric_unit_smaller_a: "stayed",
                diff_b_name: "more stakes than statues", diff_b_abbr: "more stakes"},
            superhero: {diff_a_name: "more feathers than glue", diff_a_abbr: "more feathers",  numeric_unit_larger_a: "feathers", numeric_unit_smaller_a: "glue",
                diff_b_name: "more elbows than dropkicks", diff_b_abbr: "more elbows"}
        };
        
        private var m_activeLargerValue:int;
        private var m_activeSmallerValue:int;
        
        public function IntroSubtraction(gameEngine:IGameEngine, 
                                         expressionCompiler:IExpressionTreeCompiler, 
                                         assetManager:AssetManager, 
                                         playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                         id:String=null, 
                                         isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
            super.pushChild(m_switchModelScript);
            
            // At the start do not allow any changes to the bar model
            var prioritySelector:PrioritySelector = new PrioritySelector("barmodelgestures");
            var cardOnSegmentRadialOptions:CardOnSegmentEdgeRadialOptions = new CardOnSegmentEdgeRadialOptions(gameEngine, expressionCompiler, assetManager, "CardOnSegmentEdgeRadialOptions", false);
            prioritySelector.pushChild(cardOnSegmentRadialOptions);
            prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 2, "AddNewBar"));
            prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
            prioritySelector.pushChild(new RemoveBarComparison(gameEngine, expressionCompiler, assetManager, "RemoveBarComparison", false));
            prioritySelector.pushChild(new ShowBarModelHitAreas(m_gameEngine, m_expressionCompiler, m_assetManager, "CardOnSegmentEdgeRadialOptions"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            super.pushChild(prioritySelector);
            
            // Undo and reset bar model
            super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea", false));
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea", false));
            
            // Even though it is not necessary for this problem, include add segment action so user can see they need to make a choice
            var addNewBarSegment:AddNewBarSegment = new AddNewBarSegment(m_gameEngine, m_expressionCompiler, m_assetManager, "AddNewBarSegment");
            cardOnSegmentRadialOptions.addGesture(addNewBarSegment);
            var addNewBarComparison:AddNewBarComparison = new AddNewBarComparison(m_gameEngine, m_expressionCompiler, m_assetManager, "AddNewBarComparison");
            cardOnSegmentRadialOptions.addGesture(addNewBarComparison);
            
            super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
            
            // Creating basic equations
            super.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager));
            
            super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
            
            // Validating both parts of the problem modeling process
            m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
            super.pushChild(m_validateBarModel);
            m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
            super.pushChild(m_validateEquation);
            
            // Logic for text dragging + discovery
            super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
            super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
            super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
            
            m_addFirstNumberHint = new CustomFillLogicHint(showAddNumber, ["Add first number here.", 0], null, null, hideAddNumber, null, true);
            m_addSecondNumberHint = new CustomFillLogicHint(showAddNumber, ["Add the other number here", 60], null, null, hideAddNumber, null, true);
            m_addComparisonHint = new CustomFillLogicHint(showAddComparison, null, null, null, hideAddComparison, null, true);
            m_wrongAddHint = new CustomFillLogicHint(showWrongAdd, null, null, null, hideWrongAdd, null, true);
            m_equationSubtractionHint = new CustomFillLogicHint(showSubtractionHint, null, null, null, hideSubtractionHint, null, true);
            m_submitBarModelHint = new CustomFillLogicHint(showSubmitAnswer, ["validateButton"], null, null, hideSubmitAnswer, ["validateButton"], true);
            m_submitEquationHint = new CustomFillLogicHint(showSubmitAnswer, ["modelEquationButton"], null, null, hideSubmitAnswer, ["modelEquationButton"], true);
        }
        
        override public function visit():int
        {
            if (m_ready)
            {
                var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                if (m_progressControl.getProgressValueEquals("hinting", "parta_add_bars"))
                {
                    // Make sure both numbers have been added
                    var numBarWholesAdded:int = barWholes.length;
                    if (numBarWholesAdded == 0 && m_hintController.getCurrentlyShownHint() != m_addFirstNumberHint)
                    {
                        // Hint to add first number
                        m_hintController.manuallyShowHint(m_addFirstNumberHint);
                    }
                    else if (numBarWholesAdded == 1 && m_hintController.getCurrentlyShownHint() != m_addSecondNumberHint)
                    {
                        // Hint to add the other number
                        m_hintController.manuallyShowHint(m_addSecondNumberHint);
                    }
                    else if (numBarWholesAdded == 2)
                    {
                        m_hintController.manuallyRemoveAllHints();
                        
                        // Make sure the numbers are not removeable
                        var removeBarSegment:RemoveBarSegment = getNodeById("RemoveBarSegment") as RemoveBarSegment;
                        removeBarSegment.segmentIdsCannotRemove.push(barWholes[0].barSegments[0].id);
                        removeBarSegment.segmentIdsCannotRemove.push(barWholes[1].barSegments[0].id);
                        
                        // Allow adding comparison only after both bars added
                        getNodeById("CardOnSegmentEdgeRadialOptions").setIsActive(true);
                        
                        // Only make the unknown selectable after both bars added, also highlight it
                        (getNodeById("RestrictCardsInBarModel") as RestrictCardsInBarModel).setTermValuesToIgnore(null);
                        setDocumentIdsSelectable(Vector.<String>([m_differenceDocId]), true, 0);
                        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent(m_differenceDocId, 0xFF9900, 2));
                        
                        m_progressControl.setProgressValue("hinting", "parta_add_difference");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("hinting", "parta_add_difference"))
                {
                    if (barWholes.length < 2)
                    {
                        m_progressControl.setProgressValue("hinting", "parta_add_bars");
                    }
                    else
                    {
                        // Check if the difference has been added
                        var comparisonAdded:Boolean = barWholes[0].barComparison != null || barWholes[1].barComparison != null;
                        if (comparisonAdded)
                        {
                            // Model should be correct at this point, enable validate
                            m_validateBarModel.setIsActive(true);
                            if (m_hintController.getCurrentlyShownHint() != m_submitBarModelHint)
                            {
                                m_hintController.manuallyShowHint(m_submitBarModelHint);
                            }
                        }
                        else
                        {
                            // Check if they incorrectly added instead
                            var incorrectlyAdded:Boolean = barWholes[0].barSegments.length > 1 || barWholes[1].barSegments.length > 1;
                            if (incorrectlyAdded && !m_isRadialMenuOpen && m_hintController.getCurrentlyShownHint() != m_wrongAddHint)
                            {
                                m_hintController.manuallyShowHint(m_wrongAddHint);
                            }
                            // Point out the empty space to add the comparison
                            else if (!incorrectlyAdded && m_hintController.getCurrentlyShownHint() != m_addComparisonHint)
                            {
                                m_hintController.manuallyShowHint(m_addComparisonHint);
                            }
                            else if (!incorrectlyAdded && m_isRadialMenuOpen && m_hintController.getCurrentlyShownHint() == m_addComparisonHint)
                            {
                                m_hintController.manuallyRemoveAllHints();
                            }
                        }
                    }
                }
                else if (m_progressControl.getProgressValueEquals("hinting", "parta_subtraction_operator"))
                {
                    // Check if the used subtraction.
                    var leftTermArea:TermAreaWidget = m_gameEngine.getUiEntity("leftTermArea") as TermAreaWidget;
                    var rightTermArea:TermAreaWidget = m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
                    var usedSubtractionOperator:Boolean = leftTermArea.getWidgetRoot() != null && rightTermArea.getWidgetRoot() != null &&
                        (leftTermArea.getWidgetRoot().getNode().data == "-" || rightTermArea.getWidgetRoot().getNode().data == "-");
                    if (!usedSubtractionOperator && m_hintController.getCurrentlyShownHint() != m_equationSubtractionHint)
                    {
                        m_hintController.manuallyShowHint(m_equationSubtractionHint);   
                    }
                    else if (usedSubtractionOperator && m_hintController.getCurrentlyShownHint() != m_submitEquationHint)
                    {
                        m_hintController.manuallyShowHint(m_submitEquationHint);
                    }
                    
                    if (usedSubtractionOperator != m_validateEquation.getIsActive())
                    {
                        m_validateEquation.setIsActive(usedSubtractionOperator);
                    }
                }
            }
            return super.visit();
        }
        
        override public function getNumCopilotProblems():int
        {
            return 4;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_temporaryTextureControl.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.TERM_AREAS_CHANGED, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.OPEN_RADIAL_OPTIONS, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.CLOSE_RADIAL_OPTIONS, bufferEvent);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            super.disablePrevNextTextButtons();
            
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            m_gameEngine.getCurrentLevel().getLevelRules().allowSubtract = true;
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.OPEN_RADIAL_OPTIONS, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.CLOSE_RADIAL_OPTIONS, bufferEvent);
            
            // Clip out content not belonging to the character selected job
            var selectedPlayerJob:String = m_playerStatsAndSaveData.getPlayerDecision("job") as String;
            TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 0);
            //TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 1);
            
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
            super.pushChild(hintController);
            hintController.overrideLevelReady();
            m_hintController = hintController;
            
            var helperCharacterController:HelperCharacterController = new HelperCharacterController(
                m_gameEngine.getCharacterComponentManager(),
                new CalloutCreator(m_textParser, m_textViewFactory));
            m_hintController.setRootHintSelectorNode(new SimpleSubtractionHint(
                m_gameEngine, m_assetManager, m_textParser, m_textViewFactory, helperCharacterController, m_validateBarModel, m_validateEquation
            ));
            
            m_barModelArea = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_barModelArea.unitHeight = 60;
            m_barModelArea.unitLength = 100;
            m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            m_textAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
            
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            var slideUpPositionY:Number = m_gameEngine.getUiEntity("deckAndTermContainer").y;
            m_switchModelScript.setContainerOriginalY(slideUpPositionY);
            
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0, y:650}));
            
            // Show the question after a short delay
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    greyOutAndDisableButton("undoButton", true);
                    greyOutAndDisableButton("resetButton", true);
                    setDocumentIdVisible({id:"common_instructions", visible:true, pageIndex:0});
                    return ScriptStatus.SUCCESS;
                }, null));
            
            // Reveal the modeling ui after a short delay
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.6}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            
            // Initialize the first part of the problem
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_progressControl.setProgressValue("hinting", "parta_add_bars");
                    
                    m_switchModelScript.setIsActive(false);
                    var firstPartDocIdsForNumbers:Vector.<String> = Vector.<String>(["part_a_number_a", "part_a_number_b"]);
                    createBarAndEquationModelsFromElements(firstPartDocIdsForNumbers, m_differenceValue, m_differenceDocId, selectedPlayerJob, 0);
                    
                    var levelId:int = m_gameEngine.getCurrentLevel().getId();
                    var largerValue:String = TutorialV2Util.getNumberValueFromDocId("part_a_number_a", m_textAreaWidget);
                    assignColorToCardFromSeed(largerValue, levelId);
                    var smallerValue:String = TutorialV2Util.getNumberValueFromDocId("part_a_number_b", m_textAreaWidget);
                    assignColorToCardFromSeed(smallerValue, levelId);
                    assignColorToCardFromSeed(m_differenceValue, levelId);
                    
                    var dataForCard:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(largerValue);
                    dataForCard.abbreviatedName = largerValue + " " + m_jobToTotalMapping[selectedPlayerJob].numeric_unit_larger_a;
                    dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(smallerValue);
                    dataForCard.abbreviatedName = smallerValue + " " + m_jobToTotalMapping[selectedPlayerJob].numeric_unit_smaller_a;
                    
                    (getNodeById("RestrictCardsInBarModel") as RestrictCardsInBarModel).setTermValuesToIgnore(Vector.<String>([m_differenceValue]));
                    setDocumentIdsSelectable(Vector.<String>([m_differenceDocId]), false, 1);
                    return ScriptStatus.SUCCESS;
                }, null));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"parta_barmodel_finished"}));
            
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Disable the bar model actions
                    getNodeById("barmodelgestures").setIsActive(false);
                    m_progressControl.setProgressValue("hinting", "parta_subtraction_operator");
                    m_hintController.manuallyRemoveAllHints(false, true);
                    m_validateBarModel.setIsActive(false);
                    
                    // Set up a prebuilt equation for the first equation model using subtraction
                    m_gameEngine.setTermAreaContent("leftTermArea rightTermArea", "diff_a=" + m_activeLargerValue + "+" + m_activeSmallerValue);
                    
                    // Auto slide up to solve the equation
                    m_switchModelScript.setIsActive(true);
                    m_switchModelScript.onSwitchModelClicked();
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"parta_equation_finished"}));
            
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_hintController.manuallyRemoveAllHints();
                    m_progressControl.setProgressValue("hinting", null);
                    return ScriptStatus.SUCCESS;
                }, null));
            
            // End level after first euqation finished
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:1.0}));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            super.pushChild(sequenceSelector);
            
            var selectedGender:String = m_playerStatsAndSaveData.getPlayerDecision("gender") as String;
            m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 0);
            //m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 1);
            m_progressControl.setProgressValue("stage", "start");
            m_progressControl.setProgressValue("hinting", null);
        }
        
        private function createBarAndEquationModelsFromElements(docIdsForNumbers:Vector.<String>, 
                                                                unknownValue:String, 
                                                                unknownDocId:String, 
                                                                selectedPlayerJob:String, 
                                                                pageIndex:int):void
        {
            // Get the values from the text, use them to create the reference models and equations
            var numbersForModel:Vector.<int> = new Vector.<int>();
            
            setDocumentIdsSelectable(docIdsForNumbers, true, pageIndex);
            for each (var docId:String in docIdsForNumbers)
            {
                var value:String = TutorialV2Util.getNumberValueFromDocId(docId, m_textAreaWidget);
                m_gameEngine.addTermToDocument(value, docId);
                numbersForModel.push(parseInt(value));
            }
            
            m_gameEngine.addTermToDocument(unknownValue, unknownDocId);
            
            // Change the name of the symbol
            var expressionDataForTotal:Object = m_jobToTotalMapping[selectedPlayerJob];
            var symbolDataForTotal:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(unknownValue);
            symbolDataForTotal.abbreviatedName = expressionDataForTotal[unknownValue + "_abbr"];
            symbolDataForTotal.name = expressionDataForTotal[unknownValue + "_name"];
            
            // Create the reference bar model
            var referenceBarModels:Vector.<BarModelData> = new Vector.<BarModelData>();
            var correctModel:BarModelData = new BarModelData();
            for (var i:int = 0; i < numbersForModel.length; i++)
            {
                var barWholeValue:int = numbersForModel[i];
                var barWhole:BarWhole = new BarWhole(false, i + "");
                barWhole.barSegments.push(new BarSegment(barWholeValue, 1, 0xFFFFFFFF, null));
                barWhole.barLabels.push(new BarLabel(barWholeValue + "", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                correctModel.barWholes.push(barWhole);
            }
            
            // Add comparison construct (assuming just two values)
            var smallerIndex:int = 0;
            var largerIndex:int = 1;
            if (numbersForModel[0] > numbersForModel[1])
            {
                smallerIndex = 1;
                largerIndex = 0;
            }
            var smallerBarWhole:BarWhole = correctModel.barWholes[smallerIndex];
            smallerBarWhole.barComparison = new BarComparison(unknownValue, largerIndex + "", 0);
            
            referenceBarModels.push(correctModel);
            m_validateBarModel.setReferenceModels(referenceBarModels);
            
            // Keep track of the active numbers for a problem
            m_activeLargerValue = numbersForModel[largerIndex];
            m_activeSmallerValue = numbersForModel[smallerIndex];
            
            // Create the reference equation
            m_validateEquation.addEquation("unknownDocId", unknownValue + "=" + m_activeLargerValue + "-" + m_activeSmallerValue, false, true);
            
            // Set the bar value of the unknown
            var termValueToBarValue:Object = {};
            termValueToBarValue[unknownValue] = numbersForModel[largerIndex] - numbersForModel[smallerIndex]
            m_gameEngine.getCurrentLevel().termValueToBarModelValue = termValueToBarValue;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgressValueEquals("stage", "start"))
                {
                    m_progressControl.setProgressValue("stage", "parta_barmodel_finished");
                }
                else if (m_progressControl.getProgressValueEquals("stage", "partb_barmodel_start"))
                {
                    m_progressControl.setProgressValue("stage", "partb_barmodel_finished");
                }
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                if (m_progressControl.getProgressValueEquals("stage", "parta_barmodel_finished"))
                {
                    m_progressControl.setProgressValue("stage", "parta_equation_finished");
                }
                else if (m_progressControl.getProgressValueEquals("stage", "partb_barmodel_finished"))
                {
                    m_progressControl.setProgressValue("stage", "partb_equation_finished");   
                }
            }
            else if (eventType == GameEvent.OPEN_RADIAL_OPTIONS)
            {
                if (m_progressControl.getProgressValueEquals("hinting", "parta_add_difference"))
                {
                    // Show callout on the radial menu telling them to pick the subtraction option
                    var radialDisplay:DisplayObject = param.display;
                    var radialDisplayRenderComponent:RenderableComponent = new RenderableComponent("radialOptions");
                    radialDisplayRenderComponent.view = radialDisplay;
                    m_gameEngine.getUiComponentManager().addComponentToEntity(radialDisplayRenderComponent);
                    
                    showDialogForUi( {
                        id:"radialOptions", text:"Use subtract!", color:CALLOUT_TEXT_DEFAULT_COLOR, 
                        direction:Callout.DIRECTION_DOWN, animationPeriod:1 
                    } );
                }
                m_isRadialMenuOpen = true;
            }
            else if (eventType == GameEvent.CLOSE_RADIAL_OPTIONS)
            {
                // Remove dialog if still in the first part
                if (m_progressControl.getProgressValueEquals("stage", "start"))
                {
                    m_gameEngine.getUiComponentManager().removeAllComponentsFromEntity("radialOptions");
                }
                m_isRadialMenuOpen = false;
            }
        }
        
        private function onSwitchModelClicked(inBarModelMode:Boolean):void
        {
        }
        
        /*
        Logic for hints
        */
        private function showAddNumber(textContent:String, yOffset:Number):void
        {
            // Highlight the bar model area
            showDialogForUi({
                id:"barModelArea", text:textContent,
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_RIGHT, width:150, height:50, animationPeriod:1, xOffset:-300, yOffset:yOffset
            });
            
            m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("", 0xCCFF00, 2));
        }
        
        private function hideAddNumber():void
        {
            removeDialogForUi({id:"barModelArea"});
        }
        
        private var m_segmentIdToAddCalloutTo:String;
        private function showAddComparison():void
        {
            // Attach a callout to the smaller bar and offset it far to the right so it looks like it is pointing
            // to the space in the comparison.
            var barModelArea:BarModelAreaWidget = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            var barWholes:Vector.<BarWhole> = barModelArea.getBarModelData().barWholes;
            
            var smallerIndex:int = 0;
            var largerIndex:int = 1;
            if (barWholes[0].getValue() > barWholes[1].getValue())
            {
                smallerIndex = 1;
                largerIndex = 0;
            }
            
            var boundsLargerBar:Rectangle = barModelArea.getBarWholeViews()[largerIndex].getBounds(barModelArea);
            var boundsSmallerBar:Rectangle = barModelArea.getBarWholeViews()[smallerIndex].getBounds(barModelArea);
            var xOffset:Number = (boundsLargerBar.width - boundsSmallerBar.width) * 0.5;
            
            var barIdForCallout:String = barWholes[smallerIndex].barSegments[0].id;
            barModelArea.addOrRefreshViewFromId(barIdForCallout);
            showDialogForBaseWidget({
                id:barIdForCallout, widgetId:"barModelArea", text:"Drag the difference here!",
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_DOWN, width:250, height:40, animationPeriod:1, xOffset:xOffset, yOffset:0
            });
            m_segmentIdToAddCalloutTo = barIdForCallout;
        }
        
        private function hideAddComparison():void
        {
            removeDialogForBaseWidget({id:m_segmentIdToAddCalloutTo, widgetId:"barModelArea"});
        }
        
        private function showWrongAdd():void
        {
            // Identify the incorrect segment, add callout saying to remove it
            var targetSegmentId:String = null;
            var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
            for each (var barWhole:BarWhole in barWholes)
            {
                if (barWhole.barSegments.length == 2)
                {
                    var incorrectSegment:BarSegment = barWhole.barSegments[1];
                    targetSegmentId = incorrectSegment.id;
                    break;
                }
            }
            
            if (targetSegmentId != null)
            {
                m_barModelArea.addOrRefreshViewFromId(targetSegmentId);
                showDialogForBaseWidget({
                    id:targetSegmentId, widgetId:"barModelArea", text:"Not right!",
                    color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_DOWN, width:150, height:40, animationPeriod:1, xOffset:0, yOffset:0
                });
                m_segmentIdToAddCalloutTo = targetSegmentId;
            }
        }
        
        private function hideWrongAdd():void
        {
            removeDialogForBaseWidget({id:m_segmentIdToAddCalloutTo, widgetId:"barModelArea"});
        }
        
        private function showSubtractionHint():void
        {
            // Set dialog on the subtract term telling to click on it
            // Since it is not possible
            var subtractTermText:String = "Click to change to subtraction.";
            var rightTermArea:TermAreaWidget = m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
            var rightChildWidget:BaseTermWidget = rightTermArea.getWidgetRoot().rightChildWidget;
            var xOffset:Number = 0;
            if (rightChildWidget.stage != null)
            {
                // Assuming the operator to click is to the left of the right term
                // Figure out the xOffset such that the callout floats over the middle of the operator image
                var operatorDisplay:DisplayObject = (rightTermArea.getWidgetRoot() as GroupTermWidget).groupImage;
                var operatorBounds:Rectangle = operatorDisplay.getBounds(rightTermArea);
                var rightTermBounds:Rectangle = rightChildWidget.getBounds(rightTermArea);
                xOffset -= (rightTermBounds.x - (operatorBounds.x + operatorBounds.width * 0.5)) + rightTermBounds.width * 0.5
            }
            
            var subtractTermId:String = rightChildWidget.getNode().id + "";
            showDialogForBaseWidget({
                id:subtractTermId, widgetId:"rightTermArea", text:subtractTermText, 
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_UP, width:200, xOffset:xOffset, animationPeriod:1
            });
        }
        
        private function hideSubtractionHint():void
        {
            var rightTermArea:TermAreaWidget = m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
            if (rightTermArea != null)
            {
                var subtractTermId:String = rightTermArea.getWidgetRoot().rightChildWidget.getNode().id + "";
                removeDialogForBaseWidget({id:subtractTermId, widgetId:"rightTermArea"});
            }
        }
        
        private function showSubmitAnswer(uiEntity:String):void
        {
            // Highlight the validate button
            showDialogForUi({
                id:uiEntity, text:"Click when done.",
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_UP, width:170, height:40, animationPeriod:1
            });
        }
        
        private function hideSubmitAnswer(uiEntity:String):void
        {
            removeDialogForUi({id:uiEntity});
        }
    }
}