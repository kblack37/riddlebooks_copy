package levelscripts.barmodel.tutorials;


import flash.utils.Dictionary;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Callout;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.level.LevelRules;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.PrioritySelector;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.hints.CustomFillLogicHint;
import wordproblem.hints.HintScript;
import wordproblem.hints.scripts.HelpController;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.barmodel.AddNewVerticalLabel;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
import wordproblem.scripts.barmodel.ResetBarModelArea;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
import wordproblem.scripts.barmodel.UndoBarModelArea;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckCallout;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.expression.RemoveTerm;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.expression.ResetTermArea;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.HighlightTextForCard;
import wordproblem.scripts.text.TextToCard;
import wordproblem.scripts.expression.UndoTermArea;

class LSAddVerticalLabelA extends BaseCustomLevelScript
{
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    /**
     * Script controlling correctness of bar models
     */
    private var m_validation : ValidateBarModelArea;
    private var m_hintController : HelpController;
    
    /**
     * Script controlling swapping between bar model and equation model.
     */
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    
    private var m_items : Array<String>;
    
    private var m_selectedItem : String;
    
    /*
    Hints
    */
    private var m_isBarModelSetup : Bool;
    private var m_addVerticalLabelHint : HintScript;
    private var m_createBarWithVerticalLabelHint : HintScript;
    
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
        resizeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager));
        resizeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager));
        super.pushChild(resizeGestures);
        
        var prioritySelector : PrioritySelector = new PrioritySelector("barModelDragGestures");
        prioritySelector.pushChild(new AddNewVerticalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewVerticalLabel"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewVerticalLabel", "ShowAddNewVerticalLabelHitAreas"));
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 2, "AddNewBar"));
        super.pushChild(prioritySelector);
        
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
        m_switchModelScript.targetY = 80;
        super.pushChild(m_switchModelScript);
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        
        // Add logic to only accept the model of a particular equation
        super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
        // Add logic to handle adding new cards (only active after all cards discovered)
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager));
        super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
        
        // Logic for text dragging + discovery
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new HighlightTextForCard(m_gameEngine, m_assetManager));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
        super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
        m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
        super.pushChild(m_validation);
        
        m_items = ["banana", "spider", "gorilla", "fairy"];
        
        m_isBarModelSetup = false;
        m_addVerticalLabelHint = new CustomFillLogicHint(showAddVerticalLabel, null, null, null, hideAddVerticalLabel, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
            if (m_progressControl.getProgress() == 0 && m_isBarModelSetup) 
            {
                var labelAdded : Bool = barModelArea.getVerticalBarLabelViews().length > 0;
                if (!labelAdded && m_hintController.getCurrentlyShownHint() != m_addVerticalLabelHint) 
                {
                    m_hintController.manuallyShowHint(m_addVerticalLabelHint);
                }
                else if (labelAdded && m_hintController.getCurrentlyShownHint() != null) 
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
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        
        m_temporaryTextureControl.dispose();
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        disablePrevNextTextButtons();
        
        var uiContainer : DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
        var startingUiContainerY : Float = uiContainer.y;
        m_switchModelScript.setContainerOriginalY(startingUiContainerY);
        
        var levelRules : LevelRules = m_gameEngine.getCurrentLevel().getLevelRules();
        levelRules.allowMultiply = false;
        levelRules.allowDivide = false;
        
        // Bind events
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
        
        // Set up all the special controllers for logic and data management in this specific level
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.0,
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
                    y : 280,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setupFirstModel();
                    m_isBarModelSetup = true;
                    return ScriptStatus.SUCCESS;
                }, null));
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
                    pageIndex : 2

                }));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 280,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    refreshThirdPage();
                    setupSecondModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setupThirdModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        // Special tutorial hints
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
            if (m_progressControl.getProgress() == 0) 
            {
                m_progressControl.incrementProgress();
                
                // Clear the bar model
                (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(null);
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                barModelArea.getBarModelData().clear();
                barModelArea.redraw();
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                m_progressControl.incrementProgress();
                
                // Get the item that was selected
                var targetBarWhole : BarWhole = barModelArea.getBarModelData().barWholes[0];
                m_selectedItem = targetBarWhole.barLabels[0].value;
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                barModelArea.getBarModelData().clear();
                barModelArea.redraw();
                
                // Replace as many instances as possible
                var itemName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_selectedItem).name;
                var contentA : FastXML = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(itemName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_a", "item_select_b", "item_select_c"],
                        [contentA, contentA, contentA], 2);
                
                setDocumentIdVisible({
                            id : "hidden_a",
                            visible : true,

                        });
                refreshThirdPage();
            }
            else if (m_progressControl.getProgress() == 2) 
            {
                m_progressControl.incrementProgress();
                
                // Set up last equation
                var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
                modelSpecificEquationScript.addEquation("1", "total=instance_a+instance_b", false, true);
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).setIsActive(false);
                
                // Activate the switch
                m_switchModelScript.setIsActive(true);
                m_switchModelScript.onSwitchModelClicked();
                
                this.getNodeById("UndoTermArea").setIsActive(true);
                this.getNodeById("ResetTermArea").setIsActive(true);
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgress() == 3) 
            {
                m_progressControl.incrementProgress();
            }
        }
    }
    
    private function setupFirstModel() : Void
    {
        var deckItems : Array<String> = ["new_box"];
        m_gameEngine.setDeckAreaContent(deckItems, super.getBooleanList(deckItems.length, false), false);
        
        // Reference is two boxes combined by vertical label
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(false);
        correctBarWhole.barSegments.push(new BarSegment(3, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("green", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctModel.barWholes.push(correctBarWhole);
        
        correctBarWhole = new BarWhole(false);
        correctBarWhole.barSegments.push(new BarSegment(2, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("blue", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctModel.barWholes.push(correctBarWhole);
        
        correctModel.verticalBarLabels.push(new BarLabel("new_box", 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null));
        
        referenceBarModels.push(correctModel);
        m_validation.setReferenceModels(referenceBarModels);
        
        // Automatically fill in the player area with the starting bars
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        var startingBarWhole : BarWhole = new BarWhole(false);
        startingBarWhole.barSegments.push(new BarSegment(3, 1, 0x006D2F, null));
        startingBarWhole.barLabels.push(new BarLabel("green", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        barModelArea.getBarModelData().barWholes.push(startingBarWhole);
        
        startingBarWhole = new BarWhole(false);
        startingBarWhole.barSegments.push(new BarSegment(2, 1, 0x3399FF, null));
        startingBarWhole.barLabels.push(new BarLabel("blue", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        barModelArea.getBarModelData().barWholes.push(startingBarWhole);
        barModelArea.redraw(false);
        
        (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(barModelArea.getBarModelData());
        
        // Disable remove, only need to add the vertical bracket
        this.getNodeById("barModelRemoveGestures").setIsActive(false);
    }
    
    private function setupSecondModel() : Void
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
        
        // Re-enable remove
        this.getNodeById("barModelRemoveGestures").setIsActive(true);
    }
    
    private function setupThirdModel() : Void
    {
        // The instances must have card names be altered to fit the choice the player made
        var instanceAData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("instance_a");
        instanceAData.abbreviatedName = m_selectedItem + " one";
        instanceAData.name = instanceAData.abbreviatedName;
        var instanceBData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("instance_b");
        instanceBData.abbreviatedName = m_selectedItem + " two";
        instanceBData.name = instanceBData.abbreviatedName;
        var instanceTotalData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("total");
        instanceTotalData.abbreviatedName = "mega " + m_selectedItem + " weight";
        instanceTotalData.name = instanceTotalData.abbreviatedName;
        
        var deckItems : Array<String> = ["instance_a", "instance_b", "total"];
        m_gameEngine.setDeckAreaContent(deckItems, super.getBooleanList(deckItems.length, false), false);
        
        // Manually bind the numeric value for each custom instance
        var termToValueMap : Dictionary = new Dictionary();
        Reflect.setField(termToValueMap, "instance_a", 3);
        Reflect.setField(termToValueMap, "instance_b", 2);
        m_gameEngine.getCurrentLevel().termValueToBarModelValue = termToValueMap;
        
        // Reference is two boxes combined by vertical label
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(false, "barA");
        correctBarWhole.barSegments.push(new BarSegment(3, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("instance_a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctModel.barWholes.push(correctBarWhole);
        
        correctBarWhole = new BarWhole(false, "barB");
        correctBarWhole.barSegments.push(new BarSegment(2, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("instance_b", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctModel.barWholes.push(correctBarWhole);
        
        correctModel.verticalBarLabels.push(new BarLabel("total", 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null));
        
        referenceBarModels.push(correctModel);
        m_validation.setReferenceModels(referenceBarModels);
    }
    
    private function refreshThirdPage() : Void
    {
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null);
    }
    
    private function onSwitchModelClicked(inBarModelMode : Bool) : Void
    {
        if (inBarModelMode) 
        {
            this.getNodeById("barModelDragGestures").setIsActive(true);
            this.getNodeById("barModelRemoveGestures").setIsActive(true);
            this.getNodeById("BarToCard").setIsActive(false);
        }
        else 
        {
            this.getNodeById("barModelDragGestures").setIsActive(false);
            this.getNodeById("barModelRemoveGestures").setIsActive(false);
            this.getNodeById("BarToCard").setIsActive(true);
        }
    }
    
    /*
    Logic for hints
    */
    private var m_pickedId : String;
    private function showAddVerticalLabel() : Void
    {
        // The dialog should appear far to the right of the longer bar
        var id : String = null;
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        if (barModelArea.getBarWholeViews().length == 2) 
        {
            var targetSegment : BarSegmentView = barModelArea.getBarWholeViews()[0].segmentViews[0];
            id = targetSegment.data.id;
        }
        
        if (id != null) 
        {
            barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : "Drag here to add boxes on two lines.",
                        color : 0xFFFFFF,
                        direction : Callout.DIRECTION_RIGHT,
                        width : 200,
                        height : 70,
                        animationPeriod : 1,
                        xOffset : 60,

                    });
            m_pickedId = id;
        }
    }
    
    private function hideAddVerticalLabel() : Void
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
}
