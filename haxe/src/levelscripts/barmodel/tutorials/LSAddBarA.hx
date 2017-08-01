package levelscripts.barmodel.tutorials;


import flash.geom.Rectangle;

import cgs.overworld.core.engine.avatar.AvatarColors;
import cgs.overworld.core.engine.avatar.body.AvatarAnimations;
import cgs.overworld.core.engine.avatar.body.AvatarExpressions;
import cgs.overworld.core.engine.avatar.data.AvatarSpeciesData;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.time.Time;

import feathers.controls.Callout;

import starling.display.Image;
import starling.textures.Texture;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.constants.Direction;
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
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.barmodel.ResetBarModelArea;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.barmodel.UndoBarModelArea;
import wordproblem.scripts.barmodel.ValidateBarModelArea;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.scripts.level.util.AvatarControl;
import wordproblem.scripts.level.util.LevelCommonUtil;
import wordproblem.scripts.level.util.ProgressControl;
import wordproblem.scripts.level.util.TemporaryTextureControl;
import wordproblem.scripts.level.util.TextReplacementControl;

class LSAddBarA extends BaseCustomLevelScript
{
    private var m_avatarControl : AvatarControl;
    private var m_progressControl : ProgressControl;
    private var m_textReplacementControl : TextReplacementControl;
    private var m_temporaryTextureControl : TemporaryTextureControl;
    
    /**
     * Script controlling correctness of bar models
     */
    private var m_validation : ValidateBarModelArea;
    private var m_barModelArea : BarModelAreaWidget;
    private var m_hintController : HelpController;
    private var m_levelTimer : Time;
    
    /*
    Default Settings for the player's avatar
    */
    private var m_avatarSpecies : Int = AvatarSpeciesData.ALIEN;
    private var m_avatarColor : Int = AvatarColors.WHITE;
    private inline var m_avatarEarId : Int = 1;
    
    /*
    Options selected by the player
    */
    private var m_color : String = "start";
    private var m_costume : String = "none";
    private var m_food : String;
    private var m_gender : String = "f";
    
    /*
    Hints
    */
    private var m_isBarModelSetup : Bool;
    private var m_pickAnyHint : HintScript;
    private var m_submitAnswerHint : HintScript;
    private var m_pickNumberHint : HintScript;
    
    private var m_foodValueToSingularFormName : Dynamic = {
            snail : "snail",
            rock : "rock",
            adventurer : "adventurer",

        };
    
