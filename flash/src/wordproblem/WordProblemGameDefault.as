package wordproblem
{
    import cgs.CgsApi;
    import cgs.Cache.ICgsUserCache;
    import cgs.internationalization.StringTable;
    
    import dragonbox.common.console.expression.MethodExpression;
    import dragonbox.common.state.IState;
    
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.text.TextField;
    
    import wordproblem.account.LockAnonymousAccountController;
    import wordproblem.account.RegisterAccountState;
    import wordproblem.achievements.PlayerAchievementsModel;
    import wordproblem.achievements.scripts.UpdateAndSaveAchievements;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.currency.PlayerCurrencyModel;
    import wordproblem.currency.scripts.CurrencyAwardedScript;
    import wordproblem.engine.component.CurrentGrowInStageComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.scripting.ScriptParser;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.widget.ConfirmationWidget;
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
    import wordproblem.scripts.items.BaseGiveRewardScript;
    import wordproblem.scripts.items.BaseRevealItemScript;
    import wordproblem.scripts.items.DefaultGiveRewardScript;
    import wordproblem.scripts.level.save.UpdateAndSaveLevelDataScript;
    import wordproblem.scripts.performance.PerformanceAndStatsScript;
    import wordproblem.scripts.state.GameStateNavigationDefault;
    import wordproblem.state.ExternalLoginTitleScreenState;
    import wordproblem.state.TitleScreenState;
    import wordproblem.state.WordProblemGameState;
    import wordproblem.state.WordProblemSelectState;
    import wordproblem.summary.scripts.SummaryScript;
    import wordproblem.xp.PlayerXpModel;
    import wordproblem.xp.scripts.PlayerXPScript;

    /**
     * The main application entry point.
     * 
     * It contains all the major resources, configurations, and systems for the game.
     * The settings specified in the class will get passed to various systems to configure the
     * game, for example the language files to use are initialized and passed to the string
     * table here.
     */
    public class WordProblemGameDefault extends WordProblemGameBase
    {
        // For now the top level class is the best place to append the loading of game specific data, which for now
        // deals mostly with data related to the inventory. From here it can be passed to any other screen that needs
        // to read or modify it during runtime.
        /**
         * Keep track of properties of all game world item (not player specific so does not need to be 
         * reset for different players)
         */
        protected var m_itemDataSource:ItemDataSource;
        
        /**
         * Keep track of items specifically belonging to a player. (needs to be reset when different players come in)
         */
        protected var m_playerItemInventory:ItemInventory;
        
        /**
         * This is the data representation of the experience that the player gains during a
         * playthrough of the game.
         */
        protected var m_playerXpModel:PlayerXpModel;
        
        /**
         * Data representation of the currency the player earns
         */
        protected var m_playerCurrencyModel:PlayerCurrencyModel;
        
        /**
         * Have this object active if we want guest account to be locked out after a certain number
         * of finished levels.
         */
        private var m_lockAnonymousAccountController:LockAnonymousAccountController;
        
        // HACK: On authenticate split up code/objects that only need to run once
        // and ones that need to reset
        private var m_setUpClassAlready:Boolean = false;
        
        public function WordProblemGameDefault()
        {
            super();
        }
        
        override public function invoke(methodExpression:MethodExpression):void
        {
            super.invoke(methodExpression);
            
            var alias:String = methodExpression.methodAlias;
            var args:Vector.<String> = methodExpression.arguments;
            switch (alias)
            {
                case "updateItemStage":
                    var entityId:String = args[0];
                    var newStatus:int = parseInt(args[1]);
                    var currentStageComponent:CurrentGrowInStageComponent = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        CurrentGrowInStageComponent.TYPE_ID
                    ) as CurrentGrowInStageComponent;
                    currentStageComponent.currentStage = newStatus;
                    var renderComponent:RenderableComponent = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        entityId, 
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    renderComponent.renderStatus = newStatus;
                    break;
                case "getEggs":
                    var giveRewardScript:BaseGiveRewardScript = m_fixedGlobalScript.getNodeById("GiveRewardScript") as BaseGiveRewardScript;
                    giveRewardScript.giveRewardFromEntityId("egg_collection");
                    break;
            }
        }
        
        override protected function onStartingResourcesLoaded():void
        {
            // Setup a standard start screen, with login prompt
            
            var titleScreenState:TitleScreenState = new TitleScreenState(
                m_stateMachine,
                m_assetManager,
                m_logger,
                m_config,
                m_nativeFlashStage,
                false,
                null,
                null,
                true,
                true,
                m_config.getUsernamePrefix()
            );
            /*
            var titleScreenState:ExternalLoginTitleScreenState = new ExternalLoginTitleScreenState(
                m_stateMachine,
                m_assetManager,
                m_config.getTeacherCode(),
                m_config.getSaveDataKey(),
                m_config.getSaveDataToServer(),
                m_logger
            );*/
            titleScreenState.addEventListener(CommandEvent.USER_AUTHENTICATED, onUserAuthenticated);
            titleScreenState.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
            titleScreenState.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
            
            m_stateMachine.register(titleScreenState);
            
            // Automatically go to the problem selection state
            m_stateMachine.changeState(titleScreenState);
            
            // Skip to level select if we don't want to do anything with the server
            if (m_config.debugNoServerLogin)
            {
                onUserAuthenticated();
            }
        }
        
        override protected function onUserAuthenticated():void
        {
            // HACK: Should not be executing this function multiple times anyways
            // If the level manager already exists then we have already run this function, lets not do it again.
            if (!m_setUpClassAlready)
            {
                // If user authenticated, then use the cgs user object returned as the cache.
                // Otherwise create a dummy temp storage.
                if (m_logger.getCgsUser() != null)
                {
                    var cache:ICgsUserCache =  m_logger.getCgsUser();
                }
                else
                {
                    cache = new DummyCache();
                }
                
                // Load up the save data for the player
                m_playerStatsAndSaveData = new PlayerStatsAndSaveData(cache);
                
                // Load up the amount of experience points earned by the player
                m_playerXpModel = new PlayerXpModel(cache);
                
                m_playerCurrencyModel = new PlayerCurrencyModel(cache);
                
                // Set up parsers for scripts and text
                m_scriptParser = new ScriptParser(gameEngine, m_expressionCompiler, m_assetManager, m_playerStatsAndSaveData);
                m_textParser = new TextParser();
                
                // Read in definitions for all items
                var rawItemData:Object = m_assetManager.getObject("items_db");
                var itemDataSource:ItemDataSource = new ItemDataSource(rawItemData["items"]);
                m_itemDataSource = itemDataSource;
                
                // Read initial items to be given to a player 
                // (mostly for debugging purposes as the reward script can figure out from level progress
                // which rewards were given and at what stage the rewards should be in)
                var gameItemsData:Object = m_assetManager.getObject("game_items");
                
                // From a data file populate initial items that belong to player.
                // First step is to create initial data structures for each 'item'
                // Second step is to update those data structures with the progress
                var playerItemInventory:ItemInventory = new ItemInventory(m_itemDataSource, cache);
                playerItemInventory.loadInitialItems(gameItemsData.playerItems);
                m_playerItemInventory = playerItemInventory;
                
                var playerAchievementsDataSource:Object = m_assetManager.getObject("achievements");
                var playerAchievementsModel:PlayerAchievementsModel = new PlayerAchievementsModel(playerAchievementsDataSource);
                
                // Non-persistent storage of the color of buttons selected by the user
                var buttonColorData:ButtonColorData = m_playerStatsAndSaveData.buttonColorData;
                var changeButtonColorScript:ChangeButtonColorScript = new ChangeButtonColorScript(buttonColorData, playerItemInventory, itemDataSource);
                
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
                    !m_config.unlockAllLevels
                );
                m_levelManager.setToNewLevelProgression("sequence_genres_A", cache);
                
                // The selection state has a reference to available levels to play.
                // Note is does not have access to the actual level data
                var wordProblemSelectState:WordProblemSelectState = new WordProblemSelectState(
                    m_stateMachine,
                    m_config,
                    m_levelManager,
                    m_assetManager,
                    m_playerItemInventory,
                    m_itemDataSource,
                    m_logger,
                    m_nativeFlashStage,
                    buttonColorData
                );
                wordProblemSelectState.addEventListener(CommandEvent.GO_TO_LEVEL, onGoToLevel);
                wordProblemSelectState.addEventListener(CommandEvent.SIGN_OUT, onSignOut);
                wordProblemSelectState.addEventListener(CommandEvent.RESET_DATA, onResetData);
                wordProblemSelectState.addEventListener(CommandEvent.SHOW_ACCOUNT_CREATE, onShowAccountCreate);
                wordProblemSelectState.addEventListener(CommandEvent.GO_TO_PLAYER_COLLECTIONS, onGoToPlayerCollections);
                m_stateMachine.register(wordProblemSelectState);
                
                // Initialize all the objects related to the game state
                // As it also has a dependency on the fixed set of items belonging to the player,
                // which can only be fetched after some authentication phase.
                var wordProblemGameState:WordProblemGameState = new WordProblemGameState(
                    m_stateMachine,
                    gameEngine,
                    m_assetManager,
                    m_expressionCompiler,
                    m_expressionSymbolMap,
                    m_config,
                    m_console,
                    buttonColorData
                );
                wordProblemGameState.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
                wordProblemGameState.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
                m_stateMachine.register(wordProblemGameState);
                
                var playerCollectionState:PlayerCollectionsState = new PlayerCollectionsState(
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
                    m_fixedGlobalScript.getNodeById("ChangeCursorScript") as ChangeCursorScript,
                    changeButtonColorScript,
                    function():void
                    {
                        m_stateMachine.changeState(WordProblemSelectState);
                    },
                    buttonColorData
                );
                m_stateMachine.register(playerCollectionState);
                
                // Adding screen for new play mode
                var wordproblemCreateState:WordProblemCreateState = new WordProblemCreateState(
                    m_stateMachine,
                    m_nativeFlashStage,
                    m_mouseState,
                    m_assetManager,
                    m_gameServerRequester,
                    m_levelCompiler,
                    m_config,
                    m_playerStatsAndSaveData,
                    buttonColorData
                );
                m_stateMachine.register(wordproblemCreateState);
                
                // Link logging events to game engine
                m_logger.setGameEngine(gameEngine, wordProblemGameState);
                
                // Go directly to the level select state
                m_stateMachine.changeState(WordProblemSelectState, null);
                
                m_fixedGlobalScript.pushChild(new DrawItemsOnShelves(
                    wordProblemSelectState, 
                    m_playerItemInventory, 
                    m_itemDataSource,
                    m_assetManager, 
                    Starling.juggler
                ));
                
                // Add scripts that have logic that operate across several levels.
                // This deals with things like handing out rewards or modifying rewards
                // We need to make sure the reward script comes before the advance stage otherwise the item won't even exist
                m_fixedGlobalScript.pushChild(new PlayerXPScript(gameEngine, m_assetManager));
                m_fixedGlobalScript.pushChild(new PerformanceAndStatsScript(gameEngine));
                m_fixedGlobalScript.pushChild(new UpdateAndSaveLevelDataScript(wordProblemGameState, gameEngine, m_levelManager));
                
                m_fixedGlobalScript.pushChild(new UpdateAndSaveAchievements(gameEngine, m_assetManager, playerAchievementsModel, m_levelManager, m_playerXpModel, this.stage));
                m_fixedGlobalScript.pushChild(new DefaultGiveRewardScript(gameEngine, playerItemInventory, m_logger, gameItemsData.rewards, m_levelManager, m_playerXpModel, "GiveRewardScript"));
                m_fixedGlobalScript.pushChild(new BaseAdvanceItemStageScript(gameEngine, playerItemInventory, itemDataSource, m_levelManager, "AdvanceStageScript"));
                m_fixedGlobalScript.pushChild(new BaseRevealItemScript(gameEngine, playerItemInventory, m_levelManager, Vector.<String>(["6",
                    "7",
                    "8",
                    "9",
                    "10",
                    "11",
                    "12",
                    "13",
                    "14"]), "RevealItemScript"));
                m_fixedGlobalScript.pushChild(new CurrencyAwardedScript(gameEngine, m_playerCurrencyModel, m_playerXpModel));
                m_fixedGlobalScript.pushChild(new SummaryScript(
                    wordProblemGameState, gameEngine, m_levelManager,
                    m_assetManager, playerItemInventory, itemDataSource, m_playerXpModel, m_playerCurrencyModel,
                    true, buttonColorData, "SummaryScript"));
                m_fixedGlobalScript.pushChild(new GameStateNavigationDefault(wordProblemGameState, m_stateMachine, m_levelManager, wordproblemCreateState));
                m_fixedGlobalScript.pushChild(new UpdateAndSavePlayerStatsAndDataScript(wordProblemGameState, gameEngine, m_playerXpModel, m_playerStatsAndSaveData, m_playerItemInventory));
                m_fixedGlobalScript.pushChild(m_logger);
                
                // Look at the player's save data and change the cursor is a different one from default was equipped
                (m_fixedGlobalScript.getNodeById("ChangeCursorScript") as ChangeCursorScript).initialize(
                    playerItemInventory, itemDataSource, m_playerStatsAndSaveData.getCursorName());
                
                // Create the lock controller
                if (m_config.getLockAnonymousThreshold() >= 0)
                {
                    m_lockAnonymousAccountController = new LockAnonymousAccountController(
                        m_logger.getCgsUser(), 
                        m_levelManager, 
                        m_config.getLockAnonymousThreshold()
                    );
                }
                
                m_setUpClassAlready = true;
            }
            else
            {
                resetClientData();
                
                // Go back into the select 
                m_stateMachine.changeState(WordProblemSelectState, null);
            }
        }
        
        override protected function onStartLevel(id:String, src:String, extraLevelProgressionData:Object=null):void
        {
            // If the player is anonymous and we want to lock anonymous players then we need to
            // to prompt the create account screen
            if (m_lockAnonymousAccountController != null && m_lockAnonymousAccountController.getShouldAccountBeLocked())
            {
                var superOnStartLevelCallback:Function = super.onStartLevel;
                m_stateMachine.changeState(WordProblemSelectState, null);
                (m_stateMachine.getStateInstance(WordProblemSelectState) as WordProblemSelectState).isActive = false;
                
                onWaitShow();
                
                var registerScreen:RegisterAccountState = new RegisterAccountState(
                    m_logger.getCgsUser(),
                    m_config,
                    m_logger.getCgsApi(),
                    m_logger.getChallengeService(),
                    m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey()),
                    onRegisterCancel,
                    onRegisterSuccess,
                    "Create an account to keep playing!"
                );
                m_nativeFlashStage.addChild(registerScreen);
                
                function onRegisterCancel():void
                {
                    // Remove the screen
                    m_nativeFlashStage.removeChild(registerScreen);
                    registerScreen.dispose();
                    
                    onWaitHide();
                    (m_stateMachine.getStateInstance(WordProblemSelectState) as WordProblemSelectState).isActive = true;
                }
                
                function onRegisterSuccess():void
                {
                    // Destroy the lock controller
                    m_lockAnonymousAccountController = null;
                    
                    // During the creation of a new user, we may end up with the initial dummy anonymous user
                    // and the authenticated one which is bad since we want to assume just one user
                    var cgsApi:CgsApi = m_logger.getCgsApi();
                    if (cgsApi.userManager.userList.length > 1)
                    {
                        cgsApi.removeUser(cgsApi.userManager.userList[0]);
                    }
                    
                    // Remove the screen
                    m_nativeFlashStage.removeChild(registerScreen);
                    registerScreen.dispose();
                    
                    onWaitHide();
                    (m_stateMachine.getStateInstance(WordProblemSelectState) as WordProblemSelectState).isActive = true;
                    
                    // Start at the level the player should have gone into
                    superOnStartLevelCallback(id, src, extraLevelProgressionData);
                }
            }
            else
            {
                super.onStartLevel(id, src, extraLevelProgressionData);
            }
        }
        
        override protected function onNoNextLevel():void
        {
            m_stateMachine.changeState(WordProblemSelectState);
        }
        
        override protected function resetClientData():void
        {
            super.resetClientData();
            
            // Read initial items to be given to a player 
            // (mostly for debugging purposes as the reward script can figure out from level progress
            // which rewards were given and at what stage the rewards should be in)
            var gameItemsData:Object = m_assetManager.getObject("game_items");
            
            // From a data file populate initial items that belong to player.
            // First step is to create initial data structures for each 'item'
            // Second step is to update those data structures with the progress
            var playerItemList:Array = gameItemsData.playerItems;
            m_playerItemInventory.loadInitialItems(playerItemList);
            
            // TODO:
            // Reload save data in the item inventory
            
            // Reset item drawing for global scripts
            (m_fixedGlobalScript.getNodeById("GiveRewardScript") as BaseGiveRewardScript).resetData();
            (m_fixedGlobalScript.getNodeById("AdvanceStageScript") as BaseAdvanceItemStageScript).resetData();
            (m_fixedGlobalScript.getNodeById("RevealItemScript") as BaseRevealItemScript).resetData();
        }
        
        override protected function customSignout():void
        {
            m_playerItemInventory.componentManager.clear();
            
            m_stateMachine.changeState(TitleScreenState);
        }
        
        override protected function onLevelLoadError(levelId:String, url:String):void
        {
            onWaitHide();
            m_stateMachine.changeState(WordProblemSelectState);
            
            // Show error message that level failed to load
            var levelError:ConfirmationWidget = new ConfirmationWidget(800, 600, 
                function():DisplayObject
                {
                    return new TextField(300, 200, "Failed to load level !", GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF);
                },
                function():void
                {
                    levelError.removeFromParent(true);
                }, null, m_assetManager, m_playerStatsAndSaveData.buttonColorData.getUpButtonColor(), StringTable.lookup("ok"), null, true);
            m_stateMachine.addChild(levelError);
        }
        
        override protected function onResetData():void
        {
            super.onResetData();
            
            m_stateMachine.changeState(WordProblemSelectState);
        }
        
        /**
         * HACK: assuming the event comes from the level select state
         */
        private function onShowAccountCreate():void
        {
            (m_stateMachine.getStateInstance(WordProblemSelectState) as WordProblemSelectState).isActive = false;
            
            onWaitShow();
            
            var registerScreen:RegisterAccountState = new RegisterAccountState(
                m_logger.getCgsUser(),
                m_config,
                m_logger.getCgsApi(),
                m_logger.getChallengeService(),
                m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey()),
                onRegisterCancel,
                onRegisterSuccess,
                "Create an account to save your progress!"
            );
            m_nativeFlashStage.addChild(registerScreen);
            
            function onRegisterCancel():void
            {
                // Remove the screen
                m_nativeFlashStage.removeChild(registerScreen);
                registerScreen.dispose();
                
                onWaitHide();
                (m_stateMachine.getStateInstance(WordProblemSelectState) as WordProblemSelectState).isActive = true;
            }
            
            function onRegisterSuccess():void
            {
                // Remove the screen
                m_nativeFlashStage.removeChild(registerScreen);
                registerScreen.dispose();
                
                // During the creation of a new user, we may end up with the initial dummy anonymous user
                // and the authenticated one which is bad since we want to assume just one user
                var cgsApi:CgsApi = m_logger.getCgsApi();
                if (cgsApi.userManager.userList.length > 1)
                {
                    cgsApi.removeUser(cgsApi.userManager.userList[0]);
                }
                
                onWaitHide();
                (m_stateMachine.getStateInstance(WordProblemSelectState) as WordProblemSelectState).isActive = true;
                m_stateMachine.changeState(WordProblemSelectState);
            }
        }
        
        private function onGoToPlayerCollections():void
        {
            // Have the player collection screen slide in from the right
            m_stateMachine.changeState(PlayerCollectionsState, null, function(prevState:IState, nextState:IState, finishCallback:Function):void
            {
                nextState.getSprite().x = -800;
                var tween:Tween = new Tween(nextState.getSprite(), 0.3, Transitions.EASE_OUT);
                tween.animate("x", 0);
                tween.onComplete = finishCallback;
                Starling.juggler.add(tween);
            }
            );
        }
    }
}