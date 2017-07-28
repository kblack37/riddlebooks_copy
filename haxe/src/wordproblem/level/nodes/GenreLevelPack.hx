package wordproblem.level.nodes;

import wordproblem.level.nodes.WordProblemLevelPack;

import cgs.cache.ICgsUserCache;
import cgs.levelProgression.ICgsLevelManager;
import cgs.levelProgression.util.ICgsLevelFactory;
import cgs.levelProgression.util.ICgsLockFactory;

/**
 * This level pack will group together word problems that all have the same primary genre.
 * It's main usage is for rendering the level selection screen properly, it is one of the layers
 * of the categorization of a level.
 * 
 * For example we will have one for fantasy and another for sci-fi.
 * Each genre will need to link to additional information like graphical themes, flavor text, and a
 * list of related books.
 */
class GenreLevelPack extends WordProblemLevelPack
{
    public static inline var NODE_TYPE : String = "GenreLevelPack";
    
    public function new(levelManager : ICgsLevelManager, cache : ICgsUserCache, levelFactory : ICgsLevelFactory, lockFactory : ICgsLockFactory, nodeLabel : Int)
    {
        super(levelManager, cache, levelFactory, lockFactory, nodeLabel);
    }
    
    /**
     * The theme id links to a key in the asset manager that is a parsed json object
     * containing specifics about the theme.
     * 
     * Look at the README in assets/genres for more data
     */
    public function getThemeId() : String
    {
        return super.nodeName;
    }
}
