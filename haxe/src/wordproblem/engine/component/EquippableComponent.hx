package wordproblem.engine.component;


/**
 * The presence of this component indicates that an associated entity is an equippable
 * mouse cursor
 * 
 * (Used for the customizable pointers the player can purchase
 */
class EquippableComponent extends Component
{
    public static inline var TYPE_ID : String = "EquippableComponent";
    
    // Equippable objects can further be categorized
    public static inline var MOUSE : String = "mouse";
    public static inline var BUTTON_COLOR : String = "button_color";
    
    public var isEquipped : Bool;
    
    public var equippableType : String;
    
    public function new(entityId : String)
    {
        super(entityId, EquippableComponent.TYPE_ID);
        
        this.isEquipped = false;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.equippableType = data.equippableType;
    }
}
