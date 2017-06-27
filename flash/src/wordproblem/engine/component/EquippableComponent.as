package wordproblem.engine.component
{
    /**
     * The presence of this component indicates that an associated entity is an equippable
     * mouse cursor
     * 
     * (Used for the customizable pointers the player can purchase
     */
    public class EquippableComponent extends Component
    {
        public static const TYPE_ID:String = "EquippableComponent";
        
        // Equippable objects can further be categorized
        public static const MOUSE:String = "mouse";
        public static const BUTTON_COLOR:String = "button_color";
        
        public var isEquipped:Boolean;
        
        public var equippableType:String;
        
        public function EquippableComponent(entityId:String)
        {
            super(entityId, EquippableComponent.TYPE_ID);
            
            this.isEquipped = false;
        }
        
        override public function deserialize(data:Object):void
        {
            this.equippableType = data.equippableType;
        }
    }
}