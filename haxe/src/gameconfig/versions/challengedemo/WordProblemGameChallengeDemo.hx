package gameconfig.versions.challengedemo;

import gameconfig.versions.challengedemo.WordProblemGameChallengeDemoLogin;

import cgs.cache.ICgsUserCache;
import cgs.levelprogression.nodes.ICgsLevelNode;
import cgs.server.responses.CgsUserResponse;
import cgs.user.CgsUserProperties;
import cgs.user.ICgsUser;

import dragonbox.common.console.expression.MethodExpression;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IState;

import levelscripts.barmodel.tutorialsv2.TutorialV2Util;

import starling.animation.Juggler;
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.events.Event;
import starling.events.KeyboardEvent;

import wordproblem.WordProblemGameBase;
import wordproblem.achievements.PlayerAchievementsModel;
import wordproblem.achievements.scripts.UpdateAndSaveAchievements;
import wordproblem.copilot.AlgebraAdventureCopilotService;
import wordproblem.creator.ProblemCreateData;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.currency.PlayerCurrencyModel;
import wordproblem.currency.scripts.CurrencyAwardedScript;
import wordproblem.engine.component.CurrentGrowInStageComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.text.TextParser;
import wordproblem.event.CommandEvent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.LevelNodeCompletionValues;
import wordproblem.level.LevelNodeSaveKeys;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.level.nodes.WordProblemLevelLeaf;
import wordproblem.level.nodes.WordProblemLevelPack;
import wordproblem.levelselect.scripts.DrawItemsOnShelves;
import wordproblem.player.ButtonColorData;
import wordproblem.player.ChangeButtonColorScript;
import wordproblem.player.ChangeCursorScript;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.player.UpdateAndSavePlayerStatsAndDataScript;
import wordproblem.playercollections.PlayerCollectionsState;
import wordproblem.saves.DummyCache;
import wordproblem.saves.RepairSaveData;
import wordproblem.scripts.items.BaseAdvanceItemStageScript;
import wordproblem.scripts.items.BaseGiveRewardScript;
import wordproblem.scripts.items.BaseRevealItemScript;
import wordproblem.scripts.items.DefaultGiveRewardScript;
import wordproblem.scripts.level.save.UpdateAndSaveLevelDataScript;
import wordproblem.scripts.performance.PerformanceAndStatsScript;
import wordproblem.scripts.state.GameStateNavigationDefault;
import wordproblem.state.CopilotScreenState;
import wordproblem.state.WordProblemGameState;
import wordproblem.state.WordProblemLoadingState;
import wordproblem.state.WordProblemSelectState;
import wordproblem.summary.scripts.SummaryScript;
import wordproblem.xp.PlayerXpModel;
import wordproblem.xp.scripts.RevisedPlayerXPScript;

/**
 * Main application for challenge type events using the word problem game.
 */
class WordProblemGameChallengeDemo extends WordProblemGameBase
{
    /*
    AB Testing names
    */
    private static inline var AB_VAR_POL_ITEMS : String = "pol";
    private static inline var AB_VAR_DONGSHENG_ITEMS : String = "dongsheng";
    private static inline var AB_VAR_CUSTOM_HINTS : String = "customhints";
    private static inline var POL_ITEMS_DEFAULT : String = "a";
    private static inline var DONSHENG_ITEMS_DEFAULT : String = "a";
    
    // For now the top level class is the best place to append the loading of game specific data, which for now
    // deals mostly with data related to the inventory. From here it can be passed to any other screen that needs
    // to read or modify it during runtime.
    /**
     * Keep track of properties of all game world item (not player specific so does not need to be 
     * reset for different players)
     */
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * Keep track of items specifically belonging to a player. (needs to be reset when different players come in)
     */
    private var m_playerItemInventory : ItemInventory;
    
    /**
     * This is the data representation of the experience that the player gains during a
     * playthrough of the game.
     */
    private var m_playerXpModel : PlayerXpModel;
    
    // HACK: On authenticate split up code/objects that only need to run once
    // and ones that need to reset
    private var m_setUpClassAlready : Bool = false;
    
    /**
     * Main animation player
     */
    private var m_mainJuggler : Juggler;
    
    private var m_playerCurrencyModel : PlayerCurrencyModel;
    
    /**
     * Game specific Copilot Service, for running Copilot related functions and relaying messages.
     */
    private var m_algebraAdventureCopilotService : AlgebraAdventureCopilotService;
    
    public function new()
    {
        super();
        
        m_mainJuggler = new Juggler();
    }
    
    override public function getSupportedMethods() : Array<String>
    {
        var methods : Array<String> = super.getSupportedMethods();
        methods.push("addCoins");
        
        return methods;
    }
    
