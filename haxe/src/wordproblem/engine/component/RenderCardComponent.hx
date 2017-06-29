package wordproblem.engine.component;


/**
 * When attached to an entity, it signifies we should render the object like we 
 * would a symbol on a card.
 * 
 * We can also do things like bind dummy symbols to values which are never used by other
 * terms in the game. The texture information then becomes available to use for other
 * items however.
 */
class RenderCardComponent extends RenderableComponent
{
    public static inline var TYPE_ID : String = "RenderCardComponent";
    
    /**
     * This should match up with a symbol that was bound as part of the term
     * expressions. This allows us to implicitly map into several different
     * images.
     */
    public var symbolName : String;
    
    public function new(entityId : String,
            symbolName : String)
    {
        super(entityId, TYPE_ID);
        
        this.symbolName = symbolName;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.symbolName = data.symbolName;
    }
}
