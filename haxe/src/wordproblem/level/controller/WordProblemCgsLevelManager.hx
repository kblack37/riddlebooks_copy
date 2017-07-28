package wordproblem.level.controller;

import flash.errors.Error;

import cgs.cache.ICgsUserCache;
import cgs.achievement.ICgsAchievementManager;
import cgs.levelProgression.ICgsLevelManager;
import cgs.levelProgression.nodes.ICgsLevelLeaf;
import cgs.levelProgression.nodes.ICgsLevelNode;
import cgs.levelProgression.nodes.ICgsLevelPack;
import cgs.levelProgression.nodes.ICgsStatusNode;
import cgs.levelProgression.util.ICgsLevelFactory;
import cgs.levelProgression.util.ICgsLevelResourceManager;
import cgs.levelProgression.util.ICgsLockFactory;
import cgs.user.ICgsUserManager;

import dragonbox.common.util.PMPRNG;

import haxe.Constraints.Function;

import wordproblem.engine.level.LevelEndTypes;
import wordproblem.engine.level.LevelStatistics;
import wordproblem.engine.objectives.BaseObjective;
import wordproblem.engine.objectives.ObjectivesFactory;
import wordproblem.level.LevelNodeActions;
import wordproblem.level.LevelNodeCompletionValues;
import wordproblem.level.LevelNodeSaveKeys;
import wordproblem.level.conditions.ICondition;
import wordproblem.level.conditions.KOutOfNProficientCondition;
import wordproblem.level.conditions.NLevelsCompletedCondition;
import wordproblem.level.conditions.NodeStatusCondition;
import wordproblem.level.nodes.ChapterLevelPack;
import wordproblem.level.nodes.GenreLevelPack;
import wordproblem.level.nodes.WordProblemLevelLeaf;
import wordproblem.level.nodes.WordProblemLevelNode;
import wordproblem.level.nodes.WordProblemLevelPack;
import wordproblem.level.util.WordProblemLevelFactory;
import wordproblem.level.util.WordProblemLockFactory;
import wordproblem.resource.AssetManager;

/**
 * A very important note is that the level manager is coupled to the logging system
 * It presumes the player has been logged into the system with some set of credentials
 * 
 * This level manager builds a decision system on top of the node structure.
 */
class WordProblemCgsLevelManager implements ICgsLevelManager
{
    public var currentLevel(get, never) : ICgsLevelLeaf;
    public var currentLevelProgression(get, never) : ICgsLevelPack;
    public var resourceManager(get, never) : ICgsLevelResourceManager;
    public var achievementManager(get, never) : ICgsAchievementManager;
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
    public var isCompleteCompletionValue(get, set) : Float;
    public var doCheckLocks(get, set) : Bool;

    /**
     * While the game is live, users might express complaints about certain levels that we decide
     * to ultimately remove from that version. However, it is possible some players have those removed
     * levels stored in the save data as the next one to go to. In the updated version they would jump into the
     * correct spot again.
     */
    private static var REMOVED_LEVEL_ID_TO_BUCKET : Dynamic = { };
    
    /**
     * Recursively separate out the items in a chapter and the level not in a chapter
     */
    public static function separateChapterAndLevelNodes(outChapterNodes : Array<ChapterLevelPack>,
            outLevelNodesWithoutChapter : Array<WordProblemLevelLeaf>,
            levelNode : ICgsLevelNode) : Void
    {
        if (levelNode != null) 
        {
            if (Std.is(levelNode, WordProblemLevelLeaf)) 
            {
                outLevelNodesWithoutChapter.push(try cast(levelNode, WordProblemLevelLeaf) catch (e : Dynamic) null);
            }
            else if (Std.is(levelNode, ICgsLevelPack)) 
            {
                if (Std.is(levelNode, ChapterLevelPack)) 
                {
                    outChapterNodes.push(try cast(levelNode, ChapterLevelPack) catch(e:Dynamic) null);
                }
                else 
                {
                    var children : Array<ICgsLevelNode> = (try cast(levelNode, ICgsLevelPack) catch(e:Dynamic) null).nodes;
                    var numChildren : Int = children.length;
                    var i : Int;
                    for (i in 0...numChildren){
                        separateChapterAndLevelNodes(outChapterNodes, outLevelNodesWithoutChapter, children[i]);
                    }
                }
            }
        }
    }
    
    /**
     * Recursively get all leaf nodes nested within a another target node.
     * 
     * @param outLevelNodes
     *      Output list of level leaf nodes contained in the root
     * @param levelNode
     *      Root node to start search
     */
    public static function getLevelNodes(outLevelNodes : Array<WordProblemLevelLeaf>, levelNode : ICgsLevelNode) : Void
    {
        if (levelNode != null) 
        {
            if (Std.is(levelNode, WordProblemLevelLeaf)) 
            {
                outLevelNodes.push(try cast(levelNode, WordProblemLevelLeaf) catch (e : Dynamic) null);
            }
            else if (Std.is(levelNode, ICgsLevelPack)) 
            {
                var children : Array<ICgsLevelNode> = (try cast(levelNode, ICgsLevelPack) catch(e:Dynamic) null).nodes;
                var numChildren : Int = children.length;
                var i : Int;
                for (i in 0...numChildren){
                    getLevelNodes(outLevelNodes, children[i]);
                }
            }
        }
    }
    
    /*
    The save blob for state should look like:
    {
    name:<level name>,
    conds:{
    <edgeId>:{
    <condition_index>:{<save_data_blob>}
    }
    }
    }
    */
    
    /**
     * This is the key name in the save map for all data related to the current progress of the player.
     */
    private static inline var CURRENT_LEVEL_STATE_SAVE_KEY : String = "cls";
    
    private static inline var CURRENT_LEVEL_NAME_SAVE_KEY : String = "n";
    
    private static inline var CURRENT_LEVEL_CONDITIONS_SAVE_KEY : String = "cnds";
    
    private var m_rootLevelProgression : ICgsLevelPack;
    private var m_lockFactory : ICgsLockFactory;
    private var m_levelFactory : ICgsLevelFactory;
    private var m_resourceManager : ICgsLevelResourceManager;
    private var m_userManager : ICgsUserManager;
    private var m_isCompleteCompletionValue : Float = 1;
    private var m_doCheckLocks : Bool = true;
    
    /**
     * Saved callback that will signal the outside application that they should start a
     * level with a given id and using a specific resource location.
     * Made protected so that subclass NeverEndingLevelManager can have access.
     */
    private var m_startLevelCallback : Function;
    
    /**
     * Saved callback that will signal to the outside application that there is no next level
     * that can be played. One response to this is to kick the player back in the level select screen if this happens.
     * 
     * Accepts no params
     */
    private var m_noNextLevelCallback : Function;
    
    /**
     * At the end of each level this manager needs to save the next level that the game should go to automatically.
     * From the perspective of the manager, the time when the next level should start after one has been completed is
     * unknown. When the game is ready to go to the next level we use this saved information.
     */
    private var m_savedNextLevelLeaf : ICgsLevelLeaf;
    
    /**
     * A list of edge data objects ripped straight from the json data file
     * Assume each edge object looks like
     * {
     * id:<unique name for edge>,
     * startId:<node name>,
     * endId:<node name>,
     * conditions:[
     * {type:<>, extraDataForCondition:...}
     * ],
     * actions:[
     * {type:<>, extraDataForAction}
     * ]
     * }
     * Conditions (optional) is list of even more data objects that define small test that need to pass
     * for the us to take an edge.
     * Actions (optional) are logic that should run if this edge is taken
     * 
     * This is a list of raw edge data, the ordering is very important as edges at the beginning have higher priority.
     * We also try to take the higher priority edges first.
     */
    private var m_nodeEdges : Array<Dynamic>;
    
    /**
     * Current state stored in conditions that are in possible edges the user can take
     * in the current level.
     * 
     * key: id of the edge
     * value: Vector of condition objects for evaluation of the edge
     */
    private var m_edgeIdToConditionsList : Dynamic;
    
