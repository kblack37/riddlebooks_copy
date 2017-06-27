package starling.extensions
{
    import starling.display.Image;
    import starling.textures.Texture;
    
    public class ImageTest extends Image
    {
        public function ImageTest(texture:Texture)
        {
            super(texture);
        }
        
        public function changeVertexPosition(index:int, x:Number, y:Number):void
        {
            mVertexData.setPosition(index, x, y);
        }
        
        // Over time, the x and y of a pair of vertices either on the left or right should change
        // The width should decrease in magnitude to zero, the height should increase in magnitude by
        // some small delta.
        public function animate(xDelta:Number, yDelta:Number):void
        {
            const originalX:Number = 0;
            const originalY:Number = 0;
        }
        
        public function modifyVertexPosition():void
        {
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, 100, 0.0);
            mVertexData.setPosition(2, 0.0, 100);
            mVertexData.setPosition(3, 100, 500); 
        }
    }
}