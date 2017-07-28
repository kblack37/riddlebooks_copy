package wordproblem.scripts.items;


import cgs.levelProgression.nodes.ICgsLevelPack;

import wordproblem.engine.IGameEngine;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.log.AlgebraAdventureLogger;
import wordproblem.xp.PlayerXpModel;

class DefaultGiveRewardScript extends BaseGiveRewardScript
{
    /**
     * Need a reference to the user object because one of the rewards is given after the player has registered.
     * To check this, we just see if the user is not anonymous
     */
    private var m_logger : AlgebraAdventureLogger;
    
    public function new(gameEngine : IGameEngine,
            itemInventory : ItemInventory,
            logger : AlgebraAdventureLogger,
            rewardsData : Array<Dynamic>,
            levelManager : WordProblemCgsLevelManager,
            xpModel : PlayerXpModel,
            id : String)
    {
        super(gameEngine, itemInventory, rewardsData, levelManager, xpModel, id);
        
        m_logger = logger;
    }
    
    override private function shouldGiveReward(rewardEntityId : String) : Bool
    {
        var giveReward : Bool = false;
        switch (rewardEntityId)
        {
            case "egg_collection":
                // Eggs are given after the player finishes the first tutorial chapter
                var targetChapter : ICgsLevelPack = try cast(m_levelManager.getNodeByName("intro_one"), ICgsLevelPack) catch(e:Dynamic) null;
                giveReward = targetChapter != null && targetChapter.numLevelLeafsUncompleted == 0 && !checkIfUniqueRewardGiven("1");
            case "fish_bowl":
                // Give reward after player finishes first level
                var targetChapter = try cast(m_levelManager.getNodeByName("intro_one"), ICgsLevelPack) catch(e:Dynamic) null;
                giveReward = targetChapter != null && targetChapter.numLevelLeafsCompleted > 0 && !checkIfUniqueRewardGiven("4");
            case "dragonbox_box":
                // Give reward after player finishes three levels
                var targetChapter = try cast(m_levelManager.getNodeByName("intro_one"), ICgsLevelPack) catch(e:Dynamic) null;
                giveReward = targetChapter != null && targetChapter.numLevelLeafsCompleted > 3 && !checkIfUniqueRewardGiven("5");
        }
        
        return giveReward;
    }
}
