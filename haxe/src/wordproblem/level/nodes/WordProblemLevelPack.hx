package wordproblem.level.nodes;

import cgs.cache.ICgsUserCache;
import cgs.levelProgression.ICgsLevelManager;
import cgs.levelProgression.locks.ICgsLevelLock;
import cgs.levelProgression.nodes.ICgsLevelLeaf;
import cgs.levelProgression.nodes.ICgsLevelNode;
import cgs.levelProgression.nodes.ICgsLevelPack;
import cgs.levelProgression.util.ICgsLevelFactory;
import cgs.levelProgression.util.ICgsLockFactory;

import wordproblem.level.LevelNodeCompletionValues;
import wordproblem.level.LevelNodeSaveKeys;
import wordproblem.level.locks.NodeStatusLock;

/**
 * This class is another layer of grouping the levels.
 * 
 * Unlike chapter and genre, which are mostly just cosmetic to get the level select to appear, this node helps
 * group important subgraphs in the progression. For example all levels in a pack might be related
 * to a specific bar model subtype, regardless of what specific level they are in this pack once they finished x amount
 * of levels they should transition to another pack.
 * 
 * This pack provides a way to aggregate logic in the transitions to it is applied to all sub-levels in a pack, which
 * saves us having to specify edges for every individual node.
 */
class WordProblemLevelPack extends WordProblemLevelNode implements ICgsLevelPack
{
    private var cacheSaveName(get, never) : String;
    public var firstLeaf(get, never) : ICgsLevelLeaf;
    public var lastLeaf(get, never) : ICgsLevelLeaf;
    public var length(get, never) : Float;
    public var levelNames(get, never) : Array<String>;
    public var nodes(get, never) : Array<ICgsLevelNode>;
    public var nodeType(get, never) : String;
    public var numLevelLeafsCompleted(get, never) : Int;
    public var numLevelLeafsUncompleted(get, never) : Int;
    public var numLevelLeafsPlayed(get, never) : Int;
    public var numLevelLeafsUnplayed(get, never) : Int;
    public var numLevelLeafsLocked(get, never) : Int;
    public var numLevelLeafsUnlocked(get, never) : Int;
    public var numTotalLevelLeafs(get, never) : Int;
    public var numLevelPacksCompleted(get, never) : Int;
    public var numLevelPacksUncompleted(get, never) : Int;
    public var numLevelPacksFullyPlayed(get, never) : Int;
    public var numLevelPacksPlayed(get, never) : Int;
    public var numLevelPacksUnplayed(get, never) : Int;
    public var numLevelPacksLocked(get, never) : Int;
    public var numLevelPacksUnlocked(get, never) : Int;
    public var numTotalLevelPacks(get, never) : Int;
    public var isLocked(get, never) : Bool;
    public var isFullyPlayed(get, never) : Bool;

    public static inline var NODE_TYPE : String = "WordProblemLevelPack";
    
    /**
     * This is an extra blob of data inserted per genre or chapter containing extra information
     * needed to render various elements of the level select or parts of the game showing
     * descriptors of the level.
     * 
     * (TODO: Document the fields somewhere)
     */
    public var descriptionData : Dynamic;
    
    /**
     * When navigating to a level pack node without any extra information, we need to figure out what
     * leaf (which is an actual playable level) we should go to.
     * 
     * A selection policy is the action which determines this. 
     * (By defaultif this is null or an unknown value pick the first uncompleted level)
     */
    private var m_selectionPolicy : String;
    
    // Perma-State (only clear on destroy)
    private var m_levelFactory : ICgsLevelFactory;
    
    // Other State (clear on reset or destroy)
    private var m_levelData : Array<ICgsLevelNode>;
    private var m_packLocks : Array<ICgsLevelLock>;
    private var m_parent : ICgsLevelPack;
    
    public function new(levelManager : ICgsLevelManager,
            cache : ICgsUserCache,
            levelFactory : ICgsLevelFactory,
            lockFactory : ICgsLockFactory,
            nodeLabel : Int)
    {
        super(levelManager, cache, lockFactory, nodeLabel);
        m_levelFactory = levelFactory;
        m_levelData = new Array<ICgsLevelNode>();
        m_packLocks = new Array<ICgsLevelLock>();
    }
    
