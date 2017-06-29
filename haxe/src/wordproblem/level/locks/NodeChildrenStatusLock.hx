package wordproblem.level.locks;


import cgs.levelprogression.ICgsLevelManager;
import cgs.levelprogression.locks.ICgsLevelLock;
import cgs.levelprogression.nodes.ICgsLevelNode;
import cgs.levelprogression.nodes.ICgsLevelPack;

import wordproblem.level.LevelNodeStatuses;

/**
 * Check if all children of a node have an exact status.
 */
class NodeChildrenStatusLock implements ICgsLevelLock
{
    public var lockType(get, never) : String;
    public var isLocked(get, never) : Bool;

    public static inline var TYPE : String = "NodeChildrenStatus";
    public static inline var NODE_NAME_KEY : String = "name";
    public static inline var NODE_STATUS_KEY : String = "unlockStatus";
    
    private var m_levelManager : ICgsLevelManager;
    
    private var m_unlockNodeName : String;
    private var m_unlockStatus : String;
    
    public function new(levelManager : ICgsLevelManager)
    {
        m_levelManager = levelManager;
    }
    
    public function init(lockKeyData : Dynamic = null) : Void
    {
        m_unlockNodeName = Reflect.field(lockKeyData, NODE_NAME_KEY);
        m_unlockStatus = Reflect.field(lockKeyData, NODE_STATUS_KEY);
    }
    
    public function destroy() : Void
    {
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
        var isLocked : Bool = false;
        
        // Find the node we are locked on
        var levelNode : ICgsLevelNode = m_levelManager.getNodeByName(m_unlockNodeName);
        if (Std.is(levelNode, ICgsLevelPack)) 
        {
            var levelPack : ICgsLevelPack = try cast(levelNode, ICgsLevelPack) catch(e:Dynamic) null;
            var childrenNodes : Array<ICgsLevelNode> = levelPack.nodes;
            var i : Int;
            var numChildren : Int = childrenNodes.length;
            for (i in 0...numChildren){
                var childMatches : Bool = LevelNodeStatuses.getNodeMatchesStatus(childrenNodes[i], m_unlockStatus);
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
    
    public function doesKeyMatch(keyData : Dynamic) : Bool
    {
        return false;
    }
}
