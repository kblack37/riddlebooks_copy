package wordproblem.creator;


import flash.text.TextFormat;

import cgs.internationalization.StringTable;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.engine.GameEngine;
import wordproblem.engine.barmodel.BarModelLevelCreator;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.level.LevelCompiler;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;
import wordproblem.scripts.expression.TermAreaMouseScript;
import wordproblem.settings.OptionButton;

/**
 * This is the main screen that is used by the player to test whether the level that they
 * created is actually solvable.
 * 
 * The primary motivation is that if the user can play and finish the level, the number of
 * errors present in the problem may be decreased which save some time when it comes to the
 * revision process.
 */
class TestCreatedLevelScreen extends Sprite
{
    private var m_assetManager : AssetManager;
    private var m_expressionCompiler : IExpressionTreeCompiler;
    private var m_config : AlgebraAdventureConfig;
    private var m_barModelLevelCreator : BarModelLevelCreator;
    private var m_levelCompiler : LevelCompiler;
    private var m_scriptParser : ScriptParser;
    private var m_textParser : TextParser;
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    private var m_gameEngine : GameEngine;
    
    /**
     * Intially this contains the common set of helper characters that are accessible to
     * every level.
     * 
     * If a level wants to add a new one-off character, then it must be later stripped out when the level ends.
     */
    private var m_characterComponentManager : ComponentManager;
    
    /**
     * This is the overall root for pre-baked logic
     * Used to enhance the basic levels.
     * This logic should execute along side scripts bound to specific levels
     */
    private var m_preBakedScript : ScriptNode;
    
    private var m_levelReady : Bool;
    
    private var m_optionsButton : OptionButton;
    
    /**
     * Sub screen with list of options for this mode. Should include
     * Resume, Restart, End (returns user to the edit mode)
     */
    private var m_optionsScreen : Sprite;
    private var m_optionButtonCallbacks : Array<Function>;
    
    /**
     * Callback to inform the external class containing this screen that the level should
     * be stopped.
     */
    private var m_stopLevelCallback : Function;
    
    public function new(assetManager : AssetManager,
            levelCompiler : LevelCompiler,
            config : AlgebraAdventureConfig,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            mouseState : MouseState)
    {
        super();
        
        var screenWidth : Float = 800;
        var screenHeight : Float = 600;
        m_assetManager = assetManager;
        m_barModelLevelCreator = new BarModelLevelCreator(null);
        
        var expressionCompiler : IExpressionTreeCompiler = new LatexCompiler(new RealsVectorSpace());
        m_expressionCompiler = expressionCompiler;
        m_expressionSymbolMap = new ExpressionSymbolMap(assetManager);
        m_gameEngine = new GameEngine(expressionCompiler, assetManager, m_expressionSymbolMap, screenWidth, screenHeight, mouseState);
        m_levelCompiler = levelCompiler;
        m_scriptParser = new ScriptParser(m_gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData);
        m_textParser = new TextParser();
        m_config = config;
        
        // Prepare space for helper characters
        m_characterComponentManager = new ComponentManager();
        
        // Set up intial data for common characters
        var componentFactory : ComponentFactory = new ComponentFactory(expressionCompiler);
        var characterData : Dynamic = assetManager.getObject("characters");
        componentFactory.createAndAddComponentsForItemList(m_characterComponentManager, characterData.charactersGame);
        
        m_optionsButton = new OptionButton(m_assetManager, playerStatsAndSaveData.buttonColorData.getUpButtonColor(), onOptionsClicked);
        m_optionsButton.x = 0;
        m_optionsButton.y = screenHeight - m_optionsButton.height - 2;
        
        // Options for the test level should be resume, restart, and stop
        m_optionsScreen = new Sprite();
        var disablingQuad : Quad = new Quad(screenWidth, screenHeight, 0x000000);
        disablingQuad.alpha = 0.7;
        m_optionsScreen.addChild(disablingQuad);
        
        var optionsButtonContainer : Sprite = new Sprite();
        var optionsBackground : Image = new Image(getTexture("summary_background"));
        optionsButtonContainer.addChild(optionsBackground);
        m_optionsScreen.addChild(optionsButtonContainer);
        
        var buttonWidth : Float = 120;
        var buttonHeight : Float = 40;
        var buttonGap : Float = 20;
        var sidePadding : Float = 30;
        function getOptionButton(label : String, x : Float, y : Float, callback : Function) : Void
        {
            var button : Button = WidgetUtil.createGenericColoredButton(
                    assetManager,
                    playerStatsAndSaveData.buttonColorData.getUpButtonColor(),
                    label,
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                    );
            button.addEventListener(MouseEvent.CLICK, callback);
            button.width = buttonWidth;
            button.height = buttonHeight;
            button.x = x;
            button.y = y;
            optionsButtonContainer.addChild(button);
        };
        
        m_optionButtonCallbacks = [onOptionResume, onOptionRestart, onOptionExit];
        var buttonNames : Array<String> = [StringTable.lookup("resume"), StringTable.lookup("restart"), StringTable.lookup("exit")];
        var numButtons : Int = buttonNames.length;
        optionsBackground.height = numButtons * buttonHeight + (numButtons - 1) * buttonGap + 2 * sidePadding;
        optionsBackground.width = buttonWidth + sidePadding * 2;
        
        var i : Int = 0;
        var xOffset : Float = (optionsBackground.width - buttonWidth) * 0.5;
        var yOffset : Float = sidePadding;
        for (i in 0...numButtons){
            getOptionButton(buttonNames[i], xOffset, yOffset, m_optionButtonCallbacks[i]);
            yOffset += buttonHeight + buttonGap;
        }
        
        optionsButtonContainer.x = (screenWidth - optionsButtonContainer.width) * 0.5;
        optionsButtonContainer.y = (screenHeight - optionsButtonContainer.height) * 0.5;
    }
    