    /**
     * Transitions in the level graph will often times require the 'proficient' completion
     * of a level. What it means for a level to be 'proficiently' completed is very fuzzy and
     * depends on the content of the problem
     * It makes sense for that data of what proficient means to be encoded in the same json
     * file as it puts the transition and how it gets there in one place for easier book-keeping.
     * 
     * We can break down proficiency in the completion of modular Objectives.
     * In fact objectives can be used to figure out poor performance, player exceeded a time limit or
     * made too many mistakes. Reaching those objectives would require a remediation edge.
     * 
     * key: id of a collection of related objectives
     * value: list of BaseObjective objects in that id
     * 
     * objectiveClasses:[
     *      {id:<class_name>, objectives:[] },...
     * ]
     */
    private var m_objectiveClassIdToObjectives : Dynamic;
    
    private var m_outLevelBuffer : Array<WordProblemLevelLeaf>;
    
    /**
     * The interface for the save data. Should be able to easily switch between saving locally and saving
     * on the server.
     */
    private var m_cache : ICgsUserCache;
    
    /**
     * Seeded random number generator.
     */
    private var m_randomGenerator : PMPRNG;
    
    /**
     * The current progression resource that was set
     * (Exposed only so the game can automatically refetch the progression on a reset)
     */
    public var progressionResourceName : String;
    
    /**
     * 
     * @param userManager
     *      The progression library requires a credentials for a user that has already been logged in
     * @param resourceManager
     *      Hold references to the textual data of the files
     * @param startCallback
     *      Signature is callback(id:String, url:String, levelProgressData:Object):void
     *      id is unique name of the level, 
     *      url is where it should be loaded from, 
     *      levelProgressData is extra details the game might need to know to draw the level (includes telling us
     *      whether a level is part of an adaptive progression)
     * @param noLevelCallback
     *      Register callback to tell the game that there is no further level
     *      to be played. (Right now occurs at the end of a genre)
     *      Callback accepts no parameters
     * @param doCheckLocks
     *      Initial setting of whether levels should check lock constructs (mostly affects the level select screen)
     */
    public function new(userManager : ICgsUserManager,
            resourceManager : AssetManager,
            startCallback : Function,
            noLevelCallback : Function,
            doCheckLocks : Bool = true)
    {
        m_userManager = userManager;
        
        // Creates all the managers and factories
        // DO NOT call super as it does not set the properties we want in the right order
        m_lockFactory = try cast(new WordProblemLockFactory(try cast(this, ICgsLevelManager) catch (e : Dynamic) null), ICgsLockFactory) catch (e : Dynamic) null;
        m_resourceManager = resourceManager;
        m_startLevelCallback = startCallback;
        m_noNextLevelCallback = noLevelCallback;
        
        // The level manager creates a default sequential locking system on level sequences
        // It seems as though the lock is placed on all but the first level in the sequence, those
        // level that have locks on them should only be unlocked if the prior level was completed
        // (default condition was just if they were at all played, which checks completion value)
        
        // Set the value that a leaf takes to indicate that a level is completed
        m_isCompleteCompletionValue = LevelNodeCompletionValues.PLAYED_SUCCESS;
        
        m_outLevelBuffer = new Array<WordProblemLevelLeaf>();
        
        // For this session, the random generator reuses the same seed
        m_randomGenerator = PMPRNG.createGen(null);
        m_randomGenerator.seed = 42;
        this.doCheckLocks = doCheckLocks;
    }
    
    /*
     * @return Object mapping from Edge ID(int) to Conditions List(Vector.<ICondition>) which are active for the current level
     */
    public function getEdgeIdToConditionsList() : Dynamic{
        return m_edgeIdToConditionsList;
    }
    
