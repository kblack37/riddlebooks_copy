package wordproblem.player
{
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.level.LevelStatistics;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.event.CommandEvent;
    import wordproblem.items.ItemInventory;
    import wordproblem.scripts.BaseBufferEventScript;
    import wordproblem.state.WordProblemGameState;
    import wordproblem.xp.PlayerXpModel;
    
    /**
     * This scripts handles the proper timed updating+saving of various player save data.
     * 
     * In particular it flushes the xp information.
     */
    public class UpdateAndSavePlayerStatsAndDataScript extends BaseBufferEventScript
    {
        private var m_gameState:WordProblemGameState;
        private var m_gameEngine:IGameEngine;
        private var m_playerXpModel:PlayerXpModel;
        private var m_flushSaveImmediately:Boolean;
        
        /**
         * Hack: the addition of new items or changes in their properties happens in other scripts so why is this here.
         */
        private var m_itemInventory:ItemInventory;
        
        public function UpdateAndSavePlayerStatsAndDataScript(gameState:WordProblemGameState, 
                                                              gameEngine:IGameEngine,
                                                              playerXpModel:PlayerXpModel,
                                                              playerStatsAndSaveData:PlayerStatsAndSaveData,
                                                              playerItemInventory:ItemInventory,
                                                              id:String=null, 
                                                              isActive:Boolean=true, 
                                                              flushSaveImmediately:Boolean=true)
        {
            super(id, isActive);
            
            m_gameState = gameState;
            m_gameState.addEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_SKIP, bufferEvent);
            
            m_gameEngine = gameEngine;
            m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.LEVEL_COMPLETE, bufferEvent);
            
            m_playerXpModel = playerXpModel;
            m_itemInventory = playerItemInventory;
            m_flushSaveImmediately = flushSaveImmediately;
        }
        
        override public function dispose():void
        {
            super.dispose();
            m_gameState.removeEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
            m_gameState.removeEventListener(CommandEvent.LEVEL_SKIP, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.LEVEL_COMPLETE, bufferEvent);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            var level:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            var levelStatistics:LevelStatistics = level.statistics;
            if (eventType == CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION)
            {
            }
            else if (eventType == CommandEvent.LEVEL_SKIP)
            {
            }
            else if (eventType == GameEvent.LEVEL_SOLVED)
            {
                // On solve write out new xp earned and flush it to the cache
                m_playerXpModel.totalXP += levelStatistics.xpEarnedForLevel;
            }
            else if (eventType == GameEvent.LEVEL_COMPLETE)
            {
                // HACK:
                // Hidden timing here, giving of rewards is on this event
                m_itemInventory.save();
            }
            
            // Assume only enter this on one of the end events
            // ALways save xp on end
            m_playerXpModel.save(m_flushSaveImmediately);
        }
    }
}