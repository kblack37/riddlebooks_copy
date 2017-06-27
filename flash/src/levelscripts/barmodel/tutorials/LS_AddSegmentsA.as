package levelscripts.barmodel.tutorials
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import starling.display.Image;
    import starling.textures.Texture;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.CustomFillLogicHint;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewBarSegment;
    import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
    import wordproblem.scripts.barmodel.ResetBarModelArea;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.LevelCommonUtil;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    
    public class LS_AddSegmentsA extends BaseCustomLevelScript
    {
        private var m_progressControl:ProgressControl;
        private var m_textReplacementControl:TextReplacementControl;
        private var m_temporaryTextureControl:TemporaryTextureControl;
        
        /**
         * Script controlling correctness of bar models
         */
        private var m_validation:ValidateBarModelArea;
        private var m_barModelArea:BarModelAreaWidget;
        private var m_hintController:HelpController;
        
        private var m_enemyOptions:Vector.<String>;
        private var m_henchmenOptions:Vector.<String>;
        private var m_thrownOptions:Vector.<String>;
        
        private var m_enemySelected:String;
        private var m_henchmenSelected:String;
        private var m_thrownSelected:String;
        
        /*
        Hints
        */
        private var m_isBarModelSetup:Boolean;
        private var m_addToEndHint:HintScript;
        
        public function LS_AddSegmentsA(gameEngine:IGameEngine, 
                                        expressionCompiler:IExpressionTreeCompiler, 
                                        assetManager:AssetManager, 
                                        playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                        id:String=null, 
                                        isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
            
            var prioritySelector:PrioritySelector = new PrioritySelector();
            prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel"));
            prioritySelector.pushChild(new AddNewBarSegment(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", true, customAddNewBarSegment));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", "ShowAddNewBarSegmentHitAreas"));
            prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar", true));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            
            // Delete gestures
            prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
            prioritySelector.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager, "RemoveHorizontalLabel"));
            super.pushChild(prioritySelector);
            super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
            
            m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
            super.pushChild(m_validation);
            
            m_enemyOptions = Vector.<String>(["princess", "elf", "troll", "pumpkin", "martian"]);
            m_henchmenOptions = Vector.<String>(["monster", "dragon_red", "bear", "mouse", "knight"]);
            m_thrownOptions = Vector.<String>(["rock", "apple", "popcorn", "cow"]);
            
            m_isBarModelSetup = false;
            m_addToEndHint = new CustomFillLogicHint(showAddBarToEnd, null, null, null, hideAddBarToEnd, null, true);
        }
        
        override public function visit():int
        {
            if (m_ready)
            {
                if (m_progressControl.getProgress() == 2 && m_isBarModelSetup)
                {
                    var addedSegment:Boolean = false;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        var barWhole:BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                        addedSegment = barWhole.barSegments.length > 1;
                    }
                    
                    if (!addedSegment && m_hintController.getCurrentlyShownHint() != m_addToEndHint)
                    {
                        m_hintController.manuallyShowHint(m_addToEndHint);
                    }
                    else if (addedSegment && m_hintController.getCurrentlyShownHint() != null)
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
            m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            
            m_temporaryTextureControl.dispose();
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            super.disablePrevNextTextButtons();
            
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            var slideDownPositionY:Number = 650;
            var slideUpPositionY:Number = m_gameEngine.getUiEntity("deckAndTermContainer").y;
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideDownPositionY}));
            
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:1}));
            
            // Setup second model
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    refreshSecondPage();
                    setupSecondModel();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideDownPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:2}));
            
            // Setup second model
            // Player trying to add things for first time now
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    refreshThirdPage();                    
                    setupThirdModel();
                    m_isBarModelSetup = true;
                    return ScriptStatus.SUCCESS;
                }, null));
            
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideDownPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:3}));
            
            // Picking item to throw
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    refreshFourthPage();                   
                    setupFourthModel();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
            
            // Solving last part without prior setup
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setupFifthModel();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 5));
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:4}));
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            super.pushChild(sequenceSelector);
            
            // Special tutorial hints
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
            super.pushChild(hintController);
            hintController.overrideLevelReady();
            m_hintController = hintController;
            
            // Bind events
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
            
            m_barModelArea = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            
            // Replace as many instances showing decisions as possible
            var costumeId:String = m_playerStatsAndSaveData.getPlayerDecision("costume") as String;
            var contentA:XML = <span></span>;
            contentA.appendChild(costumeId);
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["occupation_select_a"]),
                Vector.<XML>([contentA]), 0);
            
            contentA = <span></span>;
            contentA.appendChild(costumeId + "'s");
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["occupation_select_b"]),
                Vector.<XML>([contentA]), 3);
            
            contentA = <span></span>;
            contentA.appendChild(costumeId);
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["occupation_select_c"]),
                Vector.<XML>([contentA]), 4);
            
            var treasureId:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(
                m_playerStatsAndSaveData.getPlayerDecision("treasure") as String).name;
            contentA = <span></span>;
            contentA.appendChild(treasureId);
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["treasure_select_a"]),
                Vector.<XML>([contentA]), 0);
            
            contentA = <span></span>;
            contentA.appendChild(treasureId);
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["treasure_select_b"]),
                Vector.<XML>([contentA]), 4);
            
            var petId:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(
                m_playerStatsAndSaveData.getPlayerDecision("pet") as String).name;
            contentA = <span></span>;
            contentA.appendChild(petId);
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["pet_select_a"]),
                Vector.<XML>([contentA]), 3);
            
            var gender:String = m_playerStatsAndSaveData.getPlayerDecision("gender") as String;
            contentA = (gender == "m") ? <span>his</span> : <span>her</span>;
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["gender_select_a"]),
                Vector.<XML>([contentA]), 4);
            refreshFirstPage();
            setupFirstModel();
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgress() == 0)
                {
                    m_progressControl.incrementProgress();
                    
                    var targetBarWhole:BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_enemySelected = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    var contentA:XML = <span></span>;
                    contentA.appendChild(m_enemySelected);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["enemy_select_a", "enemy_select_b"]),
                        Vector.<XML>([contentA, contentA]), 0);
                    refreshFirstPage();
                    
                    // Fill in content in other pages
                    contentA = <span></span>;
                    contentA.appendChild(m_enemySelected);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["enemy_select_c"]),
                        Vector.<XML>([contentA]), 1);
                    
                    contentA = <span></span>;
                    contentA.appendChild(m_enemySelected);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["enemy_select_d"]),
                        Vector.<XML>([contentA]), 3);
                    
                    contentA = <span></span>;
                    contentA.appendChild(m_enemySelected);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["enemy_select_e"]),
                        Vector.<XML>([contentA]), 4);
                }
                else if (m_progressControl.getProgress() == 1)
                {
                    m_progressControl.incrementProgress();
                    
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_henchmenSelected = targetBarWhole.barLabels[0].value;
                    var henchmenId:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_henchmenSelected).name;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    contentA = <span></span>;
                    contentA.appendChild(henchmenId);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["henchmen_select_a"]),
                        Vector.<XML>([contentA]), 1);
                    refreshSecondPage();
                    
                    contentA = <span></span>;
                    contentA.appendChild(henchmenId);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["henchmen_select_b"]),
                        Vector.<XML>([contentA]), 3);
                    
                    contentA = <span></span>;
                    contentA.appendChild(henchmenId);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["henchmen_select_c"]),
                        Vector.<XML>([contentA]), 4);
                }
                else if (m_progressControl.getProgress() == 2)
                {
                    m_progressControl.incrementProgress();
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                }
                else if (m_progressControl.getProgress() == 3)
                {
                    m_progressControl.incrementProgress();
                    
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_thrownSelected = targetBarWhole.barLabels[0].value;
                    
                    var throwId:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_thrownSelected).name;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    contentA = <span></span>;
                    contentA.appendChild(throwId);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["throw_select_a", "throw_select_b", "throw_select_c"]),
                        Vector.<XML>([contentA, contentA, contentA]), 3);
                    refreshFourthPage();
                }
                else if (m_progressControl.getProgress() == 4)
                {
                    m_progressControl.incrementProgress();
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                }
            }
            else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN)
            {
                if (m_progressControl.getProgress() == 0)
                {
                    var enemyValue:String = null;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        enemyValue = m_barModelArea.getBarModelData().barWholes[0].barLabels[0].value;
                    }

                    var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
                    drawEnemyOnFirstPage(textArea, enemyValue);
                }
                else if (m_progressControl.getProgress() == 1)
                {
                    var henchmenValue:String = null;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        henchmenValue = m_barModelArea.getBarModelData().barWholes[0].barLabels[0].value;
                    }
                    
                    textArea = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
                    drawHenchmenOnSecondPage(textArea, henchmenValue);
                }
                else if (m_progressControl.getProgress() == 3)
                {
                    var thrownValue:String = null;
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        thrownValue = m_barModelArea.getBarModelData().barWholes[0].barLabels[0].value;
                    }
                    
                    textArea = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
                    drawThrownObjectOnFourthPage(textArea, thrownValue);
                }
            }
        }
        
        private function setupFirstModel():void
        {
            this.getNodeById("AddNewHorizontalLabel").setIsActive(false);
            this.getNodeById("AddNewBarSegment").setIsActive(false);
            
            m_gameEngine.setDeckAreaContent(m_enemyOptions, super.getBooleanList(m_enemyOptions.length, false), false);
            LevelCommonUtil.setReferenceBarModelForPickem("a_build", null, m_enemyOptions, m_validation);
        }
        
        private function setupSecondModel():void
        {
            m_gameEngine.setDeckAreaContent(m_henchmenOptions, super.getBooleanList(m_henchmenOptions.length, false), false);
            
            // Reuse the same junk model, can pick any henchman
            LevelCommonUtil.setReferenceBarModelForPickem("a_build", null, m_henchmenOptions, m_validation);
        }
        
        private function setupThirdModel():void
        {
            this.getNodeById("AddNewHorizontalLabel").setIsActive(false);
            this.getNodeById("AddNewBarSegment").setIsActive(true);
            
            // Do not allow deletion of the existing parts
            (this.getNodeById("RemoveBarSegment") as RemoveBarSegment).segmentIdsCannotRemove.push("non_removeable_3_segment");
            this.getNodeById("RemoveHorizontalLabel").setIsActive(false);

            m_validation.clearAliases();
            var answers:Vector.<String> = Vector.<String>(["4"]);
            m_gameEngine.setDeckAreaContent(answers, super.getBooleanList(answers.length, false), false);
            
            // Set up the numbers
            var referenceBarModels:Vector.<BarModelData> = new Vector.<BarModelData>();
            var correctModel:BarModelData = new BarModelData();
            var correctBarWhole:BarWhole = new BarWhole(true);
            correctBarWhole.barSegments.push(new BarSegment(3, 1, 0, null));
            correctBarWhole.barSegments.push(new BarSegment(4, 1, 0, null));
            correctBarWhole.barLabels.push(new BarLabel("3", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            correctBarWhole.barLabels.push(new BarLabel("4", 1, 1, true, false, BarLabel.BRACKET_NONE, null));
            correctBarWhole.barLabels.push(new BarLabel(m_henchmenSelected, 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            correctModel.barWholes.push(correctBarWhole);
            referenceBarModels.push(correctModel);
            m_validation.setReferenceModels(referenceBarModels);
            
            var barModelData:BarModelData = m_barModelArea.getBarModelData();
            var blankBarWhole:BarWhole = new BarWhole(false);
            blankBarWhole.barSegments.push(new BarSegment(3, 1, 0xFFFFFF, null, "non_removeable_3_segment"));
            blankBarWhole.barLabels.push(new BarLabel("3", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            blankBarWhole.barLabels.push(new BarLabel(m_henchmenSelected, 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
            barModelData.barWholes.push(blankBarWhole);
            m_barModelArea.redraw();
            
            (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(barModelData);
        }
        
        private function setupFourthModel():void
        {
            this.getNodeById("AddNewHorizontalLabel").setIsActive(false);
            this.getNodeById("AddNewBarSegment").setIsActive(false);
            
            // Re-enable delete
            this.getNodeById("RemoveBarSegment").setIsActive(true);
            this.getNodeById("RemoveHorizontalLabel").setIsActive(true);
            
            m_gameEngine.setDeckAreaContent(m_thrownOptions, super.getBooleanList(m_thrownOptions.length, false), false);
            
            LevelCommonUtil.setReferenceBarModelForPickem("a_build", null, m_thrownOptions, m_validation);
            
            (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(null);
        }
        
        private function setupFifthModel():void
        {
            this.getNodeById("AddNewHorizontalLabel").setIsActive(true);
            this.getNodeById("AddNewBarSegment").setIsActive(true);

            m_validation.clearAliases();
            var answers:Vector.<String> = Vector.<String>(["2", "9", m_thrownSelected]);
            m_gameEngine.setDeckAreaContent(answers, super.getBooleanList(answers.length, false), false);
            
            // Add up items
            var referenceBarModels:Vector.<BarModelData> = new Vector.<BarModelData>();
            var correctModel:BarModelData = new BarModelData();
            var correctBarWhole:BarWhole = new BarWhole(true);
            correctBarWhole.barSegments.push(new BarSegment(2, 1, 0, null));
            correctBarWhole.barSegments.push(new BarSegment(9, 1, 0, null));
            correctBarWhole.barLabels.push(new BarLabel("2", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            correctBarWhole.barLabels.push(new BarLabel("9", 1, 1, true, false, BarLabel.BRACKET_NONE, null));
            correctBarWhole.barLabels.push(new BarLabel(m_thrownSelected, 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            correctModel.barWholes.push(correctBarWhole);
            referenceBarModels.push(correctModel);
            m_validation.setReferenceModels(referenceBarModels);
        }
        
        private function refreshFirstPage():void
        {
            // Get the question marks in the first page and paint them green
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
            
            // Draw picture of enemy
            drawEnemyOnFirstPage(textArea, m_enemySelected);
            
            if (m_enemySelected != null)
            {
                setDocumentIdVisible({id:"hidden_a", visible:true});
            }
        }
        
        private function drawEnemyOnFirstPage(textArea:TextAreaWidget, enemyValue:String):void
        {
            var containerViews:Vector.<DocumentView> = textArea.getDocumentViewsAtPageIndexById("enemy_container_a", null, 0);
            containerViews[0].removeChildren(0, -1, true);
            if (enemyValue != null)
            {
                var enemyTexture:Texture = m_temporaryTextureControl.getDisposableTexture(enemyValue);
                var image:Image = new Image(enemyTexture);
                image.scaleX = image.scaleY = 200 / enemyTexture.height;
                containerViews[0].addChild(image);
            }
        }
        
        private function refreshSecondPage():void
        {
            // Draw picture of henchman
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            drawHenchmenOnSecondPage(textArea, m_henchmenSelected);
            
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
        }
        
        private function drawHenchmenOnSecondPage(textArea:TextAreaWidget, henchmenValue:String):void
        {
            var containerViews:Vector.<DocumentView> = textArea.getDocumentViewsAtPageIndexById("henchmen_container_a", null, 1);
            containerViews[0].removeChildren(0, -1, true);
            
            if (henchmenValue != null)
            {
                var enemyTexture:Texture = m_temporaryTextureControl.getDisposableTexture(henchmenValue);
                var image:Image = new Image(enemyTexture);
                image.scaleX = image.scaleY = 200 / enemyTexture.height;
                containerViews[0].addChild(image);
            }
        }
        
        private function refreshThirdPage():void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var containerViews:Vector.<DocumentView> = textArea.getDocumentViewsByClass("henchmen", null, 2);
            var i:int;
            for (i = 0; i < containerViews.length; i++)
            {
                var enemyTexture:Texture = m_temporaryTextureControl.getDisposableTexture(m_henchmenSelected);
                var image:Image = new Image(enemyTexture);
                image.scaleX = image.scaleY = 90 / enemyTexture.height;
                containerViews[i].addChild(image);
            }
        }
        
        private function refreshFourthPage():void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            drawThrownObjectOnFourthPage(textArea, m_thrownSelected);
            if (m_thrownSelected != null)
            {
                setDocumentIdVisible({id:"hidden_b", visible:true});
            }
            
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
        }
        
        private function drawThrownObjectOnFourthPage(textArea:TextAreaWidget, thrownValue:String):void
        {
            var containerViews:Vector.<DocumentView> = textArea.getDocumentViewsAtPageIndexById("throw_container_a", null, 3);
            containerViews[0].removeChildren(0, -1, true);
            
            if (thrownValue != null)
            {
                var throwTexture:Texture = m_temporaryTextureControl.getDisposableTexture(thrownValue);
                var image:Image = new Image(throwTexture);
                image.scaleX = image.scaleY = 120 / throwTexture.height;
                containerViews[0].addChild(image);
            }
        }
        
        private function customAddNewBarSegment(barModelData:BarModelData, targetBarWhole:BarWhole, data:String, color:uint, labelOnTop:String, id:String=null):void
        {
            var value:Number = parseInt(data);
            var barSegmentWidth:Number = 0;
            
            // Make non-numeric values into segments of unit one by default
            var targetNumeratorValue:Number = 1;
            var targetDenominatorValue:Number = 1;
            if (!isNaN(value))
            {
                // Possible the data is a negative value, we do not take this as affecting
                targetNumeratorValue = Math.abs(value);
                targetDenominatorValue = m_barModelArea.normalizingFactor;
            }
            else
            {
                // Check later if the non-numeric values have a value it should bind to
                var termToValueMap:Object = m_gameEngine.getCurrentLevel().termValueToBarModelValue;
                if (termToValueMap != null && termToValueMap.hasOwnProperty(data))
                {
                    targetNumeratorValue = termToValueMap[data];
                    targetDenominatorValue = m_barModelArea.normalizingFactor;
                }
            }
            
            if (m_progressControl.getProgress() == 2)
            {
                var newBarSegment:BarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, 0xFFFFFF, null, id);
                targetBarWhole.barSegments.push(newBarSegment);
                
                var newBarSegmentIndex:int = targetBarWhole.barSegments.length - 1;
                var newBarLabel:BarLabel = new BarLabel(data, newBarSegmentIndex, newBarSegmentIndex, true, false, BarLabel.BRACKET_NONE, null);
                newBarLabel.numImages = value;
                targetBarWhole.barLabels.push(newBarLabel);
                
                // Stretch the previous label to fit the new segment
                var i:int;
                var numBarLabels:int = targetBarWhole.barLabels.length;
                var barLabel:BarLabel;
                for (i = 0; i < numBarLabels; i++)
                {
                    barLabel = targetBarWhole.barLabels[i];
                    if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT)
                    {
                        barLabel.endSegmentIndex = 1;
                        break;
                    }
                }
            }
            else
            {
                newBarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, color, null, id);
                targetBarWhole.barSegments.push(newBarSegment);
                
                newBarSegmentIndex = targetBarWhole.barSegments.length - 1;
                newBarLabel = new BarLabel(data, newBarSegmentIndex, newBarSegmentIndex, true, false, BarLabel.BRACKET_NONE, null);
                targetBarWhole.barLabels.push(newBarLabel);
                
                // Any existing horizontal bracket should span the entire set of boxes
                for each (var existingBarLabel:BarLabel in targetBarWhole.barLabels)
                {
                    if (existingBarLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT)
                    {
                        existingBarLabel.endSegmentIndex = newBarSegmentIndex;
                    }
                }
            }
        }
        
        /*
        Logic for hints
        */
        private var m_pickedId:String;
        private function showAddBarToEnd():void
        {
            // The dialog should point the right end of the box
            var id:String;
            if (m_barModelArea.getBarWholeViews().length > 0)
            {
                var barWholeView:BarWholeView = m_barModelArea.getBarWholeViews()[0];
                if (barWholeView.segmentViews.length > 0)
                {
                    var segmentView:BarSegmentView = barWholeView.segmentViews[0];
                    id = segmentView.data.id;
                    var xOffset:Number = segmentView.width * 0.5;
                }
            }
            
            if (id != null)
            {
                m_barModelArea.addOrRefreshViewFromId(id);
                showDialogForBaseWidget({
                    id:id, widgetId:"barModelArea", text:"Move new number to end to add.",
                    color:0xFFFFFF, direction:Callout.DIRECTION_DOWN, width:200, height:70, animationPeriod:1, xOffset:xOffset
                });
                m_pickedId = id;
            }
        }
        
        private function hideAddBarToEnd():void
        {
            if (m_pickedId != null)
            {
                removeDialogForBaseWidget({id:m_pickedId, widgetId:"barModelArea"});
            }
        }
    }
}