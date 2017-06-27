package wordproblem.engine.barmodel.view
{
    import dragonbox.common.dispose.IDisposable;
    
    import starling.display.Sprite;
    
    public class ResizeableBarPieceView extends Sprite implements IDisposable
    {
        /**
         * Total length in pixels of this display.
         */
        public var pixelLength:Number;
        
        public function ResizeableBarPieceView()
        {
            super();
            this.pixelLength = 0;
        }
        
        public function resizeToLength(newLength:Number):void
        {
            
        }
    }
}