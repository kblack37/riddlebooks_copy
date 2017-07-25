package wordproblem.level.locks;

// TODO: uncomment once cgs library is ported
//import cgs.levelprogression.ICgsLevelManager;
//import cgs.levelprogression.locks.ICgsLevelLock;
//import cgs.levelprogression.nodes.ICgsLevelNode;

import wordproblem.level.LevelNodeStatuses;

class NodeStatusLock //implements ICgsLevelLock
{
    //public var lockType(get, never) : String;
    //public var isLocked(get, never) : Bool;
//
    //public static inline var TYPE : String = "NodeStatus";
    //
    //// Data Keys
    //public static inline var NODE_NAME_KEY : String = "name";
    //public static inline var NODE_STATUS_KEY : String = "unlockStatus";
    //
    //private var m_levelManager : ICgsLevelManager;
    //
    //private var m_unlockNodeName : String;
    //private var m_unlockStatus : String;
    //
    //public function new(levelManager : ICgsLevelManager)
    //{
        //m_levelManager = levelManager;
    //}
    //
    ///**
     //* @inheritDoc
     //*/
    //public function init(lockKeyData : Dynamic = null) : Void
    //{
        //if (lockKeyData == null) 
        //{
            //// Do nothing if no data provided
            //return;
        //}
        //
        //m_unlockNodeName = Reflect.field(lockKeyData, NODE_NAME_KEY);
        //m_unlockStatus = Reflect.field(lockKeyData, NODE_STATUS_KEY);
    //}
    //
    ///**
     //* @inheritDoc
     //*/
    //public function destroy() : Void
    //{
        //reset();
    //}
    //
    ///**
     //* @inheritDoc
     //*/
    //public function reset() : Void
    //{
        //m_unlockStatus = LevelNodeStatuses.PLAYED;
    //}
    //
    ///**
     //* @inheritDoc
     //*/
    //private function get_lockType() : String
    //{
        //return TYPE;
    //}
    //
    ///**
     //* @inheritDoc
     //*/
    //private function get_isLocked() : Bool
    //{
        //// Find the node we are locked on
        //var levelNode : ICgsLevelNode = m_levelManager.getNodeByName(m_unlockNodeName);
        //
        //// Check lock
        //var isLocked : Bool = (levelNode == null || !LevelNodeStatuses.getNodeMatchesStatus(levelNode, m_unlockStatus));
        //return isLocked;
    //}
    //
    ///**
     //* @inheritDoc
     //*/
    //public function doesKeyMatch(keyData : Dynamic) : Bool
    //{
        //return false;
    //}
}
