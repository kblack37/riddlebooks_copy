package levelscripts.barmodel.tutorialsv2;


import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.expression.tree.ExpressionTree;
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
import wordproblem.scripts.barmodel.AddNewVerticalLabel;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.CardOnSegmentRadialOptions;
import wordproblem.scripts.barmodel.ResetBarModelArea;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SplitBarSegment;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.UndoBarModelArea;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckCallout;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.expression.RemoveTerm;
import wordproblem.scripts.expression.ResetTermArea;
import wordproblem.scripts.expression.UndoTermArea;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.TextToCard;

class IntroDivision extends BaseCustomLevelScript
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
    private var m_termAreaWidgetBuffer : Array<DisplayObject>;
    
    private var m_splitHint : HintScript;
    private var m_addNameToBoxHint : HintScript;
    private var m_divideEquationHint : HintScript;
    private var m_undoMistakeHint : HintScript;
    
    private var m_divisorDocId : String = "part_a_divisor";
    
    private var m_divisorAGroups : Int = 0;
    private var m_dividendAValue : String = "";
    private var m_totalA : String = "total_a";
    private var m_isRadialMenuOpen : Bool = false;
    
    // This problem deals with solving two diagrams.
    // The name of the 'total' in each diagram differs depending on the job
    // Create mapping from job to what the name of the total should be
    private var m_jobToTotalMapping : Dynamic = {
            ninja : {
                unit_a_name : "powder per bomb",
                unit_a_abbr : "powder",
                hint_group : "powder per bomb",
                hint_divide : "smokebombs",
                numeric_unit_group : "smokebombs",
                numeric_unit_total : "scoops",

            },
            zombie : {
                unit_a_name : "doses per zombie",
                unit_a_abbr : "doses",
                hint_group : "doses per zombie",
                hint_divide : "wild zombies",
                numeric_unit_group : "zombies",
                numeric_unit_total : "doses",

            },
            basketball : {
                unit_a_name : "shots per player",
                unit_a_abbr : "shots",
                hint_group : "shots per player",
                hint_divide : "players",
                numeric_unit_group : "players",
                numeric_unit_total : "shots",

            },
            fairy : {
                unit_a_name : "decades per life",
                unit_a_abbr : "decades",
                hint_group : "decades per life",
                hint_divide : "lifespans",
                numeric_unit_group : "lifespans",
                numeric_unit_total : "decades",

            },
            superhero : {
                unit_a_name : "mutants per tank",
                unit_a_abbr : "mutants",
                hint_group : "mutants per tank",
                hint_divide : "tanks",
                numeric_unit_group : "tanks",
                numeric_unit_total : "mutants",

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
        
        var orderedGestures : PrioritySelector = new PrioritySelector("BarModelDragGestures");
        super.pushChild(orderedGestures);
        orderedGestures.pushChild(new CardOnSegmentRadialOptions(gameEngine, expressionCompiler, assetManager, "CardOnSegmentRadialOptions"));
        orderedGestures.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, -1, "AddNewHorizontalLabel", false));
        orderedGestures.pushChild(new AddNewVerticalLabel(gameEngine, expressionCompiler, assetManager, -1, "AddNewVerticalLabel", false));
        orderedGestures.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 2, "AddNewBar", false));
        orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel"));
        orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewVerticalLabel"));
        orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        
        // Undo and reset bar model
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea", false));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea", false));
        
        super.pushChild(new DeckCallout(gameEngine, expressionCompiler, assetManager));
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        
        // Creating basic equations
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm", false));
        super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm", false));
        super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
        super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
        
        // Used to drag things from the bar model area to the equation area
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        
        // Validating both parts of the problem modeling process
        m_validateBarModel = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea", false);
        super.pushChild(m_validateBarModel);
        m_validateEquation = new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false);
        super.pushChild(m_validateEquation);
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        m_divideEquationHint = new CustomFillLogicHint(showDivideEquation, null, null, null, hideDivideEquation, null, false);
        m_undoMistakeHint = new CustomFillLogicHint(showUndoMistake, null, null, null, hideUndoMistake, null, false);
        
        m_termAreaWidgetBuffer = new Array<DisplayObject>();
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            if (m_progressControl.getProgressValueEquals("hinting", "split_bar")) 
            {
                var mistakeMade : Bool = getBarModelMistakeDetected();
                if (mistakeMade && m_hintController.getCurrentlyShownHint() != m_undoMistakeHint) 
                {
                    m_hintController.manuallyShowHint(m_undoMistakeHint);
                }
                else if (!mistakeMade) 
                {
                    if (m_hintController.getCurrentlyShownHint() == m_undoMistakeHint) 
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    var correctNumberOfGroups : Bool = validateCorrectNumberGroups();
                    if (!correctNumberOfGroups && !m_isRadialMenuOpen && m_hintController.getCurrentlyShownHint() != m_splitHint) 
                    {
                        m_hintController.manuallyShowHint(m_splitHint);
                        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent(m_divisorDocId, 0xFF9900, 1));
                    }
                    else if ((correctNumberOfGroups || m_isRadialMenuOpen) && m_hintController.getCurrentlyShownHint() == m_splitHint) 
                                    {
                                        m_hintController.manuallyRemoveAllHints();
                                        m_textAreaWidget.componentManager.removeComponentFromEntity(m_divisorDocId, HighlightComponent.TYPE_ID);
                                    }(try cast((try cast(getNodeById("CardOnSegmentRadialOptions"), CardOnSegmentRadialOptions) catch(e:Dynamic) null).getGestureScript("SplitBarSegment"), SplitBarSegment) catch(e:Dynamic) null).setIsActive(!correctNumberOfGroups);
                    
                    if (correctNumberOfGroups) 
                    {
                        m_progressControl.setProgressValue("hinting", "add_unknown");
                        m_gameEngine.addTermToDocument(m_totalA, "part_a_group_value");
                        setDocumentIdsSelectable(["part_a_group_value"], true, 0);
                        
                        m_textAreaWidget.componentManager.addComponentToEntity(new HighlightComponent("part_a_group_value", 0xFF9900, 2));
                    }
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "add_unknown")) 
            {
                // Search if the unknown has been added
                correctNumberOfGroups = validateCorrectNumberGroups();
                
                var addedUnknown : Bool = false;
                var barWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_NONE && barLabel.value == m_totalA) 
                    {
                        addedUnknown = true;
                        break;
                    }
                }
                
                m_validateBarModel.setIsActive(correctNumberOfGroups && addedUnknown);
                
                if (!addedUnknown && m_hintController.getCurrentlyShownHint() != m_addNameToBoxHint) 
                {
                    m_hintController.manuallyShowHint(m_addNameToBoxHint);
                }
                // Switch back to the split bar mode
                else if (addedUnknown && m_hintController.getCurrentlyShownHint() == m_addNameToBoxHint) 
                {
                    m_textAreaWidget.componentManager.removeComponentFromEntity("part_a_group_value", HighlightComponent.TYPE_ID);
                    m_hintController.manuallyRemoveAllHints();
                }
                
                
                
                if (!correctNumberOfGroups) 
                {
                    m_progressControl.setProgressValue("hinting", "split_bar");
                }
            }
            else if (m_progressControl.getProgressValueEquals("hinting", "divide_equation")) 
            {
                // Check if the user has added the division operator in the equation
                var didDivide : Bool = false;
                as3hx.Compat.setArrayLength(m_termAreaWidgetBuffer, 0);
                m_gameEngine.getUiEntitiesByClass(TermAreaWidget, m_termAreaWidgetBuffer);
                for (termAreaWidget in m_termAreaWidgetBuffer)
                {
                    var tree : ExpressionTree = termAreaWidget.getTree();
                    var expressionRoot : ExpressionNode = tree.getRoot();
                    if (expressionRoot != null && expressionRoot.data == tree.getVectorSpace().getDivisionOperator()) 
                    {
                        didDivide = true;
                        break;
                    }
                }
                
                if (!didDivide && m_hintController.getCurrentlyShownHint() != m_divideEquationHint) 
                {
                    m_hintController.manuallyShowHint(m_divideEquationHint);
                }
                else if (didDivide && m_hintController.getCurrentlyShownHint() == m_divideEquationHint) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
                
                if (m_validateEquation.getIsActive() != didDivide) 
                {
                    m_validateEquation.setIsActive(didDivide);
                }
            }
            
            function validateCorrectNumberGroups() : Bool
            {
                var correctNumberOfGroups : Bool = false;
                
                // Check if the user has split the bar into the appropriate number of segments
                var barWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                var numSegmentsGroups : Int = barWhole.barSegments.length;
                correctNumberOfGroups = numSegmentsGroups == m_divisorAGroups;
                
                return correctNumberOfGroups;
            }  // If split correctly, tell them to drag the unknown over one of the boxes to name it    // If they did not split the part into the correct number of groups, tell them to drag over the box    // In the first section the hint flow should be:  ;
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
        m_gameEngine.removeEventListener(GameEvent.OPEN_RADIAL_OPTIONS, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.CLOSE_RADIAL_OPTIONS, bufferEvent);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.OPEN_RADIAL_OPTIONS, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.CLOSE_RADIAL_OPTIONS, bufferEvent);
        
        // Clip out content not belonging to the character selected job
        var selectedPlayerJob : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("job"), String) catch(e:Dynamic) null;
        TutorialV2Util.clipElementsNotBelongingToJob(selectedPlayerJob, m_textReplacementControl, 0);
        var jobData : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
        m_splitHint = new CustomFillLogicHint(showCalloutOnSegment, 
                ["Drag on top to divide by the number of " + jobData.hint_divide + "!", 90], 
                null, null, hideCalloutOnSegment, null, false);
        m_addNameToBoxHint = new CustomFillLogicHint(showCalloutOnSegment, 
                ["Show the " + jobData.hint_group + "!", 60], 
                null, null, hideCalloutOnSegment, null, false);
        
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_textAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        
        var selectedGender : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("gender"), String) catch(e:Dynamic) null;
        m_textReplacementControl.replaceContentForClassesAtPageIndex(m_textAreaWidget, "gender_select", selectedGender, 0);
        
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
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setDocumentIdVisible({
                                id : "common_instructions",
                                visible : true,
                                pageIndex : 0,

                            });
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Immediately put the dividend in the bar model, the player learns how to split
                    var dividendDocId : String = "part_a_dividend";
                    var dividendValue : String = TutorialV2Util.getNumberValueFromDocId(dividendDocId, m_textAreaWidget);
                    m_dividendAValue = dividendValue;
                    
                    var divisorValue : String = TutorialV2Util.getNumberValueFromDocId(m_divisorDocId, m_textAreaWidget);
                    m_gameEngine.addTermToDocument(divisorValue, m_divisorDocId);
                    m_divisorAGroups = parseInt(divisorValue);
                    
                    var levelId : Int = m_gameEngine.getCurrentLevel().getId();
                    assignColorToCardFromSeed(dividendValue, levelId);
                    assignColorToCardFromSeed(divisorValue, levelId);
                    assignColorToCardFromSeed(m_totalA, levelId);
                    
                    var dataForCard : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(dividendValue);
                    dataForCard.abbreviatedName = dividendValue + " " + Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_total;
                    dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(divisorValue);
                    dataForCard.abbreviatedName = divisorValue + " " + Reflect.field(m_jobToTotalMapping, selectedPlayerJob).numeric_unit_group;
                    
                    var barWhole : BarWhole = new BarWhole(false);
                    barWhole.barSegments.push(new BarSegment(parseInt(dividendValue), 1, 0xFFFFFFFF, null));
                    barWhole.barLabels.push(new BarLabel(dividendValue, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                    m_barModelArea.getBarModelData().barWholes.push(barWhole);
                    m_barModelArea.redraw(false);
                    
                    var referenceModel : BarModelData = new BarModelData();
                    var referenceBarWhole : BarWhole = new BarWhole(false);
                    var divisorNumber : Int = parseInt(divisorValue);
                    for (i in 0...divisorNumber){
                        referenceBarWhole.barSegments.push(new BarSegment(1, 1, 0xFFFFFFFF, null));
                    }
                    referenceBarWhole.barLabels.push(new BarLabel(m_totalA, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                    referenceBarWhole.barLabels.push(new BarLabel(dividendValue, 0, divisorNumber - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
                    referenceModel.barWholes.push(referenceBarWhole);
                    m_validateBarModel.setReferenceModels([referenceModel]);
                    
                    // Make sure undo and reset revert to this original state
                    var undoBarModel : UndoBarModelArea = try cast(getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null;
                    undoBarModel.resetHistory();
                    undoBarModel.setIsActive(true);
                    
                    var resetBarModel : ResetBarModelArea = try cast(getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null;
                    resetBarModel.setStartingModel(m_barModelArea.getBarModelData().clone());
                    resetBarModel.setIsActive(true);
                    
                    // Make sure the total has the appropriate name and value mapping
                    m_gameEngine.getCurrentLevel().termValueToBarModelValue[m_totalA] = parseInt(m_dividendAValue) / m_divisorAGroups;
                    var expressionDataForTotal : Dynamic = Reflect.field(m_jobToTotalMapping, selectedPlayerJob);
                    var symbolDataForTotal : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_totalA);
                    symbolDataForTotal.abbreviatedName = Reflect.field(expressionDataForTotal, "unit_a_abbr");
                    symbolDataForTotal.name = Reflect.field(expressionDataForTotal, "unit_a_name");
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        // Slide the deck back upwards to reveal the area
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        
        // After slide up start the hint sequence to talk about
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Start the hint flow for splitting the bar model
                    m_progressControl.setProgressValue("hinting", "split_bar");
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "divide_bar_finished",

                }));
        
        // Start the hint sequence which should guide the player towards splitting a value and then
        // labeling a single group in that value
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Disable the undo/reset
                    getNodeById("ResetBarModelArea").setIsActive(false);
                    getNodeById("UndoBarModelArea").setIsActive(false);
                    greyOutAndDisableButton("resetButton", true);
                    greyOutAndDisableButton("undoButton", true);
                    
                    // Disable all the bar model actions
                    getNodeById("BarModelDragGestures").setIsActive(false);
                    m_validateBarModel.setIsActive(false);
                    
                    // Stop all active hints
                    m_progressControl.setProgressValue("hinting", null);
                    
                    // Slide up the equation area
                    m_switchModelScript.onSwitchModelClicked();
                    
                    // Need to figure out the correct equation
                    m_validateEquation.addEquation("1", m_totalA + "=" + m_dividendAValue + "/" + m_divisorAGroups, false, true);
                    
                    // Put most of the values onto the equation areas already
                    m_gameEngine.setTermAreaContent("leftTermArea", m_totalA);
                    m_gameEngine.setTermAreaContent("rightTermArea", m_dividendAValue);
                    
                    var leftTermArea : TermAreaWidget = (try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null);
                    leftTermArea.restrictValues = true;
                    
                    var rightTermArea : TermAreaWidget = (try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null);
                    rightTermArea.restrictValues = true;
                    rightTermArea.restrictedValues.push(m_divisorAGroups + "");
                    getNodeById("AddTerm").setIsActive(true);
                    getNodeById("RemoveTerm").setIsActive(true);
                    
                    // Enable the equation area (only allow user to drag a specific part)
                    m_gameEngine.getCurrentLevel().getLevelRules().termsNotRemovable.push(m_totalA, m_dividendAValue);
                    
                    m_progressControl.setProgressValue("hinting", "divide_equation");
                    m_progressControl.setProgressValue("stage", "divide_equation_start");
                    
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressValueEqualsCallback, {
                    key : "stage",
                    value : "divide_equation_finished",

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.5

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        var addNewLabelOnSegment : AddNewLabelOnSegment = new AddNewLabelOnSegment(m_gameEngine, m_expressionCompiler, m_assetManager, "AddNewLabelOnSegment");
        (try cast(getNodeById("CardOnSegmentRadialOptions"), CardOnSegmentRadialOptions) catch(e:Dynamic) null).addGesture(addNewLabelOnSegment);
        addNewLabelOnSegment.overrideLevelReady();
        
        var splitBarSegment : SplitBarSegment = new SplitBarSegment(m_gameEngine, m_expressionCompiler, m_assetManager, "SplitBarSegment");
        (try cast(getNodeById("CardOnSegmentRadialOptions"), CardOnSegmentRadialOptions) catch(e:Dynamic) null).addGesture(splitBarSegment);
        splitBarSegment.overrideLevelReady();
        
        m_progressControl.setProgressValue("stage", "divide_bar_start");
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "divide_bar_start")) 
            {
                m_progressControl.setProgressValue("stage", "divide_bar_finished");
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgressValueEquals("stage", "divide_equation_start")) 
            {
                m_progressControl.setProgressValue("stage", "divide_equation_finished");
            }
        }
        else if (eventType == GameEvent.OPEN_RADIAL_OPTIONS) 
        {
            // Show callout telling them to pick the divide option
            var radialDisplay : DisplayObject = param.display;
            var radialDisplayRenderComponent : RenderableComponent = new RenderableComponent("radialOptions");
            radialDisplayRenderComponent.view = radialDisplay;
            m_gameEngine.getUiComponentManager().addComponentToEntity(radialDisplayRenderComponent);
            
            showDialogForUi({
                        id : "radialOptions",
                        text : "Use divide!",
                        color : 0x5082B9,
                        direction : Callout.DIRECTION_DOWN,
                        animationPeriod : 1,

                    });
            m_isRadialMenuOpen = true;
        }
        else if (eventType == GameEvent.CLOSE_RADIAL_OPTIONS) 
        {
            // Clear the callout on the radial menu
            m_gameEngine.getUiComponentManager().removeAllComponentsFromEntity("radialOptions");
            m_isRadialMenuOpen = false;
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
    
    private function getBarModelMistakeDetected() : Bool
    {
        // Prompt a reset or undo if the divisor has been used incorrectly
        // Easy way to detect is checking there is a label with that value
        var mistakeMade : Bool = false;
        var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
        for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(targetBarWhole),barLabels) type: null */ in targetBarWhole.barLabels)
        {
            if (barLabel.value == Std.string(m_divisorAGroups)) 
            {
                mistakeMade = true;
                break;
            }
        }
        return mistakeMade;
    }
    
    private var m_pickedSegmentId : String;
    private function showCalloutOnSegment(calloutMessage : String, height : Float) : Void
    {
        // Add callout on one of the segments
        var id : String = null;
        var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
        if (barWholes.length > 0) 
        {
            var firstBarWhole : BarWhole = barWholes[0];
            if (firstBarWhole.barSegments.length > 0) 
            {
                id = firstBarWhole.barSegments[0].id;
            }
        }
        
        if (id != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : calloutMessage,
                        color : 0x5082B9,
                        direction : Callout.DIRECTION_UP,
                        width : 200,
                        height : height,
                        animationPeriod : 1,
                        xOffset : 0,

                    });
            m_pickedSegmentId = id;
        }
    }
    
    private function hideCalloutOnSegment() : Void
    {
        if (m_pickedSegmentId != null) 
        {
            removeDialogForBaseWidget({
                        id : m_pickedSegmentId,
                        widgetId : "barModelArea",

                    });
            m_pickedSegmentId = null;
        }
    }
    
    private function showUndoMistake() : Void
    {
        showDialogForUi({
                    id : "undoButton",
                    text : "Press here to undo!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    width : 200,
                    height : 60,
                    animationPeriod : 1,
                    xOffset : 0,

                });
    }
    
    private function hideUndoMistake() : Void
    {
        removeDialogForUi({
                    id : "undoButton"

                });
    }
    
    private var m_divideTermId : String;
    private function showDivideEquation() : Void
    {
        // Since there is no bar element with the divisor, you'll need to grab the element in the deck
        showDialogForBaseWidget({
                    id : "8",
                    widgetId : "deckArea",
                    text : "Drag number here...",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_DOWN,
                    width : 200,
                    height : 60,
                    animationPeriod : 1,
                    xOffset : 0,

                });
        
        // Tell the user to drag the target element below in order to divide
        var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var multiplyTermId : String = rightTermArea.getWidgetRoot().getNode().id + "";
        showDialogForBaseWidget({
                    id : multiplyTermId,
                    widgetId : "rightTermArea",
                    text : "...underneath this to divide!",
                    color : 0x5082B9,
                    direction : Callout.DIRECTION_UP,
                    width : 200,
                    height : 70,
                    xOffset : 0,
                    animationPeriod : 1,

                });
        m_divideTermId = multiplyTermId;
    }
    
    private function hideDivideEquation() : Void
    {
        removeDialogForBaseWidget({
                    id : "8",
                    widgetId : "deckArea",

                });
        removeDialogForBaseWidget({
                    id : m_divideTermId,
                    widgetId : "rightTermArea",

                });
    }
}
