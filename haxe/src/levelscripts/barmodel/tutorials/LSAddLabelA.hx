package levelscripts.barmodel.tutorials;


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
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.PrioritySelector;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.hints.CustomFillLogicHint;
import wordproblem.hints.HintScript;
import wordproblem.hints.scripts.HelpController;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
import wordproblem.scripts.barmodel.CustomReplaceHiddenBarLabel;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
import wordproblem.scripts.barmodel.ResetBarModelArea;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.UndoBarModelArea;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;

class LSAddLabelA extends BaseCustomLevelScript
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
    
    private var m_petOptions : Array<String>;
    private var m_treasureOptions : Array<String>;
    
    private var m_petSelected : String;
    private var m_treasureSelected : String;
    
    /*
    Hints
    */
    private var m_isBarModelSetup : Bool;
    private var m_createLabelAHint : HintScript;
    private var m_createLabelBHint : HintScript;
    private var m_createBarWithNameHint : HintScript;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
        
        super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
        
        var resizeGestures : PrioritySelector = new PrioritySelector("BarModelClickGestures");
        resizeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment", false));
        resizeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager, "RemoveHorizontalLabel", true));
        super.pushChild(resizeGestures);
        
        var prioritySelector : PrioritySelector = new PrioritySelector();
        prioritySelector.pushChild(new CustomReplaceHiddenBarLabel(gameEngine, expressionCompiler, assetManager, onCheckReplacementValid, onApplyReplacement, "CustomReplaceHiddenBarLabel"));
        prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        super.pushChild(prioritySelector);
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
        
        m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
        super.pushChild(m_validation);
        
        m_petOptions = ["unicorn", "cat", "dragon_green", "banana", "bush"];
        m_treasureOptions = ["coin", "lizard_spotted", "cheese", "butterfly", "steak"];
        
        m_isBarModelSetup = false;
        m_createLabelAHint = new CustomFillLogicHint(showCreateLabelA, null, null, null, hideCreateLabel, null, true);
        m_createLabelBHint = new CustomFillLogicHint(showCreateLabelB, null, null, null, hideCreateLabel, null, true);
        m_createBarWithNameHint = new CustomFillLogicHint(showCreateBarWithName, null, null, null, hideCreateBarWithName, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_ready) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                var labelSelected : Bool = this.getHiddenLabelId() == null;
                
                if (!labelSelected && m_hintController.getCurrentlyShownHint() != m_createLabelAHint) 
                {
                    m_hintController.manuallyShowHint(m_createLabelAHint);
                }
                else if (labelSelected && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgress() == 1 && m_isBarModelSetup) 
            {
                labelSelected = m_barModelArea.getBarModelData().barWholes.length > 0 && m_barModelArea.getBarModelData().barWholes[0].barLabels.length >= 2;
                if (!labelSelected && m_hintController.getCurrentlyShownHint() != m_createLabelBHint) 
                {
                    m_hintController.manuallyShowHint(m_createLabelBHint);
                }
                else if (labelSelected && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
            else if (m_progressControl.getProgress() == 2 && m_isBarModelSetup) 
            {
                var modelConstructed : Bool = false;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    var barWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    modelConstructed = barWhole.barLabels.length >= 2;
                }
                
                if (!modelConstructed && m_hintController.getCurrentlyShownHint() != m_createBarWithNameHint) 
                {
                    m_hintController.manuallyShowHint(m_createBarWithNameHint);
                }
                else if (modelConstructed && m_hintController.getCurrentlyShownHint() != null) 
                {
                    m_hintController.manuallyRemoveAllHints();
                }
            }
        }
        return super.visit();
    }
    
    override public function getNumCopilotProblems() : Int
    {
        return 3;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_temporaryTextureControl.dispose();
        
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        super.disablePrevNextTextButtons();
        
        m_progressControl = new ProgressControl();
        m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
        m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
        
        var slideUpPositionY : Float = m_gameEngine.getUiEntity("deckAndTermContainer").y;
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
                    m_isBarModelSetup = true;
                    setupSecondModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
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
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    m_isBarModelSetup = true;
                    setupThirdModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
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
                    pageIndex : 3

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
        
        // Special tutorial hints
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        // Bind events
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitHeight = 60;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        
        // Replace costume places
        var costumeName : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("costume"), String) catch(e:Dynamic) null;
        var contentA : FastXML = FastXML.parse("<span></span>");
        contentA.node.appendChild.innerData(costumeName);
        m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["occupation_select_a"],
                [contentA], 0);
        
        contentA = FastXML.parse("<span></span>");
        contentA.node.appendChild.innerData(costumeName);
        m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["occupation_select_b"],
                [contentA], 1);
        
        contentA = FastXML.parse("<span></span>");
        contentA.node.appendChild.innerData(costumeName);
        m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["occupation_select_c"],
                [contentA], 3);
        
        // Replace the gender places
        var gender : String = try cast(m_playerStatsAndSaveData.getPlayerDecision("gender"), String) catch(e:Dynamic) null;
        contentA = ((gender == "m")) ? FastXML.parse("<span>His</span>") : FastXML.parse("<span>Her</span>");
        m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["gender_select_a"],
                [contentA], 0);
        contentA = ((gender == "m")) ? FastXML.parse("<span>He</span>") : FastXML.parse("<span>She</span>");
        m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["gender_select_b"],
                [contentA], 1);
        
        setupFirstModel();
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                m_progressControl.incrementProgress();
                
                // Get the pet value that was selected
                var targetBarWhole : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                var barLabels : Array<BarLabel> = targetBarWhole.barLabels;
                for (barLabel in barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                    {
                        m_petSelected = barLabel.value;
                        break;
                    }
                }
                m_playerStatsAndSaveData.setPlayerDecision("pet", m_petSelected);
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the question mark on the first page
                var petName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_petSelected).name;
                var contentA : FastXML = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(petName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["pet_select_a"],
                        [contentA], 0);
                refreshFirstPage();
                
                m_isBarModelSetup = false;
                m_hintController.manuallyRemoveAllHints();
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                m_progressControl.incrementProgress();
                
                // Get the treasure value that was selected
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                barLabels = targetBarWhole.barLabels;
                for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EIdent(barLabels) type: null */ in barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                    {
                        m_treasureSelected = barLabel.value;
                        break;
                    }
                }
                m_playerStatsAndSaveData.setPlayerDecision("treasure", m_treasureSelected);
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the treasure areas
                var treasureName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_treasureSelected).name;
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(treasureName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["treasure_select_a"],
                        [contentA], 1);
                refreshSecondPage();
                
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(treasureName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["treasure_select_b", "treasure_select_c"],
                        [contentA, contentA], 3);
                
                m_isBarModelSetup = false;
                m_hintController.manuallyRemoveAllHints();
            }
            else if (m_progressControl.getProgress() == 2) 
            {
                m_progressControl.incrementProgress();
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                m_isBarModelSetup = false;
                m_hintController.manuallyRemoveAllHints();
            }
        }
        else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN) 
        {
            if (m_progressControl.getProgress() == 0) 
            {
                // Get the label with the bracket, this tells us the texture to use
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                barLabels = targetBarWhole.barLabels;
                for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EIdent(barLabels) type: null */ in barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                    {
                        break;
                    }
                }
                
                var petValue : String = barLabel.value;
                var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                var containerViews : Array<DocumentView> = textArea.getDocumentViewsByClass("pet_container");
                for (containerView in containerViews)
                {
                    var displayToUse : DisplayObject = null;
                    if (barLabel.value != "placeholder" && Lambda.indexOf(m_petOptions, barLabel.value) >= 0) 
                    {
                        var petTexture : Texture = m_temporaryTextureControl.getDisposableTexture(petValue);
                        displayToUse = new Image(petTexture);
                        containerView.removeChildren();
                        displayToUse.scaleX = displayToUse.scaleY = 120 / displayToUse.height;
                        containerView.addChild(displayToUse);
                    }
                }
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                // Get the label with the bracket, this tells us the texture to use
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                barLabels = targetBarWhole.barLabels;
                var treasureValue : String = null;
                for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EIdent(barLabels) type: null */ in barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT && barLabel.value != "placeholder") 
                    {
                        treasureValue = barLabel.value;
                        break;
                    }
                }
                textArea = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                drawSelectedTreasureOnSecondPage(textArea, treasureValue);
            }
        }
    }
    
    private function setupFirstModel() : Void
    {
        m_gameEngine.setDeckAreaContent(m_petOptions, super.getBooleanList(m_petOptions.length, false), false);
        
        // The correct model will allow for every color to be an acceptable answer
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        correctBarWhole.barSegments.push(new BarSegment(3, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("3", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctBarWhole.barLabels.push(new BarLabel("any_pet", 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
        m_validation.setTermValueAliases("any_pet", m_petOptions);
        
        // Draw initially blank bar next to segment
        var barModelData : BarModelData = m_barModelArea.getBarModelData();
        var blankBarWhole : BarWhole = new BarWhole(false);
        blankBarWhole.barSegments.push(new BarSegment(3, 1, 0xFFFFFF, null));
        blankBarWhole.barLabels.push(new BarLabel("3", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        blankBarWhole.barLabels.push(new BarLabel("placeholder", 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, "placeholder"));
        barModelData.barWholes.push(blankBarWhole);
        m_barModelArea.redraw();
        
        refreshFirstPage();
        
        (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(barModelData);
    }
    
    private function setupSecondModel() : Void
    {
        m_gameEngine.setDeckAreaContent(m_treasureOptions, super.getBooleanList(m_treasureOptions.length, false), false);
        
        // The correct model will allow for every treasure to be an acceptable answer
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        correctBarWhole.barSegments.push(new BarSegment(10, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("10", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctBarWhole.barLabels.push(new BarLabel("any_treasure", 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
        m_validation.setTermValueAliases("any_treasure", m_treasureOptions);
        
        // Draw a single segment, this time without the blank space placeholder for the label
        var barModelData : BarModelData = m_barModelArea.getBarModelData();
        var blankBarWhole : BarWhole = new BarWhole(false);
        blankBarWhole.barSegments.push(new BarSegment(10, 1, 0xFFFFFF, null));
        blankBarWhole.barLabels.push(new BarLabel("10", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        barModelData.barWholes.push(blankBarWhole);
        m_barModelArea.redraw();
        
        (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(barModelData);
    }
    
    private function setupThirdModel() : Void
    {
        var answers : Array<String> = ["2", "3", "4", "chests"];
        m_gameEngine.setDeckAreaContent(answers, super.getBooleanList(answers.length, false), false);
        
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        correctBarWhole.barSegments.push(new BarSegment(4, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("4", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctBarWhole.barLabels.push(new BarLabel("chests", 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
        
        (try cast(this.getNodeById("ResetBarModelArea"), ResetBarModelArea) catch(e:Dynamic) null).setStartingModel(null);
        
        // Allow player to delete existing part of the model
        this.getNodeById("RemoveBarSegment").setIsActive(true);
    }
    
    private function refreshFirstPage() : Void
    {
        // Get the question marks in the first page and paint them green
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
        
        var containerViews : Array<DocumentView> = textArea.getDocumentViewsByClass("pet_container");
        for (containerView in containerViews)
        {
            var displayToUse : DisplayObject = null;
            if (m_petSelected != null) 
            {
                var petTexture : Texture = m_temporaryTextureControl.getDisposableTexture(m_petSelected);
                displayToUse = new Image(petTexture);
                containerView.removeChildren();
                displayToUse.scaleX = displayToUse.scaleY = 120 / displayToUse.height;
                containerView.addChild(displayToUse);
            }
        }
    }
    
    private function refreshSecondPage() : Void
    {
        // Get the question marks in the first page and paint them green
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
        
        var petTexture : Texture = m_temporaryTextureControl.getDisposableTexture(m_petSelected);
        var petImage : Image = new Image(petTexture);
        petImage.scaleX = petImage.scaleY = 140 / petTexture.height;
        var containerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById("pet_container_a", null, 1);
        containerViews[0].removeChildren();
        containerViews[0].addChild(petImage);
        
        drawSelectedTreasureOnSecondPage(textArea, m_treasureSelected);
    }
    
    private function drawSelectedTreasureOnSecondPage(textArea : TextAreaWidget, treasureValue : String) : Void
    {
        var containerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById("treasure_container_a", null, 1);
        containerViews[0].removeChildren();
        
        if (treasureValue != null) 
        {
            var treasureTexture : Texture = m_temporaryTextureControl.getDisposableTexture(treasureValue);
            var treasureImage : Image = new Image(treasureTexture);
            treasureImage.pivotX = treasureTexture.width * 0.5;
            treasureImage.pivotY = treasureTexture.height * 0.5;
            treasureImage.scaleX = treasureImage.scaleY = 80 / treasureTexture.height;
            containerViews[0].addChild(treasureImage);
        }
    }
    
    private function onCheckReplacementValid(barLabelId : String, isVertical : Bool, dataToAdd : String) : Bool
    {
        return true;
    }
    
    private function onApplyReplacement(barLabelId : String, isVertical : Bool, dataToAdd : String, barModelData : BarModelData) : Void
    {
        // Simply replace the target label label id
        var barLabel : BarLabel = barModelData.getBarLabelById(barLabelId);
        barLabel.hiddenValue = null;
        barLabel.value = dataToAdd;
    }
    
    /*
    Hint logic
    */
    private var m_pickedId : String;
    private function showCreateLabelA() : Void
    {
        // Highlight the placeholder label
        var labelId : String = getHiddenLabelId();
        if (labelId != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(labelId);
            showDialogForBaseWidget({
                        id : labelId,
                        widgetId : "barModelArea",
                        text : "Drag here to name.",
                        color : 0xFFFFFF,
                        direction : Callout.DIRECTION_RIGHT,
                        width : 200,
                        height : 70,
                        animationPeriod : 1,

                    });
            m_pickedId = labelId;
        }
    }
    
    private function hideCreateLabel() : Void
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
    
    private function getHiddenLabelId() : String
    {
        var labelId : String = null;
        if (m_barModelArea.getBarModelData().barWholes.length > 0) 
        {
            var firstBar : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
            var barLabels : Array<BarLabel> = firstBar.barLabels;
            for (barLabel in barLabels)
            {
                if (barLabel.value == "placeholder") 
                {
                    labelId = barLabel.id;
                    break;
                }
            }
        }
        
        return labelId;
    }
    
    private function showCreateLabelB() : Void
    {
        // Create dialog on the bar segment telling to drag underneath
        var id : String;
        if (m_barModelArea.getBarModelData().barWholes.length > 0) 
        {
            var firstBar : BarWhole = m_barModelArea.getBarModelData().barWholes[0];
            if (firstBar.barSegments.length > 0) 
            {
                id = firstBar.barSegments[0].id;
            }
        }
        
        if (id != null) 
        {
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                        id : id,
                        widgetId : "barModelArea",
                        text : "Drag under box to name.",
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
    
    private function showCreateBarWithName() : Void
    {
        // Create dialog inside the bar model area
        showDialogForUi({
                    id : "barModelArea",
                    text : "Create a box with a number then put the name under it.",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_RIGHT,
                    width : 200,
                    height : 70,
                    animationPeriod : 1,
                    xOffset : -390,

                });
    }
    
    private function hideCreateBarWithName() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
}
