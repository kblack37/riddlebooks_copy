package wordproblem.engine.animation;


import dragonbox.common.dispose.IDisposable;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;

class AlternateParenthesisFadeAnimation implements IDisposable
{
    private var m_fadeLeftParenthesisTween : Tween;
    private var m_fadeRightParenthesisTween : Tween;
    
    private var m_fadeDuration : Float = 1.0;
    private var m_leftParenthesis : DisplayObject;
    private var m_leftParenthesisArgs : Array<Dynamic>;
    private var m_rightParenthesis : DisplayObject;
    private var m_rightParenthesisArgs : Array<Dynamic>;
    
    public function new(leftParenthesis : DisplayObject,
            rightParenthesis : DisplayObject)
    {
        
        m_leftParenthesis = leftParenthesis;
        m_fadeLeftParenthesisTween = new Tween(m_leftParenthesis, 0, Transitions.EASE_IN);
        m_leftParenthesisArgs = [m_fadeLeftParenthesisTween];
        
        m_rightParenthesis = rightParenthesis;
        m_fadeRightParenthesisTween = new Tween(m_rightParenthesis, 0, Transitions.EASE_IN);
        m_rightParenthesisArgs = [m_fadeRightParenthesisTween];
    }
    
    public function start() : Void
    {
        reinitializeLeft();
        Starling.juggler.add(m_fadeLeftParenthesisTween);
        
        m_leftParenthesis.alpha = 0.2;
        m_rightParenthesis.alpha = 0.2;
    }
    
    public function stop() : Void
    {
        Starling.juggler.remove(m_fadeLeftParenthesisTween);
        Starling.juggler.remove(m_fadeRightParenthesisTween);
    }
    
    public function dispose() : Void
    {
    }
    
    private function reinitializeLeft() : Void
    {
        // TODO: On repeat relaunch
        m_leftParenthesis.alpha = 0.2;
        m_fadeLeftParenthesisTween.reset(m_leftParenthesis, m_fadeDuration, Transitions.EASE_IN);
        m_fadeLeftParenthesisTween.reverse = true;
        m_fadeLeftParenthesisTween.repeatCount = 2;
        m_fadeLeftParenthesisTween.onRepeat = onRepeat;
        m_fadeLeftParenthesisTween.onRepeatArgs = m_leftParenthesisArgs;
        m_fadeLeftParenthesisTween.onComplete = onComplete;
        m_fadeLeftParenthesisTween.onCompleteArgs = m_leftParenthesisArgs;
        m_fadeLeftParenthesisTween.animate("alpha", 1.0);
    }
    
    private function reinitializeRight() : Void
    {
        m_rightParenthesis.alpha = 0.2;
        m_fadeRightParenthesisTween.reset(m_rightParenthesis, m_fadeDuration, Transitions.EASE_IN);
        m_fadeRightParenthesisTween.reverse = true;
        m_fadeRightParenthesisTween.repeatCount = 2;
        m_fadeRightParenthesisTween.onRepeat = onRepeat;
        m_fadeRightParenthesisTween.onRepeatArgs = m_rightParenthesisArgs;
        m_fadeRightParenthesisTween.onComplete = onComplete;
        m_fadeRightParenthesisTween.onCompleteArgs = m_rightParenthesisArgs;
        m_fadeRightParenthesisTween.animate("alpha", 1.0);
    }
    
    private function onRepeat(tween : Tween) : Void
    {
        if (tween == m_fadeLeftParenthesisTween) 
        {
            reinitializeRight();
            Starling.juggler.add(m_fadeRightParenthesisTween);
        }
        else 
        {
            reinitializeLeft();
            Starling.juggler.add(m_fadeLeftParenthesisTween);
        }
    }
    
    private function onComplete(tween : Tween) : Void
    {
        if (tween == m_fadeLeftParenthesisTween) 
        {
            Starling.juggler.remove(m_fadeLeftParenthesisTween);
        }
        else 
        {
            Starling.juggler.remove(m_fadeRightParenthesisTween);
        }
    }
}
