package wordproblem.level.nodes;

import wordproblem.level.nodes.WordProblemLevelNode;

import cgs.cache.ICgsUserCache;
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
class WordProblemLevelLeaf extends WordProblemLevelNode implements ICgsLevelLeaf
{
    public var fileName(get, never) : String;
    public var nodeType(get, never) : String;
    public var nextLevel(get, set) : ICgsLevelLeaf;
    public var previousLevel(get, set) : ICgsLevelLeaf;
    public var isLocked(get, never) : Bool;
    public var highScore(get, never) : Int;
    public var serializedObjectives(get, never) : Dynamic;
    public var serializedPerformanceState(get, never) : Dynamic;
    private var cacheSaveName(get, never) : String;

    public static inline var NODE_TYPE : String = "WordProblemLevelLeaf";
    
    /**
     * Get back the genre that contains this leaf (set after construction)
     * 
     * @return
     *      null if this level is not attached to any GenreLevelPack
     */
    public var parentGenreLevelPack : GenreLevelPack;
    
    /**
     * Get back the chapter that contains this leaf (set after construction)
     * 
     * @return
     *      null if this level is not attached to any ChapterLevelPack
     */
    public var parentChapterLevelPack : ChapterLevelPack;
    
    /**
     * A zero based index of where this level lies either within a chapter or genre.
     */
    public var index : Int = -1;
    
    /**
     * Internally keep track of the maximum score the player has ever earned for this level.
     * High score value determines how well the student performed.
     */
    private var m_highScore : Int;
    
    /**
     * Serialized format of the progress or best performance for a player in this particular level
     */
    private var m_serializedObjectives : Dynamic;
    
    private var m_serializedPerformanceState : Dynamic;
    
    // Other State (clear on reset or destroy)
    
    private var m_fileName : String;
    private var m_saveName : String;
    private var m_levelLocks : Array<ICgsLevelLock>;
    private var m_previousLevel : ICgsLevelLeaf;
    
    /**
     * The next level is really determined by how things are organized in the json file.
     * (Has nothing to do with the edge graph)
     */
    private var m_nextLevel : ICgsLevelLeaf;
    private var m_parent : ICgsStatusNode;
    
    private var m_skippable : Bool;
    private var m_isProblemCreate : Bool;
    
    public function new(levelManager : ICgsLevelManager,
            cache : ICgsUserCache,
            lockFactory : ICgsLockFactory,
            nodeLabel : Int)
    {
        super(levelManager, cache, lockFactory, nodeLabel);
        
        m_levelLocks = new Array<ICgsLevelLock>();
        m_skippable = true;
        m_isProblemCreate = false;
        m_serializedPerformanceState = null;
    }
    
