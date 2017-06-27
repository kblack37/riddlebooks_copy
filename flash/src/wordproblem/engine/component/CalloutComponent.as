package wordproblem.engine.component
{
    import feathers.controls.Callout;
    
    import starling.animation.Tween;
    import starling.display.DisplayObject;
    
    /**
     * This component keeps track of information for showing a callout/tooltip next to
     * an entity. This also doubles as a simple dialog box
     */
    public class CalloutComponent extends Component
    {
        public static const TYPE_ID:String = "CalloutComponent";
        
        /**
         * Reference to the actuall callout display object. Do not set this manually,
         * it is automatically created by a system.
         */
        public var callout:Callout;
        
        /**
         * If null, don't use any background
         */
        public var backgroundTexture:String;
        
        /**
         * The tint to apply to the background
         */
        public var backgroundColor:uint = 0xFFFFFF;
        
        /**
         * If null, don't use any arrow. HACK:
         * Currently not read, as long as not null defaults to a triangle colored the same as
         * the background.
         */
        public var arrowTexture:String;
        
        /**
         * Desired orientation of the callout, by default let feathers position it.
         */
        public var directionFromOrigin:String;
        
        /**
         * Space to put around the edge borders of the background image.
         * Used to accomodate the arrow texture, this space will separate the arrow from the main
         * background.
         */
        public var edgePadding:Number;
        
        /**
         * HACK: For some reason, dialogs that are text views have almost no bottom padding.
         * This causes some of the content to bleed over.
         * 
         * Set this to a positive value to prevent the bleed over
         */
        public var contentPadding:Number;
        
        /**
         * The number of seconds for the arrow to move up or down
         * 
         * If zero or less, then no animation should be played. Also note that the directionFromOrigin
         * must not be direction_any since we need to know which arrow image to tween.
         */
        public var arrowAnimationPeriod:Number;
        
        /**
         * Reference to the tween used to animate the arrow, only used internally by the system
         * that draws the callout
         */
        public var arrowAnimationTween:Tween;
        
        /**
         * Placeholder, the contents to show in the callout. You need to explicitly set this.
         * In most cases this is just a textfield.
         */
        public var display:DisplayObject;
        
        /**
         * If true, this callout should be removed when clicked anywhere outside
         */
        public var closeOnTouchOutside:Boolean;
        
        /**
         * If true, this callout should be removed when clicked anywhere inside
         */
        public var closeOnTouchInside:Boolean;
        
        /**
         * Function to be triggered if a callout is to be closed. Accepts no params
         */
        public var closeCallback:Function;
        
        /**
         * Additional x offset to apply to the regular position of the callout
         */
        public var xOffset:Number;
        
        /**
         * Additional y offset to apply to the regular position of the callout
         */
        public var yOffset:Number;
        
        public function CalloutComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
            
            this.directionFromOrigin = Callout.DIRECTION_ANY;
            this.edgePadding = 0.0;
            this.contentPadding = 0.0;
            this.arrowAnimationPeriod = 0.0;
            this.closeOnTouchOutside = false;
            this.closeOnTouchInside = false;
            
            this.xOffset = 0.0;
            this.yOffset = 0.0;
        }
        
        override public function dispose():void
        {
            if (this.callout != null)
            {
                this.callout.close(true);
                this.callout = null;
                
                // If the arrow texture is animating, kill the tween associated with it.
                // The system that created the tween should be the on disposing it
                // The on complete notifies the system to erase the tween
                if (this.arrowAnimationTween != null)
                {
                    this.arrowAnimationTween.onComplete(this.arrowAnimationTween);
                    this.arrowAnimationTween = null;
                }
            }
        }
    }
}