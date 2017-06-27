package wordproblem.level.conditions
{
    import cgs.levelProgression.ICgsLevelManager;
    import cgs.levelProgression.nodes.ICgsLevelNode;
    
    import wordproblem.level.LevelNodeStatuses;

    /**
     * Condition passes if a node with a given name has been marked as completed
     */
    public class NodeStatusCondition implements ICondition
    {
        public static const TYPE:String = "NodeStatus";
        
        private var m_nodeName:String;
        private var m_nodeStatus:String;
        
        private var m_targetNode:ICgsLevelNode;
        
        public function NodeStatusCondition(name:String=null, status:String=null)
        {
            m_nodeName = name;
            m_nodeStatus = status;
        }
        
        public function getSatisfied():Boolean
        {
            var satisfied:Boolean = false;
            if (m_targetNode != null)
            {
                satisfied = LevelNodeStatuses.getNodeMatchesStatus(m_targetNode, m_nodeStatus);
            }
            return satisfied;
        }
        
        public function getType():String
        {
            return NodeStatusCondition.TYPE;
        }
        
        public function deserialize(data:Object):void
        {
            m_nodeName = data.name;
            m_nodeStatus = data.status;
        }
        
        public function serialize():Object
        {
            return null;
        }
        
        public function clearState():void
        {  
        }
        
        public function dispose():void
        {
        }
        
        public function update(levelManager:ICgsLevelManager):void
        {
            m_targetNode = levelManager.getNodeByName(m_nodeName);
        }
    }
}