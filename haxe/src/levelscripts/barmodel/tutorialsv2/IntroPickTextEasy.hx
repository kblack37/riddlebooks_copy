package levelscripts.barmodel.tutorialsv2;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import starling.display.Image;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.PrioritySelector;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.TermAreaWidget;
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
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
import wordproblem.scripts.barmodel.ResetBarModelArea;
import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.UndoBarModelArea;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.AvatarControl;
import wordproblem.scripts.level.util.LevelCommonUtil;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.HighlightTextForCard;
import wordproblem.scripts.text.TextToCard;

/**
 * This is the level to introduce picking parts of the text
 * 
 * Differs from the other in that the player will not learn adding yet. Instead, they will immediately
 * start constructing the equation involving a single number and total
 */
class IntroPickTextEasy extends BaseCustomLevelScript
{
    private var m_avatarControl : AvatarControl;
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    /*
    Options selected by the player
    */
    private var m_color : String = "start";
    private var m_job : String = "none";
    private var m_gender : String = "none";
    
    private var m_colorValueToPotionOptionName : Dynamic = {
            red : "tomatoes",
            orange : "carrots",
            yellow : "cheese",
            green : "leaves",
            blue : "blueberries",
            purple : "grapes",
            start : "milk",

        };
    
    /**
     * Script controlling correctness of bar models
     */
    private var m_validateBarModel : ValidateBarModelArea;
    private var m_validateEquation : ModelSpecificEquation;
    
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    
    private var m_barModelArea : BarModelAreaWidget;
    private var m_textAreaWidget : TextAreaWidget;
    private var m_hintController : HelpController;
    
    private var m_correctNumber : String = "3";
    private var m_correctLabel : String = "night";
    
    /*
    Hints
    */
    private var m_pickAnyHint : HintScript;
    private var m_submitBarModelHint : HintScript;
    private var m_pickNumberHint : HintScript;
    private var m_pickNumberWrongHint : HintScript;
    private var m_addLabelHint : HintScript;
    
    private var m_showEquationNumberHint : HintScript;
    private var m_showEquationVariableHint : HintScript;
    private var m_showSubmitEquationHint : HintScript;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
        
        // Control of deck
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
        m_switchModelScript.targetY = 80;
        super.pushChild(m_switchModelScript);
        
        // Player is supposed to add a new bar into a blank space
        var prioritySelector : PrioritySelector = new PrioritySelector("barmodeldraggestures");
        prioritySelector.pushChild(new AddNewBarSegment(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", false, null));
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar", true, customAddBarFunction));
        prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel", false));
        prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
        prioritySelector.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager, "RemoveHorizontalLabel"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", "ShowAddNewBarSegmentHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel"));
        super.pushChild(prioritySelector);
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
        super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
        
        m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
        super.pushChild(m_validateBarModel);
        
        // Add logic to only accept the model of a particular equation
        m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
        super.pushChild(m_validateEquation);
        
        // Dragging things from bar model to equation
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm"));
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new HighlightTextForCard(m_gameEngine, m_assetManager));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        m_pickAnyHint = new CustomFillLogicHint(showPickAny, null, null, null, hidePickAny, null, true);
        m_submitBarModelHint = new CustomFillLogicHint(showSubmitAnswer, null, null, null, hideSubmitAnswer, null, true);
        m_pickNumberHint = new CustomFillLogicHint(showPickRightNumber, ["Pick the correct number!"], null, null, hidePickRightNumber, null, true);
        m_pickNumberWrongHint = new CustomFillLogicHint(showPickRightNumber, ["Read the question and try again!"], null, null, hidePickRightNumber, null, true);
        m_addLabelHint = new CustomFillLogicHint(showCreateLabel, null, null, null, hideCreateLabel, null, true);
        
        m_showEquationNumberHint = new CustomFillLogicHint(showDragNumber, null, null, null, hideDragNumber, null, true);
        m_showEquationVariableHint = new CustomFillLogicHint(showDragVariable, null, null, null, hideDragVariable, null, true);
        m_showSubmitEquationHint = new CustomFillLogicHint(showSubmitEquation, null, null, null, hideSubmitEquation, null, true);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_avatarControl.dispose();
        m_temporaryTextureControl.dispose();
    }
    
