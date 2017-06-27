package levelscripts.barmodel.tutorialsv2
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.component.HighlightComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.CustomFillLogicHint;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewBarComparison;
    import wordproblem.scripts.barmodel.AddNewVerticalLabel;
    import wordproblem.scripts.barmodel.BarToCard;
    import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckCallout;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.expression.AddTerm;
    import wordproblem.scripts.expression.PressToChangeOperator;
    import wordproblem.scripts.expression.RemoveTerm;
    import wordproblem.scripts.expression.ResetTermArea;
    import wordproblem.scripts.expression.UndoTermArea;
    import wordproblem.scripts.expression.systems.SaveEquationInSystem;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.text.DragText;
    import wordproblem.scripts.text.TextToCard;
    
    public class IntroTwoStepNoGroups extends BaseCustomLevelScript
    {
        private var m_progressControl:ProgressControl;
        private var m_textReplacementControl:TextReplacementControl;
        private var m_temporaryTextureControl:TemporaryTextureControl;
        
        private var m_switchModelScript:SwitchBetweenBarAndEquationModel;
        private var m_validateBarModel:ValidateBarModelArea;
        private var m_validateEquation:ModelSpecificEquation;
        
        private var m_textAreaWidget:TextAreaWidget;
        private var m_barModelArea:BarModelAreaWidget;
        private var m_hintController:HelpController;
        
        private var m_unknownSmaller:String = "unknown_a";
        private var m_unknownSmallerIntValue:int;
        private var m_unknownLarger:String = "unknown_b";
        private var m_unknownLargerIntValue:int;
        private var m_sum:String;
        private var m_difference:String;
        
        private var m_unknownSmallerDocId:String;
        private var m_unknownLargerDocId:String;
        private var m_sumDocId:String;
        private var m_differenceDocId:String;
        
        private var m_barElementIdsToHighlight:Vector.<String>;
        
        private var m_addFirstUnknownHint:HintScript;
        private var m_addSecondUnknownHint:HintScript;
        private var m_addSumHint:HintScript;
        private var m_addDifferenceHint:HintScript;
        
        private var m_addAdditionEquationHint:HintScript;
        private var m_addSubtractionEquationHint:HintScript;
        
        private var m_jobToTotalMapping:Object = {
            ninja: {
                unknown_a_name: "nightengale floors", unknown_a_abbr: "floors", unknown_b_name: "trap doors", unknown_b_abbr: "doors", 
                hint_add:"both kinds of obstacles", numeric_unit_total: "obstacles", numeric_unit_diff: "obstacles"
            },
            zombie: {
                unknown_a_name: "gas bomb cure", unknown_a_abbr: "bomb", unknown_b_name: "spray cure", unknown_b_abbr: "spray",
                hint_add:"both kinds of cure delivery", numeric_unit_total: "zombies", numeric_unit_diff: "zombies"
            },
            basketball: {
                unknown_a_name: "first half shots", unknown_a_abbr: "first", unknown_b_name: "second half shots", unknown_b_abbr: "second",
                hint_add:"shots in each half", numeric_unit_total: "shots", numeric_unit_diff: "shots"
            },
            fairy: {
                unknown_a_name: "mudballs hit", unknown_a_abbr: "hit", unknown_b_name: "mudballs miss", unknown_b_abbr: "miss",
                hint_add:"mudballs hit and missed", numeric_unit_total: "mudballs", numeric_unit_diff: "mudballs"
            },
            superhero: {
                unknown_a_name: "open barrels", unknown_a_abbr: "open", unknown_b_name: "closed barrels", unknown_b_abbr: "closed",
                hint_add:"barrels opened and closed", numeric_unit_total: "barrels", numeric_unit_diff: "barrels"
            }
        };
        
        public function IntroTwoStepNoGroups(gameEngine:IGameEngine, 
                                             expressionCompiler:IExpressionTreeCompiler,
                                             assetManager:AssetManager, 
                                             playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                             id:String=null, 
                                             isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            m_barElementIdsToHighlight = new Vector.<String>();
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
            super.pushChild(m_switchModelScript);
            
            var orderedGestures:PrioritySelector = new PrioritySelector("BarModelDragGestures");
            orderedGestures.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 2, "AddNewBar"));
            orderedGestures.pushChild(new AddNewBarComparison(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison", false));
            orderedGestures.pushChild(new AddNewVerticalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewVerticalLabel", false));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewVerticalLabel"));
            super.pushChild(orderedGestures);
            super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
            
            super.pushChild(new DeckCallout(gameEngine, expressionCompiler, assetManager));
            super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
            
            // Validating both parts of the problem modeling process
            m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
            super.pushChild(m_validateBarModel);
            m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
            super.pushChild(m_validateEquation);
            
            // Logic for text dragging + discovery
            super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
            super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
            super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
            
            // Dragging things from bar model to equation
            super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
            
            // Extra script that saves just ONE additional equation in a buffer for simple systems
            super.pushChild(new SaveEquationInSystem(m_gameEngine, expressionCompiler, m_assetManager));
            
            // Adding parts to the term area
            super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm"));
            super.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager, "PressToChangeOperator", false));
            super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
            super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
            super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
            
            m_addFirstUnknownHint = new CustomFillLogicHint(showAddUnknownHint, null, null, null, hideAddUnknownHint, null, false);
            m_addSumHint = new CustomFillLogicHint(showSumHint, null, null, null, hideSumHint, null, false);
            m_addDifferenceHint = new CustomFillLogicHint(showAddComparison, null, null, null, hideAddComparison, null, false);
        }
        
        override public function visit():int
        {
            if (m_ready)
            {
                var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                
                // Tell user to add the unknowns
                if (m_progressControl.getProgressValueEquals("stage", "add_unknowns"))
                {
                    var addedFirstUnknown:Boolean = false;
                    var addedSecondUnknown:Boolean = false;
                    if (barWholes.length > 0)
                    {
                        for each (var barWhole:BarWhole in barWholes)
                        {
                            for each (var barLabel:BarLabel in barWhole.barLabels)
                            {
                                if (barLabel.value == m_unknownSmaller)
                                {
                                    addedFirstUnknown = true;
                                }
                                
                                if (barLabel.value == m_unknownLarger)
                                {
                                    addedSecondUnknown = true;
                                }
                            }
                        }
                    }
                    
                    if (!(addedFirstUnknown && addedSecondUnknown) && m_hintController.getCurrentlyShownHint() == null)
                    {
                        m_hintController.manuallyShowHint(m_addFirstUnknownHint);
                    }
                    else if (addedFirstUnknown && addedSecondUnknown)
                    {
                        if (m_hintController.getCurrentlyShownHint() == m_addFirstUnknownHint)
                        {
                            m_hintController.manuallyRemoveAllHints();   
                        }
                        
                        m_progressControl.setProgressValue("stage", "add_sum");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "add_sum"))
                {
                    // Check that they added the sum as a vertical label
                    var addedSum:Boolean = false;
                    if (m_barModelArea.getBarModelData().verticalBarLabels.length > 0)
                    {
                        addedSum = (m_barModelArea.getBarModelData().verticalBarLabels[0].value == m_sum);
                    }
                    
                    if (!addedSum && m_hintController.getCurrentlyShownHint() == null)
                    {
                        m_hintController.manuallyShowHint(m_addSumHint);
                    }
                    else if (addedSum)
                    {
                        if (m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        m_progressControl.setProgressValue("stage", "add_difference");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "add_difference"))
                {
                    // Check that they added the difference between the two parts
                    var addedDifference:Boolean = false;
                    if (barWholes.length > 1)
                    {
                        for each (barWhole in barWholes)
                        {
                            if (barWhole.barComparison != null)
                            {
                                addedDifference = true;
                                break;
                            }
                        }
                    }
                    
                    if (!addedDifference && m_hintController.getCurrentlyShownHint() == null)
                    {
                        m_hintController.manuallyShowHint(m_addDifferenceHint);
                    }
                    else if (addedDifference)
                    {
                        if (m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        getNodeById("AddNewBarComparison").setIsActive(false);
                        m_progressControl.setProgressValue("stage", "added_all_parts");
                        m_validateBarModel.setIsActive(true);
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "first_equation_started"))
                {
                    if (m_hintController.getCurrentlyShownHint() != m_addAdditionEquationHint)
                    {
                        m_hintController.manuallyShowHint(m_addAdditionEquationHint);
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "second_equation_started"))
                {
                    if (m_hintController.getCurrentlyShownHint() != m_addSubtractionEquationHint)
                    {
                        m_hintController.manuallyShowHint(m_addSubtractionEquationHint);
                    }
                }
            }
            
            return super.visit();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgressValueEquals("stage", "added_all_parts"))
                {
                    m_progressControl.setProgressValue("stage", "finished_bar_model");
                }
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                if (m_progressControl.getProgressValueEquals("stage", "first_equation_started"))
                {
                    m_progressControl.setProgressValue("stage", "first_equation_finished");
                }
                else if (m_progressControl.getProgressValueEquals("stage", "second_equation_started"))
                {
                    m_progressControl.setProgressValue("stage", "all_equations_finished");
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            super.disablePrevNextTextButtons();
            
            m_unknownSmallerDocId = "unknown_a";
            m_unknownLargerDocId = "unknown_b";
            m_sumDocId = "sum";
            m_differenceDocId = "difference";
            
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            
            m_barModelArea = m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget)[0] as BarModelAreaWidget;
            m_textAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
            
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
            super.pushChild(hintController);
            hintController.overrideLevelReady();
            m_hintController = hintController;
            
            // Clip out content not belonging to the character selected job
            var selectedPlayerJob:String = m_playerStatsAndSaveData.getPlayerDecision("job") as String;
            TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 1);
            var jobData:Object = m_jobToTotalMapping[selectedPlayerJob];
            
            m_addAdditionEquationHint = new CustomFillLogicHint(showEquationHint, 
                ["Add together " + jobData.hint_add + "!"], 
                null, null, hideEquationHint, null, false);
            m_addSubtractionEquationHint = new CustomFillLogicHint(showEquationHint, 
                ["Subtract to get the difference from " + jobData.hint_add + "!"], 
                null, null, hideEquationHint, null, false);
            
            var selectedGender:String = m_playerStatsAndSaveData.getPlayerDecision("gender") as String;
            m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 1);
            
            var slideUpPositionY:Number = m_gameEngine.getUiEntity("deckAndTermContainer").y;
            m_switchModelScript.setContainerOriginalY(slideUpPositionY);
            
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:1.0}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:1}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setDocumentIdVisible({id:selectedPlayerJob, visible:true, pageIndex:1});
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:1.0}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    greyOutAndDisableButton("undoButton", true);
                    greyOutAndDisableButton("resetButton", true);
                    
                    m_gameEngine.addTermToDocument(m_unknownSmaller, m_unknownSmallerDocId);
                    m_gameEngine.addTermToDocument(m_unknownLarger, m_unknownLargerDocId);
                    setDocumentIdsSelectable(Vector.<String>([m_unknownSmallerDocId, m_unknownLargerDocId]), true, 1);
                    
                    var sumValue:String = TutorialV2Util.getNumberValueFromDocId(m_sumDocId, m_textAreaWidget, 1);
                    m_sum = sumValue;
                    
                    var differenceValue:String = TutorialV2Util.getNumberValueFromDocId(m_differenceDocId, m_textAreaWidget, 1);
                    m_difference = differenceValue;
                    
                    var levelId:int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(m_sum, levelId);
                    assignColorToCardFromSeed(m_difference, levelId);
                    assignColorToCardFromSeed(m_unknownLarger, levelId);
                    assignColorToCardFromSeed(m_unknownSmaller, levelId);
                    
                    var dataForCard:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_sum);
                    dataForCard.abbreviatedName = m_sum + " " + m_jobToTotalMapping[selectedPlayerJob].numeric_unit_total;
                    dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_difference);
                    dataForCard.abbreviatedName = m_difference + " " + m_jobToTotalMapping[selectedPlayerJob].numeric_unit_diff;
                    
                    // Need to figure out the actual numeric value of the unknowns based on the other values in
                    // the problem. a+b=sum, a-b=diff, (sum+diff)/2=a, (sum-diff)/2=b
                    m_unknownSmallerIntValue = (parseInt(m_sum) + parseInt(m_difference)) * 0.5;
                    m_gameEngine.getCurrentLevel().termValueToBarModelValue[m_unknownSmaller] = m_unknownSmallerIntValue;
                    m_unknownLargerIntValue = parseInt(m_sum) - m_unknownSmallerIntValue;
                    m_gameEngine.getCurrentLevel().termValueToBarModelValue[m_unknownLarger] = m_unknownLargerIntValue;
                    
                    m_progressControl.setProgressValue("stage", "add_unknowns");
                    
                    // Reference model involves both a sum and difference
                    var barWholeA:BarWhole = new BarWhole(false, "largerbar");
                    barWholeA.barSegments.push(new BarSegment(m_unknownSmallerIntValue, 1, 0xFFFFFFFF, null));
                    barWholeA.barLabels.push(new BarLabel(m_unknownSmaller, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                    
                    var barWholeB:BarWhole = new BarWhole(false, "smallerbar");
                    barWholeB.barSegments.push(new BarSegment(m_unknownLargerIntValue, 1, 0xFFFFFFFF, null));
                    barWholeB.barLabels.push(new BarLabel(m_unknownLarger, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                    
                    barWholeB.barComparison = new BarComparison(m_difference, "largerbar", 0);
                    
                    var referenceModel:BarModelData = new BarModelData();
                    referenceModel.barWholes.push(barWholeA, barWholeB);
                    referenceModel.verticalBarLabels.push(new BarLabel(m_sum, 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null));
                    m_validateBarModel.setReferenceModels(Vector.<BarModelData>([referenceModel]));
                    
                    // Highlight the unknown doc ids
                    m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent(m_unknownSmallerDocId, 0xFF9900, 2));
                    m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent(m_unknownLargerDocId, 0xFF9900, 2));
                    
                    // Change the name of the unknown symbols based on the occupation selected by the player
                    var expressionDataForTotal:Object = m_jobToTotalMapping[selectedPlayerJob];
                    var symbolDataForLarger:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_unknownLarger);
                    symbolDataForLarger.abbreviatedName = expressionDataForTotal.unknown_b_abbr;
                    symbolDataForLarger.name = expressionDataForTotal.unknown_b_name;
                    var symbolDataForSmaller:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_unknownSmaller);
                    symbolDataForSmaller.abbreviatedName = expressionDataForTotal.unknown_a_abbr;
                    symbolDataForSmaller.name = expressionDataForTotal.unknown_a_name;
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"add_sum"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Remove the highlights in the unknown
                    m_textAreaWidget.componentManager.removeComponentFromEntity(m_unknownSmallerDocId, HighlightComponent.TYPE_ID);
                    m_textAreaWidget.componentManager.removeComponentFromEntity(m_unknownLargerDocId, HighlightComponent.TYPE_ID);
                    
                    // At this point we do not need to let the user
                    getNodeById("AddNewVerticalLabel").setIsActive(true);
                    setDocumentIdsSelectable(Vector.<String>([m_sumDocId]), true, 1);
                    m_gameEngine.addTermToDocument(m_sum, m_sumDocId);
                    
                    m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent(m_sumDocId, 0xFF9900, 2));
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"add_difference"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_textAreaWidget.componentManager.removeComponentFromEntity(m_sumDocId, HighlightComponent.TYPE_ID);
                    m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent(m_differenceDocId, 0xFF9900, 2));
                    
                    // At this point we do not need to let the user add another label
                    getNodeById("AddNewVerticalLabel").setIsActive(false);
                    getNodeById("AddNewBarComparison").setIsActive(true);
                    var differenceDocId:String = "difference";
                    setDocumentIdsSelectable(Vector.<String>([differenceDocId]), true, 1);
                    m_gameEngine.addTermToDocument(m_difference, differenceDocId);
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"finished_bar_model"}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:2}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setDocumentIdVisible({id:"equation_description", visible:true, pageIndex:2});
                    
                    m_textAreaWidget.componentManager.removeComponentFromEntity(m_differenceDocId, HighlightComponent.TYPE_ID);
                    m_validateBarModel.setIsActive(false);
                    m_switchModelScript.setIsActive(true);
                    
                    // Set up a simple set of equations
                    m_validateEquation.addEquation("1", m_unknownSmaller + "=" + m_sum + "-" + m_unknownLarger, false);
                    m_validateEquation.addEquation("2", m_unknownLarger + "=" + m_unknownSmaller + "-" + m_difference, false);
                    m_validateEquation.addEquationSet(Vector.<String>(["1", "2"]));
                    
                    // TODO:
                    // Want to make it clear to the user they can construct two simple equations using only some parts
                    // To convey this idea, we may want to disable parts of the bar model from being draggable
                    // When we request the user create the addition equation, grey out the difference
                    // When we request the user create the subtraction equation, grey out the sum
                    var barToCard:BarToCard = getNodeById("BarToCard") as BarToCard;
                    var barWholes:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
                    for each (var barWhole:BarWholeView in barWholes)
                    {
                        if (barWhole.comparisonView != null)
                        {
                            barWhole.comparisonView.alpha = 0.2;
                            barToCard.getIdsToIgnore().push(barWhole.comparisonView.data.id);
                        }
                        
                        m_barElementIdsToHighlight.push(barWhole.segmentViews[0].data.id);
                    }
                    
                    m_barElementIdsToHighlight.push(m_barModelArea.getVerticalBarLabelViews()[0].data.id);
                    
                    // Highlight the unknowns and the sum
                    for each (var barElementId:String in m_barElementIdsToHighlight)
                    {
                        m_barModelArea.addOrRefreshViewFromId(barElementId);
                        m_barModelArea.componentManager.addComponentToEntity(new HighlightComponent(barElementId, 0xFF9900, 2));
                    }
                    
                    // Once player presses the 'switch to equation' button, start the next stage
                    
                    m_validateEquation.setIsActive(true);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"first_equation_finished"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Re-enable the difference
                    var barToCard:BarToCard = getNodeById("BarToCard") as BarToCard;
                    barToCard.getIdsToIgnore().length = 0;
                    var barWholes:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
                    for each (var barWhole:BarWholeView in barWholes)
                    {
                        if (barWhole.comparisonView != null)
                        {
                            barWhole.comparisonView.alpha = 1.0;
                            var comparisonId:String = barWhole.comparisonView.data.id;
                            m_barElementIdsToHighlight.push(comparisonId);
                            m_barModelArea.addOrRefreshViewFromId(comparisonId);
                            m_barModelArea.componentManager.addComponentToEntity(new HighlightComponent(comparisonId, 0xFF9900, 2));
                        }
                    }
                    
                    // Add transparency to the part to indicate it is disabled.
                    var sumLabelView:BarLabelView = m_barModelArea.getVerticalBarLabelViews()[0];
                    sumLabelView.alpha = 0.2;
                    barToCard.getIdsToIgnore().push(sumLabelView.data.id);
                    m_barModelArea.componentManager.removeComponentFromEntity(sumLabelView.data.id, HighlightComponent.TYPE_ID);
                    
                    m_progressControl.setProgressValue("stage", "second_equation_started");
                    getNodeById("PressToChangeOperator").setIsActive(true);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"all_equations_finished"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_hintController.manuallyRemoveAllHints();
                    for each (var barElementId:String in m_barElementIdsToHighlight)
                    {
                        m_barModelArea.componentManager.removeComponentFromEntity(barElementId, HighlightComponent.TYPE_ID);
                    }
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.5}));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            
            super.pushChild(sequenceSelector);
        }
        
        private function onSwitchModelClicked(inBarModelMode:Boolean):void
        {
            if (inBarModelMode)
            {
                this.getNodeById("BarToCard").setIsActive(false);
            }
            else
            {
                this.getNodeById("BarToCard").setIsActive(true);
                
                if (m_progressControl.getProgressValueEquals("stage", "finished_bar_model"))
                {
                    m_progressControl.setProgressValue("stage", "first_equation_started");
                }
            }
        }
        
        private function showAddUnknownHint():void
        {
            var selectedPlayerJob:String = m_playerStatsAndSaveData.getPlayerDecision("job") as String;
            var jobData:Object = m_jobToTotalMapping[selectedPlayerJob];
            
            showDialogForUi({
                id:"barModelArea", text:"Add boxes for " + jobData.hint_add + "!",
                color:0x5082B9, direction:Callout.DIRECTION_RIGHT, width:150, height:100, animationPeriod:1, xOffset:-300, yOffset:0
            });
        }
        
        private function hideAddUnknownHint():void
        {
            removeDialogForUi({id:"barModelArea"});
        }
        
        private function showSumHint():void
        {
            var selectedPlayerJob:String = m_playerStatsAndSaveData.getPlayerDecision("job") as String;
            var jobData:Object = m_jobToTotalMapping[selectedPlayerJob];
            
            showDialogForUi({
                id:"barModelArea", text:"Add total for " + jobData.hint_add + "!",
                color:0x5082B9, direction:Callout.DIRECTION_UP, width:150, height:100, animationPeriod:1, xOffset:320, yOffset:0
            });
        }
        
        private function hideSumHint():void
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
            
            // Callout normally goes in the middle of the bar segment, shift it so it is in the middle of the empty
            // space instead.
            var xOffset:Number = (boundsLargerBar.width - boundsSmallerBar.width) * 0.5 + boundsSmallerBar.width * 0.5;
            
            var barIdForCallout:String = barWholes[smallerIndex].barSegments[0].id;
            barModelArea.addOrRefreshViewFromId(barIdForCallout);
            showDialogForBaseWidget({
                id:barIdForCallout, widgetId:"barModelArea", text:"Put the difference here!",
                color:0x5082B9, direction:Callout.DIRECTION_DOWN, width:270, height:40, animationPeriod:1, xOffset:xOffset, yOffset:0
            });
            m_segmentIdToAddCalloutTo = barIdForCallout;
        }
        
        private function hideAddComparison():void
        {
            removeDialogForBaseWidget({id:m_segmentIdToAddCalloutTo, widgetId:"barModelArea"});
        }
        
        private function showEquationHint(text:String):void
        {
            // Attach the callout to the term area
            showDialogForUi({
                id:"leftTermArea", text:text,
                color:0x5082B9, direction:Callout.DIRECTION_UP, width:200, height:100, animationPeriod:1, xOffset:0, yOffset:0
            });
        }
        
        private function hideEquationHint():void
        {
            removeDialogForUi({id:"leftTermArea"});
        }
    }
}