package wordproblem.scripts.items
{
    import cgs.levelProgression.nodes.ICgsLevelNode;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.HiddenItemComponent;
    import wordproblem.engine.component.ItemIdComponent;
    import wordproblem.engine.component.LevelComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.items.ItemInventory;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.level.nodes.ChapterLevelPack;
    import wordproblem.level.nodes.GenreLevelPack;
    import wordproblem.level.nodes.WordProblemLevelLeaf;
    import wordproblem.level.nodes.WordProblemLevelPack;
    import wordproblem.scripts.BaseBufferEventScript;
    
    /**
     * This script handles switching an item from it's hidden state to it's revealed state.
     * 
     * By definition a hidden item shows a transparent silouhette on the shelf.
     */
    public class BaseRevealItemScript extends BaseBufferEventScript
    {
        /**
         * This is the primary object in which to inject newly added objects
         */
        private var m_itemInventory:ItemInventory;
        
        /**
         * The level manager is the data source where we check whether something was discovered in the first
         * place.
         */
        private var m_levelManager:WordProblemCgsLevelManager;
        
        /**
         * This is the list of entity ids of the items that can switch from a hidden and revealed state
         */
        private var m_possibleEntityIdsRevealed:Vector.<String>;
        
        public function BaseRevealItemScript(gameEngine:IGameEngine,
                                         itemInventory:ItemInventory, 
                                         levelManager:WordProblemCgsLevelManager,
                                         possibleEntityIds:Vector.<String>,
                                         id:String=null, 
                                         isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_itemInventory = itemInventory;
            m_levelManager = levelManager;
            
            m_possibleEntityIdsRevealed = (possibleEntityIds != null) ? possibleEntityIds : new Vector.<String>();
            
            gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
            
            resetData();
        }
        
        public function resetData():void
        {
            // For all the level components we need to fill in the missing information either about
            // the level name or its position, different parts of the app would use one or the other
            // in rendering, for example the level select screen needs the position info.
            var levelComponents:Vector.<Component> = m_itemInventory.componentManager.getComponentListForType(LevelComponent.TYPE_ID);
            var numComponents:int = levelComponents.length;
            for (i = 0; i < numComponents; i++)
            {
                var levelComponent:LevelComponent = levelComponents[i] as LevelComponent;
                if (levelComponent.levelName != null)
                {
                    var targetNode:ICgsLevelNode = m_levelManager.getNodeByName(levelComponent.levelName);
                    levelComponent.levelNode = targetNode;
                    
                    if (targetNode is WordProblemLevelLeaf)
                    {
                        var targetLeaf:WordProblemLevelLeaf = targetNode as WordProblemLevelLeaf;
                        levelComponent.genre = targetLeaf.parentGenreLevelPack.getThemeId();
                        levelComponent.chapterIndex = targetLeaf.parentChapterLevelPack.index;
                        levelComponent.levelIndex = targetLeaf.index;
                    }
                    else if (targetNode is WordProblemLevelPack)
                    {
                        var targetPack:WordProblemLevelPack = targetNode as WordProblemLevelPack;
                        if (targetPack.getParent() != null)
                        {
                            levelComponent.levelIndex = targetPack.getParent().nodes.indexOf(targetNode);
                        }
                        
                        // Trace up from the node to find the proper index, chapter, and genre
                        var tracerNode:ICgsLevelNode = targetPack.getParent();
                        while (tracerNode != null)
                        {
                            if (tracerNode is WordProblemLevelPack)
                            {
                                if (tracerNode is ChapterLevelPack)
                                {
                                    levelComponent.chapterIndex = (tracerNode as ChapterLevelPack).index;
                                }
                                else if (tracerNode is GenreLevelPack)
                                {
                                    levelComponent.genre = (tracerNode as GenreLevelPack).getThemeId();
                                }
                                
                                tracerNode = (tracerNode as WordProblemLevelPack).getParent();
                            }
                        }
                    }
                }
                // Using the genre, chapter index, and level index, fill in the name
                else
                {
                    var genre:WordProblemLevelPack = m_levelManager.getNodeByName(levelComponent.genre) as WordProblemLevelPack;
                    // Assuming chapters are just one level below the genre
                    var chapter:WordProblemLevelPack = genre.nodes[levelComponent.chapterIndex] as WordProblemLevelPack;
                    targetNode = chapter.nodes[levelComponent.levelIndex];
                    levelComponent.levelName = targetNode.nodeName;
                }
                levelComponent.levelNode = targetNode;
            }
            
            // At the start reveal initial items based on player progress or if the data json was overriden
            var numEntities:int = m_possibleEntityIdsRevealed.length;
            var i:int;
            var entityId:String;
            for (i = 0; i < numEntities; i++)
            {
                entityId = m_possibleEntityIdsRevealed[i];
                
                var hiddenItemComponent:HiddenItemComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    entityId, 
                    HiddenItemComponent.TYPE_ID
                ) as HiddenItemComponent;
                var renderComponent:RenderableComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    entityId,
                    RenderableComponent.TYPE_ID
                ) as RenderableComponent;
                
                if (shouldRevealItem(entityId) || !hiddenItemComponent.isHidden)
                {
                    hiddenItemComponent.isHidden = false;
                    renderComponent.renderStatus = 1;
                }
                else
                {
                    renderComponent.renderStatus = 0;
                }
            }
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.LEVEL_SOLVED)
            {
                m_itemInventory.outNewRewardItemIds.length = 0;
                
                var numEntities:int = m_possibleEntityIdsRevealed.length;
                var i:int;
                var entityId:String;
                for (i = 0; i < numEntities; i++)
                {
                    entityId = m_possibleEntityIdsRevealed[i];
                    if (shouldRevealItem(entityId))
                    {
                        var hiddenItemComponent:HiddenItemComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            entityId, 
                            HiddenItemComponent.TYPE_ID
                        ) as HiddenItemComponent;
                        hiddenItemComponent.isHidden = false;
                        
                        // Changing the hidden component should also change the render status
                        var renderComponent:RenderableComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            RenderableComponent.TYPE_ID
                        ) as RenderableComponent;
                        renderComponent.renderStatus = 1;
                        
                        var itemIdComponent:ItemIdComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            entityId, 
                            ItemIdComponent.TYPE_ID
                        ) as ItemIdComponent;
                        
                        // Output that this item has changed
                        m_itemInventory.outNewRewardItemIds.push(itemIdComponent.itemId);
                    }
                }
            }
        }
        
        private function shouldRevealItem(rewardEntityId:String):Boolean
        {
            var giveReward:Boolean = false;
            
            // Item should not be revealed again
            var hiddenItemComponent:HiddenItemComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                rewardEntityId, 
                HiddenItemComponent.TYPE_ID
            ) as HiddenItemComponent;
            if (hiddenItemComponent.isHidden)
            {
                // Several classes of items should be recieved if the player has finished a very specific
                // level in a progression, we first check this general condition
                // This depends on the level name or position of that level
                var levelComponent:LevelComponent = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    rewardEntityId, 
                    LevelComponent.TYPE_ID
                ) as LevelComponent;
                
                if (levelComponent != null && levelComponent.levelNode != null)
                {
                    giveReward = levelComponent.levelNode.isComplete;
                }
                else
                {
                    // Add in logic to reveal items not dependent on the completion of a single particular level
                }
            }
            
            return giveReward;
        }
    }
}