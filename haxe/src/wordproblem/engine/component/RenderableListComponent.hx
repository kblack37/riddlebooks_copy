package wordproblem.engine.component;


import openfl.display.DisplayObject;

/**
 * Used if an entity might have several views attached to it.
 * 
 * One example usage of this is the term areas, which contain several cards possibly bound to
 * a single data value. (In this case the entity id is the data)
 */
class RenderableListComponent extends Component
{
    public static inline var TYPE_ID : String = "RenderableListComponent";
    
    /**
     * List of display objects for the enitity, can be null
     */
    public var views : Array<DisplayObject>;
    
    public function new(entityId : String, views : Array<DisplayObject>)
    {
        super(entityId, TYPE_ID);
        
        this.views = views;
    }
}
