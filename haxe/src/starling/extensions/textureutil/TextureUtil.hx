package starling.extensions.textureutil;


import flash.display.BitmapData;
import flash.display.Shape;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.RenderTexture;
import starling.textures.Texture;

class TextureUtil
{
    public function new()
    {
    }
    
    // These buffers are to prevent the creation of too many helper objects
    // and to store original values of the view passed in
    private static var m_pointBuffer : Point = new Point();
    private static var m_rectangleBuffer : Rectangle = new Rectangle();
    
    /**
     * Important: the image returned is using a custom rendered texture. These need to be disposed of when they are
     * no longer used.
     */
    public static function getImageFromDisplayObject(displayObject : DisplayObject, scaleFactor : Float = 1.0) : Image
    {
        // In order to safely extract the text without potentially screwing up the view
        // we first want to save the original layout information
        m_pointBuffer.x = displayObject.x;
        m_pointBuffer.y = displayObject.y;
        
        // Its possible that visible portions of the view flow into negative coordinates,
        // in which case they would be cut off when drawn.
        // By getting the object bounds in terms of itself we can find how
        displayObject.getBounds(displayObject, m_rectangleBuffer);
        var tx : Float = -1 * m_rectangleBuffer.left;
        var ty : Float = -1 * m_rectangleBuffer.top;
        
        // Shift the view over to a (0, 0) registration so the next copying step becomes easier
        displayObject.x = 0;
        displayObject.y = 0;
        
        // Draw a copy of the dragged view
        var renderTexture : RenderTexture = new RenderTexture(Std.int(displayObject.width * scaleFactor), Std.int(displayObject.height * scaleFactor), false);
        var matrix : Matrix = new Matrix(scaleFactor, 0, 0, scaleFactor, tx, ty);
        renderTexture.draw(displayObject, matrix);
        var viewCopy : Image = new Image(renderTexture);
        
        // Restore the modified view data after the draw is finished
        displayObject.x = m_pointBuffer.x;
        displayObject.y = m_pointBuffer.y;
        
        return viewCopy;
    }
    
    /**
     * Get back a segment of a ring as a texture that can be displayed by the starling framework
     * 
     * @param startAngleRad
     *      angle of the starting 'arm'
     * @param radToFill
     *      amount from the start arm to fill
     * @param clockwise
     *      true if the fill should go clockwise
     * @param bitmapFillData
     *      If null, fill color is used
     */
    public static function getRingSegmentTexture(innerRadius : Float,
            outerRadius : Float,
            startAngleRad : Float,
            radToFill : Float,
            clockwise : Bool,
            bitmapFillData : BitmapData = null,
            fillColor : Int = 0x00FF00,
            useOutline : Bool = false,
            outlineThickness : Float = 1,
            outlineColor : Int = 0x000000) : Texture
    {
        var shape : Shape = new Shape();
        
        if (useOutline) 
        {
            shape.graphics.lineStyle(outlineThickness, outlineColor);
        }
        
        var diameter : Float = outerRadius * 2;
        if (bitmapFillData != null) 
        {
            var bitmapWidth : Float = bitmapFillData.width;
            var bitmapHeight : Float = bitmapFillData.height;
            shape.graphics.beginBitmapFill(bitmapFillData,
                    new Matrix(diameter / bitmapWidth, 0, 0, diameter / bitmapHeight, -outerRadius, -outerRadius),
                    false
                    );
        }
        else 
        {
            shape.graphics.beginFill(fillColor);
        }
        
        var numSteps : Int = 150;
        var radPerStep : Float = Math.PI * 2 / numSteps;
        // Counters to determine how much of the circle is drawn independent
        // of actual starting position
        var amountFilled : Float = 0.0;
        var currentRad : Float = startAngleRad;
        var innerCoordinates : Array<Float> = new Array<Float>();
        var outCoordinates : Array<Float> = new Array<Float>();
        while (amountFilled <= radToFill)
        {
            var cos : Float = Math.cos(currentRad);
            var sin : Float = Math.sin(currentRad);
            
            var innerX : Float = innerRadius * cos;
            var innerY : Float = innerRadius * sin;
            innerCoordinates.push(innerX);
            innerCoordinates.push(innerY);
            
            
            var outerX : Float = outerRadius * cos;
            var outerY : Float = outerRadius * sin;
            outCoordinates.push(outerX);
            outCoordinates.push(outerY);
            
            if (clockwise) 
            {
                currentRad += radPerStep;
            }
            else 
            {
                currentRad -= radPerStep;
            }
            amountFilled += radPerStep;
        }  
		
		// Make sure no missing space at the end  
        var cos = Math.cos(startAngleRad + radToFill);
        var sin = Math.sin(startAngleRad + radToFill);
        innerCoordinates.push(innerRadius * cos);
        innerCoordinates.push(innerRadius * sin);
        
        outCoordinates.push(outerRadius * cos);
        outCoordinates.push(outerRadius * sin);
        
        
        var i : Int = 0;
        var numCoordinates : Int = innerCoordinates.length;
        shape.graphics.moveTo(innerCoordinates[0], innerCoordinates[1]);
        for (i in 0...numCoordinates){
            var innerX = innerCoordinates[i];
            var innerY = innerCoordinates[i + 1];
            shape.graphics.lineTo(innerX, innerY);
        } 
		
		// Outer loop, goes backwards  
        for (i in numCoordinates - 1...0){
            var outerX = outCoordinates[i - 1];
            var outerY = outCoordinates[i];
            shape.graphics.lineTo(outerX, outerY);
        }  
		
		// Close at start of inner  
        shape.graphics.lineTo(innerCoordinates[0], innerCoordinates[1]);
        
        // If an outline is used it added to the size
        if (useOutline) 
        {
            diameter += outlineThickness;
        }
        
        var bitmapData : BitmapData = new BitmapData(Std.int(diameter), Std.int(diameter), true, 0x00000000);
        bitmapData.draw(shape, new Matrix(1, 0, 0, 1, outerRadius, outerRadius));
        var texture : Texture = Texture.fromBitmapData(bitmapData, false);
        bitmapData.dispose();
        return texture;
    }
}
