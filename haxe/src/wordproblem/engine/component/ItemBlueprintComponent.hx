package wordproblem.engine.component;


/**
 * An item is made up of fixed properties that are the same for every instance of that item
 * and dynamic properties that vary depending on player progress or vary per instance.
 * 
 * This component keeps track of the json object defining the component list that act like
 * the blueprint for every brand new instance.
 */
class ItemBlueprintComponent extends Component
{
    public static inline var TYPE_ID : String = "ItemBlueprintComponent";
    
    public var data : Dynamic;
    
    public function new(entityId : String)
    {
        super(entityId, ItemBlueprintComponent.TYPE_ID);
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.data = data;
    }
}
