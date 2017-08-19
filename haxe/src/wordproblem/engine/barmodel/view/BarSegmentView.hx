package wordproblem.engine.barmodel.view;


import dragonbox.common.dispose.IDisposable;
import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

import openfl.display.DisplayObject;
import openfl.display.Sprite;

import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.component.RigidBodyComponent;
import wordproblem.display.DottedRectangle;

/**
 * The most basic unit for drawing a segment
 */
class BarSegmentView extends Sprite implements IDisposable
{
    public var data : BarSegment;
    
    /**
     * The bounds of the view relative to the bar area widget
     */
    public var rigidBody : RigidBodyComponent;
    
	// TODO: these were scaled image classes from the feathers library and
	// will probably have to be fixed
    private var m_nineSliceImage : Bitmap;
    private var m_threeSliceHorizontalImage : Bitmap;
    private var m_threeSliceVerticalImage : Bitmap;
    private var m_originalImage : Bitmap;
    
    /**
     * The image to use if the segment is supposed to be hidden
     */
    private var m_hiddenImage : DottedRectangle;
    
    public function new(barSegment : BarSegment,
            segmentBitmapData : BitmapData,
            hiddenImage : DottedRectangle)
    {
        super();
        
        this.data = barSegment;
        this.rigidBody = new RigidBodyComponent(barSegment.id);
        
        // Create the image for the segment
        // To make scaling of the segment look sharp we use nine slice
        // However this fails if one of the dimensions is LESS than the padding we start the slice from
        // (i.e. if non-scaling parts exceeds the desired width)
        // In this instance we need to fall back to drawing the unsliced image
        m_nineSliceImage = new Bitmap(segmentBitmapData);
		var nineSlicePadding : Float = 8;
		var nineSliceGrid : Rectangle = new Rectangle(
			nineSlicePadding, 
			nineSlicePadding, 
			segmentBitmapData.width - 2 * nineSlicePadding, 
			segmentBitmapData.height - 2 * nineSlicePadding
		);
		m_nineSliceImage.scale9Grid = nineSliceGrid;
		
        m_threeSliceHorizontalImage = new Bitmap(segmentBitmapData);
		m_threeSliceHorizontalImage.scale9Grid = new Rectangle(
			nineSliceGrid.left,
			0,
			nineSliceGrid.right,
			segmentBitmapData.height
		);
		
        m_threeSliceVerticalImage = new Bitmap(segmentBitmapData);
		m_threeSliceVerticalImage.scale9Grid = new Rectangle(
			0,
			nineSliceGrid.top,
			segmentBitmapData.width,
			nineSliceGrid.bottom
		);
		
        m_originalImage = new Bitmap(segmentBitmapData);
        
        m_hiddenImage = hiddenImage;
    }
    
    public function resize(unitWidth : Float, height : Float) : Void
    {
        this.removeChildren();
        
        var targetWidth : Float = unitWidth * data.getValue();
        var minimumWidthForNineSlice : Float = 2 * m_nineSliceImage.width;  // Assume padding on left and right are the same  
        var minimumHeightForNineSlice : Float = 2 * m_nineSliceImage.height;
        
        // HACK: To avoid having invisible segments we push up the width of a segment to one even
        // if it causes things to lose proportionality
        if (targetWidth < 3) 
        {
            targetWidth = 3;
        }
		
		// If segment height less than slice padding, should also not scale vertically.  		
		// However should scale horizontally with 3-slice
        var segmentImage : DisplayObject = null;
        if (data.hiddenValue != null) 
        {
            m_hiddenImage.resize(targetWidth, height, 12, 2);
            segmentImage = m_hiddenImage;
        }
        else 
        {
            if (targetWidth >= minimumWidthForNineSlice && height >= minimumHeightForNineSlice) 
            {
				m_nineSliceImage.transform.colorTransform.concat(XColor.rgbToColorTransform(data.color));
                segmentImage = m_nineSliceImage;
            }
            else if (targetWidth >= minimumWidthForNineSlice && height < minimumHeightForNineSlice) 
            {
				m_threeSliceHorizontalImage.transform.colorTransform.concat(XColor.rgbToColorTransform(data.color));
                segmentImage = m_threeSliceHorizontalImage;
            }
            else if (targetWidth < minimumWidthForNineSlice && height >= minimumHeightForNineSlice) 
            {
				m_threeSliceVerticalImage.transform.colorTransform.concat(XColor.rgbToColorTransform(data.color));
                segmentImage = m_threeSliceVerticalImage;
            }
            else 
            {
				m_originalImage.transform.colorTransform.concat(XColor.rgbToColorTransform(data.color));
                segmentImage = m_originalImage;
            }
            
            segmentImage.width = targetWidth;
            segmentImage.height = height;
        }
        
        addChild(segmentImage);
    }
    
    public function dispose() : Void
    {
        this.removeChildren();
    }
}