    override public function invoke(methodExpression : MethodExpression) : Void
    {
        super.invoke(methodExpression);
        
        var alias : String = methodExpression.methodAlias;
        var args : Array<String> = methodExpression.arguments;
        switch (alias)
        {
            case "updateItemStage":
                var entityId : String = args[0];
                var newStatus : Int = parseInt(args[1]);
                var currentStageComponent : CurrentGrowInStageComponent = try cast(m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        CurrentGrowInStageComponent.TYPE_ID
                        ), CurrentGrowInStageComponent) catch(e:Dynamic) null;
                currentStageComponent.currentStage = newStatus;
                var renderComponent : RenderableComponent = try cast(m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                renderComponent.renderStatus = newStatus;
            case "getEggs":
                var giveRewardScript : BaseGiveRewardScript = try cast(m_fixedGlobalScript.getNodeById("GiveRewardScript"), BaseGiveRewardScript) catch(e:Dynamic) null;
                giveRewardScript.giveRewardFromEntityId("egg_collection");
            case "unlock":
                m_levelManager.doCheckLocks = (args[0] == "false");
                m_stateMachine.changeState(WordProblemSelectState);
            case "addCoins":
                m_playerCurrencyModel.totalCoins += 1000;
        }
    }
    
    override private function onStartingResourcesLoaded() : Void
    {
        // HACK: Teacher version of the game should have a special keyboard cheat to
        // unlock all the levels
        if (m_config.getEnableUnlockLevelsShortcut()) 
        {
            m_containerStage.addEventListener(KeyboardEvent.KEY_DOWN, function(event : KeyboardEvent) : Void
                    {
                        // Ctrl+C will unlock the game
                        if (event.keyCode == 67 && event.ctrlKey) 
                        {
                            m_levelManager.doCheckLocks = false;
                            m_stateMachine.changeState(WordProblemSelectState);
                        }
                    });
        }
        
        m_levelManager = new WordProblemCgsLevelManager(
                m_logger.getCgsApi().userManager, 
                m_assetManager, 
                onStartLevel, 
                onNoNextLevel, 
                !m_config.unlockAllLevels, 
                );
        
        // For the challenge, a login might be required
        // Depending on whether the link is played independently at home.
        // to detect this will need to look at the url.
        // On real release this should be eliminated and replaced with a regular waiting screen
        var loginScreen : BaseState = null;
        if (m_config.debugNoServerLogin) 
        {
            loginScreen = new WordProblemGameChallengeDemoLogin(m_stateMachine, 
                    m_assetManager, m_config.getTeacherCode(), m_config.getSaveDataKey(), m_config.getSaveDataToServer(), m_logger, m_nativeFlashStage, null, 
                    );
        }
        else 
        {
            loginScreen = new CopilotScreenState(m_stateMachine, m_assetManager);
        }
        
        loginScreen.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
        loginScreen.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
        loginScreen.addEventListener(CommandEvent.USER_AUTHENTICATED, function(event : Event, params : Dynamic) : Void
                {
                    if (params != null && params.exists("grade")) 
                    {
                        var userGrade : Int = Reflect.field(params, "grade");
                        if (!m_setUpClassAlready) 
                        {
                            setUpGameForFirstTime(userGrade);
                            m_setUpClassAlready = true;
                        }
                        m_levelManager.goToNextLevel();
                    }
                });
        
        m_stateMachine.register(loginScreen);
        
        // Automatically go to the problem selection state
        m_stateMachine.changeState(loginScreen);
        
        // Start up the copilot
        var copilotProps : CgsUserProperties = m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey());
        copilotProps.completeCallback = function userPropsCompleteCallbackForCopilot(userResponse : CgsUserResponse) : Void
                {
                    // Register user
                    if (userResponse.success) 
                    {
                        // For the copilot, we will wait for the activity start event before doing game setup
                        
                    }
                };
        m_algebraAdventureCopilotService = new AlgebraAdventureCopilotService(
                m_logger.getCgsApi(), 
                copilotProps, 
                this, 
                m_levelManager, 
                m_logger, 
                onCopilotActivityStart, 
                );
        m_algebraAdventureCopilotService.applicationReady();
    }
    
    /*
    HACK: Grade is coming in on an activity start. This bit of information is required to configure the game so we
    must wait for that signal rather than the user authentication.
    */
    
    /**
     * 
     * @param userGrade
     *      If -1, then grade for that user is kept unspecified
     */
    private function setUpGameForFirstTime(userGrade : Int) : Void
    {
        // The cache saves user data either locally or on the servers
        var cache : ICgsUserCache = null;
        if (m_logger.getCgsUser() != null) 
        {
            cache = m_logger.getCgsUser();
        }
        else 
        {
            cache = new DummyCache();
        }  // Load up the save data for the player  
        
        
        
        var defaultDecisions : Dynamic = {
            color : "red",
            job : TutorialV2Util.JOB_BASKETBALL_PLAYER,
            gender : "m",

        };
        m_playerStatsAndSaveData = new PlayerStatsAndSaveData(cache, defaultDecisions);
        
        //Todo: should eventually  be a/b tested
        m_playerStatsAndSaveData.useCustomHints = true;
        
        // Load up the amount of experience points earned by the player
        m_playerXpModel = new PlayerXpModel(cache);
        
        var playerCurrencyModel : PlayerCurrencyModel = new PlayerCurrencyModel(cache);
        m_playerCurrencyModel = playerCurrencyModel;
        
        // Set up parsers for scripts and text
        m_scriptParser = new ScriptParser(gameEngine, m_expressionCompiler, m_assetManager, m_playerStatsAndSaveData, m_levelManager);
        m_textParser = new TextParser();
        
        // Read in definitions for all items
        var rawItemData : Dynamic = m_assetManager.getObject("items_db");
        var itemDataSource : ItemDataSource = new ItemDataSource(Reflect.field(rawItemData, "items"));
        m_itemDataSource = itemDataSource;
        
        // Read initial items to be given to a player
        // (mostly for debugging purposes as the reward script can figure out from level progress
        // which rewards were given and at what stage the rewards should be in)
        var gameItemsData : Dynamic = m_assetManager.getObject("game_items");
        
        // From a data file populate initial items that belong to player.
        // First step is to create initial data structures for each 'item'
        // Second step is to update those data structures with the progress
        var playerItemInventory : ItemInventory = new ItemInventory(m_itemDataSource, cache);
        playerItemInventory.loadInitialItems(gameItemsData.playerItems);
        m_playerItemInventory = playerItemInventory;
        
        var playerAchievementsDataSource : Dynamic = m_assetManager.getObject("achievements");
        var playerAchievementsModel : PlayerAchievementsModel = new PlayerAchievementsModel(playerAchievementsDataSource);
        
        // The grade selected by the user in the login screen will determine the sequence to use
        if (userGrade < 0) 
        {
            userGrade = 4;
        }
        
        var levelSequenceNameToUse : String = "sequence_grade_7_up";
        if (userGrade <= 2) 
        {
            levelSequenceNameToUse = "sequence_grade_2_under";
        }
        else if (userGrade <= 4) 
        {
            levelSequenceNameToUse = "sequence_grade_3_4";
        }
        else if (userGrade <= 6) 
        {
            levelSequenceNameToUse = "sequence_grade_5_6";
        }
        m_importantNodeNamesForUser = getImportantNodeNamesInSequence(userGrade);
        
        var masteryToNodeNameMap : Dynamic = { };
        if (userGrade <= 4) 
        {
            Reflect.setField(masteryToNodeNameMap, "1", "addition_full_equation");
            Reflect.setField(masteryToNodeNameMap, "2", "multipart_subtraction");
            Reflect.setField(masteryToNodeNameMap, "3", "multiply_unknown_group");
        }
        else 
        {
            Reflect.setField(masteryToNodeNameMap, "1", "addition_unknown_total");
            Reflect.setField(masteryToNodeNameMap, "2", "multipart_subtraction");
            Reflect.setField(masteryToNodeNameMap, "3", "multiply_unknown_group");
        }
        
        Reflect.setField(masteryToNodeNameMap, "4", "multiply_multi_operator");
        Reflect.setField(masteryToNodeNameMap, "5", "two_step_groups_mixed");
        Reflect.setField(masteryToNodeNameMap, "6", "basic_fractions_c");
        Reflect.setField(masteryToNodeNameMap, "7", "advanced_fractions_d");
        
        // TODO: Only for testing
        //levelSequenceNameToUse = "sequence_grade_all";
        
        m_levelManager.setToNewLevelProgression(levelSequenceNameToUse, cache, preprocessLevels);
        
        // Non-persistent storage of the color of buttons selected by the user
        var buttonColorData : ButtonColorData = m_playerStatsAndSaveData.buttonColorData;
        var changeButtonColorScript : ChangeButtonColorScript = new ChangeButtonColorScript(buttonColorData, playerItemInventory, itemDataSource);
        
        // The selection state has a reference to available levels to play.
        // Note is does not have access to the actual level data
        var wordProblemSelectState : WordProblemSelectState = new WordProblemSelectState(
        m_stateMachine, 
        m_config, 
        m_levelManager, 
        m_assetManager, 
        m_playerItemInventory, 
        m_itemDataSource, 
        m_logger, 
        m_nativeFlashStage, 
        buttonColorData, 
        );
        wordProblemSelectState.addEventListener(CommandEvent.GO_TO_LEVEL, onGoToLevel);
        wordProblemSelectState.addEventListener(CommandEvent.SIGN_OUT, onSignOut);
        wordProblemSelectState.addEventListener(CommandEvent.RESET_DATA, onResetData);
        wordProblemSelectState.addEventListener(CommandEvent.GO_TO_PLAYER_COLLECTIONS, onGoToPlayerCollections);
        m_stateMachine.register(wordProblemSelectState);
        
        // Initialize all the objects related to the game state
        // As it also has a dependency on the fixed set of items belonging to the player,
        // which can only be fetched after some authentication phase.
        var wordProblemGameState : WordProblemGameState = new WordProblemGameState(
        m_stateMachine, 
        gameEngine, 
        m_assetManager, 
        m_expressionCompiler, 
        m_expressionSymbolMap, 
        m_config, 
        m_console, 
        buttonColorData, 
        m_levelManager, 
        );
        wordProblemGameState.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
        wordProblemGameState.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
        m_stateMachine.register(wordProblemGameState);
        
        var wordProblemCreateState : WordProblemCreateState = new WordProblemCreateState(
        m_stateMachine, 
        m_nativeFlashStage, 
        m_mouseState, 
        m_assetManager, 
        m_gameServerRequester, 
        m_levelCompiler, 
        m_config, 
        m_playerStatsAndSaveData, 
        buttonColorData);
        wordProblemCreateState.addEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, function() : Void
                {
                    m_stateMachine.changeState(WordProblemSelectState);
                });
        m_stateMachine.register(wordProblemCreateState);
        
        var playerCollectionState : PlayerCollectionsState = new PlayerCollectionsState(
        m_stateMachine, 
        m_assetManager, 
        m_mouseState, 
        m_levelManager, 
        m_playerXpModel, 
        playerCurrencyModel, 
        playerAchievementsModel, 
        m_itemDataSource, 
        m_playerItemInventory, 
        gameItemsData.types, 
        gameItemsData.customizables, 
        m_playerStatsAndSaveData, 
        try cast(m_fixedGlobalScript.getNodeById("ChangeCursorScript"), ChangeCursorScript) catch(e:Dynamic) null, 
        changeButtonColorScript, function() : Void
        {
            if (m_config.allowLevelSelect) 
            {
                m_stateMachine.changeState(WordProblemSelectState);
            }
            else 
            {
                // Return to the last played level
                m_levelManager.goToNextLevel();
            }
        }, 
        buttonColorData, 
        );
        m_stateMachine.register(playerCollectionState);
        
        // Link logging events to game engine
        m_logger.setGameEngine(gameEngine, wordProblemGameState);
        
        m_fixedGlobalScript.pushChild(new DrawItemsOnShelves(
                wordProblemSelectState, 
                m_playerItemInventory, 
                m_itemDataSource, 
                m_assetManager, 
                m_mainJuggler, 
                ));
        
        // Add scripts that have logic that operate across several levels.
        // This deals with things like handing out rewards or modifying rewards
        // We need to make sure the reward script comes before the advance stage otherwise the item won't even exist
        m_fixedGlobalScript.pushChild(new RevisedPlayerXPScript(gameEngine, m_assetManager));
        m_fixedGlobalScript.pushChild(new PerformanceAndStatsScript(gameEngine));
        m_fixedGlobalScript.pushChild(new UpdateAndSaveLevelDataScript(wordProblemGameState, gameEngine, m_levelManager));
        
        // The alteration of items might depend on the level information/save being updated first
        m_fixedGlobalScript.pushChild(new DefaultGiveRewardScript(gameEngine, playerItemInventory, m_logger, gameItemsData.rewards, m_levelManager, m_playerXpModel, "GiveRewardScript"));
        m_fixedGlobalScript.pushChild(new BaseAdvanceItemStageScript(gameEngine, playerItemInventory, itemDataSource, m_levelManager, "AdvanceStageScript"));
        m_fixedGlobalScript.pushChild(new BaseRevealItemScript(gameEngine, playerItemInventory, m_levelManager, null, "RevealItemScript"));
        m_fixedGlobalScript.pushChild(new CurrencyAwardedScript(gameEngine, playerCurrencyModel, m_playerXpModel, null, true, false));
        m_fixedGlobalScript.pushChild(new SummaryScript(
                wordProblemGameState, gameEngine, m_levelManager, 
                m_assetManager, playerItemInventory, itemDataSource, m_playerXpModel, playerCurrencyModel, 
                true, buttonColorData, "SummaryScript"));
        
        m_fixedGlobalScript.pushChild(new UpdateAndSavePlayerStatsAndDataScript(wordProblemGameState, gameEngine, m_playerXpModel, m_playerStatsAndSaveData, playerItemInventory, 
                null, true, false));
        
        // Also make sure button color is saved
        changeButtonColorScript.changeToButtonColor(m_playerStatsAndSaveData.getButtonColorName());
        
        // Look at the player's save data and change the cursor is a different one from default was equipped
        (try cast(m_fixedGlobalScript.getNodeById("ChangeCursorScript"), ChangeCursorScript) catch(e:Dynamic) null).initialize(
                playerItemInventory, itemDataSource, m_playerStatsAndSaveData.getCursorName());
        
        // Achievements depend on the player save data so that updates
        m_fixedGlobalScript.pushChild(new UpdateAndSaveAchievements(gameEngine, m_assetManager, playerAchievementsModel, 
                m_levelManager, m_playerXpModel, m_playerItemInventory, masteryToNodeNameMap, this.stage));
        m_fixedGlobalScript.pushChild(new GameStateNavigationDefault(wordProblemGameState, m_stateMachine, m_levelManager));
        m_fixedGlobalScript.pushChild(m_logger);
        m_fixedGlobalScript.pushChild(m_algebraAdventureCopilotService);
        
        var repairSaveData : RepairSaveData = new RepairSaveData(gameEngine, cache, onRepairData, onSaveData);
        m_fixedGlobalScript.pushChild(repairSaveData);
    }
    
    override private function startLevelFromXmlAndExtraData(id : String, levelXml : FastXML, extraLevelProgressionData : Dynamic = null) : Void
    {
        // TODO: To integrate the problem creation levels we need additional information about the level.
        // We need a way to tell if a level is a normal word problem vs a creation problem.
        // We would have separate objects to compile those particular levels.
        // HACK: The type of the problem is encoded in the extra progression data.
        // The end/start level events trigger several other pieces
        // It seems like this logic should only be valid for versions that would include the new level type
        if (extraLevelProgressionData != null && extraLevelProgressionData.exists("isProblemCreate") && extraLevelProgressionData.isProblemCreate) 
        {
            // If a problem is of level create type we have a different bundle of initial data
            // that needs to be loaded
            var problemCreateData : ProblemCreateData = new ProblemCreateData();
            problemCreateData.parseFromXml(levelXml);
            
            // TODO: This is hardcoded to load everything from a relative path,
            // Whether or not it is embedded or loaded dynamically should be specified elsewhere
            // Load the example text (which is a separate xml file) for this level
            var barModelType : String = problemCreateData.barModelType;
            var resourceName : String = "example_" + barModelType;
            m_assetManager.enqueueWithName("../assets/problem_create_examples/" + barModelType + ".xml", resourceName);
            m_assetManager.loadQueue(function(ratio : Float) : Void
                    {
                        (try cast(m_stateMachine.getStateInstance(WordProblemLoadingState), WordProblemLoadingState) catch(e:Dynamic) null).setLoadingRatio(ratio);
                        if (ratio == 1.0) 
                        {
                            // Disable problem creation for now
                            var params : Array<Dynamic> = [problemCreateData];
                            m_stateMachine.changeState(WordProblemCreateState, params);
                        }
                    });
        }
        else 
        {
            super.startLevelFromXmlAndExtraData(id, levelXml, extraLevelProgressionData);
        }
    }
    
    override private function onNoNextLevel() : Void
    {
        if (m_config.allowLevelSelect) 
        {
            m_stateMachine.changeState(WordProblemSelectState);
        }
        else 
        {
            m_stateMachine.changeState(PlayerCollectionsState);
        }
    }
    
    override private function resetClientData() : Void
    {
        super.resetClientData();
        
        // Read initial items to be given to a player
        // (mostly for debugging purposes as the reward script can figure out from level progress
        // which rewards were given and at what stage the rewards should be in)
        var gameItemsData : Dynamic = m_assetManager.getObject("game_items");
        
        // From a data file populate initial items that belong to player.
        // First step is to create initial data structures for each 'item'
        // Second step is to update those data structures with the progress
        var playerItemList : Array<Dynamic> = gameItemsData.playerItems;
        m_playerItemInventory.loadInitialItems(playerItemList);
        
        // TODO:
        // Reload save data in all the elements that need it.
        // (includes xp, items, other stats)
        
        // Reset item drawing for global scripts
        (try cast(m_fixedGlobalScript.getNodeById("GiveRewardScript"), BaseGiveRewardScript) catch(e:Dynamic) null).resetData();
        (try cast(m_fixedGlobalScript.getNodeById("AdvanceStageScript"), BaseAdvanceItemStageScript) catch(e:Dynamic) null).resetData();
        (try cast(m_fixedGlobalScript.getNodeById("RevealItemScript"), BaseRevealItemScript) catch(e:Dynamic) null).resetData();
    }
    
    override private function customSignout() : Void
    {
        m_playerItemInventory.componentManager.clear();
    }
    
    override private function onResetData() : Void
    {
        super.onResetData();
        
        m_stateMachine.changeState(WordProblemSelectState);
    }
    
    override private function onEnterFrame(event : starling.events.Event) : Void
    {
        super.onEnterFrame(event);
        m_mainJuggler.advanceTime(m_time.currentDeltaSeconds);
    }
    
    private function onGoToPlayerCollections() : Void
    {
        // Have the player collection screen slide in from the right
        m_stateMachine.changeState(PlayerCollectionsState, null, function(prevState : IState, nextState : IState, finishCallback : Function) : Void
                {
                    nextState.getSprite().x = -800;
                    var tween : Tween = new Tween(nextState.getSprite(), 0.3, Transitions.EASE_OUT);
                    tween.animate("x", 0);
                    tween.onComplete = finishCallback;
                    Starling.juggler.add(tween);
                }
                );
    }
    
    // Activity start occurs AFTER the player logs in
    private function onCopilotActivityStart(activityDefinition : Dynamic, details : Dynamic) : Void
    {
        // For this version we ignore level pack since we are using a baked in progressions
        var gradeString : String = "";
        if (details.exists("grade")) 
        {
            gradeString = Reflect.field(details, "grade");
        }  // properly (in particular we may get the grade that we need)    // It is only at this point do we have all the user data necessary for the game to set up    // Only do anything if no level is active or we have orders to interrupt  
        
        
        
        
        
        
        
        var gradeNumber : Int = -1;
        if (gradeString != "") 
        {
            gradeNumber = parseInt(gradeString);
            if (Math.isNaN(gradeNumber)) 
            {
                gradeNumber = -1;
            }
        }
        setUpGameForFirstTime(gradeNumber);
        
        // Start the right level based on the logged in user's save data
        m_levelManager.goToNextLevel();
    }
    
    private var m_itemIdsToRemoveForCondition : Array<String>;
    private function preprocessLevels(levelObject : Dynamic) : Void
    {
        m_itemIdsToRemoveForCondition = new Array<String>();
        
        // Figure out what the a/b test conditions are for this user to
        // configure the progression.
        var polItemsValue : String = null;
        var dongshengItemsValue : String = null;
        if (m_logger.getCgsUser() != null) 
        {
            var user : ICgsUser = m_logger.getCgsUser();
            
            // The condition id isn't actually useful for the app,
            // the variable values contain the actual settings to affect the gameplay
            polItemsValue = user.getVariableValue(AB_VAR_POL_ITEMS);
            dongshengItemsValue = user.getVariableValue(AB_VAR_DONGSHENG_ITEMS);
        }
        
        if (polItemsValue == null) 
        {
            polItemsValue = POL_ITEMS_DEFAULT;
        }
        
        if (dongshengItemsValue == null) 
        {
            dongshengItemsValue = DONSHENG_ITEMS_DEFAULT;
        }  // For example: key=experiment a, value can be cond1 or cond2    // for that key.    // For each condition key, each user will have exactly one condition value  
        
        
        
        
        
        
        
        var userConditions : Dynamic = { };
        Reflect.setField(userConditions, AB_VAR_POL_ITEMS, polItemsValue);
        Reflect.setField(userConditions, AB_VAR_DONGSHENG_ITEMS, dongshengItemsValue);
        _preprocessLevels(levelObject, userConditions);
        
        // Edges must be modified so they don't refer to non-existent item ids
        // HACK: Assuming items being a/b testing are mutually exclusive, so an item
        // id appearing for 'a' will not appear anywhere in 'b' and vis versa.
        var levelEdges : Array<Dynamic> = levelObject.edges;
        var numEdges : Int = levelEdges.length;
        for (i in 0...numEdges){
            // We use the assumption that the item ids referenced are only used
            // in the conditions sub element
            var edge : Dynamic = levelEdges[i];
            if (edge.exists("conditions")) 
            {
                var edgeConditions : Array<Dynamic> = edge.conditions;
                for (j in 0...edgeConditions.length){
                    var condition : Dynamic = edgeConditions[j];
                    if (condition.exists("name")) 
                    {
                        var nodeNameInCondition : String = Reflect.field(condition, "name");
                        if (Lambda.indexOf(m_itemIdsToRemoveForCondition, nodeNameInCondition) > -1) 
                        {
                            // Prune this condition
                            edgeConditions.splice(j, 1);
                            j--;
                        }
                    }
                }
            }
        }
    }
    
    /**
     *
     * @param userConditions
     *      A mapping from the name of a condition to the assigned value of that condition.
     * @return
     *      False if the passed in level object should not be part of the condition
     */
    private function _preprocessLevels(levelObject : Dynamic, userConditions : Dynamic) : Bool
    {
        var levelObjectAllowedForCondition : Bool = true;
        if (levelObject.exists("condkey") && levelObject.exists("condvalue")) 
        {
            var conditionKey : String = Reflect.field(levelObject, "condkey");
            var conditionValue : String = Reflect.field(levelObject, "condvalue");
            
            // If the level object for a
            if (userConditions.exists(conditionKey)) 
            {
                var userConditionValue : String = Reflect.field(userConditions, conditionKey);
                if (conditionValue != userConditionValue) 
                {
                    levelObjectAllowedForCondition = false;
                    m_itemIdsToRemoveForCondition.push(levelObject.name);
                }
            }
        }  // Prune any child elements that don't match the conditions  
        
        
        
        if (levelObjectAllowedForCondition && levelObject.exists("children")) 
        {
            var tempChildrenBuffer : Array<Dynamic> = new Array<Dynamic>();
            var children : Array<Dynamic> = levelObject.children;
            var numChildren : Int = children.length;
            var i : Int;
            for (i in 0...numChildren){
                var childElement : Dynamic = children[i];
                var childAllowedForCondition : Bool = _preprocessLevels(childElement, userConditions);
                if (childAllowedForCondition) 
                {
                    tempChildrenBuffer.push(childElement);
                }
            }  // Clear children elements and push back ones that are allowed based on the condition  
            
            
            
            while (children.length > 0)
            {
                children.pop();
            }
            
            for (childElement in tempChildrenBuffer)
            {
                children.push(childElement);
            }
        }
        
        return levelObjectAllowedForCondition;
    }
    
    /**
     * These important names are necessary to get data repairing working as well as determining
     * the LATEST level the player should jump to on entering the game again. The latter case is to fix issues
     * where the player goes backwards in the level select, we want them to return to the latest point on the
     * next login.
     * 
     * The idea for us is that if one of these important nodes is marked as completed, then all prior
     * sets/levels should also be seen as completed.
     */
    private function getImportantNodeNamesInSequence(grade : Int) : Array<String>
    {
        var importantNodeNames : Array<String> = new Array<String>();
        
        if (grade <= 4) 
        {
            importantNodeNames.push(
                    "1578");
            importantNodeNames.push(
                    "single_value_partial_equation");
            importantNodeNames.push(
                    "single_value_full_equation");
            importantNodeNames.push(
                    "1579");
            importantNodeNames.push(  //"create_equation",  
                    "addition_partial_equation");
            importantNodeNames.push(
                    "addition_full_equation");
            importantNodeNames.push(
                    "1567");
            importantNodeNames.push(  //"compare_tut",  
                    "subtraction_partial_equation");
            importantNodeNames.push(
                    "subtraction_full_equation");
            importantNodeNames.push(
                    "addition_subtraction_mix");
            importantNodeNames.push(
                    "multipart_subtraction");
            importantNodeNames.push(
                    );
            
        }
        else 
        {
            importantNodeNames.push(
                    "1564");
            importantNodeNames.push(
                    "1565");
            importantNodeNames.push(  //"create_equation",  
                    "addition_unknown_total");
            importantNodeNames.push(
                    "1567");
            importantNodeNames.push(  //"compare_tut",  
                    "subtraction_unknown_diff");
            importantNodeNames.push(
                    "addition_subtraction_mix");
            importantNodeNames.push(
                    "multipart_subtraction");
            importantNodeNames.push(
                    );
            
        }  // All sequences share these same set and level names  
        
        
        
        importantNodeNames.push(
                "1568");
        importantNodeNames.push(  //"multiply_bar_tut",  
                "multiply_unknown_total");
        importantNodeNames.push(
                "1569");
        importantNodeNames.push(  //"split_copy_tut",  
                "multiply_unknown_group");
        importantNodeNames.push(
                "1572");
        importantNodeNames.push(  //"adv_mult_div",  
                "multiply_multi_operator");
        importantNodeNames.push(
                "1570");
        importantNodeNames.push(  //"two_step_tut",  
                "two_step_addition_a");
        importantNodeNames.push(
                "two_step_addition_b");
        importantNodeNames.push(
                "two_step_groups_total");
        importantNodeNames.push(
                "two_step_groups_diff");
        importantNodeNames.push(
                "two_step_groups_mixed");
        importantNodeNames.push(
                "1571");
        importantNodeNames.push(  //"fraction_tut",  
                "basic_fractions_a");
        importantNodeNames.push(
                "basic_fractions_b");
        importantNodeNames.push(
                "basic_fractions_c");
        importantNodeNames.push(
                "advanced_fractions_a");
        importantNodeNames.push(
                "advanced_fractions_b");
        importantNodeNames.push(
                "advanced_fractions_c");
        importantNodeNames.push(
                "advanced_fractions_d");
        importantNodeNames.push(
                );
        
        
        return importantNodeNames;
    }
    
    private var m_importantNodeNamesForUser : Array<String>;
    private function onRepairData(masterData : Array<Dynamic>) : Void
    {
        //masterData = ["1578", "multiply_multi_operator"];
        
        // Master data should have the list of nodes that are completed
        var numNodesCompleted : Int = masterData.length;
        var maxIndexOfCompletedNode : Int = -1;
        for (i in 0...numNodesCompleted){
            var nodeNameCompleted : String = masterData[i];
            var indexOfName : Int = Lambda.indexOf(m_importantNodeNamesForUser, nodeNameCompleted);
            if (indexOfName > maxIndexOfCompletedNode) 
            {
                maxIndexOfCompletedNode = indexOfName;
            }
        }  // then some data corruption occurred)    // (This should have naturally occurred duing the course of play, if it didn't    // they should be marked as completed as well    // For ALL nodes coming before the maximum one that was marked as completed,  
        
        
        
        
        
        
        
        
        
        if (maxIndexOfCompletedNode > -1) 
        {
            var repairedNodeValues : Bool = false;
            for (i in 0...maxIndexOfCompletedNode + 1){
                nodeNameCompleted = m_importantNodeNamesForUser[i];
                var nodeThatShouldBeComplete : ICgsLevelNode = m_levelManager.getNodeByName(nodeNameCompleted);
                if (nodeThatShouldBeComplete != null) 
                {
                    if (nodeThatShouldBeComplete.completionValue != LevelNodeCompletionValues.PLAYED_SUCCESS) 
                    {
                        // Need to fix this node to get the right completion value
                        var newLevelStatus : Dynamic = { };
                        newLevelStatus[LevelNodeSaveKeys.COMPLETION_VALUE] = LevelNodeCompletionValues.PLAYED_SUCCESS;
                        nodeThatShouldBeComplete.updateNode(nodeThatShouldBeComplete.nodeLabel, newLevelStatus);
                        repairedNodeValues = true;
                    }
                }
            }
            
            if (repairedNodeValues) 
            {
                // Should flush the cache at this point if any repairs were necessary
                m_logger.getCgsUser().flush();
            }  // Always select the first uncompleted node if it is a set    // To fix this, just always go to the next important node directly AFTER the one that is complete.    // user backs out and plays an older set, the current level becomes the old one.    // We already have a bit of save data to track the current level. There is a problem potentially where if the    // Based on this max index, we should be able to figure out which level or set the user should be at as well  
            
            
            
            
            
            
            
            
            
            
            
            var nextNodeIndexForPlayer : Int = maxIndexOfCompletedNode + 1;
            if (nextNodeIndexForPlayer < m_importantNodeNamesForUser.length) 
            {
                var nextNodeNameForPlayer : String = m_importantNodeNamesForUser[nextNodeIndexForPlayer];
                var nextNode : ICgsLevelNode = m_levelManager.getNodeByName(nextNodeNameForPlayer);
                if (nextNode != null) 
                {
                    if (Std.is(nextNode, WordProblemLevelPack)) 
                    {
                        var nodesInSet : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
                        WordProblemCgsLevelManager.getLevelNodes(nodesInSet, nextNode);
                        var numNodesInSet : Int = nodesInSet.length;
                        var nextNodeToPlay : WordProblemLevelLeaf = null;
                        for (i in 0...numNodesInSet){
                            var childNode : WordProblemLevelLeaf = nodesInSet[i];
                            if (!childNode.isComplete) 
                            {
                                nextNodeToPlay = childNode;
                                break;
                            }
                        }  // Play first one in sequence if all are finished  
                        
                        
                        
                        if (nextNodeToPlay == null && nodesInSet.length > 0) 
                        {
                            nextNodeToPlay = nodesInSet[0];
                        }
                        
                        m_levelManager.setNextLevelLeaf(nextNodeToPlay);
                    }
                    else if (Std.is(nextNode, WordProblemLevelLeaf)) 
                    {
                        m_levelManager.setNextLevelLeaf(try cast(nextNode, WordProblemLevelLeaf) catch(e:Dynamic) null);
                    }
                }
            }
            else 
            {
                // Finished everything, go back to level select
                m_levelManager.setNextLevelLeaf(null);
            }
        }
    }
    
    private function onSaveData() : Dynamic
    {
        // In sequence, iterate through the important node names and figure out which ones are complete
        var i : Int;
        var completedNodeNames : Array<Dynamic> = [];
        var numImportantNames : Int = m_importantNodeNamesForUser.length;
        for (i in 0...numImportantNames){
            var importantName : String = m_importantNodeNamesForUser[i];
            var importantNode : ICgsLevelNode = m_levelManager.getNodeByName(importantName);
            if (importantNode != null && importantNode.completionValue == LevelNodeCompletionValues.PLAYED_SUCCESS) 
            {
                completedNodeNames.push(importantName);
            }
        }
        
        return completedNodeNames;
    }
}
