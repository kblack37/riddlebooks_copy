package wordproblem.display;


import starling.display.DisplayObject;
import starling.display.Sprite;

/**
 * A layer represents a special display object container that help fields to keep
 * track of whether layers underneath it are to be blocked by mouse events.
 * 
 * This is useful if we choose to do custom click detection using rectangle hit tests.
 */
class Layer extends Sprite
{
    /**
     * Flag that is toggled to indicate whether the components contained in this
     * layer can accept mouse events.
     * 
     * We expect this to be false if there is a layer on top of it that has some part
     * blocking it (i.e. a layer above intercepts the mouse messages)
     */
    public var activeForFrame : Bool = true;
    
    public function new()
    {
        super();
    }
    
    /**
     * A utility function to check whether the given display object is part of a
     * layer or is a layer that is marked an inactive for an update frame.
     * 
     * @return
     *      true if the object is in an inactive frame. Normally this means that we ignore further
     *      processing of mouse events on that object since it is blocked by a top layer
     */
    public static function getDisplayObjectIsInInactiveLayer(displayObject : DisplayObject) : Bool
    {
        // Starting at the given object, keep going up the the display tree
        // until we reach the first layer containing the object
        var isInactive : Bool = false;
        var targetDisplay : DisplayObject = displayObject;
        while (targetDisplay != null)
        {
            if (Std.is(targetDisplay, Layer)) 
            {
                if (!(try cast(targetDisplay, Layer) catch(e:Dynamic) null).activeForFrame) 
                {
                    isInactive = true;
                }
                break;
            }
            
            targetDisplay = targetDisplay.parent;
        }
        
        return isInactive;
    }
}
