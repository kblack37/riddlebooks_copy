package wordproblem.level.locks
{
    import cgs.levelProgression.locks.ICgsLevelLock;
    
    /**
     * An indefinite lock can only be unlocked by the programmer going into the
     * level file and switching the lock value to false
     */
    public class IndefiniteLock implements ICgsLevelLock
    {
        public static const TYPE:String = "Indefinite";
        
        public static const LOCKED_KEY:String = "locked";
        
        private var m_locked:Boolean;
        
        public function IndefiniteLock()
        {
        }
        
        public function init(lockKeyData:Object=null):void
        {
            if(lockKeyData == null)
            {
                // Do nothing if no data provided
                return;
            }
            
            m_locked = lockKeyData[LOCKED_KEY];
        }
        
        public function destroy():void
        {
            reset();
        }
        
        public function reset():void
        {
        }
        
        public function get lockType():String
        {
            return TYPE;
        }
        
        public function get isLocked():Boolean
        {
            return m_locked;
        }
        
        public function doesKeyMatch(keyData:Object):Boolean
        {
            return false;
        }
    }
}