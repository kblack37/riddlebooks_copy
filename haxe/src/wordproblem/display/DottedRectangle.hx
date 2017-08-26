package wordproblem.display;


import dragonbox.common.dispose.IDisposable;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.geom.Rectangle;

import openfl.display.Sprite;

/**
 * A special display to draw a rectangle with a dotted border
 * 
 * (used mainly to indicate hit areas for particular parts of the bar modeling ui)
 */
class DottedRectangle extends DisposableSprite
{
    /**
     * Reference to a scalable version of the background
     */
    private var m_backgroundNineSliceImage : Scale9Image;
    
    /**
     * Reference to background texture that has no nine slice
     */
    private var m_backgroundRegularImage : Bitmap;
    
    /**
     * Reference to the texture that represents a corner of the rectangle
     */
    private var m_cornerBitmapData : BitmapData;
    
    /**
     * Reference to the texture that represents a segment that will run up and down
     */
    private var m_lineBitmapData : BitmapData;
    
    /**
     * How much bigger or smaller the textures for the dotted outline should appear
     * relative to the default
     */
    private var m_dotScaleFactor : Float;
    
    private var m_dottedLineImages : Array<DisplayObject>;
    
    /**
     *
     * @param backgroundNineSliceTexture
     *      Can be null, in which case no background is drawn
     * @param dotScaleFactor
     *      An extra number to scale up and down the corner and dots (default should be 1.0)
     */
    public function new(backgroundRegularBitmapData : BitmapData,
            BitmapScalingGrid : Rectangle,
            dotScaleFactor : Float,
            cornerBitmapData : BitmapData,
            lineBitmapData : BitmapData)
    {
        super();
        
        m_dotScaleFactor = dotScaleFactor;
        m_cornerBitmapData = cornerBitmapData;
        m_lineBitmapData = lineBitmapData;
        m_dottedLineImages = new Array<DisplayObject>();
        
        if (backgroundRegularBitmapData != null) 
        {
            m_backgroundRegularImage = new Bitmap(backgroundRegularBitmapData);
            
            if (BitmapScalingGrid != null) 
            {
                m_backgroundNineSliceImage = new Scale9Image(backgroundRegularBitmapData, BitmapScalingGrid);
            }
        }
    }
    
