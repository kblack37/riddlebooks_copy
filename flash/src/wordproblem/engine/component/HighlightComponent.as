package wordproblem.engine.component
{
    import starling.animation.Juggler;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;

    public class HighlightComponent extends Component
    {
        public static const TYPE_ID:String = "HighlightComponent";
        
        /**
         * The color to apply to the highlight
         */
        public var color:uint;
        
        /**
         * If we want the highlight to pulse over time, this is the number of seconds
         * that it should take to go for opacity to transition from max to min values.
         * 
         * If zero, do not animate.
         */
        public var animationPeriod:Number;
        
        /**
         * Right now we are assuming a highlight is just another texture that gets added somewhere
         * on the target object. If null the object doesn't have a currently displayed highlight.
         * 
         * (Set by the highlight system)
         */
        public var displayedHighlight:DisplayObject;
        
        /**
         * Set if the highlight is currently animating
         * 
         * (ONLY SET and USED INTERNALLY)
         */
        public var tween:Tween;
        
        /**
         * The juggler that is playing the tween
         * 
         * (ONLY SET and USED INTERNALLY)
         */
        public var juggler:Juggler;
        
        /**
         * This component indicates that some part of the game should get some glow around it. 
         */
        public function HighlightComponent(entityId:String, color:uint, animationPeriod:Number)
        {
            super(entityId, HighlightComponent.TYPE_ID);
            
            this.color = color;
            this.animationPeriod = animationPeriod;
            this.displayedHighlight = null;
        }
        
        override public function dispose():void
        {
            if (tween != null)
            {
                this.juggler.remove(tween);
                this.juggler = null;
            }
            
            if (displayedHighlight != null)
            {
                displayedHighlight.removeFromParent(true);
            }
        }
    }
}