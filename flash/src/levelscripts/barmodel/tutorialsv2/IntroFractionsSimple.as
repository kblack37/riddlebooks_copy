package levelscripts.barmodel.tutorialsv2
{
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import starling.display.DisplayObject;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.component.BlinkComponent;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.component.HighlightComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.CustomFillLogicHint;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
    import wordproblem.scripts.barmodel.AddNewUnitBar;
    import wordproblem.scripts.barmodel.BarToCard;
    import wordproblem.scripts.barmodel.ResizeHorizontalBarLabel;
    import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckCallout;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.deck.EnterNewCard;
    import wordproblem.scripts.expression.AddTerm;
    import wordproblem.scripts.expression.RemoveTerm;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.text.DragText;
    import wordproblem.scripts.text.TextToCard;
    
    public class IntroFractionsSimple extends BaseCustomLevelScript
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
        
        private var m_numeratorValueA:int;
        private var m_denominatorValueA:int;
        private var m_fractionalValueA:int;
        private var m_unknownValueA:String = "unknown_a";
        
        private var m_denominatorValueDocId:String = "part_a_denominator";
        private var m_fractionValueDocId:String = "part_a_fraction_amount";
        private var m_numeratorValueDocId:String = "part_a_numerator";
        private var m_unknownValueDocId:String = "part_a_unknown";
        
        private var m_groupsFromDenominatorHint:HintScript;
        private var m_fractionalAddLabelHint:HintScript;
        private var m_fractionalResizeLabelHint:HintScript;
        private var m_remainderAddLabelHint:HintScript;
        private var m_remainderResizeLabelHint:HintScript;
        private var m_createNewCardHint:HintScript;
        private var m_useNewCardHint:HintScript;
        
        private var m_jobToDataMapping:Object = {
            ninja: {
                unknown_name: "remainder documents", unknown_abbr: "documents",
                known_groups: "", unknown_groups: "", numeric_unit_fraction: "documents"
            },
            zombie: {
                unknown_name: "remainder zombies", unknown_abbr: "zombies",
                known_groups: "", unknown_groups: "", numeric_unit_fraction: "zombies"
            },
            basketball: {
                unknown_name: "three point shots", unknown_abbr: "shots",
                known_groups: "", unknown_groups: "", numeric_unit_fraction: "shots"
            },
            fairy: {
                unknown_name: "Pygmies ran away", unknown_abbr: "ran away",
                known_groups: "", unknown_groups: "", numeric_unit_fraction: "Pygmies"
            },
            superhero: {
                unknown_name: "remainder breaths", unknown_abbr: "breaths",
                known_groups: "", unknown_groups: "", numeric_unit_fraction: "breaths"
            }
        };
        
        public function IntroFractionsSimple(gameEngine:IGameEngine, 
                                            expressionCompiler:IExpressionTreeCompiler, 
                                            assetManager:AssetManager, 
                                            playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                            id:String=null, 
                                            isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
            super.pushChild(m_switchModelScript);
            
            var orderedGestures:PrioritySelector = new PrioritySelector("BarModelDragGestures");
            super.pushChild(orderedGestures);
            orderedGestures.pushChild(new ResizeHorizontalBarLabel(gameEngine, expressionCompiler, assetManager, "ResizeHorizontalBarLabel"));
            orderedGestures.pushChild(new AddNewUnitBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewUnitBar"));
            orderedGestures.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, -1, "AddNewHorizontalLabel", false));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewUnitBar"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel"));
            
            super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
            
            // Used to drag things from the bar model area to the equation area
            super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
            
            super.pushChild(new DeckCallout(gameEngine, expressionCompiler, assetManager));
            
            var deckGestures:PrioritySelector = new PrioritySelector("DeckGestures");
            deckGestures.pushChild(new DeckController(m_gameEngine, m_expressionCompiler, m_assetManager, "DeckController"));
            super.pushChild(deckGestures);
            
            // Creating basic equations
            super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm", true));
            super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm", false));
            
            // Validating both parts of the problem modeling process
            m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
            super.pushChild(m_validateBarModel);
            m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
            super.pushChild(m_validateEquation);
            
            // Logic for text dragging + discovery
            super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
            super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
            super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
            
            m_groupsFromDenominatorHint = new CustomFillLogicHint(showMakeDenominatorGroups, null, null, null, hideMakeDenominatorGroups, null, false);
            m_fractionalAddLabelHint = new CustomFillLogicHint(showAddLabel, ["part_a_fraction_amount", "Add known fraction amount!"], null, null, hideAddLabel, null, false);
            m_remainderAddLabelHint = new CustomFillLogicHint(showAddLabel, ["part_a_unknown", "Add the unknown fraction remainder!"], null, null, hideAddLabel, null, false);
            m_createNewCardHint = new CustomFillLogicHint(showCreateCard, null, null, null, hideCreateCard, null, false);
            m_useNewCardHint = new CustomFillLogicHint(showUseNewCard, null, null, null, hideUseNewCard, null, false);
            
            // Note: Other hints are initialized later, since their parameters need to wait a bit
            m_segmentIdsToEmphasize = new Vector.<String>();
        }
        
        /*
        It is at this point that the player first needs to actually resize a bracket.
        Tell them to create many equal groups using the denominator (using this value correctly is crucial
        Tell them to drag the edge so it fits the same number of boxes as the numerator
        Finally they should drag the total
        */
        override public function visit():int
        {
            if (m_ready)
            {
                if (m_progressControl.getProgressValueEquals("stage", "fraction_start"))
                {
                    // Check if the user has correctly added the number of groups
                    var addedCorrectGroups:Boolean = false;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        var targetBarWhole:BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                        addedCorrectGroups = targetBarWhole.barSegments.length == m_denominatorValueA;
                    }
                    
                    if (!addedCorrectGroups && m_hintController.getCurrentlyShownHint() != m_groupsFromDenominatorHint)
                    {
                        m_hintController.manuallyShowHint(m_groupsFromDenominatorHint);
                    }
                    else if (addedCorrectGroups && m_hintController.getCurrentlyShownHint() == m_groupsFromDenominatorHint)
                    {
                        m_hintController.manuallyRemoveAllHints();   
                    }
                    
                    if (addedCorrectGroups)
                    {
                        m_progressControl.setProgressValue("stage", "add_fractional_value");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "add_fractional_value"))
                {
                    
                    var addedLabel:Boolean = labelWithValueExists(m_fractionalValueA.toString());
                    if (!addedLabel && m_hintController.getCurrentlyShownHint() != m_fractionalAddLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_fractionalAddLabelHint);   
                    }
                    else if (addedLabel)
                    {
                        if (m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        m_progressControl.setProgressValue("stage", "resize_fractional_value");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "resize_fractional_value"))
                {
                    var resizedCorrectly:Boolean = labelWithValueResized(m_fractionalValueA.toString(), m_numeratorValueA);
                    if (!resizedCorrectly && m_hintController.getCurrentlyShownHint() != m_fractionalResizeLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_fractionalResizeLabelHint);
                    }
                    else if (resizedCorrectly)
                    {
                        if (m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        m_progressControl.setProgressValue("stage", "add_remainder_value");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "add_remainder_value"))
                {
                    addedLabel = labelWithValueExists(m_unknownValueA);
                    
                    if (!addedLabel && m_hintController.getCurrentlyShownHint() != m_remainderAddLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_remainderAddLabelHint);   
                    }
                    else if (addedLabel)
                    {
                        if (m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        m_progressControl.setProgressValue("stage", "resize_remainder_value");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "resize_remainder_value"))
                {
                    resizedCorrectly = labelWithValueResized(m_unknownValueA, m_denominatorValueA - m_numeratorValueA);
                    if (!resizedCorrectly && m_hintController.getCurrentlyShownHint() != m_remainderResizeLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_remainderResizeLabelHint);
                    }
                    else if (resizedCorrectly)
                    {
                        if (m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        m_progressControl.setProgressValue("stage", "added_all_bar_parts");
                        m_validateBarModel.setIsActive(true);
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "create_new_card"))
                {
                    var createdNewValue:Boolean = false;
                    var deckWidget:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
                    var expressionsInDeck:Vector.<Component> = deckWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                    var valueToCreate:String = (m_denominatorValueA - m_numeratorValueA).toString();
                    for each (var expressionComponent:ExpressionComponent in expressionsInDeck)
                    {
                        if (expressionComponent.expressionString == valueToCreate)
                        {
                            createdNewValue = true;
                            break;
                        }
                    }
                    
                    if (!createdNewValue && m_hintController.getCurrentlyShownHint() != m_createNewCardHint)
                    {
                        m_hintController.manuallyShowHint(m_createNewCardHint);
                    }
                    else if (createdNewValue)
                    {
                        if (m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        m_progressControl.setProgressValue("stage", "start_equation");
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "start_equation"))
                {
                    var dividedByExpectedValue:Boolean = false;
                    var rightTermArea:TermAreaWidget = m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
                    var rootNode:ExpressionNode = rightTermArea.getTree().getRoot();
                    dividedByExpectedValue = rootNode != null && rootNode.right != null && rootNode.right.data == (m_denominatorValueA - m_numeratorValueA).toString();
                    
                    if (!dividedByExpectedValue && m_hintController.getCurrentlyShownHint() == null)
                    {
                        m_hintController.manuallyShowHint(m_useNewCardHint);
                    }
                    else if (dividedByExpectedValue && m_hintController.getCurrentlyShownHint() != null)
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    m_validateEquation.setIsActive(dividedByExpectedValue);
                }
                
                function labelWithValueExists(labelValue:String):Boolean
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    var addedLabel:Boolean = false;
                    for each (var barLabel:BarLabel in targetBarWhole.barLabels)
                    {
                        if (barLabel.value == labelValue)
                        {
                            addedLabel = true;
                            break;
                        }
                    }
                    
                    return addedLabel;
                }
                
                function labelWithValueResized(labelValue:String, resizeAmount:int):Boolean
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    var resizedCorrectly:Boolean = false;
                    for each (var barLabel:BarLabel in targetBarWhole.barLabels)
                    {
                        if (barLabel.value == labelValue)
                        {
                            var numBoxes:int = barLabel.endSegmentIndex - barLabel.startSegmentIndex + 1;
                            resizedCorrectly = numBoxes == resizeAmount;
                            break;
                        }
                    }
                    
                    return resizedCorrectly;
                }
            }
            
            return super.visit();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.START_RESIZE_HORIZONTAL_LABEL, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.END_RESIZE_HORIZONTAL_LABEL, bufferEvent);
            m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgressValueEquals("stage", "added_all_bar_parts"))
                {
                    m_progressControl.setProgressValue("stage", "finished_bar_model");
                }
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                if (m_progressControl.getProgressValueEquals("stage", "start_equation"))
                {
                    m_progressControl.setProgressValue("stage", "finished_equation");
                }
            }
            else if (eventType == GameEvent.START_RESIZE_HORIZONTAL_LABEL)
            {
                if (m_progressControl.getProgressValueEquals("stage", "resize_fractional_value"))
                {
                    // Should apply the blink to the bar segments in the preview
                    addBlinkToSegments(m_numeratorValueA, true, true);
                }
                else if (m_progressControl.getProgressValueEquals("stage", "resize_remainder_value"))
                {
                    addBlinkToSegments(m_denominatorValueA - m_numeratorValueA, false, true);
                }
                m_barModelArea.componentManager.removeAllComponentsFromEntity(m_resizeButtonId);
            }
            else if (eventType == GameEvent.END_RESIZE_HORIZONTAL_LABEL)
            {
                // HACK: On end resize, a redraw occurs that destroys all the previous old views
                // Remove the effects on the preview and reapply them to the non-preview model
                if (m_progressControl.getProgressValueEquals("stage", "resize_fractional_value"))
                {
                    if (m_segmentIdsToEmphasize.length > 0)
                    {
                        hideResizeLabel();
                        addBlinkToSegments(m_numeratorValueA, true, false);
                    }
                }
                else if (m_progressControl.getProgressValueEquals("stage", "resize_remainder_value"))
                {
                    if (m_segmentIdsToEmphasize.length > 0)
                    {
                        hideResizeLabel();
                        addBlinkToSegments(m_denominatorValueA - m_numeratorValueA, false, false);
                    }
                }
            }
            else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN)
            {
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            super.disablePrevNextTextButtons();
            
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.START_RESIZE_HORIZONTAL_LABEL, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.END_RESIZE_HORIZONTAL_LABEL, bufferEvent);
            
            m_barModelArea = m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget)[0] as BarModelAreaWidget;
            m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            m_textAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
            
            // Clip out content not belonging to the character selected job
            var selectedPlayerJob:String = m_playerStatsAndSaveData.getPlayerDecision("job") as String;
            TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 1);
            
            var selectedGender:String = m_playerStatsAndSaveData.getPlayerDecision("gender") as String;
            m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 1);
            
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
            super.pushChild(hintController);
            hintController.overrideLevelReady();
            m_hintController = hintController;
            
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
                    // Don't allow undo/reset for this stage
                    greyOutAndDisableButton("undoButton", true);
                    greyOutAndDisableButton("resetButton", true);
                    
                    setDocumentIdVisible({id:selectedPlayerJob, visible:true, pageIndex:1});
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    var denominatorValue:String = TutorialV2Util.getNumberValueFromDocId(m_denominatorValueDocId, m_textAreaWidget, 1);
                    m_gameEngine.addTermToDocument(denominatorValue, m_denominatorValueDocId);
                    m_denominatorValueA = parseInt(denominatorValue);
                    
                    var numeratorValue:String = TutorialV2Util.getNumberValueFromDocId(m_numeratorValueDocId, m_textAreaWidget, 1);
                    m_numeratorValueA = parseInt(numeratorValue);
                    
                    var fractionalValue:String = TutorialV2Util.getNumberValueFromDocId(m_fractionValueDocId, m_textAreaWidget, 1);
                    m_gameEngine.addTermToDocument(fractionalValue, m_fractionValueDocId);
                    m_fractionalValueA = parseInt(fractionalValue);
                    
                    m_gameEngine.addTermToDocument(m_unknownValueA, m_unknownValueDocId);
                    
                    var levelId:int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(denominatorValue, levelId);
                    assignColorToCardFromSeed(numeratorValue, levelId);
                    assignColorToCardFromSeed(fractionalValue, levelId);
                    assignColorToCardFromSeed(m_unknownValueA, levelId);
                    
                    var dataForCard:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(fractionalValue);
                    dataForCard.abbreviatedName = fractionalValue + " " + m_jobToDataMapping[selectedPlayerJob].numeric_unit_fraction;
                    
                    // Change the name of the symbol
                    var expressionDataForTotal:Object = m_jobToDataMapping[selectedPlayerJob];
                    var symbolDataForUnknown:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_unknownValueA);
                    symbolDataForUnknown.abbreviatedName = expressionDataForTotal.unknown_abbr;
                    symbolDataForUnknown.name = expressionDataForTotal.unknown_name;
                    
                    // Set up the reference model
                    var i:int;
                    var referenceBarWhole:BarWhole = new BarWhole(false);
                    for (i = 0; i < m_denominatorValueA; i++)
                    {
                        var barSegment:BarSegment = new BarSegment(1, 1, 0xFFFFFFFF, null);
                        referenceBarWhole.barSegments.push(barSegment);
                    }
                    referenceBarWhole.barLabels.push(new BarLabel(m_fractionalValueA + "", 0, m_numeratorValueA - 1, true, false, BarLabel.BRACKET_NONE, null));
                    referenceBarWhole.barLabels.push(new BarLabel(m_unknownValueA, 0, m_denominatorValueA - m_numeratorValueA - 1, true, false, BarLabel.BRACKET_NONE, null));
                    
                    var referenceModel:BarModelData = new BarModelData();
                    referenceModel.barWholes.push(referenceBarWhole);
                    m_validateBarModel.setReferenceModels(Vector.<BarModelData>([referenceModel]));
                    
                    // Should prompt player to create several groups using the denominator
                    m_progressControl.setProgressValue("stage", "fraction_start");
                    
                    // Create resize hints here since we need to extract the numbers from text above
                    m_fractionalResizeLabelHint = new CustomFillLogicHint(showResizeLabel, 
                        [m_numeratorValueA, true, m_fractionalValueA.toString(), m_numeratorValueA.toString()], 
                        null, null, hideResizeLabel, null, false);
                    m_remainderResizeLabelHint = new CustomFillLogicHint(showResizeLabel, 
                        [m_denominatorValueA - m_numeratorValueA, false, m_unknownValueA, (m_denominatorValueA - m_numeratorValueA).toString()], 
                        null, null, hideResizeLabel, null, false);
                    
                    // Force player to create the groups first
                    setDocumentIdsSelectable(Vector.<String>([m_denominatorValueDocId]), true, 1);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"add_fractional_value"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    var restrictCardsInBarModel:RestrictCardsInBarModel = getNodeById("RestrictCardsInBarModel") as RestrictCardsInBarModel;
                    restrictCardsInBarModel.setTermValuesManuallyDisabled(Vector.<String>([m_denominatorValueA.toString()]));
                    
                    // Allow add single new label
                    getNodeById("AddNewHorizontalLabel").setIsActive(true);
                    
                    (getNodeById("ResizeHorizontalBarLabel") as ResizeHorizontalBarLabel).setRestrictedElementIdsCanPerformAction(
                        Vector.<String>([m_fractionalValueA.toString()]));
                    
                    restrictCardsInBarModel.setTermValuesToIgnore(Vector.<String>([m_unknownValueA]));
                    setDocumentIdsSelectable(Vector.<String>([m_unknownValueDocId]), false, 1);
                    setDocumentIdsSelectable(Vector.<String>([m_fractionValueDocId]), true, 1);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"add_remainder_value"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    var restrictCardsInBarModel:RestrictCardsInBarModel = getNodeById("RestrictCardsInBarModel") as RestrictCardsInBarModel;
                    restrictCardsInBarModel.setTermValuesToIgnore(null);
                    
                    // Allow add single new label
                    getNodeById("AddNewHorizontalLabel").setIsActive(true);
                    
                    (getNodeById("ResizeHorizontalBarLabel") as ResizeHorizontalBarLabel).setRestrictedElementIdsCanPerformAction(
                        Vector.<String>([m_unknownValueA.toString()]));
                    m_barModelArea.redraw(true);
                    
                    setDocumentIdsSelectable(Vector.<String>([m_unknownValueDocId]), true, 1);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"added_all_bar_parts"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    getNodeById("ResizeHorizontalBarLabel").setIsActive(false);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"finished_bar_model"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_validateBarModel.setIsActive(false);
                    getNodeById("BarModelDragGestures").setIsActive(false);
                    
                    // Set up the reference equation
                    m_validateEquation.addEquation("1", m_unknownValueA + "=" + m_fractionalValueA + "/" + m_numeratorValueA + "*(" + m_denominatorValueA + "-" + m_numeratorValueA + ")", false, true);
                    m_switchModelScript.setIsActive(true);
                    
                    m_progressControl.setProgressValue("stage", "create_new_card");
                    
                    // Indicate to player that one way to solve it is to figure out the value of ONE box
                    var enterNewCard:EnterNewCard = new EnterNewCard(m_gameEngine, m_expressionCompiler, m_assetManager, false, 1, "EnterNewCard");
                    pushChild(enterNewCard);
                    enterNewCard.overrideLevelReady();
                    getNodeById("DeckGestures").pushChild(enterNewCard, 0);
                    
                    // Make sure only the custom added number is removable
                    m_gameEngine.getCurrentLevel().getLevelRules().termsNotRemovable.push(m_fractionalValueA, m_numeratorValueA, m_unknownValueA);
                    getNodeById("RemoveTerm").setIsActive(true);
                    
                    // The existing equation
                    m_gameEngine.setTermAreaContent("leftTermArea", m_fractionalValueA + "/" + m_numeratorValueA);
                    m_gameEngine.setTermAreaContent("rightTermArea", m_unknownValueA);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:2}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setDocumentIdVisible({id:"equation_description", visible:true, pageIndex:2});
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"finished_equation"}));
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.5}));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            super.pushChild(sequenceSelector);
        }
        
        private function onSwitchModelClicked(inBarModelMode:Boolean):void
        {
            if (inBarModelMode)
            {
            }
            else
            {
                // The first time this is clicked, show the create new card hint
            }
        }
        
        /*
        Hint logic
        */
        private function showMakeDenominatorGroups():void
        {
            // Need to add a callout to the bar model area
            // It needs to be offset such that is actually points to the add unit hit area
            var xOffset:Number = -m_barModelArea.width * 0.5 + 35;
            var yOffset:Number = 25;
            showDialogForUi({
                id:"barModelArea", text:"Use the denominator to show the number of parts!",
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_UP, width:140, height:150, animationPeriod:1, xOffset:xOffset, yOffset:yOffset
            });
            
            // Highlight the text for the number
            m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("part_a_denominator", 0xFF9900, 2));
        }
        
        private function hideMakeDenominatorGroups():void
        {
            removeDialogForUi({id:"barModelArea"});
            
            m_textAreaWidget.componentManager.removeComponentFromEntity("part_a_denominator", HighlightComponent.TYPE_ID);
        }
        
        private var m_activeHighlightDocId:String;
        private var m_activeSegmentId:String;
        private function showAddLabel(docIdToHighlight:String, message:String):void
        {
            m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent(docIdToHighlight, 0xFF9900, 2));
            m_activeHighlightDocId = docIdToHighlight;
            
            // Add callout to the center of the bar whole
            if (m_barModelArea.getBarModelData().barWholes.length > 0)
            {
                var segments:Vector.<BarSegment> = m_barModelArea.getBarModelData().barWholes[0].barSegments;
                var middleIndex:int = Math.floor(segments.length / 2);
                var targetSegment:BarSegment = segments[middleIndex];
                m_activeSegmentId = targetSegment.id;
                
                m_barModelArea.addOrRefreshViewFromId(m_activeSegmentId, false);
                showDialogForBaseWidget({
                    id:m_activeSegmentId, widgetId:"barModelArea", text:message,
                    color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_DOWN, width:200, height:70, animationPeriod:1, xOffset:0, yOffset:30
                });
                
            }
        }
        
        private function hideAddLabel():void
        {
            m_textAreaWidget.componentManager.removeComponentFromEntity(m_activeHighlightDocId, HighlightComponent.TYPE_ID);
            
            if (m_activeSegmentId != null)
            {
                removeDialogForBaseWidget({id:m_activeSegmentId, widgetId:"barModelArea"});
            }
        }
        
        private var m_resizeButtonId:String = "resize_button";
        private var m_segmentIdsToEmphasize:Vector.<String>;
        private function showResizeLabel(numSegments:int, resizeRightEdge:Boolean, labelValue:String, numGroups:String):void
        {
            addBlinkToSegments(numSegments, resizeRightEdge, false);
            
            // Add callout to the label edge (requires getting the button)
            var resizeButtonImage:DisplayObject = null;
            for each (var barWholeView:BarWholeView in m_barModelArea.getBarWholeViews())
            {
                for each (var labelView:BarLabelView in barWholeView.labelViews)
                {
                    if (labelView.data.value == labelValue)
                    {
                        resizeButtonImage = labelView.getButtonImage(!resizeRightEdge)
                        break;
                    }
                }
            }
            
            if (resizeButtonImage != null)
            {
                // This should be removed once the resize starts (otherwise it sticks to the same place on the screen)
                var renderComponent:RenderableComponent = new RenderableComponent(m_resizeButtonId);
                renderComponent.view = resizeButtonImage;
                m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                
                var direction:String = (resizeRightEdge) ? "left" : "right";
                var message:String = "Drag " + direction + "! It should fit " + numGroups + " parts.";
                showDialogForBaseWidget({
                    id:m_resizeButtonId, widgetId:"barModelArea", text:message,
                    color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_DOWN, width:200, height:70, animationPeriod:1, xOffset:0
                });
            }
        }
        
        private function hideResizeLabel():void
        {
            for each (var segmentId:String in m_segmentIdsToEmphasize)
            {
                m_barModelArea.componentManager.removeComponentFromEntity(segmentId, BlinkComponent.TYPE_ID);
            }
            
            m_barModelArea.componentManager.removeAllComponentsFromEntity(m_resizeButtonId);
        }
        
        private function addBlinkToSegments(numSegments:int, resizeRightEdge:Boolean, applyToPreview:Boolean):void
        {
            var barModelView:BarModelView = (applyToPreview) ? m_barModelArea.getPreviewView(false) : m_barModelArea;
            var targetBarWhole:BarWhole = barModelView.getBarModelData().barWholes[0];
            var totalSegments:int = targetBarWhole.barSegments.length;
            
            // Find and blink the segments we want the user to drag the new label over
            // To do this we need to collect all the ids of the elements
            m_segmentIdsToEmphasize.length = 0;
            var startIndex:int = (resizeRightEdge) ? 0 : totalSegments - numSegments;
            var endIndex:int = startIndex + numSegments;
            var i:int;
            for (i = startIndex; i < endIndex; i++)
            {
                var barSegment:BarSegment = targetBarWhole.barSegments[i];
                m_segmentIdsToEmphasize.push(barSegment.id);
            }
            
            for each (var segmentId:String in m_segmentIdsToEmphasize)
            {
                m_barModelArea.addOrRefreshViewFromId(segmentId, applyToPreview);
                m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(segmentId));
            }
        }
        
        private function showCreateCard():void
        {
            var selectedPlayerJob:String = m_playerStatsAndSaveData.getPlayerDecision("job") as String;
            var jobData:Object = m_jobToDataMapping[selectedPlayerJob];
            showDialogForBaseWidget({
                id:"NEW", widgetId:"deckArea", text:"How many groups does '" + jobData.unknown_abbr + "' have? Create that number!",
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_UP, width:220, height:70, animationPeriod:1
            });
        }
        
        private function hideCreateCard():void
        {
            removeDialogForBaseWidget({
                id:"NEW", widgetId:"deckArea"
            });
        }
        
        private function showUseNewCard():void
        {
            showDialogForUi({
                id:"rightTermArea", text:"Divide by the new number to solve!",
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_UP, width:150, height:100, animationPeriod:1, xOffset:0, yOffset:0
            });
        }
        
        private function hideUseNewCard():void
        {
            removeDialogForUi({id:"rightTermArea"});
        }
    }
}