    public function resize(width : Float,
            height : Float,
            desiredHorizontalSpacing : Float,
            desiredVerticalSpacing : Float) : Void
    {
        // Delete all previous graphics
        while (m_dottedLineImages.length > 0)
        {
			var imageToRemove = m_dottedLineImages.pop();
            if (imageToRemove.parent != null) imageToRemove.parent.removeChild(imageToRemove);
        }
        
        if (m_backgroundNineSliceImage != null) 
        {
			if (m_backgroundNineSliceImage.parent != null) m_backgroundNineSliceImage.parent.removeChild(m_backgroundNineSliceImage);
        }
        
        if (m_backgroundRegularImage != null) 
        {
			if (m_backgroundRegularImage.parent != null) m_backgroundRegularImage.parent.removeChild(m_backgroundRegularImage);
        }  
		
		// Check which background should be used
		var scale9Rect = m_backgroundNineSliceImage.getScale9Rect();
        if (m_backgroundNineSliceImage != null &&
			scale9Rect.width * 2 <= width && 
			scale9Rect.height * 2 <= height)
        {
            m_backgroundNineSliceImage.width = width;
            m_backgroundNineSliceImage.height = height;
            addChild(m_backgroundNineSliceImage);
        }
        else if (m_backgroundRegularImage != null) 
        {
            m_backgroundRegularImage.width = width;
            m_backgroundRegularImage.height = height;
            addChild(m_backgroundRegularImage);
        }
        
        var cornerTextureWidth : Float = m_cornerBitmapData.width * m_dotScaleFactor;
        var cornerTextureHeight : Float = m_cornerBitmapData.height * m_dotScaleFactor;
        var lineTextureWidth : Float = m_lineBitmapData.width * m_dotScaleFactor;
        var lineTextureHeight : Float = m_lineBitmapData.height * m_dotScaleFactor;
        
        // Figure out how many dots can be drawn can be drawn both vertically and horizontally
        var horizontalSpaceForSegment : Float = width - (2 * cornerTextureWidth);
        var horizontalSegmentsAllowed : Int = Math.floor((horizontalSpaceForSegment - desiredHorizontalSpacing) / (lineTextureWidth + desiredHorizontalSpacing));
        
        var verticalSpaceForSegment : Float = height - (2 * cornerTextureHeight);
        var verticalSegmentsAllowed : Int = Math.floor((verticalSpaceForSegment - desiredVerticalSpacing) / (lineTextureWidth + desiredVerticalSpacing));
        
        // Our current implementation tries to evenly space all the segments within a line, so the desired spacing might need to change to
        // accomadate this
        var newHorizontalSpacing : Float = (horizontalSpaceForSegment - (horizontalSegmentsAllowed * lineTextureWidth)) / (horizontalSegmentsAllowed + 1.0);
        var newVerticalSpacing : Float = (verticalSpaceForSegment - (verticalSegmentsAllowed * lineTextureWidth)) / (verticalSegmentsAllowed + 1.0);
        
        // Draw out the background contained within the outline
        var topLeftCorner : Bitmap = new Bitmap(m_cornerBitmapData);
        topLeftCorner.scaleX = topLeftCorner.scaleY = m_dotScaleFactor;
        
        // Top right is reflection
        var topRightCorner : PivotSprite = new PivotSprite();
		topRightCorner.addChild(new Bitmap(m_cornerBitmapData));
        topRightCorner.scaleX = -1 * m_dotScaleFactor;
        topRightCorner.scaleY = m_dotScaleFactor;
        topRightCorner.pivotX = cornerTextureWidth;
        topRightCorner.x = width - cornerTextureWidth * m_dotScaleFactor;
        
        var bottomLeftCorner : PivotSprite = new PivotSprite();
		bottomLeftCorner.addChild(new Bitmap(m_cornerBitmapData));
        bottomLeftCorner.scaleX = bottomLeftCorner.scaleY = m_dotScaleFactor;
        bottomLeftCorner.pivotX = cornerTextureWidth;
        bottomLeftCorner.rotation = -90;
        bottomLeftCorner.y = height - cornerTextureHeight * m_dotScaleFactor;
        
        var bottomRightCorner : PivotSprite = new PivotSprite();
		bottomRightCorner.addChild(new Bitmap(m_cornerBitmapData));
        bottomRightCorner.scaleX = bottomRightCorner.scaleY = m_dotScaleFactor;
        bottomRightCorner.pivotX = cornerTextureWidth;
        bottomRightCorner.pivotY = cornerTextureHeight;
        bottomRightCorner.rotation = 180;
        bottomRightCorner.x = topRightCorner.x;
        bottomRightCorner.y = bottomLeftCorner.y;
        
        addChild(topLeftCorner);
        addChild(topRightCorner);
        addChild(bottomLeftCorner);
        addChild(bottomRightCorner);
        m_dottedLineImages.push(topLeftCorner);
        m_dottedLineImages.push(topRightCorner);
        m_dottedLineImages.push(bottomLeftCorner);
        m_dottedLineImages.push(bottomRightCorner);
        
        
        var i : Int = 0;
        var xOffset : Float = cornerTextureWidth + newHorizontalSpacing;
        var yTop : Float = 0;
        var yBottom : Float = height - lineTextureHeight;
        for (i in 0...horizontalSegmentsAllowed){
            var topHorizontalSegment : Bitmap = new Bitmap(m_lineBitmapData);
            topHorizontalSegment.scaleX = topHorizontalSegment.scaleY = m_dotScaleFactor;
            topHorizontalSegment.x = xOffset;
            addChild(topHorizontalSegment);
            
            var bottomHorizontalSegment : Bitmap = new Bitmap(m_lineBitmapData);
            bottomHorizontalSegment.scaleX = bottomHorizontalSegment.scaleY = m_dotScaleFactor;
            bottomHorizontalSegment.x = xOffset;
            bottomHorizontalSegment.y = yBottom;
            addChild(bottomHorizontalSegment);
            
            xOffset += newHorizontalSpacing + lineTextureWidth;
            
            m_dottedLineImages.push(topHorizontalSegment);
            m_dottedLineImages.push(bottomHorizontalSegment);
            
        } 
		
		// ??? When scale factor is less than one the space between the vertical segments does not have the right starting offset  
        var yOffset : Float = cornerTextureHeight + newVerticalSpacing;
        var xRight : Float = width - lineTextureHeight;
        for (i in 0...verticalSegmentsAllowed){
            var leftVerticalSegment : PivotSprite = new PivotSprite();
			leftVerticalSegment.addChild(new Bitmap(m_lineBitmapData));
            leftVerticalSegment.scaleX = leftVerticalSegment.scaleY = m_dotScaleFactor;
            leftVerticalSegment.pivotX = lineTextureWidth;
            leftVerticalSegment.rotation = -90;
            leftVerticalSegment.y = yOffset;
            addChild(leftVerticalSegment);
            
            var rightVerticalSegment : PivotSprite = new PivotSprite();
			rightVerticalSegment.addChild(new Bitmap(m_lineBitmapData));
            rightVerticalSegment.scaleX = rightVerticalSegment.scaleY = m_dotScaleFactor;
            rightVerticalSegment.pivotX = lineTextureWidth;
            rightVerticalSegment.rotation = -90;
            rightVerticalSegment.y = yOffset;
            rightVerticalSegment.x = xRight;
            addChild(rightVerticalSegment);
            
            yOffset += newVerticalSpacing + lineTextureWidth;
            
            m_dottedLineImages.push(leftVerticalSegment);
            m_dottedLineImages.push(rightVerticalSegment);
            
        }
    }
	
	override public function dispose() {
		m_backgroundNineSliceImage.dispose();
		
		while (m_dottedLineImages.length > 0) {
			var image = m_dottedLineImages.pop();
			image.parent.removeChild(image);
		}
	}
}
