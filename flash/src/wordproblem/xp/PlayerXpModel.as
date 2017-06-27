package wordproblem.xp
{
    import cgs.Cache.ICgsUserCache;

    /**
     * This is the main container for all data related to player experience.
     * It should have read/write access to some save data cache.
     */
    public class PlayerXpModel
    {
        private static const XP_SAVE_KEY:String = "xp";
        
        /**
         * The cache acts as the read/write interface for the persistent storage of
         * player xp. (NOTE: this cache object might be shared across multiple data models)
         */
        private var m_cache:ICgsUserCache;
        
        /**
         * This is the total amount of xp that the player has earned so far in this game
         */
        public var totalXP:uint;
        
        /**
         * This is a list where the index maps to the total amount of xp that
         * is needed to reach a particular level.
         */
        private var m_totalExperiencePerLevel:Vector.<uint>;
        
        /**
         * @param cache
         */
        public function PlayerXpModel(cache:ICgsUserCache)
        {
            m_cache = cache;
            m_totalExperiencePerLevel = new Vector.<uint>();
            
            /*
            TODO: 
            Need to create a plan such that the list of experience is populated
            In addition each level may need to link to additional data.
            */
            // First two levels don't have any xp since player starts at level 1
            m_totalExperiencePerLevel.push(0, 0);
            
            // Make first level have less xp requirements
            m_totalExperiencePerLevel.push(6);
            
            var maxLevel:uint = 10000;
            for (var i:int = 2; i < maxLevel; i++)
            {
                var xpForLastLevel:int = m_totalExperiencePerLevel[m_totalExperiencePerLevel.length - 1];
                var xpForNextLevel:int = xpForLastLevel;
                
                // For levels between 2 and 10, 10 xp to level up
                if (i < 5)
                {
                    xpForNextLevel += 10;
                }
                else if (i < 20)
                {
                    xpForNextLevel += 20;
                }
                else if (i < 40)
                {
                    xpForNextLevel += 30;
                }
                else
                {
                    xpForNextLevel += 50;
                }
                m_totalExperiencePerLevel.push(xpForNextLevel);
            }
            
            if (m_cache != null && m_cache.saveExists(PlayerXpModel.XP_SAVE_KEY))
            {
                totalXP = m_cache.getSave(PlayerXpModel.XP_SAVE_KEY);
            }
            else
            {
                totalXP = 0;
            }
        }
        
        /**
         * Write out contents to the cache
         * 
         * @param flush
         *      Should the cache immediately send update. The reason to hold off on this is if we know
         *      we have other info that can be batched on the same save
         */
        public function save(flush:Boolean):void
        {
            if (m_cache != null)
            {
                // Only set save if local value and cached value are different
                var valueChanged:Boolean = true;
                if (m_cache.saveExists(PlayerXpModel.XP_SAVE_KEY))
                {
                    valueChanged = m_cache.getSave(PlayerXpModel.XP_SAVE_KEY) != this.totalXP;
                }
                
                if (valueChanged)
                {
                    m_cache.setSave(PlayerXpModel.XP_SAVE_KEY, this.totalXP, flush);
                }
            }
        }
        
        /**
         * Get back the total amount of experience that is required to reach a given player level.
         * 
         * @param level
         *      The target player level to search for
         * @return
         *      total xp needed to reach a given level
         */
        public function getTotalXpForLevel(level:uint):uint
        {
            if (level > m_totalExperiencePerLevel.length)
            {
                level = m_totalExperiencePerLevel.length - 1;
            }
            return m_totalExperiencePerLevel[level];
        }
        
        /**
         * Given a total amount of xp, get back the level the player would be at
         * and the amount of leftover xp to contribute to reaching the next level.
         * 
         * @param totalXP
         * @param outData
         *      An output list of the level in the first index and remaining xp in the second index
         */
        public function getLevelAndRemainingXpFromTotalXp(totalXP:uint, outData:Vector.<uint>):void
        {
            var playerLevel:uint = 0;
            var remainingXp:uint = 0;
            var i:int;
            var numLevels:int = m_totalExperiencePerLevel.length;
            for (i = 1; i < numLevels; i++)
            {
                var totalXpForLevel:uint = m_totalExperiencePerLevel[i];
                
                // If the total amount of XP for a level exceeds the given amount
                // then the player level is the previous one
                if (totalXP < totalXpForLevel)
                {
                    playerLevel = (i > 1) ? i - 1 : 1;
                    break;
                }
            }
            
            // Remainder is just the difference between xp for player level
            // and the total xp
            var xpForPlayerLevel:uint = m_totalExperiencePerLevel[playerLevel];
            remainingXp = totalXP - xpForPlayerLevel;
            
            outData.push(playerLevel, remainingXp);
        }
    }
}