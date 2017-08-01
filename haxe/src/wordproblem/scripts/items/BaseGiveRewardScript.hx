package wordproblem.scripts.items;


import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ItemIdComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.scripts.BaseBufferEventScript;
import wordproblem.xp.PlayerXpModel;

/**
 * Scripted logic that gives rewards to the player.
 * You can think of each unique reward as having some set of rules that must be satisfied before
 * it can be awarded to the player. The script iterates through all the rules and if they are
 * satisfied for the first time, an item is given to the player.
 * 
 * The logic of a single reward needs to include some way to tell that a reward has already been
 * given if that reward should only be earnable once in a playthrough.
 * 
 * This manually injects new rewards into the player's inventory, so saving is necessary.
 */
class BaseGiveRewardScript extends BaseBufferEventScript
{
    // Static list of all possible randomly given rewards for leveling up
    public static var LEVEL_UP_REWARDS : Array<String> = [
                "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", 
                "117", "118", "119", "120", "121", "122", "123", "124", "125", "126", "127", 
                "128", "129", "130", "131", "132", "133", "134", "135", 
                "102", "103", "104", "105", "106", "107", "108", "109", 
                "110", "111", "112", "113", "114", "115", "116", 
                "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99", "100", "101", 
                "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41"];
    
    /**
     * This is the actual list of items that the player can potentially still acquire. Items they already earned
     * are filtered out
     */
    private var m_availableLevelUpRewards : Array<String>;
    
    private var m_gameEngine : IGameEngine;
    
    /**
     * This is the primary object in which to inject newly added objects
     */
    private var m_itemInventory : ItemInventory;
    
    /**
     * An object that contains all possible rewards that can be handed out during a playthrough.
     * This is just a set of tuples with id and items that should be added to the player's inventory
     */
    private var m_rewardsData : Array<Dynamic>;
    
    /**
     * Level manager is needed because some rewards require checking how far in the level progression
     * the player has reached
     */
    private var m_levelManager : WordProblemCgsLevelManager;
    
    /**
     * The xp model is needed because some rewards are given after the level has increased their level
     */
    private var m_xpModel : PlayerXpModel;
    
    /**
     *
     * @param rewardsData
     *      A list of objects containing an id for the reward collection and the list
     *      of item ids in that collection (defined in an external data file)
     */
    public function new(gameEngine : IGameEngine,
            itemInventory : ItemInventory,
            rewardsData : Array<Dynamic>,
            levelManager : WordProblemCgsLevelManager,
            xpModel : PlayerXpModel,
            id : String)
    {
        super(id);
        
        m_gameEngine = gameEngine;
        m_itemInventory = itemInventory;
        m_rewardsData = rewardsData;
        m_levelManager = levelManager;
        m_xpModel = xpModel;
        
        gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        gameEngine.addEventListener(GameEvent.LEVEL_COMPLETE, bufferEvent);
        
        // For any items in which we can determine whether they are earned soley from looking
        // at the save data, we do not need to store the items in the cache.
        // Instead we just hand them out at the start.
        checkAndAddItemsToInventory(m_rewardsData, null);
        
        // From list of candidate, random rewards find which ones the player already has.
        // They should not be given again
        m_availableLevelUpRewards = new Array<String>();
        var i : Int = 0;
        var numPossibleRandomRewards : Int = LEVEL_UP_REWARDS.length;
        for (i in 0...numPossibleRandomRewards){
            var itemId : String = LEVEL_UP_REWARDS[i];
            if (m_itemInventory.componentManager.getComponentFromEntityIdAndType(itemId, ItemIdComponent.TYPE_ID) == null) 
            {
                m_availableLevelUpRewards.push(itemId);
            }
        }
    }
    
    public function resetData() : Void
    {
        checkAndAddItemsToInventory(m_rewardsData, null);
    }
    
