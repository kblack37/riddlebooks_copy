package gameconfig.versions.challenge0316;


import cgs.cache.ICgsUserCache;
import cgs.server.responses.CgsUserResponse;
import cgs.user.CgsUserProperties;
import cgs.user.ICgsUser;

import dragonbox.common.console.expression.MethodExpression;
import dragonbox.common.state.IState;
import dragonbox.common.util.XString;

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
import wordproblem.currency.PlayerCurrencyModel;
import wordproblem.currency.scripts.CurrencyAwardedScript;
import wordproblem.engine.component.CurrentGrowInStageComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.text.TextParser;
import wordproblem.event.CommandEvent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.levelselect.scripts.DrawItemsOnShelves;
import wordproblem.player.ButtonColorData;
import wordproblem.player.ChangeButtonColorScript;
import wordproblem.player.ChangeCursorScript;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.player.UpdateAndSavePlayerStatsAndDataScript;
import wordproblem.playercollections.PlayerCollectionsState;
import wordproblem.saves.BatchSaveDataScript;
import wordproblem.saves.DummyCache;
import wordproblem.scripts.items.BaseAdvanceItemStageScript;
import wordproblem.scripts.items.BaseGiveRewardScript;
import wordproblem.scripts.items.BaseRevealItemScript;
import wordproblem.scripts.items.DefaultGiveRewardScript;
import wordproblem.scripts.level.save.UpdateAndSaveLevelDataScript;
import wordproblem.scripts.performance.PerformanceAndStatsScript;
import wordproblem.scripts.state.GameStateNavigationDefault;
import wordproblem.state.ChallengeTitleScreenState;
import wordproblem.state.CopilotScreenState;
import wordproblem.state.ExternalLoginTitleScreenState;
import wordproblem.state.WordProblemGameState;
import wordproblem.state.WordProblemSelectState;
import wordproblem.summary.scripts.SummaryScript;
import wordproblem.xp.PlayerXpModel;
import wordproblem.xp.scripts.PlayerXPScript;

/**
 * Main application for challenge type events using the word problem game.
 */
class WordProblemGameChallenge0316 extends WordProblemGameBase
{
    private static var USE_LOGIN_SCREEN : Bool = true;
    
    /*
    Set to -1 to use the copilot grade instead
    */
    private static inline var DUMMY_GRADE : Int = 2;
    
    /*
    AB Testing names
    */
    private static inline var AB_VAR_POL_ITEMS : String = "pol";
    private static inline var AB_VAR_DONGSHENG_ITEMS : String = "dongsheng";
    private static inline var AB_VAR_CUSTOM_HINTS : String = "customhints";
    private static inline var POL_ITEMS_DEFAULT : String = "a";
    private static inline var DONSHENG_ITEMS_DEFAULT : String = "a";
    private static var DEFAULT_USE_CUSTOM_HINTS : Bool = true;
    
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
    
    /**
     * Game specific Copilot Service, for running Copilot related functions and relaying messages.
     */
    private var m_algebraAdventureCopilotService : AlgebraAdventureCopilotService;
    
    private var m_playerCurrencyModel : PlayerCurrencyModel;
    
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
        
