package levelscripts.barmodel.tutorialsv2;


import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import wordproblem.callouts.CalloutCreator;
import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
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
import wordproblem.hints.processes.HighlightTextProcess;
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
import wordproblem.scripts.barmodel.ResetBarModelArea;
import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.UndoBarModelArea;
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

/**
 * Introduce creating both the horizontal AND vertical labels
 */
class IntroAddLabelEasy extends BaseCustomLevelScript
{
    private var m_avatarControl : AvatarControl;
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    private var m_barModelArea : BarModelAreaWidget;
    private var m_textAreaWidget : TextAreaWidget;
    
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    private var m_validateBarModel : ValidateBarModelArea;
    private var m_validateEquation : ModelSpecificEquation;
    
    private var m_expressionNodeBuffer : Array<ExpressionNode>;
    private var m_hintController : HelpController;
    private var m_submitBarModelHint : HintScript;
    private var m_createInitialBox : HintScript;
    private var m_addNumberToExistingRow : HintScript;
    private var m_createHorizontalBracket : HintScript;
    private var m_createNumbersDifferentRows : HintScript;
    private var m_createVerticalBracket : HintScript;
    private var m_showNumberAHint : HintScript;
    private var m_showVariableAHint : HintScript;
    private var m_showSubmitHint : HintScript;
    
    private var m_firstNumberValue : String;
    private var m_secondNumberValue : String;
    private var m_partATotalValue : String = "total_a";
    private var m_partBTotalValue : String = "total_b";
    
    // This problem deals with solving two diagrams.
    // The name of the 'total' in each diagram differs depending on the job
    // Create mapping from job to what the name of the total should be
    private var m_jobToTotalMapping : Dynamic = {
            ninja : {
                total_a_name : "months spent training",
                total_a_abbr : "total months",
                numeric_unit_a : "months",
                total_b_name : "disguises mastered",
                total_b_abbr : "total disguises",
                numeric_unit_b : "disguises",

            },
            zombie : {
                total_a_name : "zombies in horde",
                total_a_abbr : "total zombies",
                numeric_unit_a : "zombies",
                total_b_name : "people ran away",
                total_b_abbr : "total people",
                numeric_unit_b : "people",

            },
            basketball : {
                total_a_name : "rebounds in drill",
                total_a_abbr : "total rebounds",
                numeric_unit_a : "rebounds",
                total_b_name : "passes in play",
                total_b_abbr : "total passes",
                numeric_unit_b : "passes",

            },
            fairy : {
                total_a_name : "fairies in forest",
                total_a_abbr : "total fairies",
                numeric_unit_a : "fairies",
                total_b_name : "tree checked",
                total_b_abbr : "total trees",
                numeric_unit_b : "trees",

            },
            superhero : {
                total_a_name : "rads absorbed",
                total_a_abbr : "total rads",
                numeric_unit_a : "rads",
                total_b_name : "people rescued",
                total_b_abbr : "total people",
                numeric_unit_b : "people",

            },

        };
    
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
        
