package wordproblem.scripts.state
{
    import dragonbox.common.state.IStateMachine;
    
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.event.CommandEvent;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.scripts.BaseBufferEventScript;
    import wordproblem.state.WordProblemGameState;
    import wordproblem.state.WordProblemSelectState;
    
    /**
     * Handles logic of moving between different screens upon receiving different command events
     * 
     * Override if we want differnet behavior or screens when switching
     */
    public class GameStateNavigationDefault extends BaseBufferEventScript
    {
        protected var m_gameState:WordProblemGameState;
        protected var m_stateMachine:IStateMachine;
        protected var m_levelManager:WordProblemCgsLevelManager;
        
        /** If null, the game mode does not have a problem create mode */
        protected var m_problemCreateState:WordProblemCreateState;
        
        public function GameStateNavigationDefault(gameState:WordProblemGameState,
                                                   stateMachine:IStateMachine,
                                                   levelManager:WordProblemCgsLevelManager,
                                                   problemCreateState:WordProblemCreateState=null,
                                                   id:String=null, 
                                                   isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_gameState = gameState;
            m_gameState.addEventListener(CommandEvent.GO_TO_NEXT_LEVEL, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_QUIT_AFTER_COMPLETION, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_SKIP, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_RESTART, bufferEvent);
        
            if (problemCreateState != null)
            {
                m_problemCreateState = problemCreateState;
                m_problemCreateState.addEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
            }
            
            m_stateMachine = stateMachine;
            m_levelManager = levelManager;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == CommandEvent.GO_TO_NEXT_LEVEL)
            {
                m_levelManager.goToNextLevel();
            }
            else if (eventType == CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION || 
                eventType == CommandEvent.LEVEL_QUIT_AFTER_COMPLETION)
            {
                // On a hard termination we automatically jump back in the
                // level select state
                var eventParams:Vector.<Object> = new Vector.<Object>();
                if (param != null && param.hasOwnProperty("level"))
                {
                    var levelData:WordProblemLevelData = param["level"];
                    if (levelData != null)
                    {
                        eventParams.push({
                            levelIndex: levelData.getLevelIndex(),
                            chapterIndex: levelData.getChapterIndex(),
                            genre: levelData.getGenreId()
                        });
                    }
                }
                m_stateMachine.changeState(WordProblemSelectState, eventParams); 
            }
            else if (eventType == CommandEvent.LEVEL_SKIP)
            {
                m_levelManager.goToNextLevel();
            }
            else if (eventType == CommandEvent.LEVEL_RESTART)
            {
                m_levelManager.goToLevelById((param.level as WordProblemLevelData).getName());
            }
        }
    }
}