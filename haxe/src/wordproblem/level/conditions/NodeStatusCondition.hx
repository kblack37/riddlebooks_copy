package wordproblem.level.conditions;

// TODO: uncomment once cgs library is ported
//import cgs.levelprogression.ICgsLevelManager;
//import cgs.levelprogression.nodes.ICgsLevelNode;

import wordproblem.level.LevelNodeStatuses;

/**
 * Condition passes if a node with a given name has been marked as completed
 */
class NodeStatusCondition implements ICondition
{
    //public static inline var TYPE : String = "NodeStatus";
    //
    //private var m_nodeName : String;
    //private var m_nodeStatus : String;
    //
    //private var m_targetNode : ICgsLevelNode;
    //
    //public function new(name : String = null, status : String = null)
    //{
        //m_nodeName = name;
        //m_nodeStatus = status;
    //}
    //
    public function getSatisfied() : Bool
    {
        var satisfied : Bool = false;
        //if (m_targetNode != null) 
        //{
            //satisfied = LevelNodeStatuses.getNodeMatchesStatus(m_targetNode, m_nodeStatus);
        //}
        return satisfied;
    }
    //
    public function getType() : String
    {
        //return NodeStatusCondition.TYPE;
		return "";
    }
    //
    public function deserialize(data : Dynamic) : Void
    {
        //m_nodeName = data.name;
        //m_nodeStatus = data.status;
    }
    //
    public function serialize() : Dynamic
    {
        return null;
    }
    //
    public function clearState() : Void
    {
    }
    //
    public function dispose() : Void
    {
    }
    //
    //public function update(levelManager : ICgsLevelManager) : Void
    //{
        //m_targetNode = levelManager.getNodeByName(m_nodeName);
    //}
}