    /**
     * MUST CALL THIS TO INITIALIZE
     * 
     * @param sequenceName
     *      Name of the resource that contains how the levels should be sequenced
     * @param cache
     *      This is the save interface to use when populating the given progression resource with save
     *      If null, we attempt to use the logged in user
     * @param preprocessCallback
     *      signature callback(levelObject:Object):void
     *      If not null this callback is a way for a separate part of the app to modify the json before it
     *      is parsed. Used for AB testing where a condition requires deleting or reshuffling parts of the progression.
     */
    public function setToNewLevelProgression(progressionResourceName : String,
            cache : ICgsUserCache,
            preprocessCallback : Function = null) : Void
    {
        // The asset manager has the general level sequence template
        // Note that this init function also loads in save data into the graph
        this.progressionResourceName = progressionResourceName;
        var levelObject : Dynamic = (try cast(this.resourceManager, AssetManager) catch(e:Dynamic) null).getObject(progressionResourceName);
        if (preprocessCallback != null) 
        {
            preprocessCallback(levelObject);
        }
        
        if (cache != null) 
        {
            m_cache = cache;
        }
        // MUST recreate the factory so the new cache is used
        else if (m_userManager.userList.length > 0) 
        {
            m_cache = try cast(m_userManager.userList[0], ICgsUserCache) catch (e : Dynamic) null;
        }
        
        
        
        m_levelFactory = try cast(new WordProblemLevelFactory(
				try cast(this, ICgsLevelManager) catch (e : Dynamic) null,
				m_lockFactory,
				m_userManager,
				cache
			), ICgsLevelFactory) catch (e : Dynamic) null;
        
        if (m_rootLevelProgression != null) 
        {
            this.reset();
        }
        
        this.init(levelObject);
        
        // IMPORTANT NOTE: The current node and its parent form the nodes the player is in.
        
        // Get all save data related to the state the player is in
		var localConditionSavedData : Dynamic = null;
        if (m_cache.saveExists(CURRENT_LEVEL_STATE_SAVE_KEY)) 
        {
            var clsSaveBlob : Dynamic = m_cache.getSave(CURRENT_LEVEL_STATE_SAVE_KEY);
            if (clsSaveBlob == null) 
            {
                clsSaveBlob = { };
            }
            
            if (clsSaveBlob.exists(CURRENT_LEVEL_NAME_SAVE_KEY)) 
            {
                var nextNodeName : String = Reflect.field(clsSaveBlob, CURRENT_LEVEL_NAME_SAVE_KEY);
                
                // If the next node was something that was retroactively deleted, we need to
                // pick an equivalent node
                if (WordProblemCgsLevelManager.REMOVED_LEVEL_ID_TO_BUCKET.exists(nextNodeName)) 
                {
					var candidateBucketName : String = Reflect.field(WordProblemCgsLevelManager.REMOVED_LEVEL_ID_TO_BUCKET, nextNodeName);
                    m_savedNextLevelLeaf = this.getNextLeafFromSelectionPolicy(this.getNodeByName(candidateBucketName), null);
                }
                else 
                {
                    m_savedNextLevelLeaf = try cast(this.getNodeByName(nextNodeName), WordProblemLevelLeaf) catch(e:Dynamic) null;
                }
            }
            
            if (clsSaveBlob.exists(CURRENT_LEVEL_CONDITIONS_SAVE_KEY)) 
            {
                localConditionSavedData = Reflect.field(clsSaveBlob, CURRENT_LEVEL_CONDITIONS_SAVE_KEY);
            }
        }
		
		// The progression object has an optional extra property to indicate the exact node that acts as the starting  
		// point in the graph.
		// This is useful the very first time the player enters and they have no saved data where they were.
        // If starting point not specified we pick the very first level in the list.
        if (m_savedNextLevelLeaf == null) 
        {
            // Restriction: start node name must be a leaf node
            if (levelObject.exists("startNodeName")) 
            {
                var startingNode : WordProblemLevelLeaf = try cast(this.getNodeByName(levelObject.startNodeName), WordProblemLevelLeaf) catch(e:Dynamic) null;
                if (startingNode != null) 
                {
                    m_savedNextLevelLeaf = startingNode;
                }
            }
			
			// No valid start means we pick first level in list  
            if (m_savedNextLevelLeaf == null) 
            {
                m_savedNextLevelLeaf = try cast(this.currentLevelProgression.firstLeaf, WordProblemLevelLeaf) catch(e:Dynamic) null;
            }
        }
        
        m_edgeIdToConditionsList = { };
        
        // Part of the root level object is a list of edge objects
        m_nodeEdges = new Array<Dynamic>();
        if (levelObject.exists("edges")) 
        {
            // Convert the array into mappings
            // The reason is we only care about edge order in terms of the outgoing edges per node
            var edgeList : Array<Dynamic> = levelObject.edges;
            var numEdges : Int = edgeList.length;
            for (i in 0...numEdges){
                var edgeObject : Dynamic = edgeList[i];
                m_nodeEdges.push(edgeObject);
                
                // Go through the conditions of the edge and inject save data if it exists
                if (edgeObject.exists("conditions") && localConditionSavedData != null && localConditionSavedData.exists(edgeObject.id)) 
                {
                    var conditions : Array<Dynamic> = edgeObject.conditions;
                    var conditionIndexToSaveBlob : Dynamic = localConditionSavedData[edgeObject.id];
                    for (j in 0...conditions.length){
                        // Stuffing extra serialized save property into condition object if it exists
                        var index : String = Std.string(j);
                        if (conditionIndexToSaveBlob.exists(index)) 
                        {
                            conditions[j].save = Reflect.field(conditionIndexToSaveBlob, index);
                        }
                    }
                }
            }
        }  // were accomplished.    // Condition may link to a group to see if all of those objectives in a level    // Parse the special objective groups used by some of the conditions  
        
        
        
        
        
        
        
        m_objectiveClassIdToObjectives = { };
        if (levelObject.exists("objectiveClasses")) 
        {
            var objectiveClassList : Array<Dynamic> = levelObject.objectiveClasses;
            var numObjectiveClasses : Int = objectiveClassList.length;
            for (i in 0...numObjectiveClasses){
                var objectiveClass : Dynamic = objectiveClassList[i];
                var objectiveObjects : Array<BaseObjective> = ObjectivesFactory.getObjectivesFromJsonArray(
                        objectiveClass.objectives
                        );
                m_objectiveClassIdToObjectives[objectiveClass.id] = objectiveObjects;
            }
        }  // and assign an index to them    // Post process after the graph has been created, go through each chapter and level  
        
        
        
        
        
        var genreLevelPacks : Array<GenreLevelPack> = new Array<GenreLevelPack>();
        var chapterNodesInGenre : Array<ChapterLevelPack> = new Array<ChapterLevelPack>();
        var levelNodesWithoutChapterInGenre : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
        var levelNodesInChapter : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
        this.getGenreNodes(genreLevelPacks);
        for (genreLevelPack in genreLevelPacks)
        {
            WordProblemCgsLevelManager.separateChapterAndLevelNodes(chapterNodesInGenre, levelNodesWithoutChapterInGenre, genreLevelPack);
            var i : Int;
            var numChapterNodes : Int = chapterNodesInGenre.length;
            var chapterLevelPack : ChapterLevelPack;
            for (i in 0...numChapterNodes){
                chapterLevelPack = chapterNodesInGenre[i];
                chapterLevelPack.index = i;
                
                // Set parent genre and chapter for levels in a chapter
                WordProblemCgsLevelManager.getLevelNodes(levelNodesInChapter, chapterLevelPack);
                var j : Int;
                var levelNodeInChapter : WordProblemLevelLeaf;
                var numLevelNodesInChapter : Int = levelNodesInChapter.length;
                for (j in 0...numLevelNodesInChapter){
                    levelNodeInChapter = levelNodesInChapter[j];
                    levelNodeInChapter.index = j;
                    levelNodeInChapter.parentChapterLevelPack = chapterLevelPack;
                    levelNodeInChapter.parentGenreLevelPack = genreLevelPack;
                }  
				
				// Clear buffer for next chapter  
                levelNodesInChapter = new Array<WordProblemLevelLeaf>();
            }  
			
			// Set parent genre and index for levels without a chapter  
            var numLevelNodesWithoutChapter : Int = levelNodesWithoutChapterInGenre.length;
            var levelLeafWithoutChapter : WordProblemLevelLeaf;
            for (i in 0...numLevelNodesWithoutChapter){
                levelLeafWithoutChapter = try cast(levelNodesWithoutChapterInGenre[i], WordProblemLevelLeaf) catch(e:Dynamic) null;
                levelLeafWithoutChapter.index = i;
                levelLeafWithoutChapter.parentGenreLevelPack = genreLevelPack;
            }  
			
			// Clear buffers for next genre  
            chapterNodesInGenre = new Array<ChapterLevelPack>();
			levelNodesWithoutChapterInGenre = new Array<WordProblemLevelLeaf>();
        }
		
		// At this point, all the nodes should be synchronized with the save data.  
		// Fire event so other parts of the game can process this information
    }
    
    /**
     * Allow an entry point for the main application class to determine the next level to go to.
     * The main usage is for when a player logs in again after a short break. We want to make sure
     * the user goes to the 'furthest' point in the progression. Since the definition of furthest
     * is version dependent the logic for it should appear elsewhere
     */
    public function setNextLevelLeaf(leaf : WordProblemLevelLeaf) : Void
    {
        m_savedNextLevelLeaf = leaf;
    }
    
