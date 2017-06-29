package wordproblem;


import cgs.cache.ICgsUserCache;
import cgs.server.IntegrationDataService;
import cgs.server.logging.CGSServerConstants;
import cgs.server.responses.CgsResponseStatus;
import cgs.server.responses.CgsUserResponse;
import cgs.server.responses.ResponseStatus;
import cgs.user.ICgsUser;

import dragonbox.common.state.IState;

import gameconfig.versions.brainpop.scripts.GiveRewardScript;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.events.Event;

import wordproblem.achievements.PlayerAchievementsModel;
import wordproblem.achievements.scripts.UpdateAndSaveAchievements;
import wordproblem.brainpop.BrainpopApi;
import wordproblem.currency.PlayerCurrencyModel;
import wordproblem.currency.scripts.CurrencyAwardedScript;
import wordproblem.engine.events.GameEvent;
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
import wordproblem.saves.DummyCache;
import wordproblem.scripts.items.BaseAdvanceItemStageScript;
import wordproblem.scripts.items.BaseRevealItemScript;
import wordproblem.scripts.level.save.UpdateAndSaveLevelDataScript;
import wordproblem.scripts.performance.PerformanceAndStatsScript;
import wordproblem.scripts.state.GameStateNavigationDefault;
import wordproblem.state.ExternalLoginTitleScreenState;
import wordproblem.state.WordProblemGameState;
import wordproblem.state.WordProblemSelectState;
import wordproblem.summary.scripts.SummaryScript;
import wordproblem.xp.PlayerXpModel;
import wordproblem.xp.scripts.PlayerXPScript;

/**
 * This is the main application for versions in which we cannot ask for login.
 */
class WordProblemGameBrainpop extends WordProblemGameBase
{
    private static inline var AB_VAR_GROUP : String = "group";
    private static inline var AB_VAR_OFFSET : String = "offset";
    
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
    
    /**
     * Data representation of the currency the player earns
     */
    private var m_playerCurrencyModel : PlayerCurrencyModel;
    
    // HACK: On authenticate split up code/objects that only need to run once
    // and ones that need to reset
    private var m_setUpClassAlready : Bool = false;
    
    /**
     * Need this object to send various requests related to checking existence
     * of the member accounts
     */
    private var m_integrationDataService : IntegrationDataService;
    
    public function new()
    {
        super();
    }
    
    override private function onStartingResourcesLoaded() : Void
    {
        CGSServerConstants.INTEGRATION_LOCAL_PORT = 10059;
        
        // Don't show the name in the level select screen
        m_config.showUserNameInSelectScreen = false;
        
        // Attach the Brainpop screen capture component to the Starling based stage
        
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
        m_stateMachine.changeState(titleScreenState);
        
        // Bind listener when grade and gender gets a request to update
        this.gameEngine.addEventListener(GameEvent.UPDATE_GRADE_GENDER, onUpdateGradeAndGender);
        
        // For this setup we DO NOT want to show the player's user name as part of the level select
        // Since they can't pick a username the one that gets assigned to them is nonsense
        
        // Skip to level select if we don't want to do anything with the server
        if (m_config.debugNoServerLogin) 
        {
            onUserAuthenticated();
        }
        
        var brainpopApi : BrainpopApi = new BrainpopApi(
        m_logger, 
        m_config.getTeacherCode(), 
        m_config.getServerDeployment(), 
        m_config.getSaveDataToServer(), 
        m_config.getSaveDataKey(), 
        m_config.getUseHttps(), 
        m_nativeFlashStage, 
        this.stage);
        brainpopApi.checkLoginStatus(onBrainpopCheckLogin);
        
        // If we recieve a response from the brainpop api and a player has not already logged in
        // then we see if the given id is already linked to an account on our server.
        // If it is, use the id as the username in authentication
        // Otherwise create a new account
        m_integrationDataService = m_logger.getCgsApi().createIntegrationDataService(m_logger.getCgsUserProperties(true, null));
    }
    
