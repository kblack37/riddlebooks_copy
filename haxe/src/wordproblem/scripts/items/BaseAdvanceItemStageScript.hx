package wordproblem.scripts.items;


import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.CurrentGrowInStageComponent;
import wordproblem.engine.component.ItemIdComponent;
import wordproblem.engine.component.LevelsCompletedPerStageComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.level.nodes.GenreLevelPack;
import wordproblem.scripts.BaseBufferEventScript;

/**
 * This script handles the logic in determining whether items owned in a particular inventory
 * will advance in their current stages. The determination of when the stage changes are
 * encapsulated in specific rules.
 * 
 * For example the item represented by a dragon will only grow if the player finishes a level.
 * This logic can be made as complex as desired, for example the rules to transition from
 * stage 1 to 2 can be different from the rules for 2 to 3. Rules might apply to an entire class
 * of items or just a specific one.
 * 
 * The goal is to keep all these logic encapsulated in this one class.
 * A consequence of this is that this script needs to possibly link into many other events and
 * data sources before it can do its rule checking.
 * 
 * Note that this directly modifies the inventory data, a save mechanism for items may be needed
 * if the state cannot be reconstructed just from level progress.
 */
class BaseAdvanceItemStageScript extends BaseBufferEventScript
{
    /**
     * These are the items belonging to some entity, like the player.
     * The script will read and write this data to cause the item to change
     * in stages.
     */
    private var m_itemInventory : ItemInventory;
    
    /**
     * This data source is required to figure out the maximum number of stages each particular item
     * can take on.
     */
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * The level manager is used because several conditions will require seeing how many levels
     * were completed by the user.
     */
    private var m_levelManager : WordProblemCgsLevelManager;
    
    public function new(gameEngine : IGameEngine,
            itemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            levelManager : WordProblemCgsLevelManager,
            id : String = null)
    {
        super(id);
        
        m_itemInventory = itemInventory;
        m_itemDataSource = itemDataSource;
        m_levelManager = levelManager;
        
        gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        
        resetData();
    }
    
    public function resetData() : Void
    {
        var currentGrowInStageComponents : Array<Component> = m_itemInventory.componentManager.getComponentListForType(CurrentGrowInStageComponent.TYPE_ID);
        var numComponents : Int = currentGrowInStageComponents.length;
        var i : Int;
        var currentGrowInStageComponent : CurrentGrowInStageComponent;
        for (i in 0...numComponents){
            currentGrowInStageComponent = try cast(currentGrowInStageComponents[i], CurrentGrowInStageComponent) catch(e:Dynamic) null;
            
            var currentStage : Int = currentGrowInStageComponent.currentStage;
            var nextStage : Int = getNextStageForItem(currentGrowInStageComponent);
            if (currentStage != nextStage) 
            {
                currentGrowInStageComponent.currentStage = nextStage;
            }  // and is exactly the same of the current stage    // Update the render status, this is the actual index into the texture collection to draw the item  
            
            
            
            
            
            var renderComponent : RenderableComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    currentGrowInStageComponent.entityId,
                    RenderableComponent.TYPE_ID
                    ), RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent != null) 
            {
                renderComponent.renderStatus = currentGrowInStageComponent.currentStage;
            }
        }
    }
    
    /**
     * The end of a level is a precise moment at which we want to do something like give a reward
     * 
     * @param levelNode
     * @param previousCompletionStatus
     * @param outItemIds 
     *      At the end, populated with list of item ids that were modified.
     * @param outPreviousStage
     *      For each changed item, get the list of stages the items were previously at.
     * @param outCurrentStage
     *      For each changed item, get the list of stages the items are at now
     */
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.LEVEL_SOLVED) 
        {
			m_itemInventory.outChangedRewardEntityIds = new Array<String>();
			m_itemInventory.outPreviousStages = new Array<Int>();
			m_itemInventory.outCurrentStages = new Array<Int>();
            
            var currentGrowInStageComponents : Array<Component> = m_itemInventory.componentManager.getComponentListForType(CurrentGrowInStageComponent.TYPE_ID);
            var numComponents : Int = currentGrowInStageComponents.length;
            var i : Int;
            var currentGrowInStageComponent : CurrentGrowInStageComponent;
            for (i in 0...numComponents){
                currentGrowInStageComponent = try cast(currentGrowInStageComponents[i], CurrentGrowInStageComponent) catch(e:Dynamic) null;
                
                var currentStage : Int = currentGrowInStageComponent.currentStage;
                var nextStage : Int = getNextStageForItem(currentGrowInStageComponent);
                if (currentStage != nextStage) 
                {
                    currentGrowInStageComponent.currentStage = nextStage;
                    
                    // Update the render status, this is the actual index into the texture collection to draw the item
                    // and is exactly the same of the current stage
                    var renderComponent : RenderableComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            currentGrowInStageComponent.entityId,
                            RenderableComponent.TYPE_ID
                            ), RenderableComponent) catch(e:Dynamic) null;
                    if (renderComponent != null) 
                    {
                        renderComponent.renderStatus = currentGrowInStageComponent.currentStage;
                    }  // Add the items that were modified  
                    
                    
                    
                    m_itemInventory.outChangedRewardEntityIds.push(this.getItemIdFromEntityId(currentGrowInStageComponent.entityId));
                    m_itemInventory.outPreviousStages.push(currentStage);
                    m_itemInventory.outCurrentStages.push(nextStage);
                }
            }
        }
    }
    
    /*
    Hard code logic per genre and per item
    This is messed up since items themselves are attached to a genre, but we have dependency between an instance of that
    item and the levels completed in a genre.
    */
    private function getCompletedLevelsForGenre(genreNodeName : String) : Int
    {
        // Get the number of levels in a genre marked with a "complete" value
        var nodeForGenre : GenreLevelPack = try cast(m_levelManager.getNodeByName(genreNodeName), GenreLevelPack) catch(e:Dynamic) null;
        var levelCompletedInGenre : Int = ((nodeForGenre != null)) ? nodeForGenre.numLevelLeafsCompleted : 0;
        return levelCompletedInGenre;
    }
    
    private function getItemIdFromEntityId(entityId : String) : String
    {
        var componentManager : ComponentManager = m_itemInventory.componentManager;
        var itemIdComponent : ItemIdComponent = try cast(componentManager.getComponentFromEntityIdAndType(entityId, ItemIdComponent.TYPE_ID), ItemIdComponent) catch(e:Dynamic) null;
        return itemIdComponent.itemId;
    }
    
    /**
     * Override this function to alter the behavior of how certain items change their state
     */
    private function getNextStageForItem(currentGrowInStageComponent : CurrentGrowInStageComponent) : Int
    {
        var nextStage : Int = 0;
        var useGenericEggStageFunction : Bool = false;
        
        // If the returned stage is different then signal something
        var entityId : String = currentGrowInStageComponent.entityId;
		var completedLevels : Int = 0;
        switch (entityId)
        {
            // Right now all eggs share the same progress model
            // Purple egg
            case "1":
                completedLevels = this.getCompletedLevelsForGenre("multiply_divide");
                useGenericEggStageFunction = true;
            // Blue egg
            case "3":
                completedLevels = this.getCompletedLevelsForGenre("fraction_ratio");
                useGenericEggStageFunction = true;
            // Yellow egg
            case "2":
                completedLevels = this.getCompletedLevelsForGenre("addition_subtraction");
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
