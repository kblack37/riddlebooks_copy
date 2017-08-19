package wordproblem.engine.component;


import openfl.display.DisplayObject;

/**
 * Indicates that an entity should be rendered on screen.
 * Component should not subclass any display type object so the reference to
 * the view is done through composition.
 * 
 * Serves as the parent class for render components that require more data about
 * how to render to be stored
 */
class RenderableComponent extends Component
{
    public static inline var TYPE_ID : String = "RenderableComponent";
    
    /**
     * The number is used as a special indicator for how the item should be drawn.
     * For example in the item in the shelves we treat this value as an index into a
     * collection of textures representing different states of the item.
     * 
     * (Note that since this is a stateful property that varies for different instances of
     * an item it needs to be saved)
     */
    public var renderStatus : Int;
    
    /**
     * The container for graphics
     */
    public var view : DisplayObject;
    
    public var isVisible : Bool = true;
    
    public function new(entityId : String, typeId : String = TYPE_ID)
    {
        super(entityId, typeId);
        
        this.renderStatus = 0;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        if (data.exists("isVisible")) 
        {
            this.isVisible = data.isVisible;
        }
    }
}
