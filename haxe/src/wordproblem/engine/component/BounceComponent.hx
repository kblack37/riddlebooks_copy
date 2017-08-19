package wordproblem.engine.component;


import motion.Actuate;
import openfl.display.DisplayObject;
import openfl.geom.Point;

import wordproblem.engine.component.Component;


class BounceComponent extends Component
{
    public static inline var TYPE_ID : String = "BounceComponent";
    
    /**
     * Is the bounce animation in progress. If the tween is paused then do not update the
     * tween.
     */
    public var paused : Bool;
	
	/**
	 * The target of the bounce animation; null when the animation is inactive
	 */
	public var target : DisplayObject;
    
    /**
     * The original position of the object that is bouncing before the animation started.
     */
    private var originalPosition : Point;
    
    public function new(entityId : String)
    {
        super(entityId, BounceComponent.TYPE_ID);
    }
    
    override public function dispose() : Void
    {
        // Kill the animation
        if (target != null) 
        {
			Actuate.stop(target);
        }
        
        this.resetToOriginalPosition();
		
		target = null;
    }
    
    public function setOriginalPosition(x : Float, y : Float) : Void
    {
        originalPosition = new Point(x, y);
    }
    
    public function resetToOriginalPosition() : Void
    {
        if (target != null) 
        {
            target.x = originalPosition.x;
            target.y = originalPosition.y;
        }
    }
}
