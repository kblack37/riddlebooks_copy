package gameconfig.versions.brainpop.scripts;


import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.CurrentGrowInStageComponent;
import wordproblem.engine.component.LevelsCompletedPerStageComponent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.scripts.items.BaseAdvanceItemStageScript;

class AdvanceItemStageScript extends BaseAdvanceItemStageScript
{
    public function new(gameEngine : IGameEngine, itemInventory : ItemInventory, itemDataSource : ItemDataSource, levelManager : WordProblemCgsLevelManager, id : String = null)
    {
        super(gameEngine, itemInventory, itemDataSource, levelManager, id);
    }
    
    override private function getNextStageForItem(currentGrowInStageComponent : CurrentGrowInStageComponent) : Int
    {
        var nextStage : Int = 0;
        var useGenericEggStageFunction : Bool = false;
        
        // If the returned stage is different then signal something
        var entityId : String = currentGrowInStageComponent.entityId;
        switch (entityId)
        {
            // Right now all eggs share the same progress model
            // Purple egg
            case "1":
                var completedLevels : Int = this.getCompletedLevelsForGenre("fantasy");
                useGenericEggStageFunction = true;
            // Blue egg
            case "3":
                completedLevels = this.getCompletedLevelsForGenre("scifi");
                useGenericEggStageFunction = true;
            // Yellow egg
            case "2":
                completedLevels = this.getCompletedLevelsForGenre("mystery");
                useGenericEggStageFunction = true;
        }
        
        if (useGenericEggStageFunction) 
        {
            var itemId : String = getItemIdFromEntityId(entityId);
            var levelsCompletedPerStageComponent : LevelsCompletedPerStageComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                    itemId,
                    LevelsCompletedPerStageComponent.TYPE_ID
                    ), LevelsCompletedPerStageComponent) catch(e:Dynamic) null;
            
            // It is possible for something to advance multiple stages so we need to loop multiple times potentially
            // (happens at the start where we need to set the right initial stage so we need to loop through multiple time)
            
            // Make sure that the current stage can advance to a next value
            if (levelsCompletedPerStageComponent != null) 
            {
                var currentStage : Int = currentGrowInStageComponent.currentStage;
                nextStage = currentStage;
                while (currentStage < levelsCompletedPerStageComponent.stageToLevelsCompleted.length)
                {
                    var levelThresholdForCurrentStage : Int = levelsCompletedPerStageComponent.stageToLevelsCompleted[currentStage];
                    if (completedLevels >= levelThresholdForCurrentStage) 
                    {
                        nextStage = ++currentStage;
                    }
                    else 
                    {
                        break;
                    }
                }
            }
        }
        
        return nextStage;
    }
}
