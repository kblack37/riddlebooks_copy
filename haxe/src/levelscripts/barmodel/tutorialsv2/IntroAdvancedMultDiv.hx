package levelscripts.barmodel.tutorialsv2;


import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.time.Time;

import feathers.controls.Callout;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.level.LevelRules;
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
import wordproblem.scripts.barmodel.AddNewBarComparison;
import wordproblem.scripts.barmodel.AddNewLabelOnSegment;
import wordproblem.scripts.barmodel.AddNewUnitBar;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.HoldToCopy;
import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckCallout;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.drag.WidgetDragSystem;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.expression.PressToChangeOperator;
import wordproblem.scripts.expression.RemoveTerm;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.TextToCard;

/**
 * Intended to teach the player to solve more advanced multiply/divide problems where the
 * hold to copy mechanic will finally be of some use.
 */
class IntroAdvancedMultDiv extends BaseCustomLevelScript
{
    private var m_time : Time;
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    private var m_validateBarModel : ValidateBarModelArea;
    private var m_validateEquation : ModelSpecificEquation;
    
    private var m_textAreaWidget : TextAreaWidget;
    private var m_barModelArea : BarModelAreaWidget;
    private var m_hintController : HelpController;
    
    private var m_multiplierValue : Int;
    private var m_unknownValue : String = "unknown";
    private var m_differenceValue : String;
    
    private var m_multiplierDocId : String = "multiplier";
    private var m_unknownDocId : String = "unknown";
    private var m_differenceDocId : String = "difference";
    
    private var m_addGroupHint : HintScript;
    private var m_copyPartHint : HintScript;
    private var m_addCopyToNewLineHint : HintScript;
    private var m_addLabelHint : HintScript;
    private var m_addDifferenceHint : HintScript;
    private var m_multiplyEquationHint : HintScript;
    private var m_subtractEquationHint : HintScript;
    
