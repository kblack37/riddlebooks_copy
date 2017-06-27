package wordproblem.scripts.items
{
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
    public class BaseAdvanceItemStageScript extends BaseBufferEventScript
    {
        /**
         * These are the items belonging to some entity, like the player.
         * The script will read and write this data to cause the item to change
         * in stages.
         */
        protected var m_itemInventory:ItemInventory;
        
        /**
         * This data source is required to figure out the maximum number of stages each particular item
         * can take on.
         */
        protected var m_itemDataSource:ItemDataSource;
        
        /**
         * The level manager is used because several conditions will require seeing how many levels
         * were completed by the user.
         */
        protected var m_levelManager:WordProblemCgsLevelManager;
        
        public function BaseAdvanceItemStageScript(gameEngine:IGameEngine,
                                           itemInventory:ItemInventory, 
                                           itemDataSource:ItemDataSource, 
                                           levelManager:WordProblemCgsLevelManager, 
                                           id:String=null)
        {
            super(id);
            
            m_itemInventory = itemInventory;
            m_itemDataSource = itemDataSource;
            m_levelManager = levelManager;
            
            gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
            
            resetData();
        }
        
        public function resetData():void
        {
            var currentGrowInStageComponents:Vector.<Component> = m_itemInventory.componentManager.getComponentListForType(CurrentGrowInStageComponent.TYPE_ID);
            var numComponents:int = currentGrowInStageComponents.length;
            var i:int;
            var currentGrowInStageComponent:CurrentGrowInStageComponent;
            for (i = 0; i < numComponents; i++)
            {
                currentGrowInStageComponent = currentGrowInStageComponents[i] as CurrentGrowInStageComponent;
                
                var currentStage:int = currentGrowInStageComponent.currentStage;
                var nextStage:int = getNextStageForItem(currentGrowInStageComponent);
                if (currentStage != nextStage)
                {
                    currentGrowInStageComponent.currentStage = nextStage;
                }
                
                // Update the render status, this is the actual index into the texture collection to draw the item
                // and is exactly the same of the current stage
                var renderComponent:RenderableComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    currentGrowInStageComponent.entityId,
                    RenderableComponent.TYPE_ID
                ) as RenderableComponent;
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
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.LEVEL_SOLVED)
            {
                m_itemInventory.outChangedRewardEntityIds.length = 0;
                m_itemInventory.outPreviousStages.length = 0;
                m_itemInventory.outCurrentStages.length = 0;
                
                var currentGrowInStageComponents:Vector.<Component> = m_itemInventory.componentManager.getComponentListForType(CurrentGrowInStageComponent.TYPE_ID);
                var numComponents:int = currentGrowInStageComponents.length;
                var i:int;
                var currentGrowInStageComponent:CurrentGrowInStageComponent;
                for (i = 0; i < numComponents; i++)
                {
                    currentGrowInStageComponent = currentGrowInStageComponents[i] as CurrentGrowInStageComponent;
                    
                    var currentStage:int = currentGrowInStageComponent.currentStage;
                    var nextStage:int = getNextStageForItem(currentGrowInStageComponent);
                    if (currentStage != nextStage)
                    {
                        currentGrowInStageComponent.currentStage = nextStage;
                        
                        // Update the render status, this is the actual index into the texture collection to draw the item
                        // and is exactly the same of the current stage
                        var renderComponent:RenderableComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            currentGrowInStageComponent.entityId,
                            RenderableComponent.TYPE_ID
                        ) as RenderableComponent;
                        if (renderComponent != null)
                        {
                            renderComponent.renderStatus = currentGrowInStageComponent.currentStage;
                        }
                        
                        // Add the items that were modified
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
        protected function getCompletedLevelsForGenre(genreNodeName:String):int
        {
            // Get the number of levels in a genre marked with a "complete" value
            const nodeForGenre:GenreLevelPack = m_levelManager.getNodeByName(genreNodeName) as GenreLevelPack;
            const levelCompletedInGenre:int = (nodeForGenre != null)?nodeForGenre.numLevelLeafsCompleted:0;
            return levelCompletedInGenre;
        }
        
        protected function getItemIdFromEntityId(entityId:String):String
        {
            var componentManager:ComponentManager = m_itemInventory.componentManager;
            var itemIdComponent:ItemIdComponent = componentManager.getComponentFromEntityIdAndType(entityId, ItemIdComponent.TYPE_ID) as ItemIdComponent;
            return itemIdComponent.itemId;
        }
        
        /**
         * Override this function to alter the behavior of how certain items change their state
         */
        protected function getNextStageForItem(currentGrowInStageComponent:CurrentGrowInStageComponent):int
        {
            var nextStage:int = 0;
            var useGenericEggStageFunction:Boolean = false;
            
            // If the returned stage is different then signal something
            var entityId:String = currentGrowInStageComponent.entityId;
            switch (entityId)
            {
                // Right now all eggs share the same progress model
                // Purple egg
                case "1":
                    var completedLevels:int = this.getCompletedLevelsForGenre("multiply_divide");
                    useGenericEggStageFunction = true;
                    break;
                // Blue egg
                case "3":
                    completedLevels = this.getCompletedLevelsForGenre("fraction_ratio");
                    useGenericEggStageFunction = true;
                    break;
                // Yellow egg
                case "2":
                    completedLevels = this.getCompletedLevelsForGenre("addition_subtraction");
                    useGenericEggStageFunction = true;
                    break;
            }
            
            if (useGenericEggStageFunction)
            {
                var itemId:String = getItemIdFromEntityId(entityId);
                var levelsCompletedPerStageComponent:LevelsCompletedPerStageComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                    itemId, 
                    LevelsCompletedPerStageComponent.TYPE_ID
                ) as LevelsCompletedPerStageComponent;
                
                // It is possible for something to advance multiple stages so we need to loop multiple times potentially
                // (happens at the start where we need to set the right initial stage so we need to loop through multiple time)
                
                // Make sure that the current stage can advance to a next value
                if (levelsCompletedPerStageComponent != null)
                {
                    var currentStage:int = currentGrowInStageComponent.currentStage;
                    nextStage = currentStage;
                    while (currentStage < levelsCompletedPerStageComponent.stageToLevelsCompleted.length)
                    {
                        var levelThresholdForCurrentStage:int = levelsCompletedPerStageComponent.stageToLevelsCompleted[currentStage];
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
}