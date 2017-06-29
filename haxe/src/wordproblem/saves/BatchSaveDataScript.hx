package wordproblem.saves;


import cgs.cache.ICgsUserCache;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.scripts.BaseBufferEventScript;

/**
 * For performance and data consistency purposes, it may be very important to batch save data
 * into atomic operations.
 * 
 * The current save data model involves using key-value pairs where several different places in the application
 * want to update their own properties.
 */
class BatchSaveDataScript extends BaseBufferEventScript
{
    private var m_gameEngine : IGameEngine;
    
    /**
     * This class is what is performing the actual requests to either save the data locally
     * or to a remote server. The idea is that the script has logic to properly organize the
     * key-value save pairs and flush out to this object in batches.
     */
    private var m_realCacheInterface : ICgsUserCache;
    
    /*
    TODO:
    Keep a list of dummy cache objects. Main idea is to pass one of these to external scripts that
    want to utilize data saving.
    
    Idea is that each of these individual caches can have their own names and settings that
    this script can access to see how data should be organized before flushing them in the
    real cache interface.
    
    For example, the level progression system gets it own cache to handle changes in the nodes. The cache
    can indicate that all data in it should be flushed altogether.
    Each version of the game may need its own version of this script IF it wants to organize save data in
    a special way.
    
    First version should simply detect which properties changed
    */
    
    /**
     * The application save data can segment save properties into separate blocks that other scripts
     * can write things into.
     */
    private var m_blockNameToCache : Dynamic;
    
    public function new(gameEngine : IGameEngine,
            realCacheInterface : ICgsUserCache,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_gameEngine = gameEngine;
        m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        m_realCacheInterface = realCacheInterface;
        m_blockNameToCache = { };
    }
    
    public function getCacheBlockByName(blockName : String) : ICgsUserCache
    {
        var matchingCache : ICgsUserCache = m_realCacheInterface;
        if (m_blockNameToCache.exists(blockName)) 
        {
            matchingCache = Reflect.field(m_blockNameToCache, blockName);
        }
        
        return matchingCache;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        // TODO: Need to figure out when the best time is to flush all the save information.
        // After solving is when all the calculations of the next level and the node status
        // are complete
        if (eventType == GameEvent.LEVEL_SOLVED) 
        {
            m_realCacheInterface.flush(null);
        }
    }
}