    /**
     * Exposed publically for debug purposes
     * 
     * @param outItemIds
     *      Buffer to store the item ids that are successfully given.
     */
    public function giveRewardFromEntityId(entityId : String, outItemIds : Array<String> = null) : Void
    {
        // This refers to the player's item collection
        var componentManager : ComponentManager = m_itemInventory.componentManager;
        
        // Need to map the reward id to the item id/item ids so we can add the appropriate
        // data structures into the player's inventory
        var i : Int = 0;
        var numRewards : Int = m_rewardsData.length;
        for (i in 0...numRewards){
            var rewardData : Dynamic = m_rewardsData[i];
            if (rewardData.id == entityId) 
            {
                if (rewardData.exists("itemInstanceIds")) 
                {
                    // Add each item inside a collection, assume collections do not nest
                    var rewardsCollection : Array<Dynamic> = try cast(Reflect.field(rewardData, "itemInstanceIds"), Array<Dynamic>) catch(e:Dynamic) null;
                    for (idInCollection in rewardsCollection)
                    {
                        m_itemInventory.createItemFromBlueprint(idInCollection);
                        var itemIdComponent : ItemIdComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                                idInCollection,
                                ItemIdComponent.TYPE_ID
                                ), ItemIdComponent) catch(e:Dynamic) null;
                        
                        if (outItemIds != null) 
                        {
                            outItemIds.push(itemIdComponent.itemId);
                        }
                    }
                }
                else 
                {
                    m_itemInventory.createItemFromBlueprint(rewardData.itemInstanceId);
                    var itemIdComponent = try cast(m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                                    rewardData.itemInstanceId,
                                    ItemIdComponent.TYPE_ID
                                    ), ItemIdComponent) catch(e:Dynamic) null;
                    if (outItemIds != null) 
                    {
                        outItemIds.push(itemIdComponent.itemId);
                    }
                }
                break;
            }
        }
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        // Detecting rewards to give at the END of a level
        if (eventType == GameEvent.LEVEL_SOLVED) 
        {
			m_itemInventory.outNewRewardItemIds = new Array<String>();
            checkAndAddItemsToInventory(m_rewardsData, m_itemInventory.outNewRewardItemIds);
        }
        // Temp step to check if player leveled up by finishing this level.
        // If so give them a random collectable from an item pool
        // Assumes that the level stats have already been written out
        else if (eventType == GameEvent.LEVEL_COMPLETE) 
        {
            // Figure out how many levels the player has gained since completing the last level
            var outData : Array<Int> = new Array<Int>();
            m_xpModel.getLevelAndRemainingXpFromTotalXp(m_xpModel.totalXP, outData);
            var currentLevel : Int = outData[0];
			outData = new Array<Int>();
            var xpInLevel : Int = m_gameEngine.getCurrentLevel().statistics.xpEarnedForLevel;
            m_xpModel.getLevelAndRemainingXpFromTotalXp(m_xpModel.totalXP - xpInLevel, outData);
            var prevLevel : Int = outData[0];
            var levelChange : Int = currentLevel - prevLevel;
            
            // For each level gained, give a random collectable from the level pool
            var i : Int = 0;
            for (i in 0...levelChange){
                var numCollectablesToGive : Int = 2;
                var j : Int = 0;
                for (j in 0...numCollectablesToGive){
                    if (m_availableLevelUpRewards.length > 0) 
                    {
                        var randomIndex : Int = Math.floor(Math.random() * m_availableLevelUpRewards.length);
                        var itemId : String = m_availableLevelUpRewards.splice(randomIndex, 1)[0];
                        
                        m_itemInventory.createItemFromBlueprint(itemId);
                        m_itemInventory.outNewRewardItemIds.push(itemId);
                    }
                }
            }
        }
    }
    
    /**
     * For items that are permanent AND unique in the inventory, an easy way to check whether they
     * have already been awarded is just to see if the item inventory contains the entityId.
     * (We assign entityIds for each item here)
     * 
     * @return
     *      true if reward already given
     */
    private function checkIfUniqueRewardGiven(entityId : String) : Bool
    {
        var itemIdComponent : Component = m_itemInventory.componentManager.getComponentFromEntityIdAndType(
                entityId,
                ItemIdComponent.TYPE_ID
                );
        return itemIdComponent != null;
    }
    
    /**
     * Given a list of candidate reward ids, figure out which ones the player has not earned yet
     * and has satisfied the conditions for
     */
    private function checkAndAddItemsToInventory(rewardsData : Array<Dynamic>, outItemIds : Array<String> = null) : Void
    {
        var numEntities : Int = rewardsData.length;
        var i : Int = 0;
        var entityId : String = null;
        for (i in 0...numEntities){
            entityId = rewardsData[i].id;
            
            // Get the function that checks whether the given entity id should be given
            if (shouldGiveReward(entityId)) 
            {
                giveRewardFromEntityId(entityId, outItemIds);
            }
        }
    }
    
    /**
     * Get whether a particular reward item should be given to the player
     * Override to change when a reward is given
     * 
     * @return
     *      True if a reward should be given
     */
    private function shouldGiveReward(rewardEntityId : String) : Bool
    {
        return false;
    }
}
