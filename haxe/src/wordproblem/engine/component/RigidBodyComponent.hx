package wordproblem.engine.component;


import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * Component that defines whether an entity can be represented by by solid
 * bounding box. With some well defined position.
 */
class RigidBodyComponent extends Component
{
    public static inline var TYPE_ID : String = "RigidBodyComponent";
    
    public var boundingRectangle : Rectangle;
    private var m_pointBuffer : Point;
    
    public function new(entityId : String,
            x : Float = 0,
            y : Float = 0,
            width : Float = 0,
            height : Float = 0)
    {
        boundingRectangle = new Rectangle(x, y, width, height);
        super(entityId, RigidBodyComponent.TYPE_ID);
        
        m_pointBuffer = new Point();
    }
    
    /**
		 * Assuming an even density distribution, get the central point
		 * of this body.
		 */
    public function getCenterOfMass() : Point
    {
        m_pointBuffer.x = boundingRectangle.x + boundingRectangle.width / 2;
        m_pointBuffer.y = boundingRectangle.y + boundingRectangle.height / 2;
        return m_pointBuffer;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        if (this.boundingRectangle == null) 
        {
            this.boundingRectangle = new Rectangle();
        }
        
        this.boundingRectangle.setTo(
                data.x,
                data.y,
                data.width,
                data.height
                );
    }
}
