package gameconfig.versions.brainpop.scripts;


import wordproblem.engine.IGameEngine;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.scripts.items.BaseGiveRewardScript;
import wordproblem.xp.PlayerXpModel;

class GiveRewardScript extends BaseGiveRewardScript
{
    public function new(gameEngine : IGameEngine,
            itemInventory : ItemInventory,
            rewardsData : Array<Dynamic>,
            levelManager : WordProblemCgsLevelManager,
            xpModel : PlayerXpModel,
            id : String)
    {
        super(gameEngine, itemInventory, rewardsData, levelManager, xpModel, id);
    }
}
