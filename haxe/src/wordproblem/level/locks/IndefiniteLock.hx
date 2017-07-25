package wordproblem.level.locks;

// TODO: uncomment once cgs library is ported
//import cgs.levelprogression.locks.ICgsLevelLock;

/**
 * An indefinite lock can only be unlocked by the programmer going into the
 * level file and switching the lock value to false
 */
class IndefiniteLock //implements ICgsLevelLock
{
    public var lockType(get, never) : String;
    public var isLocked(get, never) : Bool;

    public static inline var TYPE : String = "Indefinite";
    
    public static inline var LOCKED_KEY : String = "locked";
    
    private var m_locked : Bool;
    
    public function new()
    {
    }
    
    public function init(lockKeyData : Dynamic = null) : Void
    {
        if (lockKeyData == null) 
        {
            // Do nothing if no data provided
            return;
        }
        
        m_locked = Reflect.field(lockKeyData, LOCKED_KEY);
    }
    
    public function destroy() : Void
    {
        reset();
    }
    
    public function reset() : Void
    {
    }
    
    private function get_lockType() : String
    {
        return TYPE;
    }
    
    private function get_isLocked() : Bool
    {
        return m_locked;
    }
    
    public function doesKeyMatch(keyData : Dynamic) : Bool
    {
        return false;
    }
}
