package wordproblem.display
{
    import flash.geom.Rectangle;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    /**
     * A special display to draw a rectangle with a dotted border
     * 
     * (used mainly to indicate hit areas for particular parts of the bar modeling ui)
     */
    public class DottedRectangle extends Sprite
    {
        /**
         * Reference to a scalable version of the background
         */
        private var m_backgroundNineSliceImage:Scale9Image;
        
        /**
         * Reference to background texture that has no nine slice
         */
        private var m_backgroundRegularImage:Image;
        
        /**
         * Reference to the texture that represents a corner of the rectangle
         */
        private var m_cornerTexture:Texture;
        
        /**
         * Reference to the texture that represents a segment that will run up and down
         */
        private var m_lineTexture:Texture;
        
        /**
         * How much bigger or smaller the textures for the dotted outline should appear
         * relative to the default
         */
        private var m_dotScaleFactor:Number;
        
        private var m_dottedLineImages:Vector.<Image>;
        
        /**
         *
         * @param backgroundNineSliceTexture
         *      Can be null, in which case no background is drawn
         * @param dotScaleFactor
         *      An extra number to scale up and down the corner and dots (default should be 1.0)
         */
        public function DottedRectangle(backgroundRegularTexture:Texture,
                                        textureScalingGrid:Rectangle,
                                        dotScaleFactor:Number,
                                        cornerTexture:Texture, 
                                        lineTexture:Texture)
        {
            super();

            m_dotScaleFactor = dotScaleFactor;
            m_cornerTexture = cornerTexture;
            m_lineTexture = lineTexture;
            m_dottedLineImages = new Vector.<Image>();
            
            if (backgroundRegularTexture != null)
            {
                m_backgroundRegularImage = new Image(backgroundRegularTexture);
                
                if (textureScalingGrid != null)
                {
                    m_backgroundNineSliceImage = new Scale9Image(new Scale9Textures(backgroundRegularTexture, textureScalingGrid));
                }
            }
        }
        
        public function resize(width:Number, 
                               height:Number, 
                               desiredHorizontalSpacing:Number, 
                               desiredVerticalSpacing:Number):void
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
            }
            
            // Check which background should be used
            if (m_backgroundNineSliceImage != null && 
                m_backgroundNineSliceImage.textures.scale9Grid.left * 2 <= width &&
                m_backgroundNineSliceImage.textures.scale9Grid.top * 2 <= height)
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
            
            var cornerTextureWidth:Number = m_cornerTexture.width * m_dotScaleFactor;
            var cornerTextureHeight:Number = m_cornerTexture.height * m_dotScaleFactor;
            var lineTextureWidth:Number = m_lineTexture.width * m_dotScaleFactor;
            var lineTextureHeight:Number = m_lineTexture.height * m_dotScaleFactor;
            
            // Figure out how many dots can be drawn can be drawn both vertically and horizontally
            var horizontalSpaceForSegment:Number = width - (2 * cornerTextureWidth);
            var horizontalSegmentsAllowed:int = Math.floor((horizontalSpaceForSegment - desiredHorizontalSpacing) / (lineTextureWidth + desiredHorizontalSpacing));
            
            var verticalSpaceForSegment:Number = height - (2 * cornerTextureHeight);
            var verticalSegmentsAllowed:int = Math.floor((verticalSpaceForSegment - desiredVerticalSpacing) / (lineTextureWidth + desiredVerticalSpacing));
            
            // Our current implementation tries to evenly space all the segments within a line, so the desired spacing might need to change to
            // accomadate this
            var newHorizontalSpacing:Number = (horizontalSpaceForSegment - (horizontalSegmentsAllowed * lineTextureWidth)) / (horizontalSegmentsAllowed + 1.0);
            var newVerticalSpacing:Number = (verticalSpaceForSegment - (verticalSegmentsAllowed * lineTextureWidth)) / (verticalSegmentsAllowed + 1.0);
            
            // Draw out the background contained within the outline
            var topLeftCorner:Image = new Image(m_cornerTexture);
            topLeftCorner.scaleX = topLeftCorner.scaleY = m_dotScaleFactor;
            
            // Top right is reflection
            var topRightCorner:Image = new Image(m_cornerTexture);
            topRightCorner.scaleX = -1 * m_dotScaleFactor;
            topRightCorner.scaleY = m_dotScaleFactor;
            topRightCorner.pivotX = cornerTextureWidth;
            topRightCorner.x = width - cornerTextureWidth * m_dotScaleFactor;
            
            var bottomLeftCorner:Image = new Image(m_cornerTexture);
            bottomLeftCorner.scaleX = bottomLeftCorner.scaleY = m_dotScaleFactor;
            bottomLeftCorner.pivotX = cornerTextureWidth;
            bottomLeftCorner.rotation = Math.PI * -0.5;
            bottomLeftCorner.y = height - cornerTextureHeight * m_dotScaleFactor;
            
            var bottomRightCorner:Image = new Image(m_cornerTexture);
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
            m_dottedLineImages.push(topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner);
            
            var i:int;
            var xOffset:Number = cornerTextureWidth + newHorizontalSpacing;
            var yTop:Number = 0;
            var yBottom:Number = height - lineTextureHeight;
            for (i = 0; i < horizontalSegmentsAllowed; i++)
            {
                var topHorizontalSegment:Image = new Image(m_lineTexture);
                topHorizontalSegment.scaleX = topHorizontalSegment.scaleY = m_dotScaleFactor;
                topHorizontalSegment.x = xOffset;
                addChild(topHorizontalSegment);
                
                var bottomHorizontalSegment:Image = new Image(m_lineTexture);
                bottomHorizontalSegment.scaleX = bottomHorizontalSegment.scaleY = m_dotScaleFactor;
                bottomHorizontalSegment.x = xOffset;
                bottomHorizontalSegment.y = yBottom;
                addChild(bottomHorizontalSegment);
                
                xOffset += newHorizontalSpacing + lineTextureWidth;
                
                m_dottedLineImages.push(topHorizontalSegment, bottomHorizontalSegment);
            }
            
            // ??? When scale factor is less than one the space between the vertical segments does not have the right starting offset
            var yOffset:Number = cornerTextureHeight + newVerticalSpacing;
            var xRight:Number = width - lineTextureHeight;
            for (i = 0; i < verticalSegmentsAllowed; i++)
            {
                var leftVerticalSegment:Image = new Image(m_lineTexture);
                leftVerticalSegment.scaleX = leftVerticalSegment.scaleY = m_dotScaleFactor;
                leftVerticalSegment.pivotX = lineTextureWidth;
                leftVerticalSegment.rotation = Math.PI * -0.5;
                leftVerticalSegment.y = yOffset;
                addChild(leftVerticalSegment);
                
                var rightVerticalSegment:Image = new Image(m_lineTexture);
                rightVerticalSegment.scaleX = rightVerticalSegment.scaleY = m_dotScaleFactor;
                rightVerticalSegment.pivotX = lineTextureWidth;
                rightVerticalSegment.rotation = Math.PI * -0.5;
                rightVerticalSegment.y = yOffset;
                rightVerticalSegment.x = xRight;
                addChild(rightVerticalSegment);
                
                yOffset += newVerticalSpacing + lineTextureWidth;
                
                m_dottedLineImages.push(leftVerticalSegment, rightVerticalSegment);
            }
        }
        
        override public function dispose():void
        {
            super.dispose();
        }
    }
}