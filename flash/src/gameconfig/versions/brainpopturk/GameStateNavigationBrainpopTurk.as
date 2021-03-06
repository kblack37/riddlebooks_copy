package gameconfig.versions.brainpopturk
{
    import dragonbox.common.state.IStateMachine;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.event.CommandEvent;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.playercollections.PlayerCollectionsState;
    import wordproblem.scripts.BaseBufferEventScript;
    import wordproblem.state.WordProblemGameState;
    import wordproblem.state.WordProblemSelectState;
    
    public class GameStateNavigationBrainpopTurk extends BaseBufferEventScript
    {
        private var m_brainpopTurkMain:WordProblemGameBrainpopTurk;
        private var m_gameState:WordProblemGameState;
        private var m_stateMachine:IStateMachine;
        private var m_levelManager:WordProblemCgsLevelManager;
        private var m_config:AlgebraAdventureConfig;
        
        public function GameStateNavigationBrainpopTurk(brainpopTurkMain:WordProblemGameBrainpopTurk,
                                                        gameState:WordProblemGameState,
                                                        stateMachine:IStateMachine,
                                                        levelManager:WordProblemCgsLevelManager,
                                                        config:AlgebraAdventureConfig,
                                                        id:String=null, 
                                                        isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_brainpopTurkMain = brainpopTurkMain;
            m_gameState = gameState;
            m_gameState.addEventListener(CommandEvent.GO_TO_NEXT_LEVEL, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_QUIT_AFTER_COMPLETION, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_SKIP, bufferEvent);
            m_gameState.addEventListener(CommandEvent.LEVEL_RESTART, bufferEvent);
            
            m_stateMachine = stateMachine;
            m_levelManager = levelManager;
            m_config = config;
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
                // On a hard termination (i.e. quit we go to level select if that is enabled
                if (m_config.allowLevelSelect)
                {
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
                else
                {
                    if (m_brainpopTurkMain.playerFinishedTheRequiredExperimentSets())
                    {
                        m_stateMachine.changeState(WordProblemSelectState);
                    }
                    else
                    {
                        m_stateMachine.changeState(PlayerCollectionsState);
                    }
                }
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