    override public function visit() : Int
    {
        if (m_progressControl.getProgressValueEquals("hinting", "pickgender") || m_progressControl.getProgressValueEquals("hinting", "pickcolor")) 
        {
            var answerPicked : Bool = m_barModelArea.getBarModelData().barWholes.length > 0;
            if (!answerPicked && m_hintController.getCurrentlyShownHint() != m_pickAnyHint) 
            {
                m_hintController.manuallyShowHint(m_pickAnyHint);
            }
            // Disable the validation button until an answer is actually selected
            else if (answerPicked && m_hintController.getCurrentlyShownHint() != m_submitBarModelHint) 
            {
                m_hintController.manuallyShowHint(m_submitBarModelHint);
            }
            
            
            
            if (answerPicked != m_validateBarModel.getIsActive()) 
            {
                m_validateBarModel.setIsActive(answerPicked);
            }
        }
        else if (m_progressControl.getProgressValueEquals("hinting", "pickrightnumber")) 
        {
            var correctAnswerPicked : Bool = false;
            answerPicked = m_barModelArea.getBarModelData().barWholes.length > 0;
            if (answerPicked) 
            {
                answerPicked = true;
                var selectedBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                var selectedValue : String = selectedBarWhole.barLabels[0].value;
                correctAnswerPicked = selectedValue == m_correctNumber;
            }
            
            if (!answerPicked && m_hintController.getCurrentlyShownHint() != m_pickNumberHint) 
            {
                m_hintController.manuallyShowHint(m_pickNumberHint);
            }
            else if (answerPicked && !correctAnswerPicked && m_hintController.getCurrentlyShownHint() != m_pickNumberWrongHint) 
            {
                m_hintController.manuallyShowHint(m_pickNumberWrongHint);
            }
            else if (!answerPicked && m_hintController.getCurrentlyShownHint() == m_pickNumberWrongHint) 
            {
                m_hintController.manuallyRemoveAllHints();
            }
            // If the correct is selected, move to next portion telling them to add the label
            else if (answerPicked && m_hintController.getCurrentlyShownHint() == m_pickNumberHint) 
            {
                m_hintController.manuallyRemoveAllHints();
            }
            
            
            
            if (correctAnswerPicked) 
            {
                m_progressControl.setProgressValue("stage", "addparts");
                
                // Allow adding label
                getNodeById("AddNewHorizontalLabel").setIsActive(true);
                
                // Remove the highlights from the numbers in the text
                this.deleteChild(getNodeById("numberhighlight"));
                
                // Disable being able to pick the numbers and enable the total
                (try cast(getNodeById("RestrictCardsInBarModel"), RestrictCardsInBarModel) catch(e:Dynamic) null).setTermValuesToIgnore(null);
                (try cast(getNodeById("RestrictCardsInBarModel"), RestrictCardsInBarModel) catch(e:Dynamic) null).setTermValuesManuallyDisabled(["2", "3"]);
                setDocumentIdsSelectable(["night"], true);
            }
        }
        else if (m_progressControl.getProgressValueEquals("hinting", "addlabel")) 
        {
            var correctLabelAdded : Bool = false;
            var labelAdded : Bool = false;
            answerPicked = m_barModelArea.getBarModelData().barWholes.length > 0;
            if (answerPicked) 
            {
                selectedBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(selectedBarWhole),barLabels) type: null */ in selectedBarWhole.barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                    {
                        labelAdded = true;
                        correctLabelAdded = barLabel.value == m_correctLabel;
                    }
                }
            }
            
            if (!labelAdded && m_hintController.getCurrentlyShownHint() != m_addLabelHint) 
            {
                m_hintController.manuallyShowHint(m_addLabelHint);
            }
            else if (labelAdded && m_hintController.getCurrentlyShownHint() == m_addLabelHint) 
            {
                m_hintController.manuallyRemoveAllHints();
            }
            
            if (!answerPicked) 
            {
                m_progressControl.setProgressValue("hinting", "pickrightnumber");
                
                // Disallow adding label
                getNodeById("AddNewHorizontalLabel").setIsActive(false);
            }
            
