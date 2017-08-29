package wordproblem.engine.animation;

import haxe.Timer;
import motion.Actuate;
import dragonbox.common.util.XColor;
import openfl.display.Bitmap;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.events.EventDispatcher;

/**
 * Animation smoothly interpolates the color of a given image from a start to an end value.
 */
class ColorChangeAnimation
{
	private static inline var TIMER_INTERVAL_MS : Float = 16;
	
    private var m_image : DisplayObject;
    private var m_startColor : Int;
    private var m_endColor : Int;
    private var m_elapsedTime : Float;
    private var m_duration : Float;
	private var m_timer : Timer;
    
    public function new()
    {
		
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
        m_image.transform.colorTransform = XColor.rgbToColorTransform(startColor);
		
		m_timer = new Timer(Std.int(TIMER_INTERVAL_MS));
		m_timer.run = advanceTime;
    }
    
    private function advanceTime() : Void
    {
        m_elapsedTime += TIMER_INTERVAL_MS / 1000.0;
        var resultColor : Int = XColor.interpolateColors(m_endColor, m_startColor, m_elapsedTime / m_duration);
        m_image.transform.colorTransform = XColor.rgbToColorTransform(resultColor);
        
        if (m_elapsedTime > m_duration) 
        {
            m_image.transform.colorTransform = XColor.rgbToColorTransform(m_endColor);
			m_timer.stop();
		}
    }
}
