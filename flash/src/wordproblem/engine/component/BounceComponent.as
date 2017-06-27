package wordproblem.engine.component
{
    import flash.geom.Point;
    
    import starling.animation.Tween;
    import starling.core.Starling;

    public class BounceComponent extends Component
    {
        public static const TYPE_ID:String = "BounceComponent";
        
        /**
         * Is the bounce animation in progress. If the tween is paused then do not update the
         * tween.
         */
        public var paused:Boolean;
        
        /**
         * The tween that will apply the changes the target display object
         */
        public var tween:Tween;
        
        /**
         * The original position of the object that is bouncing before the animation started.
         */
        private var originalPosition:Point;
        
        public function BounceComponent(entityId:String)
        {
            super(entityId, BounceComponent.TYPE_ID);
        }
        
        override public function dispose():void
        {
            // Kill the animation
            if (tween != null && Starling.juggler.contains(tween))
            {
                Starling.juggler.remove(tween);
            }
            
            this.resetToOriginalPosition();
        }
        
        public function setOriginalPosition(x:Number, y:Number):void
        {
            originalPosition = new Point(x, y);
        }
        
        public function resetToOriginalPosition():void
        {
            if (tween != null)
            {
                tween.target.x = originalPosition.x;
                tween.target.y = originalPosition.y;
            }
        }
    }
}