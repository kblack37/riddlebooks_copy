package levelscripts.barmodel.tutorials
{
    import flash.geom.Rectangle;
    
    import cgs.overworld.core.engine.avatar.AvatarColors;
    import cgs.overworld.core.engine.avatar.body.AvatarAnimations;
    import cgs.overworld.core.engine.avatar.body.AvatarExpressions;
    import cgs.overworld.core.engine.avatar.data.AvatarSpeciesData;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    
    import wordproblem.callouts.CalloutCreator;
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.component.HighlightComponent;
    import wordproblem.engine.constants.Direction;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.CustomFillLogicHint;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.HintSelectorNode;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewBarComparison;
    import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
    import wordproblem.scripts.barmodel.AddNewVerticalLabel;
    import wordproblem.scripts.barmodel.BarToCard;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
    import wordproblem.scripts.barmodel.RemoveLabelOnSegment;
    import wordproblem.scripts.barmodel.RemoveVerticalLabel;
    import wordproblem.scripts.barmodel.ResetBarModelArea;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.expression.AddTerm;
    import wordproblem.scripts.expression.PressToChangeOperator;
    import wordproblem.scripts.expression.RemoveTerm;
    import wordproblem.scripts.expression.systems.SaveEquationInSystem;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.AvatarControl;
    import wordproblem.scripts.level.util.LevelCommonUtil;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.expression.ResetTermArea;
    import wordproblem.scripts.text.DragText;
    import wordproblem.scripts.text.TextToCard;
    import wordproblem.scripts.expression.UndoTermArea;
    
    /**
     * A tutorial that introduces how to approach two step problems. Mainly introduces creation of multiple equations from a single bar
     * model as well as using two variables in the bar model.
     */
    public class LS_TwoStepA extends BaseCustomLevelScript
    {
        private var m_avatarControl:AvatarControl;
        private var m_progressControl:ProgressControl;
        private var m_textReplacementControl:TextReplacementControl;
        private var m_temporaryTextureControl:TemporaryTextureControl;
        
        private var m_validation:ValidateBarModelArea;
        private var m_barModelArea:BarModelAreaWidget;
        private var m_hintController:HelpController;
        
        /**
         * Script controlling swapping between bar model and equation model.
         */
        private var m_switchModelScript:SwitchBetweenBarAndEquationModel;
        
        private var m_characterAOptions:Vector.<String>;
        private var m_characterASelected:String;
        private var m_characterASettings:Object;
        private var m_characterBOptions:Vector.<String>;
        private var m_characterBSelected:String;
        private var m_characterBSettings:Object;
        private var m_characterToHatId:Object;
        
        // Pause until the clicked the hint button
        private var m_hintButtonClickedOnce:Boolean = false;
        private var m_sawSecondHint:Boolean = false;
        
        // Hints to get working
        private var m_barModelIsSetup:Boolean = false;
        private var m_addFirstBarHint:HintScript;
        private var m_addSecondBarHint:HintScript;
        private var m_addVerticalLabelHint:HintScript;
        private var m_addComparisonHint:HintScript;
        private var m_getNewHint:HintScript;
        
        public function LS_TwoStepA(gameEngine:IGameEngine, 
                                    expressionCompiler:IExpressionTreeCompiler, 
                                    assetManager:AssetManager, 
                                    playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                    id:String=null, 
                                    isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            // Control of deck
            super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
            
            // Player is supposed to add a new bar into a blank space
            var prioritySelector:PrioritySelector = new PrioritySelector("BarModelDragGestures");
            prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel", false));
            prioritySelector.pushChild(new AddNewVerticalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewVerticalLabel", false));
            prioritySelector.pushChild(new AddNewBarComparison(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison", false));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewVerticalLabel", "ShowAddNewVerticalLabelHitAreas"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison"));
            prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            super.pushChild(prioritySelector);
            
            // Remove gestures are a child
            var modifyGestures:PrioritySelector = new PrioritySelector("BarModelModifyGestures");
            modifyGestures.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, true, "BarToCardModelMode", false));
            var removeGestures:PrioritySelector = new PrioritySelector("BarModelRemoveGestures");
            removeGestures.pushChild(new RemoveLabelOnSegment(gameEngine, expressionCompiler, assetManager, "RemoveLabelOnSegment", false));
            removeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager));
            removeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager));
            removeGestures.pushChild(new RemoveVerticalLabel(gameEngine, expressionCompiler, assetManager));
            modifyGestures.pushChild(removeGestures);
            super.pushChild(modifyGestures);
            
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, null, "SwitchBetweenBarAndEquationModel", false);
            m_switchModelScript.targetY = 20;
            super.pushChild(m_switchModelScript);
            super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
            super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
            super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
            
            // Add logic to only accept the model of a particular equation
            super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
            // Add logic to handle adding new cards (only active after all cards discovered)
            super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm", false));
            // Bar to card for the equation
            super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCardEquationMode", false));
            // Allow for dragging of text
            super.pushChild(new DragText(gameEngine, expressionCompiler, assetManager, "DragText"));
            super.pushChild(new TextToCard(gameEngine, expressionCompiler, assetManager, "TextToCard"));
            super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
            super.pushChild(new SaveEquationInSystem(m_gameEngine, expressionCompiler, m_assetManager));
            
            var termAreaPrioritySelector:PrioritySelector = new PrioritySelector();
            super.pushChild(termAreaPrioritySelector);
            termAreaPrioritySelector.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager));
            termAreaPrioritySelector.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
            
            m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
            super.pushChild(m_validation);
            
            m_characterAOptions = Vector.<String>(["pirate", "bandit", "chef", "viking"]);
            m_characterASettings = {
                species: AvatarSpeciesData.MAMMAL,
                earType: 7,
                color: AvatarColors.PINK
            };
            m_characterBOptions = Vector.<String>(["cowboy", "skeleton", "witch", "blonde"]);
            m_characterBSettings = {
                species: AvatarSpeciesData.BIRD,
                earType: 3,
                color: AvatarColors.TEAL
            }
            m_characterToHatId = {
                pirate: 1,
                cowboy: 4,
                chef: 10,
                viking: 88,
                bandit: 112,
                skeleton: 131,
                witch: 141,
                blonde: 12
            };
            
            m_getNewHint = new CustomFillLogicHint(showGetNewHint, null, null, null, hideGetNewHint, null, true);
            m_addFirstBarHint = new CustomFillLogicHint(showAddFirstBar, null, null, null, hideAddFirstBar, null, true);
            m_addSecondBarHint = new CustomFillLogicHint(showAddSecondBar, null, null, null, hideAddSecondBar, null, true);
            m_addComparisonHint = new CustomFillLogicHint(showAddComparison, null, null, null, hideAddComparison, null, true);
            m_addVerticalLabelHint = new CustomFillLogicHint(showAddVerticalLabel, null, null, null, hideAddVerticalLabel, null, true);
        }
        
        override public function visit():int
        {
            // Custom logic needed to deal with controlling when hints not bound to the hint screen
            // are activated or deactivated
            if (m_ready)
            {
                // Highlight the split button
                if (m_progressControl.getProgress() == 2 && m_barModelIsSetup)
                {
                    var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
                    var foundAllParts:Boolean = deckArea.getObjects().length == 4;
                    if (foundAllParts)
                    {
                        var addedFirstBar:Boolean = false;
                        var addedSecondBar:Boolean = false;
                        var addedComparison:Boolean = false;
                        var addedVerticalLabel:Boolean = false;
                        
                        var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                        var numBarWholes:int = barWholes.length;
                        for (var i:int = 0; i < numBarWholes; i++)
                        {
                            var barWhole:BarWhole = barWholes[i];
                            if (barWhole.barSegments.length == 1 && barWhole.barLabels.length > 0)
                            {
                                var labelValue:String = barWhole.barLabels[0].value;
                                if (labelValue == "10")
                                {
                                    addedFirstBar = true;
                                }
                                else if (labelValue == "table")
                                {
                                    addedSecondBar = true;
                                    
                                    if (barWhole.barComparison != null && barWhole.barComparison.value == "6")
                                    {
                                        addedComparison = true;
                                    }
                                }
                            }
                        }
                        
                        var verticalLabels:Vector.<BarLabel> = m_barModelArea.getBarModelData().verticalBarLabels
                        addedVerticalLabel = verticalLabels.length > 0 && verticalLabels[0].value == "total";
                        
                        if (addedFirstBar && addedSecondBar && addedComparison && addedVerticalLabel && m_hintController.getCurrentlyShownHint() != null)
                        {
                            m_hintController.manuallyRemoveAllHints();
                        }
                        
                        if (!addedFirstBar && m_hintController.getCurrentlyShownHint() != m_addFirstBarHint)
                        {
                            m_hintController.manuallyShowHint(m_addFirstBarHint);
                        }
                        
                        if (addedFirstBar && !addedSecondBar && m_hintController.getCurrentlyShownHint() != m_addSecondBarHint)
                        {
                            m_hintController.manuallyShowHint(m_addSecondBarHint);
                        }
                        
                        if (addedFirstBar && addedSecondBar && !addedComparison && m_hintController.getCurrentlyShownHint() != m_addComparisonHint)
                        {
                            m_hintController.manuallyShowHint(m_addComparisonHint);
                        }
                        
                        if (addedFirstBar && addedSecondBar && addedComparison && !addedVerticalLabel && m_hintController.getCurrentlyShownHint() != m_addVerticalLabelHint)
                        {
                            m_hintController.manuallyShowHint(m_addVerticalLabelHint);
                        }
                    }
                }
                else if (m_progressControl.getProgress() == 3)
                {
                    if (!m_hintButtonClickedOnce && m_hintController.getCurrentlyShownHint() == null)
                    {
                        m_hintController.manuallyShowHint(m_getNewHint);
                    }
                    
                    if (m_hintButtonClickedOnce && m_hintController.getCurrentlyShownHint() != null && !m_sawSecondHint)
                    {
                        m_sawSecondHint = true;
                        m_hintController.manuallyRemoveAllHints();
                    }
                }
            }
            return super.visit();
        }
        
        override public function getNumCopilotProblems():int
        {
            return 5;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
            m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            
            m_temporaryTextureControl.dispose();
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            disablePrevNextTextButtons();
            
            var uiContainer:DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
            var startingUiContainerY:Number = uiContainer.y;
            m_switchModelScript.setContainerOriginalY(startingUiContainerY);
            
            // Bind events
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
            m_barModelArea = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_barModelArea.unitHeight = 60;
            m_barModelArea.unitLength = 300;
            m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            
            m_avatarControl = new AvatarControl();
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            // Make sure the table is the right size
            var termValueToBarModelValueMap:Object = {table: 4};
            m_gameEngine.getCurrentLevel().termValueToBarModelValue = termValueToBarModelValueMap;
            
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:1}));
            
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:275}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Activate the the hint
                    m_hintController.setIsActive(true);
                    m_hintController.manuallyShowHint(m_getNewHint);
                    return ScriptStatus.SUCCESS;
                }, null));
            
            // Wait until they have clicked the hint button
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    if (m_hintButtonClickedOnce)
                    {
                        setupBarModel();
                    }
                    return (m_hintButtonClickedOnce) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            super.pushChild(sequenceSelector);
            
            // Special tutorial hints
            // First shows all the character
            var helperCharacterController:HelperCharacterController = new HelperCharacterController(
                m_gameEngine.getCharacterComponentManager(),
                new CalloutCreator(m_textParser, m_textViewFactory));
            var hintSelector:HintSelectorNode = new HintSelectorNode();
            hintSelector.setCustomGetHintFunction(function():HintScript
            {
                // TODO: This hint should not show up until the player has modeled the bars

                var textAreas:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TextAreaWidget);
                if (textAreas.length > 0)
                {
                    var textArea:TextAreaWidget = textAreas[0] as TextAreaWidget;
                    
                    // Bind parts of text to document
                    if (textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID).length == 0)
                    {
                        // The problem is the binding of the terms occurs as soon as the hint button is clicked,
                        // however at this same moment, this function gets called. This gets called before the set
                        // so nothing gets highlighted on the first click
                        m_gameEngine.addTermToDocument("10", "10");
                        m_gameEngine.addTermToDocument("6", "6");
                        m_gameEngine.addTermToDocument("table", "table");
                        m_gameEngine.addTermToDocument("total", "total");
                    }
                    
                    if (m_progressControl.getProgress() == 3)
                    {
                        hintData = {
                            descriptionContent: "You need to make two equation to finish the problem, 10 + table = total and table=10-6."
                        };
                        hint = HintCommonUtil.createHintFromMismatchData(hintData,
                            helperCharacterController,
                            m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, textArea, 
                            m_gameEngine, 200, 350);
                    }
                    else if (m_progressControl.getProgress() == 2)
                    {
                        var hintData:Object = {
                            descriptionContent: "This problem has multiple unknowns that you need in your answer.",
                            highlightDocIds: textArea.getAllDocumentIdsTiedToExpression()
                        };
                        var hint:HintScript = HintCommonUtil.createHintFromMismatchData(hintData,
                            helperCharacterController,
                            m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, textArea, 
                            m_gameEngine, 200, 350);
                    }
                }
                return hint;
            }, null);
            
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
            super.pushChild(hintController);
            hintController.overrideLevelReady();
            hintController.setRootHintSelectorNode(hintSelector);
            m_hintController = hintController;
            
            setupFirstAnimalSelectModel();
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgress() == 0)
                {
                    m_progressControl.incrementProgress();

                    var targetBarWhole:BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_characterASelected = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    // Replace the parts with the first character
                    var contentA:XML = <span></span>;
                    contentA.appendChild(m_characterASelected);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["character_a_a"]),
                        Vector.<XML>([contentA]), 0);
                    
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["character_a_b"]),
                        Vector.<XML>([contentA]), 1);
                    
                    refreshFirstPage();
                    
                    // Immediately go to the next problem
                    setupSecondAnimalSelectModel();
                }
                else if (m_progressControl.getProgress() == 1)
                {
                    m_progressControl.incrementProgress();
                    
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_characterBSelected = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    // Replace the parts with the second character
                    contentA = <span></span>;
                    contentA.appendChild(m_characterBSelected);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["character_b_a"]),
                        Vector.<XML>([contentA]), 0);
                    
                    refreshFirstPage();
                    
                    // Clear the deck
                    m_gameEngine.setDeckAreaContent(Vector.<String>([]), Vector.<Boolean>([]), false);
                }
                else if (m_progressControl.getProgress() == 2)
                {
                    m_progressControl.incrementProgress();
                    
                    // After solving the bar model, they need to solve the equation
                    // by using a system of equations
                    setupEquationModel();
                    
                    m_hintButtonClickedOnce = false;
                }
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                if (m_progressControl.getProgress() == 3)
                {
                    var modelSpecificEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
                    if (modelSpecificEquationScript.getAtLeastOneSetComplete())
                    {
                        m_progressControl.incrementProgress();
                    }
                }
                
                // Clear undo history, there is another equation and we need to start fresh
                (this.getNodeById("UndoTermArea") as UndoTermArea).resetHistory(false);
            }
            else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN)
            {
                if (m_progressControl.getProgress() == 0 || m_progressControl.getProgress() == 1)
                {
                    var selectedValue:String = null;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                        selectedValue = targetBarWhole.barLabels[0].value;
                    }
                    
                    if (m_progressControl.getProgress() == 0)
                    {
                        redrawCharacterAOnFirstPage(selectedValue);
                    }
                    else
                    {
                        redrawCharacterBOnFirstPage(selectedValue);
                    }
                }
            }
            else if (eventType == GameEvent.HINT_BUTTON_SELECTED)
            {
                m_hintButtonClickedOnce = true;
            }
        }
        
        private function setupFirstAnimalSelectModel():void
        {
            m_gameEngine.setDeckAreaContent(m_characterAOptions, super.getBooleanList(m_characterAOptions.length, false), false);
            
            LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_characterAOptions, m_validation);
            
            refreshFirstPage();
        }
        
        private function setupSecondAnimalSelectModel():void
        {
            m_gameEngine.setDeckAreaContent(m_characterBOptions, super.getBooleanList(m_characterBOptions.length, false), false);
            
            LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_characterBOptions, m_validation);
        }
        
        private function setupBarModel():void
        {
            m_barModelIsSetup = true;
            
            var referenceModel:BarModelData = new BarModelData();
            var barWhole:BarWhole = new BarWhole(false, "a");
            barWhole.barSegments.push(new BarSegment(10, 1, 0, null));
            barWhole.barLabels.push(new BarLabel("10", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            referenceModel.barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            barWhole.barSegments.push(new BarSegment(4, 1, 0, null));
            barWhole.barLabels.push(new BarLabel("table", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            barWhole.barComparison = new BarComparison("6", "a", 0);
            referenceModel.barWholes.push(barWhole);
            
            referenceModel.verticalBarLabels.push(new BarLabel("total", 0, 1, false, true, BarLabel.BRACKET_STRAIGHT, null));
            m_validation.setReferenceModels(Vector.<BarModelData>([referenceModel]));
            
            // Allow the gestures to properly create the new model
            (this.getNodeById("AddNewBar") as AddNewBar).setMaxBarsAllowed(2);
            this.getNodeById("AddNewHorizontalLabel").setIsActive(true);
            this.getNodeById("AddNewVerticalLabel").setIsActive(true);
            this.getNodeById("AddNewBarComparison").setIsActive(true);
        }
        
        private function setupEquationModel():void
        {
            // Hide validate button
            m_gameEngine.getUiEntity("validateButton").visible = false;
            
            // Disable all bar model actions
            this.getNodeById("BarModelDragGestures").setIsActive(false);
            this.getNodeById("BarModelModifyGestures").setIsActive(false);
            
            // Disable reset+undo on the bar model
            this.getNodeById("ResetBarModelArea").setIsActive(false);
            this.getNodeById("UndoBarModelArea").setIsActive(false);
            m_validation.setIsActive(false);
            
            // Bar to card in the equation
            this.getNodeById("BarToCardEquationMode").setIsActive(true);
            
            // Activate the switch
            m_switchModelScript.setIsActive(true);
            m_switchModelScript.onSwitchModelClicked();
            
            // Set up equation
            var modelSpecificEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
            modelSpecificEquationScript.addEquation("1", "table=total-10", false);
            modelSpecificEquationScript.addEquation("2", "table=10-6", false);
            modelSpecificEquationScript.addEquationSet(Vector.<String>(["1", "2"]));
            
            // Enable the term area undo, reset, and add
            this.getNodeById("AddTerm").setIsActive(true);
            this.getNodeById("UndoTermArea").setIsActive(true);
            this.getNodeById("ResetTermArea").setIsActive(true);
        }
        
        private function refreshFirstPage():void
        {
            redrawCharacterAOnFirstPage(m_characterASelected);
            
            redrawCharacterBOnFirstPage(m_characterBSelected);
            
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(m_gameEngine.getUiEntity("textArea") as TextAreaWidget);
        }
        
        private function redrawCharacterAOnFirstPage(selectedValue:String):void
        {
            // Create the head of the first character
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var characterAHead:Image = m_avatarControl.createAvatarImage(
                m_characterASettings.species,
                m_characterASettings.earType,
                m_characterASettings.color,
                (selectedValue != null) ? m_characterToHatId[selectedValue] : 0,
                0,
                AvatarExpressions.SAD,
                AvatarAnimations.IDLE,
                0, 230,  
                new Rectangle(30, 230, 160, 160),
                Direction.EAST
            );
            m_textReplacementControl.addImageAtDocumentId(characterAHead, textArea, "character_a_container", 0);
        }
        
        private function redrawCharacterBOnFirstPage(selectedValue:String):void
        {
            // Create the head of the second character
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var characterBHead:Image = m_avatarControl.createAvatarImage(
                m_characterBSettings.species,
                m_characterBSettings.earType,
                m_characterBSettings.color,
                (selectedValue != null) ? m_characterToHatId[selectedValue] : 0,
                0,
                AvatarExpressions.NEUTRAL,
                AvatarAnimations.IDLE,
                0, 230,
                new Rectangle(15, 230, 170, 160),
                Direction.SOUTH
            );
            m_textReplacementControl.addImageAtDocumentId(characterBHead, textArea, "character_b_container", 0);
        }
        
        /*
        Logic for custom hints
        */
        private function showGetNewHint():void
        {
            showDialogForUi({id:"hintButton", text:"New Hint", width:170, height:70, direction:Callout.DIRECTION_RIGHT, color:0xFFFFFF});
        }
        
        private function hideGetNewHint():void
        {
            removeDialogForUi({id:"hintButton"});
        }
        
        private function showAddFirstBar():void
        {
            showDeckTooltip("10", "Make a box for this.");
        }
        
        private function hideAddFirstBar():void
        {
            hideDeckTooltip("10");
        }
        
        private function showAddSecondBar():void
        {
            showDeckTooltip("table", "Make a box for this.");
        }
        
        private function hideAddSecondBar():void
        {
            hideDeckTooltip("table");
        }
        
        private function showAddComparison():void
        {
            showDeckTooltip("6", "Use to show the difference between the boxes");
        }
        
        private function hideAddComparison():void
        {
            hideDeckTooltip("6");
        }
        
        private function showAddVerticalLabel():void
        {
            showDeckTooltip("total", "Add to the side of both boxes");
        }
        
        private function hideAddVerticalLabel():void
        {
            hideDeckTooltip("total");
        }
        
        private function showDeckTooltip(deckId:String, text:String):void
        {
            // Highlight the number in the deck and say player should drag it onto the bar below
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            deckArea.componentManager.addComponentToEntity(new HighlightComponent(deckId, 0xFF0000, 2));
            showDialogForBaseWidget({
                id:deckId, widgetId:"deckArea", text:text,
                color:0xFFFFFF, direction:Callout.DIRECTION_UP, width:200, height:70, animationPeriod:1
            });
        }
        
        private function hideDeckTooltip(deckId:String):void
        {
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            if (deckArea != null)
            {
                deckArea.componentManager.removeComponentFromEntity(deckId, HighlightComponent.TYPE_ID);
                removeDialogForBaseWidget({
                    id:deckId, widgetId:"deckArea"
                });
            }
        }
    }
}