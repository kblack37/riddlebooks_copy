package wordproblem.scripts.items
{
    import cgs.levelProgression.nodes.ICgsLevelPack;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.items.ItemInventory;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.log.AlgebraAdventureLogger;
    import wordproblem.xp.PlayerXpModel;
    
    public class DefaultGiveRewardScript extends BaseGiveRewardScript
    {
        /**
         * Need a reference to the user object because one of the rewards is given after the player has registered.
         * To check this, we just see if the user is not anonymous
         */
        private var m_logger:AlgebraAdventureLogger;
        
        public function DefaultGiveRewardScript(gameEngine:IGameEngine, 
                                                itemInventory:ItemInventory, 
                                                logger:AlgebraAdventureLogger, 
                                                rewardsData:Array, 
                                                levelManager:WordProblemCgsLevelManager, 
                                                xpModel:PlayerXpModel, 
                                                id:String)
        {
            super(gameEngine, itemInventory, rewardsData, levelManager, xpModel, id);
            
            m_logger = logger;
        }
        
        override protected function shouldGiveReward(rewardEntityId:String):Boolean
        {
            var giveReward:Boolean = false;
            switch(rewardEntityId)
            {
                case "egg_collection":
                    // Eggs are given after the player finishes the first tutorial chapter
                    var targetChapter:ICgsLevelPack = m_levelManager.getNodeByName("intro_one") as ICgsLevelPack;
                    giveReward = targetChapter != null && targetChapter.numLevelLeafsUncompleted == 0 && !checkIfUniqueRewardGiven("1");
                    break;
                case "fish_bowl":
                    // Give reward after player finishes first level
                    targetChapter = m_levelManager.getNodeByName("intro_one") as ICgsLevelPack;
                    giveReward = targetChapter != null && targetChapter.numLevelLeafsCompleted > 0 && !checkIfUniqueRewardGiven("4");
                    break;
                case "dragonbox_box":
                    // Give reward after player finishes three levels
                    targetChapter = m_levelManager.getNodeByName("intro_one") as ICgsLevelPack;
                    giveReward = targetChapter != null && targetChapter.numLevelLeafsCompleted > 3 && !checkIfUniqueRewardGiven("5");
                    break;
            }
            
            return giveReward;
        }
    }
}