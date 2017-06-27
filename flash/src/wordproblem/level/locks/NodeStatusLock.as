package wordproblem.level.locks
{
    import cgs.levelProgression.ICgsLevelManager;
    import cgs.levelProgression.locks.ICgsLevelLock;
    import cgs.levelProgression.nodes.ICgsLevelNode;
    
    import wordproblem.level.LevelNodeStatuses;
    
    public class NodeStatusLock implements ICgsLevelLock
    {
        public static const TYPE:String = "NodeStatus";
        
        // Data Keys
        public static const NODE_NAME_KEY:String = "name";
        public static const NODE_STATUS_KEY:String = "unlockStatus";
        
        private var m_levelManager:ICgsLevelManager;
        
        private var m_unlockNodeName:String;
        private var m_unlockStatus:String;
        
        public function NodeStatusLock(levelManager:ICgsLevelManager)
        {
            m_levelManager = levelManager;
        }
        
        /**
         * @inheritDoc
         */
        public function init(lockKeyData:Object = null):void
        {
            if(lockKeyData == null)
            {
                // Do nothing if no data provided
                return;
            }

            m_unlockNodeName = lockKeyData[NODE_NAME_KEY];
            m_unlockStatus = lockKeyData[NODE_STATUS_KEY];
        }
        
        /**
         * @inheritDoc
         */
        public function destroy():void
        {
            reset();
        }
        
        /**
         * @inheritDoc
         */
        public function reset():void 
        {
            m_unlockStatus = LevelNodeStatuses.PLAYED;
        }
        
        /**
         * @inheritDoc
         */
        public function get lockType():String
        {
            return TYPE;
        }
        
        /**
         * @inheritDoc
         */
        public function get isLocked():Boolean
        {
            // Find the node we are locked on
            var levelNode:ICgsLevelNode = m_levelManager.getNodeByName(m_unlockNodeName);
            
            // Check lock
            var isLocked:Boolean = (levelNode == null || !LevelNodeStatuses.getNodeMatchesStatus(levelNode, m_unlockStatus));
            return isLocked;
        }
        
        /**
         * @inheritDoc
         */
        public function doesKeyMatch(keyData:Object):Boolean
        {
            return false;
        }
    }
}