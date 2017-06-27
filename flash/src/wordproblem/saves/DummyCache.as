package wordproblem.saves
{
    import cgs.Cache.ICgsUserCache;
    
    import wordproblem.level.LevelNodeCompletionValues;
    import wordproblem.level.LevelNodeSaveKeys;
    
    /**
     * This cache is used entirely for testing purposes.
     */
    public class DummyCache implements ICgsUserCache
    {
        private var m_dummyMap:Object;
        
        public function DummyCache(dummyData:Object=null)
        {
            m_dummyMap = (dummyData != null) ? dummyData : {};
            
            // Finished tutorials
            m_dummyMap['ll_$0'] = getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS);
            m_dummyMap['ll_$1'] = getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS);
            m_dummyMap['ll_$2'] = getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS);
            m_dummyMap['ll_start'] = getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS);
            m_dummyMap['ll_text_discover'] = getCompletionObject(LevelNodeCompletionValues.PLAYED_SUCCESS);
        }
        
        private function getCompletionObject(value:int):Object
        {
            var save:Object = {};
            save[LevelNodeSaveKeys.COMPLETION_VALUE] = value;
            return save;
        }
        
        public function get size():uint
        {
            return 0;
        }
        
        public function clearCache():void
        {
        }
        
        public function deleteSave(property:String):void
        {
        }
        
        public function flush(callback:Function=null):Boolean
        {
            return false;
        }
        
        public function registerSaveCallback(property:String, callback:Function):void
        {
        }
        
        public function unregisterSaveCallback(property:String):void
        {
        }
        
        public function getSave(property:String):*
        {
            return m_dummyMap[property];
        }
        
        public function initSave(property:String, defaultVal:*, flush:Boolean=true):void
        {
        }
        
        public function saveExists(property:String):Boolean
        {
            return m_dummyMap.hasOwnProperty(property);
        }
        
        public function setSave(property:String, val:*, flush:Boolean=true):Boolean
        {
            return m_dummyMap[property] = val;
        }
    }
}