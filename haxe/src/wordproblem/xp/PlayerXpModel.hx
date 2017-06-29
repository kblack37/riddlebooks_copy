package wordproblem.xp;


import cgs.cache.ICgsUserCache;

/**
 * This is the main container for all data related to player experience.
 * It should have read/write access to some save data cache.
 */
class PlayerXpModel
{
    private static inline var XP_SAVE_KEY : String = "xp";
    
    /**
     * The cache acts as the read/write interface for the persistent storage of
     * player xp. (NOTE: this cache object might be shared across multiple data models)
     */
    private var m_cache : ICgsUserCache;
    
    /**
     * This is the total amount of xp that the player has earned so far in this game
     */
    public var totalXP : Int;
    
    /**
     * This is a list where the index maps to the total amount of xp that
     * is needed to reach a particular level.
     */
    private var m_totalExperiencePerLevel : Array<Int>;
    
    /**
     * @param cache
     */
    public function new(cache : ICgsUserCache)
    {
        m_cache = cache;
        m_totalExperiencePerLevel = new Array<Int>();
        
        /*
        TODO: 
        Need to create a plan such that the list of experience is populated
        In addition each level may need to link to additional data.
        */
        // First two levels don't have any xp since player starts at level 1
        m_totalExperiencePerLevel.push(0);
        m_totalExperiencePerLevel.push(0);
        
        
        // Make first level have less xp requirements
        m_totalExperiencePerLevel.push(6);
        
        var maxLevel : Int = 10000;
        for (i in 2...maxLevel){
            var xpForLastLevel : Int = m_totalExperiencePerLevel[m_totalExperiencePerLevel.length - 1];
            var xpForNextLevel : Int = xpForLastLevel;
            
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
    public function save(flush : Bool) : Void
    {
        if (m_cache != null) 
        {
            // Only set save if local value and cached value are different
            var valueChanged : Bool = true;
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
    public function getTotalXpForLevel(level : Int) : Int
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
    public function getLevelAndRemainingXpFromTotalXp(totalXP : Int, outData : Array<Int>) : Void
    {
        var playerLevel : Int = 0;
        var remainingXp : Int = 0;
        var i : Int;
        var numLevels : Int = m_totalExperiencePerLevel.length;
        for (i in 1...numLevels){
            var totalXpForLevel : Int = m_totalExperiencePerLevel[i];
            
            // If the total amount of XP for a level exceeds the given amount
            // then the player level is the previous one
            if (totalXP < totalXpForLevel) 
            {
                playerLevel = ((i > 1)) ? i - 1 : 1;
                break;
            }
        }  // and the total xp    // Remainder is just the difference between xp for player level  
        
        
        
        
        
        var xpForPlayerLevel : Int = m_totalExperiencePerLevel[playerLevel];
        remainingXp = totalXP - xpForPlayerLevel;
        
        outData.push(playerLevel);
        outData.push(remainingXp);
        
    }
}
