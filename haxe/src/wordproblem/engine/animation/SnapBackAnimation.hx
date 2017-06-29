package wordproblem.engine.animation;


import flash.geom.Point;

import starling.animation.IAnimatable;
import starling.display.DisplayObject;

/**
 * Basic animation to snap a bit of text to a target location
 */
class SnapBackAnimation implements IAnimatable
{
    private var m_deltaX : Float;
    private var m_deltaY : Float;
    private var m_startingPoint : Point;
    private var m_destinationPoint : Point;
    private var m_elapsedTime : Float;
    private var m_duration : Float;
    
    private var m_viewToSnapTo : DisplayObject;
    private var m_viewToMove : DisplayObject;
    private var m_onComplete : Function;
    
    public function new()
    {
        m_startingPoint = new Point();
        m_destinationPoint = new Point();
    }
    
    // Origin point
    private var pointBuffer : Point = new Point(0, 0);
    
    /**
     * 
     * @param velocity
     *      The average number of pixels per second the tween move by
     */
    public function setParameters(viewToMove : DisplayObject,
            viewToSnapTo : DisplayObject,
            velocity : Float,
            onComplete : Function) : Void
    {
        // Normalize both views to global coordinates
        viewToMove.localToGlobal(pointBuffer, m_startingPoint);
        viewToSnapTo.localToGlobal(pointBuffer, m_destinationPoint);
        
        // Reposition if view to move has different registration point
        viewToMove.pivotX = 0;
        viewToMove.pivotY = 0;
        
        // Transfer the view to move to global coordinates
        viewToMove.x = m_startingPoint.x;
        viewToMove.y = m_startingPoint.y;
        viewToMove.stage.addChild(viewToMove);
        
        // Figure out the distance to animate
        m_deltaX = m_destinationPoint.x - m_startingPoint.x;
        m_deltaY = m_destinationPoint.y - m_startingPoint.y;
        
        m_viewToMove = viewToMove;
        m_viewToSnapTo = viewToSnapTo;
        m_duration = Math.sqrt(m_deltaX * m_deltaX + m_deltaY * m_deltaY) / velocity;
        m_onComplete = onComplete;
        m_elapsedTime = 0;
    }
    
    public function dispose() : Void
    {
        if (m_viewToMove != null) 
        {
            m_viewToMove.removeFromParent(true);
        }
    }
    
    public function advanceTime(time : Float) : Void
    {
        m_elapsedTime += time;
        if (m_elapsedTime > m_duration) 
        {
            // clamp elapsed time
            m_elapsedTime = m_duration;
        }
        
        m_viewToMove.x = quarticEaseOut(m_elapsedTime, m_startingPoint.x, m_deltaX, m_duration);
        m_viewToMove.y = quarticEaseOut(m_elapsedTime, m_startingPoint.y, m_deltaY, m_duration);
        
        // Once we reach the target duration we can quit
        if (m_elapsedTime >= m_duration) 
        {
            if (m_onComplete != null) 
            {
                m_onComplete();
            }
        }
    }
    
    private function quarticEaseOut(currentTime : Float, startValue : Float, changeInValue : Float, duration : Float) : Float
    {
        currentTime /= duration;
        currentTime--;
        return -changeInValue * (currentTime * currentTime * currentTime * currentTime - 1) + startValue;
    }
}
