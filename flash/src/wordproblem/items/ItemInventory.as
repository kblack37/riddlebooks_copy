package wordproblem.items
{
    import cgs.Cache.ICgsUserCache;
    
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
    public class ItemInventory
    {
        /**
         * Save name in the cache for list of items randomly given to the player
         */
        public static const ITEM_IDS_SAVE_KEY:String = "itemIds";
        
        /**
         * This is the main storage for all the data related to a player's inventory.
         * Each item (that is something tagged with a player specific item id) has a list
         * of components whose data is specific to that item
         */
        public var componentManager:ComponentManager;
        
        /**
         * At the end of each level we write out rewards that should be given.
         * The summary can use this to display correct images
         */
        public var outNewRewardItemIds:Vector.<String>;
        
        public var outChangedRewardEntityIds:Vector.<String>;
        public var outPreviousStages:Vector.<int>;
        public var outCurrentStages:Vector.<int>;
        
        private var m_componentFactory:ComponentFactory;
        
        /**
         * Need this to fetch the blueprint for an item instance
         */
        private var m_itemDataSource:ItemDataSource;
        
        /**
         * HACK:
         * There are several items where it is not possible to determine whether the player acquired them
         * via other saved data or stats. For these items we have no choice but to save the id itself
         * so we remember the player has an item across different sessions.
         */
        private var m_itemIdsThatNeedToBeSaved:Vector.<String>;
        
        private var m_cache:ICgsUserCache;
        
        public function ItemInventory(itemDataSource:ItemDataSource, cache:ICgsUserCache)
        {
            this.componentManager = new ComponentManager();
            this.outNewRewardItemIds = new Vector.<String>();
            this.outChangedRewardEntityIds = new Vector.<String>();
            this.outPreviousStages = new Vector.<int>();
            this.outCurrentStages = new Vector.<int>();
            
            m_componentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
            m_itemDataSource = itemDataSource;
            m_cache = cache;
            loadFromSaveData();
            
            // Add the reward collectable items
            m_itemIdsThatNeedToBeSaved = BaseGiveRewardScript.LEVEL_UP_REWARDS.concat();
            // Add the purchasable items
            m_itemIdsThatNeedToBeSaved.push("136", "137", "138", "139", "140", "141", "142", "143",
                "144", "145", "146", "147", "148", "149"
            );
        }
        
        /**
         * List of items that the player should automatically acquire at the start of the game.
         * ??? Is this necessary
         */
        public function loadInitialItems(playerItemList:Array):void
        {
            var numPlayerItems:int = playerItemList.length;
            var instanceId:String;
            var i:int;
            for (i = 0; i < numPlayerItems; i++)
            {
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
        public function createItemFromBlueprint(instanceId:String, itemId:String=null):void
        {
            itemId = instanceId;
            var itemBlueprintComponent:ItemBlueprintComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                itemId, 
                ItemBlueprintComponent.TYPE_ID
            ) as ItemBlueprintComponent;
            var componentListObject:Object = itemBlueprintComponent.data;
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
        public function save():void
        {
            var prevItemsSaved:Array = (m_cache.saveExists("itemIds")) ? m_cache.getSave("itemIds") : [];
            
            // For each entity name create a list of components
            // The items that we care about saving are those in which it is impossible to determine
            // that the player earned it from exisiting data.
            // (All the randomly given rewards fit into this class, since those could be anything we
            // need to remember which ones were actually given via this cache)
            var itemIds:Array = [];
            var itemIdComponents:Vector.<Component> = this.componentManager.getComponentListForType(ItemIdComponent.TYPE_ID);
            var i:int;
            var numComponents:int = itemIdComponents.length;
            for (i = 0; i < numComponents; i++)
            {
                var itemIdComponent:ItemIdComponent = itemIdComponents[i] as ItemIdComponent;
                var itemId:String = itemIdComponent.itemId;
                if (m_itemIdsThatNeedToBeSaved.indexOf(itemId) >= 0)
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
        private function loadFromSaveData():void
        {
            // The first piece of the cache is to back a list of item instance ids unique to the player
            // (we cannot determine that the player has these items any other way)
            if (m_cache.saveExists("itemIds"))
            {
                // FORMAT {itemIds:[list of strings for ids]}
                var itemIds:Array = m_cache.getSave("itemIds");
                if (itemIds == null)
                {
                    m_cache.setSave("itemIds", itemIds);
                    itemIds = [];
                }
                
                var i:int;
                var numIds:int = itemIds.length;
                for (i = 0; i < numIds; i++)
                {
                    // For each id, make sure a blueprint is created for the item
                    var itemId:String = itemIds[i];
                    this.createItemFromBlueprint(itemId, itemId);
                    
                    // TODO: Then we need to load any extra progress information for an item
                }
            }
        }
    }
}