    /**
     * Go to a specific level by an id
     * 
     * @param id
     *      The unique name belonging to a single level or level set, in the case of a set the level is picked
     *      depending on the selection policy on that set.
     */
    public function goToLevelById(id : String) : Void
    {
        var levelNode : ICgsLevelNode = currentLevelProgression.getNodeByName(id);
        if (m_startLevelCallback != null && levelNode != null) 
        {
            // If the level to go to is actually a level pack, we determine the leaf based on the selection policy set
            // on that pack
            if (Std.is(levelNode, WordProblemLevelPack)) 
            {
                levelNode = this.getNextLeafFromSelectionPolicy(levelNode, (try cast(levelNode, WordProblemLevelPack) catch(e:Dynamic) null).getSelectionPolicy());
            }  // is for drawing purposes.    // The application may need to know extra data about where in the progression the level  
            
            
            
            
            
            var extraLevelProgressionData : Dynamic = null;
            if (Std.is(levelNode, WordProblemLevelLeaf)) 
            {
                var wordProblemLeaf : WordProblemLevelLeaf = try cast(levelNode, WordProblemLevelLeaf) catch(e:Dynamic) null;
                extraLevelProgressionData = {
                            genreId : wordProblemLeaf.parentGenreLevelPack.getThemeId(),
                            chapterIndex : wordProblemLeaf.parentChapterLevelPack.index,
                            levelIndex : wordProblemLeaf.index,
                            skippable : wordProblemLeaf.getSkippable(),
                            isProblemCreate : wordProblemLeaf.getIsProblemCreate(),
                            previousCompletionStatus : wordProblemLeaf.completionValue,
                            tags : wordProblemLeaf.getTags(),
                        };
				
				function getInheritedProperty(checkPropertyIsInherited : Function, startingNode : ICgsStatusNode) : Void
                {
                    var trackingNode : ICgsStatusNode = wordProblemLeaf;
                    var continueSearch : Bool = true;
                    while (trackingNode != null && Std.is(trackingNode, WordProblemLevelNode) && continueSearch)
                    {
                        var trackingNodeTemp : WordProblemLevelNode = try cast(trackingNode, WordProblemLevelNode) catch(e:Dynamic) null;
                        if (checkPropertyIsInherited(trackingNodeTemp)) 
                        {
                            continueSearch = false;
                        }
                        else 
                        {
                            if (Std.is(trackingNode, WordProblemLevelLeaf)) 
                            {
                                trackingNode = (try cast(trackingNode, WordProblemLevelLeaf) catch(e:Dynamic) null).getParent();
                            }
                            else if (Std.is(trackingNode, WordProblemLevelPack)) 
                            {
                                trackingNode = (try cast(trackingNode, WordProblemLevelPack) catch(e:Dynamic) null).getParent();
                            }
                            else 
                            {
                                break;
                            }
                        }
                    }
                };
                
                // If a node does not explicitly define rules to override check if parent node
                // have this information. Inherit the entire rule set from the closest parent
                getInheritedProperty(function(levelNode : WordProblemLevelNode) : Bool
                        {
                            var isInherited : Bool = false;
                            if (levelNode.getOverriddenRules() != null) 
                            {
                                Reflect.setField(extraLevelProgressionData, "rules", levelNode.getOverriddenRules());
                                isInherited = true;
                            }
                            return isInherited;
                        }, wordProblemLeaf);
                
                // Search for the data about prepopulating the equation area
                getInheritedProperty(function(levelNode : WordProblemLevelNode) : Bool
                        {
                            var isInherited : Bool = false;
                            if (levelNode.getPrepopulateEquationData() != null) 
                            {
                                Reflect.setField(extraLevelProgressionData, "prepopulateEquation", levelNode.getPrepopulateEquationData());
                                isInherited = true;
                            }
                            return isInherited;
                        }, wordProblemLeaf);
                
                // Get the difficulty level
                getInheritedProperty(function(levelNode : WordProblemLevelNode) : Bool
                        {
                            var isInherited : Bool = false;
                            if (levelNode.getDifficultySet()) 
                            {
                                Reflect.setField(extraLevelProgressionData, "difficulty", levelNode.getDifficulty());
                                isInherited = true;
                            }
                            return isInherited;
                        }, wordProblemLeaf);
				
                var nodesContainingCurrentLevel : Array<ICgsLevelNode> = getNodesContainingCurrentLevel(wordProblemLeaf.nodeName);
                var numNodesContainingThisLevel : Int = nodesContainingCurrentLevel.length;
                
                // Check if there is an objective class that this node, we stop at the lowest level
                // containing objectives (means objectives are not inherited right now)
                for (i in 0...numNodesContainingThisLevel){
                    var nodeContainingLevel = nodesContainingCurrentLevel[i];
                    
                    var objectiveClassName : String = (try cast(nodeContainingLevel, WordProblemLevelNode) catch(e:Dynamic) null).getObjectiveClass();
                    if (objectiveClassName != null) 
                    {
                        // Create cloned copy of the objectives
                        var objectivesForNode : Array<BaseObjective> = Reflect.field(m_objectiveClassIdToObjectives, objectiveClassName);
                        if (objectivesForNode != null) 
                        {
                            var copyOfObjectives : Array<BaseObjective> = new Array<BaseObjective>();
                            for (objective in objectivesForNode)
                            {
                                copyOfObjectives.push(objective.clone());
                            }
                            Reflect.setField(extraLevelProgressionData, "objectives", copyOfObjectives);
                        }
                        
                        break;
                    }
                }
                
                if (wordProblemLeaf.getSavePerformanceStateAcrossInstances()) 
                {
                    Reflect.setField(extraLevelProgressionData, "performanceState", wordProblemLeaf.serializedPerformanceState);
                }
                
                m_startLevelCallback(wordProblemLeaf.nodeName, wordProblemLeaf.fileName, extraLevelProgressionData);
                
                // Temp key-value map to delete unused edges
                var edgeIdToEdgeObject : Dynamic = { };
                
                // Intialize conditions for edges at this node
                // Iterate through the start of the edge list and check for ones where the starting
                // node is in one we are currently in.
                // If a node in the path contains outgoing edges, update all the condition objects
                var i : Int;
                var numEdges : Int = m_nodeEdges.length;
                var closestAncestorWithASpecifiedEdge : ICgsLevelNode = null;
                for (i in 0...numEdges){
                    var edgeObject : Dynamic = m_nodeEdges[i];
                    edgeIdToEdgeObject[edgeObject.id] = edgeObject;
                    var startNodeIdForEdge : String = edgeObject.startId;
                    
                    // Check if an edges matches one of the set the current level node is contained within
                    var j : Int;
                    for (j in 0...numNodesContainingThisLevel){
                        // If an edge is outgoing from a set, we test whether we should take this edge
                        var nodeContainingLevel : ICgsLevelNode = nodesContainingCurrentLevel[j];
                        if (nodeContainingLevel.nodeName == startNodeIdForEdge) 
                        {
                            closestAncestorWithASpecifiedEdge = nodeContainingLevel;
                            
                            // Create new condition objects for an edge
                            if (!m_edgeIdToConditionsList.exists(edgeObject.id)) 
                            {
                                var conditionsList : Array<ICondition> = new Array<ICondition>();
                                if (edgeObject.exists("conditions")) 
                                {
                                    var conditionsData : Array<Dynamic> = edgeObject.conditions;
                                    var k : Int;
                                    for (k in 0...conditionsData.length){
                                        conditionsList.push(createCondition(conditionsData[k]));
                                    }
                                }
                                
                                m_edgeIdToConditionsList[edgeObject.id] = conditionsList;
                            }
                        }
                    }
                }  // If the start node id is not part of the nodes currently in, it should be removed    // Identify the start node id of the existing edges being tracked    // Discard edges that are no longer valid on start  
                
                
                
                
                
                
                
                var edgeIdsToDelete : Array<String> = new Array<String>();
                for (existingEdgeId in Reflect.fields(m_edgeIdToConditionsList))
                {
                    var startingNodeIdForEdge : String = Reflect.field(edgeIdToEdgeObject, existingEdgeId).startId;
                    var edgeIsContainedInCurrentNode : Bool = false;
                    for (nodeContainingLevel in nodesContainingCurrentLevel)
                    {
                        if (nodeContainingLevel.nodeName == startingNodeIdForEdge) 
                        {
                            edgeIsContainedInCurrentNode = true;
                            break;
                        }
                    }
                    
                    if (!edgeIsContainedInCurrentNode) 
                    {
                        edgeIdsToDelete.push(startingNodeIdForEdge);
                    }
                }
            }
        }
        // TODO: HACK to get unknown levels in the progression to be playable
        // Is there a way to create a way a node on the fly such that we can return the important information
        else 
        {
            m_startLevelCallback(id, null, null);
        }
    }
    
    /**
     * Go to the next level in the progression
     */
    public function goToNextLevel() : Void
    {
        // If we have a next level already determined from a previous end level, this is the point where
        // we send a signal that it is ready to play.
        if (m_savedNextLevelLeaf != null) 
        {
            this.goToLevelById(m_savedNextLevelLeaf.nodeName);
            m_savedNextLevelLeaf = null;
        }
        else if (m_noNextLevelCallback != null) 
        {
            m_noNextLevelCallback();
        }
    }
    
    /*
    TODO:
    Reset state on edge conditions where the starting node is not part of the current node.
    For example, suppose we have a condition where the player needs to finish k of n levels
    proficiently. Should the player go to a different set and return, they would need to start
    over.
    */
    
