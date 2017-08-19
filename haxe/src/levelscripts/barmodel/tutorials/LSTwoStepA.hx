package levelscripts.barmodel.tutorials;


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
class LSTwoStepA extends BaseCustomLevelScript
{
    private var m_avatarControl : AvatarControl;
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    private var m_validation : ValidateBarModelArea;
    private var m_barModelArea : BarModelAreaWidget;
    private var m_hintController : HelpController;
    
    /**
     * Script controlling swapping between bar model and equation model.
     */
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    
    private var m_characterAOptions : Array<String>;
    private var m_characterASelected : String;
    private var m_characterASettings : Dynamic;
    private var m_characterBOptions : Array<String>;
    private var m_characterBSelected : String;
    private var m_characterBSettings : Dynamic;
    private var m_characterToHatId : Dynamic;
    
    // Pause until the clicked the hint button
    private var m_hintButtonClickedOnce : Bool = false;
    private var m_sawSecondHint : Bool = false;
    
    // Hints to get working
    private var m_barModelIsSetup : Bool = false;
    private var m_addFirstBarHint : HintScript;
    private var m_addSecondBarHint : HintScript;
    private var m_addVerticalLabelHint : HintScript;
    private var m_addComparisonHint : HintScript;
    private var m_getNewHint : HintScript;
    
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
        
