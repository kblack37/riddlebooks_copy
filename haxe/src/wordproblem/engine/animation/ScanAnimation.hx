package wordproblem.engine.animation;


import flash.display3d.IndexBuffer3D;
import flash.display3d.VertexBuffer3D;

import starling.animation.IAnimatable;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.filters.ScanLineFilter;
import starling.textures.Texture;

/**
 * This animation takes a list of views and animates a colored line scanning over the
 * width of that view.
 * 
 */
class ScanAnimation implements IAnimatable
{
    /**
     * Keep a list of all the views to apply the scan line to
     */
    private var m_views : Array<DisplayObject>;
    
    /**
     * The target color of the scan line.
     * This gets passed to each filter for each view.
     */
    private var m_color : Int;
    
    /**
     * Absolute number of pixels per second the scan line should travel.
     */
    private var m_scanVelocity : Float;
    
    /**
     * The total width of the scan line in absolute pixels.
     */
    private var m_scanWidth : Float;
    
    /**
     * From the set of available scan objects, this is the filter that applies the
     * line to the current display object
     */
    private var m_scanLineFilter : ScanLineFilter;
    
    /**
     * The index of the view that has the scan animation
     */
    private var m_currentViewIndex : Int;
    
    /**
     * Need to keep track of the total width of the textures in order to convert absolute pixel
     * values to uv-like ratios that the filter applies
     * These are always a power of two due to how the starling filters are applied.
     */
    private var m_viewTextureWidths : Array<Float>;
    
    /**
     * List of values between 0.0 and 1.0 indicating the spot
     * in the texture where actual display object ends.
     * 
     * For example if a value is one, it means the texture and object
     * are the exact same width. If 0.5, the object takes up half of the texture.
     */
    private var m_viewTextureEndRatio : Array<Float>;
    
    /**
     * The number of seconds to wait before restarting the scan line.
     */
    private var m_delay : Float;
    
    /**
     * Keep track of the amount of time spent in a current delay. Once this exceeds the delay
     * value we will need to restart
     */
    private var m_delayCounter : Float;
    
    /**
     *
     * @param color
     *      Color of the scan line
     * @param scanVelocity
     *      The number of pixels per second the scanline should move
     * @param scanWidth
     *      The number of pixels wide the scan line should take
     * @param delay
     *      The number of seconds to wait after the line has reached the end of all views before
     *      starting at the beginning.
     */
    public function new(color : Int,
            scanVelocity : Float,
            scanWidth : Float,
            delay : Float)
    {
        super();
        
        m_color = color;
        m_scanVelocity = scanVelocity;
        m_scanWidth = scanWidth;
        m_delay = delay;
        m_delayCounter = 0.0;
        
        m_viewTextureWidths = new Array<Float>();
        m_viewTextureEndRatio = new Array<Float>();
    }
    
    /**
     * Bind a set of display objects to take the scan line animation.
     */
    public function play(views : Array<DisplayObject>) : Void
    {
        m_views = views;
        as3hx.Compat.setArrayLength(m_viewTextureWidths, 0);
        as3hx.Compat.setArrayLength(m_viewTextureEndRatio, 0);
        
        // We have the issue where the texture used in the filter is not the
        // same dimension as the display object
        // Textures always have a width to the power of two
        
        // For the current display object,
        // Need to determine the actual bounds (0.0 to 1.0) that the scan line can go into
        // We expect the texture to have extra space on the right end to chop off
        
        // Assuming the dimensions of the views do not change,
        // we cache the width and the expected width of the texture
        var i : Int;
        var view : DisplayObject;
        for (i in 0...views.length){
            view = views[i];
            
            var actualWidth : Int = Math.ceil(view.width);
            
            var textureWidth : Int = 32;
            while (textureWidth < actualWidth)
            {
                textureWidth = textureWidth << 1;
            }
            m_viewTextureWidths.push(textureWidth);
            
            // Calculate the actual end bound of the texture
            var maxBound : Float = actualWidth / textureWidth;
            m_viewTextureEndRatio.push(maxBound);
        }  // Pick the first view to draw the scanline onto  
        
        
        
        m_currentViewIndex = 0;
        
        // The width of the scan line needs to be converted to a ratio
        // This is based on the width of the texture
        // This will simply give us the difference between the min and max bounds of the filter
        textureWidth = m_viewTextureWidths[m_currentViewIndex];
        var scanWidthRatio : Float = m_scanWidth / textureWidth;
        
        // Apply the filter to the view
        var currentView : DisplayObject = m_views[m_currentViewIndex];
        m_scanLineFilter = new ScanLineFilter(m_color, -1 * scanWidthRatio, 0.0);
        currentView.filter = m_scanLineFilter;
        
        Starling.juggler.add(this);
    }
    
    public function stop() : Void
    {
        Starling.juggler.remove(this);
        
        // Kill the current filter
        if (m_views != null) 
        {
            var currentView : DisplayObject = m_views[m_currentViewIndex];
            currentView.filter = null;
            
            m_scanLineFilter.dispose();
        }
    }
    
    public function advanceTime(time : Float) : Void
    {
        // If delay is active do not change anything
        
        if (m_delayCounter >= m_delay) 
        {
            
            // On each update we need to alter the position of the scan line
            // Based on the timestep, figure out how many pixels to advance the scanline
            var pixelsToProgress : Float = m_scanVelocity * time;
            
            // The pixels difference needs to be converted to the ratio difference in terms
            // of the actual width.
            var currentTextureWidth : Float = m_viewTextureWidths[m_currentViewIndex];
            var ratioToProgress : Float = pixelsToProgress / currentTextureWidth;
            
            // Increment the bounds and clamp them
            var newMinBound : Float = m_scanLineFilter.getMinBound() + ratioToProgress;
            var newMaxBound : Float = m_scanLineFilter.getMaxBound() + ratioToProgress;
            if (newMinBound > m_viewTextureEndRatio[m_currentViewIndex]) 
            {
                var previousView : DisplayObject = m_views[m_currentViewIndex];
                previousView.filter = null;
                
                // Remove the filter from the view and add it to the next one in the list
                m_currentViewIndex++;
                if (m_currentViewIndex >= m_views.length) 
                {
                    m_currentViewIndex = 0;
                    
                    // Might need to activate the delay
                    m_delayCounter = 0.0;
                }
                
                var nextView : DisplayObject = m_views[m_currentViewIndex];
                nextView.filter = m_scanLineFilter;
                
                var textureWidth : Float = m_viewTextureWidths[m_currentViewIndex];
                var scanWidthRatio : Float = m_scanWidth / textureWidth;
                
                newMinBound = -1 * scanWidthRatio;
                newMaxBound = 0.0;
            }  // Update the bounds of the scan line  
            
            
            
            m_scanLineFilter.setMinBound(newMinBound);
            m_scanLineFilter.setMaxBound(newMaxBound);
        }
        else 
        {
            m_delayCounter += time;
        }
    }
}
