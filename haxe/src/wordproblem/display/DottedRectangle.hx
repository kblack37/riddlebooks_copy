package wordproblem.display;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Tile;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.geom.Rectangle;


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
	
	private var m_corners : Array<DisplayObject>;
    
	/**
	 * Using the OpenFL solution to batching to improve performance
	 */
    private var m_tilemap : Tilemap;
	private var m_tileset : Tileset;
    
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
		m_corners = new Array<DisplayObject>();
		m_tileset = new Tileset(m_lineBitmapData, [ new Rectangle(0, 0, m_lineBitmapData.width, m_lineBitmapData.height) ]);
        
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
		while (m_corners.length > 0) {
			this.removeChild(m_corners.pop());
		}
		
		if (m_tilemap != null) {
			this.removeChild(m_tilemap);
			m_tilemap.removeTiles();
		}
		m_tilemap = new Tilemap(Std.int(width), Std.int(height), m_tileset);
        
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
		var topRightCorner : Bitmap = new Bitmap(m_cornerBitmapData);
        topRightCorner.scaleX = topRightCorner.scaleY = m_dotScaleFactor;
		topRightCorner.rotation = 90;
		topRightCorner.x = width;
        
		var bottomLeftCorner : Bitmap = new Bitmap(m_cornerBitmapData);
        bottomLeftCorner.scaleX = bottomLeftCorner.scaleY = m_dotScaleFactor;
		bottomLeftCorner.rotation = -90;
		bottomLeftCorner.y = height;
        
		var bottomRightCorner : Bitmap = new Bitmap(m_cornerBitmapData);
        bottomRightCorner.scaleX = bottomRightCorner.scaleY = m_dotScaleFactor;
		bottomRightCorner.rotation = 180;
		bottomRightCorner.x = topRightCorner.x;
		bottomRightCorner.y = bottomLeftCorner.y;
        
        addChild(topLeftCorner);
        addChild(topRightCorner);
        addChild(bottomLeftCorner);
        addChild(bottomRightCorner);
		m_corners.push(topLeftCorner);
		m_corners.push(topRightCorner);
		m_corners.push(bottomLeftCorner);
		m_corners.push(bottomRightCorner);
        
        var i : Int = 0;
        var xOffset : Float = cornerTextureWidth + newHorizontalSpacing;
        var yBottom : Float = height - lineTextureHeight;
        for (i in 0...horizontalSegmentsAllowed){
			var topHorizontalSegment : Tile = new Tile(0, xOffset, 0, m_dotScaleFactor, m_dotScaleFactor);
			m_tilemap.addTile(topHorizontalSegment);
            
			var bottomHorizontalSegment : Tile = new Tile(0, xOffset, yBottom, m_dotScaleFactor, m_dotScaleFactor);
			m_tilemap.addTile(bottomHorizontalSegment);
            
            xOffset += newHorizontalSpacing + lineTextureWidth;
        }
		
		// ??? When scale factor is less than one the space between the vertical segments does not have the right starting offset  
        var yOffset : Float = cornerTextureHeight + newVerticalSpacing;
        var xRight : Float = width - lineTextureHeight;
        for (i in 0...verticalSegmentsAllowed){
			var leftVerticalSegment : Tile = new Tile(0, lineTextureHeight, yOffset, m_dotScaleFactor, m_dotScaleFactor, 90);
			m_tilemap.addTile(leftVerticalSegment);
            
			var rightVerticalSegment : Tile = new Tile(0, xRight + lineTextureHeight, yOffset, m_dotScaleFactor, m_dotScaleFactor, 90);
			m_tilemap.addTile(rightVerticalSegment);
            
            yOffset += newVerticalSpacing + lineTextureWidth;
        }
		
		this.addChild(m_tilemap);
    }
	
	override public function dispose() {
		super.dispose();
		
		if (m_tilemap != null) m_tilemap.removeTiles();
	}
}
