package wordproblem.state;

import cgs.audio.Audio;

import dragonbox.common.console.IConsole;
import dragonbox.common.console.IConsoleInterfacable;
import dragonbox.common.console.expression.MethodExpression;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XString;

import starling.display.Button;
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

class WordProblemGameState extends BaseState implements IConsoleInterfacable
{
    /**
     * Reference to the main game system mostly to recieve important events
     * from the system.
     */
    private var m_gameEngine : IGameEngine;
    
    /**
     * Keep expression map is preserved across several levels.
     */
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    private var m_assetManager : AssetManager;
    
    private var m_expressionCompiler : IExpressionTreeCompiler;
    
    /**
     * This is the overall root for pre-baked logic
     * Used to enhance the basic levels.
     * This logic should execute along side scripts bound to specific levels
     */
    private var m_preBakedScript : ScriptNode;
    
    /**
     * Intially this contains the common set of helper characters that are accessible to
     * every level.
     * 
     * If a level wants to add a new one-off character, then it must be later stripped out when the level ends.
     */
    private var m_characterComponentManager : ComponentManager;
    
    /**
     * Configurations of game
     */
    private var m_config : AlgebraAdventureConfig;
    
    /**
     * Clicking on this option will pause the game and open up an options overlay
     */
    private var m_optionsButton : OptionButton;
    
    /**
     * This is the container for all buttons for options and blocks the entire screen.
     * 
     * The options are: 
     * resume (unpause), skip, toggle music/sfx, quit level, restart level
     * Depending on the game configuration, not all of these options will be present,
     * for example for the version that replays only a single level, there is no skip or quit.
     */
    private var m_optionsScreen : OptionsScreen;
    
    /**
     * This textfield shows the player the genre, chapter, and level index that the current player is in.
     */
    private var m_levelInformationText : TextField;
    
    /**
     * When the player selects the options menu, the game should be temporarily frozen.
     */
    private var m_paused : Bool;
    
    /**
     * Handle the turning on and off of background music while playing,
     * upon entering and exiting a level.  This variable holds the singleton audio driver.
     */
    private var m_audioDriver : Audio;
    
    /**
     * If true then all levels in this version should ignore any skip values specified in the level data
     * and just make everything skippable or everything not skippable
     */
    private var m_overrideSkip : Bool;
    
    /**
     * If override skip is true, then all levels should use this skippable value
     */
    private var m_overrideSkipValue : Bool;
    private var m_allowExit : Bool;
    
    /**
     * The object is needed so the screen can alter the color of several buttons to 
     * match the one selected by the user.
     */
    private var m_buttonColorData : ButtonColorData;
    
    private var m_helpScreenViewer : HelpScreenViewer;
    
    /**
     * Used to figure out the correct indices when writing the level descriptors
     */
    private var m_levelManager : WordProblemCgsLevelManager;
    
