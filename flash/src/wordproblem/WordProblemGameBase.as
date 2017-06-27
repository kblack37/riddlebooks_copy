package wordproblem
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.geom.Rectangle;
    import flash.utils.getQualifiedClassName;
    
    import cgs.Audio.Audio;
    import cgs.Cache.ICgsUserCache;
    import cgs.internationalization.StringTable;
    import cgs.user.ICgsUser;
    import cgs.utils.FlashContext;
    
    import dragonbox.common.console.Console;
    import dragonbox.common.console.IConsole;
    import dragonbox.common.console.IConsoleInterfacable;
    import dragonbox.common.console.expression.MethodExpression;
    import dragonbox.common.dispose.IDisposable;
    import dragonbox.common.expressiontree.WildCardNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.expressiontree.compile.LatexCompiler;
    import dragonbox.common.math.vectorspace.RealsVectorSpace;
    import dragonbox.common.state.IState;
    import dragonbox.common.state.StateMachine;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.LoadingSpinner;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.XString;
    
    import starling.core.Starling;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.display.Stage;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.engine.GameEngine;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.BarModelLevelCreator;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.level.LevelCompiler;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.objectives.BaseObjective;
    import wordproblem.engine.scripting.ScriptParser;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.TextParser;
    import wordproblem.level.LevelNodeCompletionValues;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.log.AlgebraAdventureLogger;
    import wordproblem.log.GameServerRequester;
    import wordproblem.player.ChangeCursorScript;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.resource.FlashResourceUtil;
    import wordproblem.resource.bundles.ResourceBundle;
    import wordproblem.saves.DummyCache;
    import wordproblem.scripts.layering.Layering;
    import wordproblem.state.WordProblemGameState;
    import wordproblem.state.WordProblemLoadingState;
    
    /**
     * For each build target we create a subclass of this.
     * 
     * The main difference for each target is just the configuration settings that is loads and
     * the resources it should use.
     */
    public class WordProblemGameBase extends starling.display.Sprite implements IDisposable, IConsoleInterfacable
    {
        [Embed(source="/../assets/fonts/Immortal.ttf", fontName="Immortal", mimeType="application/x-font-truetype", embedAsCFF="false")]
        private const Immortal:Class;
        [Embed(source="/../assets/fonts/Monofonto.ttf", fontName="Monofonto", mimeType="application/x-font-truetype", embedAsCFF="false")]
        private const Monofonto:Class;
        [Embed(source="/../assets/fonts/Bookworm.ttf", fontName="Bookworm", mimeType="application/x-font-truetype", embedAsCFF="false")]
        private const Bookworm:Class;
        
        [Embed(source="/gameconfig/predefined_layouts.xml", mimeType="application/octet-stream")] 
        private static const PREDEFINED_LAYOUTS:Class;
        
        /**
         * Expose the game engine so other objects can directly listen to relevant game events
         */
        public var gameEngine:IGameEngine;
        
        /**
         * A switch between the highest level screens of the game, like the splash
         * screen, level select, and actual gameplay state.
         */
        protected var m_stateMachine:StateMachine;
        
        /**
         * The root flash display layer (this is on top of starling)
         */
        protected var m_nativeFlashStage:flash.display.Stage;
        
        /**
         * The root starling display layer
         */
        protected var m_containerStage:starling.display.Stage;

        /**
         * The flash context stores all parameters values passed in from a url when the
         * game launched.
         */
        protected var m_flashContext:FlashContext;
        
        /**
         * Manage the ticks of time.
         */
        protected var m_time:Time;
        
        /**
         * Manager all mouse events funnelling through the application
         */
        protected var m_mouseState:MouseState;
        
        /**
         * Developer console used for debugging purposes
         */
        protected var m_console:IConsole;
        
        /**
         * The controller to handle the playthrough of levels.
         * ??? Not initialized in the base class, subclass needs to create it
         * somewhere in the subclass since it requires a user to be logged in.
         */
        protected var m_levelManager:WordProblemCgsLevelManager;
        
        /**
         * This object is responsible for holding all resources this particular build requires.
         * All assets are loaded and fetched through this interface.
         */
        protected var m_assetManager:AssetManager;
        
        protected var m_config:AlgebraAdventureConfig;
        
        /**
         * Parse the level xml into a data structure.
         */
        protected var m_levelCompiler:LevelCompiler;
        
        protected var m_expressionCompiler:IExpressionTreeCompiler;
        protected var m_expressionSymbolMap:ExpressionSymbolMap;
        
        /**
         * These are the collection of saved aggregate stats data and player decisions.
         * Level scripts may rely on them to customize the content.
         * (need to manually initialize later)
         */
        protected var m_playerStatsAndSaveData:PlayerStatsAndSaveData;
        
        /**
         * Parse level specific logic into a tree structure (need to manually initialize later)
         */
        protected var m_scriptParser:ScriptParser;
        
        /**
         * Parse text content formatted in xml into a DOM format. (need to manually initialize later)
         */
        protected var m_textParser:TextParser;
        
        /**
         * The spinner is used to indicate that some loading is in progress.
         * It should block all interactions with the rest of the screen
         */
        protected var m_loadingScreen:DisplayObjectContainer;
        
        /**
         * This quad is used to block out mouse events on the stage3d layer.
         * The reason is that the block sprite on the flash layer still allows the options button to be clicked
         */
        protected var m_disablingStage3dQuad:Quad;
        
        /**
         * For logging to Server. This is an updatable script that must be added to the m_fixedGlobalScript
         * by the subclass.
         */
        protected var m_logger:AlgebraAdventureLogger;
        
        // Logical scripts that were supposed to be instantiated at the level of the old GameEngine are pushed in here
        // This is because the level select is also a part of the game world.
        // Functionality like pasting dialogs and handing out rewards should be general across all these screens which is
        // why they need to exist so high up in this chain.
        protected var m_fixedGlobalScript:ScriptNode;
        
        /**
         * This serves as the interface that fetches levels remotely. This is supposed to allow for
         * immediate play of newly created problems without having to run offline scripts to generate
         * the appropriate xml level file.
         */
        protected var m_levelCreator:BarModelLevelCreator;
        
        /**
         * This serves as the interface to communicate with the server to fetch and save information
         * that is not provided by cgs common. For example the saving of problems created by the user.
         */
        protected var m_gameServerRequester:GameServerRequester;
        
        private var m_resourceLoadFinishedOnNextFrame:Boolean;
        private var m_isPaused:Boolean;
        private var m_wasMusicPlayingBeforePause:Boolean;
        
        public function WordProblemGameBase()
        {
            m_isPaused = false;
        }
        
        public function getObjectAlias():String
        {
            return "Main";
        }
        
        public function getSupportedMethods():Vector.<String>
        {
            const methods:Vector.<String> = Vector.<String>([
                "start",
                "createUsers",
                "unlock",
                "logout",
                "load"
            ]);
            
            return methods;
        }
        
        public function getMethodDetails(methodName:String):String
        {
            var details:String = "";
            if (methodName == "start")
            {
                details = "Start a level with a given node id. Pass name of node in progression.";
            }
            else if (methodName == "unlock")
            {
                details = "Toggle whether levels should lock on progression conditions. Enter true to make all levels playable.";
            }
            else if (methodName == "load")
            {
                details = "Load and start level from a remote source based on the qid";
            }
            return details;
        }
        
        public function invoke(methodExpression:MethodExpression):void
        {
            const alias:String = methodExpression.methodAlias;
            const args:Vector.<String> = methodExpression.arguments;
            switch (alias)
            {
                case "start":
                    this.onGoToLevel(null, args[0]);
                    break;
                case "createUsers":
                    var numUsers:int = parseInt(args[0]);
                    var usernamePrefix:String = args[1];
                    var i:int;
                    for (i = 0; i < numUsers; i++)
                    {
                        var playtestName:String = usernamePrefix + i;
                        m_logger.getCgsApi().registerUser(
                            m_logger.getCgsUserProperties(false, null),
                            playtestName,
                            playtestName,
                            null,
                            null
                        );
                    }
                    break;
                case "unlock":
                    m_levelManager.doCheckLocks = !XString.stringToBool(args[0]);
                    break;
                case "logout":
                    onSignOut();
                    break;
                case "load":
                    this.onGoToLevel(null, args[0]);
                    break;
            }
        }
        
        override public function dispose():void
        {
            m_containerStage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            m_mouseState.dispose();
            m_stateMachine.dispose();
            
            super.dispose();
        }
        
        /**
         * Set up the initialization params for the application.
         */
        public function initialize(nativeFlashStage:flash.display.Stage, gameConfig:AlgebraAdventureConfig):void
        {
            m_nativeFlashStage = nativeFlashStage;
            m_containerStage = this.stage;
            
            // To bootstrap the resource loading process we have a fixed location for the
            // game config file to be loaded. It is either embedded or in a hard coded url
            // The config contains more specific information about other important files that
            // need to be loaded to instantiate the game.
            // The config contains the name of resource bundles to load.
            // It also points to the level sequence to use
            m_config = gameConfig;
            
            m_gameServerRequester = new GameServerRequester(m_config);
            m_levelCreator = new BarModelLevelCreator(m_gameServerRequester);
            
            m_time = new Time();
            m_mouseState = new MouseState(m_containerStage, nativeFlashStage);
            
            var forceUid:String = null;
            var flashContext:FlashContext = new FlashContext(nativeFlashStage);
            if (flashContext.containsFlashVar("uid"))
            {
                forceUid = flashContext.getFlashVar("uid");
            }
            
            // NOTE: The config is NOT loaded at this point,
            // So the resource path and https setting are not what the final value should be yet
            // Initial settings need to be hardcoded if any dynamic loading is occuring before the config is
            // loaded. (This includes the config itself being loaded, although normally we should be fine loading
            // from a relative url)
            var resourcePathBase:String = m_config.getResourcePathBase();
            if (resourcePathBase != null)
            {
                var httpPrefix:String = m_config.getUseHttps() ? "https://" : "http://";
                resourcePathBase = httpPrefix + resourcePathBase;
            }
            m_assetManager = new AssetManager(1, false, null);
            
            // We need to make sure the resources needed to get a basic loading/wait
            // screen are part of the resource management system.
            // We need this to display to the user at least while we load in other resources
            var loadingScreenResources:Vector.<ResourceBundle> = gameConfig.getResourceBundlesByName("loadingScreen");
            m_assetManager.loadResourceBundles(loadingScreenResources, null, function():void
            {
                // We assume that the loading screen assets are loaded instantly, no need to wait
            });
            
            // Once we are sure the assets in the loading screen are set up we know we are able to display
            // that screen while we load any other bundles specific to a version
            // This class contains the highlevel application game states/screens
            // Commonly this includes login/splashscreen, level select, and most importantly the gameplay screen
            // Read the total display resolution from the config file
            var width:Number = m_config.getWidth();
            var height:Number = m_config.getHeight();
            Starling.current.stage.stageWidth  = width;
            Starling.current.stage.stageHeight = height;
            nativeFlashStage.frameRate = m_config.getFps();
            
            m_disablingStage3dQuad = new Quad(width, height, 0x000000);
            m_disablingStage3dQuad.alpha = 0.01;
            m_stateMachine = new StateMachine(width, height);
            
            // Only set up the simple load wait screen by default
            var loadingScreenState:WordProblemLoadingState = new WordProblemLoadingState(
                m_stateMachine,
                m_config.getWidth(),
                m_config.getHeight(),
                m_assetManager
            );
            m_stateMachine.register(loadingScreenState);
            
            // HACK: For some reason showing this for the copilot causes a stage 3d error.
            // Cannot render this yet
            var usingCopilot:Boolean = true;
            if (!usingCopilot)
            {
                m_stateMachine.changeState(loadingScreenState);
            }
            
            addChild(m_stateMachine.getSprite());
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            
            // Initialize the text strings embeded in the game
            // We need to pass in the embedded class containing the text data to the string table.
            // Create the engine after initial resources loaded
            StringTable.initialize(gameConfig.getLocalizationClassForStringTable(), false);
            
            // While this process is taking place we should perhaps play some background movie
            // that we have hardcoded to embed. This movie thus becomes immediately available to use
            // at this point. Show wait screen while dynamic resources load
            //onWaitShow();
            
            // The first thing to load is the configuration settings file
            var gameBaseReference:WordProblemGameBase = this;
            var configurationResources:Vector.<ResourceBundle> = gameConfig.getResourceBundlesByName("config");
            m_assetManager.loadResourceBundles(configurationResources, null, function():void
            {
                // At this point the game config is not fully populated.
                // More fine grained configuration settings need to be loaded in later
                // (i.e. logging parameters and possible locations for other resources)
                var configXml:XML = m_assetManager.getXml("config");
                gameConfig.readConfigFromData(configXml);
                GameFonts.DEFAULT_FONT_NAME = gameConfig.getDefaultFontFamily();
                
                var resourcePathBase:String = m_config.getResourcePathBase();
                if (resourcePathBase != null)
                {
                    var httpPrefix:String = m_config.getUseHttps() ? "https://" : "http://";
                    resourcePathBase = httpPrefix + resourcePathBase;
                }
                m_assetManager.resourcePathBase = resourcePathBase;
                
                // Asset and resource initialization
                // At the start of the application dynamically create the texture atlas structure for the
                // bundles of images that have not already formatted into spritesheets
                var expressionCompiler:IExpressionTreeCompiler = new LatexCompiler(new RealsVectorSpace());
                expressionCompiler.setDynamicVariableInformation(WildCardNode.WILD_CARD_SYMBOLS, WildCardNode.createWildCardNode);
                m_expressionCompiler = expressionCompiler;
                
                var levelCompiler:LevelCompiler = new LevelCompiler(
                    expressionCompiler,
                    new PREDEFINED_LAYOUTS().toString()
                );
                m_levelCompiler = levelCompiler;
                
                // If the teacher code in the config is set, it will override any code that attempted to be set here
                if (flashContext.containsFlashVar(FlashContext.TEACHER_CODE_KEY) && m_config.getTeacherCode() == null)
                {
                    m_config.setTeacherCode(flashContext.getFlashVar(FlashContext.TEACHER_CODE_KEY));
                }
                
                // Check if console should be created
                if (m_config.getEnableConsole())
                {
                    m_console = new Console(nativeFlashStage);
                    m_console.registerConsoleInterfacable(gameBaseReference);
                }
                
                // Initialize the api to the cgs services.  This initialization occurs within the Logger which sets the cgs User Properties first.
                m_logger = new AlgebraAdventureLogger(m_config, forceUid, onUserAuthenticated, m_mouseState);
                
                // Instantiate the scripts that are going to execute across from different levels.
                // This is logic that is common to every played level
                var globalSequenceScript:ConcurrentSelector = new ConcurrentSelector(-1);
                globalSequenceScript.pushChild(new Layering(m_stateMachine.getSprite(), m_mouseState));
                m_fixedGlobalScript = globalSequenceScript;
                
                var startingBundles:Vector.<ResourceBundle> = gameConfig.getResourceBundlesByName("allResources");
                m_assetManager.loadResourceBundles(startingBundles, null, function onComplete():void
                {
                    //onWaitHide();
                    var audioXml:XML = m_assetManager.getXml("audio");
                    if (audioXml != null)
                    {
                        // Initialize all non-streaming audio sources using the cgs common library
                        var nonStreamingAudioLib:Audio =  Audio.instance;
                        
                        // Modify the url property of the xml to use the base path if specified
                        if (resourcePathBase != null)
                        {
                            var audioTypes:XMLList = audioXml.child("type");
                            for each (var audioType:XML in audioTypes)
                            {
                                var sounds:XMLList = audioType.child("sound");
                                for each (var sound:XML in sounds)
                                {
                                    if (sound.hasOwnProperty("@url"))
                                    {
                                        var url:String = sound.@url;
                                        url = m_assetManager.stripRelativePartsFromPath(url, resourcePathBase);
                                        sound.@url = url;
                                    }
                                }
                            }
                        }
                        
                        nonStreamingAudioLib.init(Vector.<XML>([audioXml]), m_assetManager);
                    }
                    
                    m_expressionSymbolMap = new ExpressionSymbolMap(m_assetManager);
                    
                    // Game engine is the object that plays and renders the levels
                    gameEngine = new GameEngine(
                        m_expressionCompiler,
                        m_assetManager,
                        m_expressionSymbolMap,
                        width,
                        height,
                        m_mouseState
                    );
                    
                    // For commonly re-used textures that are derived from a fla source
                    // we need to specify the sampling box.
                    var flaTextureClass:Vector.<Class> = Vector.<Class>([Art_Brain, Art_StarBurst, Art_YellowArch, Art_YellowGlow,
                        Art_BrainFrontBgA, Art_BrainFrontBgB, Art_BrainFrontBgC, Art_BrainLargeFront,
                        Art_LockRed,
                        Art_LockGrey,
                        Art_GemBlueBlank, Art_GemBlueCenter, Art_GemBlueFilled,
                        Art_GemGreenBlank, Art_GemGreenCenter, Art_GemGreenFilled,
                        Art_GemOrangeBlank, Art_GemOrangeCenter, Art_GemOrangeFilled,
                        Art_TrophyBronze, Art_TrophyGold, Art_TrophySilverLong, Art_TrophySilverShort
                    ]);
                    var flaTextureScale:Vector.<Number> = Vector.<Number>([1, 0.17, 1, 1,
                        1, 1, 1, 1,
                        0.4,
                        1.0,
                        1, 1, 1,
                        1, 1, 1,
                        1, 1, 1,
                        1, 1, 1, 1
                    ]);
                    // Need to take into account scaling we defined above
                    var flaTextureBoxes:Vector.<Rectangle> = Vector.<Rectangle>([
                        new Rectangle(0, 0, 56, 38),
                        new Rectangle(0, 0, 156, 156),
                        new Rectangle(0, 0, 113, 45),
                        new Rectangle(0, 0, 183, 183),
                        new Rectangle(79, 49.25, 157.95, 98.55),
                        new Rectangle(91.8, 61, 183.55, 122),
                        new Rectangle(102.85, 68.4, 205.75, 136.8),
                        new Rectangle(160, 92.35, 320, 184.75),
                        new Rectangle(0, 0, 64, 97),
                        new Rectangle(0, 0, 160, 243),
                        new Rectangle(95.95, 88.2, 191.95, 176.4), new Rectangle(63.2, 58.1, 126.45, 116.25), new Rectangle(86.15, 79.15, 172.3, 158.35),
                        new Rectangle(78.9, 91.1, 157.85, 182.25), new Rectangle(55.1, 63.65, 110.25, 127.3), new Rectangle(71.55, 82.65, 143.15, 165.35),
                        new Rectangle(80.35, 84.15, 160.7, 168.35), new Rectangle(56.45, 59.15, 112.9, 118.3), new Rectangle(74, 77.75, 148, 155.5),
                        new Rectangle(0, 0, 119, 108.2), new Rectangle(0, 0, 107, 118.9), new Rectangle(0, 0, 120, 110.5), new Rectangle(0, 0, 120, 118.95)
                    ]);
                    
                    var i:int;
                    for (i = 0; i < flaTextureClass.length; i++)
                    {
                        var generatedTexture:Texture = FlashResourceUtil.getTextureFromFlashClass(flaTextureClass[i], null, flaTextureScale[i], flaTextureBoxes[i]);
                        m_assetManager.addTexture(getQualifiedClassName(flaTextureClass[i]), generatedTexture);
                    }
                    
                    globalSequenceScript.pushChild(new ChangeCursorScript(m_assetManager, "ChangeCursorScript"));
                    
                    m_resourceLoadFinishedOnNextFrame = true;
                });
            });
        }
        
        /**
         * Suspend the application
         * (most useful for mobile applications when they move to the background)
         */
        public function pause():void
        {
            if (!m_isPaused)
            {
                m_wasMusicPlayingBeforePause = Audio.instance.musicOn;
                
                // Must stop the audio and stop all the processes
                Audio.instance.musicOn = false;
                
                // Delete the refresh logic that was occuring on every frame
                removeEventListener(Event.ENTER_FRAME, onEnterFrame);
                m_isPaused = true;
            }
        }
        
        /**
         * Resume the application from the suspended state
         * (most useful for mobile applications to restart a background application)
         */
        public function resume():void
        {
            if (m_isPaused)
            {
                // Resume the background audio if the user had enabled it before
                Audio.instance.musicOn = m_wasMusicPlayingBeforePause;
                
                // Resume the script processes
                addEventListener(Event.ENTER_FRAME, onEnterFrame);
                m_isPaused = false;
            }
        }
        
        /**
         * The config settings indicate what resources need to be loaded at the start.
         * This callback gets triggered when it is finished.
         * 
         * All sub-classes of this application should override the default behavior if necessary
         * 
         * OVERRIDE to setup different screens
         */
        protected function onStartingResourcesLoaded():void
        {
        }
        
        /**
         * Intended to be a callback to catch a CommandEvent.GO_TO_LEVEL event
         */
        protected function onGoToLevel(event:Event, levelId:String):void
        {
            // Let the controller determine what the contents to play are
            m_levelManager.goToLevelById(levelId);
        }
        
        /**
         * Returns whether or not a level is running.
         * @return
         */
        public function isLevelRunning():Boolean
        {
            // To check that a level is running, we see if the current state is the game state.
            var gameState:IState = m_stateMachine.getStateInstance(WordProblemGameState);
            return (gameState != null && m_stateMachine.getCurrentState() == gameState);
        }
        
        /**
         * Stops the current level, if any.
         * 
         * OVERRIDE
         */
        public function stopCurrentLevel():void 
        {
            // If we are currently in the middle of a level, terminate it.
            if (isLevelRunning())
            {
                m_stateMachine.changeState(WordProblemLoadingState, null);
            }
        }
        
        /**
         * Registered callback from the controller to start a specific level.
         * 
         * @param id
         *      Cannot be null.
         * @param src
         *      The url of the level xml that should be played.
         *      If this is null
         * @param extraLevelPorgressionData
         *      Key-value pairs that give extra data of where this level fits in a larger progression.
         *      genreId: The world the level is in
         *      chapterIndex: The chapter number
         *      levelIndex: The sequence in the chapter
         *      bucketName: If the level is actually part of a larger bucket of like items
         *      previousCompletionStatus: Code in LevelNodeCompletionValues indicating whether the represented level
         *      had been previously played. Example usage is a when a level script sends data to the server only on
         *      the first instance a player has finished that level
         */
        protected function onStartLevel(id:String, src:String, extraLevelProgressionData:Object=null):void
        {
            // If we are currently in the middle of a level, terminate it and go to the new one.
            stopCurrentLevel();
            
            // Per level we have a potential two stage loading process. The first attempts
            // to load the xml level description.
            // Once the description has been loaded and parsed we load the resources specific
            // to just that level.
            // We can use the same loading/wait screen that was shown when initial resource bundles
            // were loaded.
            // Show loading screen until the dynamic resources have been fetched
            m_stateMachine.changeState(WordProblemLoadingState, null);
            
            // After the xml has been loaded, find the resources
            var levelResourceKeyName:String = "level_" + id;
            var levelData:String = m_assetManager.getXml(levelResourceKeyName);
            if (levelData == null)
            {
                if (src != null)
                {
                    m_assetManager.enqueueWithName(src, levelResourceKeyName);
                    m_assetManager.loadQueue(function(ratio:Number):void
                    {
                        (m_stateMachine.getStateInstance(WordProblemLoadingState) as WordProblemLoadingState).setLoadingRatio(ratio);
                        if (ratio >= 1.0)
                        {
                            onLevelLoaded();
                        }
                    });
                }
                else
                {
                    m_levelCreator.loadLevelFromId(parseInt(id), function(problemXml:XML):void
                    {
                        m_assetManager.addXml(levelResourceKeyName, problemXml);
                        onLevelLoaded();
                    });
                }
            }
            else
            {
                // The level description has already been cached and can be immediately retrieved
                // from the asset manager.
                onLevelLoaded();
            }
            
            function onLevelLoaded():void
            {
                // Once the level configurations have been loaded we can start the game.
                var levelXml:XML = m_assetManager.getXml(levelResourceKeyName);
                if (levelXml == null)
                {
                    // Break out if we can't find the level data, show some error somewhere.
                    onLevelLoadError(id, src);
                }
                else
                {
                    startLevelFromXmlAndExtraData(id, levelXml, extraLevelProgressionData);
                }
            }
        }
        
        protected function startLevelFromXmlAndExtraData(id:String, levelXml:XML, extraLevelProgressionData:Object=null):void
        {
            // Check if the level to start is bound to some genre
            // Get a reference to the level node object, check that it does belong to a genre
            // One use is so we can render the correct creature in the win summary screen.
            var genreId:String = null;
            var chapterIndex:int = -1;
            var levelIndex:int = -1;
            var bucketName:String = null;
            var previousCompletionStatus:int = LevelNodeCompletionValues.UNKNOWN;
            var objectives:Vector.<BaseObjective> = null;
            if (extraLevelProgressionData != null)
            {
                if (extraLevelProgressionData.hasOwnProperty("genreId"))
                {
                    genreId = extraLevelProgressionData.genreId;
                }
                
                if (extraLevelProgressionData.hasOwnProperty("chapterIndex"))
                {
                    chapterIndex = extraLevelProgressionData.chapterIndex;
                }
                
                if (extraLevelProgressionData.hasOwnProperty("levelIndex"))
                {
                    levelIndex = extraLevelProgressionData.levelIndex;
                }
                
                if (extraLevelProgressionData.hasOwnProperty("previousCompletionStatus"))
                {
                    previousCompletionStatus = extraLevelProgressionData.previousCompletionStatus;
                }
                
                if (extraLevelProgressionData.hasOwnProperty("objectives"))
                {
                    objectives = extraLevelProgressionData.objectives;
                }
            }
            
            // When a level has been selected, we parse the data and load any resources needed by that
            // level before starting the game
            var problemData:WordProblemLevelData = m_levelCompiler.compileWordProblemLevel(
                levelXml,
                id,
                levelIndex,
                chapterIndex,
                genreId,
                m_config, 
                m_scriptParser, 
                m_textParser,
                objectives
            );
            problemData.previousCompletionStatus = previousCompletionStatus;
            
            // Perform post process alterations to the problems based on properties
            // coming from the level progression node
            if (extraLevelProgressionData != null)
            {
                // Add skippable property if defined
                if (extraLevelProgressionData.hasOwnProperty("skippable"))
                {
                    problemData.skippable = extraLevelProgressionData.skippable;
                }
                
                // Override some of the rules
                // Consider scenarios where levels by default have a rule set depending on
                // bar model type. However, we may have one-off levels where it has slightly 
                // different rules that the original ones
                if (extraLevelProgressionData.hasOwnProperty("rules"))
                {
                    var levelRules:LevelRules = problemData.getLevelRules();
                    var rulesToOverride:Object = extraLevelProgressionData.rules;
                    for (var ruleName:String in rulesToOverride)
                    {
                        levelRules[ruleName] = rulesToOverride[ruleName];
                    }
                }
                
                if (extraLevelProgressionData.hasOwnProperty("tags"))
                {
                    problemData.tags = extraLevelProgressionData["tags"];
                }
                
                if (extraLevelProgressionData.hasOwnProperty("difficulty"))
                {
                    problemData.difficulty = extraLevelProgressionData["difficulty"];
                }
                
                // Get whether this level should pre-populate some of the data for the equation
                if (extraLevelProgressionData.hasOwnProperty("prepopulateEquation"))
                {
                    problemData.prepopulateEquationData = extraLevelProgressionData["prepopulateEquation"];
                }
                
                if (extraLevelProgressionData.hasOwnProperty("performanceState"))
                {
                    problemData.statistics.deserialize(extraLevelProgressionData["performanceState"]);
                }
            }
            
            // Load the images specific to this problem into the asset manager.
            // Note that these images need to be later cleared out on the exit of a level
            // If several levels share common images it might be a good idea just to keep the textures cached.
            var extraResourcesLoaded:Boolean = false;
            var numExtraResources:int = 0;
            var imagesToLoad:Vector.<String> = problemData.getImagesToLoad();
            
            // For now we will use the source exactly as the id to fetch the images
            // this will free the id for images from naming restrictions and allow us
            // to easily detect if an image was already loaded
            for each (var imageSourceName:String in imagesToLoad)
            {
                if (m_assetManager.getTexture(imageSourceName) == null)
                {
                    numExtraResources++;
                    m_assetManager.enqueueWithName(imageSourceName, imageSourceName);
                }
            }
            
            // Texture atlas and audio can be directly loaded via starling's built-in asset manager functionality
            for each (var audioDataPart:Object in problemData.getAudioData())
            {
                // Only load the audio if it is of a url type
                if (audioDataPart.type == "url")
                {
                    var audioUrl:String = audioDataPart.src;
                    numExtraResources++;
                    m_assetManager.enqueue(audioUrl);    
                }
            }
            
            for each (var atlasList:Vector.<String> in problemData.getTextureAtlasesToLoad())
            {
                numExtraResources++;
                m_assetManager.enqueue(atlasList[0], atlasList[1]);
            }
            
            if (numExtraResources > 0)
            {
                m_assetManager.loadQueue(function(ratio:Number):void
                {
                    (m_stateMachine.getStateInstance(WordProblemLoadingState) as WordProblemLoadingState).setLoadingRatio(ratio);
                    if (ratio == 1.0)
                    {
                        extraResourcesLoaded = true;
                        resourceBatchLoaded();
                    }
                });
            }
            else
            {
                extraResourcesLoaded = true;
                resourceBatchLoaded();
            }
            
            function resourceBatchLoaded():void
            {
                if (extraResourcesLoaded)
                {
                    var params:Vector.<Object> = new Vector.<Object>();
                    params.push(problemData);
                    m_stateMachine.changeState(WordProblemGameState, params);
                }
            }
        }
        
        /**
         * Registered callback on the level manager has determined there is no next level to
         * logically progress to.
         * 
         * OVERRIDE
         */
        protected function onNoNextLevel():void
        {
        }
        
        /**
         * This function gets called whenever a user has been authenticated into the game.
         * This includes guests or players that are not even connected to cgs servers.
         * 
         * OVERRIDE for custom code
         */
        protected function onUserAuthenticated():void
        {
        }
        
        /**
         * Reset all the client specific data that is volatile.
         * 
         * OVERRIDE if more parts of the game need to be cleaned or the level progression
         * is different
         */
        protected function resetClientData():void
        {
            var users:Vector.<ICgsUser> = m_logger.getCgsApi().userManager.userList;
            var cache:ICgsUserCache;
            if (users.length > 0) 
            {
                cache = users[0] as ICgsUserCache;
            }
            else
            {
                cache = new DummyCache();
            }
            m_levelManager.setToNewLevelProgression(m_levelManager.progressionResourceName, cache);
        }
        
        protected function onWaitHide():void
        {
            if (m_loadingScreen != null)
            {
                var loader:LoadingSpinner = m_loadingScreen.getChildAt(0) as LoadingSpinner;
                m_nativeFlashStage.removeChild(m_loadingScreen);
                loader.dispose();
                
                m_loadingScreen = null;
                
                m_disablingStage3dQuad.removeFromParent();
            }
        }
        
        protected function onWaitShow():void
        {
            if (m_loadingScreen == null)
            {
                // Note on mobile devices the viewport is a fraction of the screen.
                // On web browsers the swf size is a fixed pixel size
                var targetViewPort:Rectangle = Starling.current.viewPort;
                var targetWidth:Number = targetViewPort.width;
                var targetHeight:Number = targetViewPort.height;
                var container:flash.display.Sprite = new flash.display.Sprite();
                container.graphics.beginFill(0, 0.5);
                container.graphics.drawRect(0, 0, targetWidth, targetHeight);
                
                var loader:LoadingSpinner = new LoadingSpinner(12, 30, 0x193D0C, 0x42A321);
                loader.x = targetWidth * 0.5;
                loader.y = targetHeight * 0.5;
                container.addChild(loader);
                
                container.x = targetViewPort.x;
                container.y = targetViewPort.y;
                m_nativeFlashStage.addChild(container);
                m_loadingScreen = container;
                
                addChild(m_disablingStage3dQuad);
            }
        }
        
        /**
         * Trigger when the player attempts to sign out from the current account
         * 
         * DON"T OVERRIDE, override the other function
         */
        protected function onSignOut():void
        {
            customSignout();
            
            // Clear out all state player state related data
            // Their progress in the levels and the items they posess
            m_levelManager.reset();
            
            // Logout current user
            m_logger.getCgsApi().userManager.removeUser(m_logger.getCgsUser());
        }
        
        /**
         * OVERRIDE if more parts need to be cleaned up
         */
        protected function customSignout():void
        {
            
        }
        
        /**
         * OVERRIDE to change the behavior if the level data fails to load.
         * (Without modifying the behavior this will just get stuck on the loading screen)
         */
        protected function onLevelLoadError(levelId:String, url:String):void
        {
            throw new Error("ERROR: Could not load the level. id=" + levelId + " source url=" + url);
        }
        
        /**
         * Trigger when the player wants to clear out all save data associated with their account.
         * Is not the same as signing out as the data should remain deleted on next sign in and the
         * user remains authenticated.
         * 
         * OVERRIDE if more parts need to be cleared
         */
        protected function onResetData():void
        {
            // Needs to clear the data source (stuff on the server or flash player local storage) and also
            // the client side
            // It then needs to reload the game (treat this like we are loading in a brand new player)
            
            // Differs from sign out which only needs to clear client side data
            // The next login performs the reload
            var user:ICgsUser = m_logger.getCgsUser();
            if (user != null)
            {
                user.clearCache();
            }
            
            resetClientData();
        }
        
        protected function onEnterFrame(event:Event):void
        {
            if (m_resourceLoadFinishedOnNextFrame)
            {
                m_resourceLoadFinishedOnNextFrame = false;
                onStartingResourcesLoaded();
            }
            
            m_time.update();
            
            // There are some scripts that operate across multiple levels. A prime example of this is the logic that determines
            // when to hand out rewards. A condition to trigger a reward can come at any time, either during a level or after
            // they finished it and are in the level select screen.
            if (m_fixedGlobalScript != null)
            {
                m_fixedGlobalScript.visit();
            }
            
            // Update each individual screen (only if the loading screen is not visible)
            m_stateMachine.update(m_time, m_mouseState);
            
            // Need to explicitly reset mouse state after the updates have been applied to the game
            m_mouseState.onEnterFrame();
        }
    }
}