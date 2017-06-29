package wordproblem.engine.component;


/**
 * Attach this component to any entity that can smoothly move from one position to the next within a grid-like
 * construct. For example this works for characters within a world with a top-down view and there is limited
 * freedom in the directions of movement.
 * 
 * A system can also use this to do movement in any direction, it just ignores the property whether to move
 * in x or y direction first.
 */
class MoveableComponent extends Component
{
    public static inline var TYPE_ID : String = "MoveableComponent";
    
    /**
     * The final goal x for the target
     */
    public var targetX : Float;
    
    /**
     * The final goal y for the target
     */
    public var targetY : Float;
    
    /**
     * The pixel per second velocity at which this thing should move at
     * 
     * If zero or less should do the move instantaneously
     */
    public var velocityPixelPerSecond : Float;
    
    /**
     * A bit hacky, keep track of the number of pixels the entity has moved
     * since the animation cycle was last altered. This is so the image switches
     * during movement attempt to smoothly coincide with the actual position changes
     */
    public var pixelsMovedSinceAnimationCycle : Float;
    
    /**
     * If true entity should attempt to cover the x distance first, otherwise
     * it will cover the y distance first
     */
    public var moveHorizontallyFirst : Bool;
    
    /**
     * Extra flag read and written by the movement system to check whether
     * the movement of this entity is active in the current snapshot.
     */
    public var isActive : Bool;
    
    /**
     * Extra flag read and written by free transform system that indicates whether
     * a tween was already created for a request to move.
     */
    public var requestHandled : Bool;
    
    /**
     * The motion component will define any data related how the movement of
     * an entity should be changed.
     */
    public function new(entityId : String)
    {
        this.setDestinationAndVelocity(0, 0, 0);
        this.isActive = false;
        
        super(entityId, TYPE_ID);
    }
    
    /**
     * Convience function to move this entity to a new 2d location with a certain speed.
     * 
     * @param x
     *      x coordinate of the entity relative to whatever frame its display was added to
     * @param y
     *      y coordinate of the entity relative to whatever frame its display was added to
     * @param velocity
     *      The speed in pixels to move the entity, negative means go to the x,y instantly
     * @param moveHorizontallyFirst
     *      If the entity moves in two directions, should it try to cover te horizontal distance first
     */
    public function setDestinationAndVelocity(x : Float, y : Float, velocity : Float, moveHorizontallyFirst : Bool = true) : Void
    {
        this.targetX = x;
        this.targetY = y;
        this.pixelsMovedSinceAnimationCycle = 0.0;
        this.velocityPixelPerSecond = velocity;
        this.isActive = true;
        this.moveHorizontallyFirst = moveHorizontallyFirst;
        
        this.requestHandled = false;
    }
}
