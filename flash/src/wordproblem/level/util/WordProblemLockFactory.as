package wordproblem.level.util
{
    import cgs.levelProgression.ICgsLevelManager;
    import cgs.levelProgression.locks.ICgsLevelLock;
    import cgs.levelProgression.util.ICgsLockFactory;
    
    import wordproblem.level.locks.IndefiniteLock;
    import wordproblem.level.locks.NodeChildrenStatusLock;
    import wordproblem.level.locks.NodeStatusLock;
    
    /**
     * We create a brand new subclass of the lock factory, this appears to be the only way to have
     * our own node locking conditions.
     * 
     * For example we want locks based on progress within dragonbox, those locks are created in
     * this factory.
     */
    public class WordProblemLockFactory implements ICgsLockFactory
    {
        private var m_lockStorage:Object;
        private var m_levelManager:ICgsLevelManager;
        
        public function WordProblemLockFactory(levelManager:ICgsLevelManager)
        {
            m_levelManager = levelManager;
            m_lockStorage = new Object();
        }
        
        /**
         * @inheritDoc
         */
        public function getLockInstance(lockType:String, lockKeyData:Object):ICgsLevelLock
        {
            // Do nothing if no lock type given
            if (lockType == null || lockType == "")
            {
                return null;
            }
            
            var lock:ICgsLevelLock;
            
            // Get the lock storage for this type, creating the storage if this is a new type
            if (!m_lockStorage.hasOwnProperty(lockType))
            {
                // create new array for this type id
                m_lockStorage[lockType] = new Array();
            }
            var lockStorage:Array = m_lockStorage[lockType];
            
            // Get a lock out of storage
            if (lockStorage.length > 0)
            {
                lock = lockStorage.pop();
            }
            // Generate a new lock
            else
            {
                lock = generateLockInstance(lockType);
            }
            
            // Init the lock
            if (lock)
            {
                lock.init(lockKeyData);
            }
            
            return lock;
        }
        
        /**
         * @inheritDoc
         */
        public function recycleLock(lock:ICgsLevelLock):void
        {
            lock.reset();
            m_lockStorage[lock.lockType].push(lock);
        }
        
        private function generateLockInstance(lockType:String):ICgsLevelLock
        {
            var lock:ICgsLevelLock = null;
            
            // Scan for locks specific to the word problem game
            if (lockType == IndefiniteLock.TYPE)
            {
                lock = new IndefiniteLock();
            }
            else if (lockType == NodeChildrenStatusLock.TYPE)
            {
                lock = new NodeChildrenStatusLock(m_levelManager);
            }
            else
            {
                lock = new NodeStatusLock(m_levelManager);
            }
            
            return lock;
        }
    }
}