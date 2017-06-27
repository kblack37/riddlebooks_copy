package wordproblem.level.nodes
{
    import cgs.Cache.ICgsUserCache;
    import cgs.levelProgression.ICgsLevelManager;
    import cgs.levelProgression.locks.ICgsLevelLock;
    import cgs.levelProgression.nodes.ICgsLevelLeaf;
    import cgs.levelProgression.nodes.ICgsLevelNode;
    import cgs.levelProgression.nodes.ICgsLevelPack;
    import cgs.levelProgression.nodes.ICgsStatusNode;
    import cgs.levelProgression.util.ICgsLockFactory;
    
    import dragonbox.common.util.XString;
    
    import wordproblem.level.LevelNodeCompletionValues;
    import wordproblem.level.LevelNodeSaveKeys;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    
    /**
     * By extending the existing leaf node class we have more control over the type and
     * data stored in the node and how that data is read and stored.
     * 
     * One of the primary benefits is that during the testing phase we can bypass the
     * use of the player cache and keep save data in a local object.
     * 
     * IMPORTANT: This leaf inherits a field called m_completionValue which serves as the status
     * counter for how far the player is from completing this node. By default, any value less than zero
     * means it is locked and was never played. Any non-negative values indicate it should be playable, but
     * whether it is formally complete depends on a threshold value set in the CGSLevelManager class.
     */
    public class WordProblemLevelLeaf extends WordProblemLevelNode implements ICgsLevelLeaf
    {
        public static const NODE_TYPE:String = "WordProblemLevelLeaf";
        
        /**
         * Get back the genre that contains this leaf (set after construction)
         * 
         * @return
         *      null if this level is not attached to any GenreLevelPack
         */
        public var parentGenreLevelPack:GenreLevelPack;
        
        /**
         * Get back the chapter that contains this leaf (set after construction)
         * 
         * @return
         *      null if this level is not attached to any ChapterLevelPack
         */
        public var parentChapterLevelPack:ChapterLevelPack;
        
        /**
         * A zero based index of where this level lies either within a chapter or genre.
         */
        public var index:int = -1;
        
        /**
         * Internally keep track of the maximum score the player has ever earned for this level.
         * High score value determines how well the student performed.
         */
        private var m_highScore:int;
        
        /**
         * Serialized format of the progress or best performance for a player in this particular level
         */
        private var m_serializedObjectives:Object;
        
        private var m_serializedPerformanceState:Object;
        
        // Other State (clear on reset or destroy)
        
        protected var m_fileName:String;
        protected var m_saveName:String;
        protected var m_levelLocks:Vector.<ICgsLevelLock>;
        protected var m_previousLevel:ICgsLevelLeaf;
        
        /**
         * The next level is really determined by how things are organized in the json file.
         * (Has nothing to do with the edge graph)
         */
        protected var m_nextLevel:ICgsLevelLeaf;
        protected var m_parent:ICgsStatusNode;
        
        private var m_skippable:Boolean;
        private var m_isProblemCreate:Boolean;
        
        public function WordProblemLevelLeaf(levelManager:ICgsLevelManager, 
                                             cache:ICgsUserCache,
                                             lockFactory:ICgsLockFactory, 
                                             nodeLabel:int)
        {
            super(levelManager, cache, lockFactory, nodeLabel);
            
            m_levelLocks = new Vector.<ICgsLevelLock>();
            m_skippable = true;
            m_isProblemCreate = false;
            m_serializedPerformanceState = null;
        }
        
        public function init(parent:ICgsLevelPack, prevLevel:ICgsLevelLeaf, data:Object = null):ICgsLevelLeaf
        {
            // Do nothing if no data provided
            if (data != null)
            {
                parseCommonData(data);
                
                // Save references to other objects
                m_parent = parent;
                
                // Init from data
                m_previousLevel = prevLevel;
                if (m_previousLevel != null)
                {
                    m_previousLevel.nextLevel = this;
                }
                
                // Get the name
                m_fileName = data.fileName;
                
                // get the level name, which defaults to file name if no level name is provided
                if(m_name == null || m_name == "")
                {
                    m_name = m_fileName;
                }
                
                // Get the save name, which defaults to the level name if no save name is provided
                m_saveName = data.hasOwnProperty("saveName")?data.saveName:null;
                if (m_saveName == null || m_saveName == "")
                {
                    m_saveName = m_name;
                }
                
                if (data.hasOwnProperty("skippable"))
                {
                    m_skippable = XString.stringToBool(data.skippable);
                }
                
                // Get the locks, if any
                if (data.hasOwnProperty("locks"))
                {
                    var locks:Array = data.locks;
                    for each (var lock:Object in locks)
                    {
                        var lockType:String = lock["type"];
                        var lvlLock:ICgsLevelLock = m_lockFactory.getLockInstance(lockType, lock);
                        m_levelLocks.push(lvlLock);
                    }
                }
                
                // Check if the problem is a create/edit type
                if (data.hasOwnProperty("isProblemCreate"))
                {
                    m_isProblemCreate = XString.stringToBool(data.isProblemCreate);
                }
                
                // Load from cache
                if (m_cache != null)
                {
                    loadNodeFromCache(null);
                }
            }
            
            return this;
        }
        
        /**
         * Flag to indicate if this current node is skippable in the progression.
         */
        public function getSkippable():Boolean
        {
            return m_skippable;
        }
        
        /**
         * The game supports a new type of level involving creating or editing the text contents
         * of a problem. Other parts of the application will need to know if a level is of this type
         * since configuration is different.
         */
        public function getIsProblemCreate():Boolean
        {
            return m_isProblemCreate;
        }
        
        /**
         * @inheritDoc
         */
        public function destroy():void
        {
            reset();
            
            // Null out perma-state
            m_nodeLabel = -1;
            m_levelManager = null;
            m_lockFactory = null;
            
            // Null out reset state
            m_levelLocks = null;
        }
        
        /**
         * @inheritDoc
         */
        public function reset():void
        {
            while (m_levelLocks.length > 0)
            {
                var lock:ICgsLevelLock = m_levelLocks.pop();
                m_lockFactory.recycleLock(lock);
            }
            m_levelLocks = new Vector.<ICgsLevelLock>();
            m_name = null;
            m_fileName = null;
            m_saveName = null;
            m_previousLevel = null;
            m_nextLevel = null;
            m_completionValue = -1;
        }
        
        /**
         * This override only exists for debug reinitialization of completion states.
         * 
         * Also do not set an initial save if it doesn't already exist, problem is that this
         * sends hundreds of post requests, one per level node. This is unneeded network usage
         * and seems to cause a pause at the start
         */ 
        public function loadNodeFromCache(userId:String):void
        {
            this.setSaveDataFieldsToDefaultValues();
            var nodeSaveName:String = cacheSaveName;
            
            // Read the saved data for a node if it exists.
            // If it doesn't default initial values are kept.
            if (m_cache.saveExists(nodeSaveName) && m_cache.getSave(nodeSaveName) != null)
            {
                // Save data is either a single number 
                // OR an object with the original completion value and the high score
                // Everything should eventually move over to using the object
                var saveData:Object = m_cache.getSave(nodeSaveName);
                this.updateSaveDataFieldsFromObject(saveData);
            }
        }
        
        /**
         * @inheritDoc
         */
        public function get fileName():String
        {
            return m_fileName;
        }
        
        /**
         * @inheritDoc
         */
        public function get nodeType():String 
        {
            return NODE_TYPE;
        }
        
        /**
         * @inheritDoc
         */
        public function get nextLevel():ICgsLevelLeaf
        {
            return m_nextLevel;
        }
        
        /**
         * @inheritDoc
         */
        public function set nextLevel(nextLevel:ICgsLevelLeaf):void
        {
            m_nextLevel = nextLevel;
        }
        
        /**
         * @inheritDoc
         */
        public function get previousLevel():ICgsLevelLeaf
        {
            return m_previousLevel;
        }
        
        /**
         * @inheritDoc
         */
        public function set previousLevel(prevLevel:ICgsLevelLeaf):void
        {
            m_previousLevel = prevLevel;
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
                for each (var aLock:ICgsLevelLock in m_levelLocks)
                {
                    result = result || aLock.isLocked;
                }
            }
            return result;
        }
        
        /**
         * @inheritDoc
         */
        public function launchLevel(data:Object = null):void
        {
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
            m_levelLocks.push(aLock);
            return true;
        }
        
        /**
         * @inheritDoc
         */
        public function hasLock(lockType:String, keyData:Object):Boolean
        {
            var result:Boolean;
            for each (var lock:ICgsLevelLock in m_levelLocks)
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
            for each (var lock:ICgsLevelLock in m_levelLocks)
            {
                if (lock.lockType == lockType && lock.doesKeyMatch(keyData))
                {
                    m_levelLocks.splice(m_levelLocks.indexOf(lock), 1);
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
            return m_nodeLabel == nodeLabel;
        }
        
        /**
         * @inheritDoc
         */
        public function getNode(nodeLabel:int):ICgsLevelNode
        {
            if(m_nodeLabel == nodeLabel)
                return this;
            return null;
        }
        
        /**
         * @inheritDoc
         */
        public function getNodeByName(nodeName:String):ICgsLevelNode
        {
            if(m_name == nodeName)
                return this;
            return null;
        }
        
        /**
         * Note: This is different from the save id that actually gets stored in the cache.
         * Instead the save name is used to indentify different nodes that should share the same progress.
         * For example, if two levels share the same save name, then completing one of those levels will
         * set the other one as playable
         */
        public function getSaveName():String
        {
            return m_saveName;
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
         * @inheritDoc
         */
        public function updateNode(nodeLabel:int, data:Object = null):Boolean
        {
            /*
            BUG in Common: Common save name only sets the cache value, it does not update the actual value of the
            node objects while the application is running.
            
            For example, if three levels share the same save name and one gets completed, the other two nodes are marked
            as incomplete still until data is reloaded from the cache. Since we don't want to reload each time we just need to update the
            data
            
            Thus what we need to do is look through every node that shares the same save name and actually update its status
            */
            
            var updateSuccessful:Boolean = false;
            var doFlushChanges:Boolean = false;
            if (nodeLabel == this.nodeLabel)
            {
                // If we mark the node as completed, then levels that are not already completed that share the
                // same save name should be unlocked as well. Note that in this overridden method the save names specified
                // in the json files are only ever used by the client application, they are not saved in the database.
                var saveValuesChanged:Boolean = updateSaveDataFieldsFromObject(data);
                
                // Note that we cannot just call the updateNode function on the other node, otherwise we get trapped in an infinite
                // recursive loop. Need to directly modify the completion value of nodes sharing the same save name.
                var levelNodes:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
                WordProblemCgsLevelManager.getLevelNodes(levelNodes, m_levelManager.currentLevelProgression);
                var levelNode:WordProblemLevelLeaf;
                var i:int;
                var numLevelNodes:int = levelNodes.length;
                for (i = 0; i < numLevelNodes; i++)
                {
                    levelNode = levelNodes[i];
                    if (levelNode.getSaveName() == this.getSaveName() && levelNode.nodeLabel != this.nodeLabel)
                    {
                        // Only update other node if this node's new completion value is greater
                        // If it is the other node can take any value as long as it doesn't become complete
                        if (levelNode.completionValue < m_completionValue)
                        {
                            // We update the completion value of the other node and set the cache save for it to
                            // the new value. The other save information of the node are kept the same however.
                            levelNode.m_completionValue = 0;
                            if (m_cache != null)
                            {
                                m_cache.setSave(levelNode.cacheSaveName, levelNode.getSerializedSaveData(), false);
                            }
                        }
                    }
                }
                
                // This is just an optimization to reduce total message sent out
                if (saveValuesChanged && m_cache != null)
                {
                    m_cache.setSave(cacheSaveName, this.getSerializedSaveData(), false);
                }
                
                updateSuccessful = true;
            }
            
            return updateSuccessful;
        }
        
        /**
         * Set all save data fields to starting default values
         * 
         * OVERRIDE if we have more fields to initialize
         */
        protected function setSaveDataFieldsToDefaultValues():void
        {
            // Default value of -1 for completion means that it was never played before
            m_completionValue = LevelNodeCompletionValues.UNKNOWN;
            m_highScore = 0;
            m_serializedObjectives = null;
            m_serializedPerformanceState = null;
        }
        
        /**
         * Pack together all volatile data of this node into an object that can be saved into the cgs cache
         * 
         * OVERRIDE if we have nodes that require more or less save data fields
         */
        protected function getSerializedSaveData():Object
        {
            var dataToSave:Object = {};
            dataToSave[LevelNodeSaveKeys.COMPLETION_VALUE] = this.completionValue;
            dataToSave[LevelNodeSaveKeys.HIGH_SCORE] = this.highScore;
            if (m_serializedObjectives != null)
            {
                dataToSave[LevelNodeSaveKeys.OBJECTIVES] = this.serializedObjectives;
            }
            
            if (m_savePerformanceStateAcrossInstances)
            {
                dataToSave[LevelNodeSaveKeys.PERFORMANCE_STATE] = m_serializedPerformanceState;
            }
            
            return dataToSave;
        }
        
        /**
         * From a object field extract all save data and set the member fields in this object to
         * this same values
         * 
         * OVERRIDE if we have more fields to update
         * 
         * @param data
         *      An object containing all the new save data field this node should take
         * @return
         *      True if at least on of the fields has changed in value from what it was before.
         *      False if it has not changed. This is a way to check if the save entry does in fact need to be rewritten
         *      or resent.
         */
        protected function updateSaveDataFieldsFromObject(data:Object):Boolean
        {
            var newCompletionValue:int = (data.hasOwnProperty(LevelNodeSaveKeys.COMPLETION_VALUE)) ?
                data[LevelNodeSaveKeys.COMPLETION_VALUE] : m_completionValue;
            var completionValueChanged:Boolean = newCompletionValue != m_completionValue; 
            m_completionValue = newCompletionValue;
            
            var newHighScore:int = (data.hasOwnProperty(LevelNodeSaveKeys.HIGH_SCORE)) ?
                data[LevelNodeSaveKeys.HIGH_SCORE] : m_highScore;
            var highScoreChanged:Boolean = newHighScore != m_highScore;
            m_highScore = newHighScore;
            
            // Each objective can be composed of multiple parts
            // The work around for this is the level node needs the objective object
            // we can perform a comparison of whether anything really changed.
            if (data.hasOwnProperty(LevelNodeSaveKeys.OBJECTIVES))
            {
                m_serializedObjectives = data[LevelNodeSaveKeys.OBJECTIVES];
            }
            
            var performanceStateChanged:Boolean = false;
            if (m_savePerformanceStateAcrossInstances && data.hasOwnProperty(LevelNodeSaveKeys.PERFORMANCE_STATE))
            {
                performanceStateChanged = true;
                m_serializedPerformanceState = data[LevelNodeSaveKeys.PERFORMANCE_STATE];
            }
            
            return completionValueChanged || highScoreChanged || performanceStateChanged;
        }
        
        /**
         * Get back the best score ever earned by the player for the playthrough of this level.
         * 
         * @return
         *      Top score for the level, zero if level never played or finished.
         */
        public function get highScore():int
        {
            return m_highScore;
        }
        
        /**
         * Get back the player's progress in all objectives for this level.
         * There should be enough data in here to reconstruct a player's progress in an objective
         * 
         * @return
         *      The format of the returned objectives is pretty much the raw data that is saved.
         *      Null if no special objectives we needed for this level.
         */
        public function get serializedObjectives():Object
        {
            return m_serializedObjectives;
        }
        
        /**
         * Get back performances state info across all played instances of this problem
         * 
         * @return
         *      Null if this node does not keep track of performance state or it was never played
         */
        public function get serializedPerformanceState():Object
        {
            return m_serializedPerformanceState;
        }
        
        /**
         * Ensure no level leaf shares the same cache entry until the bug with node values actually updating is fixed.
         * (prefix ll stands for level leaf)
         */
        protected function get cacheSaveName():String 
        {
            return "ll_" + this.nodeName;
        }
    }
}