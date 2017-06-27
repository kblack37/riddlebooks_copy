package wordproblem.engine.component
{
    public class MouseInteractableComponent extends Component
    {
        public static const TYPE_ID:String = "MouseInteractableComponent";
        
        public var selected:Boolean;
        
        /**
         * Is the player's mouse pressed down on the entity for this
         * frame.
         */
        public var selectedThisFrame:Boolean;
        
        /**
         * Is the player dragging around this entity at a current frame.
         */
        public var draggedThisFrame:Boolean;
        
        public function MouseInteractableComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
    }
}