    /**
     * 
     * @param id
     *      The id of a level 'leaf' in the sequence graph
     * @return
     *      The element at the head, is the level itself. The element at the end of the list is
     *      the top most node. List is empty is no level matches the id
     */
    private function getNodesContainingCurrentLevel(id : String) : Array<ICgsLevelNode>
    {
        var currentLevelLeaf : WordProblemLevelLeaf = try cast(this.currentLevelProgression.getNodeByName(id), WordProblemLevelLeaf) catch(e:Dynamic) null;
        var nodesContainingCurrentLevel : Array<ICgsLevelNode> = new Array<ICgsLevelNode>();
        nodesContainingCurrentLevel.push(currentLevelLeaf);
        var parentLevelSet : ICgsLevelPack = currentLevelLeaf.getParent();
        
        // Trace up from current leaf and keep track of all nodes on the path
        while (parentLevelSet != null && Std.is(parentLevelSet, WordProblemLevelPack))
        {
            nodesContainingCurrentLevel.push(parentLevelSet);
            parentLevelSet = (try cast(parentLevelSet, WordProblemLevelPack) catch(e:Dynamic) null).getParent();
        }
        return nodesContainingCurrentLevel;
    }
    
    
    /**
     * End the current level
     * 
     * @param id
     *      Unique name for the level to terminate
     * @param data
     *      These are details about how the user completed the level. Properties are:
     *      'endType'->whether the player skipped, finished, or quit
     *      'score'->points earned during the play though
     */
    public function endLevel(id : String, data : LevelStatistics) : Void
    {
        // At this point we may need to figure out what the next level to play should be
        // The next level may depend on the player's performance in the current level
        var currentLevelLeaf : WordProblemLevelLeaf = try cast(this.currentLevelProgression.getNodeByName(id), WordProblemLevelLeaf) catch(e:Dynamic) null;
        var currentLevelLeafSaveData : Dynamic = { };
        var currentCompletionStatus : Int = Std.int(currentLevelLeaf.completionValue);
        var newCompletionStatus : Int = LevelNodeCompletionValues.UNKNOWN;
        
        // Do not mark as complete if they skipped, solved using a cheat hint, or quit in the middle
        if (data.endType == LevelEndTypes.SKIPPED ||
            data.endType == LevelEndTypes.SOLVED_USING_CHEAT ||
            data.endType == LevelEndTypes.QUIT_BEFORE_SOLVING) 
        {
            newCompletionStatus = LevelNodeCompletionValues.PLAYED_FAIL;
        }
        else if (data.endType == LevelEndTypes.SOLVED_ON_OWN) 
        {
            newCompletionStatus = LevelNodeCompletionValues.PLAYED_SUCCESS;
        }
        
        if (currentCompletionStatus < newCompletionStatus) 
        {
			Reflect.setField(currentLevelLeafSaveData, LevelNodeSaveKeys.COMPLETION_VALUE, newCompletionStatus);
        }
		
		// Objectives+Score progress should only be updated if the player completed the level  
        if (newCompletionStatus == LevelNodeCompletionValues.PLAYED_SUCCESS) 
        {
			Reflect.setField(currentLevelLeafSaveData, LevelNodeSaveKeys.HIGH_SCORE, data.gradeFromSummaryObjectives);
        }
        
        if (currentLevelLeaf.getSavePerformanceStateAcrossInstances()) 
        {
			Reflect.setField(currentLevelLeafSaveData, LevelNodeSaveKeys.PERFORMANCE_STATE, data.serialize());
        }
		
		// Update the save data progress of the current level  		
		// Only need to do this if the completion status has increased or a better high score was achieved.
        currentLevelLeaf.updateNode(currentLevelLeaf.nodeLabel, currentLevelLeafSaveData);
        
        // Determine what the next level to play should be.
        // Transitions are based on edge information between nodes that was encoded in the level seqeunce json data.
        // If no edge were explicitly defined for the current state, we fallback to the default behavior of going to
        // the next level leaf in the order specified in the json.
        var edgeSelected : Dynamic = null;
        
        // The level just played might be nested in several level sets and each of those sets might have edge transitions too.
        // The edges involving nodes at upper nested levels take priority, check if we use those transitions first
        // Trace up to the layer of nodes just below the chapters, the nodes below this level form the level graph we care about.
        // This is the set of 'states' that the just completed level leaf is contained within so they are all possible candiate
        // to take transitions from.
        var nodesContainingCurrentLevel : Array<ICgsLevelNode> = getNodesContainingCurrentLevel(id);
        
        var parentLevelSet : ICgsLevelPack = currentLevelLeaf.getParent();
        
        // Iterate through the start of the edge list and check for ones where the starting
        // node is in one we are currently in.
        // If a node in the path contains outgoing edges, update all the condition objects
        var i : Int;
        var numEdges : Int = m_nodeEdges.length;
        var closestAncestorWithASpecifiedEdge : ICgsLevelNode = null;
        for (i in 0...numEdges){
            var edgeObject : Dynamic = m_nodeEdges[i];
            var startNodeIdForEdge : String = edgeObject.startId;
            
            // Check if an edges matches one of the set the current level node is contained within
            var numNodesToCheckEdges : Int = nodesContainingCurrentLevel.length;
            var j : Int;
            var k : Int;
            for (j in 0...numNodesToCheckEdges){
                // If an edge is outgoing from a set, we test whether we should take this edge
                var nodeContainingLevel : ICgsLevelNode = nodesContainingCurrentLevel[j];
                if (nodeContainingLevel.nodeName == startNodeIdForEdge) 
                {
                    closestAncestorWithASpecifiedEdge = nodeContainingLevel;
                    
                    // Update all the conditions at that edge
                    var conditionsList : Array<ICondition> = m_edgeIdToConditionsList[edgeObject.id];
                    if (conditionsList != null) 
                    {
                        for (k in 0...conditionsList.length){
                            updateCondition(conditionsList[k], data, currentLevelLeaf);
                        }  // If the conditions for an edge passed then we immediately take that transition  
                        
                        
                        
                        if (edgeConditionsPassed(conditionsList)) 
                        {
                            edgeSelected = edgeObject;
                            break;
                        }
                    }
                }
            }
            
            if (edgeSelected != null) 
            {
                // Record the edge id taken for other scripts to read (needed for logger to send this info)
                data.levelGraphEdgeIdTaken = edgeSelected.id;
                break;
            }
        }
        
        var nextLevelNode : WordProblemLevelLeaf = null;
        
        // If an edge was specified and the conditions passed then go to the end node of that edge
        if (edgeSelected != null) 
        {
            // It is possible the node goes to a 'null' end value which means don't go to any next
            // level, which can be interpreted as kick the player back out to the level select the next time
            // the 'next' level is requested.
            var noNextLevelExplicitlyRequested : Bool = edgeSelected.endId == "";
			var nodeAtEnd : ICgsLevelNode = null;
            if (!noNextLevelExplicitlyRequested) 
            {
                nodeAtEnd = this.currentLevelProgression.getNodeByName(edgeSelected.endId);
                if (nodeAtEnd != null && Std.is(nodeAtEnd, WordProblemLevelLeaf)) 
                {
                    nextLevelNode = try cast(nodeAtEnd, WordProblemLevelLeaf) catch(e:Dynamic) null;
                }
            }  // Edges may have actions bound to them we perform them  
            
            
            
            if (edgeSelected.exists("actions")) 
            {
                var actions : Array<Dynamic> = edgeSelected.actions;
                for (i in 0...actions.length){
                    var action : Dynamic = actions[i];
                    var actionType : String = action.type;
                    
                    // Pick a random node at the new node that isn't marked as complete
                    if (actionType == LevelNodeActions.PICK_RANDOM_UNCOMPLETED_LEVEL) 
                    {
                        nextLevelNode = getNextLeafFromSelectionPolicy(nodeAtEnd, actionType);
                    }
                    else if (actionType == LevelNodeActions.PICK_FIRST_LEVEL) 
                    {
                        nextLevelNode = try cast(this.getNextLevel(currentLevelLeaf), WordProblemLevelLeaf) catch(e:Dynamic) null;
                    }
                    else if (actionType == LevelNodeActions.PICK_NEXT_IN_SET) 
                    {
                        var outNodesInSet : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
                        WordProblemCgsLevelManager.getLevelNodes(outNodesInSet, nodeAtEnd);
                        var indexOfCurrent : Int = Lambda.indexOf(outNodesInSet, currentLevelLeaf);
                        if (outNodesInSet.length > 0 && indexOfCurrent >= 0) 
                        {
                            var nextIndex : Int = indexOfCurrent + 1;
                            if (nextIndex >= outNodesInSet.length) 
                            {
                                nextIndex = 0;
                            }
                            nextLevelNode = outNodesInSet[nextIndex];
                        }
                    }
                    // Action to alter the completion value of a particular node
                    else if (actionType == LevelNodeActions.SET_NODE_COMPLETE) 
                    {
                        var nodeName : String = action.name;
                        updateNodeWithNewCompletionValue(this.getNodeByName(nodeName), LevelNodeCompletionValues.PLAYED_SUCCESS);
                    }
                    else if (actionType == LevelNodeActions.SET_NODE_AVAILABLE) 
                    {
                        var nodeName = action.name;
                        updateNodeWithNewCompletionValue(this.getNodeByName(nodeName), LevelNodeCompletionValues.UNPLAYED);
                    }
                    // Action saying the app should send a message that mastery was achieved
                    else if (actionType == LevelNodeActions.SET_MASTERY) 
                    {
                        // Mastery is a single numerical id that maps to some 'topic'
                        // HACKY:
                        // (Copilot cares about this data so it needs to be stuffed in some intermediary part)
                        var masteryId : Int = action.masteryId;
                        data.masteryIdAchieved = masteryId;
                    }
                    else if (actionType == LevelNodeActions.CLEAR_CONDITIONS_FOR_EDGE) 
                    {
                        // Search for edges matching the target id and clear all condition state
                        var edgeIdToClear : String = Std.string(action.edgeId);
                        if (m_edgeIdToConditionsList.exists(edgeIdToClear)) 
                        {
                            var conditionsToClear : Array<ICondition> = Reflect.field(m_edgeIdToConditionsList, edgeIdToClear);
                            for (conditionToClear in conditionsToClear)
                            {
                                conditionToClear.clearState();
                            }
                        }
                    }
                    else if (actionType == LevelNodeActions.CLEAR_PERFORMANCE_STATE_FOR_NODE) 
                    {
                        // For a particular leaf node or the children leaves, reset all saved performance data
                        // back to default starting values
                        var nodeName = action.name;
                        var outLevelLeafNodes : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
                        WordProblemCgsLevelManager.getLevelNodes(outLevelLeafNodes, this.getNodeByName(nodeName));
                        for (outLevelLeaf in outLevelLeafNodes)
                        {
                            var resetData : Dynamic = { };
							Reflect.setField(resetData, LevelNodeSaveKeys.PERFORMANCE_STATE, null);
                            outLevelLeaf.updateNode(outLevelLeaf.nodeLabel, resetData);
                        }
                    }
                }
            }
			
			// If an action did not end up picking the next level and the end node is a level set  
			// we need to decide which node in the set to start, use the selection policy on that set
            // DO NOT do this if an edge explicitly marked an empty or null node as the end
            if (!noNextLevelExplicitlyRequested && nextLevelNode == null && Std.is(nodeAtEnd, WordProblemLevelPack)) 
            {
                nextLevelNode = this.getNextLeafFromSelectionPolicy(nodeAtEnd, (try cast(nodeAtEnd, WordProblemLevelPack) catch(e:Dynamic) null).getSelectionPolicy());
            }
        }
        // If no edge selected, we just directly go to the next node in the sequence
        // Do this only if no ancestors (including this node itself) have an edge specified or
        // the next node is contained within the closest ancestor
        // This is to make sure auto-progressing is not override the logic of the specified edge
        else 
        {
            // TODO: This is always getting the very next level LEAF, the next node sibling might actually
            // be a set which has a selection policy we should use instead.
            nextLevelNode = try cast(this.getNextLevel(currentLevelLeaf), WordProblemLevelLeaf) catch(e:Dynamic) null;
            
            // If the closest ancestor is the node itself then cannot auto progress since that would override the edge data
            if (closestAncestorWithASpecifiedEdge != null && currentLevelLeaf != closestAncestorWithASpecifiedEdge) 
            {
                // Make sure the next node is contained
                var nextNodeContainedInAncestorWithEdge : Bool = false;
                var parentPack : ICgsLevelPack = nextLevelNode.getParent();
                while (Std.is(parentPack, WordProblemLevelPack))
                {
                    if (parentPack == closestAncestorWithASpecifiedEdge) 
                    {
                        nextNodeContainedInAncestorWithEdge = true;
                        break;
                    }
                    else 
                    {
                        parentPack = (try cast(parentPack, WordProblemLevelPack) catch(e:Dynamic) null).getParent();
                    }
                }  // in the ancestor. We are stuck at the node    // Next node not allowed to go to a different part of the graph that is not contained  
                
                
                
                
                
                if (!nextNodeContainedInAncestorWithEdge) 
                {
                    nextLevelNode = currentLevelLeaf;
                }
            }
            // Important! We do not treat each genre as a linear sequence.
            // Once a player finished the last level in a genre, we jump them back to the
            // main level select screen
            // We check if the current finished level is the last in the genre
            // If the exit condition is a quit and there is no edge selected, the next node should exactly be the
            // level that was just quit. If they disconnect at this point, the next level they go to should
            // be the one exited.
            else if (closestAncestorWithASpecifiedEdge == null) 
            {
                if (currentLevelLeaf.parentGenreLevelPack != null) 
                {
					m_outLevelBuffer = new Array<WordProblemLevelLeaf>();
                    WordProblemCgsLevelManager.getLevelNodes(m_outLevelBuffer, currentLevelLeaf.parentGenreLevelPack);
                    if (m_outLevelBuffer[m_outLevelBuffer.length - 1] == currentLevelLeaf) 
                    {
                        nextLevelNode = null;
                    }
                }
            }
            
            if (data.endType == LevelEndTypes.QUIT_BEFORE_SOLVING) 
            {
                nextLevelNode = currentLevelLeaf;
            }
        }
        
        if (m_cache != null) 
        {
            // Must save the next level AND state within the conditions
            // For the set of states the player will be in for the next level, several outgoing edges
            // have state (like total levels in row for current node) that need to be remembered
            // Only care about conditions in states the next level is part of and already exist
            var saveDataForAllEdges : Dynamic = { };  // Blob for all conditions  
            var numEdgesToSave : Int = 0;
            var edgeIdsInTheNexLevel : Array<String> = new Array<String>();
            if (nextLevelNode != null) 
            {
				nodesContainingCurrentLevel = new Array<ICgsLevelNode>();
                nodesContainingCurrentLevel.push(nextLevelNode);
                parentLevelSet = nextLevelNode.getParent();
                
                // Trace up from current leaf and keep track of all nodes on the path
                while (parentLevelSet != null && Std.is(parentLevelSet, WordProblemLevelPack))
                {
                    nodesContainingCurrentLevel.push(parentLevelSet);
                    parentLevelSet = (try cast(parentLevelSet, WordProblemLevelPack) catch(e:Dynamic) null).getParent();
                }  // again need to iterate through all edges to find a match    // Want to identify all outgoing edges from the next level node,  
                
                
                
                
                
                for (i in 0...m_nodeEdges.length){
                    var edgeObject = m_nodeEdges[i];
                    var startNodeIdForEdge = edgeObject.startId;
                    for (j in 0...nodesContainingCurrentLevel.length){
                        if (startNodeIdForEdge == nodesContainingCurrentLevel[j].nodeName) 
                        {
                            var edgeId : String = edgeObject.id;
                            edgeIdsInTheNexLevel.push(edgeId);
                            
                            // Only care about previously created conditions
                            // This is because the new nodes without conditions have starting
                            // values that are empty anyways
                            if (m_edgeIdToConditionsList.exists(edgeId)) 
                            {
                                var saveForEdge : Dynamic = null;
                                var conditionsForEdge : Array<ICondition> = Reflect.field(m_edgeIdToConditionsList, edgeId);
                                for (k in 0...conditionsForEdge.length){
                                    var saveForCondition : Dynamic = conditionsForEdge[k].serialize();
                                    if (saveForCondition != null) 
                                    {
                                        if (saveForEdge == null) 
                                        {
                                            saveForEdge = { };
                                        }
										
										// Index for condition maps to serialized version of that condition  
                                        saveForEdge[k] = saveForCondition;
                                    }
                                }
                                
                                if (saveForEdge != null) 
                                {
                                    numEdgesToSave++;
                                    
                                    // Edge id maps to collection of condition indices to serialized condition objects
                                    Reflect.setField(saveDataForAllEdges, edgeId, saveForEdge);
                                }
                            }
							
							// Assume nodes have unique names  
                            break;
                        }
                    }
                }
            }
            
            var newCurrentLevelStateSaveData : Dynamic = { };
            if (nextLevelNode != null) 
            {
                Reflect.setField(newCurrentLevelStateSaveData, CURRENT_LEVEL_NAME_SAVE_KEY, nextLevelNode.nodeName);
            }
            
            if (numEdgesToSave > 0) 
            {
                Reflect.setField(newCurrentLevelStateSaveData, CURRENT_LEVEL_CONDITIONS_SAVE_KEY, saveDataForAllEdges);
            }
            m_cache.setSave(CURRENT_LEVEL_STATE_SAVE_KEY, newCurrentLevelStateSaveData, false);
            
            m_cache.flush();
        }  
		
		// The edge id to condition map no longer needs conditions bound to nodes we are no longer in.  
		// We need to identify which of these edges we no longer need and dispose of them
		m_savedNextLevelLeaf = nextLevelNode;
    }
    
