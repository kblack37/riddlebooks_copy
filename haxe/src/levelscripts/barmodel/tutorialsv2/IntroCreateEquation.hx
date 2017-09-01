package levelscripts.barmodel.tutorialsv2;


import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import wordproblem.callouts.CalloutCreator;
import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.SymbolData;
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
import wordproblem.hints.selector.SimpleAdditionHint;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.barmodel.AddNewBarSegment;
import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
import wordproblem.scripts.barmodel.AddNewVerticalLabel;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
import wordproblem.scripts.barmodel.RemoveVerticalLabel;
import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.expression.RemoveTerm;
import wordproblem.scripts.expression.ResetTermArea;
import wordproblem.scripts.expression.UndoTermArea;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.AvatarControl;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.TextToCard;

class IntroCreateEquation extends BaseCustomLevelScript
{
    private var m_avatarControl : AvatarControl;
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    /**
     * Script controlling swapping between bar model and equation model.
     */
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    private var m_validateBarModel : ValidateBarModelArea;
    private var m_validateEquation : ModelSpecificEquation;
    
    private var m_textAreaWidget : TextAreaWidget;
    private var m_barModelArea : BarModelAreaWidget;
    
    private var m_hintController : HelpController;
    
    // Sequenced hints
    private var m_showNumberAHint : HintScript;
    private var m_showVariableAHint : HintScript;
    private var m_showSubmitHint : HintScript;
    
    // This problem deals with solving two diagrams.
    // The name of the 'total' in each diagram differs depending on the job
    // Create mapping from job to what the name of the total should be
    private var m_jobToTotalMapping : Dynamic = {
            ninja : {
                total_a_name : "guards snuck past",
                total_a_abbr : "total guards",
                total_b_name : "total rooms counted",
                total_b_abbr : "rooms",

            },
            zombie : {
                total_a_name : "",
                total_a_abbr : "",
                total_b_name : "",
                total_b_abbr : "",

            },
            basketball : {
                total_a_name : "shots made",
                total_a_abbr : "total made shots",
                total_b_name : "total turnovers",
                total_b_abbr : "turnovers",

            },
            fairy : {
                total_a_name : "travelers lured",
                total_a_abbr : "total travelers",
                total_b_name : "total chirps made",
                total_b_abbr : "chirps",

            },
            superhero : {
                total_a_name : "villians battled",
                total_a_abbr : "total villians",
                total_b_name : "",
                total_b_abbr : "",

            },

        };
    
    /**
     * Based on the characters job selection, different sets of numbers are used.
     * Keeping track of numbers may be necessary for different hints.
     */
    private var m_targetNumbersActive : Array<String>;
    private var m_expressionNodeBuffer : Array<ExpressionNode>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
        
        m_expressionNodeBuffer = new Array<ExpressionNode>();
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
        m_switchModelScript.targetY = 80;
        super.pushChild(m_switchModelScript);
        