        // Player is supposed to add a new bar into a blank space
        var prioritySelector : PrioritySelector = new PrioritySelector("BarModelDragGestures");
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
        var modifyGestures : PrioritySelector = new PrioritySelector("BarModelModifyGestures");
        modifyGestures.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, true, "BarToCardModelMode", false));
        var removeGestures : PrioritySelector = new PrioritySelector("BarModelRemoveGestures");
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
        
        var termAreaPrioritySelector : PrioritySelector = new PrioritySelector();
        super.pushChild(termAreaPrioritySelector);
        termAreaPrioritySelector.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager));
        termAreaPrioritySelector.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
        
        m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
        super.pushChild(m_validation);
        
        m_characterAOptions = ["pirate", "bandit", "chef", "viking"];
        m_characterASettings = {
                    species : AvatarSpeciesData.MAMMAL,
                    earType : 7,
                    color : AvatarColors.PINK,

                };
        m_characterBOptions = ["cowboy", "skeleton", "witch", "blonde"];
        m_characterBSettings = {
                    species : AvatarSpeciesData.BIRD,
                    earType : 3,
                    color : AvatarColors.TEAL,

                };
        m_characterToHatId = {
                    pirate : 1,
                    cowboy : 4,
                    chef : 10,
                    viking : 88,
                    bandit : 112,
                    skeleton : 131,
                    witch : 141,
                    blonde : 12,

                };
        
        m_getNewHint = new CustomFillLogicHint(showGetNewHint, null, null, null, hideGetNewHint, null, true);
        m_addFirstBarHint = new CustomFillLogicHint(showAddFirstBar, null, null, null, hideAddFirstBar, null, true);
        m_addSecondBarHint = new CustomFillLogicHint(showAddSecondBar, null, null, null, hideAddSecondBar, null, true);
        m_addComparisonHint = new CustomFillLogicHint(showAddComparison, null, null, null, hideAddComparison, null, true);
        m_addVerticalLabelHint = new CustomFillLogicHint(showAddVerticalLabel, null, null, null, hideAddVerticalLabel, null, true);
    }
    
    override public function visit() : Int
    {
        // Custom logic needed to deal with controlling when hints not bound to the hint screen
        // are activated or deactivated
        if (m_ready) 
        {
            // Highlight the split button
            if (m_progressControl.getProgress() == 2 && m_barModelIsSetup) 
            {
                var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
                var foundAllParts : Bool = deckArea.getObjects().length == 4;
                if (foundAllParts) 
                {
                    var addedFirstBar : Bool = false;
                    var addedSecondBar : Bool = false;
                    var addedComparison : Bool = false;
                    var addedVerticalLabel : Bool = false;
                    
                    var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                    var numBarWholes : Int = barWholes.length;
                    for (i in 0...numBarWholes){
                        var barWhole : BarWhole = barWholes[i];
                        if (barWhole.barSegments.length == 1 && barWhole.barLabels.length > 0) 
                        {
                            var labelValue : String = barWhole.barLabels[0].value;
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
                    
                    var verticalLabels : Array<BarLabel> = m_barModelArea.getBarModelData().verticalBarLabels;
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
    
    override public function getNumCopilotProblems() : Int
    {
        return 5;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
        m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        
        m_temporaryTextureControl.dispose();
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        disablePrevNextTextButtons();
        
        var uiContainer : DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
        var startingUiContainerY : Float = uiContainer.y;
        m_switchModelScript.setContainerOriginalY(startingUiContainerY);
        
        // Bind events
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitHeight = 60;
        m_barModelArea.unitLength = 300;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        
        m_avatarControl = new AvatarControl();
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        // Make sure the table is the right size
        var termValueToBarModelValueMap : Dynamic = {
            table : 4

        };
        m_gameEngine.getCurrentLevel().termValueToBarModelValue = termValueToBarModelValueMap;
        
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 350,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 1

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 275,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    // Activate the the hint
                    m_hintController.setIsActive(true);
                    m_hintController.manuallyShowHint(m_getNewHint);
                    return ScriptStatus.SUCCESS;
                }, null));
        
        // Wait until they have clicked the hint button
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    if (m_hintButtonClickedOnce) 
                    {
                        setupBarModel();
                    }
                    return ((m_hintButtonClickedOnce)) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        // Special tutorial hints
        // First shows all the character
        var helperCharacterController : HelperCharacterController = new HelperCharacterController(
        m_gameEngine.getCharacterComponentManager(), 
        new CalloutCreator(m_textParser, m_textViewFactory));
        var hintSelector : HintSelectorNode = new HintSelectorNode();
        hintSelector.setCustomGetHintFunction(function() : HintScript
                {
                    // TODO: This hint should not show up until the player has modeled the bars
                    
                    var textAreas : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TextAreaWidget);
                    if (textAreas.length > 0) 
                    {
                        var textArea : TextAreaWidget = try cast(textAreas[0], TextAreaWidget) catch(e:Dynamic) null;
                        
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
                                        descriptionContent : "You need to make two equation to finish the problem, 10 + table = total and table=10-6."

                                    };
                            hint = HintCommonUtil.createHintFromMismatchData(hintData,
                                            helperCharacterController,
                                            m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, textArea,
                                            m_gameEngine, 200, 350);
                        }
                        else if (m_progressControl.getProgress() == 2) 
                        {
                            var hintData : Dynamic = {
                                descriptionContent : "This problem has multiple unknowns that you need in your answer.",
                                highlightDocIds : textArea.getAllDocumentIdsTiedToExpression(),

                            };
                            var hint : HintScript = HintCommonUtil.createHintFromMismatchData(hintData,
                                    helperCharacterController,
                                    m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, textArea,
                                    m_gameEngine, 200, 350);
                        }
                    }
                    return hint;
                }, null);
        
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        hintController.setRootHintSelectorNode(hintSelector);
        m_hintController = hintController;
        
        setupFirstAnimalSelectModel();
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                m_progressControl.incrementProgress();
                
                var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_characterASelected = targetBarWhole.barLabels[0].value;
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the parts with the first character
                var contentA : FastXML = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(m_characterASelected);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["character_a_a"],
                        [contentA], 0);
                
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["character_a_b"],
                        [contentA], 1);
                
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
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the parts with the second character
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(m_characterBSelected);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["character_b_a"],
                        [contentA], 0);
                
                refreshFirstPage();
                
                // Clear the deck
                m_gameEngine.setDeckAreaContent([], [], false);
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
                                var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
                                if (modelSpecificEquationScript.getAtLeastOneSetComplete()) 
                                {
                                    m_progressControl.incrementProgress();
                                }
                            }(try cast(this.getNodeById("UndoTermArea"), UndoTermArea) catch(e:Dynamic) null).resetHistory(false)  // Clear undo history, there is another equation and we need to start fresh  ;
        }
        else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN) 
        {
            if (m_progressControl.getProgress() == 0 || m_progressControl.getProgress() == 1) 
            {
                var selectedValue : String = null;
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
    
    private function setupFirstAnimalSelectModel() : Void
    {
        m_gameEngine.setDeckAreaContent(m_characterAOptions, super.getBooleanList(m_characterAOptions.length, false), false);
        
        LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_characterAOptions, m_validation);
        
        refreshFirstPage();
    }
    
    private function setupSecondAnimalSelectModel() : Void
    {
        m_gameEngine.setDeckAreaContent(m_characterBOptions, super.getBooleanList(m_characterBOptions.length, false), false);
        
        LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_characterBOptions, m_validation);
    }
    
    private function setupBarModel() : Void
    {
        m_barModelIsSetup = true;
        
        var referenceModel : BarModelData = new BarModelData();
        var barWhole : BarWhole = new BarWhole(false, "a");
        barWhole.barSegments.push(new BarSegment(10, 1, 0, null));
        barWhole.barLabels.push(new BarLabel("10", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        referenceModel.barWholes.push(barWhole);
        
        barWhole = new BarWhole(false);
        barWhole.barSegments.push(new BarSegment(4, 1, 0, null));
        barWhole.barLabels.push(new BarLabel("table", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        barWhole.barComparison = new BarComparison("6", "a", 0);
        referenceModel.barWholes.push(barWhole);
        
        referenceModel.verticalBarLabels.push(new BarLabel("total", 0, 1, false, true, BarLabel.BRACKET_STRAIGHT, null));
        m_validation.setReferenceModels([referenceModel]);
        
        // Allow the gestures to properly create the new model
        (try cast(this.getNodeById("AddNewBar"), AddNewBar) catch(e:Dynamic) null).setMaxBarsAllowed(2);
        this.getNodeById("AddNewHorizontalLabel").setIsActive(true);
        this.getNodeById("AddNewVerticalLabel").setIsActive(true);
        this.getNodeById("AddNewBarComparison").setIsActive(true);
    }
    
    private function setupEquationModel() : Void
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
        var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
        modelSpecificEquationScript.addEquation("1", "table=total-10", false);
        modelSpecificEquationScript.addEquation("2", "table=10-6", false);
        modelSpecificEquationScript.addEquationSet(["1", "2"]);
        
        // Enable the term area undo, reset, and add
        this.getNodeById("AddTerm").setIsActive(true);
        this.getNodeById("UndoTermArea").setIsActive(true);
        this.getNodeById("ResetTermArea").setIsActive(true);
    }
    
    private function refreshFirstPage() : Void
    {
        redrawCharacterAOnFirstPage(m_characterASelected);
        
        redrawCharacterBOnFirstPage(m_characterBSelected);
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null);
    }
    
    private function redrawCharacterAOnFirstPage(selectedValue : String) : Void
    {
        // Create the head of the first character
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var characterAHead : Image = m_avatarControl.createAvatarImage(
                m_characterASettings.species,
                m_characterASettings.earType,
                m_characterASettings.color,
                ((selectedValue != null)) ? Reflect.field(m_characterToHatId, selectedValue) : 0,
                0,
                AvatarExpressions.SAD,
                AvatarAnimations.IDLE,
                0, 230,
                new Rectangle(30, 230, 160, 160),
                Direction.EAST
                );
        m_textReplacementControl.addImageAtDocumentId(characterAHead, textArea, "character_a_container", 0);
    }
    
    private function redrawCharacterBOnFirstPage(selectedValue : String) : Void
    {
        // Create the head of the second character
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var characterBHead : Image = m_avatarControl.createAvatarImage(
                m_characterBSettings.species,
                m_characterBSettings.earType,
                m_characterBSettings.color,
                ((selectedValue != null)) ? Reflect.field(m_characterToHatId, selectedValue) : 0,
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
    private function showGetNewHint() : Void
    {
        showDialogForUi({
                    id : "hintButton",
                    text : "New Hint",
                    width : 170,
                    height : 70,
                    direction : Callout.DIRECTION_RIGHT,
                    color : 0xFFFFFF,

                });
    }
    
    private function hideGetNewHint() : Void
    {
        removeDialogForUi({
                    id : "hintButton"

                });
    }
    
    private function showAddFirstBar() : Void
    {
        showDeckTooltip("10", "Make a box for this.");
    }
    
    private function hideAddFirstBar() : Void
    {
        hideDeckTooltip("10");
    }
    
    private function showAddSecondBar() : Void
    {
        showDeckTooltip("table", "Make a box for this.");
    }
    
    private function hideAddSecondBar() : Void
    {
        hideDeckTooltip("table");
    }
    
    private function showAddComparison() : Void
    {
        showDeckTooltip("6", "Use to show the difference between the boxes");
    }
    
    private function hideAddComparison() : Void
    {
        hideDeckTooltip("6");
    }
    
    private function showAddVerticalLabel() : Void
    {
        showDeckTooltip("total", "Add to the side of both boxes");
    }
    
    private function hideAddVerticalLabel() : Void
    {
        hideDeckTooltip("total");
    }
    
    private function showDeckTooltip(deckId : String, text : String) : Void
    {
        // Highlight the number in the deck and say player should drag it onto the bar below
        var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        deckArea.componentManager.addComponentToEntity(new HighlightComponent(deckId, 0xFF0000, 2));
        showDialogForBaseWidget({
                    id : deckId,
                    widgetId : "deckArea",
                    text : text,
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    width : 200,
                    height : 70,
                    animationPeriod : 1,

                });
    }
    
    private function hideDeckTooltip(deckId : String) : Void
    {
        var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        if (deckArea != null) 
        {
            deckArea.componentManager.removeComponentFromEntity(deckId, HighlightComponent.TYPE_ID);
            removeDialogForBaseWidget({
                        id : deckId,
                        widgetId : "deckArea",

                    });
        }
    }
}
