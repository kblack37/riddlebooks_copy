package wordproblem.engine.component
{
    /**
     * Component to indicate that an entity should have one or more of its transform properties
     * updated to a new value within a given time.
     * 
     * This should be split up into multiple components if there is a need to update properties at different 
     */
    public class RotatableComponent extends Component
    {
        public static const TYPE_ID:String = "RotatableComponent";
        
        /**
         * Target rotation orientation in radians.
         */
        public var targetRotation:Number;
        
        /**
         * Radians to move per second.
         * 
         * If zero or less, perform rotation instantly
         */
        public var velocityRadiansPerSecond:Number;
        
        /**
         * Flag to indicate whether a request to rotate has been completed.
         * Used internally and by the system reading it.
         */
        public var isActive:Boolean;
        
        /**
         * Flag to indicate that a system has already started on this request. This is for the
         * situation where we create a tween to animate the change ONLY once per request.
         * 
         * Used internally only
         */
        public var requestHandled:Boolean;
        
        public function RotatableComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
        
        public function setRotation(targetRotation:Number, velocity:Number):void
        {
            this.targetRotation = targetRotation;
            this.velocityRadiansPerSecond = velocity;
            this.isActive = true;
            this.requestHandled = false;
        }
    }
}