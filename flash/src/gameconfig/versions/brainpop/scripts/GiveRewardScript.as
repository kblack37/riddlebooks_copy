package gameconfig.versions.brainpop.scripts
{
    import wordproblem.engine.IGameEngine;
    import wordproblem.items.ItemInventory;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.scripts.items.BaseGiveRewardScript;
    import wordproblem.xp.PlayerXpModel;
    
    public class GiveRewardScript extends BaseGiveRewardScript
    {
        public function GiveRewardScript(gameEngine:IGameEngine, 
                                         itemInventory:ItemInventory,
                                         rewardsData:Array, 
                                         levelManager:WordProblemCgsLevelManager, 
                                         xpModel:PlayerXpModel, 
                                         id:String)
        {
            super(gameEngine, itemInventory, rewardsData, levelManager, xpModel, id);
        }
    }
}