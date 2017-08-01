package wordproblem.engine.barmodel.view;


import dragonbox.common.dispose.IDisposable;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

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
    private var m_nineSliceImage : Image;
    private var m_threeSliceHorizontalImage : Image;
    private var m_threeSliceVerticalImage : Image;
    private var m_originalImage : Image;
    
    /**
     * The image to use if the segment is supposed to be hidden
     */
    private var m_hiddenImage : DottedRectangle;
    
    public function new(barSegment : BarSegment,
            nineSliceTexture : Texture,
            regularTexture : Texture,
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
		// TODO: these images were replaced from the feathers library and will need
		// to be fixed later
        m_nineSliceImage = new Image(nineSliceTexture);
        m_threeSliceHorizontalImage = new Image(Texture.fromTexture(regularTexture));
        m_threeSliceVerticalImage = new Image(Texture.fromTexture(regularTexture));
        m_originalImage = new Image(regularTexture);
        
        m_hiddenImage = hiddenImage;
    }
    
    public function resize(unitWidth : Float, height : Float) : Void
    {
        this.removeChildren();
        
        var nineSliceTexture : Texture = m_nineSliceImage.texture;
        var targetWidth : Float = unitWidth * data.getValue();
        var minimumWidthForNineSlice : Float = 2 * nineSliceTexture.width;  // Assume padding on left and right are the same  
        var minimumHeightForNineSlice : Float = 2 * nineSliceTexture.height;
        
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
                m_nineSliceImage.color = data.color;
                segmentImage = m_nineSliceImage;
            }
            else if (targetWidth >= minimumWidthForNineSlice && height < minimumHeightForNineSlice) 
            {
                m_threeSliceHorizontalImage.color = data.color;
                segmentImage = m_threeSliceHorizontalImage;
            }
            else if (targetWidth < minimumWidthForNineSlice && height >= minimumHeightForNineSlice) 
            {
                m_threeSliceVerticalImage.color = data.color;
                segmentImage = m_threeSliceVerticalImage;
            }
            else 
            {
                m_originalImage.color = data.color;
                segmentImage = m_originalImage;
            }
            
            segmentImage.width = targetWidth;
            segmentImage.height = height;
        }
        
        addChild(segmentImage);
    }
    
    override public function dispose() : Void
    {
        this.removeChildren();
        
        super.dispose();
    }
}
