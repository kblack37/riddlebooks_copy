package wordproblem.level.locks
{
    import cgs.levelProgression.ICgsLevelManager;
    import cgs.levelProgression.locks.ICgsLevelLock;
    import cgs.levelProgression.nodes.ICgsLevelNode;
    import cgs.levelProgression.nodes.ICgsLevelPack;
    
    import wordproblem.level.LevelNodeStatuses;
    
    /**
     * Check if all children of a node have an exact status.
     */
    public class NodeChildrenStatusLock implements ICgsLevelLock
    {
        public static const TYPE:String = "NodeChildrenStatus";
        public static const NODE_NAME_KEY:String = "name";
        public static const NODE_STATUS_KEY:String = "unlockStatus";
        
        private var m_levelManager:ICgsLevelManager;
        
        private var m_unlockNodeName:String;
        private var m_unlockStatus:String;
        
        public function NodeChildrenStatusLock(levelManager:ICgsLevelManager)
        {
            m_levelManager = levelManager;
        }
        
        public function init(lockKeyData:Object=null):void
        {
            m_unlockNodeName = lockKeyData[NODE_NAME_KEY];
            m_unlockStatus = lockKeyData[NODE_STATUS_KEY];
        }
        
        public function destroy():void
        {
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
            var isLocked:Boolean = false;
            
            // Find the node we are locked on
            var levelNode:ICgsLevelNode = m_levelManager.getNodeByName(m_unlockNodeName);
            if (levelNode is ICgsLevelPack)
            {
                var levelPack:ICgsLevelPack = levelNode as ICgsLevelPack;
                var childrenNodes:Vector.<ICgsLevelNode> = levelPack.nodes;
                var i:int;
                var numChildren:int = childrenNodes.length;
                for (i = 0; i < numChildren; i++)
                {
                    var childMatches:Boolean = LevelNodeStatuses.getNodeMatchesStatus(childrenNodes[i], m_unlockStatus);
                    if (!childMatches)
                    {
                        isLocked = true;
                        break;
                    }
                }
            }
            else
            {
                isLocked = !LevelNodeStatuses.getNodeMatchesStatus(levelNode, m_unlockStatus);
            }
            
            return isLocked;
        }
        
        public function doesKeyMatch(keyData:Object):Boolean
        {
            return false;
        }
    }
}