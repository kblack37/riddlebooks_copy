package wordproblem.level.nodes;

import wordproblem.level.nodes.WordProblemLevelPack;

import cgs.cache.ICgsUserCache;
import cgs.levelProgression.ICgsLevelManager;
import cgs.levelProgression.nodes.ICgsLevelNode;
import cgs.levelProgression.util.ICgsLevelFactory;
import cgs.levelProgression.util.ICgsLockFactory;

/**
 * Similar to the GenreLevelPack, the ChapterLevelPack is a way to categorize levels.
 * However, it is expected that a chapter occurs at a lower level than a genre. That is a genre
 * potentially has several chapters, but chapters can only contain levels.
 */
class ChapterLevelPack extends WordProblemLevelPack
{
    public static inline var NODE_TYPE : String = "ChapterLevelPack";
    
    /**
     * A zero based index of where this chapter lies within a genre.
     */
    public var index : Int = -1;
    
    public function new(levelManager : ICgsLevelManager,
            cache : ICgsUserCache,
            levelFactory : ICgsLevelFactory,
            lockFactory : ICgsLockFactory,
            nodeLabel : Int)
    {
        super(levelManager, cache, levelFactory, lockFactory, nodeLabel);
    }
    
    override private function get_isComplete() : Bool
    {
        // A chapter being completed is the same as all childs levels or level sets underneath
        // it being complete or it was manually set as complete
        var isChapterCompleted : Bool = super.isComplete;
        if (!isChapterCompleted) 
        {
            isChapterCompleted = true;
            for (childNode/* AS3HX WARNING could not determine type for var: childNode exp: EIdent(m_levelData) type: null */ in m_levelData)
            {
                if (!childNode.isComplete) 
                {
                    isChapterCompleted = false;
                    break;
                }
            }
        }
        
        return isChapterCompleted;
    }
}
