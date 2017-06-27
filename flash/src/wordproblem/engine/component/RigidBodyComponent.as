package wordproblem.engine.component
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

    /**
     * Component that defines whether an entity can be represented by by solid
     * bounding box. With some well defined position.
     */
	public class RigidBodyComponent extends Component
	{
		public static const TYPE_ID:String = "RigidBodyComponent";
		
		public var boundingRectangle:Rectangle;
        private var m_pointBuffer:Point
		
		public function RigidBodyComponent(entityId:String,
										   x:Number = 0, 
										   y:Number = 0,
										   width:Number = 0, 
										   height:Number = 0)
		{
			boundingRectangle = new Rectangle(x, y, width, height);
			super(entityId, RigidBodyComponent.TYPE_ID);
            
            m_pointBuffer = new Point();
		}
		
		/**
		 * Assuming an even density distribution, get the central point
		 * of this body.
		 */
		public function getCenterOfMass():Point
		{
            m_pointBuffer.x = boundingRectangle.x + boundingRectangle.width / 2;
            m_pointBuffer.y = boundingRectangle.y + boundingRectangle.height / 2;
			return m_pointBuffer;
		}
        
        override public function deserialize(data:Object):void
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
}