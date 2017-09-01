package levelscripts.barmodel.tutorialsv2;


import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.component.HighlightComponent;
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
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
import wordproblem.scripts.barmodel.AddNewLabelOnSegment;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.MultiplyBarSegments;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckCallout;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.TextToCard;

class IntroMultiplication extends BaseCustomLevelScript
{
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    private var m_validateBarModel : ValidateBarModelArea;
    private var m_validateEquation : ModelSpecificEquation;
    
    private var m_textAreaWidget : TextAreaWidget;
    private var m_barModelArea : BarModelAreaWidget;
    private var m_hintController : HelpController;
    
    private var m_multiplyHint : HintScript;
    private var m_addTotalHint : HintScript;
    private var m_replaceBoxHint : HintScript;
    private var m_multiplyOperatorHint : HintScript;
    
    private var m_firstMultiplicandValue : String;
    private var m_secondMultiplicandValue : String;
    private var m_firstMultiplier : String;
    private var m_firstTotal : String = "total_a";
    private var m_secondTotal : String = "total_b";
    
    private var m_jobToTotalMapping : Dynamic = {
            ninja : {
                total_a_name : "total ninjas",
                total_a_abbr : "total ninjas",
                total_b_name : "total scouts",
                total_b_abbr : "scouts",
                numeric_unit_group : "groups",
                numeric_unit_unit_a : "ninjas",
                numeric_unit_unit_b : "scouts",

            },
            zombie : {
                total_a_name : "total zombies",
                total_a_abbr : "total zombies",
                total_b_name : "total siege zombies",
                total_b_abbr : "siege zombies",
                numeric_unit_group : "groups",
                numeric_unit_unit_a : "zombies",
                numeric_unit_unit_b : "siege",

            },
            basketball : {
                total_a_name : "total players",
                total_a_abbr : "total players",
                total_b_name : "total coaches",
                total_b_abbr : "coaches",
                numeric_unit_group : "teams",
                numeric_unit_unit_a : "players",
                numeric_unit_unit_b : "coaches",

            },
            fairy : {
                total_a_name : "total fairies",
                total_a_abbr : "total fairies",
                total_b_name : "total light bearers",
                total_b_abbr : "light bearers",
                numeric_unit_group : "groups",
                numeric_unit_unit_a : "fairies",
                numeric_unit_unit_b : "bearers",

            },
            superhero : {
                total_a_name : "total heroes",
                total_a_abbr : "total heroes",
                total_b_name : "total elite heroes",
                total_b_abbr : "elite heroes",
                numeric_unit_group : "teams",
                numeric_unit_unit_a : "heroes",
                numeric_unit_unit_b : "elite",

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
        
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
        super.pushChild(m_switchModelScript);
        
        var prioritySelector : PrioritySelector = new PrioritySelector("barmodelgestures");
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, -1, "AddNewBar", false));
        prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, -1, "AddNewHorizontalLabel", false));
        prioritySelector.pushChild(new AddNewLabelOnSegment(gameEngine, expressionCompiler, assetManager, "AddNewLabelOnSegment", false));
        prioritySelector.pushChild(new MultiplyBarSegments(gameEngine, expressionCompiler, assetManager, 1, "MultiplyBarSegments"));
        prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment", false));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "MultiplyBarSegments"));
        super.pushChild(prioritySelector);
        
        // Used to drag things from the bar model area to the equation area
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
        
        super.pushChild(new DeckCallout(gameEngine, expressionCompiler, assetManager));
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        
        // Creating basic equations
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm", false));
        
        // Validating both parts of the problem modeling process
        m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
        super.pushChild(m_validateBarModel);
        m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
        super.pushChild(m_validateEquation);
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        m_multiplyHint = new CustomFillLogicHint(showMultiply, null, null, null, hideMultiply, null, true);
        m_addTotalHint = new CustomFillLogicHint(showAddTotal, null, null, null, hideAddTotal, null, true);
        m_replaceBoxHint = new CustomFillLogicHint(showReplaceBox, null, null, null, hideReplaceBox, null, true);
        m_multiplyOperatorHint = new CustomFillLogicHint(showMultiplyOperator, null, null, null, hideMultiplyOperator, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            // Check if the user has created the correct number of bars
            if (m_progressControl.getProgressValueEquals("hinting", "use_multiply")) 
            {
                var didMultiply : Bool = false;
                var firstBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                if (firstBarWhole.barSegments.length > 1) 
                {
                    didMultiply = true;
                    m_progressControl.setProgressValue("hinting", "use_multiply_finished");
                }
                
                if (!didMultiply && m_hintController.getCurrentlyShownHint() != m_multiplyHint) 
                {
                    m_hintController.manuallyShowHint(m_multiplyHint);
                }
                else if (didMultiply && m_hintController.getCurrentlyShownHint() == m_multiplyHint) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "add_total")) 
            {
                var addedBracket : Bool = false;
                firstBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(firstBarWhole),barLabels) type: null */ in firstBarWhole.barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                    {
                        addedBracket = true;
                        m_progressControl.setProgressValue("hinting", "add_total_finished");
                        break;
                    }
                }
                
                if (!addedBracket && m_hintController.getCurrentlyShownHint() != m_addTotalHint) 
                {
                    m_hintController.manuallyShowHint(m_addTotalHint);
                }
                else if (addedBracket && m_hintController.getCurrentlyShownHint() == m_addTotalHint) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "replace_box")) 
            {
                // Check if the old multiplicand label is gone and the new one was added
                var oldMultiplicandPresent : Bool = false;
                var newMultiplicandPresent : Bool = false;
                firstBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(firstBarWhole),barLabels) type: null */ in firstBarWhole.barLabels)
                {
                    if (m_firstMultiplicandValue == barLabel.value) 
                    {
                        oldMultiplicandPresent = true;
                    }
                    else if (m_secondMultiplicandValue == barLabel.value) 
                    {
                        newMultiplicandPresent = true;
                    }
                }
                
                if (oldMultiplicandPresent && !newMultiplicandPresent && m_hintController.getCurrentlyShownHint() != m_replaceBoxHint) 
                {
                    m_hintController.manuallyShowHint(m_replaceBoxHint);
                }
                else if (!oldMultiplicandPresent && newMultiplicandPresent && m_hintController.getCurrentlyShownHint() == m_replaceBoxHint) 
                {
                    m_progressControl.setProgressValue("hinting", "replace_box_finished");
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "add_multiply_operator")) 
            {
                // Check if they have added the multiply operator on the correct side
                var addedMultiplication : Bool = false;
                var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                var rootNode : ExpressionNode = rightTermArea.getWidgetRoot().getNode();
                if (rootNode != null && rootNode.isSpecificOperator("*")) 
                {
                    addedMultiplication = true;
                    m_progressControl.setProgressValue("hinting", "add_multiply_operator_finished");
                }
                
                if (!addedMultiplication && m_hintController.getCurrentlyShownHint() != m_multiplyOperatorHint) 
                {
                    m_hintController.manuallyShowHint(m_multiplyOperatorHint);
                }
                else if (addedMultiplication && m_hintController.getCurrentlyShownHint() == m_multiplyOperatorHint) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
        }
        
        return super.visit();
    }
    
    override public function getNumCopilotProblems() : Int
    {
        return 4;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_temporaryTextureControl.dispose();
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        super.disablePrevNextTextButtons();
        
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        
        // Clip out content not belonging to the character selected job
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 0);
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 1);
        
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_textAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        
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
                                id : "common_instructions",
                                visible : true,
                                pageIndex : 0,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 270,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        
        // Get the initial multiplicand and add it as a box in the initial model
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Pull the initial multipler and multiplicand. Only the multiplier should be draggable
                    var multiplicandDocId : String = "part_a_multiplicand_a";
                    var multiplicand : String = TutorialV2Util.getNumberValueFromDocId(multiplicandDocId, m_textAreaWidget);
                    m_firstMultiplicandValue = multiplicand;
                    
                    var multiplierDocId : String = "part_a_multiplier";
                    var multiplier : String = TutorialV2Util.getNumberValueFromDocId(multiplierDocId, m_textAreaWidget);
                    m_firstMultiplier = multiplier;
                    
                    m_gameEngine.addTermToDocument(multiplier, multiplierDocId);
                    setDocumentIdsSelectable([multiplierDocId], true, 0);
                    
                    var levelId : Int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(multiplicand, levelId);
                    assignColorToCardFromSeed(multiplier, levelId);
                    assignColorToCardFromSeed(m_firstTotal, levelId);
                    
                    var dataForCard : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(multiplicand);
                    dataForCard.abbreviatedName = multiplicand + " " + Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_unit_a;
                    dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(multiplier);
                    dataForCard.abbreviatedName = multiplier + " " + Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_group;
                    
                    // Create initial reference model
                    createMultiplicationReferenceModel(multiplicand, multiplier, m_firstTotal);
                    
                    // Change the name of the symbol
                    var expressionDataForTotal : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
                    var symbolDataForTotal : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_firstTotal);
                    symbolDataForTotal.abbreviatedName = expressionDataForTotal.total_a_abbr;
                    symbolDataForTotal.name = expressionDataForTotal.total_a_name;
                    
                    var newBarWhole : BarWhole = new BarWhole(false);
                    newBarWhole.barSegments.push(new BarSegment(parseInt(multiplicand), 1, 0xFFFFFF, null));
                    newBarWhole.barLabels.push(new BarLabel(multiplicand, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                    m_barModelArea.getBarModelData().barWholes.push(newBarWhole);
                    m_barModelArea.redraw(false);
                    
                    m_progressControl.setProgressValue("hinting", "use_multiply");
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "hinting",
                    value : "use_multiply_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    (try cast(getNodeById("RestrictCardsInBarModel"), RestrictCardsInBarModel) catch(e:Dynamic) null).setTermValuesManuallyDisabled([m_firstMultiplier]);
                    
                    getNodeById("MultiplyBarSegments").setIsActive(false);
                    getNodeById("AddNewHorizontalLabel").setIsActive(true);
                    
                    // Once multiply is used, tell them to create the total
                    var totalDocId : String = "part_a_total";
                    m_gameEngine.addTermToDocument(m_firstTotal, totalDocId);
                    setDocumentIdsSelectable([totalDocId], true, 0);
                    
                    m_progressControl.setProgressValue("hinting", "add_total");
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "hinting",
                    value : "add_total_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(true);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "parta_barmodel_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(false);
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Once they get the first part correct, introduce the short sequence where they must add a name on top of
                    // an existing one to replace it
                    var multiplicandDocId : String = "part_a_multiplicand_b";
                    var multiplicand : String = TutorialV2Util.getNumberValueFromDocId(multiplicandDocId, m_textAreaWidget, 1);
                    m_secondMultiplicandValue = multiplicand;
                    m_gameEngine.addTermToDocument(multiplicand, multiplicandDocId);
                    var multiplierDocId : String = "part_a_multiplier";
                    var multiplier : String = TutorialV2Util.getNumberValueFromDocId(multiplierDocId, m_textAreaWidget);
                    createMultiplicationReferenceModel(multiplicand, multiplier, m_secondTotal);
                    setDocumentIdsSelectable([multiplicandDocId], true, 1);
                    
                    var levelId : Int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(multiplicand, levelId);
                    assignColorToCardFromSeed(multiplier, levelId);
                    
                    var dataForCard : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(multiplicand);
                    dataForCard.abbreviatedName = multiplicand + " " + Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_unit_b;
                    
                    // Change the name of the symbol
                    var expressionDataForTotal : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
                    var symbolDataForTotal : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_secondTotal);
                    symbolDataForTotal.abbreviatedName = expressionDataForTotal.total_b_abbr;
                    symbolDataForTotal.name = expressionDataForTotal.total_b_name;
                    
                    m_gameEngine.setDeckAreaContent([], [], false);
                    
                    // Replace the label in the previous model
                    var barWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
                    {
                        if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                        {
                            barLabel.value = m_secondTotal;
                        }
                    }
                    m_barModelArea.redraw(false);
                    
                    getNodeById("AddNewHorizontalLabel").setIsActive(false);
                    var addNewLabelOnSegment : AddNewLabelOnSegment = try cast(getNodeById("AddNewLabelOnSegment"), AddNewLabelOnSegment) catch(e:Dynamic) null;
                    addNewLabelOnSegment.setIsActive(true);
                    
                    m_progressControl.setProgressValue("stage", "partb_barmodel_start");
                    m_progressControl.setProgressValue("hinting", "replace_box");
                    
                    // Need to point to the box with the name, ask user to drop onto that one only
                    var targetSegmentId : String = m_barModelArea.getBarModelData().barWholes[0].barSegments[0].id;
                    addNewLabelOnSegment.setRestrictedElementIdsCanPerformAction([targetSegmentId]);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 1

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setDocumentIdVisible({
                                id : selectedPlayerJob,
                                visible : true,
                                pageIndex : 1,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

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
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "hinting",
                    value : "replace_box_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateBarModel.setIsActive(true);
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "partb_barmodel_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    var barToCard : BarToCard = try cast(getNodeById("BarToCard"), BarToCard) catch(e:Dynamic) null;
                    barToCard.getIdsToIgnore().length = 0;
                    var barLabels : Array<BarLabel> = m_barModelArea.getBarModelData().barWholes[0].barLabels;
                    for (barLabel in barLabels)
                    {
                        if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                        {
                            barToCard.getIdsToIgnore().push(barLabel.id);
                        }
                    }
                    
                    m_validateBarModel.setIsActive(false);
                    
                    // Set up the equation model, include existing parts
                    m_validateEquation.addEquation("1", m_secondTotal + "=" + m_secondMultiplicandValue + "*" + m_firstMultiplier, false, true);
                    m_gameEngine.setTermAreaContent("leftTermArea", m_secondTotal);
                    m_gameEngine.setTermAreaContent("rightTermArea", m_firstMultiplier);
                    m_progressControl.setProgressValue("hinting", "add_multiply_operator");
                    
                    // Make sure initial parts are not removeable
                    m_gameEngine.getCurrentLevel().getLevelRules().termsNotRemovable.push(m_secondTotal, m_firstMultiplier);
                    
                    // Make sure left term area is not interactable
                    (try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null).isInteractable = false;
                    
                    // Auto slide up to solve the equation
                    m_switchModelScript.setIsActive(true);
                    m_switchModelScript.onSwitchModelClicked();
                    
                    getNodeById("barmodelgestures").setIsActive(false);
                    getNodeById("AddTerm").setIsActive(true);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "hinting",
                    value : "add_multiply_operator_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Disable all other parts
                    getNodeById("AddTerm").setIsActive(false);
                    m_validateEquation.setIsActive(true);
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "partb_equation_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_validateEquation.setIsActive(false);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        m_progressControl.setProgressValue("stage", "start");
        m_progressControl.setProgressValue("hinting", null);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
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
        }
    }
    
    private function createMultiplicationReferenceModel(multiplicand : String, multiplier : String, total : String) : Void
    {
        var referenceModel : BarModelData = new BarModelData();
        var newBarWhole : BarWhole = new BarWhole(false);
        var numGroups : Int = parseInt(multiplier);
        for (i in 0...numGroups){
            newBarWhole.barSegments.push(new BarSegment(1, 1, 0xFFFFFFFF, null));
        }
        newBarWhole.barLabels.push(new BarLabel(multiplicand, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        newBarWhole.barLabels.push(new BarLabel(total, 0, numGroups - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        referenceModel.barWholes.push(newBarWhole);
        m_validateBarModel.setReferenceModels([referenceModel]);
    }
    /*
    At this point ignore restricting things
    
    Highlight the number then the total
    
    Need to do step by step, only allow dragging the first number to create multiple parts
    Next only allow adding label on one box
    Finally only allow adding the horizontal label
    
    Multiply operator, dragging next to an existing part
    */
    
    /*
    Logic for hints
    */
    private var m_pickedId : String;
    private function showMultiply() : Void
    {
        // Need to add a callout to the bar model area
        // It needs to be offset such that is actually points to the add unit hit area
        var xOffset : Float = -m_barModelArea.width * 0.5 + 35;
        var yOffset : Float = 25;
        showDialogForUi({
                    id : "barModelArea",
                    text : "Drag number to multiply",
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_UP,
                    width : 120,
                    height : 80,
                    animationPeriod : 1,
                    xOffset : xOffset,
                    yOffset : yOffset,

                });
        
        // Highlight the text for the number
        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("part_a_multiplier", 0xFF9900, 2));
    }
    
    private function hideMultiply() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
        
        m_textAreaWidget.componentManager.removeComponentFromEntity("part_a_multiplier", HighlightComponent.TYPE_ID);
    }
    
    private function showAddTotal() : Void
    {
        var id : String = null;
        var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
        if (barWholes.length > 0) 
        {
            // Get the middle segment, bind the callout
            var firstBarWhole : BarWhole = barWholes[0];
            var numSegments : Int = firstBarWhole.barSegments.length;
            if (numSegments > 0) 
            {
                var middleSegment : Int = numSegments / 2;
                id = firstBarWhole.barSegments[middleSegment].id;
            }
        }
        
        if (id != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : "Show the total of all boxes.",
                        color : CALLOUT_TEXT_DEFAULT_COLOR,
                        direction : Callout.DIRECTION_DOWN,
                        width : 150,
                        height : 70,
                        animationPeriod : 1,
                        xOffset : 0,
                        yOffset : 40,

                    });
            m_pickedId = id;
        }  // Highlight the text for the total  
        
        
        
        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("part_a_total", 0xFF9900, 2));
    }
    
    private function hideAddTotal() : Void
    {
        if (m_pickedId != null) 
        {
            removeDialogForBaseWidget({
                        id : m_pickedId,
                        widgetId : "barModelArea",

                    });
            m_pickedId = null;
        }
        
        m_textAreaWidget.componentManager.removeComponentFromEntity("part_a_total", HighlightComponent.TYPE_ID);
    }
    
    private function showReplaceBox() : Void
    {
        // Add callout on one of the segments
        var id : String = null;
        var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
        if (barWholes.length > 0) 
        {
            var firstBarWhole : BarWhole = barWholes[0];
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(firstBarWhole),barLabels) type: null */ in firstBarWhole.barLabels)
            {
                if (barLabel.bracketStyle == BarLabel.BRACKET_NONE) 
                {
                    id = firstBarWhole.barSegments[barLabel.startSegmentIndex].id;
                    break;
                }
            }
        }
        
        if (id != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : "Change the group to the right number.",
                        color : CALLOUT_TEXT_DEFAULT_COLOR,
                        direction : Callout.DIRECTION_UP,
                        width : 200,
                        height : 70,
                        animationPeriod : 1,
                        xOffset : 0,

                    });
            m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("part_a_multiplicand_b", 0xFF9900, 2));
            m_pickedId = id;
        }
    }
    
    private function hideReplaceBox() : Void
    {
        if (m_pickedId != null) 
        {
            removeDialogForBaseWidget({
                        id : m_pickedId,
                        widgetId : "barModelArea",

                    });
            m_pickedId = null;
            
            m_textAreaWidget.componentManager.removeComponentFromEntity("part_a_multiplicand_b", HighlightComponent.TYPE_ID);
        }
    }
    
    private var m_targetSegmentId : String = null;
    private function showMultiplyOperator() : Void
    {
        // Set dialog on the bar element
        var targetSourceSegment : String = null;
        var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
        if (barWholes.length > 0) 
        {
            var firstBarWhole : BarWhole = barWholes[0];
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(firstBarWhole),barLabels) type: null */ in firstBarWhole.barLabels)
            {
                if (barLabel.bracketStyle == BarLabel.BRACKET_NONE) 
                {
                    targetSourceSegment = firstBarWhole.barSegments[barLabel.startSegmentIndex].id;
                    break;
                }
            }
        }
        
        if (targetSourceSegment != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(targetSourceSegment);
            showDialogForBaseWidget({
                        id : targetSourceSegment,
                        widgetId : "barModelArea",
                        text : "Drag number here...",
                        color : CALLOUT_TEXT_DEFAULT_COLOR,
                        direction : Callout.DIRECTION_DOWN,
                        width : 200,
                        height : 60,
                        animationPeriod : 1,
                        xOffset : 0,

                    });
            m_targetSegmentId = targetSourceSegment;
            
            // Set dialog on the multiplicative term as the target
            var multiplyTermText : String = "...to here to multiply!";
            var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
            var multiplyTermId : String = rightTermArea.getWidgetRoot().getNode().id + "";
            showDialogForBaseWidget({
                        id : multiplyTermId,
                        widgetId : "rightTermArea",
                        text : multiplyTermText,
                        color : CALLOUT_TEXT_DEFAULT_COLOR,
                        direction : Callout.DIRECTION_UP,
                        width : 200,
                        height : 70,
                        xOffset : 0,
                        animationPeriod : 1,

                    });
            m_pickedId = multiplyTermId;
        }
    }
    
    private function hideMultiplyOperator() : Void
    {
        removeDialogForBaseWidget({
                    id : m_targetSegmentId,
                    widgetId : "barModelArea",

                });
        removeDialogForBaseWidget({
                    id : m_pickedId,
                    widgetId : "rightTermArea",

                });
    }
}
