package wordproblem.state
{
    import cgs.Audio.Audio;
    
    import dragonbox.common.console.IConsole;
    import dragonbox.common.console.IConsoleInterfacable;
    import dragonbox.common.console.expression.MethodExpression;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.state.BaseState;
    import dragonbox.common.state.IStateMachine;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.XString;
    
    import feathers.controls.Button;
    
    import starling.display.DisplayObject;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.filters.BlurFilter;
    import starling.text.TextField;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.engine.GameEngine;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentFactory;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.level.CardAttributes;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.event.CommandEvent;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.scripts.HelpScreenViewer;
    import wordproblem.hints.scripts.TipsViewer;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.level.nodes.WordProblemLevelLeaf;
    import wordproblem.level.nodes.WordProblemLevelPack;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.player.ButtonColorData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.drag.WidgetDragSystem;
    import wordproblem.scripts.expression.TermAreaMouseScript;
    import wordproblem.settings.OptionButton;
    import wordproblem.settings.OptionsScreen;
    
    public class WordProblemGameState extends BaseState implements IConsoleInterfacable
    {
        /**
         * Reference to the main game system mostly to recieve important events
         * from the system.
         */
        private var m_gameEngine:IGameEngine;
        
        /**
         * Keep expression map is preserved across several levels.
         */
        private var m_expressionSymbolMap:ExpressionSymbolMap;
        
        private var m_assetManager:AssetManager;
        
        private var m_expressionCompiler:IExpressionTreeCompiler;
        
        /**
         * This is the overall root for pre-baked logic
         * Used to enhance the basic levels.
         * This logic should execute along side scripts bound to specific levels
         */
        private var m_preBakedScript:ScriptNode;
        
        /**
         * Intially this contains the common set of helper characters that are accessible to
         * every level.
         * 
         * If a level wants to add a new one-off character, then it must be later stripped out when the level ends.
         */
        private var m_characterComponentManager:ComponentManager;
        
        /**
         * Configurations of game
         */
        private var m_config:AlgebraAdventureConfig;
        
        /**
         * Clicking on this option will pause the game and open up an options overlay
         */
        private var m_optionsButton:OptionButton;
        
        /**
         * This is the container for all buttons for options and blocks the entire screen.
         * 
         * The options are: 
         * resume (unpause), skip, toggle music/sfx, quit level, restart level
         * Depending on the game configuration, not all of these options will be present,
         * for example for the version that replays only a single level, there is no skip or quit.
         */
        private var m_optionsScreen:OptionsScreen;
        
        /**
         * This textfield shows the player the genre, chapter, and level index that the current player is in.
         */
        private var m_levelInformationText:TextField;
        
        /**
         * When the player selects the options menu, the game should be temporarily frozen.
         */
        private var m_paused:Boolean;
        
        /**
         * Handle the turning on and off of background music while playing,
         * upon entering and exiting a level.  This variable holds the singleton audio driver.
         */
        private var m_audioDriver:Audio;
        
        /**
         * If true then all levels in this version should ignore any skip values specified in the level data
         * and just make everything skippable or everything not skippable
         */
        private var m_overrideSkip:Boolean;
        
        /**
         * If override skip is true, then all levels should use this skippable value
         */
        private var m_overrideSkipValue:Boolean;
        private var m_allowExit:Boolean;
        
        /**
         * The object is needed so the screen can alter the color of several buttons to 
         * match the one selected by the user.
         */
        private var m_buttonColorData:ButtonColorData;
        
        private var m_helpScreenViewer:HelpScreenViewer;
        
        /**
         * Used to figure out the correct indices when writing the level descriptors
         */
        protected var m_levelManager:WordProblemCgsLevelManager;
        
        public function WordProblemGameState(stateMachine:IStateMachine,
                                             gameEngine:IGameEngine,
                                             assetManager:AssetManager,
                                             compiler:IExpressionTreeCompiler, 
                                             expressionSymbolMap:ExpressionSymbolMap, 
                                             config:AlgebraAdventureConfig,
                                             console:IConsole,
                                             buttonColorData:ButtonColorData, 
                                             levelManager:WordProblemCgsLevelManager=null)
        {
            super(stateMachine);
            
            m_assetManager = assetManager;
            m_expressionCompiler = compiler;
            m_config = config;
            m_overrideSkip = m_config.overrideLevelSkippable;
            m_overrideSkipValue = m_config.overrideLevelSkippableValue;
            m_allowExit = true;
            
            m_gameEngine = gameEngine;
            m_expressionSymbolMap = expressionSymbolMap;
            m_buttonColorData = buttonColorData;
            m_levelManager = levelManager;
            
            if (console != null)
            {
                console.registerConsoleInterfacable(this);
            }
            
            m_levelInformationText = new TextField(250, 40, "", "Verdana", 14, 0x291400);
            m_levelInformationText.filter = BlurFilter.createGlow(0xFFFFFF, 1.0, 0.5);
            m_levelInformationText.x = 30;
            m_levelInformationText.y = 0;
            m_levelInformationText.touchable = false;
            
            m_audioDriver = Audio.instance;
            
            // Prepare space for helper characters
            m_characterComponentManager = new ComponentManager();
            
            // Set up intial data for common characters
            var componentFactory:ComponentFactory = new ComponentFactory(compiler);
            var characterData:Object = m_assetManager.getObject("characters");
            componentFactory.createAndAddComponentsForItemList(m_characterComponentManager, characterData.charactersGame);
        }
        
        public function getObjectAlias():String
        {
            return "GameState";
        }
        
        public function getSupportedMethods():Vector.<String>
        {
            const methods:Vector.<String> = Vector.<String>([
                "completeLevel",
                "setContent",
                "setDeckVisible",
                "scrollToDocumentNode",
                "findAllCards",
                "goToTip",
                "solveBarModel"
            ]);
            
            return methods;
        }
        
        public function getMethodDetails(methodName:String):String
        {
            var details:String = "";
            switch (methodName)
            {
                case "completeLevel":
                {
                    details = "Immediately finish the level with a complete status.";
                }
                case "solveBarModel":
                {
                    details = "In levels with a bar modeling portion, inject the correct answer immediately in the modeling space.";
                }
            }
            return details;
        }
        
        public function invoke(methodExpression:MethodExpression):void
        {
            const alias:String = methodExpression.methodAlias;
            const args:Vector.<String> = methodExpression.arguments;
            switch (alias)
            {
                case "completeLevel":
                {
                    // Fake the game engine sending solve and complete events
                    m_gameEngine.dispatchEventWith(GameEvent.LEVEL_SOLVED);
                    m_gameEngine.dispatchEventWith(GameEvent.LEVEL_COMPLETE);
                    break;
                }
                case "setContent":
                {
                    const expression:String = args[0];
                    const alignment:String = args[1];
                    m_gameEngine.setTermAreaContent(expression, "");
                    break;
                }
                case "setWidgetVisible":
                {
                    const widgetId:String = args[0];
                    const visible:Boolean = XString.stringToBool(args[1]);
                    m_gameEngine.setWidgetVisible(widgetId, visible);
                    break;
                }
                case "scrollToDocumentNode":
                {
                    (m_gameEngine.getUiEntity("textArea") as TextAreaWidget).scrollToDocumentNode(args[0]);
                    break;
                }
                case "findAllCards":
                {
                    var expressionComponents:Vector.<Component> = (m_gameEngine.getUiEntity("deckArea") as DeckWidget).componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                    var discoverTerm:DiscoverTerm = m_preBakedScript.getNodeById("DiscoverTerm") as DiscoverTerm;
                    var i:int;
                    for (i = 0; i < expressionComponents.length; i++)
                    {
                        var expressionComponent:ExpressionComponent = expressionComponents[i] as ExpressionComponent;
                        if (!expressionComponent.hasBeenModeled)
                        {
                            discoverTerm.revealCard(expressionComponent.expressionString);
                            (m_gameEngine.getUiEntity("deckArea") as DeckWidget).getWidgetFromSymbol(expressionComponent.expressionString).visible = true;
                        }
                    }
                    break;
                }
                case "goToTip":
                {
                    m_gameEngine.dispatchEventWith(GameEvent.LINK_TO_TIP, false, {tipName: TipsViewer.MULTIPLY_WITH_BOXES});
                    break;
                }
                case "solveBarModel":
                {
                    // Get the correct bar model and insert it into the modeling space
                    // Pick the first reference model
                    var validateBarModel:ValidateBarModelArea = m_gameEngine.getCurrentLevel().getScriptRoot().getNodeById("ValidateBarModelArea") as ValidateBarModelArea;
                    if (validateBarModel != null)
                    {
                        var barModelArea:BarModelAreaWidget = m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget)[0] as BarModelAreaWidget;
                        barModelArea.setBarModelData(validateBarModel.getReferenceModels()[0]);
                        barModelArea.redraw();
                    }
                }
            }
        }
        
        /**
         * On entry, the game state expects the level data to play. At a minimum the resources to
         * start the level should have been already loaded.
         * 
         * @param params
         *      The first param is the problem data to play
         */
        override public function enter(fromState:Object, params:Vector.<Object>=null):void
        {
            // Make game screen visible
            addChild(m_gameEngine.getSprite());
            
            // Create button that opens the options
            var levelData:WordProblemLevelData = params[0] as WordProblemLevelData;
            var buttonColor:uint = m_buttonColorData.getUpButtonColor();
            var screenWidth:Number = 800;
            var screenHeight:Number = 600;
            m_optionsButton = new OptionButton(m_assetManager, m_buttonColorData.getUpButtonColor(), onOptionsClicked);
            m_optionsButton.x = 0;
            m_optionsButton.y = screenHeight - m_optionsButton.height - 2;
            
            // Create screen of options that pauses the game
            var buttonWidth:Number = 150;
            var buttonHeight:Number = 40;
            m_optionsScreen = new OptionsScreen(screenWidth, screenHeight, 
                buttonWidth, buttonHeight, 
                (m_overrideSkip) ? m_overrideSkipValue : true, 
                m_allowExit,
                buttonColor,
                m_assetManager, 
                onResume, onRestart, onSkip, forwardEvent, onExitToMainMenu, onHelpSelected);
            
            // Initialize new scripts to run on the level
            // Scripts should customize their own settings rather than expecting everything to be already added in place
            // Scripts will duplicate functionality but less dependencies this way
            // Only add ones we know can apply to all levels
            m_preBakedScript = new ConcurrentSelector(-1);
            
            // Generic drag controller, a bit confusing with all the dependencies on it
            m_preBakedScript.pushChild(new WidgetDragSystem(m_gameEngine, m_expressionCompiler, m_assetManager));
            
            // There are several gestures involving the term areas that can conflict with each other
            m_preBakedScript.pushChild(new TermAreaMouseScript(m_gameEngine, m_expressionCompiler, m_assetManager));
            
            // Execute the game script specific to the level being played
            m_preBakedScript.pushChild(levelData.getScriptRoot());
            
            // On the start of the new level we need to set up how the cards are going to be rendered
            const cardAttributes:CardAttributes = levelData.getCardAttributes();
            m_expressionSymbolMap.setConfiguration(
                cardAttributes
            );
            
            const symbolBindings:Vector.<SymbolData> = levelData.getSymbolsData();
            m_expressionSymbolMap.bindSymbolsToAtlas(symbolBindings);
            
            // Go to the new paragraph game state
            const gameParams:Vector.<Object> = new Vector.<Object>();
            gameParams.push(levelData);
            gameParams.push(m_characterComponentManager);

            (m_gameEngine as GameEngine).enter(gameParams);
            
            addChild(m_optionsButton);
            
            m_levelInformationText.text = getLevelDescriptor(levelData);
            addChild(m_levelInformationText);
            
            // Disable the skip button if the level specifies it
            if (!m_overrideSkip)
            {
                m_optionsScreen.toggleSkipButtonEnabled(levelData.skippable);
            }
            
            // Look at the level first and see what music should be played.
            // If nothing is specified, then use a default set
            var audioData:Vector.<Object> = levelData.getAudioData();
            if (audioData != null && audioData.length > 0)
            {
                var backgroundMusicData:Object = audioData[0];
                m_audioDriver.playMusic(backgroundMusicData.src);
            }
            else
            {
                // Play default music, if we want genre specific default then some other
                // script should have populated the audio to load field in the level data
                m_audioDriver.playMusic("bg_level_music");
            }
            
            m_helpScreenViewer = new HelpScreenViewer(m_gameEngine, m_assetManager, Vector.<HintScript>([]), this, onHelpClose, m_buttonColorData);
        }
        
        override public function exit(toState:Object):void
        {
            // Dispose of level
            cleanAndDisposeLevel();
            
            // After exiting, the engine should have cleaned up all resources related to the last level
            m_gameEngine.getSprite().removeFromParent();
            
            // Clear out the scripts to run
            m_preBakedScript.dispose();
            
            // Kill the background music
            m_audioDriver.reset();
            
            // Make sure game is unpaused
            setPaused(false);
            
            m_optionsButton.removeFromParent(true);
            
            // Dispose all the event listeners
            var buttonContainer:Sprite = m_optionsScreen.getChildAt(1) as Sprite;
            while (buttonContainer.numChildren > 0)
            {
                var child:DisplayObject = buttonContainer.getChildAt(0);
                if (child is Button)
                {
                    child.removeEventListeners();
                }
                child.removeFromParent(true);
            }
            
            // Remove option screen if visible, otherwise it will still be visible underneath
            // the ui components of the new level.
            m_optionsScreen.removeFromParent();
            
            // Clean up and remove the help screen
            m_helpScreenViewer.hide();
            m_helpScreenViewer.dispose();
        }
        
        override public function update(time:Time, mouseState:MouseState):void
        {
            if (!m_paused)
            {
                m_gameEngine.update(time, mouseState);

                // Visit the extra script nodes
                m_preBakedScript.visit();
                
                if (m_helpScreenViewer != null)
                {
                    m_helpScreenViewer.visit();
                }
            }
            else
            {
                // Clicking outside the wooden box for options should close the option
                if (m_optionsScreen.parent != null && mouseState.leftMousePressedThisFrame)
                {
                    // Check for hit outside the wood box
                    var mouseX:Number = mouseState.mousePositionThisFrame.x;
                    var mouseY:Number = mouseState.mousePositionThisFrame.y;
                    var optionsBackground:DisplayObject = m_optionsScreen.getChildAt(1);
                    var rightEdge:Number = optionsBackground.width + optionsBackground.x;
                    var bottomEdge:Number = optionsBackground.height + optionsBackground.y;
                    if (mouseX < optionsBackground.x || mouseY < optionsBackground.y || mouseX > rightEdge || mouseY > bottomEdge)
                    {
                        m_paused = false;
                        m_optionsScreen.removeFromParent();  
                    }
                }
            }
        }
        
        /**
         * Subclasses of game state should override if they want to format the desciptor differently
         */
        protected function getLevelDescriptor(levelData:WordProblemLevelData):String
        {
            var associatedGenreId:String = levelData.getGenreId();
            var levelSelectConfig:Object = m_assetManager.getObject("level_select_config");
            var worldName:String = "";
            if (levelSelectConfig != null)
            {
                var worldSections:Array = levelSelectConfig["sections"];
                for each (var worldSection:Object in worldSections)
                {
                    if (worldSection["linkToId"] == associatedGenreId)
                    {
                        worldName = worldSection["title"];
                        break;
                    }
                }
            }
            
            var levelInfoLabel:String = (levelData.getChapterIndex() + 1) + "-" + (levelData.getLevelIndex() + 1);
            
            if (m_levelManager != null)
            {
                var currentLevelId:String = levelData.getName();
                var currentLevelNode:WordProblemLevelLeaf = m_levelManager.getNodeByName(currentLevelId) as WordProblemLevelLeaf;
                if (currentLevelNode != null && currentLevelNode.getParent() is WordProblemLevelPack)
                {
                    var setIndex:int = currentLevelNode.parentChapterLevelPack.nodes.indexOf(currentLevelNode.getParent());
                    if (setIndex > -1)
                    {
                        var indexInSet:int = (currentLevelNode.getParent() as WordProblemLevelPack).nodes.indexOf(currentLevelNode);
                        levelInfoLabel = (levelData.getChapterIndex() + 1) + "-" + (setIndex + 1) + "." + (indexInSet + 1);
                    }
                }
            }
            
            
            if (worldName.length > 0)
            {
                levelInfoLabel = worldName + ": " + levelInfoLabel;
            }
            
            return levelInfoLabel;
        }
        
        /*
        Important note about these level end events
        
        The reason why level complete and level fail are differentiated from level exit is that a level
        exit is an explicit request to kill the level (for example they clicked on the 'exit' button).
        It is safe to assume in that situation that we want to immediately get out of the level.
        The other cases, we want to log as soon as possibly the player succeeded or failed a level however
        there might be more logic to execute while staying on the level.
        
        One example is that if the player that has a reward that evolves depending on how many levels he/she
        finished, the level manager needs to see the current level that was just finished to update in time.
        If the reward undergoes a change, we perhaps just want to paste this animation on top of the game screen.
        Some series of animation should finish before we exit.
        */
        
        private function cleanAndDisposeLevel():void
        {
            var level:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            
            // Clear out the resources dedicated to cards and symbols as these
            // are unique to each level.
            (m_gameEngine as GameEngine).exit();
            m_expressionSymbolMap.clear();
            
            // Remove resources that were dynamically loaded just for that particular level
            var imagesLoaded:Vector.<String> = level.getImagesToLoad();
            for each (var imageLoaded:String in imagesLoaded)
            {
                m_assetManager.removeTexture(imageLoaded, true);
            }
        }
        
        /**
         * Expose as public so application can force the options to appear at any time.
         */
        public function onOptionsClicked():void
        {
            Audio.instance.playSfx("button_click");
            var loggingDetails:Object = {buttonName:"OptionsButton"};
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
            
            // Show the level name at the top of the options

            addChild(m_optionsScreen);
            setPaused(true);
        }
        
        private function onResume():void
        {
            var loggingDetails:Object = {buttonName:"ResumeButton"};
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
            
            m_paused = false;
            m_optionsScreen.removeFromParent();  
        }
        
        private function onRestart():void
        {
            // On reset, the entire level restarts at the begining.
            // (Easiest way to implement is to trigger a go to level command
            // with the same level id as before)
            dispatchEventWith(CommandEvent.LEVEL_RESTART, false, {level: m_gameEngine.getCurrentLevel()});
        }
        
        private function onSkip():void
        {
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.SKIP);
            
            // On skip signal send up a signal that the level should be terminated with some skip tag
            var levelToEnd:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            dispatchEventWith(CommandEvent.LEVEL_SKIP, false, {level:levelToEnd});
        }
        
        private function forwardEvent(event:Event, params:Object):void
        {
            m_gameEngine.dispatchEventWith(event.type, params);
        }
        
        private function onExitToMainMenu():void
        {
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EXIT_BEFORE_COMPLETION);
            
            var levelToEnd:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            dispatchEventWith(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, false, {level:levelToEnd});
        }
        
        private function onHelpSelected():void
        {
            // Close the options menu
            m_paused = false;
            m_optionsScreen.removeFromParent();
            
            m_helpScreenViewer.show();
        }
        
        private function onHelpClose():void
        {
            m_helpScreenViewer.hide();
        }
        
        private function setPaused(value:Boolean):void
        {
            m_paused = value;
            m_gameEngine.setPaused(value);
        }
    }
}