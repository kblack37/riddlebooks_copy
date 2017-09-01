package wordproblem.scripts;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.core.Starling;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

/**
 * A subclass of this should be created in order to hard code the game logic for a particular level.
 * 
 * This script has a bare set of objects needed by nearly of all logic and also some
 * custom action functions.
 */
class BaseGameScript extends BaseBufferEventScript
{
    private var m_gameEngine : IGameEngine;
    private var m_expressionCompiler : IExpressionTreeCompiler;
    private var m_assetManager : AssetManager;
    
    private var m_ready : Bool = false;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_gameEngine = gameEngine;
        
        if (m_gameEngine != null) 
        {
            m_gameEngine.addEventListener(GameEvent.LEVEL_READY, onLevelReady);
        }
        m_expressionCompiler = expressionCompiler;
        m_assetManager = assetManager;
    }
    
    override public function dispose() : Void
    {
        if (m_gameEngine != null) 
        {
            m_gameEngine.removeEventListener(GameEvent.LEVEL_READY, onLevelReady);
        }
        
        super.dispose();
    }
    
    /**
     * A bit of a hack to handle cases when the instance that a script is created occurs AFTER the
     * LEVEL_READY event has fired. Any initialization code in that script won't execute if left alone
     * since it has missed that event.
     * 
     * Thus we need to manually call this function to initialize all that code.
     */
    public function overrideLevelReady(event : Dynamic) : Void
    {
        onLevelReady(event);
    }
    
    /**
     * Override this function to place all initialization code for the script
     */
    private function onLevelReady(event : Dynamic) : Void
    {
        m_ready = true;
    }
    
    /*
    Custom actions that can be placed inside a new node
    */
    
    /**
     * Wait for some number of seconds to elapse before continuing
     * 
     * @param param
     *      duration:Number of seconds to wait to elapse
     */
    private function secondsElapsed(param : Dynamic) : Int
    {
        // On the first visit
        if (!Reflect.hasField(param, "completed")) 
        {
            var duration : Float = param.duration;
            Starling.current.juggler.delayCall(function() : Void
                    {
                        Reflect.setField(param, "completed", true);
                    },
                    duration
                    );
            Reflect.setField(param, "completed", false);
        }
        
        return ((Reflect.field(param, "completed"))) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
    }
}
