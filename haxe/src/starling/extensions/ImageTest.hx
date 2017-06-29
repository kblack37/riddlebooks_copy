package starling.extensions;


import starling.display.Image;
import starling.textures.Texture;

class ImageTest extends Image
{
    public function new(texture : Texture)
    {
        super(texture);
    }
    
    public function changeVertexPosition(index : Int, x : Float, y : Float) : Void
    {
        mVertexData.setPosition(index, x, y);
    }
    
    // Over time, the x and y of a pair of vertices either on the left or right should change
    // The width should decrease in magnitude to zero, the height should increase in magnitude by
    // some small delta.
    public function animate(xDelta : Float, yDelta : Float) : Void
    {
        var originalX : Float = 0;
        var originalY : Float = 0;
    }
    
    public function modifyVertexPosition() : Void
    {
        mVertexData.setPosition(0, 0.0, 0.0);
        mVertexData.setPosition(1, 100, 0.0);
        mVertexData.setPosition(2, 0.0, 100);
        mVertexData.setPosition(3, 100, 500);
    }
}