    public function init(parent : ICgsLevelPack, prevLevel : ICgsLevelLeaf, data : Dynamic = null) : ICgsLevelLeaf
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
                m_previousLevel.nextLevel = try cast(this, ICgsLevelLeaf) catch (e : Dynamic) null;
            }  // Get the name  
            
            
            
            m_fileName = data.fileName;
            
            // get the level name, which defaults to file name if no level name is provided
            if (m_name == null || m_name == "") 
            {
                m_name = m_fileName;
            }  // Get the save name, which defaults to the level name if no save name is provided  
            
            
            
            m_saveName = (data.exists("saveName")) ? data.saveName : null;
            if (m_saveName == null || m_saveName == "") 
            {
                m_saveName = m_name;
            }
            
            if (data.exists("skippable")) 
            {
                m_skippable = XString.stringToBool(data.skippable);
            }  // Get the locks, if any  
            
            
            
            if (data.exists("locks")) 
            {
                var locks : Array<Dynamic> = data.locks;
                for (lock in locks)
                {
                    var lockType : String = Reflect.field(lock, "type");
                    var lvlLock : ICgsLevelLock = m_lockFactory.getLockInstance(lockType, lock);
                    m_levelLocks.push(lvlLock);
                }
            }  // Check if the problem is a create/edit type  
            
            
            
            if (data.exists("isProblemCreate")) 
            {
                m_isProblemCreate = XString.stringToBool(data.isProblemCreate);
            }  // Load from cache  
            
            
            
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
    public function getSkippable() : Bool
    {
        return m_skippable;
    }
    
    /**
     * The game supports a new type of level involving creating or editing the text contents
     * of a problem. Other parts of the application will need to know if a level is of this type
     * since configuration is different.
     */
    public function getIsProblemCreate() : Bool
    {
        return m_isProblemCreate;
    }
    
    /**
     * @inheritDoc
     */
    public function destroy() : Void
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
    public function reset() : Void
    {
        while (m_levelLocks.length > 0)
        {
            var lock : ICgsLevelLock = m_levelLocks.pop();
            m_lockFactory.recycleLock(lock);
        }
        m_levelLocks = new Array<ICgsLevelLock>();
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
    public function loadNodeFromCache(userId : String) : Void
    {
        this.setSaveDataFieldsToDefaultValues();
        var nodeSaveName : String = cacheSaveName;
        
        // Read the saved data for a node if it exists.
        // If it doesn't default initial values are kept.
        if (m_cache.saveExists(nodeSaveName) && m_cache.getSave(nodeSaveName) != null) 
        {
            // Save data is either a single number
            // OR an object with the original completion value and the high score
            // Everything should eventually move over to using the object
            var saveData : Dynamic = m_cache.getSave(nodeSaveName);
            this.updateSaveDataFieldsFromObject(saveData);
        }
    }
    
    /**
     * @inheritDoc
     */
    private function get_fileName() : String
    {
        return m_fileName;
    }
    
    /**
     * @inheritDoc
     */
    private function get_nodeType() : String
    {
        return NODE_TYPE;
    }
    
    /**
     * @inheritDoc
     */
    private function get_nextLevel() : ICgsLevelLeaf
    {
        return m_nextLevel;
    }
    
    /**
     * @inheritDoc
     */
    private function set_nextLevel(nextLevel : ICgsLevelLeaf) : ICgsLevelLeaf
    {
        m_nextLevel = nextLevel;
        return nextLevel;
    }
    
    /**
     * @inheritDoc
     */
    private function get_previousLevel() : ICgsLevelLeaf
    {
        return m_previousLevel;
    }
    
    /**
     * @inheritDoc
     */
    private function set_previousLevel(prevLevel : ICgsLevelLeaf) : ICgsLevelLeaf
    {
        m_previousLevel = prevLevel;
        return prevLevel;
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
            for (aLock in m_levelLocks)
            {
                result = result || aLock.isLocked;
            }
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function launchLevel(data : Dynamic = null) : Void
    {
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
        m_levelLocks.push(aLock);
        return true;
    }
    
    /**
     * @inheritDoc
     */
    public function hasLock(lockType : String, keyData : Dynamic) : Bool
    {
        var result : Bool;
        for (lock in m_levelLocks)
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
        var result : Bool;
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
        var result : Bool;
        for (lock in m_levelLocks)
        {
            if (lock.lockType == lockType && lock.doesKeyMatch(keyData)) 
            {
                m_levelLocks.splice(Lambda.indexOf(m_levelLocks, lock), 1);
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
        return m_nodeLabel == nodeLabel;
    }
    
    /**
     * @inheritDoc
     */
    public function getNode(nodeLabel : Int) : ICgsLevelNode
    {
        if (m_nodeLabel == nodeLabel) 
            return this;
        return null;
    }
    
    /**
     * @inheritDoc
     */
    public function getNodeByName(nodeName : String) : ICgsLevelNode
    {
        if (m_name == nodeName) 
            return this;
        return null;
    }
    
    /**
     * Note: This is different from the save id that actually gets stored in the cache.
     * Instead the save name is used to indentify different nodes that should share the same progress.
     * For example, if two levels share the same save name, then completing one of those levels will
     * set the other one as playable
     */
    public function getSaveName() : String
    {
        return m_saveName;
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
     * @inheritDoc
     */
    public function updateNode(nodeLabel : Int, data : Dynamic = null) : Bool
    {
        /*
        BUG in Common: Common save name only sets the cache value, it does not update the actual value of the
        node objects while the application is running.
        
        For example, if three levels share the same save name and one gets completed, the other two nodes are marked
        as incomplete still until data is reloaded from the cache. Since we don't want to reload each time we just need to update the
        data
        
        Thus what we need to do is look through every node that shares the same save name and actually update its status
        */
        
        var updateSuccessful : Bool = false;
        var doFlushChanges : Bool = false;
        if (nodeLabel == this.nodeLabel) 
        {
            // If we mark the node as completed, then levels that are not already completed that share the
            // same save name should be unlocked as well. Note that in this overridden method the save names specified
            // in the json files are only ever used by the client application, they are not saved in the database.
            var saveValuesChanged : Bool = updateSaveDataFieldsFromObject(data);
            
            // Note that we cannot just call the updateNode function on the other node, otherwise we get trapped in an infinite
            // recursive loop. Need to directly modify the completion value of nodes sharing the same save name.
            var levelNodes : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
            WordProblemCgsLevelManager.getLevelNodes(levelNodes, m_levelManager.currentLevelProgression);
            var levelNode : WordProblemLevelLeaf;
            var i : Int;
            var numLevelNodes : Int = levelNodes.length;
            for (i in 0...numLevelNodes){
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
            }  // This is just an optimization to reduce total message sent out  
            
            
            
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
    private function setSaveDataFieldsToDefaultValues() : Void
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
    private function getSerializedSaveData() : Dynamic
    {
        var dataToSave : Dynamic = { };
		Reflect.setField(dataToSave, LevelNodeSaveKeys.COMPLETION_VALUE, this.completionValue);
		Reflect.setField(dataToSave, LevelNodeSaveKeys.HIGH_SCORE, this.highScore);
        if (m_serializedObjectives != null) 
        {
			Reflect.setField(dataToSave, LevelNodeSaveKeys.OBJECTIVES, this.serializedObjectives);
        }
        
        if (m_savePerformanceStateAcrossInstances) 
        {
			Reflect.setField(dataToSave, LevelNodeSaveKeys.PERFORMANCE_STATE, m_serializedPerformanceState);
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
    private function updateSaveDataFieldsFromObject(data : Dynamic) : Bool
    {
        var newCompletionValue : Int = ((data.exists(LevelNodeSaveKeys.COMPLETION_VALUE))) ? 
			Reflect.field(data, LevelNodeSaveKeys.COMPLETION_VALUE) : Std.int(m_completionValue);
        var completionValueChanged : Bool = newCompletionValue != m_completionValue;
        m_completionValue = newCompletionValue;
        
        var newHighScore : Int = ((data.exists(LevelNodeSaveKeys.HIGH_SCORE))) ? 
			Reflect.field(data, LevelNodeSaveKeys.HIGH_SCORE) : m_highScore;
        var highScoreChanged : Bool = newHighScore != m_highScore;
        m_highScore = newHighScore;
        
        // Each objective can be composed of multiple parts
        // The work around for this is the level node needs the objective object
        // we can perform a comparison of whether anything really changed.
        if (data.exists(LevelNodeSaveKeys.OBJECTIVES)) 
        {
			m_serializedObjectives = Reflect.field(data, LevelNodeSaveKeys.OBJECTIVES);
        }
        
        var performanceStateChanged : Bool = false;
        if (m_savePerformanceStateAcrossInstances && data.exists(LevelNodeSaveKeys.PERFORMANCE_STATE)) 
        {
            performanceStateChanged = true;
			m_serializedPerformanceState = Reflect.field(data, LevelNodeSaveKeys.PERFORMANCE_STATE);
        }
        
        return completionValueChanged || highScoreChanged || performanceStateChanged;
    }
    
    /**
     * Get back the best score ever earned by the player for the playthrough of this level.
     * 
     * @return
     *      Top score for the level, zero if level never played or finished.
     */
    private function get_highScore() : Int
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
    private function get_serializedObjectives() : Dynamic
    {
        return m_serializedObjectives;
    }
    
    /**
     * Get back performances state info across all played instances of this problem
     * 
     * @return
     *      Null if this node does not keep track of performance state or it was never played
     */
    private function get_serializedPerformanceState() : Dynamic
    {
        return m_serializedPerformanceState;
    }
    
    /**
     * Ensure no level leaf shares the same cache entry until the bug with node values actually updating is fixed.
     * (prefix ll stands for level leaf)
     */
    private function get_cacheSaveName() : String
    {
        return "ll_" + this.nodeName;
    }
}