        // Control of deck
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        
        var prioritySelector : PrioritySelector = new PrioritySelector("barmodelgestures");
        prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel", false));
        prioritySelector.pushChild(new AddNewVerticalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewVerticalLabel", false));
        prioritySelector.pushChild(new AddNewBarSegment(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", true));
        prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
        prioritySelector.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager, "RemoveHorizontalLabel", false));
        prioritySelector.pushChild(new RemoveVerticalLabel(gameEngine, expressionCompiler, assetManager, "RemoveVerticalLabel"));
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewVerticalLabel", "ShowAddNewVerticalLabelHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", "ShowAddNewBarSegmentHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        super.pushChild(prioritySelector);
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea", false));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea", false));
        super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
        
        m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
        super.pushChild(m_validateBarModel);
        
        // Add logic to only accept the model of a particular equation
        m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
        super.pushChild(m_validateEquation);
        
        // Dragging things from bar model to equation
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        
        // Adding parts to the term area
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm"));
        super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
        super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
        super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        m_submitBarModelHint = new CustomFillLogicHint(showSubmitAnswer, null, null, null, hideSubmitAnswer, null, true);
        m_createNumbersDifferentRows = new CustomFillLogicHint(showAddNumbersOnDifferentRows, null, null, null, hideAddNumbersOnDifferentRows, null, true);
        m_createVerticalBracket = new CustomFillLogicHint(showAddVerticalBracket, null, null, null, hideAddVerticalBracket, null, true);
        m_showNumberAHint = new CustomFillLogicHint(showDragNumberA, null, null, null, hideDragNumberA, null, true);
        m_showVariableAHint = new CustomFillLogicHint(showDragVariableA, null, null, null, hideDragVariableA, null, true);
        m_showSubmitHint = new CustomFillLogicHint(showSubmitEquation, null, null, null, hideSubmitEquation, null, true);
        m_createInitialBox = new CustomFillLogicHint(showAddInitialBox, null, null, null, hideAddInitialBox, null, true);
        m_addNumberToExistingRow = new CustomFillLogicHint(showAddNumbersInOneRow, null, null, null, hideAddNumbersInOneRow, null, true);
        m_createHorizontalBracket = new CustomFillLogicHint(showAddHorizontalBracket, null, null, null, hideAddHorizontalBracket, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "add_numbers_single_row")) 
            {
                foundFirstValue = false;
                foundSecondValue = false;
                barWholes = m_barModelArea.getBarModelData().barWholes;
                if (barWholes.length > 0) 
                {
                    var targetBarWhole : BarWhole = barWholes[0];
                    for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(targetBarWhole),barLabels) type: null */ in targetBarWhole.barLabels)
                    {
                        if (barLabel.value == m_firstNumberValue) 
                        {
                            foundFirstValue = true;
                        }
                        else if (barLabel.value == m_secondNumberValue) 
                        {
                            foundSecondValue = true;
                        }
                    }
                    
                    if (foundFirstValue && foundSecondValue) 
                    {
                        getNodeById("AddNewHorizontalLabel").setIsActive(true);
                        m_progressControl.setProgressValue("stage", "add_bracket_single_row");
                    }
                }
                
                if (!foundFirstValue && !foundSecondValue && m_hintController.getCurrentlyShownHint() != m_createInitialBox) 
                {
                    m_hintController.manuallyShowHint(m_createInitialBox);
                }
                else if ((foundFirstValue || foundSecondValue) && m_hintController.getCurrentlyShownHint() != m_addNumberToExistingRow) 
                {
                    m_hintController.manuallyShowHint(m_addNumberToExistingRow);
                }
                else if (foundFirstValue && foundSecondValue && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgressValueEquals("stage", "add_bracket_single_row")) 
            {
                var addedLabel : Bool = false;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    barWhole = m_barModelArea.getBarModelData().barWholes[0];
                    for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
                    {
                        if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                        {
                            addedLabel = true;
                            break;
                        }
                    }
                }
                
                if (!addedLabel && m_hintController.getCurrentlyShownHint() != m_createHorizontalBracket) 
                {
                    m_hintController.manuallyShowHint(m_createHorizontalBracket);
                }
                else if (addedLabel && m_hintController.getCurrentlyShownHint() != m_submitBarModelHint) 
                {
                    m_hintController.manuallyShowHint(m_submitBarModelHint);
                }
                
                if (addedLabel) 
                {
                    // Remove highlight on the total
                    this.deleteChild(this.getNodeById("highlight_total_process"));
                    
                    m_progressControl.setProgressValue("hinting", null);
                    m_validateBarModel.setIsActive(true);
                }
            }
            else if (m_progressControl.getProgressValueEquals("stage", "add_numbers_vertical_model")) 
            {
                var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                var correctBoxValuesAdded : Bool = false;
                if (barWholes.length == 2) 
                {
                    // Make sure the second total was not one of the bars added
                    var foundFirstValue : Bool = false;
                    var foundSecondValue : Bool = false;
                    for (barWhole in barWholes)
                    {
                        for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
                        {
                            if (barLabel.value == m_firstNumberValue) 
                            {
                                foundFirstValue = true;
                            }
                            else if (barLabel.value == m_secondNumberValue) 
                            {
                                foundSecondValue = true;
                            }
                        }
                    }
                    
                    correctBoxValuesAdded = foundFirstValue && foundSecondValue;
                }
                
                
                if (correctBoxValuesAdded) 
                {
                    m_progressControl.setProgressValue("stage", "add_bracket_vertical_model");
                }  // If added the boxes, allow them to add the right  
                
                
                
                getNodeById("AddNewVerticalLabel").setIsActive(correctBoxValuesAdded);
                
                if (!correctBoxValuesAdded && m_hintController.getCurrentlyShownHint() != m_createNumbersDifferentRows) 
                {
                    m_hintController.manuallyShowHint(m_createNumbersDifferentRows);
                }
                else if (correctBoxValuesAdded && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgressValueEquals("stage", "add_bracket_vertical_model")) 
            {
                // Make sure total is added as vertical bracket
                var verticalBracketAdded : Bool = false;
                if (m_barModelArea.getBarModelData().verticalBarLabels.length > 0) 
                {
                    verticalBracketAdded = m_barModelArea.getBarModelData().verticalBarLabels[0].value == m_partBTotalValue;
                }
                
                if (!verticalBracketAdded && m_hintController.getCurrentlyShownHint() != m_createVerticalBracket) 
                {
                    m_hintController.manuallyShowHint(m_createVerticalBracket);
                }
                else if (verticalBracketAdded && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
                
                if (m_validateBarModel.getIsActive() != verticalBracketAdded) 
                {
                    m_validateBarModel.setIsActive(verticalBracketAdded);
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "firstequation")) 
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
                        if (leafNode.data == m_firstNumberValue) 
                        {
                            addedNumberA = true;
                        }
                        else if (leafNode.data == m_secondNumberValue) 
                        {
                            addedNumberB = true;
                        }
                        else if (leafNode.data == m_partBTotalValue) 
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
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
    }
    
    override public function getNumCopilotProblems() : Int
    {
        return 2;
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
        
        // Special tutorial hints
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, 
        "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitHeight = 60;
        m_barModelArea.unitLength = 300;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        m_textAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        
        // Bind a very simple selector for hints in the initial model. The starting hints should
        // reference how to construct the basic sum model
        var helperCharacterController : HelperCharacterController = new HelperCharacterController(
        m_gameEngine.getCharacterComponentManager(), 
        new CalloutCreator(m_textParser, m_textViewFactory));
        m_hintController.setRootHintSelectorNode(new SimpleAdditionHint(
                m_gameEngine, m_assetManager, m_textParser, m_textViewFactory, helperCharacterController, m_validateBarModel, null, 
                ));
        
        // Bind events
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
        
        // Get the saved decisions made by the players
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        var selectedGender : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("gender"), String) catch(e:Dynamic) null;
        
        // Need to clip out the portions of the text that are not related to 'job' that the player
        // had selected in the first level.
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 0);
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 2);
        
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
                    greyOutAndDisableButton("undoButton", true);
                    greyOutAndDisableButton("resetButton", true);
                    setDocumentIdVisible({
                                id : "multiple_answers_message",
                                visible : true,
                                pageIndex : 0,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 1.0

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 350,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    var sum : Float = 0;
                    var numbersForModel : Array<Int> = new Array<Int>();
                    var docIdsForNumbers : Array<String> = ["part_a_number_a", "part_a_number_b"];
                    setDocumentIdsSelectable(docIdsForNumbers, true);
                    for (docId in docIdsForNumbers)
                    {
                        var value : String = TutorialV2Util.getNumberValueFromDocId(docId, m_textAreaWidget);
                        m_gameEngine.addTermToDocument(value, docId);
                        
                        var valueAsNumber : Float = parseInt(value);
                        numbersForModel.push(valueAsNumber);
                        sum += valueAsNumber;
                        
                        if (m_firstNumberValue == null) 
                        {
                            m_firstNumberValue = value;
                        }
                        else 
                        {
                            m_secondNumberValue = value;
                        }
                    }
                    
                    var levelId : Int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(m_firstNumberValue, levelId);
                    assignColorToCardFromSeed(m_secondNumberValue, levelId);
                    assignColorToCardFromSeed(m_partATotalValue, levelId);
                    
                    // Add unit names to numbers
                    var unitName : String = Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_a;
                    var dataForCard : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_firstNumberValue);
                    dataForCard.abbreviatedName = m_firstNumberValue + " " + unitName;
                    dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_secondNumberValue);
                    dataForCard.abbreviatedName = m_secondNumberValue + " " + unitName;
                    
                    m_gameEngine.getCurrentLevel().termValueToBarModelValue[m_partATotalValue] = sum;
                    
                    // Change the name of the symbol
                    var expressionDataForTotal : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
                    var symbolDataForTotal : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("total_a");
                    symbolDataForTotal.abbreviatedName = expressionDataForTotal.total_a_abbr;
                    symbolDataForTotal.name = expressionDataForTotal.total_a_name;
                    TutorialV2Util.addSimpleSumReferenceForModel(m_validateBarModel, numbersForModel, "total_a");
                    
                    // Show hints about the horizontal model
                    m_progressControl.setProgressValue("stage", "add_numbers_single_row");
                    
                    // Highlight the numbers
                    (try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                            ["part_a_number_a", "part_a_number_b"], 0xFF9900, 1, "highlightnumbersfirstpart"));
                    
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "add_bracket_single_row",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Only allow validation if they added the components in the correct manner
                    m_validateBarModel.setIsActive(true);
                    
                    (try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null).deleteChild(getNodeById("highlightnumbersfirstpart"));
                    
                    // Player has added both numbers now have them add the label
                    // Highlight the unknown and add a dialog under the bar wholes
                    (try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null).pushChild(new HighlightTextProcess(m_textAreaWidget, 
                            ["part_a_total"], 0xFF9900, 1, "addunknownlabel"));
                    
                    // Once the numbers have been added DO NOT allow user to change them
                    // Want them to only be able to add the new horizontal bar
                    getNodeById("RemoveBarSegment").setIsActive(false);
                    
                    // Make the total a draggable part of the text
                    var docIdsForPartATotal : String = "part_a_total";
                    setDocumentIdsSelectable([docIdsForPartATotal], true);
                    m_gameEngine.addTermToDocument("total_a", docIdsForPartATotal);
                    
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "parta_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(false);
                    m_hintController.manuallyRemoveAllHints();
                    
                    var rootNode : BaseCustomLevelScript = try cast(param.rootNode, BaseCustomLevelScript) catch(e:Dynamic) null;
                    rootNode.deleteChild(rootNode.getNodeById("addunknownlabel"));
                    
                    m_gameEngine.setDeckAreaContent([], [], false);
                    
                    getNodeById("barmodelgestures").setIsActive(false);
                    m_hintController.setIsActive(false);
                    
                    return ScriptStatus.SUCCESS;
                }, {
                    rootNode : this

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.6

                }));
        
        // Once solved the bar model, show text telling the player that they will need to solve the equation
        // as well.
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 1

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setDocumentIdVisible({
                                id : "new_add_method",
                                visible : true,
                                pageIndex : 1,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        
        // Once they read the instructions, go to the next page with the problem
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 1.0

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
                    var docIds : Array<String> = ["part_b_number_a", "part_b_number_b", "part_b_total"];
                    setDocumentIdsSelectable(docIds, false, 2);
                    
                    setDocumentIdVisible({
                                id : selectedPlayerJob,
                                visible : true,
                                pageIndex : 2,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 1.0

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 470,
                    y : 290,

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Clear out the bar model while it is hidden
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    var numbersForModel : Array<Int> = new Array<Int>();
                    var docIdsForNumbers : Array<String> = ["part_b_number_a", "part_b_number_b"];
                    var sum : Float = 0;
                    m_firstNumberValue = null;
                    m_secondNumberValue = null;
                    for (docId in docIdsForNumbers)
                    {
                        var value : String = TutorialV2Util.getNumberValueFromDocId(docId, m_textAreaWidget, 2);
                        m_gameEngine.addTermToDocument(value, docId);
                        
                        var valueAsNumber : Float = parseInt(value);
                        numbersForModel.push(valueAsNumber);
                        sum += valueAsNumber;
                        
                        if (m_firstNumberValue == null) 
                        {
                            m_firstNumberValue = value;
                        }
                        else 
                        {
                            m_secondNumberValue = value;
                        }
                    }
                    
                    var levelId : Int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(m_firstNumberValue, levelId);
                    assignColorToCardFromSeed(m_secondNumberValue, levelId);
                    assignColorToCardFromSeed(m_partBTotalValue, levelId);
                    
                    // Add unit names to numbers
                    var unitName : String = Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_b;
                    var dataForCard : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_firstNumberValue);
                    dataForCard.abbreviatedName = m_firstNumberValue + " " + unitName;
                    dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_secondNumberValue);
                    dataForCard.abbreviatedName = m_secondNumberValue + " " + unitName;
                    
                    m_gameEngine.getCurrentLevel().termValueToBarModelValue[m_partBTotalValue] = sum;
                    
                    var docIdsForPartATotal : String = "part_b_total";
                    m_gameEngine.addTermToDocument(m_partBTotalValue, docIdsForPartATotal);
                    
                    // Change the name of the symbol
                    var expressionDataForTotal : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
                    var symbolDataForTotal : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_partBTotalValue);
                    symbolDataForTotal.abbreviatedName = expressionDataForTotal.total_b_abbr;
                    symbolDataForTotal.name = expressionDataForTotal.total_b_name;
                    
                    // Redraw an existing model into the area, this is the model we want the player to build an equation for
                    TutorialV2Util.addSimpleSumReferenceForModel(m_validateBarModel, numbersForModel, "total_b");
                    
                    getNodeById("RestrictCardsInBarModel").setIsActive(true);
                    getNodeById("barmodelgestures").setIsActive(true);
                    
                    // Enable adding multiple rows
                    (try cast(getNodeById("AddNewBar"), AddNewBar) catch(e:Dynamic) null).setMaxBarsAllowed(2);
                    getNodeById("AddNewBarSegment").setIsActive(false);
                    getNodeById("AddNewHorizontalLabel").setIsActive(false);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_progressControl.setProgressValue("stage", "add_numbers_vertical_model");
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "partb_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    getNodeById("barmodelgestures").setIsActive(false);
                    m_validateBarModel.setIsActive(false);
                    
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
                    
                    greyOutAndDisableButton("undoButton", false);
                    greyOutAndDisableButton("resetButton", false);
                    getNodeById("UndoTermArea").setIsActive(true);
                    getNodeById("ResetTermArea").setIsActive(true);
                    
                    // Place limits on what can be added
                    var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                    leftTermArea.restrictValues = true;
                    leftTermArea.restrictedValues.push(m_firstNumberValue, m_secondNumberValue);
                    leftTermArea.maxCardAllowed = 2;
                    var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                    rightTermArea.restrictValues = true;
                    rightTermArea.restrictedValues.push(m_partBTotalValue);
                    rightTermArea.maxCardAllowed = 1;
                    m_validateEquation.addEquation("1",
                            generateSumEquation([parseInt(m_firstNumberValue), parseInt(m_secondNumberValue)], "total_b"), false, true);
                    
                    m_progressControl.setProgressValue("stage", "equation_start");
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "equation_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        // Slide results down after a short delay
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateEquation.setIsActive(false);
                    getNodeById("AddTerm").setIsActive(false);
                    getNodeById("RemoveTerm").setIsActive(false);
                    getNodeById("UndoTermArea").setIsActive(false);
                    getNodeById("ResetTermArea").setIsActive(false);
                    
                    // Get rid of all hints and callouts
                    removeDialogForUi({
                                id : "barModelArea"

                            });
                    m_hintController.manuallyRemoveAllHints();
                    m_progressControl.setProgressValue("hinting", null);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 1.0

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 0);
        m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 2);
        m_progressControl.setProgressValue("stage", "start");
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "add_bracket_single_row")) 
            {
                m_hintController.manuallyRemoveAllHints();
                m_progressControl.setProgressValue("stage", "parta_finished");
            }
            else if (m_progressControl.getProgressValueEquals("stage", "add_bracket_vertical_model")) 
            {
                m_hintController.manuallyRemoveAllHints();
                m_progressControl.setProgressValue("stage", "partb_finished");
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "inequation")) 
            {
                m_progressControl.setProgressValue("stage", "equation_finished");
            }
        }
        else if (eventType == GameEvent.HINT_BUTTON_SELECTED) 
        {
            // On click hint, remove the dialog on the button
            if (m_progressControl.getProgressValueEquals("stage", "partb_start")) 
            {
                removeDialogForUi({
                            id : "hintButton"

                        });
            }
        }
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
    
    private function onSwitchModelClicked(inBarModelMode : Bool) : Void
    {
        if (inBarModelMode) 
        {
            this.getNodeById("BarToCard").setIsActive(false);
        }
        else 
        {
            this.getNodeById("BarToCard").setIsActive(true);
            
            if (m_progressControl.getProgressValueEquals("stage", "equation_start")) 
            {
                m_progressControl.setProgressValue("stage", "inequation");
                m_progressControl.setProgressValue("hinting", "firstequation");
                removeDialogForUi({
                            id : "switchModelButton"

                        });
                
                // Show tooltip on term areas
                showDialogForUi({
                            id : "barModelArea",
                            text : "Drag the blocks!",
                            color : 0x5082B9,
                            direction : Callout.DIRECTION_UP,
                            animationPeriod : 1,

                        });
            }
        }
    }
    
    /*
    Logic for hints
    */
    private var m_pickedId : String;
    
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
    
    private function showAddInitialBox() : Void
    {
        showDialogForUi({
                    id : "barModelArea",
                    text : "Add a number here!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_DOWN,
                    width : 150,
                    height : 50,
                    animationPeriod : 1,
                    yOffset : -160,

                });
    }
    
    private function hideAddInitialBox() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
    private function showAddNumbersInOneRow() : Void
    {
        // The dialog should point the right end of the box
        var id : String;
        if (m_barModelArea.getBarWholeViews().length > 0) 
        {
            var barWholeView : BarWholeView = m_barModelArea.getBarWholeViews()[0];
            if (barWholeView.segmentViews.length > 0) 
            {
                var segmentView : BarSegmentView = barWholeView.segmentViews[0];
                id = segmentView.data.id;
                
                var segmentBounds : Rectangle = segmentView.getBounds(m_barModelArea);
                var xOffset : Float = (segmentBounds.right - segmentBounds.left) * 0.5;
            }
        }
        
        if (id != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : "Put other number here to add.",
                        color : 0x5082B9,
                        direction : Callout.DIRECTION_DOWN,
                        width : 200,
                        height : 70,
                        animationPeriod : 1,
                        xOffset : xOffset,

                    });
            m_pickedId = id;
        }
    }
    
    private function hideAddNumbersInOneRow() : Void
    {
        if (m_pickedId != null) 
        {
            removeDialogForBaseWidget({
                        id : m_pickedId,
                        widgetId : "barModelArea",

                    });
        }
    }
    
    private function showAddHorizontalBracket() : Void
    {
        if (m_barModelArea.getBarWholeViews().length > 0 && m_barModelArea.getBarWholeViews()[0].segmentViews.length > 0) 
        {
            var segmentView : BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[0];
            var targetSegmentId : String = segmentView.data.id;
            m_barModelArea.addOrRefreshViewFromId(targetSegmentId);
            showDialogForBaseWidget({
                        id : targetSegmentId,
                        widgetId : "barModelArea",
                        text : "Put the total here.",
                        color : 0x5082B9,
                        direction : Callout.DIRECTION_DOWN,
                        width : 200,
                        height : 50,
                        animationPeriod : 1,
                        xOffset : -50,
                        yOffset : 20,

                    });
            m_pickedId = targetSegmentId;
        }
    }
    
    private function hideAddHorizontalBracket() : Void
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
    
    private function showAddNumbersOnDifferentRows() : Void
    {
        showDialogForUi({
                    id : "barModelArea",
                    text : "Add the numbers on different rows!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_RIGHT,
                    width : 150,
                    height : 100,
                    animationPeriod : 1,
                    xOffset : -300,
                    yOffset : 0,

                });
    }
    
    private function hideAddNumbersOnDifferentRows() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
    private function showAddVerticalBracket() : Void
    {
        showDialogForUi({
                    id : "barModelArea",
                    text : "Add the total here!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    width : 150,
                    height : 50,
                    animationPeriod : 1,
                    xOffset : 320,
                    yOffset : 0,

                });
    }
    
    private function hideAddVerticalBracket() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
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
        var totalName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_partBTotalValue).abbreviatedName;
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
