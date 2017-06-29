package wordproblem.engine.component;


class NameComponent extends Component
{
    public static inline var TYPE_ID : String = "NameComponent";
    
    public var name : String;
    
    public function new(entityId : String, name : String)
    {
        super(entityId, TYPE_ID);
        
        this.name = name;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.name = data.name;
    }
}
