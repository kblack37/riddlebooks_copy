package wordproblem.engine.animation;


import dragonbox.common.util.XColor;

import feathers.display.Scale9Image;

import starling.animation.IAnimatable;
import starling.display.DisplayObject;
import starling.events.Event;
import starling.events.EventDispatcher;

/**
 * Animation smoothly interpolates the color of a given image from a start to an end value.
 */
class ColorChangeAnimation extends EventDispatcher implements IAnimatable
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
        if (Std.is(m_image, Scale9Image)) 
        {
            (try cast(m_image, Scale9Image) catch(e:Dynamic) null).color = startColor;
        }
    }
    
    public function advanceTime(time : Float) : Void
    {
        m_elapsedTime += time;
        var resultColor : Int = XColor.interpolateColors(m_endColor, m_startColor, m_elapsedTime / m_duration);
        if (Std.is(m_image, Scale9Image)) 
        {
            (try cast(m_image, Scale9Image) catch(e:Dynamic) null).color = resultColor;
        }
        
        if (m_elapsedTime > m_duration) 
        {
            (try cast(m_image, Scale9Image) catch(e:Dynamic) null).color = m_endColor;
            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
        }
    }
}