        // Start up the copilot
        var copilotProps : CgsUserProperties = m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey());
        copilotProps.completeCallback = function userPropsCompleteCallbackForCopilot(userResponse : CgsUserResponse) : Void
                {
                    // Register user
                    if (userResponse.success) 
                    {
                        onUserAuthenticated();
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
        
        // Setup Copilot start screen
        var copilotScreenState : CopilotScreenState = new CopilotScreenState(
        m_stateMachine, 
        m_assetManager, 
        );
        m_stateMachine.register(copilotScreenState);
        m_stateMachine.changeState(copilotScreenState);
        
        // For the challenge, a login might be required
        // Depending on whether the link is played independently at home.
        // to detect this will need to look at the url.
        if (USE_LOGIN_SCREEN) 
        {
            var titleScreenState : ExternalLoginTitleScreenState = new ExternalLoginTitleScreenState(
            m_stateMachine, 
            m_assetManager, 
            m_config.getTeacherCode(), 
            m_config.getSaveDataKey(), 
            m_config.getSaveDataToServer(), 
            m_logger, 
            );
            titleScreenState.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
            titleScreenState.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
            titleScreenState.addEventListener(CommandEvent.USER_AUTHENTICATED, onUserAuthenticated);
            
            m_stateMachine.register(titleScreenState);
            
            // Automatically go to the problem selection state
            m_stateMachine.changeState(titleScreenState);
        }  // Skip to level select if we don't want to do anything with the server  
        
        
        
        if (m_config.debugNoServerLogin) 
        {
            onUserAuthenticated();
        }
        else 
        {
            // At the end of this function, all setup of the game is complete
            // In the copilot version, this application display is not added to the screen until AFTER
            // this signal is recieved. Avoid adding anything to the display list during this time.
            m_algebraAdventureCopilotService.applicationReady();
        }
    }
    
    /*
    HACK: Grade is coming in on an activity start. This bit of information is required to configure the game so we
    must wait for that signal rather than the user authentication.
    */
    override private function onUserAuthenticated() : Void
    {
        // HACK: Should not be executing this function multiple times anyways
        // If the level manager already exists then we have already run this function, lets not do it again.
        if (!m_setUpClassAlready) 
        {
            if (DUMMY_GRADE > -1) 
            {
                setUpGameForFirstTime(DUMMY_GRADE);
                
                // Go directly to the level select state in the case of a dummy
                m_stateMachine.changeState(WordProblemSelectState, null);
            }
            m_setUpClassAlready = true;
        }
        else 
        {
            //resetClientData();
            
            // Go back into the select
            //m_stateMachine.changeState(WordProblemSelectState, null);
            
        }
    }
    
    /**
     * 
     * @param userGrade
     *      If -1, then grade for that user is kept unspecified
     */
    private function setUpGameForFirstTime(userGrade : Int) : Void
    {
        m_stateMachine.changeState(CopilotScreenState);
        
        // The cache saves user data either locally or on the servers
        var cache : ICgsUserCache = null;
        if (m_logger.getCgsUser() != null) 
        {
            cache = m_logger.getCgsUser();
        }
        else 
        {
            cache = new DummyCache();
        }  // script    // At this point, all the data belonging to the user has already been setup need a    // TODO: Initialize batch save data.  
        
        
        
        
        
        
        
        var batchSaveDataScript : BatchSaveDataScript = new BatchSaveDataScript(this.gameEngine, cache);
        
        // Load up the save data for the player
        var defaultDecisions : Dynamic = {
            color : "red",
            costume : "zombie",
            treasure : "coin",
            pet : "cat",
            f : "f",

        };
        m_playerStatsAndSaveData = new PlayerStatsAndSaveData(cache, defaultDecisions);
        
        // Usage of custom hints is a/b test condition
        var useCustomHints : Bool = DEFAULT_USE_CUSTOM_HINTS;
        if (m_logger.getCgsUser() != null) 
        {
            var useCustomHintValue : String = m_logger.getCgsUser().getVariableValue(AB_VAR_CUSTOM_HINTS);
            if (useCustomHintValue != null) 
            {
                useCustomHints = XString.stringToBool(useCustomHintValue);
            }
        }
        m_playerStatsAndSaveData.useCustomHints = useCustomHints;
        
        // Load up the amount of experience points earned by the player
        m_playerXpModel = new PlayerXpModel(cache);
        
        var playerCurrencyModel : PlayerCurrencyModel = new PlayerCurrencyModel(cache);
        m_playerCurrencyModel = playerCurrencyModel;
        
        // Set up parsers for scripts and text
        m_scriptParser = new ScriptParser(gameEngine, m_expressionCompiler, m_assetManager, m_playerStatsAndSaveData);
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
        
        // The level manager has a dependency on the login of a player
        // Thus we cannot completely initialize the levels until after login has taken place.
        // Thus POST-login is another phase for further object initialization
        // Need to wait for the level controller to signal that it is ready as well
        // Parse the level sequence file
        var levelSequenceNameToUse : String = "sequence_5_6";
        if (userGrade > -1) 
        {
            if (userGrade <= 2) 
            {
                levelSequenceNameToUse = "sequence_2_under";
            }
            else if (userGrade <= 4) 
            {
                levelSequenceNameToUse = "sequence_3_4";
            }
            else if (userGrade <= 6) 
            {
                levelSequenceNameToUse = "sequence_5_6";
            }
            else 
            {
                levelSequenceNameToUse = "sequence_7_over";
            }
        }
        
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
        );
        wordProblemGameState.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
        wordProblemGameState.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
        m_stateMachine.register(wordProblemGameState);
        
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
            m_stateMachine.changeState(WordProblemSelectState);
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
        m_fixedGlobalScript.pushChild(new PlayerXPScript(gameEngine, m_assetManager));
        m_fixedGlobalScript.pushChild(new PerformanceAndStatsScript(gameEngine));
        m_fixedGlobalScript.pushChild(new UpdateAndSaveLevelDataScript(wordProblemGameState, gameEngine, m_levelManager));
        
        // The alteration of items might depend on the level information/save being updated first
        m_fixedGlobalScript.pushChild(new DefaultGiveRewardScript(gameEngine, playerItemInventory, m_logger, gameItemsData.rewards, m_levelManager, m_playerXpModel, "GiveRewardScript"));
        m_fixedGlobalScript.pushChild(new BaseAdvanceItemStageScript(gameEngine, playerItemInventory, itemDataSource, m_levelManager, "AdvanceStageScript"));
        m_fixedGlobalScript.pushChild(new BaseRevealItemScript(gameEngine, playerItemInventory, m_levelManager, ["6", 
                        "7", 
                        "8", 
                        "9", 
                        "10", 
                        "11", 
                        "12", 
                        "13", 
                        "14"], "RevealItemScript"));
        m_fixedGlobalScript.pushChild(new CurrencyAwardedScript(gameEngine, playerCurrencyModel, m_playerXpModel));
        m_fixedGlobalScript.pushChild(new SummaryScript(
                wordProblemGameState, gameEngine, m_levelManager, 
                m_assetManager, playerItemInventory, itemDataSource, m_playerXpModel, playerCurrencyModel, 
                true, buttonColorData, "SummaryScript"));
        
        m_fixedGlobalScript.pushChild(new UpdateAndSavePlayerStatsAndDataScript(wordProblemGameState, gameEngine, m_playerXpModel, m_playerStatsAndSaveData, playerItemInventory));
        
        // Look at the player's save data and change the cursor is a different one from default was equipped
        (try cast(m_fixedGlobalScript.getNodeById("ChangeCursorScript"), ChangeCursorScript) catch(e:Dynamic) null).initialize(
                playerItemInventory, itemDataSource, m_playerStatsAndSaveData.getCursorName());
        
        // Also make sure button color is saved
        changeButtonColorScript.changeToButtonColor(m_playerStatsAndSaveData.getButtonColorName());
        
        // Look at the player's save data and change the cursor is a different one from default was equipped
        (try cast(m_fixedGlobalScript.getNodeById("ChangeCursorScript"), ChangeCursorScript) catch(e:Dynamic) null).initialize(
                playerItemInventory, itemDataSource, m_playerStatsAndSaveData.getCursorName());
        
        // Achievements depend on the player save data so that updates
        m_fixedGlobalScript.pushChild(new UpdateAndSaveAchievements(gameEngine, m_assetManager, playerAchievementsModel, m_levelManager, m_playerXpModel, this.stage));
        m_fixedGlobalScript.pushChild(new GameStateNavigationDefault(wordProblemGameState, m_stateMachine, m_levelManager));
        m_fixedGlobalScript.pushChild(batchSaveDataScript);
        m_fixedGlobalScript.pushChild(m_logger);
        m_fixedGlobalScript.pushChild(m_algebraAdventureCopilotService);
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
     * The custom behavior when we get a copilot start.
     * It is at this point that we get the grade.
     */
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
    
    override private function onNoNextLevel() : Void
    {
        m_stateMachine.changeState(WordProblemSelectState);
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
        
        m_stateMachine.changeState(ChallengeTitleScreenState);
    }
    
    override private function onResetData() : Void
    {
        super.onResetData();
        
        m_stateMachine.changeState(WordProblemSelectState);
    }
    
    override private function onEnterFrame(event : Event) : Void
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
}
