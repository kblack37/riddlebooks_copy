package wordproblem.currency
{
    import cgs.Cache.ICgsUserCache;

    /**
     * Very simple data model referencing the currency the player has earned.
     */
    public class PlayerCurrencyModel
    {
        private static const CURRENCY_SAVE_KEY:String = "coins";
        
        /**
         * Cache serves as the read/write interface
         */
        private var m_cache:ICgsUserCache;
        
        /**
         * Coins form the base currency used to purchase things in the game
         */
        public var totalCoins:int;
        
        /**
         * For each level that has objectives, another script will be responsible for
         * populating this with values for coins earned per objective.
         * 
         * The index should line up with the objective. Should be cleared for each new
         * level, a value of zero or less rewards no coins.
         */
        public var coinsEarnedForObjectives:Vector.<int>;
        
        /**
         * The number of coins earned via brain level up (player had accumulated enough xp)
         * since the last level was completed.
         * 
         * Key: The new brain level
         * Value: Amount of coins earned for that brain level
         */
        private var m_coinsEarnedForLevelUp:Object;
        
        public function PlayerCurrencyModel(cache:ICgsUserCache)
        {
            m_cache = cache;
            
            this.coinsEarnedForObjectives = new Vector.<int>();
            m_coinsEarnedForLevelUp = {};
            
            if (m_cache != null && m_cache.saveExists(PlayerCurrencyModel.CURRENCY_SAVE_KEY))
            {
                this.totalCoins = m_cache.getSave(PlayerCurrencyModel.CURRENCY_SAVE_KEY);
            }
            else
            {
                this.totalCoins = 0;
            }
        }

        public function resetCounters():void
        {
            for (var level:String in m_coinsEarnedForLevelUp)
            {
                delete m_coinsEarnedForLevelUp[level];
            }
            
            this.coinsEarnedForObjectives.length = 0;
        }
        
        public function setCoinsEarnedForLevelUp(level:String, coins:int):void
        {
            m_coinsEarnedForLevelUp[level] = coins;
        }
        
        public function getCoinsEarnedForLevelUp(level:String):int
        {
            var coinsEarned:int = 0;
            if (m_coinsEarnedForLevelUp.hasOwnProperty(level))
            {
                coinsEarned = m_coinsEarnedForLevelUp[level];
            }
            return coinsEarned;
        }
        
        /**
         * Save the contents to cache
         */
        public function save(flush:Boolean):void
        {
            if (m_cache != null)
            {
                // Only set save if local value and cached value are different
                var valueChanged:Boolean = true;
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
        public function getTotalCoinsEarnedSinceLastLevel():int
        {
            var totalEarned:int = 0;
            var i:int;
            for (i = 0; i < coinsEarnedForObjectives.length; i++)
            {
                totalEarned += coinsEarnedForObjectives[i];
            }
            
            for (var level:String in m_coinsEarnedForLevelUp)
            {
                totalEarned += m_coinsEarnedForLevelUp[level];
            }
            
            return totalEarned;
        }
    }
}