package levelscripts.barmodel.tutorials;


import flash.geom.Rectangle;

import cgs.display.engine.avatar.Robot;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
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
import wordproblem.hints.scripts.HelpController;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.resource.FlashResourceUtil;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.expression.RemoveTerm;
import wordproblem.scripts.expression.ResetTermArea;
import wordproblem.scripts.expression.UndoTermArea;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.LevelCommonUtil;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;

class LSEquationFromBarA extends BaseCustomLevelScript
{
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    /**
     * Script controlling correctness of bar models
     */
    private var m_validation : ValidateBarModelArea;
    
    private var m_barModelArea : BarModelAreaWidget;
    private var m_hintController : HelpController;
    
    /**
     * Script controlling swapping between bar model and equation model.
     */
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    
    private var m_buildOptions : Array<String>;
    private var m_materialAOptions : Array<String>;
    private var m_materialBOptions : Array<String>;
    
    private var m_buildSelected : String;
    private var m_materialASelected : String;
    private var m_materialBSelected : String;
    
    private var m_equationAreasShowing : Bool = false;
    
    // Sequenced hints
    private var m_showNumberAHint : HintScript;
    private var m_showVariableAHint : HintScript;
    private var m_showSubmitHint : HintScript;
    private var m_showNumberBHint : HintScript;
    private var m_showVariableBHint : HintScript;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
        
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
        m_switchModelScript.targetY = 80;
        super.pushChild(m_switchModelScript);
        
