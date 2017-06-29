package wordproblem.engine.component;


class MouseInteractableComponent extends Component
{
    public static inline var TYPE_ID : String = "MouseInteractableComponent";
    
    public var selected : Bool;
    
    /**
     * Is the player's mouse pressed down on the entity for this
     * frame.
     */
    public var selectedThisFrame : Bool;
    
    /**
     * Is the player dragging around this entity at a current frame.
     */
    public var draggedThisFrame : Bool;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
    }
}