        // At the start do not allow any changes to the bar model
        var prioritySelector : PrioritySelector = new PrioritySelector("barmodelgestures", false);
        prioritySelector.pushChild(new AddNewBarSegment(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment"));
        prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel"));
        prioritySelector.pushChild(new AddNewVerticalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewVerticalLabel"));
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 2, "AddNewBar"));
        prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
        prioritySelector.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager, "RemoveHorizontalLabel"));
        prioritySelector.pushChild(new RemoveVerticalLabel(gameEngine, expressionCompiler, assetManager, "RemoveVerticalLabel"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", "ShowAddNewBarSegmentHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewVerticalLabel", "ShowAddNewVerticalLabelHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        super.pushChild(prioritySelector);
        
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        
        // Used to drag things from the bar model area to the equation area
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
        
        // Add logic to only accept the model of a particular equation
        m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
        super.pushChild(m_validateEquation);
        
        // Add logic to handle adding new cards (only active after all cards discovered)
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm"));
        super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
        
        super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", true));
        super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", true));
        m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
        super.pushChild(m_validateBarModel);
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText", false));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        m_showNumberAHint = new CustomFillLogicHint(showDragNumberA, null, null, null, hideDragNumberA, null, true);
        m_showVariableAHint = new CustomFillLogicHint(showDragVariableA, null, null, null, hideDragVariableA, null, true);
        m_showSubmitHint = new CustomFillLogicHint(showSubmitEquation, null, null, null, hideSubmitEquation, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            if (m_progressControl.getProgressValueEquals("hinting", "firstequation")) 
            {
                // Check if added the appropriate values to the term areas
                var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                
                // Check if the player has added two numbers on one side and the variable on the other
                var addedNumberA : Bool = false;
                var addedNumberB : Bool = false;
                var addedVariable : Bool = false;
                getExpressionsAdded(leftTermArea.getTree().getRoot(), "total_a");
                getExpressionsAdded(rightTermArea.getTree().getRoot(), "total_a");
                function getExpressionsAdded(root : ExpressionNode, totalName : String) : Void
                {
                    as3hx.Compat.setArrayLength(m_expressionNodeBuffer, 0);
                    ExpressionUtil.getLeafNodes(root, m_expressionNodeBuffer);
                    for (leafNode in m_expressionNodeBuffer)
                    {
                        if (leafNode.data == m_targetNumbersActive[0]) 
                        {
                            addedNumberA = true;
                        }
                        else if (leafNode.data == m_targetNumbersActive[1]) 
                        {
                            addedNumberB = true;
                        }
                        else if (leafNode.data == "total_a") 
                        {
                            addedVariable = true;
                        }
                    }
                };
                
                if ((!addedNumberA || !addedNumberB) && m_hintController.getCurrentlyShownHint() != m_showNumberAHint) 
                {
                    m_hintController.manuallyShowHint(m_showNumberAHint);
                }
                else if (addedNumberA && addedNumberB && !addedVariable && m_hintController.getCurrentlyShownHint() != m_showVariableAHint) 
                {
                    m_hintController.manuallyShowHint(m_showVariableAHint);
                }
                // Set equation validation active if they have the right answer
                // The restrictions we set up should force this to be true
                else if (addedNumberA && addedNumberB && addedVariable && m_hintController.getCurrentlyShownHint() != m_showSubmitHint) 
                {
                    m_hintController.manuallyShowHint(m_showSubmitHint);
                }
                
                
                
                
                
                var equationCorrect : Bool = addedNumberA && addedNumberB && addedVariable;
                if (m_validateEquation.getIsActive() != equationCorrect) 
                {
                    m_validateEquation.setIsActive(equationCorrect);
                }
            }
        }
        
        return super.visit();
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_avatarControl.dispose();
        m_temporaryTextureControl.dispose();
        
        m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.TERM_AREAS_CHANGED, bufferEvent);
    }
    
    override public function getNumCopilotProblems() : Int
    {
        return 3;
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        super.disablePrevNextTextButtons();
        
        // Set up all the special controllers for logic and data management in this specific level
        m_avatarControl = new AvatarControl();
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        // Clip out content not belonging to the character selected job
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 0);
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 1);
        
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        var helperCharacterController : HelperCharacterController = new HelperCharacterController(
        m_gameEngine.getCharacterComponentManager(), 
        new CalloutCreator(m_textParser, m_textViewFactory));
        m_hintController.setRootHintSelectorNode(new SimpleAdditionHint(
                m_gameEngine, m_assetManager, m_textParser, m_textViewFactory, helperCharacterController, m_validateBarModel, m_validateEquation, 
                ));
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitHeight = 60;
        m_barModelArea.unitLength = 100;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        m_textAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.TERM_AREAS_CHANGED, bufferEvent);
        
        var selectedGender : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("gender"), String) catch(e:Dynamic) null;
        
        // Bind the numbers and the variables to the text
        // Render the bar model, depending on the job the total and the numbers being added together might be different
        var numbersToAdd : Array<Int> = new Array<Int>();
        numbersToAdd.push(7);
        numbersToAdd.push(9);
        
        
        // Below is all set up of initial problem
        var nameForFirstTotal : String = "total_a";
        
        // Place limits on what can be added
        var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        leftTermArea.restrictValues = true;
        leftTermArea.restrictedValues.push(numbersToAdd[0], numbersToAdd[1]);
        leftTermArea.maxCardAllowed = 2;
        var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        rightTermArea.restrictValues = true;
        rightTermArea.restrictedValues.push(nameForFirstTotal);
        rightTermArea.maxCardAllowed = 1;
        
        var expressionDataForTotal : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
        var firstTotalSymbolData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(nameForFirstTotal);
        firstTotalSymbolData.abbreviatedName = expressionDataForTotal.total_a_abbr;
        firstTotalSymbolData.name = expressionDataForTotal.total_a_name;
        m_targetNumbersActive = new Array<String>();
        
        var existingModel : BarModelData = new BarModelData();
        var barWhole : BarWhole = new BarWhole(false);
        for (i in 0...numbersToAdd.length){
            var numberToAdd : Int = numbersToAdd[i];
            m_targetNumbersActive.push(Std.string(numberToAdd));
            barWhole.barSegments.push(new BarSegment(numberToAdd, 1, 0xFFFFFF, null));
            barWhole.barLabels.push(new BarLabel(numberToAdd + "", i, i, true, false, BarLabel.BRACKET_NONE, null));
        }
        barWhole.barLabels.push(new BarLabel(nameForFirstTotal, 0, numbersToAdd.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        existingModel.barWholes.push(barWhole);
        m_barModelArea.setBarModelData(existingModel);
        m_barModelArea.redraw(false);
        
        m_validateEquation.addEquation("1", generateSumEquation(numbersToAdd, nameForFirstTotal), false, true);
        
        var slideUpPositionY : Float = m_gameEngine.getUiEntity("deckAndTermContainer").y;
        m_switchModelScript.setContainerOriginalY(slideUpPositionY);
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0,
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
                                id : "part_a_question",
                                visible : true,
                                pageIndex : 0,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 290,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_switchModelScript.setIsActive(true);
                    showDialogForUi({
                                id : "switchModelButton",
                                text : "Click here!",
                                height : 50,
                                color : 0x5082B9,
                                direction : Callout.DIRECTION_UP,
                                animationPeriod : 1,

                            });
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "parta_equation_finished",

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Disable modification to term areas
                    getNodeById("AddTerm").setIsActive(false);
                    getNodeById("RemoveTerm").setIsActive(false);
                    m_switchModelScript.setIsActive(false);
                    
                    // Remove all the callouts for hints
                    m_progressControl.setProgressValue("hinting", null);
                    m_hintController.manuallyRemoveAllHints(false, true);
                    removeDialogForUi({
                                id : "barModelArea"

                            });
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        // After short delay slide the bar model down and clear the contents
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_switchModelScript.onSwitchModelClicked();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.4,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 300,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 1

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Activate the hint button
                    getNodeById("HintController").setIsActive(true);
                    
                    // Enable bar model validation
                    m_validateBarModel.setIsActive(true);
                    
                    // Clear bar model and equation
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    m_gameEngine.setTermAreaContent("leftTermArea rightTermArea", null);
                    
                    var levelId : Int = m_gameEngine.getCurrentLevel().getId();
                    
                    // Logic to setup the second problem
                    var numbersForModel : Array<Int> = new Array<Int>();
                    var docIdsForNumbers : Array<String> = ["number_a", "number_b"];
                    setDocumentIdsSelectable(docIdsForNumbers, true);
                    for (docId in docIdsForNumbers)
                    {
                        var value : String = TutorialV2Util.getNumberValueFromDocId(docId, m_textAreaWidget, 1);
                        m_gameEngine.addTermToDocument(value, docId);
                        numbersForModel.push(parseInt(value));
                        assignColorToCardFromSeed(value, levelId);
                    }
                    
                    m_gameEngine.addTermToDocument("total_b", "unknown");
                    assignColorToCardFromSeed("total_b", levelId);
                    
                    // Change the name of the symbol
                    var expressionDataForTotal : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
                    var symbolDataForTotal : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("total_b");
                    symbolDataForTotal.abbreviatedName = expressionDataForTotal.total_b_abbr;
                    symbolDataForTotal.name = expressionDataForTotal.total_b_name;
                    TutorialV2Util.addSimpleSumReferenceForModel(m_validateBarModel, numbersForModel, "total_b");
                    m_validateEquation.addEquation("2", generateSumEquation(numbersForModel, "total_b"), false, true);
                    
                    getNodeById("DragText").setIsActive(true);
                    getNodeById("barmodelgestures").setIsActive(true);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.8

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
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "partb_barmodel_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Term areas should not be as restricted in this case
                    var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                    leftTermArea.restrictValues = false;
                    leftTermArea.maxCardAllowed = 2;
                    var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                    rightTermArea.restrictValues = false;
                    rightTermArea.maxCardAllowed = 2;
                    
                    m_switchModelScript.setIsActive(true);
                    showDialogForUi({
                                id : "switchModelButton",
                                text : "Click here!",
                                color : 0x5082B9,
                                direction : Callout.DIRECTION_UP,
                                animationPeriod : 1,

                            });
                    getNodeById("barmodelgestures").setIsActive(false);
                    
                    getNodeById("AddTerm").setIsActive(true);
                    getNodeById("RemoveTerm").setIsActive(true);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "partb_equation_finished",

                }));
        // Slide results down after a short delay
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    getNodeById("AddTerm").setIsActive(false);
                    getNodeById("RemoveTerm").setIsActive(false);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 250,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 0);
        m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 1);
        m_progressControl.setProgressValue("stage", "start");
    }
    
    private function generateSumEquation(numbers : Array<Int>, nameForTotal : String) : String
    {
        var equation : String = nameForTotal + "=";
        for (i in 0...numbers.length){
            if (i > 0) 
            {
                equation += "+";
            }
            equation += Std.string(numbers[i]);
        }
        return equation;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "parta_equation_finished")) 
            {
                m_progressControl.setProgressValue("stage", "partb_barmodel_finished");
                m_validateBarModel.setIsActive(false);
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "parta_equation_start")) 
            {
                m_progressControl.setProgressValue("stage", "parta_equation_finished");
            }
            else if (m_progressControl.getProgressValueEquals("stage", "partb_barmodel_finished")) 
            {
                m_progressControl.setProgressValue("stage", "partb_equation_finished");
            }
        }
        else if (eventType == GameEvent.TERM_AREAS_CHANGED) 
            { }
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
            
            if (m_progressControl.getProgressValueEquals("stage", "start")) 
            {
                m_progressControl.setProgressValue("stage", "parta_equation_start");
                m_progressControl.setProgressValue("hinting", "firstequation");
                removeDialogForUi({
                            id : "switchModelButton"

                        });
                
                // Show tooltip on term areas
                showDialogForUi({
                            id : "barModelArea",
                            text : "Pick up pieces!",
                            color : 0x5082B9,
                            direction : Callout.DIRECTION_UP,
                            animationPeriod : 1,

                        });
            }
            else if (m_progressControl.getProgressValueEquals("stage", "partb_barmodel_finished")) 
            {
                removeDialogForUi({
                            id : "switchModelButton"

                        });
            }
        }
    }
    
    /*
    Logic for hints
    */
    private function showDragNumberA() : Void
    {
        showDialogForUi({
                    id : "leftTermArea",
                    text : "Add both numbers here!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
    }
    
    private function hideDragNumberA() : Void
    {
        removeDialogForUi({
                    id : "leftTermArea"

                });
    }
    
    private function showDragVariableA() : Void
    {
        // Determine which side the numbers was placed in
        var totalName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("total_a").abbreviatedName;
        var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var uiEntityToAddTo : String = ((leftTermArea.getWidgetRoot() == null)) ? "leftTermArea" : "rightTermArea";
        showDialogForUi({
                    id : uiEntityToAddTo,
                    text : "Put '" + totalName + "' here!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
    }
    
    private function hideDragVariableA() : Void
    {
        removeDialogForUi({
                    id : "rightTermArea"

                });
        removeDialogForUi({
                    id : "leftTermArea"

                });
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
