package wordproblem.engine.component
{
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;

    /**
     * When attached to an entity, signal that we should play a simple animation that tweens
     * the transparency/color to create a blink effect.
     */
    public class BlinkComponent extends Component
    {
        public static const TYPE_ID:String = "BlinkComponent";
        
        /**
         * DO NOT SET THIS MANUALLY, this is set up by the blink system
         */
        public var tween:Tween;
        
        /**
         * The number of seconds it should take for component to go from fully opaque
         * to the target minimum transparency level.
         */
        public var duration:Number;
        
        /**
         * The minimum alpha threshold the blink should stop at
         */
        public var minAlpha:Number;
        
        public function BlinkComponent(entityId:String, duration:Number=0.5, minAlpha:Number = 0.2)
        {
            super(entityId, TYPE_ID);
            
            this.duration = duration;
            this.minAlpha = minAlpha;
        }
        
        override public function dispose():void
        {
            if (this.tween != null)
            {
                // HACK: Assume the tween is always added to the root juggler
                Starling.juggler.remove(this.tween);
                
                // Restore prior alpha value
                (this.tween.target as DisplayObject).alpha = 1.0;
                this.tween = null;
            }
        }
    }
}