package wordproblem.engine.animation;


import dragonbox.common.dispose.IDisposable;

import starling.animation.IAnimatable;
import starling.animation.Tween;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.textures.Texture;

/**
 * This animation plays
 */
class RingPulseAnimation implements IAnimatable implements IDisposable
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
    
    private var m_activeTweens : Array<Tween>;
    
    private var m_ringTexture : Texture;
    
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
    
    public function new(ringTexture : Texture, onComplete : Function)
    {
        m_ringTexture = ringTexture;
        m_activeTweens = new Array<Tween>();
        m_onComplete = onComplete;
        m_numCompletedTweens = 0;
    }
    
    public function dispose() : Void
    {
        // Clear all textures that are active
        for (activeTween in m_activeTweens)
        {
            (try cast(activeTween.target, Image) catch(e:Dynamic) null).removeFromParent(true);
        }
    }
    
    public function advanceTime(time : Float) : Void
    {
        var i : Int;
        var numTweens : Int = m_activeTweens.length;
        for (i in 0...numTweens){
            m_activeTweens[i].advanceTime(time);
        }
    }
    
    public function reset(xPosition : Float, yPosition : Float, displayContainer : DisplayObjectContainer, color : Int) : Void
    {
        // Interrupt currently playing tweens
        var i : Int;
        var numTweens : Int = m_activeTweens.length;
        for (i in 0...numTweens){
            (try cast(m_activeTweens[i].target, Image) catch(e:Dynamic) null).removeFromParent(true);
        }
        as3hx.Compat.setArrayLength(m_activeTweens, 0);
        
        // Each individual ring should start out minimized and then expand outwards while fading
        m_displayContainer = displayContainer;
        m_numCompletedTweens = 0;
        var endScaleFactor : Float = m_maxRingRadius / (m_ringTexture.width * 0.5);
        
        // The number of tweens to create is determined by the number that can be active at any given
        // time.
        var numSimultaneousActiveRings : Int = Math.ceil(m_singleRingDuration / m_frequency);
        for (i in 0...numSimultaneousActiveRings){
            var ringImage : Image = new Image(m_ringTexture);
            ringImage.pivotX = m_ringTexture.width * 0.5;
            ringImage.pivotY = m_ringTexture.height * 0.5;
            ringImage.scaleX = ringImage.scaleY = 0.0;
            ringImage.x = xPosition;
            ringImage.y = yPosition;
            ringImage.color = color;
            
            var ringExpandTween : Tween = new Tween(ringImage, m_singleRingDuration);
            ringExpandTween.delay = i * m_frequency;
            ringExpandTween.animate("scaleX", endScaleFactor);
            ringExpandTween.animate("scaleY", endScaleFactor);
            ringExpandTween.animate("alpha", 0.1);
            ringExpandTween.repeatCount = 1;
            ringExpandTween.onComplete = onTweenComplete;
            ringExpandTween.onCompleteArgs = [ringExpandTween];
            m_activeTweens.push(ringExpandTween);
            
            displayContainer.addChild(ringImage);
        }
        
        m_totalTweensToPlay = m_activeTweens.length;
    }
    
    private function onTweenComplete(tween : Tween) : Void
    {
        m_displayContainer.removeChild(try cast(tween.target, Image) catch(e:Dynamic) null);
        m_activeTweens.splice(Lambda.indexOf(m_activeTweens, tween), 1);
        
        m_numCompletedTweens++;
        if (m_numCompletedTweens >= m_totalTweensToPlay) 
        {
            as3hx.Compat.setArrayLength(m_activeTweens, 0);
            m_onComplete();
        }
    }
}
