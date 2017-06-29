package wordproblem.engine.component;


import starling.display.DisplayObject;

import wordproblem.engine.animation.LinkToAnimation;

/**
 * Component is used to link an entity to it a secondary dragged object.
 * 
 * The secondard object will link to the main renderer for the entity
 */
class LinkToDraggedObjectComponent extends Component
{
    public static inline var TYPE_ID : String = "LinkToDraggedObjectComponent";
    
    /**
     * Some distinguishing property on the dragged object to indicate it is in fact
     * the one that should be linked to a given entity.
     * 
     * For example it can be the expression string or another entity id
     */
    public var draggedObjectId : String;
    
    /**
     * Reference to the display object
     */
    public var draggedObjectDisplay : DisplayObject;
    
    /**
     * Get whether the animation for this link is playing already
     */
    public var animationPlaying : Bool;
    
    /**
     * Reference to the display object representing this entity. The dragged object
     * should link to this object.
     */
    public var targetObjectDisplay : DisplayObject;
    
    /**
     * The amount to shift the x anchor point on the target display object
     */
    public var xOffset : Float;
    
    /**
     * The amount to shift the y anchor point on the target display object
     */
    public var yOffset : Float;
    
    /**
     * Need to keep a reference to the animation that is playing. This disposal of this component needs to immediately
     * trigger the disposal of the connected animation
     */
    public var animation : LinkToAnimation;
    
    public function new(entityId : String,
            draggedObjectId : String,
            xOffset : Float,
            yOffset : Float)
    {
        super(entityId, TYPE_ID);
        
        this.refresh(draggedObjectId, xOffset, yOffset);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        if (this.animation != null) 
        {
            this.animation.stop();
        }
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        var draggedObjectId : String = data.draggedObjectId;
        var xOffset : Float = data.xOffset;
        var yOffset : Float = data.yOffset;
        this.refresh(draggedObjectId, xOffset, yOffset);
    }
    
    private function refresh(draggedObjectId : String, xOffset : Float, yOffset : Float) : Void
    {
        this.draggedObjectId = draggedObjectId;
        this.animationPlaying = false;
        this.targetObjectDisplay = null;
        this.xOffset = xOffset;
        this.yOffset = yOffset;
        this.animation = null;
    }
}
