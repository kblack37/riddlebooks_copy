package wordproblem
{
    import wordproblem.event.CommandEvent;
    import wordproblem.state.PlayTestTitleScreenState;

    public class WordProblemGamePlayTest extends WordProblemGameDefault
    {
        public function WordProblemGamePlayTest()
        {
            super();
        }
        
        override protected function onStartingResourcesLoaded():void
        {
            // Setup a standard start screen, with login prompt
            var playtestTitleScreen:PlayTestTitleScreenState = new PlayTestTitleScreenState(
                m_stateMachine,
                m_assetManager,
                m_logger,
                m_nativeFlashStage,
                m_config.getUsernamePrefix(),
                m_config
            );
            playtestTitleScreen.addEventListener(CommandEvent.USER_AUTHENTICATED, onUserAuthenticated);
            playtestTitleScreen.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
            playtestTitleScreen.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
            m_stateMachine.register(playtestTitleScreen);
            
            // Automatically go to the problem selection state
            m_stateMachine.start(playtestTitleScreen);
            
            // Skip to level select if we don't want to do anything with the server
            if (m_config.debugNoServerLogin)
            {
                onUserAuthenticated();
            }
        }
    }
}