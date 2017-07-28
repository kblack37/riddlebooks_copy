package wordproblem.saves;


import cgs.cache.ICgsUserCache;

import haxe.Constraints.Function;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.scripts.BaseBufferEventScript;

/**
 * The way the save system work for the level progression sequence, each node in the system
 * has its own separate completion data. This can be problematic when certain events cause
 * multiple nodes to change their status (for example finishing a problem set can unlock a few
 * new chapters of problems). If one of those messages drops then the correct spot in the progression
 * might be screwed up.
 * 
 * This script is intended to repair large inconsistencies in the players save data.
 * Usage:
 * At the login we look for a master save blob
 * 
 * At the end of each level and after the initial modifications to the save data, we look at
 * the current progression state. Poll the important nodes in the system and flush the consistent
 * state.
 */
class RepairSaveData extends BaseBufferEventScript
{
    private var m_gameEngine : IGameEngine;
    private var m_cache : ICgsUserCache;
    
    /**
     * Should accept a list of 'key' node names that are completed by the player
     */
    private var m_executeRepairsCallback : Function;
    
    /**
     * Return an array of 'key' node names that have been completed. The idea is that just by looking
     * at the key node names we can always correctly determine what an consistent/uncorrupted save
     * progress state should look like
     */
    private var m_saveRepairsCallback : Function;
    
    private inline static var MASTER_PROGRESS_SAVE_KEY : String = "master-save";
    
    public function new(gameEngine : IGameEngine,
            cache : ICgsUserCache,
            repairCallback : Function,
            saveCallback : Function,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_gameEngine = gameEngine;
        m_gameEngine.addEventListener(GameEvent.LEVEL_COMPLETE, bufferEvent);
        
        m_cache = cache;
        
        // Listen for a message when all completion values have been altered
        // Listen for a message when the level progression nodes have been initialized to their starting values
        // (this is after save data is loaded for the user and has been applied)
        m_executeRepairsCallback = repairCallback;
        m_saveRepairsCallback = saveCallback;
        
        onLoggedIn();
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_gameEngine.removeEventListener(GameEvent.LEVEL_COMPLETE, bufferEvent);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.LEVEL_COMPLETE) 
        {
            // Get all the node names that are required to do repairs, check whether they are complete
            // If they are then they should be flushed
            if (m_saveRepairsCallback != null) 
            {
                var serializedData : Dynamic = m_saveRepairsCallback();
                if (serializedData != null) 
                {
                    m_cache.setSave(MASTER_PROGRESS_SAVE_KEY, serializedData, true);
                }
            }
        }
    }
    
    private function onLoggedIn() : Void
    {
        // Pull the level blob. The blob should just be a list on important node names that
        // are marked as completed.
        // For each of these name, get related nodes in the level progression and make sure
        // their completion value is set the the right expected value
        // If it is not, then some save network error occurred and it should be repaired
        // The repair logic is dependent on how the progression is formatted,
        var keyNodeNames : Array<Dynamic> = [];
        if (m_cache.saveExists(MASTER_PROGRESS_SAVE_KEY)) 
        {
            keyNodeNames = m_cache.getSave(MASTER_PROGRESS_SAVE_KEY);
        }
        
        if (m_executeRepairsCallback != null) 
        {
            m_executeRepairsCallback(keyNodeNames);
        }
    }
}
