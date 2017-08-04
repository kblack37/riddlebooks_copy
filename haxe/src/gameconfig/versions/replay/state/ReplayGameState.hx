package gameconfig.versions.replay.state;


import flash.geom.Rectangle;
import flash.text.TextFormat;

import cgs.server.logging.data.QuestData;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import gameconfig.versions.replay.events.ReplayEvents;
import gameconfig.versions.replay.scripts.ReplayBarModelLevel;
import gameconfig.versions.replay.scripts.ReplayControllerScript;

import starling.display.Button;
import starling.events.Event;

import wordproblem.engine.GameEngine;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.level.CardAttributes;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

/**
 * This is the main visualization screen for showing the replay of the game.
 */
class ReplayGameState extends BaseState
{
    private var m_gameEngine : GameEngine;
    private var m_expressionCompiler : IExpressionTreeCompiler;
    private var m_assetManager : AssetManager;
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * Current information about the replay the player just started.
     */
    private var m_currentReplayData : QuestData;
    
    private var m_prebakedScripts : ScriptNode;
    
    private var m_exitButton : Button;
    
    public function new(stateMachine : IStateMachine,
            gameEngine : GameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            expressionSymbolMap : ExpressionSymbolMap)
    {
        super(stateMachine);
        
        m_gameEngine = gameEngine;
        m_expressionCompiler = expressionCompiler;
        m_assetManager = assetManager;
        m_expressionSymbolMap = expressionSymbolMap;
        
        var buttonWidth : Float = 150;
        var buttonHeight : Float = 50;
        m_exitButton = WidgetUtil.createButton(
                        m_assetManager,
                        "button_white",
                        "button_white",
                        null,
                        "button_white",
                        "Exit",
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                        null,
                        new Rectangle(8, 8, 16, 16)
                        );
		// TODO: the starling button uses textures, not images like the feathers button, so this will
		// have to be redesigned
        //(try cast(m_exitButton.defaultSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.ROYAL_BLUE;
        //(try cast(m_exitButton.hoverSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        //(try cast(m_exitButton.downSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        m_exitButton.addEventListener(Event.TRIGGERED, onExitClicked);
        m_exitButton.width = buttonWidth;
        m_exitButton.height = buttonHeight;
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        addChild(m_gameEngine.getSprite());
        
        // The first element in the list should be the level data
        var levelData : WordProblemLevelData = try cast(params[0], WordProblemLevelData) catch(e:Dynamic) null;
        m_currentReplayData = try cast(params[1], QuestData) catch(e:Dynamic) null;
        var characterComponentManager : ComponentManager = new ComponentManager();
        
        var cardAttributes : CardAttributes = levelData.getCardAttributes();
        m_expressionSymbolMap.setConfiguration(
                cardAttributes
                );
        
        var symbolBindings : Array<SymbolData> = levelData.getSymbolsData();
        m_expressionSymbolMap.bindSymbolsToAtlas(symbolBindings);
        
        m_prebakedScripts = new ConcurrentSelector(-1);
        m_prebakedScripts.pushChild(new ReplayControllerScript(m_gameEngine, m_expressionCompiler, m_assetManager, m_currentReplayData));
        m_prebakedScripts.pushChild(new ReplayBarModelLevel(m_gameEngine, m_expressionCompiler, m_assetManager));
        
        m_gameEngine.enter([levelData, characterComponentManager]);
        
        m_exitButton.y = 600 - m_exitButton.height;
        addChild(m_exitButton);
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        m_prebakedScripts.dispose();
        
        removeChild(m_gameEngine.getSprite());
        m_gameEngine.exit();
        m_expressionSymbolMap.clear();
        
        removeChild(m_exitButton);
    }
    
    override public function update(time : Time, mouseState : MouseState) : Void
    {
        m_prebakedScripts.visit();
        m_gameEngine.update(time, mouseState);
    }
    
    private function onExitClicked() : Void
    {
        dispatchEventWith(ReplayEvents.EXIT_REPLAY);
    }
}