        var prioritySelector : PrioritySelector = new PrioritySelector();
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
        prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        super.pushChild(prioritySelector);
        
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        
        // Add logic to only accept the model of a particular equation
        super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
        // Add logic to handle adding new cards (only active after all cards discovered)
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager));
        super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
        
        super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", true));
        super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", true));
        m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
        super.pushChild(m_validation);
        
        m_buildOptions = ["cannon", "space_ship", "dinosaur", "teleporter", "box"];
        m_materialAOptions = ["sword", "cupcake", "rope", "bunny"];
        m_materialBOptions = ["apple", "red_panda", "flowers_pink", "mushroom"];
        
        m_showNumberAHint = new CustomFillLogicHint(showDragNumberA, null, null, null, hideDragNumberA, null, true);
        m_showVariableAHint = new CustomFillLogicHint(showDragVariableA, null, null, null, hideDragVariableA, null, true);
        m_showSubmitHint = new CustomFillLogicHint(showSubmitEquation, null, null, null, hideSubmitEquation, null, true);
        m_showNumberBHint = new CustomFillLogicHint(showDragNumberB, null, null, null, hideDragNumberB, null, true);
        m_showVariableBHint = new CustomFillLogicHint(showDragVariableB, null, null, null, hideDragVariableB, null, true);
    }
    
    override public function getNumCopilotProblems() : Int
    {
        return 5;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_temporaryTextureControl.dispose();
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            if (m_progressControl.getProgress() == 2 && m_equationAreasShowing) 
            {
                // Check if added the appropriate values to the term areas
                var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                var addedNumber : Bool = false;
                var addedVariable : Bool = false;
                if (leftTermArea.getWidgetRoot() != null) 
                {
                    addedNumber = (leftTermArea.getWidgetRoot().getNode().data == "9");
                    addedVariable = (leftTermArea.getWidgetRoot().getNode().data == m_materialASelected);
                }
                
                if (rightTermArea.getWidgetRoot() != null) 
                {
                    if (!addedNumber) 
                    {
                        addedNumber = (rightTermArea.getWidgetRoot().getNode().data == "9");
                    }
                    
                    if (!addedVariable) 
                    {
                        addedVariable = (rightTermArea.getWidgetRoot().getNode().data == m_materialASelected);
                    }
                }
                
                if (!addedNumber && m_hintController.getCurrentlyShownHint() != m_showNumberAHint) 
                {
                    m_hintController.manuallyShowHint(m_showNumberAHint);
                }
                else if (addedNumber && !addedVariable && m_hintController.getCurrentlyShownHint() != m_showVariableAHint) 
                {
                    m_hintController.manuallyShowHint(m_showVariableAHint);
                }
                else if (addedNumber && addedVariable && m_hintController.getCurrentlyShownHint() != m_showSubmitHint) 
                {
                    m_hintController.manuallyShowHint(m_showSubmitHint);
                }
            }
            else if (m_progressControl.getProgress() == 4 && m_equationAreasShowing) 
            {
                leftTermArea = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                rightTermArea = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                
                var addedBothNumbers : Bool = false;
                addedVariable = false;
                var leftRoot : BaseTermWidget = leftTermArea.getWidgetRoot();
                if (leftRoot != null) 
                {
                    if (leftRoot.leftChildWidget != null && leftRoot.rightChildWidget != null) 
                    {
                        addedBothNumbers = (leftRoot.leftChildWidget.getNode().data == "8" && leftRoot.rightChildWidget.getNode().data == "6") ||
                                (leftRoot.leftChildWidget.getNode().data == "6" && leftRoot.rightChildWidget.getNode().data == "8");
                    }
                    addedVariable = (leftTermArea.getWidgetRoot().getNode().data == m_materialBSelected);
                }
                
                var rightRoot : BaseTermWidget = rightTermArea.getWidgetRoot();
                if (rightRoot != null) 
                {
                    if (!addedBothNumbers && rightRoot.leftChildWidget != null && rightRoot.rightChildWidget != null) 
                    {
                        addedBothNumbers = (rightRoot.leftChildWidget.getNode().data == "8" && rightRoot.rightChildWidget.getNode().data == "6") ||
                                (rightRoot.leftChildWidget.getNode().data == "6" && rightRoot.rightChildWidget.getNode().data == "8");
                    }
                    
                    if (!addedVariable) 
                    {
                        addedVariable = (rightTermArea.getWidgetRoot().getNode().data == m_materialBSelected);
                    }
                }
                
                if (!addedBothNumbers && m_hintController.getCurrentlyShownHint() != m_showNumberBHint) 
                {
                    m_hintController.manuallyShowHint(m_showNumberBHint);
                }
                else if (addedBothNumbers && !addedVariable && m_hintController.getCurrentlyShownHint() != m_showVariableBHint) 
                {
                    m_hintController.manuallyShowHint(m_showVariableBHint);
                }
                else if (addedBothNumbers && addedVariable && m_hintController.getCurrentlyShownHint() != m_showSubmitHint) 
                {
                    m_hintController.manuallyShowHint(m_showSubmitHint);
                }
            }
        }
        return super.visit();
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        super.disablePrevNextTextButtons();
        
        var uiContainer : DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
        var startingUiContainerY : Float = uiContainer.y;
        m_switchModelScript.setContainerOriginalY(startingUiContainerY);
        
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
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
        
        // Setup second model
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    refreshSecondPage();
                    setupSecondModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 300,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
        
        // Once second model is done immediately build the equation
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
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
                    pageIndex : 2

                }));
        
        // Selecting the second material
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 300,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setupThirdModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
        
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
                    pageIndex : 3

                }));
        
        // At this point try to model the last equation
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 300,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 5));
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
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
                    pageIndex : 4

                }));
        sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                    duration : 0.3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 350,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        
        super.pushChild(sequenceSelector);
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitHeight = 60;
        m_barModelArea.unitLength = 200;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        setupFirstModel();
        refreshFirstPage();
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                m_progressControl.incrementProgress();
                
                // Get the color that was selected
                var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_buildSelected = targetBarWhole.barLabels[0].value;
                
                // Replace the question mark in the first page
                var buildName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_buildSelected).name;
                var contentA : FastXML = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(buildName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["build_select_a"],
                        [contentA], 0);
                refreshFirstPage();
                
                // Replace spaces in the next pages
                contentA = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(buildName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["build_select_b"],
                        [contentA], 1);
                
                contentA = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(buildName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["build_select_c", "build_select_d"],
                        [contentA, contentA], 2);
                
                contentA = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(buildName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["build_select_e"],
                        [contentA], 4);
                
                // Clear the bar model
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                m_progressControl.incrementProgress();
                
                // Get the material that was selected
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_materialASelected = targetBarWhole.barLabels[0].value;
                
                // Replace the question mark in the second page
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_materialASelected).name);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["material_a_select_a"],
                        [contentA], 1);
                refreshSecondPage();
                
                // Clear the bar model
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Transition to stage where player builds first equation
                this.getNodeById("RemoveBarSegment").setIsActive(false);
                m_switchModelScript.setIsActive(true);
                setupFirstEquation();
            }
            else if (m_progressControl.getProgress() == 3) 
            {
                m_progressControl.incrementProgress();
                
                // Get the material that was selected
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_materialBSelected = targetBarWhole.barLabels[0].value;
                
                var materialBName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_materialBSelected).name;
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(materialBName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["material_b_select_a", "material_b_select_b"],
                        [contentA, contentA], 2);
                refreshThirdPage();
                
                // Transition to stage where player builds second equation
                this.getNodeById("RemoveBarSegment").setIsActive(false);
                m_switchModelScript.setIsActive(true);
                setupSecondEquation();
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgress() == 2) 
            {
                m_progressControl.incrementProgress();
                
                // Disable switching
                m_switchModelScript.setIsActive(false);
                m_switchModelScript.onSwitchModelClicked();
                
                // Remove all tooltips
                m_hintController.manuallyRemoveAllHints();
                removeDialogForUi({
                            id : "barModelArea"

                        });
                
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw(false);
                
                // Reactivate bar model
                this.getNodeById("RemoveBarSegment").setIsActive(true);
            }
            else if (m_progressControl.getProgress() == 4) 
            {
                m_progressControl.incrementProgress();
            }
        }
        else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                var targetBuildValue : String = null;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    targetBuildValue = targetBarWhole.barLabels[0].value;
                }
                
                var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                drawBuildObjectOnFirstPage(textArea, targetBuildValue);
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                var targetMaterialValue : String = null;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    targetMaterialValue = targetBarWhole.barLabels[0].value;
                }
                
                textArea = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                drawMaterialOnSecondPage(textArea, targetMaterialValue);
            }
            else if (m_progressControl.getProgress() == 3) 
            {
                targetMaterialValue = null;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    targetMaterialValue = targetBarWhole.barLabels[0].value;
                }
                
                textArea = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                drawMaterialOnThirdPage(textArea, targetMaterialValue);
            }
        }
    }
    
    private function setupFirstModel() : Void
    {
        m_gameEngine.setDeckAreaContent(m_buildOptions, super.getBooleanList(m_buildOptions.length, false), false);
        
        LevelCommonUtil.setReferenceBarModelForPickem("a_build", null, m_buildOptions, m_validation);
    }
    
    private function setupSecondModel() : Void
    {
        // Show the bar model validate button
        m_gameEngine.getUiEntity("validateButton").visible = true;
        m_validation.setIsActive(true);
        m_gameEngine.setDeckAreaContent(m_materialAOptions, super.getBooleanList(m_materialAOptions.length, false), false);
        
        // Re-use the same junk model, set add more aliases
        LevelCommonUtil.setReferenceBarModelForPickem("a_build", null, m_materialAOptions, m_validation);
    }
    
    private function setupThirdModel() : Void
    {
        // Show the bar model validate button
        m_gameEngine.getUiEntity("validateButton").visible = true;
        m_validation.setIsActive(true);
        m_gameEngine.setDeckAreaContent(m_materialBOptions, super.getBooleanList(m_materialBOptions.length, false), false);
        
        // Re-use the same junk model, set add more aliases
        LevelCommonUtil.setReferenceBarModelForPickem("a_build", null, m_materialBOptions, m_validation);
        
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        barModelArea.unitLength = 200;
    }
    
    private function setupFirstEquation() : Void
    {
        // Hide the bar model validate button
        m_gameEngine.getUiEntity("validateButton").visible = false;
        m_validation.setIsActive(false);
        m_gameEngine.setDeckAreaContent(new Array<String>(), new Array<Bool>(), false);
        
        // Draw and lock the target bar model
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        barModelArea.unitLength = 40;
        var barModelData : BarModelData = barModelArea.getBarModelData();
        var blankBarWhole : BarWhole = new BarWhole(false);
        blankBarWhole.barSegments.push(new BarSegment(9, 1, 0xB8DBFF, null));
        blankBarWhole.barLabels.push(new BarLabel("9", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        blankBarWhole.barLabels.push(new BarLabel(m_materialASelected, 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
        barModelData.barWholes.push(blankBarWhole);
        barModelArea.redraw();
        
        var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
        modelSpecificEquationScript.addEquation("1", m_materialASelected + "=9", false, true);
        
        // Add dialog to button to swap between diagram and equation model mode
        showDialogForUi({
                    id : "switchModelButton",
                    text : "Click here!",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
    }
    
    private function setupSecondEquation() : Void
    {
        // Hide the bar model validate button
        m_gameEngine.getUiEntity("validateButton").visible = false;
        
        // Do not allow undo of the bar model
        m_validation.setIsActive(false);
        
        m_gameEngine.setDeckAreaContent(new Array<String>(), new Array<Bool>(), false);
        
        m_gameEngine.setTermAreaContent("leftTermArea", null);
        m_gameEngine.setTermAreaContent("rightTermArea", null);
        
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        barModelArea.unitLength = 30;
        var barModelData : BarModelData = barModelArea.getBarModelData();
        barModelData.clear();
        
        var blankBarWhole : BarWhole = new BarWhole(false);
        blankBarWhole.barSegments.push(new BarSegment(8, 1, 0xB8DBFF, null));
        blankBarWhole.barSegments.push(new BarSegment(6, 1, 0xB8DBFF, null));
        blankBarWhole.barLabels.push(new BarLabel("8", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        blankBarWhole.barLabels.push(new BarLabel("6", 1, 1, true, false, BarLabel.BRACKET_NONE, null));
        blankBarWhole.barLabels.push(new BarLabel(m_materialBSelected, 0, 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        barModelData.barWholes.push(blankBarWhole);
        barModelArea.redraw();
        
        var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
        modelSpecificEquationScript.resetEquations();
        modelSpecificEquationScript.addEquation("1", m_materialBSelected + "=6+8", false, true);
        
        // Add dialog to button to swap between diagram and equation model mode
        showDialogForUi({
                    id : "switchModelButton",
                    text : "Click here!",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
    }
    
    private function refreshFirstPage() : Void
    {
        // Create the robot and paste it
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var documentViews : Array<DocumentView> = new Array<DocumentView>();
        var robotImage : Image = m_temporaryTextureControl.getImageWithId("start_robot");
        if (robotImage == null) 
        {
            var robotTexture : Texture = FlashResourceUtil.getTextureFromFlashClass(Robot, {
                        frame : 0

                    }, 0.8, new Rectangle(50, 210, 140, 230));
            robotImage = new Image(robotTexture);
            m_temporaryTextureControl.saveImageWithId("start_robot", robotImage);
        }
        
        textArea.getDocumentViewsAtPageIndexById("robot_container_a", documentViews, 0);
        documentViews[0].addChild(robotImage);
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
        
        // Fill in the build option
        drawBuildObjectOnFirstPage(textArea, m_buildSelected);
    }
    
    private function drawBuildObjectOnFirstPage(textArea : TextAreaWidget, buildValue : String) : Void
    {
        m_textReplacementControl.drawDisposableTextureAtDocId(buildValue, m_temporaryTextureControl, textArea,
                "build_container_a", 0, -1, 130);
    }
    
    private function refreshSecondPage() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        drawMaterialOnSecondPage(textArea, m_materialASelected);
        
        if (m_materialASelected != null) 
        {
            setDocumentIdVisible({
                        id : "hidden_a",
                        visible : true,

                    });
        }
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    private function drawMaterialOnSecondPage(textArea : TextAreaWidget, materialValue : String) : Void
    {
        m_textReplacementControl.drawDisposableTextureAtDocId(materialValue, m_temporaryTextureControl, textArea,
                "build_container_b", 1, -1, 130);
    }
    
    private function refreshThirdPage() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        
        drawMaterialOnThirdPage(textArea, m_materialBSelected);
        
        if (m_materialBSelected != null) 
        {
            setDocumentIdVisible({
                        id : "hidden_b",
                        visible : true,

                    });
        }
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    private function drawMaterialOnThirdPage(textArea : TextAreaWidget, materialValue : String) : Void
    {
        m_textReplacementControl.drawDisposableTextureAtDocId(materialValue, m_temporaryTextureControl, textArea,
                "build_container_c", 2, -1, 130);
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
            
            if (m_progressControl.getProgress() == 2) 
            {
                removeDialogForUi({
                            id : "switchModelButton"

                        });
                
                // Show tooltip on term areas
                var materialName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_materialASelected).name;
                showDialogForUi({
                            id : "barModelArea",
                            text : "Pick up pieces!",
                            color : 0xFFFFFF,
                            direction : Callout.DIRECTION_UP,
                            animationPeriod : 1,

                        });
            }
            else if (m_progressControl.getProgress() == 4) 
            {
                removeDialogForUi({
                            id : "switchModelButton"

                        });
            }
        }
        
        m_equationAreasShowing = !inBarModelMode;
    }
    
    /*
    Logic for hints
    */
    private function showDragNumberA() : Void
    {
        showDialogForUi({
                    id : "leftTermArea",
                    text : "Put 9 here!",
                    color : 0xFFFFFF,
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
        // Determine which side the number was placed in
        var materialName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_materialASelected).name;
        var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var uiEntityToAddTo : String = ((leftTermArea.getWidgetRoot() == null)) ? "leftTermArea" : "rightTermArea";
        showDialogForUi({
                    id : uiEntityToAddTo,
                    text : "Put " + materialName + " here!",
                    color : 0xFFFFFF,
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
                    color : 0xFFFFFF,
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
    
    private function showDragNumberB() : Void
    {
        showDialogForUi({
                    id : "leftTermArea",
                    text : "Put 2 numbers here!",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
    }
    
    private function hideDragNumberB() : Void
    {
        removeDialogForUi({
                    id : "leftTermArea"

                });
    }
    
    private function showDragVariableB() : Void
    {
        var materialName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_materialBSelected).name;
        var leftTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var uiEntityToAddTo : String = ((leftTermArea.getWidgetRoot() == null)) ? "leftTermArea" : "rightTermArea";
        showDialogForUi({
                    id : uiEntityToAddTo,
                    text : "Put " + materialName + " here!",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    animationPeriod : 1,

                });
    }
    
    private function hideDragVariableB() : Void
    {
        removeDialogForUi({
                    id : "rightTermArea"

                });
        removeDialogForUi({
                    id : "leftTermArea"

                });
    }
}
