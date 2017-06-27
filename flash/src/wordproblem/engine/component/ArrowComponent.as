package wordproblem.engine.component
{
    import flash.geom.Point;
    
    import feathers.display.Scale3Image;
    
    import starling.animation.Tween;

    /**
     * This component indicates that an enitity should have some arrow drawn pointing to it
     * 
     * Positioning treats the object pointing to as the origin, for example pointing to (0,0) will
     * point directly to the objects origin
     */
    public class ArrowComponent extends Component
    {
        public static const TYPE_ID:String = "ArrowComponent";
        
        /**
         * The point anchoring the tail of the arrow
         */
        public var startPoint:Point;
        
        /**
         * The point anchoring the head of the arrow
         */
        public var endPoint:Point;
        public var midPoint:Point;
        public var length:Number;
        public var rotation:Number;
        public var arrowView:Scale3Image;
        
        /**
         * Indicate whether the arrow should animate, the animation would be a basic bobbing
         * movement.
         */
        public var animate:Boolean;
        
        /**
         * The tween for the arrow movement animation
         */
        public var animation:Tween;
        
        /**
         * The previous position of the origin object the arrow is pointing at.
         * null if the arrow view was not created OR the arrow is not pointing at anything.
         */
        public var lastTargetPosition:Point;
        
        public function ArrowComponent(entityId:String, 
                                       startX:Number, 
                                       startY:Number, 
                                       endX:Number, 
                                       endY:Number)
        {
            super(entityId, TYPE_ID);
            
            this.refresh(startX, startY, endX, endY);
        }
        
        override public function dispose():void
        {
            if (arrowView != null)
            {
                arrowView.removeFromParent();
            }
        }
        
        override public function deserialize(data:Object):void
        {
            var startX:Number = data.startX;
            var startY:Number = data.startY;
            var endX:Number = data.endX;
            var endY:Number = data.endY;
            this.refresh(startX, startY, endX, endY);
        }
        
        private function refresh(startX:Number, startY:Number, endX:Number, endY:Number):void
        {
            this.startPoint = new Point(startX, startY);
            this.endPoint = new Point(endX, endY);
            this.midPoint = new Point((endX - startX) * 0.5 + startX, (endY - startY) * 0.5 + startY);
            this.animate = true;
            
            const deltaX:Number = endX - startX;
            const deltaY:Number = endY - startY;
            this.length = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
            
            this.rotation = Math.atan2(deltaY, deltaX);
        }
    }
}