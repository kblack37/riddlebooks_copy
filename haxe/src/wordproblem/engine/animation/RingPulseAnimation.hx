package wordproblem.engine.animation;


import dragonbox.common.dispose.IDisposable;
import dragonbox.common.util.XColor;
import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import wordproblem.display.PivotSprite;

import haxe.Constraints.Function;

import openfl.display.DisplayObjectContainer;

/**
 * This animation plays
 */
class RingPulseAnimation implements IDisposable
{
    /**
     * Maximum radius that a ring can be
     */
    private var m_maxRingRadius : Float = 32;
    
    /**
     * The number of seconds it should take for a single ring to go
     * through it's animation cycle
     */
    private var m_singleRingDuration : Float = 0.75;
    
    /**
     * The number of seconds that pass before a new ring is generated
     */
    private var m_frequency : Float = 1;
    
    /**
     * The container where the rings should be added
     */
    private var m_displayContainer : DisplayObjectContainer;
    
    private var m_activeObjects : Array<DisplayObject>;
    
    private var m_ringBitmapData : BitmapData;
    
    /**
     * Trigger when the animation has completed
     */
    private var m_onComplete : Function;
    
    private var m_totalTweensToPlay : Int;
    
    /**
     * Keep track of tweens finished during a play through, should reset to zero when
     * a new one is started.
     */
    private var m_numCompletedTweens : Int;
    
    public function new(ringBitmapData : BitmapData, onComplete : Function)
    {
        m_ringBitmapData = ringBitmapData;
        m_activeObjects = new Array<DisplayObject>();
        m_onComplete = onComplete;
        m_numCompletedTweens = 0;
    }
    
    public function dispose() : Void
    {
        // Clear all textures that are active
        for (activeObject in m_activeObjects)
        {
			Actuate.stop(activeObject);
			var castedObject = try cast(activeObject, PivotSprite) catch (e : Dynamic) null;
            if (castedObject.parent != null) castedObject.parent.removeChild(castedObject);
			castedObject.dispose();
        }
    }
    
    public function reset(xPosition : Float, yPosition : Float, displayContainer : DisplayObjectContainer, color : Int) : Void
    {
        // Interrupt currently playing tweens
        for (activeObject in m_activeObjects){
            var castedObject = try cast(activeObject, PivotSprite) catch (e : Dynamic) null;
            if (castedObject.parent != null) castedObject.parent.removeChild(castedObject);
			castedObject.dispose();
        }
		m_activeObjects = new Array<DisplayObject>();
        
        // Each individual ring should start out minimized and then expand outwards while fading
        m_displayContainer = displayContainer;
        m_numCompletedTweens = 0;
        var endScaleFactor : Float = m_maxRingRadius / (m_ringBitmapData.width * 0.5);
        
        // The number of tweens to create is determined by the number that can be active at any given
        // time.
        var numSimultaneousActiveRings : Int = Math.ceil(m_singleRingDuration / m_frequency);
        for (i in 0...numSimultaneousActiveRings){
            var ringImage : PivotSprite = new PivotSprite();
			ringImage.addChild(new Bitmap(m_ringBitmapData));
            ringImage.pivotX = m_ringBitmapData.width * 0.5;
            ringImage.pivotY = m_ringBitmapData.height * 0.5;
            ringImage.scaleX = ringImage.scaleY = 0.0;
            ringImage.x = xPosition;
            ringImage.y = yPosition;
			ringImage.transform.colorTransform = XColor.rgbToColorTransform(color);
			
			Actuate.tween(ringImage, m_singleRingDuration, { scaleX: endScaleFactor, scaleY: endScaleFactor, alpha: 0.1 }).delay(i * m_frequency).repeat(1).onComplete(onTweenComplete);
            m_activeObjects.push(ringImage);
            displayContainer.addChild(ringImage);
        }
        
        m_totalTweensToPlay = m_activeObjects.length;
    }
	
	public function stop() {
		for (activeObject in m_activeObjects) {
			Actuate.stop(activeObject);
			
			if (activeObject.parent != null) activeObject.parent.removeChild(activeObject);
		}
		
		m_activeObjects = new Array<DisplayObject>();
	}
    
    private function onTweenComplete() : Void
    {
		m_displayContainer.removeChild(m_activeObjects.shift());
        
        m_numCompletedTweens++;
        if (m_numCompletedTweens >= m_totalTweensToPlay) 
        {
			m_activeObjects = new Array<DisplayObject>();
            m_onComplete();
        }
    }
}
