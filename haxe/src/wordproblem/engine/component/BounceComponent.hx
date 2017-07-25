package wordproblem.engine.component;

import wordproblem.engine.component.Component;

import flash.geom.Point;

import starling.animation.Tween;
import starling.core.Starling;

class BounceComponent extends Component
{
    public static inline var TYPE_ID : String = "BounceComponent";
    
    /**
     * Is the bounce animation in progress. If the tween is paused then do not update the
     * tween.
     */
    public var paused : Bool;
    
    /**
     * The tween that will apply the changes the target display object
     */
    public var tween : Tween;
    
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
        if (tween != null && Starling.current.juggler.contains(tween)) 
        {
            Starling.current.juggler.remove(tween);
        }
        
        this.resetToOriginalPosition();
    }
    
    public function setOriginalPosition(x : Float, y : Float) : Void
    {
        originalPosition = new Point(x, y);
    }
    
    public function resetToOriginalPosition() : Void
    {
        if (tween != null) 
        {
            tween.target.x = originalPosition.x;
            tween.target.y = originalPosition.y;
        }
    }
}
