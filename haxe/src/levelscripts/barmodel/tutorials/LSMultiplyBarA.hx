package levelscripts.barmodel.tutorials;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarLabelView;
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
import wordproblem.hints.scripts.HelpController;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
import wordproblem.scripts.barmodel.AddNewLabelOnSegment;
import wordproblem.scripts.barmodel.AddNewUnitBar;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
import wordproblem.scripts.barmodel.RemoveLabelOnSegment;
import wordproblem.scripts.barmodel.ResetBarModelArea;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.UndoBarModelArea;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckCallout;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.expression.PressToChangeOperator;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.HighlightTextForCard;
import wordproblem.scripts.text.TextToCard;

class LSMultiplyBarA extends BaseCustomLevelScript
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
    
    private var m_items : Array<String>;
    private var m_selectedItemA : String;
    
    /*
    Hints
    */
    private var m_isBarModelSetup : Bool;
    private var m_createGroupsHint : HintScript;
    private var m_dragNameOnTopHint : HintScript;
    private var m_dragNameUnderHint : HintScript;
    private var m_clickToMultiply : HintScript;
    
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
        super.pushChild(new DeckCallout(m_gameEngine, m_expressionCompiler, m_assetManager));
        
        var resizeGestures : PrioritySelector = new PrioritySelector("barModelRemoveGestures");
        resizeGestures.pushChild(new RemoveLabelOnSegment(gameEngine, expressionCompiler, assetManager, "RemoveLabelOnSegment", false));
        resizeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager));
        resizeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager));
        super.pushChild(resizeGestures);
        
        var prioritySelector : PrioritySelector = new PrioritySelector("barModelDragGestures");
        prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel", false));
        prioritySelector.pushChild(new AddNewLabelOnSegment(gameEngine, expressionCompiler, assetManager, "AddNewLabelOnSegment"));
        prioritySelector.pushChild(new AddNewUnitBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewUnitBar"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewUnitBar", "ShowAddNewUnitBarHitAreas"));
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        super.pushChild(prioritySelector);
        
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, null, "SwitchBetweenBarAndEquationModel", false);
        m_switchModelScript.targetY = 80;
        super.pushChild(m_switchModelScript);
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        
        // Add logic to only accept the model of a particular equation
        super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
        // Add logic to handle changing the operator (only active after all cards discovered)
        super.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager));
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new HighlightTextForCard(m_gameEngine, m_assetManager));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
        super.pushChild(m_validation);
        
        m_items = ["feather", "moon_craft", "buffalo", "balloon_grey", "dog_biscuit"];
        
        m_isBarModelSetup = false;
        m_createGroupsHint = new CustomFillLogicHint(showCreateGroups, null, null, null, hideCreateGroups, null, true);
        m_dragNameOnTopHint = new CustomFillLogicHint(showDragOnTop, null, null, null, hideDragOnTop, null, true);
        m_dragNameUnderHint = new CustomFillLogicHint(showDragUnder, null, null, null, hideDragUnder, null, true);
        m_clickToMultiply = new CustomFillLogicHint(showClickToMultiply, null, null, null, hideClickToMultiply, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            if (m_progressControl.getProgress() == 1 && m_isBarModelSetup) 
            {
                var groupsCreated : Bool = false;
                if (m_barModelArea.getBarWholeViews().length > 0) 
                {
                    groupsCreated = m_barModelArea.getBarWholeViews()[0].segmentViews.length >= 3;
                }
                
                if (!groupsCreated && m_hintController.getCurrentlyShownHint() != m_createGroupsHint) 
                {
                    m_hintController.manuallyShowHint(m_createGroupsHint);
                }
                else if (groupsCreated && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgress() == 2 && m_isBarModelSetup) 
            {
                groupsCreated = false;
                var nameOnTopOfSegment : Bool = false;
                if (m_barModelArea.getBarWholeViews().length > 0) 
                {
                    var barWholeView : BarWholeView = m_barModelArea.getBarWholeViews()[0];
                    groupsCreated = barWholeView.segmentViews.length >= 4;
                    nameOnTopOfSegment = barWholeView.labelViews.length > 0;
                }
                
                if (!groupsCreated && !nameOnTopOfSegment && m_hintController.getCurrentlyShownHint() != m_createGroupsHint) 
                {
                    m_hintController.manuallyShowHint(m_createGroupsHint);
                }
                else if (groupsCreated && !nameOnTopOfSegment && m_hintController.getCurrentlyShownHint() != m_dragNameOnTopHint) 
                {
                    m_hintController.manuallyShowHint(m_dragNameOnTopHint);
                }
                else if (groupsCreated && nameOnTopOfSegment && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgress() == 3 && m_isBarModelSetup) 
            {
                groupsCreated = false;
                nameOnTopOfSegment = false;
                var labelUnderneath : Bool = false;
                if (m_barModelArea.getBarWholeViews().length > 0) 
                {
                    barWholeView = m_barModelArea.getBarWholeViews()[0];
                    groupsCreated = barWholeView.segmentViews.length >= 5;
                    
                    var labelViews : Array<BarLabelView> = barWholeView.labelViews;
                    for (labelView in labelViews)
                    {
                        if (labelView.data.bracketStyle == BarLabel.BRACKET_NONE) 
                        {
                            nameOnTopOfSegment = true;
                        }
                        else 
                        {
                            labelUnderneath = true;
                        }
                    }
                }
                
                if (!groupsCreated && !nameOnTopOfSegment && !labelUnderneath && m_hintController.getCurrentlyShownHint() != m_createGroupsHint) 
                {
                    m_hintController.manuallyShowHint(m_createGroupsHint);
                }
                else if (groupsCreated && !nameOnTopOfSegment && !labelUnderneath && m_hintController.getCurrentlyShownHint() != m_dragNameOnTopHint) 
                {
                    m_hintController.manuallyShowHint(m_dragNameOnTopHint);
                }
                else if (groupsCreated && nameOnTopOfSegment && !labelUnderneath && m_hintController.getCurrentlyShownHint() != m_dragNameUnderHint) 
                {
                    m_hintController.manuallyShowHint(m_dragNameUnderHint);
                }
                else if (groupsCreated && nameOnTopOfSegment && labelUnderneath && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgress() == 4) 
            {
                var changedToMultiply : Bool = false;
                var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                if (rightTermArea.getWidgetRoot() != null) 
                {
                    changedToMultiply = rightTermArea.getWidgetRoot().getNode().isSpecificOperator(
                                    m_expressionCompiler.getVectorSpace().getMultiplicationOperator()
                                    );
                }
                
                if (!changedToMultiply && m_hintController.getCurrentlyShownHint() != m_clickToMultiply) 
                {
                    m_hintController.manuallyShowHint(m_clickToMultiply);
                }
                else if (changedToMultiply && m_hintController.getCurrentlyShownHint() != null) 
                {
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
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitLength = 150;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        
        // Set up all the special controllers for logic and data management in this specific level
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 300,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 1

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 285,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setupBarModelA();
                    m_isBarModelSetup = true;
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 300,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 2

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 285,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setupBarModelB();
                    m_isBarModelSetup = true;
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 300,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 3

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 285,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setupBarModelC();
                    m_isBarModelSetup = true;
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 5));
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        // Special tutorial hints
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        setupSelectItemAModel();
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                m_progressControl.incrementProgress();
                
                // Get the item that was selected
                var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_selectedItemA = targetBarWhole.barLabels[0].value;
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace as many instances as possible
                var itemNameSingle : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_selectedItemA).name;
                var contentA : FastXML = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(itemNameSingle);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_a", "item_select_b"],
                        [contentA, contentA], 0);
                
                contentA = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(itemNameSingle);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_c"],
                        [contentA], 1);
                
                contentA = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(itemNameSingle);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_d", "item_select_e"],
                        [contentA, contentA], 2);
                
                contentA = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(itemNameSingle);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_f", "item_select_g", "item_select_h"],
                        [contentA, contentA, contentA], 3);
                
                setDocumentIdVisible({
                            id : "hidden_a",
                            visible : true,

                        });
                
                refreshFirstPage();
                
                // Allow remove label on top of segment after the pick'em is complete
                this.getNodeById("RemoveLabelOnSegment").setIsActive(true);
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                m_progressControl.incrementProgress();
                
                // Clear the bar model
                (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(null);
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                m_isBarModelSetup = false;
            }
            else if (m_progressControl.getProgress() == 2) 
            {
                m_progressControl.incrementProgress();
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                m_isBarModelSetup = false;
            }
            else if (m_progressControl.getProgress() == 3) 
            {
                m_progressControl.incrementProgress();
                
                // Disable undo and reset
                this.getNodeById("ResetBarModelArea").setIsActive(false);
                this.getNodeById("UndoBarModelArea").setIsActive(false);
                m_validation.setIsActive(false);
                
                // Disable remove
                this.getNodeById("barModelDragGestures").setIsActive(false);
                this.getNodeById("barModelRemoveGestures").setIsActive(false);
                this.getNodeById("BarToCard").setIsActive(true);
                
                // Disable validation
                m_validation.setIsActive(false);
                
                // Hide validate button
                m_gameEngine.getUiEntity("validateButton").visible = false;
                
                // Activate the switch
                m_switchModelScript.setIsActive(true);
                m_switchModelScript.onSwitchModelClicked();
                
                // Set up equation
                var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
                modelSpecificEquationScript.addEquation("1", "total=5*4", false, true);
                
                // Player just needs to click to make the plus to a subtract
                m_gameEngine.setTermAreaContent("leftTermArea", "total");
                m_gameEngine.setTermAreaContent("rightTermArea", "5+4");
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgress() == 4) 
            {
                m_progressControl.incrementProgress();
            }
        }
        else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                var targetItem : String = null;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetItem = m_barModelArea.getBarModelData().barWholes[0].barLabels[0].value;
                }
                drawItemOnFirstPage(targetItem);
            }
        }
    }
    
    private function setupSelectItemAModel() : Void
    {
        m_gameEngine.setDeckAreaContent(m_items, super.getBooleanList(m_items.length, false), false);
        
        // The correct model will allow for every color to be an acceptable answer
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        correctBarWhole.barSegments.push(new BarSegment(1, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("anything", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
        m_validation.setTermValueAliases("anything", m_items);
        
        refreshFirstPage();
    }
    
    private function setupBarModelA() : Void
    {
        var deckItems : Array<String> = ["3"];
        m_gameEngine.setDeckAreaContent(deckItems, super.getBooleanList(deckItems.length, false), false);
        
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        var i : Int = 0;
        for (i in 0...3){
            correctBarWhole.barSegments.push(new BarSegment(1, 1, 0, null));
        }
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
        
        // Disable add bar
        this.getNodeById("AddNewBar").setIsActive(false);
        
        // Disable remove
        this.getNodeById("barModelRemoveGestures").setIsActive(false);
    }
    
    private function setupBarModelB() : Void
    {
        var deckItems : Array<String> = ["3", "4"];
        m_gameEngine.setDeckAreaContent(deckItems, super.getBooleanList(deckItems.length, false), false);
        
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        var i : Int = 0;
        for (i in 0...4){
            correctBarWhole.barSegments.push(new BarSegment(1, 1, 0, null));
        }
        correctBarWhole.barLabels.push(new BarLabel("3", 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        correctModel = new BarModelData();
        correctBarWhole = new BarWhole(true);
        for (i in 0...4){
            correctBarWhole.barSegments.push(new BarSegment(1, 1, 0, null));
            correctBarWhole.barLabels.push(new BarLabel("3", i, i, true, false, BarLabel.BRACKET_STRAIGHT, null));
        }
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
    }
    
    private function setupBarModelC() : Void
    {
        // Activate horizontal label
        this.getNodeById("AddNewHorizontalLabel").setIsActive(true);
        
        // The instances must have card names be altered to fit the choice the player made
        var itemName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_selectedItemA).name;
        var instanceAData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("total");
        instanceAData.abbreviatedName = "total " + itemName;
        instanceAData.name = instanceAData.abbreviatedName;
        
        var deckItems : Array<String> = ["4", "5", "total"];
        m_gameEngine.setDeckAreaContent(deckItems, super.getBooleanList(deckItems.length, false), false);
        
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        var i : Int = 0;
        for (i in 0...5){
            correctBarWhole.barSegments.push(new BarSegment(1, 1, 0, null));
        }
        correctBarWhole.barLabels.push(new BarLabel("4", 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctBarWhole.barLabels.push(new BarLabel("total", 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        correctModel = new BarModelData();
        correctBarWhole = new BarWhole(true);
        for (i in 0...5){
            correctBarWhole.barSegments.push(new BarSegment(1, 1, 0, null));
            correctBarWhole.barLabels.push(new BarLabel("4", 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
        }
        correctBarWhole.barLabels.push(new BarLabel("total", 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
    }
    
    private function refreshFirstPage() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_textReplacementControl.drawDisposableTextureAtDocId("zuzu", m_temporaryTextureControl, textArea,
                "character_container_a", 0, -1, 200);
        drawItemOnFirstPage(m_selectedItemA);
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    private function drawItemOnFirstPage(value : String) : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_textReplacementControl.drawDisposableTextureAtDocId(value, m_temporaryTextureControl, textArea,
                "item_container_a", 0, -1, 100);
    }
    
    /*
    Logic for hints
    */
    private var m_pickedId : String;
    private function showCreateGroups() : Void
    {
        // Need to add a callout to the bar model area
        // It needs to be offset such that is actually points to the add unit hit area
        var xOffset : Float = -m_barModelArea.width * 0.5 + 35;
        var yOffset : Float = 25;
        showDialogForUi({
                    id : "barModelArea",
                    text : "Make equal groups.",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    width : 70,
                    height : 100,
                    animationPeriod : 1,
                    xOffset : xOffset,
                    yOffset : yOffset,

                });
    }
    
    private function hideCreateGroups() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
    private function showDragOnTop() : Void
    {
        // Add callout on one of the segments
        var id : String = null;
        if (m_barModelArea.getBarWholeViews().length > 0) 
        {
            var segmentViews : Array<BarSegmentView> = m_barModelArea.getBarWholeViews()[0].segmentViews;
            if (segmentViews.length > 0) 
            {
                id = segmentViews[0].data.id;
            }
        }
        
        if (id != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : "Drag on top of box to add name.",
                        color : 0xFFFFFF,
                        direction : Callout.DIRECTION_UP,
                        width : 200,
                        height : 70,
                        animationPeriod : 1,
                        xOffset : 0,

                    });
            m_pickedId = id;
        }
    }
    
    private function hideDragOnTop() : Void
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
    
    private function showDragUnder() : Void
    {
        // Draw callout underneath the middle segment
        var id : String = null;
        if (m_barModelArea.getBarModelData().barWholes.length > 0) 
        {
            var firstBar : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
            if (firstBar.barSegments.length >= 5) 
            {
                id = firstBar.barSegments[2].id;
            }
        }
        
        if (id != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : "Drag here to name ALL groups.",
                        color : 0xFFFFFF,
                        direction : Callout.DIRECTION_DOWN,
                        width : 200,
                        height : 70,
                        animationPeriod : 1,
                        yOffset : 20,

                    });
            m_pickedId = id;
        }
    }
    
    private function hideDragUnder() : Void
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
    
    private function showClickToMultiply() : Void
    {
        // Set dialog on the subtract term telling to click on it
        var multiplyTermText : String = "Equal parts mean multiply. Click Here!";
        var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var multiplyTermId : String = rightTermArea.getWidgetRoot().rightChildWidget.getNode().id + "";
        showDialogForBaseWidget({
                    id : multiplyTermId,
                    widgetId : "rightTermArea",
                    text : multiplyTermText,
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    width : 200,
                    height : 70,
                    xOffset : -40,
                    animationPeriod : 1,

                });
        m_pickedId = multiplyTermId;
    }
    
    private function hideClickToMultiply() : Void
    {
        removeDialogForBaseWidget({
                    id : m_pickedId,
                    widgetId : "rightTermArea",

                });
    }
}