    public function new(stateMachine : IStateMachine,
            gameEngine : IGameEngine,
            assetManager : AssetManager,
            compiler : IExpressionTreeCompiler,
            expressionSymbolMap : ExpressionSymbolMap,
            config : AlgebraAdventureConfig,
            console : IConsole,
            buttonColorData : ButtonColorData,
            levelManager : WordProblemCgsLevelManager = null)
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
        var componentFactory : ComponentFactory = new ComponentFactory(compiler);
		// TODO: uncomment when assets are finalized
        //var characterData : Dynamic = m_assetManager.getObject("characters");
		var characterData : Dynamic = { charactersGame : [ ] };
        componentFactory.createAndAddComponentsForItemList(m_characterComponentManager, characterData.charactersGame);
    }
    
    public function getObjectAlias() : String
    {
        return "GameState";
    }
    
    public function getSupportedMethods() : Array<String>
    {
        var methods : Array<String> = [
                "completeLevel", 
                "setContent", 
                "setDeckVisible", 
                "scrollToDocumentNode", 
                "findAllCards", 
                "goToTip", 
                "solveBarModel"];
        
        return methods;
    }
    
    public function getMethodDetails(methodName : String) : String
    {
        var details : String = "";
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
    
    public function invoke(methodExpression : MethodExpression) : Void
    {
        var alias : String = methodExpression.methodAlias;
        var args : Array<String> = methodExpression.arguments;
        switch (alias)
        {
            case "completeLevel":
            {
                // Fake the game engine sending solve and complete events
                m_gameEngine.dispatchEventWith(GameEvent.LEVEL_SOLVED);
                m_gameEngine.dispatchEventWith(GameEvent.LEVEL_COMPLETE);
            }
            case "setContent":
            {
                var expression : String = args[0];
                var alignment : String = args[1];
                m_gameEngine.setTermAreaContent(expression, "");
            }
            case "setWidgetVisible":
            {
                var widgetId : String = args[0];
                var visible : Bool = XString.stringToBool(args[1]);
                m_gameEngine.setWidgetVisible(widgetId, visible);
            }
            case "scrollToDocumentNode":
            {
                (try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null).scrollToDocumentNode(args[0]);
            }
            case "findAllCards":
            {
                var expressionComponents : Array<Component> = (try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null).componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                var discoverTerm : DiscoverTerm = try cast(m_preBakedScript.getNodeById("DiscoverTerm"), DiscoverTerm) catch(e:Dynamic) null;
                var i : Int = 0;
                for (i in 0...expressionComponents.length){
                    var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                    if (!expressionComponent.hasBeenModeled) 
                    {
                        discoverTerm.revealCard(expressionComponent.expressionString);
                        (try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null).getWidgetFromSymbol(expressionComponent.expressionString).visible = true;
                    }
                }
            }
            case "goToTip":
            {
                m_gameEngine.dispatchEventWith(GameEvent.LINK_TO_TIP, false, {
                            tipName : TipsViewer.MULTIPLY_WITH_BOXES

                        });
            }
            case "solveBarModel":
            {
                // Get the correct bar model and insert it into the modeling space
                // Pick the first reference model
                var validateBarModel : ValidateBarModelArea = try cast(m_gameEngine.getCurrentLevel().getScriptRoot().getNodeById("ValidateBarModelArea"), ValidateBarModelArea) catch(e:Dynamic) null;
                if (validateBarModel != null) 
                {
                    var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget)[0], BarModelAreaWidget) catch(e:Dynamic) null;
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
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        // Make game screen visible
        addChild(m_gameEngine.getSprite());
        
        // Create button that opens the options
        var levelData : WordProblemLevelData = try cast(params[0], WordProblemLevelData) catch(e:Dynamic) null;
        var buttonColor : Int = m_buttonColorData.getUpButtonColor();
        var screenWidth : Float = 800;
        var screenHeight : Float = 600;
        m_optionsButton = new OptionButton(m_assetManager, m_buttonColorData.getUpButtonColor(), onOptionsClicked);
        m_optionsButton.x = 0;
        m_optionsButton.y = screenHeight - m_optionsButton.height - 2;
        
        // Create screen of options that pauses the game
        var buttonWidth : Float = 150;
        var buttonHeight : Float = 40;
        m_optionsScreen = new OptionsScreen(screenWidth, screenHeight, 
                buttonWidth, buttonHeight, 
                ((m_overrideSkip)) ? m_overrideSkipValue : true, 
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
        var cardAttributes : CardAttributes = levelData.getCardAttributes();
        m_expressionSymbolMap.setConfiguration(
                cardAttributes
                );
        
        var symbolBindings : Array<SymbolData> = levelData.getSymbolsData();
        m_expressionSymbolMap.bindSymbolsToAtlas(symbolBindings);
        
        // Go to the new paragraph game state
        var gameParams : Array<Dynamic> = new Array<Dynamic>();
        gameParams.push(levelData);
        gameParams.push(m_characterComponentManager);
        
        (try cast(m_gameEngine, GameEngine) catch(e:Dynamic) null).enter(gameParams);
        
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
        var audioData : Array<Dynamic> = levelData.getAudioData();
        if (audioData != null && audioData.length > 0) 
        {
            var backgroundMusicData : Dynamic = audioData[0];
            m_audioDriver.playMusic(backgroundMusicData.src);
        }
        else 
        {
            // Play default music, if we want genre specific default then some other
            // script should have populated the audio to load field in the level data
			m_audioDriver.playMusic("bg_level_music");
        }
        
        m_helpScreenViewer = new HelpScreenViewer(m_gameEngine, m_assetManager, [], this, onHelpClose, m_buttonColorData);
    }
    
    override public function exit(toState : Dynamic) : Void
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
        var buttonContainer : Sprite = try cast(m_optionsScreen.getChildAt(1), Sprite) catch(e:Dynamic) null;
        while (buttonContainer.numChildren > 0)
        {
            var child : DisplayObject = buttonContainer.getChildAt(0);
            if (Std.is(child, Button)) 
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
    
    override public function update(time : Time, mouseState : MouseState) : Void
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
                var mouseX : Float = mouseState.mousePositionThisFrame.x;
                var mouseY : Float = mouseState.mousePositionThisFrame.y;
                var optionsBackground : DisplayObject = m_optionsScreen.getChildAt(1);
                var rightEdge : Float = optionsBackground.width + optionsBackground.x;
                var bottomEdge : Float = optionsBackground.height + optionsBackground.y;
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
    private function getLevelDescriptor(levelData : WordProblemLevelData) : String
    {
        var associatedGenreId : String = levelData.getGenreId();
        var levelSelectConfig : Dynamic = m_assetManager.getObject("level_select_config");
        var worldName : String = "";
        if (levelSelectConfig != null) 
        {
            var worldSections : Array<Dynamic> = Reflect.field(levelSelectConfig, "sections");
            for (worldSection in worldSections)
            {
                if (Reflect.field(worldSection, "linkToId") == associatedGenreId) 
                {
                    worldName = Reflect.field(worldSection, "title");
                    break;
                }
            }
        }
        
        var levelInfoLabel : String = (levelData.getChapterIndex() + 1) + "-" + (levelData.getLevelIndex() + 1);
        
        if (m_levelManager != null) 
        {
            var currentLevelId : String = levelData.getName();
            var currentLevelNode : WordProblemLevelLeaf = try cast(m_levelManager.getNodeByName(currentLevelId), WordProblemLevelLeaf) catch(e:Dynamic) null;
            if (currentLevelNode != null && Std.is(currentLevelNode.getParent(), WordProblemLevelPack)) 
            {
                var setIndex : Int = currentLevelNode.parentChapterLevelPack.nodes.indexOf(currentLevelNode.getParent());
                if (setIndex > -1) 
                {
                    var indexInSet : Int = (try cast(currentLevelNode.getParent(), WordProblemLevelPack) catch(e:Dynamic) null).nodes.indexOf(currentLevelNode);
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
    
    private function cleanAndDisposeLevel() : Void
    {
        var level : WordProblemLevelData = m_gameEngine.getCurrentLevel();
        
        // Clear out the resources dedicated to cards and symbols as these
        // are unique to each level.
        (try cast(m_gameEngine, GameEngine) catch(e:Dynamic) null).exit();
        m_expressionSymbolMap.clear();
        
        // Remove resources that were dynamically loaded just for that particular level
        var imagesLoaded : Array<String> = level.getImagesToLoad();
        for (imageLoaded in imagesLoaded)
        {
            m_assetManager.removeTexture(imageLoaded, true);
        }
    }
    
    /**
     * Expose as public so application can force the options to appear at any time.
     */
    public function onOptionsClicked() : Void
    {
        Audio.instance.playSfx("button_click");
        var loggingDetails : Dynamic = {
            buttonName : "OptionsButton"

        };
        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
        
        // Show the level name at the top of the options
        
        addChild(m_optionsScreen);
        setPaused(true);
    }
    
    private function onResume() : Void
    {
        var loggingDetails : Dynamic = {
            buttonName : "ResumeButton"

        };
        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
        
        m_paused = false;
        m_optionsScreen.removeFromParent();
    }
    
    private function onRestart() : Void
    {
        // On reset, the entire level restarts at the begining.
        // (Easiest way to implement is to trigger a go to level command
        // with the same level id as before)
        dispatchEventWith(CommandEvent.LEVEL_RESTART, false, {
                    level : m_gameEngine.getCurrentLevel()

                });
    }
    
    private function onSkip() : Void
    {
        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.SKIP);
        
        // On skip signal send up a signal that the level should be terminated with some skip tag
        var levelToEnd : WordProblemLevelData = m_gameEngine.getCurrentLevel();
        dispatchEventWith(CommandEvent.LEVEL_SKIP, false, {
                    level : levelToEnd

                });
    }
    
    private function forwardEvent(event : Event, params : Dynamic) : Void
    {
        m_gameEngine.dispatchEventWith(event.type, params);
    }
    
    private function onExitToMainMenu() : Void
    {
        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EXIT_BEFORE_COMPLETION);
        
        var levelToEnd : WordProblemLevelData = m_gameEngine.getCurrentLevel();
        dispatchEventWith(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, false, {
                    level : levelToEnd

                });
    }
    
    private function onHelpSelected() : Void
    {
        // Close the options menu
        m_paused = false;
        m_optionsScreen.removeFromParent();
        
        m_helpScreenViewer.show();
    }
    
    private function onHelpClose() : Void
    {
        m_helpScreenViewer.hide();
    }
    
    private function setPaused(value : Bool) : Void
    {
        m_paused = value;
        m_gameEngine.setPaused(value);
    }
}