    /**
     * @inheritDoc
     */
    public function init(parent : ICgsLevelPack, prevLevel : ICgsLevelLeaf, data : Dynamic = null) : ICgsLevelLeaf
    {
        // If no data, do nothing
        if (data == null) 
        {
            return prevLevel;
        }
        
        parseCommonData(data);
        m_parent = parent;
        
        // First parse all the common data (all this code below is copied staight from common)
        // The reasone
        var node : ICgsLevelNode = null;
        var previousLevel : ICgsLevelLeaf = prevLevel;
        var previousNode : ICgsLevelNode = null;  // The first node created by the level pack will never need a previousNode since it is locked by the level pack  
        
        // Level Pack data
        var children : Array<Dynamic> = data.children;
        var lockArray : Array<Dynamic> = data.locks;
        
        // A level pack might want to apply the same set of locks to ALL direct children
        
        // One type is children are played in sequence, if children are laid out in a list
        // then a given child is only unlocked if the previous one has a certain status, like
        // it has been marked as complete
        var childSequenceLockStatusToUnlock : String = ((data.exists("addChildSequenceLocks"))) ? 
        data.addChildSequenceLocks : null;
        
        // One type is children are locked based on their own status. Like if the completion value
        // of the current node is not a specific value (which logic elsewhere would alter) then
        // it is locked.
        var childSelfStateLockStatusToUnlock : String = ((data.exists("addChildSelfStateLocks"))) ? 
        data.addChildSelfStateLocks : null;
        
        // A levelPack contains a list of levels or more levelPacks
        for (childNodeData in children)
        {
            // Add sequential locks, but not for the first node because it is unlocked by the level pack
            if (childSequenceLockStatusToUnlock != null && previousNode != null) 
            {
                // Add lock saying that the previous node needed to have a particular completion value
                // in order for this node to be treated as unlocked.
                var lockKey : Dynamic = { };
				Reflect.setField(lockKey, NodeStatusLock.NODE_NAME_KEY, previousNode.nodeName);
				Reflect.setField(lockKey, NodeStatusLock.NODE_STATUS_KEY, childSequenceLockStatusToUnlock);
                addLockToChildNodeData(childNodeData, NodeStatusLock.TYPE, lockKey);
            }  // Add a lock on the value of the child itself  
            
            
            
            if (childSelfStateLockStatusToUnlock != null) 
            {
                var lockKey : Dynamic = { };
				Reflect.setField(lockKey, NodeStatusLock.NODE_NAME_KEY, childNodeData.nodeName);
				Reflect.setField(lockKey, NodeStatusLock.NODE_STATUS_KEY, childSelfStateLockStatusToUnlock);
                addLockToChildNodeData(childNodeData, NodeStatusLock.TYPE, lockKey);
            }  // Create the node  
            
            
            
            var childNodeType : String = null;
            if (!childNodeData.exists("type")) 
            {
                // If a node has children it is a 'pack'
                if (childNodeData.exists("children")) 
                {
                    childNodeType = m_levelFactory.defaultLevelPackType;
                }
                // otherwise it is a 'leaf'
                else 
                {
                    childNodeType = m_levelFactory.defaultLevelType;
                }
            }
            else 
            {
                childNodeType = childNodeData.type;
            }
            node = m_levelFactory.getNodeInstance(childNodeType);
            
            // Save the newly created node and init it
            m_levelData.push(node);
            
            // Init the node
            previousLevel = node.init(this, previousLevel, childNodeData);
            
            // Set the previous node for the next loop
            previousNode = node;
        }  // Process locks for this level pack  
        
        
        
        for (lock in lockArray)
        {
            var lockType : String = Reflect.field(lock, "type");
            var levelLock : ICgsLevelLock = m_lockFactory.getLockInstance(lockType, lock);
            m_packLocks.push(levelLock);
        }  // Set the selection policy  
        
        
        
        if (data.exists("policy")) 
        {
            m_selectionPolicy = data.policy;
        }  // Set the extra data  
        
        
        
        if (data.exists("descriptionData")) 
        {
            this.descriptionData = data.descriptionData;
        }  // Level packs might store state. pull state if it exists  
        
        
        
        loadNodeFromCache(null);
        
        return previousLevel;
    }
    
    /**
     * Parent needs to be available because there are situations where we need to trace
     * up the layers of the progression graph
     */
    public function getParent() : ICgsLevelPack
    {
        return try cast(m_parent, ICgsLevelPack) catch(e:Dynamic) null;
    }
    
