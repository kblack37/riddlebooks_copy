package wordproblem.engine.animation;


import com.gskinner.motion.GTween;
import com.gskinner.motion.easing.Back;

import starling.animation.IAnimatable;
import starling.display.DisplayObjectContainer;

/**
 * The animation to be played when a term has been filled to the point of bursting
 */
class SquashStretchAnimation implements IAnimatable
{
    private static inline var DELAY_FRAME_THRESHOLD : Int = 120;
    
    private var m_itemToAlter : DisplayObjectContainer;
    
    private var m_squashTween : GTween;
    private var m_stretchTween : GTween;
    private var m_returnToNormalTween : GTween;
    
    private var m_tweenSequencePlaying : Bool;
    
    /**
     * Once the counter 
     */
    private var m_restartDelayAnimationCounter : Int;
    
    private var m_originalScaleX : Float;
    private var m_originalScaleY : Float;
    
    public function new(object : DisplayObjectContainer)
    {
        // Expect the graphics inside of the object to be centered around origin.
        m_itemToAlter = object;
        m_originalScaleX = object.scaleX;
        m_originalScaleY = object.scaleY;
    }
    
    public function play(finishCallback : Function) : Void
    {
        var scaleShiftAmount : Float = 0.3;
        var squashDuration : Float = 0.5;
        var squashTween : GTween = new GTween(
        m_itemToAlter, 
        squashDuration, 
        {
            scaleX : m_originalScaleX + scaleShiftAmount,
            scaleY : m_originalScaleY - scaleShiftAmount,

        }, 
        {
            ease : Back.easeIn,
            onComplete : onSquashComplete,

        });
        //squashTween.paused = true;
        m_squashTween = squashTween;
        
        var stretchDuration : Float = 0.5;
        var stretchTween : GTween = new GTween(
        m_itemToAlter, 
        stretchDuration, 
        {
            scaleY : m_originalScaleY + scaleShiftAmount,
            scaleX : m_originalScaleX - scaleShiftAmount,

        }, 
        {
            ease : Back.easeIn,
            onComplete : onStretchComplete,

        });
        stretchTween.paused = true;
        m_stretchTween = stretchTween;
        
        var returnToNormalTween : GTween = new GTween(
        m_itemToAlter, 
        squashDuration, 
        {
            scaleX : m_originalScaleX,
            scaleY : m_originalScaleY,

        }, 
        {
            onComplete : onSequenceComplete

        }, 
        );
        returnToNormalTween.paused = true;
        m_returnToNormalTween = returnToNormalTween;
        
        m_tweenSequencePlaying = true;
    }
    
    public function advanceTime(time : Float) : Void
    {
        if (!m_tweenSequencePlaying) 
        {
            m_restartDelayAnimationCounter++;
            if (m_restartDelayAnimationCounter >= DELAY_FRAME_THRESHOLD) 
            {
                m_squashTween.beginning();
                m_squashTween.paused = false;
                m_tweenSequencePlaying = true;
                m_restartDelayAnimationCounter = 0;
            }
        }
    }
    
    public function dispose() : Void
    {
        m_squashTween.paused = true;
        m_stretchTween.paused = true;
        m_returnToNormalTween.paused = true;
    }
    
    private function onSquashComplete(tween : GTween) : Void
    {
        m_stretchTween.beginning();
        m_stretchTween.paused = false;
    }
    
    private function onStretchComplete(tween : GTween) : Void
    {
        m_returnToNormalTween.beginning();
        m_returnToNormalTween.paused = false;
    }
    
    private function onSequenceComplete(tween : GTween) : Void
    {
        m_tweenSequencePlaying = false;
    }
}
