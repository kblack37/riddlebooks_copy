package wordproblem.display
{
    import starling.display.DisplayObject;
    import starling.display.Sprite;
    
    public class Scale9CompositeImage extends Sprite
    {
        public function Scale9CompositeImage(... args)
        {
            super();
            
            for (var i:int = 0; i < args.length; i++)
            {
                var childToAdd:DisplayObject = args[i] as DisplayObject;
                if (childToAdd != null)
                {
                    addChild(childToAdd);
                }
            }
        }
        
        override public function set width(value:Number):void
        {
            var i:int;
            var numChildren:int = this.numChildren;
            for (i = 0; i < numChildren; i++)
            {
                this.getChildAt(i).width = value;
            }
        }
        
        override public function set height(value:Number):void
        {
            var i:int;
            var numChildren:int = this.numChildren;
            for (i = 0; i < numChildren; i++)
            {
                this.getChildAt(i).height = value;
            }
        }
    }
}