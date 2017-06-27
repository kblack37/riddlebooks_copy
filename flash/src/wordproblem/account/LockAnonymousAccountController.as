package wordproblem.account
{
    import cgs.user.ICgsUser;
    
    import wordproblem.level.controller.WordProblemCgsLevelManager;

    /**
     * We need to stop the player that has not yet registered an account 
     * from continuing after they have played through some number of levels
     */
    public class LockAnonymousAccountController
    {
        private var m_user:ICgsUser;
        private var m_levelManager:WordProblemCgsLevelManager;
        private var m_limit:int;
        
        public function LockAnonymousAccountController(user:ICgsUser, 
                                                       levelManager:WordProblemCgsLevelManager, 
                                                       limit:int)
        {
            m_user = user;
            m_levelManager = levelManager;
            m_limit = limit;
        }
        
        public function getShouldAccountBeLocked():Boolean
        {
            var lockAccount:Boolean = false;
            if (m_user != null && m_user.username == null)
            {
                var numUniqueLevelsPlayed:int = m_levelManager.currentLevelProgression.numLevelLeafsPlayed;
                if (numUniqueLevelsPlayed >= m_limit)
                {
                    lockAccount = true;
                }
            }
            
            return lockAccount;
        }
    }
}