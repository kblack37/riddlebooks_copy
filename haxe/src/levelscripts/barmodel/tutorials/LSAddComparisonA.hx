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

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.constants.Direction;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.PrioritySelector;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.engine.text.view.DocumentView;
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
import wordproblem.scripts.expression.PressToChangeOperator;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.AvatarControl;
import wordproblem.scripts.level.util.LevelCommonUtil;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;
import wordproblem.scripts.model.ModelSpecificEquation;

class LSAddComparisonA extends BaseCustomLevelScript
{
    private var m_progressControl : ProgressControl;
    private var m_avatarControl : AvatarControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    /**
     * Script controlling correctness of bar models
     */
    private var m_validation : ValidateBarModelArea;
    
    /**
     * Script controlling swapping between bar model and equation model.
     */
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    
    private var m_hintController : HelpController;
    
    private var m_items : Array<String>;
    private var m_selectedItemA : String;
    private var m_selectedItemB : String;
    
    private var m_isBarModelSetup : Bool;
    private var m_addComparisonHint : HintScript;
    private var m_addFirstBarHint : HintScript;
    private var m_addSecondBarHint : HintScript;
    private var m_addSecondComparisonHint : HintScript;
    private var m_subtractionHint : HintScript;
    
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
        
        var resizeGestures : PrioritySelector = new PrioritySelector("barModelClickGestures");
        resizeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager));
        resizeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager));
        super.pushChild(resizeGestures);
        
        var prioritySelector : PrioritySelector = new PrioritySelector("barModelDragGestures");
        prioritySelector.pushChild(new AddNewBarComparison(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarComparison", "ShowAddNewBarComparisonHitAreas"));
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
        super.pushChild(prioritySelector);
        
        m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
        m_switchModelScript.targetY = 80;
        super.pushChild(m_switchModelScript);
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
        super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
        
        // Add logic to only accept the model of a particular equation
        super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
        super.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager));
        
        m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
        super.pushChild(m_validation);
        
        m_items = ["watermelon", "fish", "caterpillar", "cookie", "pegasus", "sea_sprite"];
        
        m_isBarModelSetup = false;
        m_addComparisonHint = new CustomFillLogicHint(showAddComparison, null, null, null, hideAddComparison, null, true);
        m_addFirstBarHint = new CustomFillLogicHint(showAddFirstBarHint, null, null, null, hideAddFirstBarHint, null, true);
        m_addSecondBarHint = new CustomFillLogicHint(showAddSecondBarHint, null, null, null, hideAddSecondBarHint, null, true);
        m_addSecondComparisonHint = new CustomFillLogicHint(showAddSecondComparisonHint, null, null, null, hideAddSecondComparisonHint, null, true);
        m_subtractionHint = new CustomFillLogicHint(showSubtractionHint, null, null, null, hideSubtractionHint, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
            var barWholes : Array<BarWhole> = barModelArea.getBarModelData().barWholes;
            if (m_progressControl.getProgress() == 1 && m_isBarModelSetup) 
            {
                var barComparisonFound : Bool = false;
                var i : Int = 0;
                for (i in 0...barWholes.length){
                    if (barWholes[i].barComparison != null) 
                    {
                        barComparisonFound = true;
                        break;
                    }
                }
                
                if (!barComparisonFound && m_hintController.getCurrentlyShownHint() != m_addComparisonHint) 
                {
                    m_hintController.manuallyShowHint(m_addComparisonHint);
                }
            }
            else if (m_progressControl.getProgress() == 3 && m_isBarModelSetup) 
            {
                var firstBarAdded : Bool = false;
                var secondBarAdded : Bool = false;
                barComparisonFound = false;
                for (i in 0...barWholes.length){
                    var barWhole : BarWhole = barWholes[i];
                    if (barWhole.barLabels.length > 0) 
                    {
                        var labelValue : String = barWhole.barLabels[0].value;
                        if (labelValue == "tic_b") 
                        {
                            firstBarAdded = true;
                        }
                        
                        if (labelValue == "tac_b") 
                        {
                            secondBarAdded = true;
                        }
                    }
                    
                    if (barWhole.barComparison != null) 
                    {
                        barComparisonFound = true;
                    }
                }
                
                if (firstBarAdded && secondBarAdded && barComparisonFound && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
                
                if (!firstBarAdded && m_hintController.getCurrentlyShownHint() != m_addFirstBarHint) 
                {
                    m_hintController.manuallyShowHint(m_addFirstBarHint);
                }
                else if (firstBarAdded && !secondBarAdded && m_hintController.getCurrentlyShownHint() != m_addSecondBarHint) 
                {
                    m_hintController.manuallyShowHint(m_addSecondBarHint);
                }
                else if (firstBarAdded && secondBarAdded && !barComparisonFound && m_hintController.getCurrentlyShownHint() != m_addSecondComparisonHint) 
                {
                    m_hintController.manuallyShowHint(m_addSecondComparisonHint);
                }
            }
            else if (m_progressControl.getProgress() == 4) 
            {
                // Set dialog on the subtract term telling to click on it
                var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
                var usedSubtract : Bool = false;
                if (rightTermArea.getWidgetRoot() != null) 
                {
                    usedSubtract = rightTermArea.getWidgetRoot().getNode().isSpecificOperator(
                                    m_expressionCompiler.getVectorSpace().getSubtractionOperator()
                                    );
                }
                
                if (!usedSubtract && m_hintController.getCurrentlyShownHint() != m_subtractionHint) 
                {
                    m_hintController.manuallyShowHint(m_subtractionHint);
                }
                else if (usedSubtract && m_hintController.getCurrentlyShownHint() != null) 
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
        
        m_avatarControl.dispose();
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
        
        // Set up all the special controllers for logic and data management in this specific level
        m_progressControl = new ProgressControl();
        m_avatarControl = new AvatarControl();
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
                    y : 350,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 1

                }));
        
        // Set up first model when reach next page
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 285,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    refreshSecondPage();
                    setupFirstModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
        
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_isBarModelSetup = true;
                    setupSecondModel();
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
                    y : 350,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {
                    pageIndex : 2

                }));
        
        // Set up next model when reach next page
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 285,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    setupThirdModel();
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
                    y : 350,

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
                    m_isBarModelSetup = true;
                    setupFourthModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
        
        // At this point they solved the last bar model and now just need to solve the last equation
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 5));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : 650,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
        sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {
                    x : 450,
                    y : 350,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
        super.pushChild(sequenceSelector);
        
        // Special tutorial hints
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        redrawFirstPage();
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
            if (m_progressControl.getProgress() == 0) 
            {
                m_progressControl.incrementProgress();
                
                // Get the item that was selected
                var targetBarWhole : BarWhole = barModelArea.getBarModelData().barWholes[0];
                m_selectedItemA = targetBarWhole.barLabels[0].value;
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                barModelArea.getBarModelData().clear();
                barModelArea.redraw();
                (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(null);
                
                // Fill in the missing words
                var itemName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_selectedItemA).name;
                var itemNamePlural : String = itemName + "s";
                var contentA : FastXML = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(itemName);
                var contentB : FastXML = FastXML.parse("<span></span>");
                contentB.node.appendChild.innerData(itemNamePlural);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_a", "item_select_b"],
                        [contentA, contentB], 1);
                
                // Replace all parts of text with the selected item
                refreshSecondPage();
                
                setDocumentIdVisible({
                            id : "hidden_a",
                            visible : true,

                        });
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                m_progressControl.incrementProgress();
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                barModelArea.getBarModelData().clear();
                barModelArea.redraw();
                (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(null);
                m_isBarModelSetup = false;
            }
            else if (m_progressControl.getProgress() == 2) 
            {
                m_progressControl.incrementProgress();
                
                // Get the item that was selected
                targetBarWhole = barModelArea.getBarModelData().barWholes[0];
                m_selectedItemB = targetBarWhole.barLabels[0].value;
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                barModelArea.getBarModelData().clear();
                barModelArea.redraw();
                (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(null);
                
                // Fill in the missing words
                itemName = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_selectedItemB).name;
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(itemName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_d"],
                        [contentA], 2);
                
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(itemName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["item_select_e", "item_select_f"],
                        [contentA, contentA], 3);
                
                refreshThirdPage();
                
                // Reveal last part of the text
                setDocumentIdVisible({
                            id : "hidden_c",
                            visible : true,

                        });
            }
            else if (m_progressControl.getProgress() == 3) 
            {
                m_progressControl.incrementProgress();
                
                // Clear the bar model
                this.getNodeById("UndoBarModelArea").setIsActive(false);
                this.getNodeById("ResetBarModelArea").setIsActive(false);
                
                // Activate the switch
                m_switchModelScript.setIsActive(true);
                m_switchModelScript.onSwitchModelClicked();
                
                setupFifthModel();
            }
        }
        else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            if (m_progressControl.getProgress() == 4) 
            {
                m_progressControl.incrementProgress();
                
                // Reveal last part of the text
                setDocumentIdVisible({
                            id : "hidden_d",
                            visible : true,

                        });
            }
        }
    }
    
    /*
    Pick first item
    */
    private function setupFirstModel() : Void
    {
        m_gameEngine.setDeckAreaContent(m_items, super.getBooleanList(m_items.length, false), false);
        
        LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_items, m_validation);
    }
    
    /*
    Create comparison with prebuilt model
    */
    private function setupSecondModel() : Void
    {
        // The instances must have card names be altered to fit the choice the player made
        var expressionSymbolMap : ExpressionSymbolMap = m_gameEngine.getExpressionSymbolResources();
        var selectedItemData : SymbolData = expressionSymbolMap.getSymbolDataFromValue(m_selectedItemA);
        
        var instanceAData : SymbolData = expressionSymbolMap.getSymbolDataFromValue("tic_a");
        instanceAData.abbreviatedName = "Tic's " + selectedItemData.abbreviatedName;
        instanceAData.name = instanceAData.abbreviatedName;
        var instanceBData : SymbolData = expressionSymbolMap.getSymbolDataFromValue("tac_a");
        instanceBData.abbreviatedName = "Tac's " + selectedItemData.abbreviatedName;
        instanceBData.name = instanceBData.abbreviatedName;
        var instanceTotalData : SymbolData = expressionSymbolMap.getSymbolDataFromValue("difference");
        instanceTotalData.abbreviatedName = "weight difference";
        instanceTotalData.name = instanceTotalData.abbreviatedName;
        
        var deckItems : Array<String> = ["difference"];
        m_gameEngine.setDeckAreaContent(deckItems, super.getBooleanList(deckItems.length, false), false);
        
        // Manually bind the numeric value for each custom instance
        var termToValueMap : Dynamic = {
            tic_a : 6,
            tac_a : 3,

        };
        m_gameEngine.getCurrentLevel().termValueToBarModelValue = termToValueMap;
        
        // Two bars with a comparison on the smaller one
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(false, "barA");
        correctBarWhole.barSegments.push(new BarSegment(Reflect.field(termToValueMap, "tic_a"), 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("tic_a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctModel.barWholes.push(correctBarWhole);
        
        correctBarWhole = new BarWhole(false, "barB");
        correctBarWhole.barSegments.push(new BarSegment(Reflect.field(termToValueMap, "tac_a"), 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("tac_a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctBarWhole.barComparison = new BarComparison("difference", "barA", 0);
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
        
        // Automatically fill in the player area with the starting bars
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        
        var startingBarWhole : BarWhole = new BarWhole(false);
        startingBarWhole.barSegments.push(new BarSegment(Reflect.field(termToValueMap, "tic_a"), 1, 0x69E3C5, null));
        startingBarWhole.barLabels.push(new BarLabel("tic_a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        barModelArea.getBarModelData().barWholes.push(startingBarWhole);
        
        startingBarWhole = new BarWhole(false);
        startingBarWhole.barSegments.push(new BarSegment(Reflect.field(termToValueMap, "tac_a"), 1, 0x95F2F2, null));
        startingBarWhole.barLabels.push(new BarLabel("tac_a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        barModelArea.getBarModelData().barWholes.push(startingBarWhole);
        barModelArea.redraw(false);
        
        // Reset should go back to the intial bars
        (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(barModelArea.getBarModelData());
        
        // Disable the remove gestures
        this.getNodeById("barModelClickGestures").setIsActive(false);
    }
    
    /*
    Pick second item
    */
    private function setupThirdModel() : Void
    {
        // Exact same as setup for first
        setupFirstModel();
        
        this.getNodeById("barModelClickGestures").setIsActive(true);
    }
    
    /*
    Create comparison from scratch
    */
    private function setupFourthModel() : Void
    {
        // The instances must have card names be altered to fit the choice the player made
        var itemName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_selectedItemB).name;
        var instanceAData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("tic_b");
        instanceAData.abbreviatedName = "Tic's " + itemName;
        instanceAData.name = instanceAData.abbreviatedName;
        var instanceBData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue("tac_b");
        instanceBData.abbreviatedName = "Tac's " + itemName;
        instanceBData.name = instanceBData.abbreviatedName;
        
        var deckItems : Array<String> = ["tic_b", "tac_b", "difference"];
        m_gameEngine.setDeckAreaContent(deckItems, super.getBooleanList(deckItems.length, false), false);
        
        // Manually bind the numeric value for each custom instance
        var termToValueMap : Dynamic = {
            tic_b : 3,
            tac_b : 6,

        };
        m_gameEngine.getCurrentLevel().termValueToBarModelValue = termToValueMap;
        
        // Two bars with a comparison on the smaller one
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(false, "barA");
        correctBarWhole.barSegments.push(new BarSegment(Reflect.field(termToValueMap, "tac_b"), 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("tac_b", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctModel.barWholes.push(correctBarWhole);
        
        correctBarWhole = new BarWhole(false, "barB");
        correctBarWhole.barSegments.push(new BarSegment(Reflect.field(termToValueMap, "tic_b"), 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("tic_b", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctBarWhole.barComparison = new BarComparison("difference", "barA", 0);
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
        
        // Allow player to create multiple bars
        (try cast(this.getNodeById("AddNewBar"), AddNewBar) catch(e:Dynamic) null).setMaxBarsAllowed(2);
    }
    
    /*
    Create the final equation
    */
    private function setupFifthModel() : Void
    {
        var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
        modelSpecificEquationScript.addEquation("1", "tic_b=tac_b-difference", false, true);
        
        // Player just needs to click to make the plus to a subtract
        m_gameEngine.setTermAreaContent("leftTermArea", "tic_b");
        m_gameEngine.setTermAreaContent("rightTermArea", "tac_b+difference");
        
        // Hide validate button
        m_gameEngine.getUiEntity("validateButton").visible = false;
        m_validation.setIsActive(false);
    }
    
    private function redrawFirstPage() : Void
    {
        // Fill in the containers on the first page with dummy avatars
        var species : Int = AvatarSpeciesData.REPTILE;
        var earId : Int = 4;
        var avatarA : Image = m_avatarControl.createAvatarImage(
                species, earId, AvatarColors.LIGHT_GREEN, 0, 0,
                AvatarExpressions.NEUTRAL, AvatarAnimations.IDLE, 0, 200,
                new Rectangle(0, 180, 120, 200),
                Direction.EAST
                );
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var avatarContainerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById("avatar_container_a");
        avatarContainerViews[0].addChild(avatarA);
        m_temporaryTextureControl.saveImageWithId("avatar_a", avatarA);
        
        var avatarB : Image = m_avatarControl.createAvatarImage(
                species, earId, AvatarColors.LIGHT_BLUE, 0, 0,
                AvatarExpressions.NEUTRAL, AvatarAnimations.IDLE, 0, 200,
                new Rectangle(-10, 180, 100, 200),
                Direction.SOUTH
                );
        avatarContainerViews = textArea.getDocumentViewsAtPageIndexById("avatar_container_b");
        avatarContainerViews[0].addChild(avatarB);
        m_temporaryTextureControl.saveImageWithId("avatar_b", avatarB);
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    private function refreshSecondPage() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_textReplacementControl.drawDisposableTextureAtDocId(m_selectedItemA, m_temporaryTextureControl, textArea, "item_container_a", 1, -1, 100);
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    private function refreshThirdPage() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_textReplacementControl.drawDisposableTextureAtDocId(m_selectedItemB, m_temporaryTextureControl, textArea, "item_container_b", 2, -1, 100);
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    private function onSwitchModelClicked(inBarModelMode : Bool) : Void
    {
        if (inBarModelMode) 
        {
            this.getNodeById("barModelDragGestures").setIsActive(true);
            this.getNodeById("barModelClickGestures").setIsActive(true);
            this.getNodeById("BarToCard").setIsActive(false);
        }
        else 
        {
            this.getNodeById("barModelDragGestures").setIsActive(false);
            this.getNodeById("barModelClickGestures").setIsActive(false);
            this.getNodeById("BarToCard").setIsActive(true);
        }
    }
    
    /*
    Logic for hints
    */
    private var m_segmentIdToAddCalloutTo : String;
    private function showAddComparison() : Void
    {
        // Attach a callout to the second bar and offset it far to the right so it looks like it is pointing
        // to the space in the comparison.
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        var barWholes : Array<BarWhole> = barModelArea.getBarModelData().barWholes;
        var barIdForCallout : String = barWholes[1].barSegments[0].id;
        barModelArea.addOrRefreshViewFromId(barIdForCallout);
        showDialogForBaseWidget({
                    id : barIdForCallout,
                    widgetId : "barModelArea",
                    text : "Show difference.",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_DOWN,
                    width : 200,
                    height : 60,
                    animationPeriod : 1,
                    xOffset : 300,
                    yOffset : -20,

                });
        m_segmentIdToAddCalloutTo = barIdForCallout;
    }
    
    private function hideAddComparison() : Void
    {
        removeDialogForBaseWidget({
                    id : m_segmentIdToAddCalloutTo,
                    widgetId : "barModelArea",

                });
    }
    
    private function showAddFirstBarHint() : Void
    {
        showAddLabel("tic_b");
    }
    
    private function hideAddFirstBarHint() : Void
    {
        hideAddLabel("tic_b");
    }
    
    private function showAddSecondBarHint() : Void
    {
        showAddLabel("tac_b");
    }
    
    private function hideAddSecondBarHint() : Void
    {
        hideAddLabel("tac_b");
    }
    
    private function showAddSecondComparisonHint() : Void
    {
        // Get the shorter bar (tic)
        var targetId : String = null;
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        var barWholes : Array<BarWhole> = barModelArea.getBarModelData().barWholes;
        var i : Int = 0;
        for (i in 0...barWholes.length){
            var barWhole : BarWhole = barWholes[i];
            if (barWhole.barLabels.length > 0) 
            {
                if (barWhole.barLabels[0].value == "tic_b") 
                {
                    targetId = barWhole.barSegments[0].id;
                    break;
                }
            }
        }
        
        if (targetId != null) 
        {
            barModelArea.addOrRefreshViewFromId(targetId);
            m_segmentIdToAddCalloutTo = targetId;
            showDialogForBaseWidget({
                        id : targetId,
                        widgetId : "barModelArea",
                        text : "Add difference.",
                        color : 0xFFFFFF,
                        direction : Callout.DIRECTION_DOWN,
                        width : 200,
                        height : 60,
                        animationPeriod : 1,
                        xOffset : 300,

                    });
        }
    }
    
    private function hideAddSecondComparisonHint() : Void
    {
        removeDialogForBaseWidget({
                    id : m_segmentIdToAddCalloutTo,
                    widgetId : "barModelArea",

                });
    }
    
    private function showAddLabel(deckId : String) : Void
    {
        // Highlight the number in the deck and say player should drag it onto the bar below
        var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        deckArea.componentManager.addComponentToEntity(new HighlightComponent(deckId, 0xFF0000, 2));
        showDialogForBaseWidget({
                    id : deckId,
                    widgetId : "deckArea",
                    text : "Make New Box",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    width : 200,
                    height : 70,
                    animationPeriod : 1,

                });
    }
    
    private function hideAddLabel(deckId : String) : Void
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
    
    private function showSubtractionHint() : Void
    {
        // Set dialog on the subtract term telling to click on it
        var subtractTermText : String = "Difference is subtraction, click here.";
        var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var subtractTermId : String = rightTermArea.getWidgetRoot().rightChildWidget.getNode().id + "";
        showDialogForBaseWidget({
                    id : subtractTermId,
                    widgetId : "rightTermArea",
                    text : subtractTermText,
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    width : 200,
                    xOffset : -90,
                    animationPeriod : 1,

                });
    }
    
    private function hideSubtractionHint() : Void
    {
        var rightTermArea : TermAreaWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        if (rightTermArea != null) 
        {
            var subtractTermId : String = rightTermArea.getWidgetRoot().rightChildWidget.getNode().id + "";
            removeDialogForBaseWidget({
                        id : subtractTermId,
                        widgetId : "rightTermArea",

                    });
        }
    }
}
