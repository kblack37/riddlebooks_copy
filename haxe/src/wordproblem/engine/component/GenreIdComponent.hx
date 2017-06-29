package wordproblem.engine.component;


/**
 * Indicate that an entity is bound to one particular word problem genre.
 * 
 * It's usage is to make it clear where a reward item should be placed in the level selection screen
 */
class GenreIdComponent extends Component
{
    public static inline var TYPE_ID : String = "GenreIdComponent";
    
    /**
     * The genre id is the same string that is used to tag GenreLevelPacks within the level
     * management system.
     */
    public var genreId : String;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.genreId = data.genreId;
    }
}
