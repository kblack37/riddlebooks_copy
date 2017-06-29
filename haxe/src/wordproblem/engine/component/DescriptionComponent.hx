package wordproblem.engine.component;


/**
 * Component has a short summary that talks about the entity in more detail.
 */
class DescriptionComponent extends Component
{
    public static inline var TYPE_ID : String = "DescriptionComponent";
    
    public var desc : String;
    
    public function new(entityId : String)
    {
        super(entityId, DescriptionComponent.TYPE_ID);
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.desc = data.desc;
    }
}
