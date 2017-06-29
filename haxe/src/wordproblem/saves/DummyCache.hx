package wordproblem.saves;


import cgs.cache.ICgsUserCache;

import wordproblem.level.LevelNodeCompletionValues;
import wordproblem.level.LevelNodeSaveKeys;

/**
 * This cache is used entirely for testing purposes.
 */
class DummyCache implements ICgsUserCache
{
    public var size(get, never) : Int;

    private var m_dummyMap : Dynamic;
    
    public function new(dummyData : Dynamic = null)
    {
        m_dummyMap = ((dummyData != null)) ? dummyData : { };
        
        // Finished tutorials
        Reflect.setField(m_dummyMap, "ll_$0", getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS));
        Reflect.setField(m_dummyMap, "ll_$1", getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS));
        Reflect.setField(m_dummyMap, "ll_$2", getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS));
        Reflect.setField(m_dummyMap, "ll_start", getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS));
        Reflect.setField(m_dummyMap, "ll_text_discover", getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS));
    }
    
    private function getCompletionObject(value : Int) : Dynamic
    {
        var save : Dynamic = { };
        save[LevelNodeSaveKeys.COMPLETION_VALUE] = value;
        return save;
    }
    
    private function get_size() : Int
    {
        return 0;
    }
    
    public function clearCache() : Void
    {
    }
    
    public function deleteSave(property : String) : Void
    {
    }
    
    public function flush(callback : Function = null) : Bool
    {
        return false;
    }
    
    public function registerSaveCallback(property : String, callback : Function) : Void
    {
    }
    
    public function unregisterSaveCallback(property : String) : Void
    {
    }
    
    public function getSave(property : String) : Dynamic
    {
        return Reflect.field(m_dummyMap, property);
    }
    
    public function initSave(property : String, defaultVal : Dynamic, flush : Bool = true) : Void
    {
    }
    
    public function saveExists(property : String) : Bool
    {
        return m_dummyMap.exists(property);
    }
    
    public function setSave(property : String, val : Dynamic, flush : Bool = true) : Bool
    {
        return Reflect.setField(m_dummyMap, property, val);
    }
}
