package levelscripts.barmodel.tutorials
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.time.Time;
    
    import feathers.controls.Callout;
    
    import starling.display.DisplayObject;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.component.HighlightComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.SymbolTermWidget;
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
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewLabelOnSegment;
    import wordproblem.scripts.barmodel.BarToCard;
    import wordproblem.scripts.barmodel.CardOnSegmentRadialOptions;
    import wordproblem.scripts.barmodel.HoldToCopy;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
    import wordproblem.scripts.barmodel.RemoveLabelOnSegment;
    import wordproblem.scripts.barmodel.ResetBarModelArea;
    import wordproblem.scripts.barmodel.SplitBarSegment;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.drag.WidgetDragSystem;
    import wordproblem.scripts.expression.AddTerm;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.LevelCommonUtil;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.expression.ResetTermArea;
    import wordproblem.scripts.expression.UndoTermArea;
    
    public class LS_SplitCopyA extends BaseCustomLevelScript
    {
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
        
        private var m_alienOptions:Vector.<String>;
        private var m_selectedAlienA:String;
        private var m_selectedAlienB:String;
        
        /**
         * Map from alien expression value (which doubles as the texture name)
         * to the name show on the screen
         */
        private var m_alienValueToName:Object;
        
        // Hints to get working
        private var m_firstBarModelIsSetup:Boolean = false;
        private var m_secondBarModelIsSetup:Boolean = false;
        private var m_firstSplitHint:HintScript;
        private var m_secondSplitHint:HintScript;
        private var m_useCopyHint:HintScript;
        private var m_addNewBoxHint:HintScript;
        private var m_addLabelHint:HintScript;
        private var m_divideHint:HintScript;
        
        /**
         * External time tick that can be shared amongst several level scripts
         */
        private var m_time:Time;
        
        public function LS_SplitCopyA(gameEngine:IGameEngine, 
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
            var splitBarSegment:SplitBarSegment = new SplitBarSegment(m_gameEngine, m_expressionCompiler, m_assetManager, "SplitBarSegment", false);
            var cardOnSegmentRadialOptions:CardOnSegmentRadialOptions = new CardOnSegmentRadialOptions(gameEngine, expressionCompiler, assetManager);
            cardOnSegmentRadialOptions.addGesture(new AddNewLabelOnSegment(gameEngine, expressionCompiler, assetManager, "AddNewLabelOnSegment", false));
            cardOnSegmentRadialOptions.addGesture(splitBarSegment);
            prioritySelector.pushChild(cardOnSegmentRadialOptions);
            prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
            super.pushChild(prioritySelector);
            
            // The copy modal button just needs to deactivate the remove gestures from happening
            m_time = new Time();
            var modifyGestures:PrioritySelector = new PrioritySelector();
            modifyGestures.pushChild(new HoldToCopy(gameEngine, expressionCompiler, assetManager, m_time, assetManager.getBitmapData("glow_yellow"), "HoldToCopy", false));
            modifyGestures.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, true, "BarToCardModelMode", false));
            var removeGestures:PrioritySelector = new PrioritySelector("BarModelRemoveGestures");
            removeGestures.pushChild(new RemoveLabelOnSegment(gameEngine, expressionCompiler, assetManager, "RemoveLabelOnSegment", false));
            removeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager));
            removeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager));
            modifyGestures.pushChild(removeGestures);
            super.pushChild(modifyGestures);
            
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, null, "SwitchBetweenBarAndEquationModel", false);
            m_switchModelScript.targetY = 80;
            super.pushChild(m_switchModelScript);
            super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
            super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
            super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
            
            // Add logic to only accept the model of a particular equation
            super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
            // Add logic to handle adding new cards (only active after all cards discovered)
            super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm", false));
            
            m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
            super.pushChild(m_validation);
            
            m_alienOptions = Vector.<String>(["arctria", "boofly", "flarn", "flobi", "goo", "spugsy", "voya"]);
            m_alienValueToName = {
                arctria: "Arctria",
                boofly: "Boofly",
                flarn: "Flarn",
                flobi: "Flobi",
                goo: "Goo",
                spugsy: "Spugsy",
                voya: "Voya"
            };
            
            m_firstSplitHint = new CustomFillLogicHint(showFirstSplit, null, null, null, hideFirstSplit, null, true);
            m_secondSplitHint = new CustomFillLogicHint(showSecondSplit, null, null, null, hideSecondSplit, null, true);
            m_useCopyHint = new CustomFillLogicHint(showUseCopy, null, null, null, hideUseCopy, null, true);
            m_addLabelHint = new CustomFillLogicHint(showAddLabel, null, null, null, hideAddLabel, null, true);
            m_divideHint = new CustomFillLogicHint(showDivide, null, null, null, hideDivide, null, true);
            m_addNewBoxHint = new CustomFillLogicHint(showAddNewBox, null, null, null, hideAddNewBox, null, true);
        }
        
        override public function visit():int
        {
            // Custom logic needed to deal with controlling when hints not bound to the hint screen
            // are activated or deactivated
            if (m_ready)
            {
                m_time.update();
                
                // Highlight the split button
                if (m_progressControl.getProgress() == 1 && m_firstBarModelIsSetup)
                {
                    // Check if the split was performed
                    var splitPerformed:Boolean = false;
                    var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                    if (barWholes.length > 0 && barWholes[0].barSegments.length == 2)
                    {
                        splitPerformed = true;
                    }
                    
                    // No hints if split performed
                    if (m_hintController.getCurrentlyShownHint() != null && splitPerformed)
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    else if (!splitPerformed && m_hintController.getCurrentlyShownHint() != m_firstSplitHint)
                    {
                        // Button activated but split needs to be performed
                        // Show first split hint will automatically remove the activate split mode hint
                        m_hintController.manuallyShowHint(m_firstSplitHint);
                    }
                }
                else if (m_progressControl.getProgress() == 3 && m_secondBarModelIsSetup)
                {
                    splitPerformed = false;
                    var labelOnBottomBar:Boolean = false;
                    var createdBarFromCopy:Boolean = false;
                    barWholes = m_barModelArea.getBarModelData().barWholes;
                    if (barWholes.length > 0 && barWholes[0].barSegments.length == 5)
                    {
                        splitPerformed = true;
                        
                        // Check if the first segments are the same
                        if (barWholes.length == 2 && barWholes[1].barSegments.length == 1)
                        {
                            createdBarFromCopy = Math.abs(barWholes[0].barSegments[0].getValue() - barWholes[1].barSegments[0].getValue()) < 0.0001;
                            
                            if (createdBarFromCopy)
                            {
                                labelOnBottomBar = (barWholes[1].barLabels.length > 0);
                            }
                        }
                    }
                    
                    if (m_hintController.getCurrentlyShownHint() != null && splitPerformed && labelOnBottomBar && createdBarFromCopy)
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    // If split not performed show hint for it
                    if (!splitPerformed && m_hintController.getCurrentlyShownHint() != m_secondSplitHint)
                    {
                        m_hintController.manuallyShowHint(m_secondSplitHint);
                    }
                    
                    // If split performed but a copy was not, prompt to show copy
                    if (splitPerformed && !createdBarFromCopy)
                    {
                        var widgetDragSystem:WidgetDragSystem = this.getNodeById("WidgetDragSystem") as WidgetDragSystem;
                        var draggedWidget:BaseTermWidget = widgetDragSystem.getWidgetSelected();
                        if (m_hintController.getCurrentlyShownHint() != m_useCopyHint && draggedWidget == null)
                        {
                            m_hintController.manuallyShowHint(m_useCopyHint);
                        }
                        else if (m_hintController.getCurrentlyShownHint() != m_addNewBoxHint && draggedWidget != null && !(draggedWidget is SymbolTermWidget))
                        {
                            m_hintController.manuallyShowHint(m_addNewBoxHint);
                        }
                    }
                    
                    if (splitPerformed && createdBarFromCopy && !labelOnBottomBar && m_hintController.getCurrentlyShownHint() != m_addLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_addLabelHint);
                    }
                }
                else if (m_progressControl.getProgress() == 4)
                {
                    var rightTermArea:TermAreaWidget = m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
                    var rightRoot:BaseTermWidget = rightTermArea.getWidgetRoot();
                    var divided:Boolean = false;
                    if (rightRoot != null && rightRoot.getNode().isSpecificOperator(m_expressionCompiler.getVectorSpace().getDivisionOperator()))
                    {
                        divided = true;
                    }
                    
                    if (!divided && m_hintController.getCurrentlyShownHint() != m_divideHint)
                    {
                        m_hintController.manuallyShowHint(m_divideHint);
                    }
                    
                    if (divided && m_hintController.getCurrentlyShownHint() != null)
                    {
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
            m_barModelArea = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_barModelArea.unitHeight = 60;
            m_barModelArea.unitLength = 300;
            m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
            
            // Shift down the bar model area
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:1}));
            
            // After reading problem click again to show the model area
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:270}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    refreshSecondPage();
                    setupUseSplitTool();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:2}));
            
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    refreshThirdPage();
                    setupPickSecondAlienModel();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:3}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:270}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    refreshFourthPage();
                    setupUseSplitAndCopyTool();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 5));
            
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            super.pushChild(sequenceSelector);
            
            m_hintController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager);
            super.pushChild(m_hintController);
            m_hintController.overrideLevelReady();
            
            setupPickFirstAlienModel();
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgress() == 0)
                {
                    m_progressControl.incrementProgress();
                    
                    // Get the selected alien
                    var targetBarWhole:BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_selectedAlienA = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(null);
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    // Replace the question mark on the first page
                    var contentA:XML = <span></span>;
                    contentA.appendChild(m_alienValueToName[m_selectedAlienA]);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["alien_a_a"]),
                        Vector.<XML>([contentA]), 0);
                    
                    // Replace words on other pages
                    contentA = <span></span>;
                    contentA.appendChild(m_alienValueToName[m_selectedAlienA]);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["alien_a_b", "alien_a_c"]),
                        Vector.<XML>([contentA, contentA]), 1);

                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["alien_a_d"]),
                        Vector.<XML>([contentA]), 3);
                    
                    refreshFirstPage();
                }
                else if (m_progressControl.getProgress() == 1)
                {
                    m_progressControl.incrementProgress();
                    
                    // Clear the bar model
                    (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(null);
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    // Make sure all hints and tooltips from the previous stage are removed
                    m_hintController.manuallyRemoveAllHints();
                    
                }
                else if (m_progressControl.getProgress() == 2)
                {
                    m_progressControl.incrementProgress();
                    
                    // Get the selected alien
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_selectedAlienB = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(null);
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    // Replace words on other pages
                    contentA = <span></span>;
                    contentA.appendChild(m_alienValueToName[m_selectedAlienB]);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["alien_b_a"]),
                        Vector.<XML>([contentA]), 2);
                    
                    // Replace words on other pages
                    contentA = <span></span>;
                    contentA.appendChild(m_alienValueToName[m_selectedAlienB]);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["alien_b_b"]),
                        Vector.<XML>([contentA]), 3);
                    
                    refreshThirdPage();
                }
                else if (m_progressControl.getProgress() == 3)
                {
                    // Have player solve an equation using the division operator
                    m_progressControl.incrementProgress();
                    
                    // Disable undo and reset
                    this.getNodeById("ResetBarModelArea").setIsActive(false);
                    this.getNodeById("UndoBarModelArea").setIsActive(false);
                    
                    // Disable remove
                    this.getNodeById("BarModelDragGestures").setIsActive(false);
                    this.getNodeById("BarModelRemoveGestures").setIsActive(false);
                    
                    // Allow drag from bar model into the equation area
                    this.getNodeById("BarToCardModelMode").setIsActive(true);
                    
                    // Disable validation
                    m_validation.setIsActive(false);
                    
                    // Hide validate button
                    m_gameEngine.getUiEntity("validateButton").visible = false;
                    
                    // Activate the switch
                    m_switchModelScript.setIsActive(true);
                    m_switchModelScript.onSwitchModelClicked();
                    
                    // Set up equation
                    var modelSpecificEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
                    modelSpecificEquationScript.addEquation("1", m_selectedAlienB + "=10/5", false, true);
                    
                    // Player just needs to click to make the plus to a subtract
                    var leftStartingExpression:String = m_selectedAlienB;
                    m_gameEngine.setTermAreaContent("leftTermArea", leftStartingExpression);
                    var rightStartingExpression:String = "10";
                    m_gameEngine.setTermAreaContent("rightTermArea", rightStartingExpression);
                    
                    // Enable the term area undo, reset, and add
                    this.getNodeById("AddTerm").setIsActive(true);
                    var undoTermAreaScript:UndoTermArea = this.getNodeById("UndoTermArea") as UndoTermArea;
                    undoTermAreaScript.setIsActive(true);
                    undoTermAreaScript.resetHistory(true);
                    var resetTermAreaScript:ResetTermArea = this.getNodeById("ResetTermArea") as ResetTermArea;
                    resetTermAreaScript.setIsActive(true);
                    resetTermAreaScript.setStartingExpressions(Vector.<String>([
                        leftStartingExpression,
                        rightStartingExpression
                    ]));
                    
                    // Disable hold to copy
                    this.getNodeById("HoldToCopy").setIsActive(false);
                }
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                if (m_progressControl.getProgress() == 4)
                {
                    m_progressControl.incrementProgress();
                }
            }
            else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN)
            {
                if (m_progressControl.getProgress() == 0)
                {
                    var alienValue:String = null;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        alienValue = m_barModelArea.getBarModelData().barWholes[0].barLabels[0].value;
                    }
                    drawAlienOnFirstPage(alienValue);
                }
                else if (m_progressControl.getProgress() == 2)
                {
                    alienValue = null;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        alienValue = m_barModelArea.getBarModelData().barWholes[0].barLabels[0].value;
                    }
                    drawAlienOnThirdPage(alienValue);
                }
            }
        }
        
        private function setupPickFirstAlienModel():void
        {
            m_gameEngine.setDeckAreaContent(m_alienOptions, super.getBooleanList(m_alienOptions.length, false), false);
            
            // The correct model will allow for any alien to be right
            LevelCommonUtil.setReferenceBarModelForPickem("a_alien", null, m_alienOptions, m_validation);
            
            refreshFirstPage();
        }
        
        private function setupUseSplitTool():void
        {
            // Disable remove gestures (only want them to do the split)
            this.getNodeById("BarModelRemoveGestures").setIsActive(false);
            
            // Activate the split button
            
            var deck:Vector.<String> = Vector.<String>(["2"]);
            m_gameEngine.setDeckAreaContent(deck, super.getBooleanList(deck.length, false), false);
            
            var referenceModel:BarModelData = new BarModelData();
            var barWhole:BarWhole = new BarWhole(false);
            var numSegments:int = 2;
            for (var i:int = 0; i < numSegments; i++)
            {
                barWhole.barSegments.push(new BarSegment(5, 1, 0, null));
            }
            barWhole.barLabels.push(new BarLabel("10", 0, barWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            referenceModel.barWholes.push(barWhole);
            m_validation.setReferenceModels(Vector.<BarModelData>([referenceModel]));
            
            // The level starts out with a single bar.
            var barModelData:BarModelData = m_barModelArea.getBarModelData();
            var blankBarWhole:BarWhole = new BarWhole(false);
            blankBarWhole.barSegments.push(new BarSegment(10, 1, 0xFFFFFF, null));
            blankBarWhole.barLabels.push(new BarLabel("10", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            barModelData.barWholes.push(blankBarWhole);
            m_barModelArea.redraw();
            
            (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(barModelData);
            
            // Show initial activate hint
            m_firstBarModelIsSetup = true;
        }
        
        private function setupPickSecondAlienModel():void
        {
            // Allow for remove of everything but a single label
            this.getNodeById("BarModelRemoveGestures").setIsActive(true);
            this.getNodeById("BarModelRemoveGestures").setIsActive(true);
            this.getNodeById("RemoveLabelOnSegment").setIsActive(false);
            
            // Do not allow for the same alien to be picked again
            var prunedAlienOptions:Vector.<String> = new Vector.<String>();
            for each (var alienOption:String in m_alienOptions)
            {
                if (alienOption != m_selectedAlienA)
                {
                    prunedAlienOptions.push(alienOption);
                }
            }
            
            m_gameEngine.setDeckAreaContent(prunedAlienOptions, super.getBooleanList(prunedAlienOptions.length, false), false);
            
            // The correct model will allow for any alien to be right
            LevelCommonUtil.setReferenceBarModelForPickem("a_alien", null, null, m_validation);
        }
        
        private function setupUseSplitAndCopyTool():void
        {
            m_secondBarModelIsSetup = true;
            
            var deck:Vector.<String> = Vector.<String>(["5", m_selectedAlienB]);
            m_gameEngine.setDeckAreaContent(deck, super.getBooleanList(deck.length, false), false);
            
            // The reference model is a group at the top line
            // and the unknown as a unit equal to one group on the bottom line.
            var referenceModel:BarModelData = new BarModelData();
            var barWhole:BarWhole = new BarWhole(false);
            var numSegments:int = 5;
            var segmentValue:int = 10 / numSegments;
            for (var i:int = 0; i < numSegments; i++)
            {
                barWhole.barSegments.push(new BarSegment(segmentValue, 1, 0, null));
            }
            barWhole.barLabels.push(new BarLabel("10", 0, barWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            referenceModel.barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            barWhole.barSegments.push(new BarSegment(segmentValue, 1, 0, null));
            barWhole.barLabels.push(new BarLabel("a_alien", 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
            referenceModel.barWholes.push(barWhole);
            m_validation.setReferenceModels(Vector.<BarModelData>([referenceModel]));
            
            // The level starts out with a single bar.
            var barModelData:BarModelData = m_barModelArea.getBarModelData();
            var blankBarWhole:BarWhole = new BarWhole(false);
            blankBarWhole.barSegments.push(new BarSegment(10, 1, 0xFFFFFF, null));
            blankBarWhole.barLabels.push(new BarLabel("10", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            barModelData.barWholes.push(blankBarWhole);
            m_barModelArea.redraw();
            
            (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(barModelData);
            
            // Enable the copy after they have split the bar
            // As a consequence this will also cause the removal scripts to also activate
            this.getNodeById("HoldToCopy").setIsActive(true);
            this.getNodeById("BarModelRemoveGestures").setIsActive(false);
            
            // Need to allow for adding new bar
            // and a label ontop of the bar (this conflicts with the split)
            (this.getNodeById("AddNewBar") as AddNewBar).setMaxBarsAllowed(2);
        }
        
        private function refreshFirstPage():void
        {
            drawAlienOnFirstPage(m_selectedAlienA);
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(m_gameEngine.getUiEntity("textArea") as TextAreaWidget);
        }
        
        private function drawAlienOnFirstPage(alienValue:String):void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            m_textReplacementControl.drawDisposableTextureAtDocId(alienValue, m_temporaryTextureControl, textArea, "alien_container_a", 0, 160);
        }
        
        private function refreshSecondPage():void
        {
            
        }
        
        private function refreshThirdPage():void
        {
            drawAlienOnThirdPage(m_selectedAlienB);
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(m_gameEngine.getUiEntity("textArea") as TextAreaWidget);
        }
        
        private function drawAlienOnThirdPage(alienValue:String):void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            m_textReplacementControl.drawDisposableTextureAtDocId(alienValue, m_temporaryTextureControl, textArea, "alien_container_b", 2, 0, 160);
        }
        
        private function refreshFourthPage():void
        {
            
        }
        
        /*
        Logic for the dynamic hints
        */
        private function showFirstSplit():void
        {
            // Highlight the number in the deck and say player should drag it onto the bar below
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            deckArea.componentManager.addComponentToEntity(new HighlightComponent("2", 0xFF0000, 2));
            showDialogForBaseWidget({
                id:"2", widgetId:"deckArea", text:"Drag onto box to divide into 2",
                color:0xFFFFFF, direction:Callout.DIRECTION_RIGHT, width:200, height:70, animationPeriod:1
            });
        }
        
        private function hideFirstSplit():void
        {
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            if (deckArea != null)
            {
                deckArea.componentManager.removeComponentFromEntity("2", HighlightComponent.TYPE_ID);
                removeDialogForBaseWidget({
                    id:"2", widgetId:"deckArea"
                });
            }
        }
        
        private function showSecondSplit():void
        {
            // Highlight the number in the deck and say player should drag it onto the bar below
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            deckArea.componentManager.addComponentToEntity(new HighlightComponent("5", 0xFF0000, 2));
            showDialogForBaseWidget({
                id:"5", widgetId:"deckArea", text:"Drag onto box to divide into 5",
                color:0xFFFFFF, direction:Callout.DIRECTION_RIGHT, width:200, height:70, animationPeriod:1
            });
        }
        
        private function hideSecondSplit():void
        {
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            if (deckArea != null)
            {
                deckArea.componentManager.removeComponentFromEntity("5", HighlightComponent.TYPE_ID);
                removeDialogForBaseWidget({
                    id:"5", widgetId:"deckArea"
                });
            }
        }
        
        private var m_firstSegmentId:String = null;
        private function showUseCopy():void
        {
            // Highlight the first bar 
            var firstSegmentInBarId:String = m_barModelArea.getBarWholeViews()[0].segmentViews[0].data.id;
            m_barModelArea.addOrRefreshViewFromId(firstSegmentInBarId);
            showDialogForBaseWidget({
                id:firstSegmentInBarId, widgetId:"barModelArea", text:"Press and hold to copy",
                color:0xFFFFFF, direction:Callout.DIRECTION_UP, width:200, height:70, animationPeriod:1
            });
            m_firstSegmentId = firstSegmentInBarId;
        }
        
        private function hideUseCopy():void
        {
            removeDialogForBaseWidget({
                id:m_firstSegmentId, widgetId:"barModelArea"
            });
        }
        
        private function showAddLabel():void
        {
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            deckArea.componentManager.addComponentToEntity(new HighlightComponent(m_selectedAlienB, 0xFF0000, 2));
            showDialogForBaseWidget({
                id:m_selectedAlienB, widgetId:"deckArea", text:"Drag onto the new box",
                color:0xFFFFFF, direction:Callout.DIRECTION_RIGHT, width:200, height:70, animationPeriod:1
            });
        }
        
        private function hideAddLabel():void
        {
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            if (deckArea != null)
            {
                deckArea.componentManager.removeComponentFromEntity(m_selectedAlienB, HighlightComponent.TYPE_ID);
                removeDialogForBaseWidget({
                    id:m_selectedAlienB, widgetId:"deckArea"
                });
            }
        }
        
        private function showAddNewBox():void
        {
            showDialogForUi({id:"barModelArea", text:"Add box here!", 
                yOffset:50, xOffset:-400,
                color:0xFFFFFF, direction:Callout.DIRECTION_RIGHT, width:200, height:70, animationPeriod:1});
        }
        
        private function hideAddNewBox():void
        {
            removeDialogForUi({id:"barModelArea"});
        }
        
        private var m_divisorId:String = null;
        private function showDivide():void
        {
            // Set dialog on the existing 10 term, tell them to drag underneath to divide
            var divideText:String = "Put 5 underneath to divide!";
            var rightTermArea:TermAreaWidget = m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
            var divisorId:String = rightTermArea.getWidgetRoot().getNode().id + "";
            showDialogForBaseWidget({
                id:divisorId, widgetId:"rightTermArea", text:divideText, 
                color:0xFFFFFF, direction:Callout.DIRECTION_RIGHT, width:100, height:80, animationPeriod:1
            });
            m_divisorId = divisorId;
        }
        
        private function hideDivide():void
        {
            removeDialogForBaseWidget({
                id:m_divisorId, widgetId:"rightTermArea"
            });
        }
    }
}