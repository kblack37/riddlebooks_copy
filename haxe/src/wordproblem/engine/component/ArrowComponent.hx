package wordproblem.engine.component;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.math.util.MathUtil;
import openfl.display.DisplayObject;
import wordproblem.engine.component.Component;

import openfl.geom.Point;

/**
 * This component indicates that an enitity should have some arrow drawn pointing to it
 * 
 * Positioning treats the object pointing to as the origin, for example pointing to (0,0) will
 * point directly to the objects origin
 */
class ArrowComponent extends Component
{
    public static inline var TYPE_ID : String = "ArrowComponent";
    
    /**
     * The point anchoring the tail of the arrow
     */
    public var startPoint : Point;
    
    /**
     * The point anchoring the head of the arrow
     */
    public var endPoint : Point;
    public var midPoint : Point;
    public var length : Float;
    public var rotation : Float;
    public var arrowView : DisplayObject;
    
    /**
     * Indicate whether the arrow should animate, the animation would be a basic bobbing
     * movement.
     */
    public var animate : Bool;
    
    /**
     * The previous position of the origin object the arrow is pointing at.
     * null if the arrow view was not created OR the arrow is not pointing at anything.
     */
    public var lastTargetPosition : Point;
    
    public function new(entityId : String,
            startX : Float,
            startY : Float,
            endX : Float,
            endY : Float)
    {
        super(entityId, TYPE_ID);
        
        this.refresh(startX, startY, endX, endY);
    }
    
    override public function dispose() : Void
    {
        if (arrowView != null) 
        {
            if (arrowView.parent != null) arrowView.parent.removeChild(arrowView);
			(try cast(arrowView, IDisposable) catch (e : Dynamic) null).dispose();
        }
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        var startX : Float = data.startX;
        var startY : Float = data.startY;
        var endX : Float = data.endX;
        var endY : Float = data.endY;
        this.refresh(startX, startY, endX, endY);
    }
    
    private function refresh(startX : Float, startY : Float, endX : Float, endY : Float) : Void
    {
        this.startPoint = new Point(startX, startY);
        this.endPoint = new Point(endX, endY);
        this.midPoint = new Point((endX - startX) * 0.5 + startX, (endY - startY) * 0.5 + startY);
        this.animate = true;
        
        var deltaX : Float = endX - startX;
        var deltaY : Float = endY - startY;
        this.length = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        
        this.rotation = MathUtil.radsToDegrees(Math.atan2(deltaY, deltaX));
    }
}
