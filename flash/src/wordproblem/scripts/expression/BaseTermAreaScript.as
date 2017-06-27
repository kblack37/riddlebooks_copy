package wordproblem.scripts.expression
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObject;
    import starling.events.EventDispatcher;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * A base script to handle interactions with cards in the term area
     */
    public class BaseTermAreaScript extends BaseGameScript
    {
        /**
         * Keep track of all the areas that card can interact with
         */
        protected var m_termAreas:Vector.<TermAreaWidget>;
        
        /**
         * Dispatcher to send game related signals, usually this is the passed in game engine.
         * Exception is for situation like the tip playback animation or replays .
         */
        protected var m_eventDispatcher:EventDispatcher;
        
        /**
         * Mouse data used to interpret interactions
         */
        protected var m_mouseState:MouseState;
        
        protected var m_levelRules:LevelRules;
        
        public function BaseTermAreaScript(gameEngine:IGameEngine, 
                                           expressionCompiler:IExpressionTreeCompiler, 
                                           assetManager:AssetManager, 
                                           id:String=null, 
                                           isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        /**
         * HACK function so that the 'tips' section of the game help menu
         * can re-use these scripts to show a playback.
         * 
         * Manually set up parts of the script that
         * 
         * Each subclass MUST call this, not overridable because each subclass may have additional params
         * as part of setup. If it doesn't then this function can be called directly.
         */
        public function setCommonParams(termAreas:Vector.<TermAreaWidget>,
                                        levelRules:LevelRules, 
                                        gameEngineEventDispatcher:EventDispatcher, 
                                        mouseState:MouseState):void
        {
            m_termAreas = termAreas;
            m_levelRules = levelRules;
            m_eventDispatcher = gameEngineEventDispatcher;
            m_mouseState = mouseState;
            
            if (m_eventDispatcher != m_gameEngine)
            {
                m_eventDispatcher.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
            }
            
            m_ready = true;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_termAreas = new Vector.<TermAreaWidget>();
            var termAreas:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
            for each (var termArea:TermAreaWidget in termAreas)
            {
                m_termAreas.push(termArea);    
            }
            
            m_mouseState = m_gameEngine.getMouseState();
            m_eventDispatcher = m_gameEngine as EventDispatcher;
            m_levelRules = m_gameEngine.getCurrentLevel().getLevelRules();
        }
    }
}