package wordproblem.engine.component
{
    /**
     * A transformable object has position, orientation, and scale
     */
    public class TransformComponent extends Component
    {
        public static const TYPE_ID:String = "TransformComponent";
        
        public var x:Number;
        public var y:Number;
        public var direction:int;
        public var scale:Number;
        
        /**
         * Rotation of the object in radians
         */
        public var rotation:Number;
        
        /**
         * This is an extra value to indicate special animation status. For example 0->stand still
         * and 1, 2 are different states of walking.
         */
        public var animationCycle:int;
        
        public function TransformComponent(entityId:String,
                                           x:Number = 0, 
                                           y:Number = 0, 
                                           initalDirection:int = -1)
        {
            super(entityId, TransformComponent.TYPE_ID);
            
            this.x = x;
            this.y = y;
            this.direction = initalDirection;
            this.scale = 1;
            this.rotation = 0.0;
        }
        
        override public function deserialize(data:Object):void
        {
            this.x = data.x;
            this.y = data.y;
            if (data.hasOwnProperty("scale"))
            {
                this.scale = data.scale;
            }
            
            if (data.hasOwnProperty("rotation"))
            {
                this.rotation = data.rotation
            }
        }
    }
}