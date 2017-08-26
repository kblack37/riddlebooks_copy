package wordproblem.engine.animation;


import motion.Actuate;
import motion.actuators.GenericActuator;
import motion.easing.Quart;
import openfl.geom.Point;
import openfl.display.DisplayObject;
import wordproblem.display.DisposableSprite;
import wordproblem.display.PivotSprite;

import haxe.Constraints.Function;

/**
 * Basic animation to snap a bit of text to a target location
 */
class SnapBackAnimation
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
        m_startingPoint = viewToMove.localToGlobal(pointBuffer);
        m_destinationPoint = viewToSnapTo.localToGlobal(pointBuffer);
        
        // Reposition if view to move has different registration point
		if (Std.is(viewToMove, PivotSprite)) {
			var castedView : PivotSprite = try cast(viewToMove, PivotSprite) catch (e : Dynamic) null;
			castedView.pivotX = 0;
			castedView.pivotY = 0;
		}
        
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
	
	public function start() : Void {
		var actuator = Actuate.tween(m_viewToMove, m_duration, { x: m_destinationPoint.x, y: m_destinationPoint.y }).ease(Quart.easeOut);
		if (m_onComplete != null) {
			actuator.onComplete(m_onComplete);
		}
	}
	
	public function stop() : Void {
		Actuate.stop(m_viewToMove);
	}
    
    public function dispose() : Void
    {
		Actuate.stop(m_viewToMove);
        if (m_viewToMove != null) 
        {
			m_viewToMove.parent.removeChild(m_viewToMove);
			if (Std.is(m_viewToMove, DisposableSprite)) {
				(try cast(m_viewToMove, DisposableSprite) catch (e : Dynamic) null).dispose();
			}
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
