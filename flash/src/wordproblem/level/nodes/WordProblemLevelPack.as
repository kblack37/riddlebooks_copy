package wordproblem.level.nodes
{
    import cgs.Cache.ICgsUserCache;
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
    public class WordProblemLevelPack extends WordProblemLevelNode implements ICgsLevelPack
    {
        public static const NODE_TYPE:String = "WordProblemLevelPack";
        
        /**
         * This is an extra blob of data inserted per genre or chapter containing extra information
         * needed to render various elements of the level select or parts of the game showing
         * descriptors of the level.
         * 
         * (TODO: Document the fields somewhere)
         */
        public var descriptionData:Object;
        
        /**
         * When navigating to a level pack node without any extra information, we need to figure out what
         * leaf (which is an actual playable level) we should go to.
         * 
         * A selection policy is the action which determines this. 
         * (By defaultif this is null or an unknown value pick the first uncompleted level)
         */
        private var m_selectionPolicy:String;
        
        // Perma-State (only clear on destroy)
        protected var m_levelFactory:ICgsLevelFactory;
        
        // Other State (clear on reset or destroy)
        protected var m_levelData:Vector.<ICgsLevelNode>;
        protected var m_packLocks:Vector.<ICgsLevelLock>;
        protected var m_parent:ICgsLevelPack;
        
        public function WordProblemLevelPack(levelManager:ICgsLevelManager,
                                             cache:ICgsUserCache,
                                             levelFactory:ICgsLevelFactory, 
                                             lockFactory:ICgsLockFactory, 
                                             nodeLabel:int)
        {
            super(levelManager, cache, lockFactory, nodeLabel);
            m_levelFactory = levelFactory;
            m_levelData = new Vector.<ICgsLevelNode>();
            m_packLocks = new Vector.<ICgsLevelLock>();
        }
        
        /**
         * @inheritDoc
         */
        public function init(parent:ICgsLevelPack, prevLevel:ICgsLevelLeaf, data:Object = null):ICgsLevelLeaf
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
            var node:ICgsLevelNode;
            var previousLevel:ICgsLevelLeaf = prevLevel;
            var previousNode:ICgsLevelNode = null;	// The first node created by the level pack will never need a previousNode since it is locked by the level pack
            
            // Level Pack data
            var children:Array = data.children;
            var lockArray:Array = data.locks;
            
            // A level pack might want to apply the same set of locks to ALL direct children
            
            // One type is children are played in sequence, if children are laid out in a list
            // then a given child is only unlocked if the previous one has a certain status, like
            // it has been marked as complete
            var childSequenceLockStatusToUnlock:String = (data.hasOwnProperty("addChildSequenceLocks")) ?
                data.addChildSequenceLocks : null;
            
            // One type is children are locked based on their own status. Like if the completion value
            // of the current node is not a specific value (which logic elsewhere would alter) then
            // it is locked.
            var childSelfStateLockStatusToUnlock:String = (data.hasOwnProperty("addChildSelfStateLocks")) ?
                data.addChildSelfStateLocks : null;
            
            // A levelPack contains a list of levels or more levelPacks
            for each (var childNodeData:Object in children)
            {
                // Add sequential locks, but not for the first node because it is unlocked by the level pack
                if (childSequenceLockStatusToUnlock != null && previousNode != null)
                {
                    // Add lock saying that the previous node needed to have a particular completion value
                    // in order for this node to be treated as unlocked.
                    var lockKey:Object = {};
                    lockKey[NodeStatusLock.NODE_NAME_KEY] = previousNode.nodeName;
                    lockKey[NodeStatusLock.NODE_STATUS_KEY] = childSequenceLockStatusToUnlock;
                    addLockToChildNodeData(childNodeData, NodeStatusLock.TYPE, lockKey);
                }
                
                // Add a lock on the value of the child itself
                if (childSelfStateLockStatusToUnlock != null)
                {
                    lockKey = {};
                    lockKey[NodeStatusLock.NODE_NAME_KEY] = childNodeData.name;
                    lockKey[NodeStatusLock.NODE_STATUS_KEY] = childSelfStateLockStatusToUnlock;
                    addLockToChildNodeData(childNodeData, NodeStatusLock.TYPE, lockKey);
                }
                
                // Create the node
                var childNodeType:String = null;
                if (!childNodeData.hasOwnProperty("type"))
                {
                    // If a node has children it is a 'pack'
                    if (childNodeData.hasOwnProperty("children"))
                    {
                        childNodeType = m_levelFactory.defaultLevelPackType;
                    }
                    // otherwise it is a 'leaf'
                    else
                    {
                        childNodeType =  m_levelFactory.defaultLevelType;
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
            }
            
            // Process locks for this level pack
            for each (var lock:Object in lockArray)
            {
                var lockType:String = lock["type"];
                var levelLock:ICgsLevelLock = m_lockFactory.getLockInstance(lockType, lock);
                m_packLocks.push(levelLock);
            }
            
            // Set the selection policy
            if (data.hasOwnProperty("policy"))
            {
                m_selectionPolicy = data.policy;
            }
            
            // Set the extra data
            if (data.hasOwnProperty("descriptionData"))
            {
                this.descriptionData = data.descriptionData;
            }
            
            // Level packs might store state. pull state if it exists
            loadNodeFromCache(null);
            
            return previousLevel;
        }
        
        /**
         * Parent needs to be available because there are situations where we need to trace
         * up the layers of the progression graph
         */
        public function getParent():ICgsLevelPack
        {
            return m_parent as ICgsLevelPack;
        }
        
        /**
         * Get back how a level should be selected from this pack if we navigate to this node.
         */
        public function getSelectionPolicy():String
        {
            return m_selectionPolicy;
        }
        
        public function loadNodeFromCache(userId:String):void
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
                var saveData:Object = m_cache.getSave(cacheSaveName);
                m_completionValue = saveData[LevelNodeSaveKeys.COMPLETION_VALUE];
            }
        }
        
        public function updateNode(nodeLabel:int, data:Object=null):Boolean
        {
            // Need override behavior of level pack update so it will save status value of the pack
            // Right now we only care about saving the completion status of the node
            // (Used for cases where we cannot calculate whether a pack is 'mastered' from state
            // of current nodes because mastery was based on completion of unknown set of child levels)
            if (nodeLabel == this.nodeLabel)
            {
                var newCompletionValue:int = data[LevelNodeSaveKeys.COMPLETION_VALUE];
                var saveValuesChanged:Boolean = m_completionValue != newCompletionValue;
                
                if (saveValuesChanged && m_cache != null)
                {
                    m_completionValue = newCompletionValue;
                    
                    var newSaveData:Object = {};
                    newSaveData[LevelNodeSaveKeys.COMPLETION_VALUE] = m_completionValue;
                    m_cache.setSave(cacheSaveName, newSaveData, false);
                }
            }
            
            return saveValuesChanged;
        }

        /**
         * (prefix lp stands for level pack)
         */
        private function get cacheSaveName():String
        {
            return "lp_" + this.nodeName;
        }
        
        /**
         * We 'override' how default sequential locks are added to the system.
         * The reason is that the locks are by default unlocked when the previous level is played,
         * we want a level to be unlocked if a previous level has been completed
         */
        private function addLockToChildNodeData(childNodeData:Object, lockType:String, lockKey:Object):void
        {
            // Adds new lock to the json data for the locks
            lockKey.type = lockType;
            
            // Add locks if none exist
            if (!childNodeData.hasOwnProperty("locks"))
            {
                childNodeData["locks"] = new Array();
            }
            var childLocks:Array = childNodeData["locks"] as Array;
            childLocks.push(lockKey);
        }
        
        /**
         * @inheritDoc
         */
        public function destroy():void
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
            
            super.destroy();
        }
        
        /**
         * @inheritDoc
         */
        public function reset():void
        {
            while (m_levelData.length > 0)
            {
                var node:ICgsLevelNode = m_levelData.pop();
                m_levelFactory.recycleNodeInstance(node);
            }
            m_levelData = new Vector.<ICgsLevelNode>();
            m_name = ""
            while (m_packLocks.length > 0)
            {
                var lock:ICgsLevelLock = m_packLocks.pop();
                m_lockFactory.recycleLock(lock);
            }
            m_packLocks = new Vector.<ICgsLevelLock>();
            m_parent = null;
        }
        
        /**
         * @inheritDoc
         */
        public function get firstLeaf():ICgsLevelLeaf
        {
            var result:ICgsLevelLeaf;
            if (m_levelData.length > 0)
            {
                var firstNode:ICgsLevelNode = m_levelData[0];
                if (firstNode is ICgsLevelLeaf)
                {
                    result = firstNode as ICgsLevelLeaf;
                }
                else if (firstNode is ICgsLevelPack)
                {
                    result = (firstNode as ICgsLevelPack).firstLeaf
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get lastLeaf():ICgsLevelLeaf
        {
            var result:ICgsLevelLeaf;
            if (m_levelData.length > 0)
            {
                var lastNode:ICgsLevelNode = m_levelData[m_levelData.length - 1];
                if (lastNode is ICgsLevelLeaf)
                {
                    result = lastNode as ICgsLevelLeaf;
                }
                else if (lastNode is ICgsLevelPack)
                {
                    result = (lastNode as ICgsLevelPack).lastLeaf
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get length():Number 
        {
            return m_levelData.length;
        }
        
        /**
         * @inheritDoc
         */
        public function get levelNames():Vector.<String> 
        {
            var result:Vector.<String> = new Vector.<String>();
            
            // Collect the names of our children
            for each (var node:ICgsLevelNode in nodes) 
            {
                if (node is ICgsLevelPack)
                {
                    result = result.concat((node as ICgsLevelPack).levelNames);
                }
                else if (node is ICgsLevelLeaf)
                {
                    result.push(node.nodeName);
                }
            }
            
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get nodes():Vector.<ICgsLevelNode>
        {
            return m_levelData;
        }
        
        /**
         * @inheritDoc
         */
        public function get nodeType():String 
        {
            return WordProblemLevelPack.NODE_TYPE;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsCompleted():int
        {
            var result:Number = 0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelLeafsCompleted;
                }
                else if (childNode is ICgsLevelLeaf && (childNode as ICgsLevelLeaf).isComplete)
                {
                    result++;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsUncompleted():int
        {
            var result:Number = 0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelLeafsUncompleted;
                }
                else if (childNode is ICgsLevelLeaf && !(childNode as ICgsLevelLeaf).isComplete)
                {
                    result++;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsPlayed():int
        {
            var result:Number = 0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelLeafsPlayed;
                }
                else if (childNode is ICgsLevelLeaf && (childNode as ICgsLevelLeaf).isPlayed)
                {
                    result++;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsUnplayed():int
        {
            var result:Number = 0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelLeafsUnplayed;
                }
                else if (childNode is ICgsLevelLeaf && !(childNode as ICgsLevelLeaf).isPlayed)
                {
                    result++;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsLocked():int
        {
            var result:Number = 0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelLeafsLocked;
                }
                else if (childNode is ICgsLevelLeaf && (childNode as ICgsLevelLeaf).isLocked)
                {
                    result++;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsUnlocked():int
        {
            var result:Number = 0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelLeafsUnlocked;
                }
                else if (childNode is ICgsLevelLeaf && !(childNode as ICgsLevelLeaf).isLocked)
                {
                    result++;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numTotalLevelLeafs():int
        {
            var result:Number = 0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numTotalLevelLeafs;
                }
                else if (childNode is ICgsLevelLeaf)
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
        public function get numLevelPacksCompleted():int
        {
            // Dont forget self
            var result:Number = isComplete?1:0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelPacksCompleted;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksUncompleted():int
        {
            // Dont forget self
            var result:Number = !isComplete?1:0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelPacksUncompleted;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksFullyPlayed():int
        {
            // Dont forget self
            var result:Number = isFullyPlayed?1:0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelPacksFullyPlayed;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksPlayed():int
        {
            // Dont forget self
            var result:Number = isPlayed?1:0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelPacksPlayed;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksUnplayed():int
        {
            // Dont forget self
            var result:Number = !isPlayed?1:0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelPacksUnplayed;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksLocked():int
        {
            // Dont forget self
            var result:Number = isLocked?1:0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelPacksLocked;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksUnlocked():int
        {
            // Dont forget self
            var result:Number = !isLocked?1:0;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numLevelPacksUnlocked;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get numTotalLevelPacks():int
        {
            // Dont forget self
            var result:Number = 1;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    result += (childNode as ICgsLevelPack).numTotalLevelPacks;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get isLocked():Boolean
        {
            var result:Boolean = false;
            if (m_levelManager.doCheckLocks)
            {
                result = m_parent != null && m_parent.isLocked;
                for each (var aLock:ICgsLevelLock in m_packLocks)
                {
                    result = result || aLock.isLocked;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function get isFullyPlayed():Boolean 
        {
            var result:Boolean = true;
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                // All children need to have been played to be "fully" played
                if (childNode is ICgsLevelPack)
                {
                    result = result && (childNode as ICgsLevelPack).isFullyPlayed;
                }
                else if (childNode is ICgsLevelLeaf)
                {
                    result = result && childNode.isPlayed;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsComplete():void
        {
            markAllLevelLeafsAsCompletionValue(m_levelManager.isCompleteCompletionValue);
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsPlayed():void
        {
            markAllLevelLeafsAsCompletionValue(0);
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsUnplayed():void
        {
            markAllLevelLeafsAsCompletionValue(-1);
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsCompletionValue(value:Number):void
        {
            for each(var childNode:ICgsLevelNode in m_levelData)
            {
                if (childNode is ICgsLevelPack)
                {
                    (childNode as ICgsLevelPack).markAllLevelLeafsAsCompletionValue(value);
                }
                else if (childNode is ICgsLevelLeaf)
                {
                    markLevelLeafAsCompletionValue((childNode as ICgsLevelLeaf), value);
                }
            }
        }
        
        /**
         * Marks the given level leaf with the given completion value.
         * @param	nodeLabel - The level leaf to marked with the given value.
         * @param	value - The completion value to be assigned.
         */
        protected function markLevelLeafAsCompletionValue(levelLeaf:ICgsLevelLeaf, value:Number):void
        {
            var data:Object = new Object();
            data[LevelNodeSaveKeys.COMPLETION_VALUE] = value;
            levelLeaf.updateNode(levelLeaf.nodeLabel, data);
        }
        
        /**
         * @inheritDoc
         */
        public function addLock(lockType:String, keyData:Object):Boolean
        {
            // Do nothing if no lock type given
            if (lockType == null || lockType == "")
            {
                return false;
            }
            
            var aLock:ICgsLevelLock = m_lockFactory.getLockInstance(lockType, keyData);
            m_packLocks.push(aLock);
            return true;
        }
        
        /**
         * @inheritDoc
         */
        public function hasLock(lockType:String, keyData:Object):Boolean
        {
            var result:Boolean;
            for each (var lock:ICgsLevelLock in m_packLocks)
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
        public function editLock(lockType:String, oldKeyData:Object, newKeyData:Object):Boolean
        {
            var result:Boolean;
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
        public function removeLock(lockType:String, keyData:Object):Boolean
        {
            var result:Boolean;
            for each (var lock:ICgsLevelLock in m_packLocks)
            {
                if (lock.lockType == lockType && lock.doesKeyMatch(keyData))
                {
                    m_packLocks.splice(m_packLocks.indexOf(lock), 1);
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
        public function containsNode(nodeLabel:int):Boolean
        {
            // Check if we are the desired node
            if (m_nodeLabel == nodeLabel)
                return true;
            
            // Check if the desired node is one of our children
            var result:Boolean = false;
            for (var i:int = 0; i < m_levelData.length; i++) 
            {
                result = m_levelData[i].containsNode(nodeLabel);
                if (result)
                    break;
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function getNode(nodeLabel:int):ICgsLevelNode
        {
            // Check if we are the desired node
            if (m_nodeLabel == nodeLabel)
                return this;
            
            // Check if the desired node is one of our children
            var result:ICgsLevelNode = null;
            for (var i:int = 0; i < m_levelData.length; i++) 
            {
                result = m_levelData[i].getNode(nodeLabel);
                if (result)
                    break;
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function getNodeByName(nodeName:String):ICgsLevelNode
        {
            // Check if we are the desired node
            if (m_name == nodeName)
                return this;
            
            // Check if the desired node is one of our children
            var result:ICgsLevelNode = null;
            for (var i:int = 0; i < m_levelData.length; i++) 
            {
                result = m_levelData[i].getNodeByName(nodeName);
                if (result)
                    break;
            }
            return result;
        }
        
        public function addNodeToProgression(nodeData:Object, parentPackName:String = null, index:int = -1):Boolean
        {
            return false;
        }
        
        public function editNodeInProgression(nameOfNode:String, newNodeData:Object):Boolean
        {
            return false;
        }
        
        public function removeNodeFromProgression(nodeName:String):Boolean
        {
            return false;
        }
        
        /**
         * @inheritDoc
         */
        public function getNextLevel(aNodeLabel:int = -1):ICgsLevelLeaf
        {
            var result:ICgsLevelLeaf;
            
            // Find the node with the given label, get the level that comes after it (if any).
            if (aNodeLabel >= 0)
            {
                // Recursively search for the node and get the level that comes after it
                for each (var node:ICgsLevelNode in nodes)
                {
                    // We contain the node, time to find the next node and get the level from it
                    if (node.nodeLabel == aNodeLabel)
                    {
                        var nodeIndex:int = nodes.indexOf(node);
                        
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
                            var nextNode:ICgsLevelNode = nodes[nodeIndex + 1];
                            if (nextNode is ICgsLevelPack)
                            {
                                // The next node is a level pack, get the first leaf
                                result = (nextNode as ICgsLevelPack).firstLeaf;
                            }
                            else if (nextNode is ICgsLevelLeaf)
                            {
                                // The next node is a leaf, return it
                                result = nextNode as ICgsLevelLeaf;
                            }
                        }
                        
                        // We found the node we want the next level for, no more searching needed
                        break;
                    }
                    else if (node is ICgsLevelPack)
                    {
                        // Recursive case
                        result = (node as ICgsLevelPack).getNextLevel(aNodeLabel);
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
        public function getPrevLevel(aNodeLabel:int = -1):ICgsLevelLeaf
        {
            var result:ICgsLevelLeaf;
            
            // Find the node with the given label, get the level that comes before it (if any).
            if (aNodeLabel >= 0)
            {
                // Recursively search for the node and get the level that comes before it
                for each (var node:ICgsLevelNode in nodes)
                {
                    // We contain the node, time to find the next node and get the level from it
                    if (node.nodeLabel == aNodeLabel)
                    {
                        var nodeIndex:int = nodes.indexOf(node);
                        
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
                            var previousNode:ICgsLevelNode = nodes[nodeIndex - 1];
                            if (previousNode is ICgsLevelPack)
                            {
                                // The previous node is a level pack, get the last leaf
                                result = (previousNode as ICgsLevelPack).lastLeaf;
                            }
                            else if (previousNode is ICgsLevelLeaf)
                            {
                                // The previous node is a leaf, return it
                                result = previousNode as ICgsLevelLeaf;
                            }
                        }
                        
                        // We found the node we want the next level for, no more searching needed
                        break;
                    }
                    else if (node is ICgsLevelPack)
                    {
                        // Recursive case
                        result = (node as ICgsLevelPack).getPrevLevel(aNodeLabel);
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
}