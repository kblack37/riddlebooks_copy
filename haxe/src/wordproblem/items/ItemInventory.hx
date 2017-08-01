package wordproblem.items;

import cgs.cache.ICgsUserCache;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;

import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ItemBlueprintComponent;
import wordproblem.engine.component.ItemIdComponent;
import wordproblem.scripts.items.BaseGiveRewardScript;

/**
 * This class defines a collection of items that are owned by some entity.
 * 
 * For example every item belonging to a player will be included in one of these objects.
 * Systems dealing with the drawing or modification of items will always deal with the inventory
 * rather than the data source.
 * 
 * Use the item data source in conjunction with this to fetch all neccessary properties for an item.
 * You can think of this as storing all volatile and instance specific data for an item, for example
 * the main display object that is used to visualize it in the world and whether or not it is hidden.
 * The main reason it is separated from the item data source is if multiple instances of a particular
 * item can exist. (Probably will never be the case, instance id and item id should be the same)
 */
class ItemInventory
{
    /**
     * Save name in the cache for list of items randomly given to the player
     */
    public static inline var ITEM_IDS_SAVE_KEY : String = "itemIds";
    
    /**
     * This is the main storage for all the data related to a player's inventory.
     * Each item (that is something tagged with a player specific item id) has a list
     * of components whose data is specific to that item
     */
    public var componentManager : ComponentManager;
    
    /**
     * At the end of each level we write out rewards that should be given.
     * The summary can use this to display correct images
     */
    public var outNewRewardItemIds : Array<String>;
    
    public var outChangedRewardEntityIds : Array<String>;
    public var outPreviousStages : Array<Int>;
    public var outCurrentStages : Array<Int>;
    
    private var m_componentFactory : ComponentFactory;
    
    /**
     * Need this to fetch the blueprint for an item instance
     */
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * HACK:
     * There are several items where it is not possible to determine whether the player acquired them
     * via other saved data or stats. For these items we have no choice but to save the id itself
     * so we remember the player has an item across different sessions.
     */
    private var m_itemIdsThatNeedToBeSaved : Array<String>;
    
    private var m_cache : ICgsUserCache;
    
    public function new(itemDataSource : ItemDataSource, cache : ICgsUserCache)
    {
        this.componentManager = new ComponentManager();
        this.outNewRewardItemIds = new Array<String>();
        this.outChangedRewardEntityIds = new Array<String>();
        this.outPreviousStages = new Array<Int>();
        this.outCurrentStages = new Array<Int>();
        
        m_componentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
        m_itemDataSource = itemDataSource;
        m_cache = cache;
        loadFromSaveData();
        
        // Add the reward collectable items
        m_itemIdsThatNeedToBeSaved.concat(BaseGiveRewardScript.LEVEL_UP_REWARDS);
        // Add the purchasable items
        m_itemIdsThatNeedToBeSaved.push("136");
        m_itemIdsThatNeedToBeSaved.push("137");
        m_itemIdsThatNeedToBeSaved.push("138");
        m_itemIdsThatNeedToBeSaved.push("139");
        m_itemIdsThatNeedToBeSaved.push("140");
        m_itemIdsThatNeedToBeSaved.push("141");
        m_itemIdsThatNeedToBeSaved.push("142");
        m_itemIdsThatNeedToBeSaved.push("143");
        m_itemIdsThatNeedToBeSaved.push("144");
        m_itemIdsThatNeedToBeSaved.push("145");
        m_itemIdsThatNeedToBeSaved.push("146");
        m_itemIdsThatNeedToBeSaved.push("147");
        m_itemIdsThatNeedToBeSaved.push("148");
        m_itemIdsThatNeedToBeSaved.push("149");
    }
    
    /**
     * List of items that the player should automatically acquire at the start of the game.
     * ??? Is this necessary
     */
    public function loadInitialItems(playerItemList : Array<Dynamic>) : Void
    {
        var numPlayerItems : Int = playerItemList.length;
        var instanceId : String = null;
        var i : Int = 0;
        for (i in 0...numPlayerItems){
            instanceId = playerItemList[i];
            this.createItemFromBlueprint(instanceId);
        }
    }
    
    /**
     * Create a brand new instance of a particular item.
     * 
     * @param instanceId
     *      If not found in the map, assume it is the same as the item id
     * @param itemId
     *      If null, then some fixed definition of the instance id should be used
     *      to fetch it
     */
    public function createItemFromBlueprint(instanceId : String, itemId : String = null) : Void
    {
        itemId = instanceId;
        var itemBlueprintComponent : ItemBlueprintComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                itemId,
                ItemBlueprintComponent.TYPE_ID
                ), ItemBlueprintComponent) catch(e:Dynamic) null;
        var componentListObject : Dynamic = itemBlueprintComponent.data;
        componentListObject.entityId = instanceId;
        
        m_componentFactory.createAndAddComponentsForSingleItem(this.componentManager, componentListObject);
    }
    
    /**
     * Convert the inventory collection into a string that can easily be saved
     * to an external storage medium.
     * 
     * HACK: This object now has internal knowledge about what are the important items that should be saved
     * This is to reduce the total size of the array since some items we can figure from other data whether they
     * got the item.
     */
    public function save() : Void
    {
        var prevItemsSaved : Array<Dynamic> = ((m_cache.saveExists("itemIds"))) ? m_cache.getSave("itemIds") : [];
        
        // For each entity name create a list of components
        // The items that we care about saving are those in which it is impossible to determine
        // that the player earned it from exisiting data.
        // (All the randomly given rewards fit into this class, since those could be anything we
        // need to remember which ones were actually given via this cache)
        var itemIds : Array<Dynamic> = [];
        var itemIdComponents : Array<Component> = this.componentManager.getComponentListForType(ItemIdComponent.TYPE_ID);
        var i : Int = 0;
        var numComponents : Int = itemIdComponents.length;
        for (i in 0...numComponents){
            var itemIdComponent : ItemIdComponent = try cast(itemIdComponents[i], ItemIdComponent) catch(e:Dynamic) null;
            var itemId : String = itemIdComponent.itemId;
            if (Lambda.indexOf(m_itemIdsThatNeedToBeSaved, itemId) >= 0) 
            {
                itemIds.push(itemId);
            }
        }
        
        if (prevItemsSaved == null || prevItemsSaved.length < itemIds.length) 
        {
            m_cache.setSave(ItemInventory.ITEM_IDS_SAVE_KEY, itemIds);
        }
    }
    
    /**
     * It is important to realize that only a subset of items need to be saved to be saved to
     * a persistent source. Furthermore only a few of those properties for those items need to be
     * saved at all. (This is because we might be able to determine the presence of other items
     * or their properties from other data, for example if a particular level is marked as complete
     * then a player would always have item X)
     */
    private function loadFromSaveData() : Void
    {
        // The first piece of the cache is to back a list of item instance ids unique to the player
        // (we cannot determine that the player has these items any other way)
        if (m_cache.saveExists("itemIds")) 
        {
            // FORMAT {itemIds:[list of strings for ids]}
            var itemIds : Array<Dynamic> = m_cache.getSave("itemIds");
            if (itemIds == null) 
            {
                m_cache.setSave("itemIds", itemIds);
                itemIds = [];
            }
            
            var i : Int = 0;
            var numIds : Int = itemIds.length;
            for (i in 0...numIds){
                // For each id, make sure a blueprint is created for the item
                var itemId : String = itemIds[i];
                this.createItemFromBlueprint(itemId, itemId);
            }
        }
    }
}
