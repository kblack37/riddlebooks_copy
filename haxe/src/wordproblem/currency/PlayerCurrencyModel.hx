package wordproblem.currency;


import cgs.cache.ICgsUserCache;

/**
 * Very simple data model referencing the currency the player has earned.
 */
class PlayerCurrencyModel
{
    private static inline var CURRENCY_SAVE_KEY : String = "coins";
    
    /**
     * Cache serves as the read/write interface
     */
    private var m_cache : ICgsUserCache;
    
    /**
     * Coins form the base currency used to purchase things in the game
     */
    public var totalCoins : Int;
    
    /**
     * For each level that has objectives, another script will be responsible for
     * populating this with values for coins earned per objective.
     * 
     * The index should line up with the objective. Should be cleared for each new
     * level, a value of zero or less rewards no coins.
     */
    public var coinsEarnedForObjectives : Array<Int>;
    
    /**
     * The number of coins earned via brain level up (player had accumulated enough xp)
     * since the last level was completed.
     * 
     * Key: The new brain level
     * Value: Amount of coins earned for that brain level
     */
    private var m_coinsEarnedForLevelUp : Dynamic;
    
    public function new(cache : ICgsUserCache)
    {
        m_cache = cache;
        
        this.coinsEarnedForObjectives = new Array<Int>();
        m_coinsEarnedForLevelUp = { };
        
        if (m_cache != null && m_cache.saveExists(PlayerCurrencyModel.CURRENCY_SAVE_KEY)) 
        {
            this.totalCoins = m_cache.getSave(PlayerCurrencyModel.CURRENCY_SAVE_KEY);
        }
        else 
        {
            this.totalCoins = 0;
        }
    }
    
    public function resetCounters() : Void
    {
        for (level in Reflect.fields(m_coinsEarnedForLevelUp))
        {
            ;
        }
        
        this.coinsEarnedForObjectives.length = 0;
    }
    
    public function setCoinsEarnedForLevelUp(level : String, coins : Int) : Void
    {
        Reflect.setField(m_coinsEarnedForLevelUp, level, coins);
    }
    
    public function getCoinsEarnedForLevelUp(level : String) : Int
    {
        var coinsEarned : Int = 0;
        if (m_coinsEarnedForLevelUp.exists(level)) 
        {
            coinsEarned = Reflect.field(m_coinsEarnedForLevelUp, level);
        }
        return coinsEarned;
    }
    
    /**
     * Save the contents to cache
     */
    public function save(flush : Bool) : Void
    {
        if (m_cache != null) 
        {
            // Only set save if local value and cached value are different
            var valueChanged : Bool = true;
            if (m_cache.saveExists(PlayerCurrencyModel.CURRENCY_SAVE_KEY)) 
            {
                valueChanged = m_cache.getSave(PlayerCurrencyModel.CURRENCY_SAVE_KEY) != this.totalCoins;
            }
            
            if (valueChanged) 
            {
                m_cache.setSave(PlayerCurrencyModel.CURRENCY_SAVE_KEY, this.totalCoins, flush);
            }
        }
    }
    
    /**
     * Returns the aggregation of coins earned since the last level started
     */
    public function getTotalCoinsEarnedSinceLastLevel() : Int
    {
        var totalEarned : Int = 0;
        var i : Int;
        for (i in 0...coinsEarnedForObjectives.length){
            totalEarned += coinsEarnedForObjectives[i];
        }
        
        for (level in Reflect.fields(m_coinsEarnedForLevelUp))
        {
            totalEarned += Reflect.field(m_coinsEarnedForLevelUp, level);
        }
        
        return totalEarned;
    }
}
