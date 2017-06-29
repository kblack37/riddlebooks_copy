package wordproblem.engine.component;


/**
 * A transformable object has position, orientation, and scale
 */
class TransformComponent extends Component
{
    public static inline var TYPE_ID : String = "TransformComponent";
    
    public var x : Float;
    public var y : Float;
    public var direction : Int;
    public var scale : Float;
    
    /**
     * Rotation of the object in radians
     */
    public var rotation : Float;
    
    /**
     * This is an extra value to indicate special animation status. For example 0->stand still
     * and 1, 2 are different states of walking.
     */
    public var animationCycle : Int;
    
    public function new(entityId : String,
            x : Float = 0,
            y : Float = 0,
            initalDirection : Int = -1)
    {
        super(entityId, TransformComponent.TYPE_ID);
        
        this.x = x;
        this.y = y;
        this.direction = initalDirection;
        this.scale = 1;
        this.rotation = 0.0;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.x = data.x;
        this.y = data.y;
        if (data.exists("scale")) 
        {
            this.scale = data.scale;
        }
        
        if (data.exists("rotation")) 
        {
            this.rotation = data.rotation;
        }
    }
}
