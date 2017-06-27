package wordproblem.engine.component
{
    /**
     * Used for items belonging to a player, this component provides the link to the item id
     * the entity is defined by.
     * 
     * This is an extra layer of indirection so we can quickly access the attributes belonging
     * to a class of items.
     */
    public class ItemIdComponent extends Component
    {
        public static const TYPE_ID:String = "ItemIdComponent";
        
        /**
         * Item id that maps to an entry in the items_db.json data file.
         */
        public var itemId:String;
        
        public function ItemIdComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
        
        override public function serialize():Object
        {
            var data:Object = {
                typeId:TYPE_ID,
                data:{id:itemId}
            };
            return data;
        }
        
        override public function deserialize(data:Object):void
        {
            this.itemId = data.id;
        }
    }
}