    private function updateNodeWithNewCompletionValue(node : ICgsLevelNode, newCompletionValue : Int) : Void
    {
        var newNextLevelStatus : Dynamic = { };
		Reflect.setField(newNextLevelStatus, LevelNodeSaveKeys.COMPLETION_VALUE, newCompletionValue);
        node.updateNode(node.nodeLabel, newNextLevelStatus);
    }
    
    private function getNextLeafFromSelectionPolicy(node : ICgsLevelNode, selectionPolicy : String) : WordProblemLevelLeaf
    {
        var nextLeaf : WordProblemLevelLeaf = null;
        if (Std.is(node, WordProblemLevelLeaf)) 
        {
            nextLeaf = try cast(node, WordProblemLevelLeaf) catch(e:Dynamic) null;
        }
        else if (Std.is(node, WordProblemLevelPack)) 
        {
            var levelPack : WordProblemLevelPack = try cast(node, WordProblemLevelPack) catch(e:Dynamic) null;
            var childNodes : Array<ICgsLevelNode> = levelPack.nodes;
            var selectedChild : ICgsLevelNode = null;
            if (selectionPolicy == LevelNodeActions.PICK_RANDOM_UNCOMPLETED_LEVEL) 
            {
                var candidateNodes : Array<ICgsLevelNode> = new Array<ICgsLevelNode>();
                var i : Int;
                var childNode : ICgsLevelNode;
                for (i in 0...childNodes.length){
                    childNode = childNodes[i];
                    if (!childNode.isComplete) 
                    {
                        candidateNodes.push(childNode);
                    }
                }
                
                if (candidateNodes.length > 0) 
                {
                    selectedChild = candidateNodes[m_randomGenerator.nextIntRange(0, candidateNodes.length - 1)];
                }
                else 
                {
                    // If all complete then pick any of the existing ones
                    selectedChild = childNodes[m_randomGenerator.nextIntRange(0, childNodes.length - 1)];
                }
            }
            // Default policy is first uncompleted
            else 
            {
                for (i in 0...childNodes.length){
                    var childNode = childNodes[i];
                    if (!childNode.isComplete && !childNode.isLocked) 
                    {
                        selectedChild = childNode;
                        break;
                    }
                }  // if none still fit then just pick the first one  
                
                
                
                if (selectedChild == null && childNodes.length > 0) 
                {
                    selectedChild = childNodes[0];
                }
            }
            
            if (selectedChild != null) 
            {
                // Perform recursive selection until we get a level leaf representing a single level
                var childSelectionPolicy : String = ((Std.is(selectedChild, WordProblemLevelPack))) ? 
                (try cast(selectedChild, WordProblemLevelPack) catch(e:Dynamic) null).getSelectionPolicy() : null;
                nextLeaf = getNextLeafFromSelectionPolicy(selectedChild, childSelectionPolicy);
            }
        }
        
        return nextLeaf;
    }
    
