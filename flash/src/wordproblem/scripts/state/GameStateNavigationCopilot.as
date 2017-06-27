package wordproblem.scripts.state
{
    import dragonbox.common.state.IStateMachine;
    
    import wordproblem.event.CommandEvent;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.state.CopilotScreenState;
    import wordproblem.state.WordProblemGameState;
    
    public class GameStateNavigationCopilot extends GameStateNavigationDefault
    {
        public function GameStateNavigationCopilot(gameState:WordProblemGameState, 
                                                   stateMachine:IStateMachine, 
                                                   levelManager:WordProblemCgsLevelManager, 
                                                   id:String=null, 
                                                   isActive:Boolean=true)
        {
            super(gameState, stateMachine, levelManager, id, isActive);
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
                m_stateMachine.changeState(CopilotScreenState, Vector.<Object>([true])); 
            }
            else if (eventType == CommandEvent.LEVEL_SKIP)
            {
                m_levelManager.goToNextLevel();
            }
        }
    }
}