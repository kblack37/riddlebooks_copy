package wordproblem.scripts.items;


import cgs.levelprogression.nodes.ICgsLevelNode;

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
class BaseRevealItemScript extends BaseBufferEventScript
{
    /**
     * This is the primary object in which to inject newly added objects
     */
    private var m_itemInventory : ItemInventory;
    
    /**
     * The level manager is the data source where we check whether something was discovered in the first
     * place.
     */
    private var m_levelManager : WordProblemCgsLevelManager;
    
    /**
     * This is the list of entity ids of the items that can switch from a hidden and revealed state
     */
    private var m_possibleEntityIdsRevealed : Array<String>;
    
    public function new(gameEngine : IGameEngine,
            itemInventory : ItemInventory,
            levelManager : WordProblemCgsLevelManager,
            possibleEntityIds : Array<String>,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_itemInventory = itemInventory;
        m_levelManager = levelManager;
        
        m_possibleEntityIdsRevealed = ((possibleEntityIds != null)) ? possibleEntityIds : new Array<String>();
        
        gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        
        resetData();
    }
    
    public function resetData() : Void
    {
        // For all the level components we need to fill in the missing information either about
        // the level name or its position, different parts of the app would use one or the other
        // in rendering, for example the level select screen needs the position info.
        var levelComponents : Array<Component> = m_itemInventory.componentManager.getComponentListForType(LevelComponent.TYPE_ID);
        var numComponents : Int = levelComponents.length;
        for (i in 0...numComponents){
            var levelComponent : LevelComponent = try cast(levelComponents[i], LevelComponent) catch(e:Dynamic) null;
            if (levelComponent.levelName != null) 
            {
                var targetNode : ICgsLevelNode = m_levelManager.getNodeByName(levelComponent.levelName);
                levelComponent.levelNode = targetNode;
                
                if (Std.is(targetNode, WordProblemLevelLeaf)) 
                {
                    var targetLeaf : WordProblemLevelLeaf = try cast(targetNode, WordProblemLevelLeaf) catch(e:Dynamic) null;
                    levelComponent.genre = targetLeaf.parentGenreLevelPack.getThemeId();
                    levelComponent.chapterIndex = targetLeaf.parentChapterLevelPack.index;
                    levelComponent.levelIndex = targetLeaf.index;
                }
                else if (Std.is(targetNode, WordProblemLevelPack)) 
                {
                    var targetPack : WordProblemLevelPack = try cast(targetNode, WordProblemLevelPack) catch(e:Dynamic) null;
                    if (targetPack.getParent() != null) 
                    {
                        levelComponent.levelIndex = targetPack.getParent().nodes.indexOf(targetNode);
                    }  // Trace up from the node to find the proper index, chapter, and genre  
                    
                    
                    
                    var tracerNode : ICgsLevelNode = targetPack.getParent();
                    while (tracerNode != null)
                    {
                        if (Std.is(tracerNode, WordProblemLevelPack)) 
                        {
                            if (Std.is(tracerNode, ChapterLevelPack)) 
                            {
                                levelComponent.chapterIndex = (try cast(tracerNode, ChapterLevelPack) catch(e:Dynamic) null).index;
                            }
                            else if (Std.is(tracerNode, GenreLevelPack)) 
                            {
                                levelComponent.genre = (try cast(tracerNode, GenreLevelPack) catch(e:Dynamic) null).getThemeId();
                            }
                            
                            tracerNode = (try cast(tracerNode, WordProblemLevelPack) catch(e:Dynamic) null).getParent();
                        }
                    }
                }
            }
            // Using the genre, chapter index, and level index, fill in the name
            else 
            {
                var genre : WordProblemLevelPack = try cast(m_levelManager.getNodeByName(levelComponent.genre), WordProblemLevelPack) catch(e:Dynamic) null;
                // Assuming chapters are just one level below the genre
                var chapter : WordProblemLevelPack = try cast(genre.nodes[levelComponent.chapterIndex], WordProblemLevelPack) catch(e:Dynamic) null;
                targetNode = chapter.nodes[levelComponent.levelIndex];
                levelComponent.levelName = targetNode.nodeName;
            }
            levelComponent.levelNode = targetNode;
        }  // At the start reveal initial items based on player progress or if the data json was overriden  
        
        
        
        var numEntities : Int = m_possibleEntityIdsRevealed.length;
        var i : Int;
        var entityId : String;
        for (i in 0...numEntities){
            entityId = m_possibleEntityIdsRevealed[i];
            
            var hiddenItemComponent : HiddenItemComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    entityId,
                    HiddenItemComponent.TYPE_ID
                    ), HiddenItemComponent) catch(e:Dynamic) null;
            var renderComponent : RenderableComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    entityId,
                    RenderableComponent.TYPE_ID
                    ), RenderableComponent) catch(e:Dynamic) null;
            
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
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.LEVEL_SOLVED) 
        {
            m_itemInventory.outNewRewardItemIds.length = 0;
            
            var numEntities : Int = m_possibleEntityIdsRevealed.length;
            var i : Int;
            var entityId : String;
            for (i in 0...numEntities){
                entityId = m_possibleEntityIdsRevealed[i];
                if (shouldRevealItem(entityId)) 
                {
                    var hiddenItemComponent : HiddenItemComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            HiddenItemComponent.TYPE_ID
                            ), HiddenItemComponent) catch(e:Dynamic) null;
                    hiddenItemComponent.isHidden = false;
                    
                    // Changing the hidden component should also change the render status
                    var renderComponent : RenderableComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            RenderableComponent.TYPE_ID
                            ), RenderableComponent) catch(e:Dynamic) null;
                    renderComponent.renderStatus = 1;
                    
                    var itemIdComponent : ItemIdComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            ItemIdComponent.TYPE_ID
                            ), ItemIdComponent) catch(e:Dynamic) null;
                    
                    // Output that this item has changed
                    m_itemInventory.outNewRewardItemIds.push(itemIdComponent.itemId);
                }
            }
        }
    }
    
    private function shouldRevealItem(rewardEntityId : String) : Bool
    {
        var giveReward : Bool = false;
        
        // Item should not be revealed again
        var hiddenItemComponent : HiddenItemComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                rewardEntityId,
                HiddenItemComponent.TYPE_ID
                ), HiddenItemComponent) catch(e:Dynamic) null;
        if (hiddenItemComponent.isHidden) 
        {
            // Several classes of items should be recieved if the player has finished a very specific
            // level in a progression, we first check this general condition
            // This depends on the level name or position of that level
            var levelComponent : LevelComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                    rewardEntityId,
                    LevelComponent.TYPE_ID
                    ), LevelComponent) catch(e:Dynamic) null;
            
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