    private var m_jobToTotalMapping : Dynamic = {
            ninja : {
                unknown_name : "horses snuck past",
                unknown_abbr : "horses",
                type_a_object : "foot soldiers",
                type_b_object : "horse soldiers",
                hint_difference : "soldiers",
                numeric_unit_diff : "soldiers",

            },
            zombie : {
                unknown_name : "zombies type b",
                unknown_abbr : "type b",
                type_a_object : "type a zombies",
                type_b_object : "type b zombies",
                hint_difference : "zombies",
                numeric_unit_diff : "zombies",

            },
            basketball : {
                unknown_name : "other free throws",
                unknown_abbr : "other",
                type_a_object : "character's team free throws",
                type_b_object : "opponent free throws",
                hint_difference : "free throws",
                numeric_unit_diff : "free throws",

            },
            fairy : {
                unknown_name : "water fairies",
                unknown_abbr : "water",
                type_a_object : "air fairies",
                type_b_object : "water fairies",
                hint_difference : "fairies",
                numeric_unit_diff : "fairies",

            },
            superhero : {
                unknown_name : "mutants on land",
                unknown_abbr : "land",
                type_a_object : "mutants in water",
                type_b_object : "mutants on land",
                hint_difference : "mutants",
                numeric_unit_diff : "mutants",

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
        
        m_time = new Time();
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
        super.pushChild(m_switchModelScript);
        
        var orderedGestures : PrioritySelector = new PrioritySelector("BarModelDragGestures");
        super.pushChild(orderedGestures);
        orderedGestures.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 2, "AddNewBar", false));
        orderedGestures.pushChild(new AddNewUnitBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewUnitBar"));
        orderedGestures.pushChild(new AddNewLabelOnSegment(gameEngine, expressionCompiler, assetManager, "AddNewLabelOnSegment", false));
        orderedGestures.pushChild(new AddNewBarComparison(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison", false));
        orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewUnitBar"));
        orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison"));
        
        super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
        
        var holdToCopy : HoldToCopy = new HoldToCopy(
        gameEngine, 
        expressionCompiler, 
        assetManager, 
        m_time, 
        assetManager.getBitmapData("glow_yellow"), 
        "HoldToCopy");
        super.pushChild(holdToCopy);
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        // Dragging things from bar model to equation
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        
        super.pushChild(new DeckCallout(gameEngine, expressionCompiler, assetManager));
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        
        // Adding parts to the term area
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm"));
        super.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager, "PressToChangeOperator", false));
        super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm", false));
        
        // Validating both parts of the problem modeling process
        m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
        super.pushChild(m_validateBarModel);
        m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
        super.pushChild(m_validateEquation);
        
        m_addGroupHint = new CustomFillLogicHint(showAddGroups, null, null, null, hideAddGroups, null, false);
        m_copyPartHint = new CustomFillLogicHint(showUseCopy, null, null, null, hideUseCopy, null, false);
        m_addCopyToNewLineHint = new CustomFillLogicHint(showAddCopyToNewLine, null, null, null, hideAddCopyToNewLine, null, false);
        m_addLabelHint = new CustomFillLogicHint(showAddLabel, null, null, null, hideAddLabel, null, false);
        m_addDifferenceHint = new CustomFillLogicHint(showAddDifference, null, null, null, hideAddDifference, null, false);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            m_time.update();
            if (m_progressControl.getProgressValueEquals("stage", "add_groups")) 
            {
                var addedGroups : Bool = false;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    addedGroups = m_barModelArea.getBarModelData().barWholes[0].barSegments.length == m_multiplierValue;
                }
                
                if (!addedGroups && m_hintController.getCurrentlyShownHint() == null) 
                {
                    m_hintController.manuallyShowHint(m_addGroupHint);
                }
                else if (addedGroups) 
                {
                    if (m_hintController.getCurrentlyShownHint() != null) 
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    m_progressControl.setProgressValue("stage", "add_copy");
                }
            }
            else if (m_progressControl.getProgressValueEquals("stage", "add_copy")) 
            {
                var addedCopy : Bool = false;
                if (m_barModelArea.getBarModelData().barWholes.length == 2) 
                {
                    addedCopy = true;
                }  // Check if the user is in the middle of dragging around the copy of a segment  
                
                
                
                var widgetDragSystem : WidgetDragSystem = try cast(this.getNodeById("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null;
                var draggedWidget : BaseTermWidget = widgetDragSystem.getWidgetSelected();
                var isDraggingCopy : Bool = draggedWidget != null && !(Std.is(draggedWidget, SymbolTermWidget));
                
                if (!addedCopy && !isDraggingCopy && m_hintController.getCurrentlyShownHint() != m_copyPartHint) 
                {
                    m_hintController.manuallyShowHint(m_copyPartHint);
                }
                else if (!addedCopy && isDraggingCopy && m_hintController.getCurrentlyShownHint() != m_addCopyToNewLineHint) 
                {
                    m_hintController.manuallyShowHint(m_addCopyToNewLineHint);
                }
                else if (addedCopy) 
                {
                    if (m_hintController.getCurrentlyShownHint() != null) 
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    m_progressControl.setProgressValue("stage", "add_label");
                }
            }
            else if (m_progressControl.getProgressValueEquals("stage", "add_label")) 
            {
                var addedLabel : Bool = false;
                if (m_barModelArea.getBarModelData().barWholes.length == 2) 
                {
                    var barWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[1];
                    addedLabel = barWhole.barLabels.length > 0 && barWhole.barLabels[0].value == m_unknownValue;
                }
                
                if (!addedLabel && m_hintController.getCurrentlyShownHint() != m_addLabelHint) 
                {
                    m_hintController.manuallyShowHint(m_addLabelHint);
                }
                else if (addedLabel) 
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
                var addedDifference : Bool = false;
                if (m_barModelArea.getBarModelData().barWholes.length >= 2) 
                {
                    for (barWhole/* AS3HX WARNING could not determine type for var: barWhole exp: EField(ECall(EField(EIdent(m_barModelArea),getBarModelData),[]),barWholes) type: null */ in m_barModelArea.getBarModelData().barWholes)
                    {
                        if (barWhole.barComparison != null) 
                        {
                            addedDifference = true;
                            break;
                        }
                    }
                }
                
                if (!addedDifference && m_hintController.getCurrentlyShownHint() != m_addDifferenceHint) 
                {
                    m_hintController.manuallyShowHint(m_addDifferenceHint);
                }
                else if (addedDifference) 
                {
                    if (m_hintController.getCurrentlyShownHint() != null) 
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    m_progressControl.setProgressValue("stage", "bar_model_constructed");
                    m_validateBarModel.setIsActive(true);
                }
            }
            else if (m_progressControl.getProgressValueEquals("stage", "multiply_equation")) 
            {
                var multiplyEquation : Bool = false;
                var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                var expressionRoot : ExpressionNode = rightTermArea.getTree().getRoot();
                if (expressionRoot != null && expressionRoot.isSpecificOperator("*")) 
                {
                    multiplyEquation = expressionRoot.left.data == Std.string(m_multiplierValue) ||
                            expressionRoot.right.data == Std.string(m_multiplierValue);
                }
                
                if (!multiplyEquation && m_hintController.getCurrentlyShownHint() == null) 
                {
                    m_hintController.manuallyShowHint(m_multiplyEquationHint);
                }
                else if (multiplyEquation) 
                {
                    if (m_hintController.getCurrentlyShownHint() != null) 
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    m_progressControl.setProgressValue("stage", "subtract_equation");
                }
            }
            else if (m_progressControl.getProgressValueEquals("stage", "subtract_equation")) 
            {
                var subtractedEquation : Bool = false;
                rightTermArea = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                expressionRoot = rightTermArea.getTree().getRoot();
                if (expressionRoot != null && expressionRoot.isSpecificOperator("-")) 
                {
                    subtractedEquation = expressionRoot.right.data == m_differenceValue;
                }
                
                if (!subtractedEquation && m_hintController.getCurrentlyShownHint() == null) 
                {
                    m_hintController.manuallyShowHint(m_subtractEquationHint);
                }
                else if (subtractedEquation) 
                {
                    if (m_hintController.getCurrentlyShownHint() != null) 
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    getNodeById("PressToChangeOperator").setIsActive(false);
                    getNodeById("AddTerm").setIsActive(false);
                    m_validateEquation.setIsActive(true);
                    
                    m_progressControl.setProgressValue("stage", "equation_constructed");
                }
            }
        }
        
        return super.visit();
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "bar_model_constructed")) 
            {
                m_progressControl.setProgressValue("stage", "bar_model_finished");
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "equation_constructed")) 
            {
                m_progressControl.setProgressValue("stage", "equation_finished");
            }
        }
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        super.disablePrevNextTextButtons();
        
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        
        m_barModelArea = try cast(m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget)[0], BarModelAreaWidget) catch(e:Dynamic) null;
        m_textAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        
        // Clip out content not belonging to the character selected job
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 1);
        var jobData : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
        
        var selectedGender : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("gender"), String) catch(e:Dynamic) null;
        m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 1);
        
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        var slideUpPositionY : Float = m_gameEngine.getUiEntity("deckAndTermContainer").y;
        m_switchModelScript.setContainerOriginalY(slideUpPositionY);
        
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 1.0

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
                    greyOutAndDisableButton("resetButton", true);
                    greyOutAndDisableButton("undoButton", true);
                    setDocumentIdVisible({
                                id : selectedPlayerJob,
                                visible : true,
                                pageIndex : 1,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 1.0

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
                    m_progressControl.setProgressValue("stage", "add_groups");
                    
                    var multiplierValue : String = TutorialV2Util.getNumberValueFromDocId(m_multiplierDocId, m_textAreaWidget, 1);
                    m_gameEngine.addTermToDocument(multiplierValue, m_multiplierDocId);
                    m_multiplierValue = parseInt(multiplierValue);
                    
                    var differenceValue : String = TutorialV2Util.getNumberValueFromDocId(m_differenceDocId, m_textAreaWidget, 1);
                    m_gameEngine.addTermToDocument(differenceValue, m_differenceDocId);
                    m_differenceValue = differenceValue;
                    
                    m_gameEngine.addTermToDocument(m_unknownValue, m_unknownDocId);
                    
                    var levelId : Int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(multiplierValue, levelId);
                    assignColorToCardFromSeed(differenceValue, levelId);
                    assignColorToCardFromSeed(m_unknownValue, levelId);
                    
                    var dataForCard : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(differenceValue);
                    dataForCard.abbreviatedName = differenceValue + " " + Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_diff;
                    
                    var referenceModel : BarModelData = new BarModelData();
                    var barWhole : BarWhole = new BarWhole(false, "larger");
                    var i : Int = 0;
                    for (i in 0...m_multiplierValue){
                        barWhole.barSegments.push(new BarSegment(1, 1, 0xFFFFFFFF, null));
                    }
                    referenceModel.barWholes.push(barWhole);
                    
                    barWhole = new BarWhole(false);
                    barWhole.barSegments.push(new BarSegment(1, 1, 0xFFFFFFFF, null));
                    barWhole.barLabels.push(new BarLabel(m_unknownValue, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                    barWhole.barComparison = new BarComparison(m_differenceValue, "larger", m_multiplierValue - 1);
                    referenceModel.barWholes.push(barWhole);
                    m_validateBarModel.setReferenceModels([referenceModel]);
                    
                    setDocumentIdsSelectable([m_multiplierDocId], true, 1);
                    
                    // Equation hints can only be shown after the right values have been read.
                    var multiplyHintText : String = "Multiply to get the " + jobData.type_a_object + "!";
                    m_multiplyEquationHint = new CustomFillLogicHint(
                            showEquationHint, [multiplyHintText, Std.string(m_multiplierValue)], 
                            null, null, hideEquationHint, [Std.string(m_multiplierValue)], false);
                    var subtractHintText : String = "Subtract the difference to get the " + jobData.type_b_object + "!";
                    m_subtractEquationHint = new CustomFillLogicHint(
                            showEquationHint, [subtractHintText, m_differenceValue], 
                            null, null, hideEquationHint, [m_differenceValue], false);
                    
                    // Change the name of the unknown symbols based on the occupation selected by the player
                    var expressionDataForUnknown : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
                    var symbolDataForUnknown : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_unknownValue);
                    symbolDataForUnknown.abbreviatedName = expressionDataForUnknown.unknown_abbr;
                    symbolDataForUnknown.name = expressionDataForUnknown.unknown_name;
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "add_copy",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Disable the add unit and the multiplier from being selectable
                    getNodeById("AddNewUnitBar").setIsActive(false);
                    getNodeById("AddNewBar").setIsActive(true);
                    (try cast(getNodeById("RestrictCardsInBarModel"), RestrictCardsInBarModel) catch(e:Dynamic) null).setTermValuesManuallyDisabled(
                            [Std.string(m_multiplierValue)]);
                    // The restrict script incorrectly sets things to selectable
                    setDocumentIdsSelectable([m_differenceDocId, m_unknownDocId], false, 1);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "add_label",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    var targetBarSegment : BarSegment = m_barModelArea.getBarModelData().barWholes[1].barSegments[0];
                    var addNewLabelOnSegment : AddNewLabelOnSegment = try cast(getNodeById("AddNewLabelOnSegment"), AddNewLabelOnSegment) catch(e:Dynamic) null;
                    addNewLabelOnSegment.setIsActive(true);
                    addNewLabelOnSegment.setRestrictedElementIdsCanPerformAction([targetBarSegment.id]);
                    setDocumentIdsSelectable([m_unknownDocId], true, 1);
                    setDocumentIdsSelectable([m_differenceDocId], false, 1);
                    getNodeById("HoldToCopy").setIsActive(false);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "add_difference",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setDocumentIdsSelectable([m_differenceDocId], true, 1);
                    getNodeById("AddNewLabelOnSegment").setIsActive(false);
                    getNodeById("AddNewBarComparison").setIsActive(true);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "bar_model_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Disable all bar model actions
                    getNodeById("BarModelDragGestures").setIsActive(false);
                    m_validateBarModel.setIsActive(false);
                    m_switchModelScript.setIsActive(true);
                    
                    m_gameEngine.setTermAreaContent("leftTermArea", m_unknownValue);
                    m_gameEngine.setTermAreaContent("rightTermArea", m_unknownValue);
                    var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                    leftTermArea.isInteractable = false;
                    
                    // The equation we want them to build should create a multiply term representing the first row and then subtract the difference
                    var referenceEquation : String = m_unknownValue + "=" + m_differenceValue + "/(" + m_multiplierValue + "-1)";
                    m_validateEquation.addEquation("1", referenceEquation, false, true);
                    m_progressControl.setProgressValue("stage", "equation_started");
                    getNodeById("RestrictCardsInBarModel").setIsActive(false);
                    
                    m_gameEngine.getCurrentLevel().getLevelRules().allowAddition = false;
                    m_gameEngine.getCurrentLevel().getLevelRules().allowSubtract = false;
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 2

                }));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setDocumentIdVisible({
                                id : "equation_instructions",
                                visible : true,
                                pageIndex : 2,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "multiply_equation",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
                    deckArea.toggleSymbolEnabled(true, Std.string(m_multiplierValue));
                    deckArea.toggleSymbolEnabled(false, m_unknownValue);
                    deckArea.toggleSymbolEnabled(false, m_differenceValue);
                    
                    // Ignore the unknown box and the difference
                    var barToCard : BarToCard = try cast(getNodeById("BarToCard"), BarToCard) catch(e:Dynamic) null;
                    var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[1];
                    barToCard.getIdsToIgnore().push(targetBarWhole.barSegments[0].id, targetBarWhole.barComparison.id);
                    
                    getNodeById("AddTerm").setIsActive(true);
                    m_gameEngine.getCurrentLevel().getLevelRules().allowMultiply = true;
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "subtract_equation",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
                    deckArea.toggleSymbolEnabled(false, Std.string(m_multiplierValue));
                    deckArea.toggleSymbolEnabled(true, m_differenceValue);
                    
                    var levelRules : LevelRules = m_gameEngine.getCurrentLevel().getLevelRules();
                    getNodeById("PressToChangeOperator").setIsActive(true);
                    levelRules.allowAddition = true;
                    levelRules.allowSubtract = true;
                    levelRules.allowMultiply = false;
                    
                    levelRules.termsNotRemovable.push(Std.string(m_multiplierValue), m_unknownValue);
                    getNodeById("RemoveTerm").setIsActive(true);
                    
                    // Ignore the unknown box and the difference
                    var barToCard : BarToCard = try cast(getNodeById("BarToCard"), BarToCard) catch(e:Dynamic) null;
                    var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[1];
                    barToCard.getIdsToIgnore().length = 0;
                    barToCard.getIdsToIgnore().push(targetBarWhole.barSegments[0].id);
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "equation_finished",

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
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
            
            if (m_progressControl.getProgressValueEquals("stage", "equation_started")) 
            {
                m_progressControl.setProgressValue("stage", "multiply_equation");
            }
        }
    }
    
    private function showAddGroups() : Void
    {
        // Need to add a callout to the bar model area
        // It needs to be offset such that is actually points to the add unit hit area
        var xOffset : Float = -m_barModelArea.width * 0.5 + 35;
        var yOffset : Float = 25;
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        var jobData : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
        showDialogForUi({
                    id : "barModelArea",
                    text : "First row should be the " + jobData.type_a_object + "!",
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_UP,
                    width : 120,
                    height : 150,
                    animationPeriod : 1,
                    xOffset : xOffset,
                    yOffset : yOffset,

                });
        
        // Highlight the text for the number
        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("multiplier", 0xFF9900, 2));
    }
    
    private function hideAddGroups() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
        
        m_textAreaWidget.componentManager.removeComponentFromEntity("multiplier", HighlightComponent.TYPE_ID);
    }
    
    private var m_firstSegmentId : String = null;
    private function showUseCopy() : Void
    {
        // Highlight the first bar
        var firstSegmentInBarId : String = m_barModelArea.getBarWholeViews()[0].segmentViews[0].data.id;
        m_barModelArea.addOrRefreshViewFromId(firstSegmentInBarId);
        showDialogForBaseWidget({
                    id : firstSegmentInBarId,
                    widgetId : "barModelArea",
                    text : "Press and hold to copy",
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_UP,
                    width : 140,
                    height : 70,
                    animationPeriod : 1,

                });
        m_firstSegmentId = firstSegmentInBarId;
    }
    
    private function hideUseCopy() : Void
    {
        removeDialogForBaseWidget({
                    id : m_firstSegmentId,
                    widgetId : "barModelArea",

                });
    }
    
    private function showAddCopyToNewLine() : Void
    {
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        var jobData : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
        
        // Tell player to add part near the bottom
        showDialogForUi({
                    id : "barModelArea",
                    text : "Add group for the " + jobData.type_b_object + "!",
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_RIGHT,
                    width : 130,
                    height : 100,
                    animationPeriod : 1,
                    xOffset : -300,
                    yOffset : 0,

                });
    }
    
    private function hideAddCopyToNewLine() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
    private function showAddLabel() : Void
    {
        var firstSegmentInBarId : String = m_barModelArea.getBarWholeViews()[1].segmentViews[0].data.id;
        m_barModelArea.addOrRefreshViewFromId(firstSegmentInBarId);
        showDialogForBaseWidget({
                    id : firstSegmentInBarId,
                    widgetId : "barModelArea",
                    text : "How much is one group?",
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_DOWN,
                    width : 160,
                    height : 60,
                    animationPeriod : 1,

                });
        m_firstSegmentId = firstSegmentInBarId;
        
        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("unknown", 0xFF9900, 2));
    }
    
    private function hideAddLabel() : Void
    {
        removeDialogForBaseWidget({
                    id : m_firstSegmentId,
                    widgetId : "barModelArea",

                });
        
        m_textAreaWidget.componentManager.removeComponentFromEntity("unknown", HighlightComponent.TYPE_ID);
    }
    
    private var m_segmentIdToAddCalloutTo : String;
    private function showAddDifference() : Void
    {
        // Attach a callout to the smaller bar and offset it far to the right so it looks like it is pointing
        // to the space in the comparison.
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        var barWholes : Array<BarWhole> = barModelArea.getBarModelData().barWholes;
        
        var smallerIndex : Int = 0;
        var largerIndex : Int = 1;
        if (barWholes[0].getValue() > barWholes[1].getValue()) 
        {
            smallerIndex = 1;
            largerIndex = 0;
        }
        
        var boundsLargerBar : Rectangle = barModelArea.getBarWholeViews()[largerIndex].getBounds(barModelArea);
        var boundsSmallerBar : Rectangle = barModelArea.getBarWholeViews()[smallerIndex].getBounds(barModelArea);
        
        // Callout normally goes in the middle of the bar segment, shift it so it is in the middle of the empty
        // space instead.
        var xOffset : Float = (boundsLargerBar.width - boundsSmallerBar.width) * 0.5 + boundsSmallerBar.width * 0.5;
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        var jobData : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
        var barIdForCallout : String = barWholes[smallerIndex].barSegments[0].id;
        barModelArea.addOrRefreshViewFromId(barIdForCallout);
        showDialogForBaseWidget({
                    id : barIdForCallout,
                    widgetId : "barModelArea",
                    text : "Show difference in " + jobData.hint_difference + "!",
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_DOWN,
                    width : 270,
                    height : 60,
                    animationPeriod : 1,
                    xOffset : xOffset,
                    yOffset : 0,

                });
        m_segmentIdToAddCalloutTo = barIdForCallout;
        
        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("difference", 0xFF9900, 2));
    }
    
    private function hideAddDifference() : Void
    {
        removeDialogForBaseWidget({
                    id : m_segmentIdToAddCalloutTo,
                    widgetId : "barModelArea",

                });
        
        m_textAreaWidget.componentManager.removeComponentFromEntity("difference", HighlightComponent.TYPE_ID);
    }
    
    private function showEquationHint(text : String, deckValue : String) : Void
    {
        // Attach the callout to the term area
        showDialogForUi({
                    id : "rightTermArea",
                    text : text,
                    color : CALLOUT_TEXT_DEFAULT_COLOR,
                    direction : Callout.DIRECTION_UP,
                    width : 200,
                    height : 100,
                    animationPeriod : 1,
                    xOffset : 0,
                    yOffset : 0,

                });
        
        var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        deckArea.componentManager.addComponentToEntity(new HighlightComponent(deckValue, 0xFF9900, 1));
    }
    
    private function hideEquationHint(deckValue : String) : Void
    {
        removeDialogForUi({
                    id : "rightTermArea"

                });
        
        var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        deckArea.componentManager.removeComponentFromEntity(deckValue, HighlightComponent.TYPE_ID);
    }
}
