package levelscripts.barmodel.tutorialsv2
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import starling.display.Image;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
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
    import wordproblem.hints.processes.HighlightTextProcess;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewBarSegment;
    import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.ResetBarModelArea;
    import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.AvatarControl;
    import wordproblem.scripts.level.util.LevelCommonUtil;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.text.DragText;
    import wordproblem.scripts.text.HighlightTextForCard;
    import wordproblem.scripts.text.TextToCard;
    
    /**
     * This is the level to introduce picking parts of the text
     */
    public class IntroPickText extends BaseCustomLevelScript
    {
        private var m_avatarControl:AvatarControl;
        private var m_progressControl:ProgressControl;
        private var m_textReplacementControl:TextReplacementControl;
        private var m_temporaryTextureControl:TemporaryTextureControl;
        
        /*
        Options selected by the player
        */
        private var m_color:String = "start";
        private var m_job:String = "none";
        private var m_gender:String = "none";
        
        private var m_colorValueToPotionOptionName:Object = {
            red: "tomatoes",
            orange: "carrots",
            yellow: "cheese",
            green: "leaves",
            blue: "blueberries",
            purple: "grapes",
            start: "milk"
        };
        
        /**
         * Script controlling correctness of bar models
         */
        private var m_validateBarModel:ValidateBarModelArea;
        
        private var m_barModelArea:BarModelAreaWidget;
        private var m_textAreaWidget:TextAreaWidget;
        private var m_hintController:HelpController;
        
        /*
        Hints
        */
        private var m_pickAnyHint:HintScript;
        private var m_submitAnswerHint:HintScript;
        private var m_pickNumberHint:HintScript;
        private var m_pickNumberWrongHint:HintScript;
        private var m_addToEndHint:HintScript;
        private var m_addLabelHint:HintScript;
        
        public function IntroPickText(gameEngine:IGameEngine, 
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
            var prioritySelector:PrioritySelector = new PrioritySelector("barmodeldraggestures");
            prioritySelector.pushChild(new AddNewBarSegment(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", false, null));
            prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar", true, customAddBarFunction));
            prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel", false));
            prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", "ShowAddNewBarSegmentHitAreas"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel"));
            super.pushChild(prioritySelector);
            super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
            super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
            
            m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
            super.pushChild(m_validateBarModel);
            
            // Logic for text dragging + discovery
            super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
            super.pushChild(new HighlightTextForCard(m_gameEngine, m_assetManager));
            super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
            super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
            
            m_pickAnyHint = new CustomFillLogicHint(showPickAny, null, null, null, hidePickAny, null, true);
            m_submitAnswerHint = new CustomFillLogicHint(showSubmitAnswer, null, null, null, hideSubmitAnswer, null, true);
            m_pickNumberHint = new CustomFillLogicHint(showPickRightNumber, ["Pick the CORRECT number!"], null, null, hidePickRightNumber, null, true);
            m_pickNumberWrongHint = new CustomFillLogicHint(showPickRightNumber, ["Read the question and try again!"], null, null, hidePickRightNumber, null, true);
            m_addToEndHint = new CustomFillLogicHint(showAddBarToEnd, null, null, null, hideAddBarToEnd, null, true);
            m_addLabelHint = new CustomFillLogicHint(showCreateLabel, null, null, null, hideCreateLabel, null, true);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_avatarControl.dispose();
            m_temporaryTextureControl.dispose();
        }
        
        override public function visit():int
        {
            if (m_progressControl.getProgressValueEquals("hinting", "pickgender") || m_progressControl.getProgressValueEquals("hinting", "pickcolor"))
            {
                var answerPicked:Boolean = m_barModelArea.getBarModelData().barWholes.length > 0;
                if (!answerPicked && m_hintController.getCurrentlyShownHint() != m_pickAnyHint)
                {
                    m_hintController.manuallyShowHint(m_pickAnyHint);
                }
                else if (answerPicked && m_hintController.getCurrentlyShownHint() != m_submitAnswerHint)
                {
                    m_hintController.manuallyShowHint(m_submitAnswerHint);
                }
                
                // Disable the validation button until an answer is actually selected
                if (answerPicked != m_validateBarModel.getIsActive())
                {
                    m_validateBarModel.setIsActive(answerPicked);
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "pickrightnumber"))
            {
                answerPicked = m_barModelArea.getBarModelData().barWholes.length > 0;
                if (!answerPicked && m_hintController.getCurrentlyShownHint() != m_pickNumberHint)
                {
                    m_hintController.manuallyShowHint(m_pickNumberHint);
                }
                else if (answerPicked && m_hintController.getCurrentlyShownHint() == m_pickNumberHint)
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "addboxes"))
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
                else if (addedSegment && addedLabel && m_hintController.getCurrentlyShownHint() != null)
                {
                    m_hintController.manuallyRemoveAllHints();
                }
                
                // Should only execute once
                if (addedSegment)
                {
                    m_progressControl.setProgressValue("hinting", "addlabel");
                    getNodeById("AddNewHorizontalLabel").setIsActive(true);
                    getNodeById("AddNewBarSegment").setIsActive(false);
                    
                    // Remove the highlight on the number
                    this.deleteChild(this.getNodeById("highlight_number_process"));
                    
                    // Highlight to the total and make it draggable
                    this.pushChild(new HighlightTextProcess(m_textAreaWidget, 
                        Vector.<String>(["total"]), 0xFF9900, 1, "highlight_total_process"));
                    setDocumentIdsSelectable(Vector.<String>(["total"]), true, 1);
                    m_gameEngine.addTermToDocument("total", "total");
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "addlabel"))
            {
                var addedLabel:Boolean = false;
                if (m_barModelArea.getBarModelData().barWholes.length > 0)
                {
                    barWhole = m_barModelArea.getBarModelData().barWholes[0];
                    for each (var barLabel:BarLabel in barWhole.barLabels)
                    {
                        if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT)
                        {
                            addedLabel = true;
                            break;
                        }
                    }
                }
                
                if (!addedLabel && m_hintController.getCurrentlyShownHint() != m_addLabelHint)
                {
                    m_hintController.manuallyShowHint(m_addLabelHint);
                }
                else if (addedLabel && m_hintController.getCurrentlyShownHint() != null)
                {
                    m_hintController.manuallyRemoveAllHints();
                }
                
                if (addedLabel)
                {
                    // Remove highlight on the total
                    this.deleteChild(this.getNodeById("highlight_total_process"));
                    
                    m_progressControl.setProgressValue("hinting", null);
                    m_validateBarModel.setIsActive(true);
                }
            }
 
            return super.visit();
        }
        
        override public function getNumCopilotProblems():int
        {
            return 5;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            super.disablePrevNextTextButtons();
            
            // Set up all the special controllers for logic and data management in this specific level
            m_avatarControl = new AvatarControl();
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            // Bind the gender icons
            m_gameEngine.addTermToDocument("m", "boy_option");
            m_gameEngine.addTermToDocument("f", "girl_option");
            
            // Bind colors in text to the color variables defined in the card section
            m_gameEngine.addTermToDocument("red", "red_option");
            m_gameEngine.addTermToDocument("orange", "orange_option");
            m_gameEngine.addTermToDocument("yellow", "yellow_option");
            m_gameEngine.addTermToDocument("green", "green_option");
            m_gameEngine.addTermToDocument("blue", "blue_option");
            m_gameEngine.addTermToDocument("purple", "purple_option");
            
            // Bind the job options
            m_gameEngine.addTermToDocument("zombie", "zombie_option");
            m_gameEngine.addTermToDocument("ninja", "ninja_option");
            m_gameEngine.addTermToDocument("superhero", "superhero_option");
            m_gameEngine.addTermToDocument("fairy", "fairy_option");
            m_gameEngine.addTermToDocument("basketball", "basketball_option");
            
            // Bind to the numbers in the text
            m_gameEngine.addTermToDocument("2", "2_option");
            m_gameEngine.addTermToDocument("3", "3_option");
            var levelId:int = m_gameEngine.getCurrentLevel().getId();
            assignColorToCardFromSeed("2", levelId);
            assignColorToCardFromSeed("3", levelId);
            
            // Special tutorial hints
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager,
                "HintController", true);
            super.pushChild(hintController);
            hintController.overrideLevelReady();
            m_hintController = hintController;
            
            // Bind events
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
            
            m_barModelArea = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_barModelArea.unitHeight = 60;
            m_barModelArea.unitLength = 300;
            m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            m_textAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
            
            var slideUpPositionY:Number = m_gameEngine.getUiEntity("deckAndTermContainer").y;
            
            // Set up the event sequence
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.0, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setDocumentIdVisible({id:"gender_question", visible:true, pageIndex:0});
                    setupGenderSelectModel();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Activate gender hints after a while
                    m_progressControl.setProgressValue("hinting", "pickgender");
                    
                    (param.rootNode as BaseCustomLevelScript).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                        Vector.<String>(["boy_option", "girl_option"]), 0xFF9900, 1, "pickgenderhighlight"));
                    return ScriptStatus.SUCCESS;
                }, {rootNode: this}));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"pickcolor"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_validateBarModel.setIsActive(false);
                    
                    // Any actions that should be performed after gender selected
                    m_progressControl.setProgressValue("hinting", null);
                    clearBarModelHistory();
                    m_hintController.manuallyRemoveAllHints();
                    
                    var rootNode:BaseCustomLevelScript = param.rootNode as BaseCustomLevelScript;
                    rootNode.deleteChild(rootNode.getNodeById("pickgenderhighlight"));
                    
                    return ScriptStatus.SUCCESS;
                }, {rootNode: this}));
            
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_progressControl.setProgressValue("hinting", "pickcolor");
                    (param.rootNode as BaseCustomLevelScript).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                        Vector.<String>(["red_option", "orange_option", "yellow_option", "green_option", "blue_option", "purple_option"]), 
                        0xFF9900, 1, "pickcolorhighlight"));
                    
                    // Show color question
                    setDocumentIdVisible({id:"color_question", visible:true, pageIndex:0});
                    setupColorSelectModel();
                    return ScriptStatus.SUCCESS;
                }, {rootNode: this}));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"pickjob"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_validateBarModel.setIsActive(false);
                    
                    // Any actions that should be performed after color selected
                    m_progressControl.setProgressValue("hinting", null);
                    m_hintController.manuallyRemoveAllHints();
                    var rootNode:BaseCustomLevelScript = param.rootNode as BaseCustomLevelScript;
                    rootNode.deleteChild(rootNode.getNodeById("pickcolorhighlight"));
                    
                    clearBarModelHistory();
                    return ScriptStatus.SUCCESS;
                }, {rootNode: this}));
            
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_validateBarModel.setIsActive(true);
                    
                    // Ask final customize question
                    setDocumentIdVisible({id:"job_question", visible:true, pageIndex:0});
                    setupJobSelectModel();
                    return ScriptStatus.SUCCESS;
                }, null));
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"pickfirstnumber"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setDocumentIdsSelectable(Vector.<String>(["2_option", "3_option"]), false, 1);
                    
                    // Any actions that should be performed after job selected
                    clearBarModelHistory();
                    return ScriptStatus.SUCCESS;
                }, null));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:1}));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.6}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setDocumentIdsSelectable(Vector.<String>(["2_option", "3_option"]), true, 1);
                    
                    // Show first number question
                    setDocumentIdVisible({id: "first_number_question", visible: true, pageIndex: 1});
                    
                    // Setup model
                    TutorialV2Util.addSimpleSumReferenceForModel(m_validateBarModel, Vector.<int>([3]), null);
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.6}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:250}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:slideUpPositionY}));
            
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Only show hint once the ui has slid up
                    m_progressControl.setProgressValue("hinting", "pickrightnumber");
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"addparts"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Disable undo and reset, force the user to construct the right model
                    getNodeById("UndoBarModelArea").setIsActive(false);
                    getNodeById("ResetBarModelArea").setIsActive(false);
                    greyOutAndDisableButton("undoButton", true);
                    greyOutAndDisableButton("resetButton", true);
                    
                    // Disable the validation button, make sure user constructs the right model first
                    m_validateBarModel.setIsActive(false);
                    
                    m_progressControl.setProgressValue("hinting", null);
                    m_hintController.manuallyRemoveAllHints();
                    setDocumentIdVisible({id: "first_number_question", visible: false, pageIndex: 1});
                    setDocumentIdVisible({id: "sum_question", visible: true, pageIndex: 1});
                    
                    // After a short while highlight
                    // Enable the add new bar segment.
                    getNodeById("AddNewBarSegment").setIsActive(true);
                    getNodeById("RemoveBarSegment").setIsActive(false);
                    TutorialV2Util.addSimpleSumReferenceForModel(m_validateBarModel, Vector.<int>([2, 3]), "total");
                    
                    // Highlight the number 
                    (param['rootNode'] as BaseCustomLevelScript).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                        Vector.<String>(["2_option"]), 0xFF9900, 1, "highlight_number_process"));
                    
                    return ScriptStatus.SUCCESS;
                }, {rootNode: this}));
            
            // After short delay, show the hint
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_progressControl.setProgressValue("hinting", "addboxes");
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {key:"stage", value:"addpartsfinished"}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    m_hintController.manuallyRemoveAllHints();
                    m_progressControl.setProgressValue("hinting", null);
                    
                    // Any actions that should be performed after sum modeled
                    // Disable all the portions of the text
                    m_validateBarModel.setIsActive(false);
                    getNodeById("barmodeldraggestures").setIsActive(false);
                    getNodeById("ResetBarModelArea").setIsActive(false);
                    getNodeById("UndoBarModelArea").setIsActive(false);
                    getNodeById("TextToCard").setIsActive(false);
                    levelSolved(null);
                    return ScriptStatus.SUCCESS;
                }, null));
            
            // End game display
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:280}));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            
            super.pushChild(sequenceSelector);
            
            m_progressControl.setProgressValue("stage", "pickgender");
            refreshFirstPageAvatar();
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgressValueEquals("stage", "pickgender"))
                {
                    m_progressControl.setProgressValue("stage", "pickcolor");
                    
                    // Get the gender that was selected
                    var targetBarWhole:BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_gender = targetBarWhole.barLabels[0].value;
                    m_playerStatsAndSaveData.setPlayerDecision("gender", m_gender);
                    
                    // Remove gender question
                    setDocumentIdVisible({id:"gender_question", visible:false, pageIndex:0});
                    
                    // Add confirmation of gender
                    setDocumentIdVisible({id:"gender_confirm", visible:true, pageIndex:0});

                    // Replace the gender based pieces
                    m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", m_gender, 0);
                    m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", m_gender, 1);
                    refreshFirstPageAvatar();
                }
                else if (m_progressControl.getProgressValueEquals("stage", "pickcolor"))
                {
                    m_progressControl.setProgressValue("stage", "pickjob");
                    
                    // Get the color that was selected
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_color = targetBarWhole.barLabels[0].value;
                    m_playerStatsAndSaveData.setPlayerDecision("color", m_color);
                    
                    setDocumentIdVisible({id:"gender_confirm", visible:false, pageIndex:0});
                    
                    // Remove color question
                    setDocumentIdVisible({id:"color_question", visible:false, pageIndex:0});
                    
                    // Add confirmation of color
                    setDocumentIdVisible({id:"color_confirm", visible:true, pageIndex:0});
                    
                    // Replace the color based pieces
                    var contentA:XML = <span></span>;
                    var contentB:XML = <span></span>;
                    var contentC:XML = <span></span>;
                    var potionItemContent:XML = <span></span>;
                    var capitalizedColor:String = m_color.charAt(0).toUpperCase() + m_color.substr(1);
                    contentA.appendChild(capitalizedColor);
                    contentB.appendChild(m_color);
                    contentC.appendChild(m_color);
                    potionItemContent.appendChild(m_colorValueToPotionOptionName[m_color]);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        Vector.<String>(["color_select_a", "color_select_b"]),
                        Vector.<XML>([contentA, contentB, contentC]), 0);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        Vector.<String>(["color_select_c"]),
                        Vector.<XML>([contentC]), 1);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        Vector.<String>(["potion_option"]),
                        Vector.<XML>([potionItemContent]), 1);
                    refreshFirstPageAvatar();
                }
                else if (m_progressControl.getProgressValueEquals("stage", "pickjob"))
                {
                    m_progressControl.setProgressValue("stage", "pickfirstnumber");
                    
                    // Get the job that was selected
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_job = targetBarWhole.barLabels[0].value;
                    m_playerStatsAndSaveData.setPlayerDecision("job", m_job);
                    
                    contentA = <span></span>;
                    contentA.appendChild(m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_job).name);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        Vector.<String>(["job_select_a"]),
                        Vector.<XML>([contentA]), 0);
                    
                    setDocumentIdVisible({id:"job_question", visible:false, pageIndex:0});
                    setDocumentIdVisible({id:"color_confirm", visible:false, pageIndex:0});
                    setDocumentIdVisible({id:"job_confirm", visible:true, pageIndex:0});
                    refreshFirstPageAvatar();
                }
                else if (m_progressControl.getProgressValueEquals("stage", "pickfirstnumber"))
                {
                    m_progressControl.setProgressValue("stage", "addparts");
                }
                else if (m_progressControl.getProgressValueEquals("stage", "addparts"))
                {
                    m_progressControl.setProgressValue("stage", "addpartsfinished");
                }
            }
            else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN)
            {
                if (m_progressControl.getProgressValueEquals("stage", "pickgender"))
                {
                    m_gender = "none";
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                        m_gender = targetBarWhole.barLabels[0].value;
                    }
                    
                    // Make sure the character is redrawn
                    refreshFirstPageAvatar();
                }
                else if (m_progressControl.getProgressValueEquals("stage", "pickcolor"))
                {
                    m_color = "start";
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                        m_color = targetBarWhole.barLabels[0].value;
                    }
                    
                    // Make sure the character is redrawn
                    refreshFirstPageAvatar();
                }
                else if (m_progressControl.getProgressValueEquals("stage", "pickjob"))
                {
                    m_job = "none";
                    if (m_barModelArea.getBarModelData().barWholes.length > 0)
                    {
                        targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                        m_job = targetBarWhole.barLabels[0].value;
                    }
                    
                    // Make sure the character is redrawn
                    refreshFirstPageAvatar();
                }
            }
            else if (eventType == GameEvent.BAR_MODEL_INCORRECT)
            {
                if (m_progressControl.getProgressValueEquals("stage", "pickfirstnumber"))
                {
                    // Show a popup saying that the message is incorrect
                    m_hintController.manuallyRemoveAllHints();
                    m_hintController.manuallyShowHint(m_pickNumberWrongHint);
                }
            }
        }
        
        private function clearBarModelHistory():void
        {
            // Clear the bar model
            (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
            m_barModelArea.getBarModelData().clear();
            m_barModelArea.redraw();
            
            m_gameEngine.setDeckAreaContent(Vector.<String>([]), Vector.<Boolean>([]), false);
        }
        
        private function setupGenderSelectModel():void
        {
            LevelCommonUtil.setReferenceBarModelForPickem("any_gender", "gender", 
                Vector.<String>([TutorialV2Util.GENDER_MALE, TutorialV2Util.GENDER_FEMALE]), m_validateBarModel);
            
            refreshFirstPageAvatar();
        }
        
        private function setupColorSelectModel():void
        {
            var characterColors:Vector.<String> = Vector.<String>(["red", "orange", "yellow", "blue", "green", "purple"]);
            LevelCommonUtil.setReferenceBarModelForPickem("a_color", "color", characterColors, m_validateBarModel);
        }
        
        private function setupJobSelectModel():void
        {
            var characterJobs:Vector.<String> = Vector.<String>(["zombie", "ninja", "basketball", "superhero", "fairy"]);
            LevelCommonUtil.setReferenceBarModelForPickem("any_job", "job", characterJobs, m_validateBarModel);
        }
        
        private function customAddBarFunction(barWholes:Vector.<BarWhole>, 
                                              data:String,
                                              color:uint,
                                              labelOnTopValue:String,
                                              id:String=null):void
        {
            var value:Number = parseInt(data);
            
            // Any non numeric cards default to a unit of 1
            // (This value can be set in the extra data field of a level file)
            var targetNumeratorValue:Number = 1;
            var targetDenominatorValue:Number = 1;
            var barModelArea:BarModelAreaWidget = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            if (!isNaN(value))
            {
                // Possible the value is negative, right now don't have this affect the ratio
                targetNumeratorValue = Math.abs(value);
                targetDenominatorValue = barModelArea.normalizingFactor;
            }
            
            var newBarWhole:BarWhole = new BarWhole(true, id);
            
            var newBarSegment:BarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, color, null);
            newBarWhole.barSegments.push(newBarSegment);
            
            // Add a label for potions and make sure the number of potion images matches the numeric value of the bar
            var newBarLabel:BarLabel = new BarLabel(data, 0, 0, true, false, BarLabel.BRACKET_NONE, null);
            newBarLabel.numImages = value;
            newBarWhole.barLabels.push(newBarLabel);
            
            var newLabelValue:String = null;
            if (m_progressControl.getProgressValueEquals("stage", "pickgender"))
            {
                newLabelValue = "gender";
            }
            else if (m_progressControl.getProgressValueEquals("stage", "pickcolor"))
            {
                newLabelValue = "color";
            }
            else if (m_progressControl.getProgressValueEquals("stage", "pickjob"))
            {
                newLabelValue = "job"
            }
            
            if (newLabelValue != null)
            {
                newBarWhole.barLabels.push(new BarLabel(newLabelValue, 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
            }
            
            barWholes.push(newBarWhole);
        }
        
        private function refreshFirstPageAvatar():void
        {
            // Clear out the old avatar
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var avatarContainerViews:Vector.<DocumentView> = textArea.getDocumentViewsAtPageIndexById("avatar_container_a", null, 0);
            avatarContainerViews[0].removeChildren();
            
            var startingAvatar:Image = generateAvatarImageFromParams();
            m_temporaryTextureControl.saveImageWithId("start", startingAvatar);
            
            avatarContainerViews[0].addChild(startingAvatar);
        }
        
        private function generateAvatarImageFromParams():Image
        {
            return TutorialV2Util.createAvatarFromChoices(m_gender, m_color, m_job, false, m_avatarControl);
        }
        
        
        /*
        Logic for hints
        */
        private function showPickAny():void
        {
            // Highlight the bar model area
            showDialogForUi({
                id:"barModelArea", text:"Drag into here!",
                color:0x5082B9, direction:Callout.DIRECTION_RIGHT, width:150, height:50, animationPeriod:1, xOffset:-390
            });
        }
        
        private function hidePickAny():void
        {
            removeDialogForUi({id:"barModelArea"});
        }
        
        private function showSubmitAnswer():void
        {
            // Highlight the validate button
            showDialogForUi({
                id:"validateButton", text:"Click when done.",
                color:CALLOUT_TEXT_DEFAULT_COLOR, direction:Callout.DIRECTION_UP, width:170, height:40, animationPeriod:1
            });
        }
        
        private function hideSubmitAnswer():void
        {
            removeDialogForUi({id:"validateButton"});
        }
        
        private function showPickRightNumber(text:String):void
        {
            // Highlight the deck
            showDialogForUi({
                id:"barModelArea", text:text,
                color:0x5082B9, direction:Callout.DIRECTION_UP, width:200, height:50, animationPeriod:1, xOffset:0, yOffset:30
            });
        }
        
        private function hidePickRightNumber():void
        {
            removeDialogForUi({id:"barModelArea"});
        }
        
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
                    
                    var segmentBounds:Rectangle = segmentView.getBounds(m_barModelArea);
                    var xOffset:Number = (segmentBounds.right - segmentBounds.left) * 0.5;
                }
            }
            
            if (id != null)
            {
                m_barModelArea.addOrRefreshViewFromId(id);
                showDialogForBaseWidget({
                    id:id, widgetId:"barModelArea", text:"Drag number here to add.",
                    color:0x5082B9, direction:Callout.DIRECTION_DOWN, width:200, height:70, animationPeriod:1, xOffset:xOffset
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
        
        private function showCreateLabel():void
        {
            if (m_barModelArea.getBarWholeViews().length > 0 && m_barModelArea.getBarWholeViews()[0].segmentViews.length > 0)
            {
                var segmentView:BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[0];
                var targetSegmentId:String = segmentView.data.id;
                m_barModelArea.addOrRefreshViewFromId(targetSegmentId);
                showDialogForBaseWidget({
                    id:targetSegmentId, widgetId:"barModelArea", text:"Drag here to name.",
                    color:0x5082B9, direction:Callout.DIRECTION_DOWN, width:200, height:50, animationPeriod:1, xOffset:-50, yOffset:20
                    });
                m_pickedId = targetSegmentId;
            }
        }
        
        private function hideCreateLabel():void
        {
            if (m_pickedId != null)
            {
                removeDialogForBaseWidget({id:m_pickedId, widgetId:"barModelArea"});
                m_pickedId = null;
            }
        }
    }
}