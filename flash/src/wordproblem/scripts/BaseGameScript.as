package wordproblem.scripts
{
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
    public class BaseGameScript extends BaseBufferEventScript
    {
        protected var m_gameEngine:IGameEngine;
        protected var m_expressionCompiler:IExpressionTreeCompiler;
        protected var m_assetManager:AssetManager;
        
        protected var m_ready:Boolean = false;
        
        public function BaseGameScript(gameEngine:IGameEngine, 
                                       expressionCompiler:IExpressionTreeCompiler, 
                                       assetManager:AssetManager,
                                       id:String=null,
                                       isActive:Boolean=true)
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
        
        override public function dispose():void
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
        public function overrideLevelReady():void
        {
            onLevelReady();
        }
        
        /**
         * Override this function to place all initialization code for the script
         */
        protected function onLevelReady():void
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
        protected function secondsElapsed(param:Object):int
        {
            // On the first visit
            if (!param.hasOwnProperty("completed"))
            {
                var duration:Number = param.duration;
                Starling.juggler.delayCall(function():void
                {
                    param["completed"] = true;
                },
                    duration
                );
                param["completed"] = false;
            }
            
            return (param["completed"]) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
        }
    }
}