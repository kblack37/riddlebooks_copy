package wordproblem.level.nodes
{
    import cgs.Cache.ICgsUserCache;
    import cgs.levelProgression.ICgsLevelManager;
    import cgs.levelProgression.nodes.ICgsLevelNode;
    import cgs.levelProgression.util.ICgsLevelFactory;
    import cgs.levelProgression.util.ICgsLockFactory;
    
    /**
     * Similar to the GenreLevelPack, the ChapterLevelPack is a way to categorize levels.
     * However, it is expected that a chapter occurs at a lower level than a genre. That is a genre
     * potentially has several chapters, but chapters can only contain levels.
     */
    public class ChapterLevelPack extends WordProblemLevelPack
    {
        public static const NODE_TYPE:String = "ChapterLevelPack";
        
        /**
         * A zero based index of where this chapter lies within a genre.
         */
        public var index:int = -1;
        
        public function ChapterLevelPack(levelManager:ICgsLevelManager,
                                         cache:ICgsUserCache,
                                         levelFactory:ICgsLevelFactory, 
                                         lockFactory:ICgsLockFactory, 
                                         nodeLabel:int)
        {
            super(levelManager, cache, levelFactory, lockFactory, nodeLabel);
        }
        
        override public function get isComplete():Boolean
        {
            // A chapter being completed is the same as all childs levels or level sets underneath
            // it being complete or it was manually set as complete
            var isChapterCompleted:Boolean = super.isComplete;
            if (!isChapterCompleted)
            {
                isChapterCompleted = true;
                for each(var childNode:ICgsLevelNode in m_levelData)
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
}