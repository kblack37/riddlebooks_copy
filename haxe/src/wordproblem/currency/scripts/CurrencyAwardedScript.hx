package wordproblem.currency.scripts;


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
class CurrencyAwardedScript extends BaseBufferEventScript
{
    private var m_gameEngine : IGameEngine;
    private var m_playerCurrencyModel : PlayerCurrencyModel;
    private var m_playerXpModel : PlayerXpModel;
    private var m_flushSaveImmediately : Bool;
    
    public function new(gameEngine : IGameEngine,
            playerCurrencyModel : PlayerCurrencyModel,
            playerXpModel : PlayerXpModel,
            id : String = null,
            isActive : Bool = true,
            flushSaveImmediately : Bool = true)
    {
        super(id, isActive);
        
        m_gameEngine = gameEngine;
        m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        m_playerCurrencyModel = playerCurrencyModel;
        m_playerXpModel = playerXpModel;
        m_flushSaveImmediately = flushSaveImmediately;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
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
            var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
            var objectives : Array<BaseObjective> = currentLevel.objectives;
            var i : Int = 0;
            for (i in 0...objectives.length){
                var coinsForObjective : Int = 0;
                var objective : BaseObjective = objectives[i];
                if (objective.getCompleted()) 
                {
                    coinsForObjective = 10;
                }
                
                m_playerCurrencyModel.coinsEarnedForObjectives.push(coinsForObjective);
            }  // HACK: For each level gained after a solve need to figure out the appropriate number of coins to give    // there is a hidden ordering dependency    // This is the wrong order (total xp doesn't get written out until later,  
            
            
            
            
            
            
            
            var xpEarnedInLevel : Int = m_gameEngine.getCurrentLevel().statistics.xpEarnedForLevel;
            var totalXpAfterLevel : Int = m_playerXpModel.totalXP + xpEarnedInLevel;
            
            var outXpData : Array<Int> = new Array<Int>();
            m_playerXpModel.getLevelAndRemainingXpFromTotalXp(m_playerXpModel.totalXP, outXpData);
            var levelBefore : Int = outXpData[0];
            
			outXpData = new Array<Int>();
            m_playerXpModel.getLevelAndRemainingXpFromTotalXp(totalXpAfterLevel, outXpData);
            var levelAfter : Int = outXpData[0];
            
            while (levelBefore < levelAfter)
            {
                // Amount of coins per level up depends on the level (i.e. higher level probably give more coins)
                levelBefore++;
                
                var coinsForLevelUp : Int = 0;
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
                m_playerCurrencyModel.setCoinsEarnedForLevelUp(Std.string(levelBefore), coinsForLevelUp);
            }  // Perform save here  
            
            
            
            m_playerCurrencyModel.totalCoins += m_playerCurrencyModel.getTotalCoinsEarnedSinceLastLevel();
            m_playerCurrencyModel.save(m_flushSaveImmediately);
        }
    }
}
