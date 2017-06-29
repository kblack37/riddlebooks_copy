package wordproblem.engine.component;

import wordproblem.engine.component.Component;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;

/**
 * When attached to an entity, signal that we should play a simple animation that tweens
 * the transparency/color to create a blink effect.
 */
class BlinkComponent extends Component
{
    public static inline var TYPE_ID : String = "BlinkComponent";
    
    /**
     * DO NOT SET THIS MANUALLY, this is set up by the blink system
     */
    public var tween : Tween;
    
    /**
     * The number of seconds it should take for component to go from fully opaque
     * to the target minimum transparency level.
     */
    public var duration : Float;
    
    /**
     * The minimum alpha threshold the blink should stop at
     */
    public var minAlpha : Float;
    
    public function new(entityId : String, duration : Float = 0.5, minAlpha : Float = 0.2)
    {
        super(entityId, TYPE_ID);
        
        this.duration = duration;
        this.minAlpha = minAlpha;
    }
    
    override public function dispose() : Void
    {
        if (this.tween != null) 
        {
            // HACK: Assume the tween is always added to the root juggler
            Starling.juggler.remove(this.tween);
            
            // Restore prior alpha value
            (try cast(this.tween.target, DisplayObject) catch(e:Dynamic) null).alpha = 1.0;
            this.tween = null;
        }
    }
}
