package wordproblem.engine.component
{
    import wordproblem.engine.animation.ScanAnimation;

    public class ScanComponent extends Component
    {
        public static const TYPE_ID:String = "ScanComponent";
        
        public var color:uint;
        public var velocity:Number;
        public var width:Number;
        public var delay:Number;
        
        /**
         * The animation that modifies the view.
         */
        public var animation:ScanAnimation;
        
        public function ScanComponent(entityId:String, 
                                      color:uint, 
                                      velocity:Number, 
                                      width:Number,
                                      delay:Number)
        {
            super(entityId, TYPE_ID);
            
            this.refresh(color, velocity, width, delay);
        }
        
        override public function dispose():void
        {
            if (this.animation != null)
            {
                this.animation.stop();
            }
        }
        
        override public function deserialize(data:Object):void
        {
            var color:uint = parseInt(data.color, 16);
            var velocity:Number = data.velocity;
            var width:Number = data.width;
            var delay:Number = data.delay;
            this.refresh(color, velocity, width, delay);
        }
        
        private function refresh(color:uint, velocity:Number, width:Number, delay:Number):void
        {
            this.color = color;
            this.velocity = velocity;
            this.width = width;
            this.delay = delay;
            this.animation = null;
        }
    }
}