    /**
     * Get back how a level should be selected from this pack if we navigate to this node.
     */
    public function getSelectionPolicy() : String
    {
        return m_selectionPolicy;
    }
    
    public function loadNodeFromCache(userId : String) : Void
    {
        // Every pack gets set to a 'locked' value
        m_completionValue = LevelNodeCompletionValues.UNKNOWN;
        
        // Completion value of a pack might need to be read from save data
        // Read the saved data for a node if it exists.
        // If it doesn't default initial values are kept.
        if (m_cache != null && m_cache.saveExists(cacheSaveName) && m_cache.getSave(cacheSaveName) != null) 
        {
            // Save data is either a single number
            // OR an object with the original completion value and the high score
            // Everything should eventually move over to using the object
            var saveData : Dynamic = m_cache.getSave(cacheSaveName);
            m_completionValue = Reflect.field(saveData, LevelNodeSaveKeys.COMPLETION_VALUE);
        }
    }
    
    public function updateNode(nodeLabel : Int, data : Dynamic = null) : Bool
    {
        // Need override behavior of level pack update so it will save status value of the pack
        // Right now we only care about saving the completion status of the node
        // (Used for cases where we cannot calculate whether a pack is 'mastered' from state
        // of current nodes because mastery was based on completion of unknown set of child levels)
		var saveValuesChanged : Bool = false;
        if (nodeLabel == this.nodeLabel) 
        {
            var newCompletionValue : Int = Reflect.field(data, LevelNodeSaveKeys.COMPLETION_VALUE);
            saveValuesChanged = m_completionValue != newCompletionValue;
            
            if (saveValuesChanged && m_cache != null) 
            {
                m_completionValue = newCompletionValue;
                
                var newSaveData : Dynamic = { };
				Reflect.setField(newSaveData, LevelNodeSaveKeys.COMPLETION_VALUE, m_completionValue);
                m_cache.setSave(cacheSaveName, newSaveData, false);
            }
        }
        
        return saveValuesChanged;
    }
    
    /**
     * (prefix lp stands for level pack)
     */
    private function get_cacheSaveName() : String
    {
        return "lp_" + this.nodeName;
    }
    
    /**
     * We 'override' how default sequential locks are added to the system.
     * The reason is that the locks are by default unlocked when the previous level is played,
     * we want a level to be unlocked if a previous level has been completed
     */
    private function addLockToChildNodeData(childNodeData : Dynamic, lockType : String, lockKey : Dynamic) : Void
    {
        // Adds new lock to the json data for the locks
        lockKey.type = lockType;
        
        // Add locks if none exist
        if (!childNodeData.exists("locks")) 
        {
            Reflect.setField(childNodeData, "locks", new Array<Dynamic>());
        }
        var childLocks : Array<Dynamic> = Reflect.field(childNodeData, "locks");
        childLocks.push(lockKey);
    }
    
    /**
     * @inheritDoc
     */
    public function destroy() : Void
    {
        reset();
        
        // Null out perma-state
        m_levelManager = null;
        m_levelFactory = null;
        m_lockFactory = null;
        m_nodeLabel = -1;
        
        // Null out reset state
        m_levelData = null;
        m_packLocks = null;
    }
    
    /**
     * @inheritDoc
     */
    public function reset() : Void
    {
        while (m_levelData.length > 0)
        {
            var node : ICgsLevelNode = m_levelData.pop();
            m_levelFactory.recycleNodeInstance(node);
        }
        m_levelData = new Array<ICgsLevelNode>();
        m_name = "";
        while (m_packLocks.length > 0)
        {
            var lock : ICgsLevelLock = m_packLocks.pop();
            m_lockFactory.recycleLock(lock);
        }
        m_packLocks = new Array<ICgsLevelLock>();
        m_parent = null;
    }
    