    public function getGenreNodes(outGenreNodes : Array<GenreLevelPack>) : Void
    {
        _getGenreNodes(this.currentLevelProgression, outGenreNodes);
    }
    
    private function _getGenreNodes(root : ICgsLevelPack, outGenreNodes : Array<GenreLevelPack>) : Void
    {
        // Once we find a genre node, we can kill the search at this node.
        // This assumes a genre CANNOT be nested within another genre.
        if (Std.is(root, GenreLevelPack)) 
        {
            outGenreNodes.push(try cast(root, GenreLevelPack) catch(e:Dynamic) null);
        }
        else 
        {
            var children : Array<ICgsLevelNode> = root.nodes;
            var i : Int;
            var child : ICgsLevelNode;
            for (i in 0...children.length){
                child = children[i];
                
                if (Std.is(child, ICgsLevelPack)) 
                {
                    _getGenreNodes(try cast(child, ICgsLevelPack) catch(e:Dynamic) null, outGenreNodes);
                }
            }
        }
    }
    
    /**
     * From json formatted string create a condition object that stores state and has logic to
     * determine if the condition for an edge has been satisfied.
     */
    private function createCondition(data : Dynamic) : ICondition
    {
        var type : String = data.type;
        var condition : ICondition = null;
        if (type == KOutOfNProficientCondition.TYPE) 
        {
            condition = new KOutOfNProficientCondition();
        }
        else if (type == NLevelsCompletedCondition.TYPE) 
        {
            condition = new NLevelsCompletedCondition();
        }
        else if (type == NodeStatusCondition.TYPE) 
        {
            condition = new NodeStatusCondition();
        }
        else 
        {
            throw new Error("Invalid condition named: " + type + " defined in progression json");
        }
        
        condition.deserialize(data);
        return condition;
    }
    
    /**
     * Some of the conditions have persistent state that needs to be updated in order for the checks
     * to correctly pass. Other times they might read from a data source in which is constantly changing.
     * An example might be a condition checking whether number of all levels attempted is greater than n.
     * Global data like that isn't nicely isolated, so we need to explicitly keep track
     * 
     * Not all conditions need to update, for example the TrueCondition has a fixed value.
     */
    private function updateCondition(condition : ICondition,
            data : LevelStatistics,
            currentLevelLeaf : WordProblemLevelLeaf) : Void
    {
        var type : String = condition.getType();
        if (type == KOutOfNProficientCondition.TYPE) 
        {
            var kOfNCondition : KOutOfNProficientCondition = try cast(condition, KOutOfNProficientCondition) catch(e:Dynamic) null;
            var objectives : Array<BaseObjective> = Reflect.field(m_objectiveClassIdToObjectives, kOfNCondition.getObjectiveClass());
            kOfNCondition.update(currentLevelLeaf, data, objectives);
        }
        else if (type == NLevelsCompletedCondition.TYPE) 
        {
            (try cast(condition, NLevelsCompletedCondition) catch(e:Dynamic) null).update(data);
        }
        else if (type == NodeStatusCondition.TYPE) 
        {
            (try cast(condition, NodeStatusCondition) catch(e:Dynamic) null).update(this);
        }
    }
    
    /**
     * When determining the next level to play, the current node that was just played may have an outgoing
     * edge to a next level. Each edge has some condition that needs to be checked.
     * 
     * @return
     *      True if all conditions were satisfied or no conditions were specified in the list
     */
    private function edgeConditionsPassed(conditions : Array<ICondition>) : Bool
    {
        var allConditionsPassed : Bool = true;
        var i : Int;
        var numConditions : Int = conditions.length;
        for (i in 0...numConditions){
            var condition : ICondition = conditions[i];
            if (!condition.getSatisfied()) 
            {
                allConditionsPassed = false;
                break;
            }
        }
        
        return allConditionsPassed;
    }
    
    /**
     * @inheritDoc
     */
    public function init(levelData : Dynamic = null) : Void
    {
        // Level Progression
        m_rootLevelProgression = try cast(m_levelFactory.getNodeInstance(m_levelFactory.defaultLevelPackType), ICgsLevelPack) catch(e:Dynamic) null;
        m_rootLevelProgression.init(null, null, levelData);
    }
    
    /**
     * @inheritDoc
     */
    public function reset() : Void
    {
        m_levelFactory.recycleNodeInstance(m_rootLevelProgression);
        m_rootLevelProgression = null;
    }
    
    /**
     * @inheritDoc
     */
    private function get_currentLevel() : ICgsLevelLeaf
    {
        return m_savedNextLevelLeaf;
    }
    
    /**
     * @inheritDoc
     */
    private function get_currentLevelProgression() : ICgsLevelPack
    {
        return m_rootLevelProgression;
    }
    