    override private function onUserAuthenticated() : Void
    {
        // HACK: Should not be executing this function multiple times anyways
        // If the level manager already exists then we have already run this function, lets not do it again.
        if (!m_setUpClassAlready) 
        {
            // If user authenticated, then use the cgs user object returned as the cache.
            // At this point we can also check if the player is part of an AB test
            // Otherwise create a dummy temp storage.
            var abTestGroup : String = "A";
            if (m_logger.getCgsUser() != null) 
            {
                var user : ICgsUser = m_logger.getCgsUser();
                var cache : ICgsUserCache = user;
                
                // The condition id isn't actually useful for the app,
                // the variable values contain the actual settings to affect the gameplay
                var userGroup : String = user.getVariableValue(AB_VAR_GROUP);
                if (userGroup != null) 
                {
                    abTestGroup = userGroup;
                }
            }
            else 
            {
                cache = new DummyCache();
            }  // Load up the save data for the player  
            
            
            
            m_playerStatsAndSaveData = new PlayerStatsAndSaveData(cache);
            var buttonColorData : ButtonColorData = m_playerStatsAndSaveData.buttonColorData;
            
            // Load up the amount of experience points earned by the player
            m_playerXpModel = new PlayerXpModel(cache);
            
            m_playerCurrencyModel = new PlayerCurrencyModel(cache);
            
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
            
            // Setting default button color
            var changeButtonColorScript : ChangeButtonColorScript = new ChangeButtonColorScript(buttonColorData, playerItemInventory, itemDataSource);
            
            var playerAchievementsDataSource : Dynamic = m_assetManager.getObject("achievements");
            var playerAchievementsModel : PlayerAchievementsModel = new PlayerAchievementsModel(playerAchievementsDataSource);
            
            // The level manager has a dependency on the login of a player
            // Thus we cannot completely initialize the levels until after login has taken place.
            // Thus POST-login is another phase for further object initialization
            // Need to wait for the level controller to signal that it is ready as well
            // Parse the level sequence file
            m_levelManager = new WordProblemCgsLevelManager(
                    m_logger.getCgsApi().userManager, 
                    m_assetManager, 
                    onStartLevel, 
                    onNoNextLevel, 
                    !m_config.unlockAllLevels, 
                    );
            
            // The brain pop experiment has 96 different conditions, although they are very slight variations
            // on four main ones. The ab test group for the user is composed of a letter and then a number
            // Think of it like a sliding window, the letter defines one of the main four sequences to
            // use while the number defines the offset
            var levelProgressionName : String = "sequence_" + abTestGroup;
            
            // Modify the contents of the json object kept in the asset manager
            // We assume this is the first chapter of each genre
            m_levelManager.setToNewLevelProgression(levelProgressionName, cache, preprocessLevel);
            
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
            m_playerCurrencyModel, 
            playerAchievementsModel, 
            m_itemDataSource, 
            m_playerItemInventory, 
            gameItemsData.types, 
            gameItemsData.customizables, 
            m_playerStatsAndSaveData, 
            try cast(m_fixedGlobalScript.getNodeById("ChangeCursorScript"), ChangeCursorScript) catch(e:Dynamic) null, 
            changeButtonColorScript, 
            function() : Void
            {
                m_stateMachine.changeState(WordProblemSelectState);
            }, 
            buttonColorData, 
            );
            m_stateMachine.register(playerCollectionState);
            
            // Link logging events to game engine
            m_logger.setGameEngine(gameEngine, wordProblemGameState);
            
            // Go directly to the level select state
            m_stateMachine.changeState(WordProblemSelectState, null);
            
            m_fixedGlobalScript.pushChild(new DrawItemsOnShelves(
                    wordProblemSelectState, 
                    m_playerItemInventory, 
                    m_itemDataSource, 
                    m_assetManager, 
                    Starling.juggler, 
                    ));
            
            // Add scripts that have logic that operate across several levels.
            // This deals with things like handing out rewards or modifying rewards
            // We need to make sure the reward script comes before the advance stage otherwise the item won't even exist
            m_fixedGlobalScript.pushChild(new PlayerXPScript(gameEngine, m_assetManager));
            m_fixedGlobalScript.pushChild(new PerformanceAndStatsScript(gameEngine));
            m_fixedGlobalScript.pushChild(new UpdateAndSaveLevelDataScript(wordProblemGameState, gameEngine, m_levelManager));
            m_fixedGlobalScript.pushChild(new UpdateAndSaveAchievements(gameEngine, m_assetManager, playerAchievementsModel, m_levelManager, m_playerXpModel, 
                    playerItemInventory, null, this.stage));
            m_fixedGlobalScript.pushChild(new GiveRewardScript(gameEngine, playerItemInventory, gameItemsData.rewards, m_levelManager, m_playerXpModel, "GiveRewardScript"));
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
            m_fixedGlobalScript.pushChild(new CurrencyAwardedScript(gameEngine, m_playerCurrencyModel, m_playerXpModel));
            m_fixedGlobalScript.pushChild(new UpdateAndSavePlayerStatsAndDataScript(wordProblemGameState, gameEngine, m_playerXpModel, m_playerStatsAndSaveData, playerItemInventory));
            m_fixedGlobalScript.pushChild(new SummaryScript(
                    wordProblemGameState, gameEngine, m_levelManager, 
                    m_assetManager, playerItemInventory, itemDataSource, m_playerXpModel, m_playerCurrencyModel, 
                    true, buttonColorData, "SummaryScript"));
            m_fixedGlobalScript.pushChild(new GameStateNavigationDefault(wordProblemGameState, m_stateMachine, m_levelManager));
            m_fixedGlobalScript.pushChild(m_logger);
            
            // Look at the player's save data and change the cursor is a different one from default was equipped
            (try cast(m_fixedGlobalScript.getNodeById("ChangeCursorScript"), ChangeCursorScript) catch(e:Dynamic) null).initialize(
                    playerItemInventory, itemDataSource, m_playerStatsAndSaveData.getCursorName());
            
            m_setUpClassAlready = true;
        }
        else 
        {
            resetClientData();
            
            // Go back into the select
            m_stateMachine.changeState(WordProblemSelectState, null);
        }
    }
    
    override private function onNoNextLevel() : Void
    {
        m_stateMachine.changeState(WordProblemSelectState);
    }
    
    override private function customSignout() : Void
    {
        m_playerItemInventory.componentManager.clear();
        
        m_stateMachine.changeState(ExternalLoginTitleScreenState);
    }
    
    /**
     * Hack: Remember external id that passes through several layers of callbacks
     */
    private var m_savedExternalId : String;
    private function onBrainpopCheckLogin(isLoggedIn : Bool, brainpopId : String) : Void
    {
        m_savedExternalId = brainpopId;
        if (isLoggedIn) 
        {
            m_integrationDataService.getUserIdFromExternalIdAndSource(
                    brainpopId,
                    BrainpopApi.BRAINPOP_EXTERNAL_SOURCE_ID,
                    onGetUserIdFromExternIdAndSource
                    );
        }
    }
    
    private function onGetUserIdFromExternIdAndSource(response : ResponseStatus, uid : String) : Void
    {
        // If found uid, then the brainpop user has a cgs account that is also correctly linked
        // they should be able to authenticate
        if (uid != null) 
        {
            // Only need to authenticate if they are still in the login screen since if they are in the
            // game already they have already been authenticated as a guest
            // No need to redo the login as that guest account is still linked correctly to the external id
            if (Std.is(m_stateMachine.getCurrentState(), ExternalLoginTitleScreenState)) 
            {
                m_logger.getCgsApi().authenticateStudent(
                        m_logger.getCgsUserProperties(true, null),
                        uid,
                        m_config.getTeacherCode(),
                        null,
                        0,
                        function onAuthenticate(response : CgsUserResponse) : Void
                        {
                            if (response.success) 
                            {
                                onUserAuthenticated();
                            }
                            else 
                            {
                                // Attempt to link the cgs id with the brainpop id failed
                                // This would fail if the uid wasn't actaully linked with brainpop
                                
                            }
                        }
                        );
            }
        }
        // In the situation where we detect a brainpop login has occurred BUT we cannot
        // find a link between a cgs account uid and that external id then we have two possible scenarios
        // 1.) They played as a guest (never logged in brainpop before)
        // so the link was never correctly established but they do have a cgs account
        // 2.) The cgs account does not exist in the first place
        else 
        {
            // To differentiate between the two situations we just need to check if the
            // currently assigned uid has an account associated with it
            m_integrationDataService.checkStudentNameAvailable(
                    null,
                    null,
                    m_config.getTeacherCode(),
                    function(responseStatus : ResponseStatus) : Void
                    {
                        // No account is present we need to create a new student
                        if (responseStatus.success) 
                        {
                            m_logger.getCgsApi().registerStudent(
                                    m_logger.getCgsUserProperties(true, null), uid, m_config.getTeacherCode(), 0,
                                    function(response : CgsResponseStatus) : Void
                                    {
                                        if (response.success) 
                                        {
                                            onUserAuthenticated();
                                        }
                                        else 
                                        { };
                                    }, 0);
                        }
                        // Account is present, but we need to update the external id and external source
                        else 
                        {
                            m_integrationDataService.updateExternalIdAndSourceFromUserId(
                                    uid, m_savedExternalId, BrainpopApi.BRAINPOP_EXTERNAL_SOURCE_ID, null
                                    );
                            onUserAuthenticated();
                        }
                    }
                    );
        }
    }
    
    /**
     * Modify the level progression data structure to it fits with the player
     * condition for the experiment.
     */
    private function preprocessLevel(levelObject : Dynamic) : Void
    {
        var abTestOffset : Int = 0;
        if (m_logger.getCgsUser() != null) 
        {
            var userOffset : Int = m_logger.getCgsUser().getVariableValue(AB_VAR_OFFSET);
            if (userOffset >= 0) 
            {
                abTestOffset = userOffset;
            }
        }  // Identify where the tutorial objects are in the first pass  
        
        
        
        var genreToTutorialLevelList : Dynamic = { };
        var levelChildren : Array<Dynamic> = levelObject.children;
        var i : Int;
        var numChildren : Int = levelChildren.length;
        for (i in 0...numChildren){
            // The special tutorial sets are formatted with a name that looks like
            // <genre_name>_tutorials
            var childObject : Dynamic = levelChildren[i];
            var childName : String = childObject.name;
            if (childName.indexOf("_tutorials") >= 0) 
            {
                var genreName : String = childName.split("_")[0];
                Reflect.setField(genreToTutorialLevelList, genreName, childObject.children);
            }
        }
        
        for (i in 0...numChildren){
            childObject = levelChildren[i];
            if (childObject.type == "GenreLevelPack") 
            {
                genreName = childObject.name;
                if (genreName == "fantasy" || genreName == "scifi" || genreName == "mystery") 
                {
                    var tutorialListForGenre : Array<Dynamic> = genreToTutorialLevelList[genreName];
                    
                    var chapters : Array<Dynamic> = childObject.children;
                    if (chapters.length > 0) 
                    {
                        // The 'sliding' window of levels in the first set just contains 10 levels
                        var chapterToModify : Dynamic = chapters[0];
                        var levels : Array<Dynamic> = chapterToModify.children;
                        var numLevels : Int = levels.length;
                        
                        var newLevelSet : Array<Dynamic> = new Array<Dynamic>();
                        var numLevelsToAddInNewSet : Int = 10;
                        for (j in 0...numLevelsToAddInNewSet){
                            // Wrap the index back to the start if it overflows
                            var indexToCheck : Int = j + abTestOffset;
                            if (indexToCheck >= numLevels) 
                            {
                                indexToCheck -= numLevels;
                            }
                            
                            var levelToAdd : Dynamic = levels[indexToCheck];
                            
                            // A level in the section being modified has a set of actions that are performed in the level.
                            // Each action should be introduced by a tutorial level
                            // (tutorials exist for subtract, multiply, divide, and parentheses)
                            if (levelToAdd.exists("tags")) 
                            {
                                // Each action maps to a tutorial, if that tutorial has not already been added
                                // to the sequence then we need to add it here.
                                var levelTags : Array<Dynamic> = levelToAdd.tags;
                                for (tag in levelTags)
                                {
                                    for (k in 0...tutorialListForGenre.length){
                                        var availableTutorial : Dynamic = tutorialListForGenre[k];
                                        var tags : Array<Dynamic> = availableTutorial.tags;
                                        
                                        // Progression changed so tutorials are part of a fixed sequence
                                        // Only the parenthesis is not introduced
                                        if (tags.length > 0 && tags[0] == tag && tag == "parenthesis") 
                                        {
                                            newLevelSet.push(availableTutorial);
                                            tutorialListForGenre.splice(k, 1);
                                            break;
                                        }
                                    }
                                }
                            }
                            
                            newLevelSet.push(levelToAdd);
                        }  // Replace the field in the json with the reorganized set  
                        
                        
                        
                        chapterToModify.children = newLevelSet;
                    }
                }
            }
        }
    }
    
    private function onUpdateGradeAndGender(event : Event, params : Dynamic) : Void
    {
        var grade : Int = params.grade;
        var gender : Int = params.gender;
        var cgsUser : ICgsUser = m_logger.getCgsUser();
        if (cgsUser != null) 
        {
            cgsUser.updateStudent(cgsUser.username, m_config.getTeacherCode(), grade, gender, function() : Void
                    {
                        trace("Grade and gender updated for user");
                    });
        }
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
