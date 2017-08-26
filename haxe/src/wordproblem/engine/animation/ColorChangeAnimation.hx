package wordproblem.engine.animation;


import dragonbox.common.util.XColor;
import openfl.display.Bitmap;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.events.EventDispatcher;

/**
 * Animation smoothly interpolates the color of a given image from a start to an end value.
 */
class ColorChangeAnimation extends EventDispatcher
{
    private var m_image : DisplayObject;
    private var m_startColor : Int;
    private var m_endColor : Int;
    private var m_elapsedTime : Float;
    private var m_duration : Float;
    
    public function new()
    {
        super();
    }
    
    public function play(startColor : Int,
            endColor : Int,
            durationSeconds : Float,
            image : DisplayObject) : Void
    {
        m_startColor = startColor;
        m_endColor = endColor;
        m_elapsedTime = 0;
        m_duration = durationSeconds;
        m_image = image;
        
        // Make the object the starting color
        if (Std.is(m_image, Bitmap)) 
        {
            (try cast(m_image, Bitmap) catch(e:Dynamic) null).transform.colorTransform = XColor.rgbToColorTransform(startColor);
        }
    }
    
    public function advanceTime(time : Float) : Void
    {
        m_elapsedTime += time;
        var resultColor : Int = XColor.interpolateColors(m_endColor, m_startColor, m_elapsedTime / m_duration);
        if (Std.is(m_image, Bitmap)) 
        {
            (try cast(m_image, Bitmap) catch(e:Dynamic) null).transform.colorTransform = XColor.rgbToColorTransform(resultColor);
        }
        
        if (m_elapsedTime > m_duration) 
        {
            (try cast(m_image, Bitmap) catch(e:Dynamic) null).transform.colorTransform = XColor.rgbToColorTransform(m_endColor);
        }
    }
}
