package wordproblem.currency.scripts
{
    import wordproblem.currency.PlayerCurrencyModel;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.objectives.BaseObjective;
    import wordproblem.scripts.BaseBufferEventScript;
    import wordproblem.xp.PlayerXpModel;
    
    /**
     * This script contains the logic for awarding currency to the player at different
     * points.
     */
    public class CurrencyAwardedScript extends BaseBufferEventScript
    {
        private var m_gameEngine:IGameEngine;
        private var m_playerCurrencyModel:PlayerCurrencyModel;
        private var m_playerXpModel:PlayerXpModel;
        private var m_flushSaveImmediately:Boolean;
        
        public function CurrencyAwardedScript(gameEngine:IGameEngine,
                                              playerCurrencyModel:PlayerCurrencyModel,
                                              playerXpModel:PlayerXpModel,
                                              id:String=null, 
                                              isActive:Boolean=true, 
                                              flushSaveImmediately:Boolean=true)
        {
            super(id, isActive);
            
            m_gameEngine = gameEngine;
            m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
            m_playerCurrencyModel = playerCurrencyModel;
            m_playerXpModel = playerXpModel;
            m_flushSaveImmediately = flushSaveImmediately;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            // Currency awarded for completing objectives or earning brain points need to 
            // determined after other scripts that update those parts are executed.
            // We must assume that all coin related events trigger on the level solve and have
            // been executed before we enter this block
            if (eventType == GameEvent.LEVEL_SOLVED)
            {
                // Reset the temp counters
                m_playerCurrencyModel.resetCounters();
                
                // HACK: For each objective need to calculate the appropriate number of coins to give
                var currentLevel:WordProblemLevelData = m_gameEngine.getCurrentLevel();
                var objectives:Vector.<BaseObjective> = currentLevel.objectives;
                var i:int;
                for (i = 0; i < objectives.length; i++)
                {
                    var coinsForObjective:int = 0;
                    var objective:BaseObjective = objectives[i];
                    if (objective.getCompleted())
                    {
                        coinsForObjective = 10;
                    }
                    
                    m_playerCurrencyModel.coinsEarnedForObjectives.push(coinsForObjective);
                }
                
                // This is the wrong order (total xp doesn't get written out until later,
                // there is a hidden ordering dependency
                // HACK: For each level gained after a solve need to figure out the appropriate number of coins to give
                var xpEarnedInLevel:int = m_gameEngine.getCurrentLevel().statistics.xpEarnedForLevel;
                var totalXpAfterLevel:int = m_playerXpModel.totalXP + xpEarnedInLevel;
                
                var outXpData:Vector.<uint> = new Vector.<uint>();
                m_playerXpModel.getLevelAndRemainingXpFromTotalXp(m_playerXpModel.totalXP, outXpData);
                var levelBefore:uint = outXpData[0];
                
                outXpData.length = 0;
                m_playerXpModel.getLevelAndRemainingXpFromTotalXp(totalXpAfterLevel, outXpData);
                var levelAfter:uint = outXpData[0];
                
                while (levelBefore < levelAfter)
                {
                    // Amount of coins per level up depends on the level (i.e. higher level probably give more coins)
                    levelBefore++;
                    
                    var coinsForLevelUp:int = 0;
                    if (levelBefore < 5)
                    {
                        coinsForLevelUp = 20;
                    }
                    else if (levelBefore < 11)
                    {
                        coinsForLevelUp = 30;
                    }
                    else if (levelBefore < 21)
                    {
                        coinsForLevelUp = 50;
                    }
                    else if (levelBefore < 30)
                    {
                        coinsForLevelUp = 60;
                    }
                    else
                    {
                        coinsForLevelUp = 70;
                    }
                    m_playerCurrencyModel.setCoinsEarnedForLevelUp(String(levelBefore), coinsForLevelUp);
                }
                
                // Perform save here
                m_playerCurrencyModel.totalCoins += m_playerCurrencyModel.getTotalCoinsEarnedSinceLastLevel();
                m_playerCurrencyModel.save(m_flushSaveImmediately);
            }
        }
        
        // Somewhere data mapping brainp xp progress to coins and objectives to coins needs to be encoded.
        // What is the best place for these rules
    }
}