            if (correctLabelAdded) 
            {
                m_validateBarModel.setIsActive(true);
                
                if (m_hintController.getCurrentlyShownHint() != m_submitBarModelHint) 
                {
                    this.deleteChild(getNodeById("highlighttotalprocess"));
                    m_hintController.manuallyShowHint(m_submitBarModelHint);
                }
            }
        }
        else if (m_progressControl.getProgressValueEquals("hinting", "addvariabletoequation")) 
        {
            var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
            var addedVariable : Bool = leftTermArea.getWidgetRoot() != null;
            if (!addedVariable && m_hintController.getCurrentlyShownHint() != m_showEquationVariableHint) 
            {
                m_hintController.manuallyShowHint(m_showEquationVariableHint);
            }
            else if (addedVariable && m_hintController.getCurrentlyShownHint() == m_showEquationVariableHint) 
            {
                m_hintController.manuallyRemoveAllHints();
            }
            
            if (addedVariable) 
            {
                m_progressControl.setProgressValue("hinting", "addnumbertoequation");
            }
        }
        else if (m_progressControl.getProgressValueEquals("hinting", "addnumbertoequation")) 
        {
            var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
            var addedNumber : Bool = rightTermArea.getWidgetRoot() != null;
            if (!addedNumber && m_hintController.getCurrentlyShownHint() != m_showEquationNumberHint) 
            {
                m_hintController.manuallyShowHint(m_showEquationNumberHint);
            }
            else if (addedNumber && m_hintController.getCurrentlyShownHint() == m_showEquationNumberHint) 
            {
                m_hintController.manuallyRemoveAllHints();
            }
            
            if (addedNumber) 
            {
                m_progressControl.setProgressValue("hinting", null);
                m_hintController.manuallyShowHint(m_showSubmitEquationHint);
                m_validateEquation.setIsActive(true);
            }
        }
        
        return super.visit();
    }
    
    override public function getNumCopilotProblems() : Int
    {
        return 5;
    }
    
    override private function onLevelReady() : Void
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
        m_gameEngine.addTermToDocument(m_correctLabel, "night");
        (try cast(getNodeById("RestrictCardsInBarModel"), RestrictCardsInBarModel) catch(e:Dynamic) null).setTermValuesToIgnore([m_correctLabel]);
        var levelId : Int = m_gameEngine.getCurrentLevel().getId();
        assignColorToCardFromSeed("2", levelId);
        assignColorToCardFromSeed("3", levelId);
        
        // Special tutorial hints
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, 
        "HintController", true);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        // Bind events
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitHeight = 60;
        m_barModelArea.unitLength = 300;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        m_textAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        
        var slideUpPositionY : Float = m_gameEngine.getUiEntity("deckAndTermContainer").y;
        m_switchModelScript.setContainerOriginalY(slideUpPositionY);
        
        // Set up the event sequence
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.0,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setDocumentIdVisible({
                                id : "gender_question",
                                visible : true,
                                pageIndex : 0,

                            });
                    setupGenderSelectModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Activate gender hints after a while
                    m_progressControl.setProgressValue("hinting", "pickgender");
                    
                    (try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                            ["boy_option", "girl_option"], 0xFF9900, 1, "pickgenderhighlight"));
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "pickcolor",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(false);
                    
                    // Any actions that should be performed after gender selected
                    m_progressControl.setProgressValue("hinting", null);
                    clearBarModelHistory();
                    m_hintController.manuallyRemoveAllHints();
                    
                    var rootNode : BaseCustomLevelScript = try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null;
                    rootNode.deleteChild(rootNode.getNodeById("pickgenderhighlight"));
                    
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_progressControl.setProgressValue("hinting", "pickcolor");
                    (try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                            ["red_option", "orange_option", "yellow_option", "green_option", "blue_option", "purple_option"], 
                            0xFF9900, 1, "pickcolorhighlight"));
                    
                    // Show color question
                    setDocumentIdVisible({
                                id : "color_question",
                                visible : true,
                                pageIndex : 0,

                            });
                    setupColorSelectModel();
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "pickjob",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(false);
                    
                    // Any actions that should be performed after color selected
                    m_progressControl.setProgressValue("hinting", null);
                    m_hintController.manuallyRemoveAllHints();
                    var rootNode : BaseCustomLevelScript = try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null;
                    rootNode.deleteChild(rootNode.getNodeById("pickcolorhighlight"));
                    
                    clearBarModelHistory();
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(true);
                    
                    // Ask final customize question
                    setDocumentIdVisible({
                                id : "job_question",
                                visible : true,
                                pageIndex : 0,

                            });
                    setupJobSelectModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "pickfirstnumber",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Any actions that should be performed after job selected
                    clearBarModelHistory();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 1

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Any actions that should be performed after job selected
                    setDocumentIdsSelectable(["2_option", "3_option"], false, 1);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.6

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Show first number question
                    setDocumentIdVisible({
                                id : "first_number_question",
                                visible : true,
                                pageIndex : 1,

                            });
                    
                    // Setup model
                    TutorialV2Util.addSimpleSumReferenceForModel(m_validateBarModel, [parseInt(m_correctNumber)], "night");
                    
                    m_validateBarModel.setIsActive(false);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.6

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setDocumentIdsSelectable(["2_option", "3_option"], true, 1);
                    
                    // Only show hint once the ui has slid up
                    m_progressControl.setProgressValue("hinting", "pickrightnumber");
                    
                    // Highlight the numbers
                    (try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                            ["2_option", "3_option"], 0xFF9900, 1, "numberhighlight"));
                    
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "addparts",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Disable undo and reset, force the user to construct the right model
                    getNodeById("UndoBarModelArea").setIsActive(false);
                    getNodeById("ResetBarModelArea").setIsActive(false);
                    greyOutAndDisableButton("undoButton", true);
                    greyOutAndDisableButton("resetButton", true);
                    
                    // After a short while highlight
                    // Enable the add new bar segment.
                    getNodeById("RemoveBarSegment").setIsActive(false);
                    
                    // Highlight the number
                    (try cast(Reflect.field(param, "rootNode"), BaseCustomLevelScript) catch(e:Dynamic) null).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                            ["night"], 0xFF9900, 1, "highlighttotalprocess"));
                    
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        // After short delay, show the hint
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_progressControl.setProgressValue("hinting", "addlabel");
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "finishedbarmodel",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(false);
                    getNodeById("RemoveHorizontalLabel").setIsActive(false);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        // Slide work area down and have the user progress to next page and see the instructions to create the equation
        // from the blocks
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 2

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Show first number question
                    setDocumentIdVisible({
                                id : "bar_to_equation_instructions",
                                visible : true,
                                pageIndex : 2,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Set up the stuff for the equation
                    m_switchModelScript.setIsActive(true);
                    showDialogForUi({
                                id : "switchModelButton",
                                text : "Click to switch to equation!",
                                height : 80,
                                color : 0x5082B9,
                                direction : Callout.DIRECTION_UP,
                                animationPeriod : 1,

                            });
                    
                    // Place limits on what can be added
                    var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                    leftTermArea.restrictValues = true;
                    leftTermArea.restrictedValues.push(m_correctLabel);
                    leftTermArea.maxCardAllowed = 1;
                    var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                    rightTermArea.restrictValues = true;
                    rightTermArea.restrictedValues.push(m_correctNumber);
                    rightTermArea.maxCardAllowed = 1;
                    m_validateEquation.addEquation("1", m_correctLabel + "=" + m_correctNumber, false, true);
                    
                    m_progressControl.setProgressValue("stage", "changetoequationmode");
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "inequationmode",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_progressControl.setProgressValue("hinting", "addvariabletoequation");
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "finish",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_hintController.manuallyRemoveAllHints();
                    m_progressControl.setProgressValue("hinting", null);
                    m_validateEquation.setIsActive(false);
                    
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
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.6

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        
        super.pushChild(sequenceSelector);
        
        m_progressControl.setProgressValue("stage", "pickgender");
        refreshFirstPageAvatar();
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "pickgender")) 
            {
                m_progressControl.setProgressValue("stage", "pickcolor");
                
                // Get the gender that was selected
                var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_gender = targetBarWhole.barLabels[0].value;
                m_playerStatsAndSaveData.setPlayerDecision("gender", m_gender);
                
                // Remove gender question
                setDocumentIdVisible({
                            id : "gender_question",
                            visible : false,
                            pageIndex : 0,

                        });
                
                // Add confirmation of gender
                setDocumentIdVisible({
                            id : "gender_confirm",
                            visible : true,
                            pageIndex : 0,

                        });
                
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
                
                setDocumentIdVisible({
                            id : "gender_confirm",
                            visible : false,
                            pageIndex : 0,

                        });
                
                // Remove color question
                setDocumentIdVisible({
                            id : "color_question",
                            visible : false,
                            pageIndex : 0,

                        });
                
                // Add confirmation of color
                setDocumentIdVisible({
                            id : "color_confirm",
                            visible : true,
                            pageIndex : 0,

                        });
                
                // Replace the color based pieces
                var contentA : FastXML = FastXML.parse("<span></span>");
                var contentB : FastXML = FastXML.parse("<span></span>");
                var contentC : FastXML = FastXML.parse("<span></span>");
                var potionItemContent : FastXML = FastXML.parse("<span></span>");
                var capitalizedColor : String = m_color.charAt(0).toUpperCase() + m_color.substr(1);
                contentA.node.appendChild.innerData(capitalizedColor);
                contentB.node.appendChild.innerData(m_color);
                contentC.node.appendChild.innerData(m_color);
                potionItemContent.node.appendChild.innerData(Reflect.field(m_colorValueToPotionOptionName, m_color));
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        ["color_select_a", "color_select_b"],
                        [contentA, contentB, contentC], 0);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        ["color_select_c"],
                        [contentC], 1);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        ["potion_option"],
                        [potionItemContent], 1);
                refreshFirstPageAvatar();
                
                var articleForColor : String = "A";
                var vowels : Array<String> = ["a", "e", "i", "o", "u"];
                if (Lambda.indexOf(vowels, m_color.charAt(0)) >= 0) 
                {
                    articleForColor = "An";
                }
                var contentArticle : FastXML = FastXML.parse("<span></span>");
                contentArticle.node.appendChild.innerData(articleForColor);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        ["article_select_a"],
                        [contentArticle], 0);
            }
            else if (m_progressControl.getProgressValueEquals("stage", "pickjob")) 
            {
                m_progressControl.setProgressValue("stage", "pickfirstnumber");
                
                // Get the job that was selected
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_job = targetBarWhole.barLabels[0].value;
                m_playerStatsAndSaveData.setPlayerDecision("job", m_job);
                
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_job).name);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(
                        ["job_select_a"],
                        [contentA], 0);
                
                setDocumentIdVisible({
                            id : "job_question",
                            visible : false,
                            pageIndex : 0,

                        });
                setDocumentIdVisible({
                            id : "color_confirm",
                            visible : false,
                            pageIndex : 0,

                        });
                setDocumentIdVisible({
                            id : "job_confirm",
                            visible : true,
                            pageIndex : 0,

                        });
                refreshFirstPageAvatar();
            }
            // Waiting for solving the first problem
            else if (m_progressControl.getProgressValueEquals("stage", "addparts")) 
            {
                m_hintController.manuallyRemoveAllHints();
                m_progressControl.setProgressValue("hinting", null);
                m_progressControl.setProgressValue("stage", "finishedbarmodel");
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
                }  // Make sure the character is redrawn  
                
                
                
                refreshFirstPageAvatar();
            }
            else if (m_progressControl.getProgressValueEquals("stage", "pickcolor")) 
            {
                m_color = "start";
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_color = targetBarWhole.barLabels[0].value;
                }  // Make sure the character is redrawn  
                
                
                
                refreshFirstPageAvatar();
            }
            else if (m_progressControl.getProgressValueEquals("stage", "pickjob")) 
            {
                m_job = "none";
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_job = targetBarWhole.barLabels[0].value;
                }  // Make sure the character is redrawn  
                
                
                
                refreshFirstPageAvatar();
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "inequationmode")) 
            {
                m_hintController.manuallyRemoveAllHints();
                m_progressControl.setProgressValue("stage", "finish");
            }
        }
    }
    
    private function clearBarModelHistory() : Void
    {
        // Clear the bar model
        (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
        m_barModelArea.getBarModelData().clear();
        m_barModelArea.redraw();
        
        m_gameEngine.setDeckAreaContent([], [], false);
    }
    
    private function setupGenderSelectModel() : Void
    {
        LevelCommonUtil.setReferenceBarModelForPickem("any_gender", "gender",
                [TutorialV2Util.GENDER_MALE, TutorialV2Util.GENDER_FEMALE], m_validateBarModel);
        
        refreshFirstPageAvatar();
    }
    
    private function setupColorSelectModel() : Void
    {
        var characterColors : Array<String> = ["red", "orange", "yellow", "blue", "green", "purple"];
        LevelCommonUtil.setReferenceBarModelForPickem("a_color", "color", characterColors, m_validateBarModel);
    }
    
    private function setupJobSelectModel() : Void
    {
        var characterJobs : Array<String> = ["zombie", "ninja", "basketball", "superhero", "fairy"];
        LevelCommonUtil.setReferenceBarModelForPickem("any_job", "job", characterJobs, m_validateBarModel);
    }
    
    private function customAddBarFunction(barWholes : Array<BarWhole>,
            data : String,
            color : Int,
            labelOnTopValue : String,
            id : String = null) : Void
    {
        var value : Float = parseInt(data);
        
        // Any non numeric cards default to a unit of 1
        // (This value can be set in the extra data field of a level file)
        var targetNumeratorValue : Float = 1;
        var targetDenominatorValue : Float = 1;
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        if (!Math.isNaN(value)) 
        {
            // Possible the value is negative, right now don't have this affect the ratio
            targetNumeratorValue = Math.abs(value);
            targetDenominatorValue = barModelArea.normalizingFactor;
        }
        
        var newBarWhole : BarWhole = new BarWhole(true, id);
        
        var newBarSegment : BarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, color, null);
        newBarWhole.barSegments.push(newBarSegment);
        
        // Add a label for potions and make sure the number of potion images matches the numeric value of the bar
        var newBarLabel : BarLabel = new BarLabel(data, 0, 0, true, false, BarLabel.BRACKET_NONE, null);
        newBarLabel.numImages = value;
        newBarWhole.barLabels.push(newBarLabel);
        
        var newLabelValue : String = null;
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
            newLabelValue = "job";
        }
        
        if (newLabelValue != null) 
        {
            newBarWhole.barLabels.push(new BarLabel(newLabelValue, 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
        }
        
        barWholes.push(newBarWhole);
    }
    
    private function refreshFirstPageAvatar() : Void
    {
        // Clear out the old avatar
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var avatarContainerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById("avatar_container_a", null, 0);
        avatarContainerViews[0].removeChildren();
        
        var startingAvatar : Image = generateAvatarImageFromParams();
        m_temporaryTextureControl.saveImageWithId("start", startingAvatar);
        
        avatarContainerViews[0].addChild(startingAvatar);
    }
    
    private function generateAvatarImageFromParams() : Image
    {
        return TutorialV2Util.createAvatarFromChoices(m_gender, m_color, m_job, false, m_avatarControl);
    }
    
    private function onSwitchModelClicked(inBarModelMode : Bool) : Void
    {
        if (inBarModelMode) 
        {
            this.getNodeById("BarToCard").setIsActive(false);
        }
        else 
        {
            this.getNodeById("BarToCard").setIsActive(true);
            
            if (m_progressControl.getProgressValueEquals("stage", "changetoequationmode")) 
            {
                removeDialogForUi({
                            id : "switchModelButton"

                        });
                
                m_progressControl.setProgressValue("stage", "inequationmode");
            }
        }
    }
    
    /*
    Logic for hints
    */
    private function showPickAny() : Void
    {
        // Highlight the bar model area
        showDialogForUi({
                    id : "barModelArea",
                    text : "Drag into here!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_RIGHT,
                    width : 150,
                    height : 50,
                    animationPeriod : 1,
                    xOffset : -390,

                });
    }
    
    private function hidePickAny() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
    private function showSubmitAnswer() : Void
    {
        // Highlight the validate button
        showDialogForUi({
                    id : "validateButton",
                    text : "Click when done.",
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_UP,
                    width : 170,
                    height : 40,
                    animationPeriod : 1,

                });
    }
    
    private function hideSubmitAnswer() : Void
    {
        removeDialogForUi({
                    id : "validateButton"

                });
    }
    
    private function showPickRightNumber(text : String) : Void
    {
        // Highlight the deck
        showDialogForUi({
                    id : "barModelArea",
                    text : text,
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_DOWN,
                    width : 200,
                    height : 50,
                    animationPeriod : 1,
                    xOffset : 0,
                    yOffset : -160,

                });
    }
    
    private function hidePickRightNumber() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
    private var m_pickedId : String;
    private function showCreateLabel() : Void
    {
        if (m_barModelArea.getBarWholeViews().length > 0 && m_barModelArea.getBarWholeViews()[0].segmentViews.length > 0) 
        {
            var segmentView : BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[0];
            var targetSegmentId : String = segmentView.data.id;
            m_barModelArea.addOrRefreshViewFromId(targetSegmentId);
            showDialogForBaseWidget({
                        id : targetSegmentId,
                        widgetId : "barModelArea",
                        text : "Drag here to name.",
                        color : 0x5082B9,
                        direction : Callout.DIRECTION_DOWN,
                        width : 200,
                        height : 50,
                        animationPeriod : 1,
                        xOffset : 0,
                        yOffset : 30,

                    });
            m_pickedId = targetSegmentId;
        }
    }
    
    private function hideCreateLabel() : Void
    {
        if (m_pickedId != null) 
        {
            removeDialogForBaseWidget({
                        id : m_pickedId,
                        widgetId : "barModelArea",

                    });
            m_pickedId = null;
        }
    }
    
    private function showDragNumber() : Void
    {
        showDialogForUi({
                    id : "rightTermArea",
                    text : "Put 3 here!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
        
        // Highlight the bar segment
        if (m_barModelArea.getBarModelData().barWholes.length > 0) 
        {
            var segmentId : String = m_barModelArea.getBarModelData().barWholes[0].barSegments[0].id;
            m_barModelArea.addOrRefreshViewFromId(segmentId);
            m_barModelArea.componentManager.addComponentToEntity(new HighlightComponent(segmentId, 0xFF9900, 2));
        }
    }
    
    private function hideDragNumber() : Void
    {
        removeDialogForUi({
                    id : "rightTermArea"

                });
        
        if (m_barModelArea.getBarModelData().barWholes.length > 0) 
        {
            var segmentId : String = m_barModelArea.getBarModelData().barWholes[0].barSegments[0].id;
            m_barModelArea.componentManager.removeComponentFromEntity(segmentId, HighlightComponent.TYPE_ID);
        }
    }
    
    private function showDragVariable() : Void
    {
        // Determine which side the numbers was placed in
        var totalName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_correctLabel).abbreviatedName;
        showDialogForUi({
                    id : "leftTermArea",
                    text : "Put '" + totalName + "' here!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
        
        // Highlight the bracket label
        if (m_barModelArea.getBarModelData().barWholes.length > 0) 
        {
            var labelId : String = null;
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EArray(EField(ECall(EField(EIdent(m_barModelArea),getBarModelData),[]),barWholes),EConst(CInt(0))),barLabels) type: null */ in m_barModelArea.getBarModelData().barWholes[0].barLabels)
            {
                if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                {
                    labelId = barLabel.id;
                    m_barModelArea.addOrRefreshViewFromId(labelId);
                    m_barModelArea.componentManager.addComponentToEntity(new HighlightComponent(labelId, 0xFF9900, 2));
                    break;
                }
            }
        }
    }
    
    private function hideDragVariable() : Void
    {
        removeDialogForUi({
                    id : "leftTermArea"

                });
        
        if (m_barModelArea.getBarModelData().barWholes.length > 0) 
        {
            var labelId : String = null;
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EArray(EField(ECall(EField(EIdent(m_barModelArea),getBarModelData),[]),barWholes),EConst(CInt(0))),barLabels) type: null */ in m_barModelArea.getBarModelData().barWholes[0].barLabels)
            {
                if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                {
                    labelId = barLabel.id;
                    m_barModelArea.componentManager.removeComponentFromEntity(labelId, HighlightComponent.TYPE_ID);
                    break;
                }
            }
        }
    }
    
    private function showSubmitEquation() : Void
    {
        showDialogForUi({
                    id : "modelEquationButton",
                    text : "Press when done!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
    }
    
    private function hideSubmitEquation() : Void
    {
        removeDialogForUi({
                    id : "modelEquationButton"

                });
    }
}
