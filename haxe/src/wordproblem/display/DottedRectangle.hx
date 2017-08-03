package wordproblem.display;


import flash.geom.Rectangle;

import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

/**
 * A special display to draw a rectangle with a dotted border
 * 
 * (used mainly to indicate hit areas for particular parts of the bar modeling ui)
 */
class DottedRectangle extends Sprite
{
    /**
     * Reference to a scalable version of the background
     */
	// TODO: this was a Scale9Image from the feathers library and will
	// probably have to be fixed
    private var m_backgroundNineSliceImage : Image;
    
    /**
     * Reference to background texture that has no nine slice
     */
    private var m_backgroundRegularImage : Image;
    
    /**
     * Reference to the texture that represents a corner of the rectangle
     */
    private var m_cornerTexture : Texture;
    
    /**
     * Reference to the texture that represents a segment that will run up and down
     */
    private var m_lineTexture : Texture;
    
    /**
     * How much bigger or smaller the textures for the dotted outline should appear
     * relative to the default
     */
    private var m_dotScaleFactor : Float;
    
    private var m_dottedLineImages : Array<Image>;
    
    /**
     *
     * @param backgroundNineSliceTexture
     *      Can be null, in which case no background is drawn
     * @param dotScaleFactor
     *      An extra number to scale up and down the corner and dots (default should be 1.0)
     */
    public function new(backgroundRegularTexture : Texture,
            textureScalingGrid : Rectangle,
            dotScaleFactor : Float,
            cornerTexture : Texture,
            lineTexture : Texture)
    {
        super();
        
        m_dotScaleFactor = dotScaleFactor;
        m_cornerTexture = cornerTexture;
        m_lineTexture = lineTexture;
        m_dottedLineImages = new Array<Image>();
        
        if (backgroundRegularTexture != null) 
        {
            m_backgroundRegularImage = new Image(backgroundRegularTexture);
            
            if (textureScalingGrid != null) 
            {
                m_backgroundNineSliceImage = new Image(Texture.fromTexture(backgroundRegularTexture, textureScalingGrid));
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
            m_dottedLineImages.pop().removeFromParent(true);
        }
        
        if (m_backgroundNineSliceImage != null) 
        {
            m_backgroundNineSliceImage.removeFromParent();
        }
        
        if (m_backgroundRegularImage != null) 
        {
            m_backgroundRegularImage.removeFromParent();
        }  // Check which background should be used  
        
        
        
        if (m_backgroundNineSliceImage != null &&
			// TODO: this conversion from a Scale9Image to a starling image
			// is probably not correct and will need to be fixed
			m_backgroundNineSliceImage.texture.width * 2 <= width &&
			m_backgroundNineSliceImage.texture.height * 2 <= height)
            //m_backgroundNineSliceImage.textures.scale9Grid.left * 2 <= width &&
            //m_backgroundNineSliceImage.textures.scale9Grid.top * 2 <= height) 
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
        
        var cornerTextureWidth : Float = m_cornerTexture.width * m_dotScaleFactor;
        var cornerTextureHeight : Float = m_cornerTexture.height * m_dotScaleFactor;
        var lineTextureWidth : Float = m_lineTexture.width * m_dotScaleFactor;
        var lineTextureHeight : Float = m_lineTexture.height * m_dotScaleFactor;
        
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
        var topLeftCorner : Image = new Image(m_cornerTexture);
        topLeftCorner.scaleX = topLeftCorner.scaleY = m_dotScaleFactor;
        
        // Top right is reflection
        var topRightCorner : Image = new Image(m_cornerTexture);
        topRightCorner.scaleX = -1 * m_dotScaleFactor;
        topRightCorner.scaleY = m_dotScaleFactor;
        topRightCorner.pivotX = cornerTextureWidth;
        topRightCorner.x = width - cornerTextureWidth * m_dotScaleFactor;
        
        var bottomLeftCorner : Image = new Image(m_cornerTexture);
        bottomLeftCorner.scaleX = bottomLeftCorner.scaleY = m_dotScaleFactor;
        bottomLeftCorner.pivotX = cornerTextureWidth;
        bottomLeftCorner.rotation = Math.PI * -0.5;
        bottomLeftCorner.y = height - cornerTextureHeight * m_dotScaleFactor;
        
        var bottomRightCorner : Image = new Image(m_cornerTexture);
        bottomRightCorner.scaleX = bottomRightCorner.scaleY = m_dotScaleFactor;
        bottomRightCorner.pivotX = cornerTextureWidth;
        bottomRightCorner.pivotY = cornerTextureHeight;
        bottomRightCorner.rotation = Math.PI;
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
            var topHorizontalSegment : Image = new Image(m_lineTexture);
            topHorizontalSegment.scaleX = topHorizontalSegment.scaleY = m_dotScaleFactor;
            topHorizontalSegment.x = xOffset;
            addChild(topHorizontalSegment);
            
            var bottomHorizontalSegment : Image = new Image(m_lineTexture);
            bottomHorizontalSegment.scaleX = bottomHorizontalSegment.scaleY = m_dotScaleFactor;
            bottomHorizontalSegment.x = xOffset;
            bottomHorizontalSegment.y = yBottom;
            addChild(bottomHorizontalSegment);
            
            xOffset += newHorizontalSpacing + lineTextureWidth;
            
            m_dottedLineImages.push(topHorizontalSegment);
            m_dottedLineImages.push(bottomHorizontalSegment);
            
        }  // ??? When scale factor is less than one the space between the vertical segments does not have the right starting offset  
        
        
        
        var yOffset : Float = cornerTextureHeight + newVerticalSpacing;
        var xRight : Float = width - lineTextureHeight;
        for (i in 0...verticalSegmentsAllowed){
            var leftVerticalSegment : Image = new Image(m_lineTexture);
            leftVerticalSegment.scaleX = leftVerticalSegment.scaleY = m_dotScaleFactor;
            leftVerticalSegment.pivotX = lineTextureWidth;
            leftVerticalSegment.rotation = Math.PI * -0.5;
            leftVerticalSegment.y = yOffset;
            addChild(leftVerticalSegment);
            
            var rightVerticalSegment : Image = new Image(m_lineTexture);
            rightVerticalSegment.scaleX = rightVerticalSegment.scaleY = m_dotScaleFactor;
            rightVerticalSegment.pivotX = lineTextureWidth;
            rightVerticalSegment.rotation = Math.PI * -0.5;
            rightVerticalSegment.y = yOffset;
            rightVerticalSegment.x = xRight;
            addChild(rightVerticalSegment);
            
            yOffset += newVerticalSpacing + lineTextureWidth;
            
            m_dottedLineImages.push(leftVerticalSegment);
            m_dottedLineImages.push(rightVerticalSegment);
            
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
    }
}