    /**
     * @inheritDoc
     */
    private function get_firstLeaf() : ICgsLevelLeaf
    {
        var result : ICgsLevelLeaf = null;
        if (m_levelData.length > 0) 
        {
            var firstNode : ICgsLevelNode = m_levelData[0];
            if (Std.is(firstNode, ICgsLevelLeaf)) 
            {
                result = try cast(firstNode, ICgsLevelLeaf) catch(e:Dynamic) null;
            }
            else if (Std.is(firstNode, ICgsLevelPack)) 
            {
                result = (try cast(firstNode, ICgsLevelPack) catch(e:Dynamic) null).firstLeaf;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_lastLeaf() : ICgsLevelLeaf
    {
        var result : ICgsLevelLeaf = null;
        if (m_levelData.length > 0) 
        {
            var lastNode : ICgsLevelNode = m_levelData[m_levelData.length - 1];
            if (Std.is(lastNode, ICgsLevelLeaf)) 
            {
                result = try cast(lastNode, ICgsLevelLeaf) catch(e:Dynamic) null;
            }
            else if (Std.is(lastNode, ICgsLevelPack)) 
            {
                result = (try cast(lastNode, ICgsLevelPack) catch(e:Dynamic) null).lastLeaf;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_length() : Float
    {
        return m_levelData.length;
    }
    
    /**
     * @inheritDoc
     */
    private function get_levelNames() : Array<String>
    {
        var result : Array<String> = new Array<String>();
        
        // Collect the names of our children
        for (node in nodes)
        {
            if (Std.is(node, ICgsLevelPack)) 
            {
                result = result.concat((try cast(node, ICgsLevelPack) catch(e:Dynamic) null).levelNames);
            }
            else if (Std.is(node, ICgsLevelLeaf)) 
            {
                result.push(node.nodeName);
            }
        }
        
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_nodes() : Array<ICgsLevelNode>
    {
        return m_levelData;
    }
    
    /**
     * @inheritDoc
     */
    private function get_nodeType() : String
    {
        return WordProblemLevelPack.NODE_TYPE;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsCompleted() : Int
    {
        var result : Int = 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelLeafsCompleted;
            }
            else if (Std.is(childNode, ICgsLevelLeaf) && (try cast(childNode, ICgsLevelLeaf) catch(e:Dynamic) null).isComplete) 
            {
                result++;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsUncompleted() : Int
    {
        var result : Int = 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelLeafsUncompleted;
            }
            else if (Std.is(childNode, ICgsLevelLeaf) && !(try cast(childNode, ICgsLevelLeaf) catch(e:Dynamic) null).isComplete) 
            {
                result++;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsPlayed() : Int
    {
        var result : Int = 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelLeafsPlayed;
            }
            else if (Std.is(childNode, ICgsLevelLeaf) && (try cast(childNode, ICgsLevelLeaf) catch(e:Dynamic) null).isPlayed) 
            {
                result++;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsUnplayed() : Int
    {
        var result : Int = 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelLeafsUnplayed;
            }
            else if (Std.is(childNode, ICgsLevelLeaf) && !(try cast(childNode, ICgsLevelLeaf) catch(e:Dynamic) null).isPlayed) 
            {
                result++;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsLocked() : Int
    {
        var result : Int = 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelLeafsLocked;
            }
            else if (Std.is(childNode, ICgsLevelLeaf) && (try cast(childNode, ICgsLevelLeaf) catch(e:Dynamic) null).isLocked) 
            {
                result++;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsUnlocked() : Int
    {
        var result : Int = 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelLeafsUnlocked;
            }
            else if (Std.is(childNode, ICgsLevelLeaf) && !(try cast(childNode, ICgsLevelLeaf) catch(e:Dynamic) null).isLocked) 
            {
                result++;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numTotalLevelLeafs() : Int
    {
        var result : Int = 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numTotalLevelLeafs;
            }
            else if (Std.is(childNode, ICgsLevelLeaf)) 
            {
                result++;
            }
        }
        return result;
    }
    
    /**
     * 
     * Level Pack Status State
     * 
     **/
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksCompleted() : Int
    {
        // Dont forget self
        var result : Int = (isComplete) ? 1 : 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelPacksCompleted;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksUncompleted() : Int
    {
        // Dont forget self
        var result : Int = !(isComplete) ? 1 : 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelPacksUncompleted;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksFullyPlayed() : Int
    {
        // Dont forget self
        var result : Int = (isFullyPlayed) ? 1 : 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelPacksFullyPlayed;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksPlayed() : Int
    {
        // Dont forget self
        var result : Int = (isPlayed) ? 1 : 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelPacksPlayed;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksUnplayed() : Int
    {
        // Dont forget self
        var result : Int = !(isPlayed) ? 1 : 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelPacksUnplayed;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksLocked() : Int
    {
        // Dont forget self
        var result : Int = (isLocked) ? 1 : 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelPacksLocked;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksUnlocked() : Int
    {
        // Dont forget self
        var result : Int = !(isLocked) ? 1 : 0;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numLevelPacksUnlocked;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numTotalLevelPacks() : Int
    {
        // Dont forget self
        var result : Int = 1;
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result += (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).numTotalLevelPacks;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_isLocked() : Bool
    {
        var result : Bool = false;
        if (m_levelManager.doCheckLocks) 
        {
            result = m_parent != null && m_parent.isLocked;
            for (aLock in m_packLocks)
            {
                result = result || aLock.isLocked;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    private function get_isFullyPlayed() : Bool
    {
        var result : Bool = true;
        for (childNode in m_levelData)
        {
            // All children need to have been played to be "fully" played
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                result = result && (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).isFullyPlayed;
            }
            else if (Std.is(childNode, ICgsLevelLeaf)) 
            {
                result = result && childNode.isPlayed;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsComplete() : Void
    {
        markAllLevelLeafsAsCompletionValue(m_levelManager.isCompleteCompletionValue);
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsPlayed() : Void
    {
        markAllLevelLeafsAsCompletionValue(0);
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsUnplayed() : Void
    {
        markAllLevelLeafsAsCompletionValue(-1);
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsCompletionValue(value : Float) : Void
    {
        for (childNode in m_levelData)
        {
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                (try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null).markAllLevelLeafsAsCompletionValue(value);
            }
            else if (Std.is(childNode, ICgsLevelLeaf)) 
            {
                markLevelLeafAsCompletionValue((try cast(childNode, ICgsLevelLeaf) catch(e:Dynamic) null), value);
            }
        }
    }
    
    /**
     * Marks the given level leaf with the given completion value.
     * @param	nodeLabel - The level leaf to marked with the given value.
     * @param	value - The completion value to be assigned.
     */
    private function markLevelLeafAsCompletionValue(levelLeaf : ICgsLevelLeaf, value : Float) : Void
    {
        var data : Dynamic = { };
		Reflect.setField(data, LevelNodeSaveKeys.COMPLETION_VALUE, value);
        levelLeaf.updateNode(levelLeaf.nodeLabel, data);
    }
    
    /**
     * @inheritDoc
     */
    public function addLock(lockType : String, keyData : Dynamic) : Bool
    {
        // Do nothing if no lock type given
        if (lockType == null || lockType == "") 
        {
            return false;
        }
        
        var aLock : ICgsLevelLock = m_lockFactory.getLockInstance(lockType, keyData);
        m_packLocks.push(aLock);
        return true;
    }
    
    /**
     * @inheritDoc
     */
    public function hasLock(lockType : String, keyData : Dynamic) : Bool
    {
        var result : Bool = false;
        for (lock in m_packLocks)
        {
            if (lock.lockType == lockType && lock.doesKeyMatch(keyData)) 
            {
                result = true;
                break;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function editLock(lockType : String, oldKeyData : Dynamic, newKeyData : Dynamic) : Bool
    {
        var result : Bool = false;
        if (removeLock(lockType, oldKeyData)) 
        {
            addLock(lockType, newKeyData);
            result = true;
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function removeLock(lockType : String, keyData : Dynamic) : Bool
    {
        var result : Bool = false;
        for (lock in m_packLocks)
        {
            if (lock.lockType == lockType && lock.doesKeyMatch(keyData)) 
            {
                m_packLocks.splice(Lambda.indexOf(m_packLocks, lock), 1);
                m_lockFactory.recycleLock(lock);
                result = true;
                break;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function containsNode(nodeLabel : Int) : Bool
    {
        // Check if we are the desired node
        if (m_nodeLabel == nodeLabel) 
            return true;  // Check if the desired node is one of our children
        
        
        
        var result : Bool = false;
        for (i in 0...m_levelData.length){
            result = m_levelData[i].containsNode(nodeLabel);
            if (result) 
                break;
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function getNode(nodeLabel : Int) : ICgsLevelNode
    {
        // Check if we are the desired node
        if (m_nodeLabel == nodeLabel) 
            return this;  // Check if the desired node is one of our children
        
        
        
        var result : ICgsLevelNode = null;
        for (i in 0...m_levelData.length){
            result = m_levelData[i].getNode(nodeLabel);
            if (result != null) 
                break;
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function getNodeByName(nodeName : String) : ICgsLevelNode
    {
        // Check if we are the desired node
        if (m_name == nodeName) 
            return this;  // Check if the desired node is one of our children
        
        
        
        var result : ICgsLevelNode = null;
        for (i in 0...m_levelData.length){
            result = m_levelData[i].getNodeByName(nodeName);
            if (result != null) 
                break;
        }
        return result;
    }
    
    public function addNodeToProgression(nodeData : Dynamic, parentPackName : String = null, index : Int = -1) : Bool
    {
        return false;
    }
    
    public function editNodeInProgression(nameOfNode : String, newNodeData : Dynamic) : Bool
    {
        return false;
    }
    
    public function removeNodeFromProgression(nodeName : String) : Bool
    {
        return false;
    }
    
    /**
     * @inheritDoc
     */
    public function getNextLevel(aNodeLabel : Int = -1) : ICgsLevelLeaf
    {
        var result : ICgsLevelLeaf = null;
        
        // Find the node with the given label, get the level that comes after it (if any).
        if (aNodeLabel >= 0) 
        {
            // Recursively search for the node and get the level that comes after it
            for (node in nodes)
            {
                // We contain the node, time to find the next node and get the level from it
                if (node.nodeLabel == aNodeLabel) 
                {
                    var nodeIndex : Int = Lambda.indexOf(nodes, node);
                    
                    // We do not contain the next node
                    if (nodeIndex == nodes.length - 1) 
                    {
                        // We do not contain the level that comes after the desired node, so check our parent for it
                        if (m_parent != null) 
                        {
                            result = m_parent.getNextLevel(nodeLabel);
                        }
                    }
                    // We contain the next node
                    else 
                    {
                        var nextNode : ICgsLevelNode = nodes[nodeIndex + 1];
                        if (Std.is(nextNode, ICgsLevelPack)) 
                        {
                            // The next node is a level pack, get the first leaf
                            result = (try cast(nextNode, ICgsLevelPack) catch(e:Dynamic) null).firstLeaf;
                        }
                        else if (Std.is(nextNode, ICgsLevelLeaf)) 
                        {
                            // The next node is a leaf, return it
                            result = try cast(nextNode, ICgsLevelLeaf) catch(e:Dynamic) null;
                        }
                    }  // We found the node we want the next level for, no more searching needed  
                    
                    
                    
                    break;
                }
                else if (Std.is(node, ICgsLevelPack)) 
                {
                    // Recursive case
                    result = (try cast(node, ICgsLevelPack) catch(e:Dynamic) null).getNextLevel(aNodeLabel);
                    if (result != null) 
                    {
                        break;
                    }
                }
            }
        }
        
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function getPrevLevel(aNodeLabel : Int = -1) : ICgsLevelLeaf
    {
        var result : ICgsLevelLeaf = null;
        
        // Find the node with the given label, get the level that comes before it (if any).
        if (aNodeLabel >= 0) 
        {
            // Recursively search for the node and get the level that comes before it
            for (node in nodes)
            {
                // We contain the node, time to find the next node and get the level from it
                if (node.nodeLabel == aNodeLabel) 
                {
                    var nodeIndex : Int = Lambda.indexOf(nodes, node);
                    
                    // We do not contain the previous node
                    if (nodeIndex == 0) 
                    {
                        // We do not contain the level that comes before the desired node, so check our parent for it
                        if (m_parent != null) 
                        {
                            result = m_parent.getPrevLevel(nodeLabel);
                        }
                    }
                    // We contain the previous node
                    else 
                    {
                        var previousNode : ICgsLevelNode = nodes[nodeIndex - 1];
                        if (Std.is(previousNode, ICgsLevelPack)) 
                        {
                            // The previous node is a level pack, get the last leaf
                            result = (try cast(previousNode, ICgsLevelPack) catch(e:Dynamic) null).lastLeaf;
                        }
                        else if (Std.is(previousNode, ICgsLevelLeaf)) 
                        {
                            // The previous node is a leaf, return it
                            result = try cast(previousNode, ICgsLevelLeaf) catch(e:Dynamic) null;
                        }
                    }  // We found the node we want the next level for, no more searching needed  
                    
                    
                    
                    break;
                }
                else if (Std.is(node, ICgsLevelPack)) 
                {
                    // Recursive case
                    result = (try cast(node, ICgsLevelPack) catch(e:Dynamic) null).getPrevLevel(aNodeLabel);
                    if (result != null) 
                    {
                        break;
                    }
                }
            }
        }
        
        return result;
    }
}
