package wordproblem.engine.component;

import cgs.levelProgression.nodes.ICgsLevelLeaf;
import cgs.levelProgression.nodes.ICgsLevelNode;

/**
 * This level indicates that an entity is attached to a single particular level in the game
 * 
 * This used used to say that a reward item can be earned by completing an exact level.
 * The level can be specified via a unique name OR a unique position, like the level 3-1 in Fantasy.
 */
class LevelComponent extends Component
{
    public static inline var TYPE_ID : String = "LevelComponent";
    
    /**
     * The unique name of the level the entity is bound to.
     * 
     * Null if this is not the id that should be used
     */
    public var levelName : String;
    
    /**
     * Zero-based index of where this level should go in its parent node
     */
    public var levelIndex : Int;
    
    /**
     * Zero-based index of the chapter of where this level should go
     * -1 if not part of a chapter
     */
    public var chapterIndex : Int;
    
    /**
     * Theme id of the genre it should belong to, null if not part of a genre.
     */
    public var genre : String;
    
    /**
     * This is not deserialized from any json file.
     * 
     * Instead some part of the application will use the other information to identify this node.
     * This assumes that level nodes are never destroyed during a run through
     */
    public var levelNode : ICgsLevelNode;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        if (data.exists("levelName")) 
        {
            this.levelName = data.levelName;
        }
        else 
        {
            this.levelIndex = data.levelIndex;
            this.chapterIndex = data.chapterIndex;
            this.genre = data.genre;
        }
    }
}