    private var m_colorValueToAvatarColor : Dynamic = {
            red : AvatarColors.RED,
            orange : AvatarColors.ORANGE,
            yellow : AvatarColors.YELLOW,
            green : AvatarColors.DARK_GREEN,
            blue : AvatarColors.DARK_BLUE,
            purple : AvatarColors.PURPLE,
            start : AvatarColors.WHITE,

        };
    
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
        var prioritySelector : PrioritySelector = new PrioritySelector();
        prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar", true, customAddBarFunction));
        prioritySelector.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager));
        prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
        super.pushChild(prioritySelector);
        super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
        super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
        
        m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
        super.pushChild(m_validation);
        
        m_levelTimer = new Time();
        m_isBarModelSetup = false;
        m_pickAnyHint = new CustomFillLogicHint(showPickAny, null, null, null, hidePickAny, null, true);
        m_submitAnswerHint = new CustomFillLogicHint(showSubmitAnswer, null, null, null, hideSubmitAnswer, null, true);
        m_pickNumberHint = new CustomFillLogicHint(showPickRightNumber, null, null, null, hidePickRightNumber, null, true);
    }
    
    override public function visit() : Int
    {
        if (m_progressControl.getProgress() == 0) 
        {
            m_levelTimer.update();
            var answerPicked : Bool = m_barModelArea.getBarModelData().barWholes.length > 0;
            if (!answerPicked && m_hintController.getCurrentlyShownHint() != m_pickAnyHint) 
            {
                m_hintController.manuallyShowHint(m_pickAnyHint);
            }
            else if (answerPicked && m_hintController.getCurrentlyShownHint() != m_submitAnswerHint) 
            {
                m_hintController.manuallyShowHint(m_submitAnswerHint);
            }
        }
        else if (m_progressControl.getProgress() == 4 && m_isBarModelSetup) 
        {
            answerPicked = m_barModelArea.getBarModelData().barWholes.length > 0;
            if (!answerPicked && m_hintController.getCurrentlyShownHint() != m_pickNumberHint) 
            {
                m_hintController.manuallyShowHint(m_pickNumberHint);
            }
            else if (answerPicked && m_hintController.getCurrentlyShownHint() != m_submitAnswerHint) 
            {
                m_hintController.manuallyShowHint(m_submitAnswerHint);
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
        m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
        
        m_avatarControl.dispose();
        m_temporaryTextureControl.dispose();
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
        
        var slideUpPositionY : Float = m_gameEngine.getUiEntity("deckAndTermContainer").y;
        var sequenceSelector : SequenceSelector = new SequenceSelector();
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
        
        // After this character is set
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
        
        // Setup food model
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    refreshSecondPage();
                    setupGenderSelectModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
        sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 4));
        
        // After this food is set
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
        
        // Setup final pick number part
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    time : 0.3,
                    y : slideUpPositionY,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(
                function(param : Dynamic) : Int
                {
                    refreshThirdPage();
                    m_isBarModelSetup = true;
                    setupFourthModel();
                    return ScriptStatus.SUCCESS;
                }, null));
        
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
        var hintController : HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, 
        "HintController", false);
        super.pushChild(hintController);
        hintController.overrideLevelReady();
        m_hintController = hintController;
        
        setupColorSelectModel();
        refreshFirstPage();
        
        // Bind events
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
        
        m_barModelArea = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_barModelArea.unitHeight = 60;
        m_barModelArea.unitLength = 300;
        m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
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
                m_color = targetBarWhole.barLabels[0].value;
                m_playerStatsAndSaveData.setPlayerDecision("color", m_color);
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the question mark on the first page
                var contentA : FastXML = FastXML.parse("<span></span>");
                contentA.node.appendChild.innerData(m_color);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["color_select_a"],
                        [contentA], 0);
                refreshFirstPage();
                
                setupOccupationSelectModel();
                
                m_hintController.manuallyRemoveAllHints();
            }
            else if (m_progressControl.getProgress() == 1) 
            {
                m_progressControl.incrementProgress();
                
                // Get the costume that was selected
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_costume = targetBarWhole.barLabels[0].value;
                m_playerStatsAndSaveData.setPlayerDecision("costume", m_costume);
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the question mark on the first page
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(m_costume);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["occupation_select_a"],
                        [contentA], 0);
                refreshFirstPage();
            }
            else if (m_progressControl.getProgress() == 2) 
            {
                m_progressControl.incrementProgress();
                
                // Get the gender selected
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_gender = targetBarWhole.barLabels[0].value;
                m_playerStatsAndSaveData.setPlayerDecision("gender", m_gender);
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the question mark on the second page
                contentA = ((m_gender == "m")) ? FastXML.parse("<span>He</span>") : FastXML.parse("<span>She</span>");
                contentB = ((m_gender == "m")) ? FastXML.parse("<span>his</span>") : FastXML.parse("<span>her</span>");
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["gender_select_a", "gender_select_c", "gender_select_b", "gender_select_d"],
                        [contentA, contentA, contentB, contentB], 1);
                refreshSecondPage();
                
                // Can immediately replace other parts too
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["gender_select_e"],
                        [contentA], 2);
                
                // Choose food next
                setupFoodSelectModel();
            }
            else if (m_progressControl.getProgress() == 3) 
            {
                m_progressControl.incrementProgress();
                
                // Get the food that was selected
                targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                m_food = targetBarWhole.barLabels[0].value;
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the question mark on the second page
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_food).name);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["food_select_a", "food_select_b"],
                        [contentA, contentA], 1);
                refreshSecondPage();
                
                setDocumentIdVisible({
                            id : "hidden_a",
                            visible : true,

                        });
                
                // Can immediately replace parts of the last page
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(m_color);
                var contentB : FastXML = FastXML.parse("<span></span>");
                contentB.node.appendChild.innerData(m_costume);
                
                // Food name is used as an adjective in one part, so it needs to be in singular form
                var foodName : String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_food).name;
                if (m_foodValueToSingularFormName.exists(m_food)) 
                {
                    foodName = Reflect.field(m_foodValueToSingularFormName, m_food);
                }
                
                var contentC : FastXML = FastXML.parse("<span></span>");
                contentC.node.appendChild.innerData(foodName);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["color_select_b", "occupation_select_b", "food_select_c"],
                        [contentA, contentB, contentC], 3);
            }
            else if (m_progressControl.getProgress() == 4) 
            {
                m_progressControl.incrementProgress();
                
                // Clear the bar model
                (try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null).resetHistory();
                m_barModelArea.getBarModelData().clear();
                m_barModelArea.redraw();
                
                // Replace the question mark on the third page
                contentA = FastXML.parse("<span></span>");
                contentA.appendChild(4 + "");
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["number_select_a"],
                        [contentA], 2);
                refreshThirdPage();
                
                // Disable the gestures since level is finished here
                m_hintController.manuallyRemoveAllHints();
            }
        }
        else if (eventType == GameEvent.BAR_MODEL_INCORRECT) 
        {
            if (m_progressControl.getProgress() == 1) 
                { }
        }
        else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN) 
        {
            // Recolor the avatar
            if (m_progressControl.getProgress() == 0) 
            {
                var targetColor : String = "start";
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    targetColor = targetBarWhole.barLabels[0].value;
                }  // Text needs to change depending on color  
                
                
                
                contentA = FastXML.parse("<span></span>");
                var aOrAn : String = ((targetColor == "orange")) ? "an" : "a";
                contentA.appendChild(aOrAn);
                m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(["a_or_an"],
                        [contentA], 0);
                refreshFirstPage();
                
                // Make sure the character is redrawn with the right color
                var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                var avatarContainerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById("avatar_container_a");
                avatarContainerViews[0].removeChildren();
                
                var newAvatarWithColor : Image = m_temporaryTextureControl.getImageWithId(targetColor);
                if (newAvatarWithColor == null) 
                {
                    newAvatarWithColor = m_avatarControl.createAvatarImage(
                                    m_avatarSpecies, m_avatarEarId, Reflect.field(m_colorValueToAvatarColor, targetColor), 0, 0,
                                    AvatarExpressions.NEUTRAL, AvatarAnimations.IDLE, 0, 200,
                                    new Rectangle(-10, 185, 105, 205),
                                    Direction.SOUTH
                                    );
                    m_temporaryTextureControl.saveImageWithId(targetColor, newAvatarWithColor);
                }
                
                avatarContainerViews[0].addChild(newAvatarWithColor);
            }
            // Re-add costume to the avatar
            else if (m_progressControl.getProgress() == 1) 
            {
                var targetCostume : String = "none";
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    targetCostume = targetBarWhole.barLabels[0].value;
                }
                
                var newAvatarWithCostume : Image = m_temporaryTextureControl.getImageWithId(targetCostume);
                if (newAvatarWithCostume == null) 
                {
                    newAvatarWithCostume = m_avatarControl.createAvatarImage(
                                    m_avatarSpecies, m_avatarEarId, Reflect.field(m_colorValueToAvatarColor, m_color),
                                    m_avatarControl.getHatIdForCostumeId(targetCostume),
                                    m_avatarControl.getShirtIdForCostumeId(targetCostume),
                                    AvatarExpressions.NEUTRAL, AvatarAnimations.IDLE, 0, 200,
                                    new Rectangle(-10, 185, 105, 205),
                                    Direction.SOUTH
                                    );
                    m_temporaryTextureControl.saveImageWithId(targetCostume, newAvatarWithCostume);
                }
                
                textArea = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                avatarContainerViews = textArea.getDocumentViewsAtPageIndexById("avatar_container_a");
                avatarContainerViews[0].removeChildren();
                avatarContainerViews[0].addChild(newAvatarWithCostume);
            }
            else if (m_progressControl.getProgress() == 3) 
            {
                var targetFoodValue : String = null;
                if (m_barModelArea.getBarModelData().barWholes.length > 0) 
                {
                    targetBarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    targetFoodValue = targetBarWhole.barLabels[0].value;
                }
                
                textArea = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
                drawFoodOntoSecondPage(textArea, targetFoodValue);
            }
        }
    }
    
    private function setupColorSelectModel() : Void
    {
        // Set the deck to have colors
        var characterColors : Array<String> = ["red", "orange", "yellow", "blue", "green", "purple"];
        m_gameEngine.setDeckAreaContent(characterColors, super.getBooleanList(characterColors.length, false), false);
        
        // The correct model will allow for every occupation to be right
        LevelCommonUtil.setReferenceBarModelForPickem("a_color", "color", characterColors, m_validation);
    }
    
    private function setupOccupationSelectModel() : Void
    {
        var characterClasses : Array<String> = ["zombie", "ninja", "superhero", "fairy", "mummy"];
        m_gameEngine.setDeckAreaContent(characterClasses, super.getBooleanList(characterClasses.length, false), false);
        
        // The correct model will allow for every occupation to be right
        LevelCommonUtil.setReferenceBarModelForPickem("an_occupation", "character", characterClasses, m_validation);
    }
    
    private function setupGenderSelectModel() : Void
    {
        var genders : Array<String> = ["m", "f"];
        m_gameEngine.setDeckAreaContent(genders, super.getBooleanList(genders.length, false), false);
        
        LevelCommonUtil.setReferenceBarModelForPickem("a_gender", null, genders, m_validation);
    }
    
    private function setupFoodSelectModel() : Void
    {
        var foods : Array<String> = ["broccoli", "candy", "snail", "rock", "adventurer"];
        m_gameEngine.setDeckAreaContent(foods, super.getBooleanList(foods.length, false), false);
        
        // The correct model will allow for every choice to be right
        LevelCommonUtil.setReferenceBarModelForPickem("a_food", "favorite", foods, m_validation);
    }
    
    private function setupFourthModel() : Void
    {
        var answers : Array<String> = ["2", "3", "4"];
        m_gameEngine.setDeckAreaContent(answers, super.getBooleanList(answers.length, false), false);
        
        m_barModelArea.unitLength = 100;
        
        // Create a new variable that represents a total of the food option they had picked earlier.
        var referenceBarModels : Array<BarModelData> = new Array<BarModelData>();
        var correctModel : BarModelData = new BarModelData();
        var correctBarWhole : BarWhole = new BarWhole(true);
        correctBarWhole.barSegments.push(new BarSegment(4, 1, 0, null));
        correctBarWhole.barLabels.push(new BarLabel("4", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        correctBarWhole.barLabels.push(new BarLabel("a_food", 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        correctModel.barWholes.push(correctBarWhole);
        referenceBarModels.push(correctModel);
        
        m_validation.setReferenceModels(referenceBarModels);
    }
    
    private function customAddBarFunction(barWholes : Array<BarWhole>,
            data : String,
            color : Int,
            labelOnTopValue : String,
            id : String = null) : Void
    {
        var value : Float = parseInt(data);
        
        // Any non numeric cards default to a unit of 1
        // (This value can be set in the extra data field of a level file)
        var targetNumeratorValue : Float = 1;
        var targetDenominatorValue : Float = 1;
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        if (!Math.isNaN(value)) 
        {
            // Possible the value is negative, right now don't have this affect the ratio
            targetNumeratorValue = Math.abs(value);
            targetDenominatorValue = barModelArea.normalizingFactor;
        }
        
        var newBarWhole : BarWhole = new BarWhole(true, id);
        
        var newBarSegment : BarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, color, null);
        newBarWhole.barSegments.push(newBarSegment);
        
        // Add a label for potions and make sure the number of potion images matches the numeric value of the bar
        var newBarLabel : BarLabel = new BarLabel(data, 0, 0, true, false, BarLabel.BRACKET_NONE, null);
        newBarLabel.numImages = value;
        newBarWhole.barLabels.push(newBarLabel);
        
        var newLabelValue : String = null;
        if (m_progressControl.getProgress() == 0) 
        {
            newLabelValue = "color";
        }
        else if (m_progressControl.getProgress() == 1) 
        {
            newLabelValue = "character";
        }
        else if (m_progressControl.getProgress() == 3) 
        {
            newLabelValue = "favorite";
        }
        else if (m_progressControl.getProgress() == 4) 
        {
            newLabelValue = m_food;
        }
        
        if (newLabelValue != null) 
        {
            newBarWhole.barLabels.push(new BarLabel(newLabelValue, 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null));
        }
        
        barWholes.push(newBarWhole);
    }
    
    /**
     * Function to apply dynamic changes to the first page after it has been redrawn.
     * (MUST be called after every redraw because those changes get tossed out)
     */
    private function refreshFirstPage() : Void
    {
        // Grab the placeholder for the avatar and inject a blank character
        var avatarColor : Int = Reflect.field(m_colorValueToAvatarColor, m_color);
        var hatId : Int = m_avatarControl.getHatIdForCostumeId(m_costume);
        var shirtId : Int = m_avatarControl.getShirtIdForCostumeId(m_costume);
        var startingAvatar : Image = m_avatarControl.createAvatarImage(
                m_avatarSpecies, m_avatarEarId, avatarColor, hatId, shirtId,
                AvatarExpressions.NEUTRAL, AvatarAnimations.IDLE, 0, 200,
                new Rectangle(-10, 185, 105, 205),
                Direction.SOUTH
                );
        m_temporaryTextureControl.saveImageWithId("start", startingAvatar);
        
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var avatarContainerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById("avatar_container_a");
        avatarContainerViews[0].addChild(startingAvatar);
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    /**
     * Function to apply dynamic changes to the second page after it has been redrawn.
     */
    private function refreshSecondPage() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        drawFoodOntoSecondPage(textArea, m_food);
        
        // Create right facing avatar
        var avatar : Image = m_temporaryTextureControl.getImageWithId("right_facing_avatar");
        if (avatar == null) 
        {
            var avatarColor : Int = Reflect.field(m_colorValueToAvatarColor, m_color);
            var hatId : Int = m_avatarControl.getHatIdForCostumeId(m_costume);
            var shirtId : Int = m_avatarControl.getShirtIdForCostumeId(m_costume);
            avatar = m_avatarControl.createAvatarImage(
                            m_avatarSpecies, m_avatarEarId, avatarColor, hatId, shirtId,
                            AvatarExpressions.HAPPY, AvatarAnimations.IDLE, 0, 200,
                            new Rectangle(-10, 185, 105, 205),
                            Direction.EAST
                            );
            m_temporaryTextureControl.saveImageWithId("right_facing_avatar", avatar);
        }
        var containerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById("avatar_container_b", null, 1);
        containerViews[0].removeChildren();
        containerViews[0].addChild(avatar);
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    private function drawFoodOntoSecondPage(textArea : TextAreaWidget, foodValue : String) : Void
    {
        // Figure out the texture of the food item to use
        m_textReplacementControl.drawDisposableTextureAtDocId(foodValue, m_temporaryTextureControl, textArea,
                "food_container_a", 1, -1, 120);
    }
    
    private function refreshThirdPage() : Void
    {
        // Figure out the texture of the food item to use and draw multiple copies to paste on the page
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var containerViews : Array<DocumentView> = textArea.getDocumentViewsByClass("food", null, 2);
        var i : Int = 0;
        for (i in 0...containerViews.length){
            // Create image of the food
            var foodTexture : Texture = m_temporaryTextureControl.getDisposableTexture(m_food);
            var foodImage : Image = new Image(foodTexture);
            foodImage.pivotX = foodTexture.width * 0.5;
            foodImage.pivotY = foodTexture.height * 0.5;
            foodImage.scaleX = foodImage.scaleY = 60 / foodTexture.height;
            containerViews[i].addChild(foodImage);
        }
        
        m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
    }
    
    /*
    Logic for hints
    */
    private function showPickAny() : Void
    {
        // Highlight the deck
        showDialogForUi({
                    id : "deckArea",
                    text : "Pick Any.",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_UP,
                    width : 150,
                    height : 50,
                    animationPeriod : 1,

                });
        
        // Highlight the bar model area
        showDialogForUi({
                    id : "barModelArea",
                    text : "Drag into here!",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_RIGHT,
                    width : 150,
                    height : 50,
                    animationPeriod : 1,
                    xOffset : -390,

                });
    }
    
    private function hidePickAny() : Void
    {
        removeDialogForUi({
                    id : "deckArea"

                });
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
    
    private function showSubmitAnswer() : Void
    {
        // Highlight the validate button
        showDialogForUi({
                    id : "validateButton",
                    text : "Click when done.",
                    color : 0xFFFFFF,
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
    
    private function showPickRightNumber() : Void
    {
        // Highlight the deck
        showDialogForUi({
                    id : "barModelArea",
                    text : "Pick the CORRECT number.",
                    color : 0xFFFFFF,
                    direction : Callout.DIRECTION_RIGHT,
                    width : 200,
                    height : 50,
                    animationPeriod : 1,
                    xOffset : -350,

                });
    }
    
    private function hidePickRightNumber() : Void
    {
        removeDialogForUi({
                    id : "barModelArea"

                });
    }
}
