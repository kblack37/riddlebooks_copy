package gameconfig.versions.brainpopturk
{
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.system.Capabilities;
    import flash.utils.Timer;
    
    import cgs.Cache.ICgsUserCache;
    import cgs.levelProgression.nodes.ICgsLevelNode;
    import cgs.server.logging.CGSServerProps;
    
    import dragonbox.common.console.expression.MethodExpression;
    import dragonbox.common.state.IState;
    
    import levelscripts.barmodel.tutorialsv2.TutorialV2Util;
    
    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    
    import wordproblem.WordProblemGameBase;
    import wordproblem.account.ExternalIdAuthenticator;
    import wordproblem.achievements.PlayerAchievementsModel;
    import wordproblem.achievements.scripts.UpdateAndSaveAchievements;
    import wordproblem.brainpop.BrainpopApi;
    import wordproblem.currency.PlayerCurrencyModel;
    import wordproblem.currency.scripts.CurrencyAwardedScript;
    import wordproblem.engine.component.CurrentGrowInStageComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.scripting.ScriptParser;
    import wordproblem.engine.text.TextParser;
    import wordproblem.event.CommandEvent;
    import wordproblem.hints.ai.AiPolicyHintSelector;
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
    import wordproblem.state.ChallengeTitleScreenState;
    import wordproblem.state.ExternalLoginTitleScreenState;
    import wordproblem.state.TOSState;
    import wordproblem.state.WordProblemGameState;
    import wordproblem.state.WordProblemLoadingState;
    import wordproblem.state.WordProblemSelectState;
    import wordproblem.summary.scripts.SummaryScript;
    import wordproblem.xp.PlayerXpModel;
    import wordproblem.xp.scripts.RevisedPlayerXPScript;
    
    /**
     * Main application for challenge type events using the word problem game.
     */
    public class WordProblemGameBrainpopTurk extends WordProblemGameBase
    {
        private static const USE_LOGIN_SCREEN:Boolean = true;
        
        private static const DEV_SERVER_MODELS_URL:String = "cgs-dev.cs.washington.edu/cgs/php/riddlebooks/db/get_latest_models.php";
        private static const PRD_SERVER_MODELS_URL:String = "prd.ws.centerforgamescience.com/cgs/php/riddlebooks/db/get_latest_models.php"; 
        
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
        
        // HACK: On authenticate split up code/objects that only need to run once
        // and ones that need to reset
        private var m_setUpClassAlready:Boolean = false;
        
        /**
         * Main animation player
         */
        private var m_mainJuggler:Juggler;

        private var m_playerCurrencyModel:PlayerCurrencyModel;
        private var m_brainpopApi:BrainpopApi;
        
        public function WordProblemGameBrainpopTurk()
        {
            super();
            
            m_mainJuggler = new Juggler();
            m_importantNodeNamesForUser = getImportantNodeNamesInSequence();
        }
        
        override public function getSupportedMethods():Vector.<String>
        {
            const methods:Vector.<String> = super.getSupportedMethods();
            methods.push("addCoins");
            
            return methods;
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
                case "unlock":
                    m_levelManager.doCheckLocks = (args[0] == "false");
                    m_stateMachine.changeState(WordProblemSelectState);
                    break;
                case "addCoins":
                    m_playerCurrencyModel.totalCoins += 1000;
                    break;
            }
        }
        
        private function loadMapsFromDatabase(cd_id:int, 
                                              progressionIndex:int, 
                                              uid:String, 
                                              onCompleteCallback:Function):void
        {
            var urlLoader:URLLoader = new URLLoader();
            var timeoutMs:int = 15000;
            var timer:Timer = new Timer(timeoutMs, 1);
            var isPrd:Boolean = (m_config.getServerDeployment() == CGSServerProps.PRODUCTION_SERVER);
            
            //var httpPrefix:String = (m_config.getUseHttps()) ? "https" : "http";
            var serverUrl:String = "http://";
            if (isPrd) {
                serverUrl += PRD_SERVER_MODELS_URL;
            } else {
                serverUrl += DEV_SERVER_MODELS_URL;
            }

            var variables:URLVariables = new URLVariables();
            variables["cd_id"] = cd_id;
            variables["progressionIndex"] = progressionIndex;
            variables["uid"] = uid;
            if (isPrd) {
                variables["deploy"] = "prd";
                trace("Production!");
                
            }
            
            var submitProblemRequest:URLRequest = new URLRequest(serverUrl);
            submitProblemRequest.data = variables;
            submitProblemRequest.method =  URLRequestMethod.POST;
            
            urlLoader.addEventListener(flash.events.Event.COMPLETE, loaderComplete);
            urlLoader.addEventListener(flash.events.ErrorEvent.ERROR, onLoaderError);
            urlLoader.addEventListener(flash.events.AsyncErrorEvent.ASYNC_ERROR, onLoaderError);
            urlLoader.addEventListener(flash.events.NetStatusEvent.NET_STATUS, onLoaderError);
            urlLoader.addEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
            urlLoader.addEventListener(flash.events.IOErrorEvent.IO_ERROR, onLoaderError);
            urlLoader.load(submitProblemRequest);

            timer.addEventListener(TimerEvent.TIMER_COMPLETE, onLoaderError);
            timer.start();
            
            function loaderComplete(e:flash.events.Event):void
            {
                timer.stop();
                timer.removeEventListener(TimerEvent.TIMER_COMPLETE, onLoaderError);
                urlLoader.removeEventListener(flash.events.Event.COMPLETE, loaderComplete);
                urlLoader.removeEventListener(flash.events.ErrorEvent.ERROR, onLoaderError);
                urlLoader.removeEventListener(flash.events.AsyncErrorEvent.ASYNC_ERROR, onLoaderError);
                urlLoader.removeEventListener(flash.events.NetStatusEvent.NET_STATUS, onLoaderError);
                urlLoader.removeEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
                urlLoader.removeEventListener(flash.events.IOErrorEvent.IO_ERROR, onLoaderError);
            

                try {
                   var maps:Object = JSON.parse(urlLoader.data);
                   loadPolicyMap(maps["policy"]["model_detail"], progressionIndex);
                   loadHintMap(maps["hintDict"]["hint_dictionary"], progressionIndex);
                                      
                } catch (err:Error) {
                    trace("Error parsing Maps!");
                    m_assetManager.addObject(AiPolicyHintSelector.LOAD_ERROR_KEY + progressionIndex, "Error Parsing Maps! "
                        + " Name? " + err.name + " Msg? "+ err.message);
                }
                if (onCompleteCallback != null)
               {
                   onCompleteCallback();
               }
                
            }
            function onLoaderError(e:flash.events.Event):void {
                timer.stop();
                timer.removeEventListener(TimerEvent.TIMER_COMPLETE, onLoaderError);
                urlLoader.removeEventListener(flash.events.Event.COMPLETE, loaderComplete);
                urlLoader.removeEventListener(flash.events.ErrorEvent.ERROR, onLoaderError);
                urlLoader.removeEventListener(flash.events.AsyncErrorEvent.ASYNC_ERROR, onLoaderError);
                urlLoader.removeEventListener(flash.events.NetStatusEvent.NET_STATUS, onLoaderError);
                urlLoader.removeEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
                urlLoader.removeEventListener(flash.events.IOErrorEvent.IO_ERROR, onLoaderError);

                var browserVersion:String = "undetected";
                try {
                    browserVersion = ExternalInterface.call("window.navigator.userAgent.toString")
                } catch (err:Error) {
                    trace(err);
                }
                var systemIdString:String = "os: " + Capabilities.os + " version: " + Capabilities.version + " browser: " + browserVersion;
                m_assetManager.addObject(AiPolicyHintSelector.LOAD_ERROR_KEY + progressionIndex, "URLLoader error  "+systemIdString + " error text: " + e.toString() );

                if (onCompleteCallback != null)
               {
                   onCompleteCallback();
               }
            }
        }
        
        
        
        private function getFileContents(filename:String, callback:Function):void
        {
            var url:URLRequest = new URLRequest(filename);
            var loader:URLLoader = new URLLoader();
            loader.load(url);
            
            loader.addEventListener(flash.events.Event.COMPLETE, loaderComplete);
            function loaderComplete(e:flash.events.Event):void
            {
                loader.removeEventListener(flash.events.Event.COMPLETE, loaderComplete);
                callback(loader.data);
            }
        }
        
        private function loadMapsFromFiles():void 
        {
            getFileContents("../assets/data/uppolicy.out", loadPolicyMap);
            getFileContents("../assets/data/hintDict.out", loadHintMap);
        }
        
        private function loadPolicyMap(data:String, progressionIndex:int):void 
        {
            var policyMap:Object = new Object();
            // The output of the text file is available via the data property
            // of URLLoader.
            policyMap = JSON.parse(data)
           /* var tokens:Array = data.split("\n");
            trace(tokens.length + " lines!");
            var i:int;
            for (i = 1; i < tokens.length-1; i++ ) {
                
                var tokens2:Array = tokens[i].split(":");
                //"(0_0_0_?_0 = " [0.5,0.5,0\r"
                if (i < 100){
                    trace(tokens[i]);
                }
                var key:String = tokens2[0].replace(/\(/g, "").replace(/\"/g, "").replace(/\)/g, "").replace(/ /g, "")
                var value:String = tokens2[1].replace(/\],.*REMOVE/g, "").replace(/.*\]/g, "").replace(/\r/g, "").replace(/\[/g, ""); 
                if (policyMap[key] != null) {
                    trace("Duplicate key! " + key);
                    continue;
                }
                policyMap[key] = value; 
            }*/
            
            m_assetManager.addObject(AiPolicyHintSelector.POLICY_MAP_KEY+"_"+progressionIndex, policyMap);
            trace("Done policymap!");
        }
        
        private function loadHintMap(data:String, progressionIndex:int):void {
             var hintMap:Object = new Object();
                // The output of the text file is available via the data property
                // of URLLoader.
                var tokens:Array = data.split("\n");
                trace(tokens.length + " lines!");
                var i:int;
                for (i = 1; i < tokens.length-1; i++ ) {
                    
                    var tokens2:Array = tokens[i].split(":");
                    
                    hintMap[tokens2[0]] = tokens2[1]; 
                }
                m_assetManager.addObject(AiPolicyHintSelector.HINT_DICT_KEY+"_"+progressionIndex, hintMap);
                trace("Done hintmap!")
        }
        
        
        override protected function onStartingResourcesLoaded():void
        {
            // HACK: Teacher version of the game should have a special keyboard cheat to
            // unlock all the levels
            if (m_config.getEnableUnlockLevelsShortcut())
            {
                m_containerStage.addEventListener(KeyboardEvent.KEY_DOWN, function(event:KeyboardEvent):void
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
                !m_config.unlockAllLevels
            );
            
            // For the challenge, a login might be required
            // Depending on whether the link is played independently at home.
            // to detect this will need to look at the url.
            if (USE_LOGIN_SCREEN)
            {
                var titleScreenState:ExternalLoginTitleScreenState = new ExternalLoginTitleScreenState(
                    m_stateMachine,
                    m_assetManager,
                    m_config.getTeacherCode(),
                    m_config.getSaveDataKey(), 
                    m_config.getSaveDataToServer(), 
                    m_logger,
                    onContinueUserSelected, 
                    onNewUserSelected,
                    ""
                );
                titleScreenState.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
                titleScreenState.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
                titleScreenState.addEventListener(CommandEvent.USER_AUTHENTICATED, onUserAuthenticated);
                
                m_stateMachine.register(titleScreenState);
                
                // Automatically go to the problem selection state
                m_stateMachine.changeState(titleScreenState);
            }
            
            var tosState:TOSState = new TOSState(m_stateMachine, m_assetManager, m_nativeFlashStage, function():void
            {
                // When the tos is completed, we start the game for the user
                setupAndStartGameForUser();
            });
            m_stateMachine.register(tosState);
            
            // HACK: Since edmodo and brainpop release versions are running the exact same experiments
            // and they have very slightly different external login procedures we need an extra flag to switch between them.
            var useBrainPOPApi:Boolean = (m_config.getLoggingCategoryId() == 18);
            
            // Skip to level select if we don't want to do anything with the server
            if (m_config.debugNoServerLogin)
            {
                onUserAuthenticated();
            }
            else if (useBrainPOPApi)
            {
                m_brainpopApi = new BrainpopApi(
                    m_logger,
                    m_config.getTeacherCode(),
                    m_config.getServerDeployment(),
                    m_config.getSaveDataToServer(),
                    m_config.getSaveDataKey(),
                    m_config.getUseHttps(),
                    m_nativeFlashStage,
                    this.stage);
                
                // At the start, check if login has occurred, if so we can immediately start the game
                onWaitShow();
                m_brainpopApi.checkLoginStatus(function(isLoggedIn:Boolean, id:String):void
                {
                    onWaitHide();
                    if (isLoggedIn)
                    {
                        m_brainpopApi.authenticateWithBrainpopId(id, onAuthenticateSuccessWithExternalId, onAuthenticateFailWithExternalId);
                    }
                    else
                    {
                        // While at the title screen and waiting for the player to start the game, we start polling
                        // for a login to brainpop
                        m_brainpopApi.startCheckLoginPoll(3, function(id:String):void
                        {
                            m_brainpopApi.authenticateWithBrainpopId(id, onAuthenticateSuccessWithExternalId, onAuthenticateFailWithExternalId);
                        });
                    }
                });
            }
            // Since we are using this as part of Edmodo, need a case when the Edmodo login passes along the special id
            // through flash vars. Use this to perform the login
            else if (m_nativeFlashStage.loaderInfo && m_nativeFlashStage.loaderInfo.parameters && m_nativeFlashStage.loaderInfo.parameters.hasOwnProperty("data"))
            {
                var externalData:Object = JSON.parse(m_nativeFlashStage.loaderInfo.parameters.data);
                if (externalData.hasOwnProperty("ext_id") && externalData.hasOwnProperty("ext_s_id"))
                {
                    // If we get passed in a uid, assume it has come from edmodo.
                    // Attempt to login into our servers using this id (in order to fetch the correct
                    // save progress)
                    // Will need to check that an association exists between the edmodo id and our account system
                    // Brainpop api handles the same thing, should try to share that logic
                    // Edmodo will pass in a data blob
                    var passedInExternalId:String = externalData["ext_id"];
                    var externalSourceId:int = externalData["ext_s_id"];
                    onWaitShow();
                    var edmodoAuthenticator:ExternalIdAuthenticator = new ExternalIdAuthenticator(
                        m_logger,
                        m_config.getTeacherCode(),
                        m_config.getSaveDataToServer(),
                        m_config.getSaveDataKey(),
                        m_config.getUseHttps());
                    edmodoAuthenticator.authenticateWithExternalId(passedInExternalId, externalSourceId, 
                        onAuthenticateSuccessWithExternalId, onAuthenticateFailWithExternalId);
                }
            }
        }
        
        private function onContinueUserSelected():void
        {
            // Attempt to login with the brainpop user first, if that fails then continue as a guest with the saved user id
            onWaitShow();
            
            if (m_brainpopApi != null)
            {
                m_brainpopApi.stopCheckLoginPoll();
                m_brainpopApi.checkLoginStatus(function(isLoggedIn:Boolean, id:String):void
                {
                    onWaitHide();
                    if (isLoggedIn)
                    {
                        m_brainpopApi.authenticateWithBrainpopId(id, onAuthenticateSuccessWithExternalId, onAuthenticateFailWithExternalId);
                    }
                    else
                    {
                        var titleScreen:ExternalLoginTitleScreenState = m_stateMachine.getStateInstance(ExternalLoginTitleScreenState) as ExternalLoginTitleScreenState;
                        titleScreen.continueGuestUser();
                    }
                });
            }
            else
            {
                var titleScreen:ExternalLoginTitleScreenState = m_stateMachine.getStateInstance(ExternalLoginTitleScreenState) as ExternalLoginTitleScreenState;
                titleScreen.continueGuestUser();
            }
        }
        
        private function onNewUserSelected():void
        {
            // Attempt to login with the brainpop user first, if that fails then continue as a new user
            onWaitShow();
            
            if (m_brainpopApi != null)
            {
                m_brainpopApi.stopCheckLoginPoll();
                m_brainpopApi.checkLoginStatus(function(isLoggedIn:Boolean, id:String):void
                {
                    onWaitHide();
                    if (isLoggedIn)
                    {
                        m_brainpopApi.authenticateWithBrainpopId(id, onAuthenticateSuccessWithExternalId, onAuthenticateFailWithExternalId);
                    }
                    else
                    {
                        var titleScreen:ExternalLoginTitleScreenState = m_stateMachine.getStateInstance(ExternalLoginTitleScreenState) as ExternalLoginTitleScreenState;
                        titleScreen.startNewGuestUser();
                    }
                });
            }
            else
            {
                var titleScreen:ExternalLoginTitleScreenState = m_stateMachine.getStateInstance(ExternalLoginTitleScreenState) as ExternalLoginTitleScreenState;
                titleScreen.startNewGuestUser();
            }
        }
        
        private function onAuthenticateSuccessWithExternalId():void
        {
            // If we successfully login with brainpop we assume all the cgs user stuff has been set within the api
            // At this point we can start the game as normal
            onUserAuthenticated();
            onWaitHide();
        }
        
        private function onAuthenticateFailWithExternalId():void
        {
            // If authentication fails we can resume the polling for brainpop or continue the gameplay as a guest
            onWaitHide();
        }
        
        /*
        HACK: Grade is coming in on an activity start. This bit of information is required to configure the game so we
        must wait for that signal rather than the user authentication.
        */
        override protected function onUserAuthenticated():void
        {
            // Usage of custom hints is a/b test condition
            var blockForTos:Boolean = false;
            if (m_logger.getCgsUser() != null)
            {
                // If a version requires a TOS, then it should show up after authentication has occurred
                if (m_config.getTosKey() != null && m_config.getTosKey().length > 0)
                {
                    m_stateMachine.changeState(TOSState, Vector.<Object>([m_logger.getCgsUser()]));
                    blockForTos = true;
                }
            }
            
            if (!blockForTos)
            {
                setupAndStartGameForUser();
            }
        }
        
        private function setupAndStartGameForUser():void
        {
            // HACK: Should not be executing this function multiple times anyways
            // If the level manager already exists then we have already run this function, lets not do it again.
            
            
            if (!m_setUpClassAlready)
            {
                setUpGameForFirstTime(-1);
                var waitForAdditionalResources:Boolean = false;
                
                // Usage of custom hints is a/b test condition
                if (m_logger.getCgsUser() != null)
                {
                    var aiHints:Boolean = m_logger.getCgsUser().getVariableValue("AiHints");
                    var conditionId:int = m_logger.getCgsUser().getUserConditionId();
                    
                    //REMOVE
                    //aiHints = true;
                    //conditionId = 123;
                    //conditionId = -3;//Override just for debug
                    trace("Uid: " + m_logger.getCgsUser().userId +  "Condition: " + conditionId + " AI Hints? " + aiHints);
                    m_playerStatsAndSaveData.useCustomHints = false;
                    
                    if (aiHints) 
                    {
                        m_playerStatsAndSaveData.useAiHints = true;
                        //For debugging may want to load maps from files to eliminate server dependency
                        var progIndex:int;
                        var requiredMapsToLoad:int = AiPolicyHintSelector.NUM_PROGRESSION_INDICIES;
                        waitForAdditionalResources = requiredMapsToLoad > 0;
                        var mapsFinished:int = 0;
                        for (progIndex = 0; progIndex < requiredMapsToLoad; progIndex++) 
                        {
                            try{
                                loadMapsFromDatabase(conditionId, progIndex, m_logger.getCgsUser().userId, onMapLoaded);
                            } catch (err:Error) {
                                trace("Error loading maps!");
                                onMapLoaded();
                            }
                        }
                        
                        function onMapLoaded():void
                        {
                            mapsFinished++;
                            if (mapsFinished >= requiredMapsToLoad)
                            {
                                goToGame();
                            }
                        }
                    }
                    
                    //loadMapsFromFiles(); 
                } 
                
                if (!waitForAdditionalResources)
                {
                    goToGame();
                }
                else
                {
                    m_stateMachine.changeState(WordProblemLoadingState);
                }
                
                m_setUpClassAlready = true;
            }
        }
        
        private function goToGame():void
        {
            // Start the right level based on the logged in user's save data
            if (m_config.allowLevelSelect)
            {
                m_stateMachine.changeState(WordProblemSelectState);
            }
            else
            {
                m_levelManager.goToNextLevel();
            }
        }
        
        public function playerFinishedTheRequiredExperimentSets():Boolean
        {
            var allRequiredSetsFinished:Boolean = true;
            var setNamesRequired:Vector.<String> = Vector.<String>(["addition_mastery", "subtract_mastery"]);
            for each (var setName:String in setNamesRequired)
            {
                var nodeThatShouldBeComplete:ICgsLevelNode = m_levelManager.getNodeByName(setName);
                if (nodeThatShouldBeComplete != null)
                {
                    if (nodeThatShouldBeComplete.completionValue != LevelNodeCompletionValues.PLAYED_SUCCESS)
                    {
                        allRequiredSetsFinished = false;
                        break;
                    }
                }
                else
                {
                    allRequiredSetsFinished = false;
                    break;
                }
            }
            
            return allRequiredSetsFinished;
        }
        
        /**
         * 
         * @param userGrade
         *      If -1, then grade for that user is kept unspecified
         */
        private function setUpGameForFirstTime(userGrade:int):void
        {
            // The cache saves user data either locally or on the servers
            var cache:ICgsUserCache = null;
            if (m_logger.getCgsUser() != null) 
            {
                cache = m_logger.getCgsUser();
            }
            else
            {
                cache = new DummyCache();
            }
            
            // Load up the save data for the player
            var defaultDecisions:Object = {
                color:"start",
                job: TutorialV2Util.JOB_NINJA,
                gender: "f"
            };
            m_playerStatsAndSaveData = new PlayerStatsAndSaveData(cache, defaultDecisions);
            m_playerStatsAndSaveData.useCustomHints = false;
            
            // Load up the amount of experience points earned by the player
            m_playerXpModel = new PlayerXpModel(cache);
            
            var playerCurrencyModel:PlayerCurrencyModel = new PlayerCurrencyModel(cache);
            m_playerCurrencyModel = playerCurrencyModel;
            
            // Set up parsers for scripts and text
            m_scriptParser = new ScriptParser(gameEngine, m_expressionCompiler, m_assetManager, m_playerStatsAndSaveData, m_levelManager);
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
            
            // The level manager has a dependency on the login of a player
            // Thus we cannot completely initialize the levels until after login has taken place.
            // Thus POST-login is another phase for further object initialization
            // Need to wait for the level controller to signal that it is ready as well
            // Parse the level sequence file
            var levelSequenceNameToUse:String = "sequence_brainpop_turk";
            m_levelManager.setToNewLevelProgression(levelSequenceNameToUse, cache);
            
            // Non-persistent storage of the color of buttons selected by the user
            var buttonColorData:ButtonColorData = m_playerStatsAndSaveData.buttonColorData;
            var changeButtonColorScript:ChangeButtonColorScript = new ChangeButtonColorScript(buttonColorData, playerItemInventory, itemDataSource);
            
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
            wordProblemSelectState.addEventListener(CommandEvent.GO_TO_PLAYER_COLLECTIONS, onGoToPlayerCollections);
            m_stateMachine.register(wordProblemSelectState);
            
            // Initialize all the objects related to the game state
            // As it also has a dependency on the fixed set of items belonging to the player,
            // which can only be fetched after some authentication phase.
            var wordProblemGameState:WordProblemGameState = new WordProblemGameStateBrainpopTurk(
                m_stateMachine,
                gameEngine,
                m_assetManager,
                m_expressionCompiler,
                m_expressionSymbolMap,
                m_config,
                m_console,
                buttonColorData,
                m_levelManager
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
                playerCurrencyModel,
                playerAchievementsModel,
                m_itemDataSource,
                m_playerItemInventory,
                gameItemsData.types,
                gameItemsData.customizables,
                m_playerStatsAndSaveData, 
                m_fixedGlobalScript.getNodeById("ChangeCursorScript") as ChangeCursorScript, 
                changeButtonColorScript, function():void
                {
                    if (m_config.allowLevelSelect || playerFinishedTheRequiredExperimentSets())
                    {
                        m_stateMachine.changeState(WordProblemSelectState);
                    }
                    else
                    {
                        m_levelManager.goToNextLevel();
                    }
                }, 
                buttonColorData
            );
            m_stateMachine.register(playerCollectionState);
            
            // Link logging events to game engine
            m_logger.setGameEngine(gameEngine, wordProblemGameState);
            
            m_fixedGlobalScript.pushChild(new DrawItemsOnShelves(
                wordProblemSelectState, 
                m_playerItemInventory, 
                m_itemDataSource,
                m_assetManager, 
                m_mainJuggler
            ));
            
            // Add scripts that have logic that operate across several levels.
            // This deals with things like handing out rewards or modifying rewards
            // We need to make sure the reward script comes before the advance stage otherwise the item won't even exist
            m_fixedGlobalScript.pushChild(new RevisedPlayerXPScript(gameEngine, m_assetManager));
            m_fixedGlobalScript.pushChild(new PerformanceAndStatsScript(gameEngine, m_levelManager));
            m_fixedGlobalScript.pushChild(new UpdateAndSaveLevelDataScript(wordProblemGameState, gameEngine, m_levelManager));
            
            // The alteration of items might depend on the level information/save being updated first
            m_fixedGlobalScript.pushChild(new DefaultGiveRewardScript(gameEngine, playerItemInventory, m_logger, gameItemsData.rewards, m_levelManager, m_playerXpModel, "GiveRewardScript"));
            m_fixedGlobalScript.pushChild(new BaseAdvanceItemStageScript(gameEngine, playerItemInventory, itemDataSource, m_levelManager, "AdvanceStageScript"));
            m_fixedGlobalScript.pushChild(new BaseRevealItemScript(gameEngine, playerItemInventory, m_levelManager, null, "RevealItemScript"));
            m_fixedGlobalScript.pushChild(new CurrencyAwardedScript(gameEngine, playerCurrencyModel, m_playerXpModel));
            m_fixedGlobalScript.pushChild(new SummaryScript(
                wordProblemGameState, gameEngine, m_levelManager,
                m_assetManager, playerItemInventory, itemDataSource, m_playerXpModel, playerCurrencyModel,
                true, buttonColorData, "SummaryScript"));
            
            m_fixedGlobalScript.pushChild(new UpdateAndSavePlayerStatsAndDataScript(wordProblemGameState, gameEngine, m_playerXpModel, m_playerStatsAndSaveData, playerItemInventory));
            
            // Also make sure button color is saved
            changeButtonColorScript.changeToButtonColor(m_playerStatsAndSaveData.getButtonColorName());
            
            // Look at the player's save data and change the cursor is a different one from default was equipped
            (m_fixedGlobalScript.getNodeById("ChangeCursorScript") as ChangeCursorScript).initialize(
                playerItemInventory, itemDataSource, m_playerStatsAndSaveData.getCursorName());
            
            // Achievements depend on the player save data so that updates
            m_fixedGlobalScript.pushChild(new UpdateAndSaveAchievements(gameEngine, m_assetManager, playerAchievementsModel, m_levelManager, m_playerXpModel, 
                m_playerItemInventory, {}, this.stage));
            m_fixedGlobalScript.pushChild(new GameStateNavigationBrainpopTurk(this, wordProblemGameState, m_stateMachine, m_levelManager, m_config));
            m_fixedGlobalScript.pushChild(m_logger);
            
            m_fixedGlobalScript.pushChild(new RepairSaveData(gameEngine, cache, onRepairData, onSaveData));
        }
        
        override protected function onNoNextLevel():void
        {
            // For a slice of players, stopping them from playing any levels may not be the desired behavior
            // Brainpop indicated that they wanted to encourage players to replay problems they had trouble with.
            // There are some parts we DO NOT want them to replay, thus should be hidden from the level select and
            // should no longer be accessible after they have been finished
            if (playerFinishedTheRequiredExperimentSets() && !m_config.allowLevelSelect)
            {
                m_stateMachine.changeState(WordProblemSelectState);
            }
            else
            {
                m_stateMachine.changeState(PlayerCollectionsState);
            }
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
            // Reload save data in all the elements that need it.
            // (includes xp, items, other stats)
            
            // Reset item drawing for global scripts
            (m_fixedGlobalScript.getNodeById("GiveRewardScript") as BaseGiveRewardScript).resetData();
            (m_fixedGlobalScript.getNodeById("AdvanceStageScript") as BaseAdvanceItemStageScript).resetData();
            (m_fixedGlobalScript.getNodeById("RevealItemScript") as BaseRevealItemScript).resetData();
        }
        
        override protected function customSignout():void
        {
            m_playerItemInventory.componentManager.clear();
            
            m_stateMachine.changeState(ChallengeTitleScreenState);
        }
        
        override protected function onResetData():void
        {
            super.onResetData();
            
            m_stateMachine.changeState(WordProblemSelectState);
        }
        
        override protected function onEnterFrame(event:starling.events.Event):void
        {
            super.onEnterFrame(event);
            m_mainJuggler.advanceTime(m_time.currentDeltaSeconds);
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
        
        /**
         * These important names are necessary to get data repairing working as well as determining
         * the LATEST level the player should jump to on entering the game again. The latter case is to fix issues
         * where the player goes backwards in the level select, we want them to return to the latest point on the
         * next login.
         * 
         * The idea for us is that if one of these important nodes is marked as completed, then all prior
         * sets/levels should also be seen as completed.
         */
        private function getImportantNodeNamesInSequence():Vector.<String>
        {
            var importantNodeNames:Vector.<String> = new Vector.<String>();
            
            // All sequences share these same set and level names
            importantNodeNames.push(
                "1590",
                "1589",
                "addition_mastery",
                "1583",
                "subtract_mastery",
                "1584",
                "multiply_simple_mastery",
                "1585",
                "multiply_divide_simple_mastery",
                "1588",
                "multiply_divide_advanced_mastery",
                "1586",
                "two_step_add_subtract_a",
                "two_step_add_subtract_b",
                "two_step_groups_sum",
                "two_step_groups_difference",
                "two_step_groups_sum_difference",
                "1587",
                "fraction_of_whole_a",
                "fraction_of_whole_b",
                "fraction_of_whole_shaded_unshaded",
                "fraction_of_larger_basic",
                "fraction_of_larger_sum",
                "fraction_of_larger_difference",
                "fraction_of_larger_sum_difference"
            );
            
            return importantNodeNames;
        }
        
        private var m_importantNodeNamesForUser:Vector.<String>;
        private function onRepairData(masterData:Array):void
        {
            // Master data should have the list of nodes that are completed
            var numNodesCompleted:int = masterData.length;
            var maxIndexOfCompletedNode:int = -1;
            for (var i:int = 0; i < numNodesCompleted; i++)
            {
                var nodeNameCompleted:String = masterData[i];
                var indexOfName:int = m_importantNodeNamesForUser.indexOf(nodeNameCompleted);
                if (indexOfName > maxIndexOfCompletedNode)
                {
                    maxIndexOfCompletedNode = indexOfName;
                }
            }
            
            // For ALL nodes coming before the maximum one that was marked as completed,
            // they should be marked as completed as well
            // (This should have naturally occurred duing the course of play, if it didn't
            // then some data corruption occurred)
            if (maxIndexOfCompletedNode > -1)
            {
                var repairedNodeValues:Boolean = false;
                for (i = 0; i <= maxIndexOfCompletedNode; i++)
                {
                    nodeNameCompleted = m_importantNodeNamesForUser[i];
                    var nodeThatShouldBeComplete:ICgsLevelNode = m_levelManager.getNodeByName(nodeNameCompleted);
                    if (nodeThatShouldBeComplete != null)
                    {
                        if (nodeThatShouldBeComplete.completionValue != LevelNodeCompletionValues.PLAYED_SUCCESS)
                        {
                            // Need to fix this node to get the right completion value
                            var newLevelStatus:Object = {};
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
                }
                
                // Based on this max index, we should be able to figure out which level or set the user should be at as well
                // We already have a bit of save data to track the current level. There is a problem potentially where if the
                // user backs out and plays an older set, the current level becomes the old one.
                // To fix this, just always go to the next important node directly AFTER the one that is complete.
                // Always select the first uncompleted node if it is a set
                var nextNodeIndexForPlayer:int = maxIndexOfCompletedNode + 1;
                if (nextNodeIndexForPlayer < m_importantNodeNamesForUser.length)
                {
                    var nextNodeNameForPlayer:String = m_importantNodeNamesForUser[nextNodeIndexForPlayer];
                    var nextNode:ICgsLevelNode = m_levelManager.getNodeByName(nextNodeNameForPlayer);
                    if (nextNode != null)
                    {
                        if (nextNode is WordProblemLevelPack)
                        {
                            var nodesInSet:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
                            WordProblemCgsLevelManager.getLevelNodes(nodesInSet, nextNode);
                            var numNodesInSet:int = nodesInSet.length;
                            var nextNodeToPlay:WordProblemLevelLeaf = null;
                            for (i = 0; i < numNodesInSet; i++)
                            {
                                var childNode:WordProblemLevelLeaf = nodesInSet[i];
                                if (!childNode.isComplete)
                                {
                                    nextNodeToPlay = childNode;
                                    break;
                                }
                            }
                            
                            // Play first one in sequence if all are finished
                            if (nextNodeToPlay == null && nodesInSet.length > 0)
                            {
                                nextNodeToPlay = nodesInSet[0];
                            }
                            
                            m_levelManager.setNextLevelLeaf(nextNodeToPlay);
                        }
                        else if (nextNode is WordProblemLevelLeaf)
                        {
                            m_levelManager.setNextLevelLeaf(nextNode as WordProblemLevelLeaf);
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
        
        private function onSaveData():Object
        {
            // In sequence, iterate through the important node names and figure out which ones are complete
            var i:int;
            var completedNodeNames:Array = [];
            var numImportantNames:int = m_importantNodeNamesForUser.length;
            for (i = 0; i < numImportantNames; i++)
            {
                var importantName:String = m_importantNodeNamesForUser[i];
                var importantNode:ICgsLevelNode = m_levelManager.getNodeByName(importantName);
                if (importantNode != null && importantNode.completionValue == LevelNodeCompletionValues.PLAYED_SUCCESS)
                {
                    completedNodeNames.push(importantName);
                }
            }
            
            return completedNodeNames;
        }
    }
}