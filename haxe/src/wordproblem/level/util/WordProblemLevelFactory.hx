package wordproblem.level.util;

import flash.errors.Error;

import cgs.cache.ICgsUserCache;
import cgs.levelProgression.ICgsLevelManager;
import cgs.levelProgression.nodes.ICgsLevelNode;
import cgs.levelProgression.util.ICgsLevelFactory;
import cgs.levelProgression.util.ICgsLockFactory;
import cgs.user.ICgsUserManager;

import wordproblem.level.nodes.ChapterLevelPack;
import wordproblem.level.nodes.GenreLevelPack;
import wordproblem.level.nodes.WordProblemLevelLeaf;
import wordproblem.level.nodes.WordProblemLevelPack;

/**
 * We need to create a brand new subclass of the level factory if we want to insert nodes with
 * custom data that is specific to this application.
 * 
 * An example is we need to group certain word problems by genre, the genre is like a level pack
 * and may have extra data to be stored.
 */
class WordProblemLevelFactory implements ICgsLevelFactory
{
    public var defaultLevelType(get, set) : String;
    public var defaultLevelPackType(get, set) : String;

    private var m_levelManager : ICgsLevelManager;
    private var m_lockFactory : ICgsLockFactory;
    private var m_userManager : ICgsUserManager;
    private var m_nextLabel : Int;
    private var m_levelNodeStorage : Dynamic;
    
    /**
     * This is the save interface for a session that several of the node will use
     */
    private var m_cache : ICgsUserCache;
    
    private var m_defaultLevelType : String;
    private var m_defaultLevelPackType : String;
    
    public function new(levelManager : ICgsLevelManager,
            lockFactory : ICgsLockFactory,
            userManager : ICgsUserManager,
            cache : ICgsUserCache)
    {
        m_lockFactory = lockFactory;
        m_levelManager = levelManager;
        m_userManager = userManager;
        m_nextLabel = 1;
        m_levelNodeStorage = { };
        m_cache = cache;
        
        m_defaultLevelType = WordProblemLevelLeaf.NODE_TYPE;
        m_defaultLevelPackType = WordProblemLevelPack.NODE_TYPE;
    }
    
    /**
     * Generates and returns a new unique level label.
     * @return
     */
    private function generateLevelLabel() : Int
    {
        var result : Int = m_nextLabel;
        m_nextLabel++;
        return (result);
    }
    
    /**
     * @inheritDoc
     */
    private function get_defaultLevelType() : String
    {
        return WordProblemLevelLeaf.NODE_TYPE;
    }
    
    /**
     * @inheritDoc
     */
    private function set_defaultLevelType(value : String) : String
    {
        m_defaultLevelType = value;
        return value;
    }
    
    /**
     * @inheritDoc
     */
    private function get_defaultLevelPackType() : String
    {
        return m_defaultLevelPackType;
    }
    
    /**
     * @inheritDoc
     */
    private function set_defaultLevelPackType(value : String) : String
    {
        m_defaultLevelPackType = value;
        return value;
    }
    
    /**
     * @inheritDoc
     */
    public function getNodeInstance(typeID : String) : ICgsLevelNode
    {
        var result : ICgsLevelNode;
        
        // Get the node storage for this type, creating the storage if this is a new type
        if (!m_levelNodeStorage.exists(typeID)) 
        {
            // create new array for this type id
            Reflect.setField(m_levelNodeStorage, typeID, new Array<Dynamic>());
        }
        var nodeStorage : Array<Dynamic> = Reflect.field(m_levelNodeStorage, typeID);
        
        // Get a node out of storage
        if (nodeStorage.length > 0) 
        {
            result = nodeStorage.pop();
        }
        // Generate a new node
        else 
        {
            var levelLabel : Int = generateLevelLabel();
            result = generateNodeInstance(typeID, levelLabel);
        }
        
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function recycleNodeInstance(node : ICgsLevelNode) : Void
    {
        node.reset();
    }
    
    /**
     * Need to override the default node creation function to allow for the construction of our
     * own custom data nodes.
     */
    private function generateNodeInstance(typeID : String, nodeLabel : Int) : ICgsLevelNode
    {
        var result : ICgsLevelNode;
        
        // List out our custom nodes here
        // In the data file the key fields are named 'levelType' for leaf nodes
        // and 'packType' for non-leaf nodes. We set those values to the ids in our subclasses.
        // Note that 'nodeType' must be set to the value 'levelPack' to indicate that it is
        // a non-leaf node.
        if (typeID == GenreLevelPack.NODE_TYPE) 
        {
            result = new GenreLevelPack(m_levelManager, m_cache, this, m_lockFactory, nodeLabel);
        }
        else if (typeID == ChapterLevelPack.NODE_TYPE) 
        {
            result = new ChapterLevelPack(m_levelManager, m_cache, this, m_lockFactory, nodeLabel);
        }
        // By default all leafs nodes will use our custom created class
        else if (typeID == WordProblemLevelLeaf.NODE_TYPE) 
        {
            result = new WordProblemLevelLeaf(m_levelManager, m_cache, m_lockFactory, nodeLabel);
        }
        // By default all non-leaf nodes that are not genres or chapters will use our custom level pack
        else if (typeID == WordProblemLevelPack.NODE_TYPE) 
        {
            // (The root node and 'adaptive buckets' fit into this category)
            result = new WordProblemLevelPack(m_levelManager, m_cache, this, m_lockFactory, nodeLabel);
        }
        else 
        {
            throw new Error("Undefined node type in level progression: " + typeID);
        }
        
        return result;
    }
}