    /**
     * Request to start playing the level just created by the user.
     */
    public function startLevel(barModelType : String, problemContext : String, problemText : String, backgroundId : String) : Void
    {
        m_levelReady = false;
        addChild(m_gameEngine.getSprite());
        addChild(m_optionsButton);
        
        var createdLevelXml : FastXML = m_barModelLevelCreator.generateLevelFromData(1, barModelType, problemContext, problemText, backgroundId, null);
        var wordProblemLevel : WordProblemLevelData = m_levelCompiler.compileWordProblemLevel(
                createdLevelXml, "Test Level", 1, 1, problemContext,
                m_config, m_scriptParser, m_textParser
                );
        
        // Exact duplicate of code found in the startLevel call of the WordProblemGameBase
        // Load any dynamic assets that is part of the user created level (mainly the background must be loaded)
        // Load the images specific to this problem into the asset manager.
        // Note that these images need to be later cleared out on the exit of a level
        // If several levels share common images it might be a good idea just to keep the textures cached.
        var extraResourcesLoaded : Bool = false;
        var numExtraResources : Int = 0;
        var imagesToLoad : Array<String> = wordProblemLevel.getImagesToLoad();
        
        // For now we will use the source exactly as the id to fetch the images
        // this will free the id for images from naming restrictions and allow us
        // to easily detect if an image was already loaded
        for (imageSourceName in imagesToLoad)
        {
            if (m_assetManager.getTexture(imageSourceName) == null) 
            {
                numExtraResources++;
                m_assetManager.enqueueWithName(imageSourceName, imageSourceName);
            }
        }  // Texture atlas and audio can be directly loaded via starling's built-in asset manager functionality  
        
        
        
        for (audioData/* AS3HX WARNING could not determine type for var: audioData exp: ECall(EField(EIdent(wordProblemLevel),getAudioData),[]) type: null */ in wordProblemLevel.getAudioData())
        {
            //numExtraResources++;
            //m_assetManager.enqueue(audioUrl);
            
        }
        
        for (atlasList/* AS3HX WARNING could not determine type for var: atlasList exp: ECall(EField(EIdent(wordProblemLevel),getTextureAtlasesToLoad),[]) type: null */ in wordProblemLevel.getTextureAtlasesToLoad())
        {
            numExtraResources++;
            m_assetManager.enqueue(atlasList[0], atlasList[1]);
        }
        
        if (numExtraResources > 0) 
        {
            m_assetManager.loadQueue(function(ratio : Float) : Void
                    {
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
        
        function resourceBatchLoaded() : Void
        {
            if (extraResourcesLoaded) 
            {
                m_levelReady = true;
                m_expressionSymbolMap.setConfiguration(wordProblemLevel.getCardAttributes());
                
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
                m_preBakedScript.pushChild(wordProblemLevel.getScriptRoot());
                
                var gameParams : Array<Dynamic> = new Array<Dynamic>();
                gameParams.push(wordProblemLevel);
                gameParams.push(m_characterComponentManager);
                
                m_gameEngine.enter(gameParams);
            }
        };
    }
    
    public function stopLevel() : Void
    {
        m_levelReady = false;
        m_gameEngine.exit();
        m_gameEngine.getSprite().removeFromParent();
        if (m_optionsButton.parent != null) m_optionsButton.parent.removeChild(m_optionsButton);
    }
    
    public function update(time : Time, mouseState : MouseState) : Void
    {
        if (m_levelReady) 
        {
            m_gameEngine.update(time, mouseState);
            m_preBakedScript.visit();
        }
    }
    
    private function onOptionsClicked() : Void
    {
        addChild(m_optionsScreen);
    }
    
    private function onOptionResume() : Void
    {
        if (m_optionsScreen.parent != null) m_optionsScreen.parent.removeChild(m_optionsScreen);
    }
    
    private function onOptionRestart() : Void
    {
        if (m_optionsScreen.parent != null) m_optionsScreen.parent.removeChild(m_optionsScreen);
    }
    
    private function onOptionExit() : Void
    {
        if (m_optionsScreen.parent != null) m_optionsScreen.parent.removeChild(m_optionsScreen);
        dispatchEvent(ProblemCreateEvent.TEST_LEVEL_EXIT, false, null);
    }
}