    /**
     * @inheritDoc
     */
    private function get_resourceManager() : ICgsLevelResourceManager
    {
        return m_resourceManager;
    }
    
    /**
     * @inheritDoc
     */
    private function get_achievementManager() : ICgsAchievementManager
    {
        return try cast(m_userManager.userList[0], ICgsAchievementManager) catch (e : Dynamic) null;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsCompleted() : Int
    {
        return m_rootLevelProgression.numLevelLeafsCompleted;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsUncompleted() : Int
    {
        return m_rootLevelProgression.numLevelLeafsUncompleted;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsPlayed() : Int
    {
        return m_rootLevelProgression.numLevelLeafsPlayed;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsUnplayed() : Int
    {
        return m_rootLevelProgression.numLevelLeafsUnplayed;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsLocked() : Int
    {
        return m_rootLevelProgression.numLevelLeafsLocked;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelLeafsUnlocked() : Int
    {
        return m_rootLevelProgression.numLevelLeafsUnlocked;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numTotalLevelLeafs() : Int
    {
        return m_rootLevelProgression.numTotalLevelLeafs;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksCompleted() : Int
    {
        return m_rootLevelProgression.numLevelPacksCompleted;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksUncompleted() : Int
    {
        return m_rootLevelProgression.numLevelPacksUncompleted;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksFullyPlayed() : Int
    {
        return m_rootLevelProgression.numLevelPacksFullyPlayed;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksPlayed() : Int
    {
        return m_rootLevelProgression.numLevelPacksPlayed;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksUnplayed() : Int
    {
        return m_rootLevelProgression.numLevelPacksUnplayed;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksLocked() : Int
    {
        return m_rootLevelProgression.numLevelPacksLocked;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numLevelPacksUnlocked() : Int
    {
        return m_rootLevelProgression.numLevelPacksUnlocked;
    }
    
    /**
     * @inheritDoc
     */
    private function get_numTotalLevelPacks() : Int
    {
        return m_rootLevelProgression.numTotalLevelPacks;
    }
    
    /**
     * @inheritDoc
     */
    public function getCompletionValueOfNode(nodeLabel : Int) : Float
    {
        return m_rootLevelProgression.getNode(nodeLabel).completionValue;
    }
    
    /**
     * @inheritDoc
     */
    private function get_isCompleteCompletionValue() : Float
    {
        return m_isCompleteCompletionValue;
    }
    
    /**
     * @inheritDoc
     */
    private function set_isCompleteCompletionValue(value : Float) : Float
    {
        m_isCompleteCompletionValue = value;
        return value;
    }
    
    /**
     * @inheritDoc
     */
    private function get_doCheckLocks() : Bool
    {
        return m_doCheckLocks;
    }
    
    /**
     * @inheritDoc
     */
    private function set_doCheckLocks(value : Bool) : Bool
    {
        m_doCheckLocks = value;
        return value;
    }
    
    /**
     * @inheritDoc
     */
    public function endCurrentLevel() : Void
    {
    }
    
    /**
     * @inheritDoc
     */
    public function playLevel(levelData : ICgsLevelLeaf, data : Dynamic = null) : Void
    {
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsComplete() : Void
    {
        m_rootLevelProgression.markAllLevelLeafsAsComplete();
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsPlayed() : Void
    {
        m_rootLevelProgression.markAllLevelLeafsAsPlayed();
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsUnplayed() : Void
    {
        m_rootLevelProgression.markAllLevelLeafsAsUnplayed();
    }
    
    /**
     * @inheritDoc
     */
    public function markAllLevelLeafsAsCompletionValue(value : Float) : Void
    {
        m_rootLevelProgression.markAllLevelLeafsAsCompletionValue(value);
    }
    
    /**
     * @inheritDoc
     */
    public function markCurrentLevelLeafAsCompletionValue(value : Float) : Void
    {
    }
    
    /**
     * @inheritDoc
     */
    public function markCurrentLevelLeafAsComplete() : Void
    {
        markCurrentLevelLeafAsCompletionValue(isCompleteCompletionValue);
    }
    
    /**
     * @inheritDoc
     */
    public function markCurrentLevelLeafAsPlayed() : Void
    {
        markCurrentLevelLeafAsCompletionValue(0);
    }
    
    /**
     * @inheritDoc
     */
    public function markCurrentLevelLeafAsUnplayed() : Void
    {
        markCurrentLevelLeafAsCompletionValue(-1);
    }
    
    /**
     * @inheritDoc
     */
    public function markLevelLeafAsCompletionValue(nodeLabel : Int, value : Float) : Void
    {
        var data : Dynamic = { };
		Reflect.setField(data, LevelNodeSaveKeys.COMPLETION_VALUE, value);
        m_rootLevelProgression.updateNode(nodeLabel, data);
    }
    
    /**
     * @inheritDoc
     */
    public function markLevelLeafAsComplete(nodeLabel : Int) : Void
    {
        markLevelLeafAsCompletionValue(nodeLabel, isCompleteCompletionValue);
    }
    
    /**
     * @inheritDoc
     */
    public function markLevelLeafAsPlayed(nodeLabel : Int) : Void
    {
        markLevelLeafAsCompletionValue(nodeLabel, 0);
    }
    
    /**
     * @inheritDoc
     */
    public function markLevelLeafAsUnplayed(nodeLabel : Int) : Void
    {
        markLevelLeafAsCompletionValue(nodeLabel, -1);
    }
    
    /**
     * @inheritDoc
     */
    public function addNodeToProgression(nodeData : Dynamic, parentPackName : String = null, index : Int = -1) : Void
    {
        // Add the given node to the progression.
        if (!m_rootLevelProgression.addNodeToProgression(nodeData, parentPackName, index)) 
        {
            // The add failed, so add it to the root itself.
            m_rootLevelProgression.addNodeToProgression(nodeData, m_rootLevelProgression.nodeName);
        }
    }
    
    /**
     * @inheritDoc
     */
    public function editNodeInProgression(nameOfNode : String, newNodeData : Dynamic) : Void
    {
        if (m_rootLevelProgression.nodeName == nameOfNode) 
        {
            reset();
            init(newNodeData);
        }
        else 
        {
            m_rootLevelProgression.editNodeInProgression(nameOfNode, newNodeData);
        }
    }
    
    /**
     * @inheritDoc
     */
    public function removeNodeFromProgression(nodeName : String) : Void
    {
        m_rootLevelProgression.removeNodeFromProgression(nodeName);
    }
    
    /**
     * @inheritDoc
     */
    public function getNode(nodeLabel : Int) : ICgsLevelNode
    {
        return m_rootLevelProgression.getNode(nodeLabel);
    }
    
    /**
     * @inheritDoc
     */
    public function getNodeByName(nodeName : String) : ICgsLevelNode
    {
        return m_rootLevelProgression.getNodeByName(nodeName);
    }
    
    /**
     * @inheritDoc
     */
    public function getNextLevel(presentLevel : ICgsLevelLeaf = null) : ICgsLevelLeaf
    {
        var result : ICgsLevelLeaf;
        if (presentLevel == null) 
        {
            result = m_rootLevelProgression.firstLeaf;
        }
        else 
        {
            // The next level here is literally the next one that appeared as a data chunk
            // in the raw progression input file
            result = presentLevel.nextLevel;
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function getNextLevelById(aNodeLabel : Int = -1) : ICgsLevelLeaf
    {
        return m_rootLevelProgression.getNextLevel(aNodeLabel);
    }
    
    /**
     * @inheritDoc
     */
    public function getPrevLevel(presentLevel : ICgsLevelLeaf = null) : ICgsLevelLeaf
    {
        var result : ICgsLevelLeaf;
        if (presentLevel == null) 
        {
            result = m_rootLevelProgression.firstLeaf;
        }
        else 
        {
            result = presentLevel.previousLevel;
        }
        return result;
    }
    
    /**
     * @inheritDoc
     */
    public function getPrevLevelById(aNodeLabel : Int = -1) : ICgsLevelLeaf
    {
        return m_rootLevelProgression.getPrevLevel(aNodeLabel);
    }
}
