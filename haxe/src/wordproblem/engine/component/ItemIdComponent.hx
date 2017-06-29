package wordproblem.engine.component;


/**
 * Used for items belonging to a player, this component provides the link to the item id
 * the entity is defined by.
 * 
 * This is an extra layer of indirection so we can quickly access the attributes belonging
 * to a class of items.
 */
class ItemIdComponent extends Component
{
    public static inline var TYPE_ID : String = "ItemIdComponent";
    
    /**
     * Item id that maps to an entry in the items_db.json data file.
     */
    public var itemId : String;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
    }
    
    override public function serialize() : Dynamic
    {
        var data : Dynamic = {
            typeId : TYPE_ID,
            data : {
                id : itemId

            },

        };
        return data;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.itemId = data.id;
    }
}
