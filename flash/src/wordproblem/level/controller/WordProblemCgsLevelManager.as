package wordproblem.level.controller
{
    import cgs.Cache.ICgsUserCache;
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
    
    import dragonbox.common.util.PM_PRNG;
    
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
    public class WordProblemCgsLevelManager implements ICgsLevelManager
    {
        /**
         * While the game is live, users might express complaints about certain levels that we decide
         * to ultimately remove from that version. However, it is possible some players have those removed
         * levels stored in the save data as the next one to go to. In the updated version they would jump into the
         * correct spot again.
         */
        private static const REMOVED_LEVEL_ID_TO_BUCKET:Object = {
        };
        
        /**
         * Recursively separate out the items in a chapter and the level not in a chapter
         */
        public static function separateChapterAndLevelNodes(outChapterNodes:Vector.<ChapterLevelPack>, 
                                                            outLevelNodesWithoutChapter:Vector.<WordProblemLevelLeaf>, 
                                                            levelNode:ICgsLevelNode):void
        {
            if (levelNode != null)
            {
                if (levelNode is WordProblemLevelLeaf)
                {
                    outLevelNodesWithoutChapter.push(levelNode);
                }
                else if (levelNode is ICgsLevelPack)
                {
                    if (levelNode is ChapterLevelPack)
                    {
                        outChapterNodes.push(levelNode as ChapterLevelPack);
                    }
                    else
                    {
                        var children:Vector.<ICgsLevelNode> = (levelNode as ICgsLevelPack).nodes;
                        var numChildren:int = children.length;
                        var i:int;
                        for (i = 0; i < numChildren; i++)
                        {
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
        public static function getLevelNodes(outLevelNodes:Vector.<WordProblemLevelLeaf>, levelNode:ICgsLevelNode):void
        {
            if (levelNode != null)
            {
                if (levelNode is WordProblemLevelLeaf)
                {
                    outLevelNodes.push(levelNode);
                }
                else if (levelNode is ICgsLevelPack)
                {
                    var children:Vector.<ICgsLevelNode> = (levelNode as ICgsLevelPack).nodes;
                    var numChildren:int = children.length;
                    var i:int;
                    for (i = 0; i < numChildren; i++)
                    {
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
        private static const CURRENT_LEVEL_STATE_SAVE_KEY:String = "cls";
        
        private static const CURRENT_LEVEL_NAME_SAVE_KEY:String = "n";
        
        private static const CURRENT_LEVEL_CONDITIONS_SAVE_KEY:String = "cnds";
        
        protected var m_rootLevelProgression:ICgsLevelPack;
        protected var m_lockFactory:ICgsLockFactory;
        protected var m_levelFactory:ICgsLevelFactory;
        protected var m_resourceManager:ICgsLevelResourceManager;
        protected var m_userManager:ICgsUserManager;
        private var m_isCompleteCompletionValue:Number = 1;
        private var m_doCheckLocks:Boolean = true;
        
        /**
         * Saved callback that will signal the outside application that they should start a
         * level with a given id and using a specific resource location.
         * Made protected so that subclass NeverEndingLevelManager can have access.
         */
        protected var m_startLevelCallback:Function;
        
        /**
         * Saved callback that will signal to the outside application that there is no next level
         * that can be played. One response to this is to kick the player back in the level select screen if this happens.
         * 
         * Accepts no params
         */
        protected var m_noNextLevelCallback:Function;
        
        /**
         * At the end of each level this manager needs to save the next level that the game should go to automatically.
         * From the perspective of the manager, the time when the next level should start after one has been completed is
         * unknown. When the game is ready to go to the next level we use this saved information.
         */
        protected var m_savedNextLevelLeaf:ICgsLevelLeaf;
        
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
        private var m_nodeEdges:Vector.<Object>;
        
        /**
         * Current state stored in conditions that are in possible edges the user can take
         * in the current level.
         * 
         * key: id of the edge
         * value: Vector of condition objects for evaluation of the edge
         */
        private var m_edgeIdToConditionsList:Object;
        
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
        private var m_objectiveClassIdToObjectives:Object;
        
        private var m_outLevelBuffer:Vector.<WordProblemLevelLeaf>;
        
        /**
         * The interface for the save data. Should be able to easily switch between saving locally and saving
         * on the server.
         */
        private var m_cache:ICgsUserCache;
        
        /**
         * Seeded random number generator.
         */
        private var m_randomGenerator:PM_PRNG;
        
        /**
         * The current progression resource that was set
         * (Exposed only so the game can automatically refetch the progression on a reset)
         */
        public var progressionResourceName:String;
        
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
        public function WordProblemCgsLevelManager(userManager:ICgsUserManager,
                                                   resourceManager:AssetManager, 
                                                   startCallback:Function, 
                                                   noLevelCallback:Function, 
                                                   doCheckLocks:Boolean=true)
        {
            m_userManager = userManager;
            
            // Creates all the managers and factories
            // DO NOT call super as it does not set the properties we want in the right order
            m_lockFactory = new WordProblemLockFactory(this);
            m_resourceManager = resourceManager;
            m_startLevelCallback = startCallback; 
            m_noNextLevelCallback = noLevelCallback;
            
            // The level manager creates a default sequential locking system on level sequences
            // It seems as though the lock is placed on all but the first level in the sequence, those
            // level that have locks on them should only be unlocked if the prior level was completed
            // (default condition was just if they were at all played, which checks completion value)
            
            // Set the value that a leaf takes to indicate that a level is completed
            m_isCompleteCompletionValue = LevelNodeCompletionValues.PLAYED_SUCCESS;
            
            m_outLevelBuffer = new Vector.<WordProblemLevelLeaf>();
            
            // For this session, the random generator reuses the same seed
            m_randomGenerator = PM_PRNG.createGen(null);
			m_randomGenerator.seed = 42;
            this.doCheckLocks = doCheckLocks;
        }
        
        /*
         * @return Object mapping from Edge ID(int) to Conditions List(Vector.<ICondition>) which are active for the current level
         */
        public function getEdgeIdToConditionsList():Object {
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
        public function setToNewLevelProgression(progressionResourceName:String, 
                                                 cache:ICgsUserCache, 
                                                 preprocessCallback:Function=null):void
        {
            // The asset manager has the general level sequence template
            // Note that this init function also loads in save data into the graph
            this.progressionResourceName = progressionResourceName;
            var levelObject:Object = (this.resourceManager as AssetManager).getObject(progressionResourceName);
            if (preprocessCallback != null)
            {
                preprocessCallback(levelObject);
            }
            
            if (cache != null)
            {
                m_cache = cache;
            }
            else if (m_userManager.userList.length > 0)
            {
                m_cache = m_userManager.userList[0];
            }
            
            // MUST recreate the factory so the new cache is used
            m_levelFactory = new WordProblemLevelFactory(this, m_lockFactory, m_userManager, cache);
            
            if (m_rootLevelProgression != null)
            {
                this.reset();
            }
            
            this.init(levelObject);
            
            // IMPORTANT NOTE: The current node and its parent form the nodes the player is in.
            
            // Get all save data related to the state the player is in
            if (m_cache.saveExists(CURRENT_LEVEL_STATE_SAVE_KEY))
            {
                var clsSaveBlob:Object = m_cache.getSave(CURRENT_LEVEL_STATE_SAVE_KEY);
                if (clsSaveBlob == null)
                {
                    clsSaveBlob = {};
                }
                
                if (clsSaveBlob.hasOwnProperty(CURRENT_LEVEL_NAME_SAVE_KEY))
                {
                    var nextNodeName:String = clsSaveBlob[CURRENT_LEVEL_NAME_SAVE_KEY];
                    
                    // If the next node was something that was retroactively deleted, we need to
                    // pick an equivalent node
                    if (WordProblemCgsLevelManager.REMOVED_LEVEL_ID_TO_BUCKET.hasOwnProperty(nextNodeName))
                    {
                        var candidateBucketName:String = WordProblemCgsLevelManager.REMOVED_LEVEL_ID_TO_BUCKET[nextNodeName];
                        m_savedNextLevelLeaf = this.getNextLeafFromSelectionPolicy(this.getNodeByName(candidateBucketName), null);
                    }
                    else
                    {
                        m_savedNextLevelLeaf = this.getNodeByName(nextNodeName) as WordProblemLevelLeaf;
                    }
                }
                
                if (clsSaveBlob.hasOwnProperty(CURRENT_LEVEL_CONDITIONS_SAVE_KEY))
                {
                    var localConditionSavedData:Object = clsSaveBlob[CURRENT_LEVEL_CONDITIONS_SAVE_KEY];
                }
            }
            
            // The progression object has an optional extra property to indicate the exact node that acts as the starting
            // point in the graph.
            // This is useful the very first time the player enters and they have no saved data where they were.
            // If starting point not specified we pick the very first level in the list.
            if (m_savedNextLevelLeaf == null)
            {
                // Restriction: start node name must be a leaf node
                if (levelObject.hasOwnProperty("startNodeName"))
                {
                    var startingNode:WordProblemLevelLeaf = this.getNodeByName(levelObject.startNodeName) as WordProblemLevelLeaf;
                    if (startingNode != null)
                    {
                        m_savedNextLevelLeaf = startingNode;
                    }
                }
                
                // No valid start means we pick first level in list
                if (m_savedNextLevelLeaf == null)
                {
                    m_savedNextLevelLeaf = this.currentLevelProgression.firstLeaf as WordProblemLevelLeaf;
                }
            }
            
            m_edgeIdToConditionsList = {};
            
            // Part of the root level object is a list of edge objects
            m_nodeEdges = new Vector.<Object>();
            if (levelObject.hasOwnProperty("edges"))
            {
                // Convert the array into mappings
                // The reason is we only care about edge order in terms of the outgoing edges per node
                var edgeList:Array = levelObject.edges;
                var numEdges:int = edgeList.length;
                for (i = 0; i < numEdges; i++)
                {
                    var edgeObject:Object = edgeList[i];
                    m_nodeEdges.push(edgeObject);
                    
                    // Go through the conditions of the edge and inject save data if it exists
                    if (edgeObject.hasOwnProperty("conditions") && localConditionSavedData != null && localConditionSavedData.hasOwnProperty(edgeObject.id))
                    {
                        var conditions:Array = edgeObject.conditions;
                        var conditionIndexToSaveBlob:Object = localConditionSavedData[edgeObject.id];
                        for (j = 0; j < conditions.length; j++)
                        {
                            // Stuffing extra serialized save property into condition object if it exists
                            var index:String = j.toString();
                            if (conditionIndexToSaveBlob.hasOwnProperty(index))
                            {
                                conditions[j].save = conditionIndexToSaveBlob[index];
                            }
                        }
                    }
                }
            }
            
            // Parse the special objective groups used by some of the conditions
            // Condition may link to a group to see if all of those objectives in a level
            // were accomplished.
            m_objectiveClassIdToObjectives = {};
            if (levelObject.hasOwnProperty("objectiveClasses"))
            {
                var objectiveClassList:Array = levelObject.objectiveClasses;
                var numObjectiveClasses:int = objectiveClassList.length;
                for (i = 0; i < numObjectiveClasses; i++)
                {
                    var objectiveClass:Object = objectiveClassList[i];
                    var objectiveObjects:Vector.<BaseObjective> = ObjectivesFactory.getObjectivesFromJsonArray(
                        objectiveClass.objectives
                    );
                    m_objectiveClassIdToObjectives[objectiveClass.id] = objectiveObjects;
                }
            }
            
            // Post process after the graph has been created, go through each chapter and level
            // and assign an index to them
            var genreLevelPacks:Vector.<GenreLevelPack> = new Vector.<GenreLevelPack>();
            var chapterNodesInGenre:Vector.<ChapterLevelPack> = new Vector.<ChapterLevelPack>();
            var levelNodesWithoutChapterInGenre:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
            var levelNodesInChapter:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
            this.getGenreNodes(genreLevelPacks);
            for each (var genreLevelPack:GenreLevelPack in genreLevelPacks)
            {
                WordProblemCgsLevelManager.separateChapterAndLevelNodes(chapterNodesInGenre, levelNodesWithoutChapterInGenre, genreLevelPack);
                var i:int;
                var numChapterNodes:int = chapterNodesInGenre.length;
                var chapterLevelPack:ChapterLevelPack;
                for (i = 0; i < numChapterNodes; i++)
                {
                    chapterLevelPack = chapterNodesInGenre[i];
                    chapterLevelPack.index = i;
                    
                    // Set parent genre and chapter for levels in a chapter
                    WordProblemCgsLevelManager.getLevelNodes(levelNodesInChapter, chapterLevelPack);
                    var j:int;
                    var levelNodeInChapter:WordProblemLevelLeaf;
                    var numLevelNodesInChapter:int = levelNodesInChapter.length;
                    for (j = 0; j < numLevelNodesInChapter; j++)
                    {
                        levelNodeInChapter = levelNodesInChapter[j];
                        levelNodeInChapter.index = j;
                        levelNodeInChapter.parentChapterLevelPack = chapterLevelPack;
                        levelNodeInChapter.parentGenreLevelPack = genreLevelPack;
                    }
                    
                    // Clear buffer for next chapter
                    levelNodesInChapter.length = 0;
                }
                
                // Set parent genre and index for levels without a chapter
                var numLevelNodesWithoutChapter:int = levelNodesWithoutChapterInGenre.length;
                var levelLeafWithoutChapter:WordProblemLevelLeaf;
                for (i = 0; i < numLevelNodesWithoutChapter; i++)
                {
                    levelLeafWithoutChapter = levelNodesWithoutChapterInGenre[i] as WordProblemLevelLeaf;
                    levelLeafWithoutChapter.index = i;
                    levelLeafWithoutChapter.parentGenreLevelPack = genreLevelPack;
                }
                
                // Clear buffers for next genre
                chapterNodesInGenre.length = 0;
                levelNodesWithoutChapterInGenre.length = 0;
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
        public function setNextLevelLeaf(leaf:WordProblemLevelLeaf):void
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
        public function goToLevelById(id:String):void
        {
            var levelNode:ICgsLevelNode = currentLevelProgression.getNodeByName(id);
            if (m_startLevelCallback != null && levelNode != null)
            {
                // If the level to go to is actually a level pack, we determine the leaf based on the selection policy set
                // on that pack
                if (levelNode is WordProblemLevelPack)
                {
                    levelNode = this.getNextLeafFromSelectionPolicy(levelNode, (levelNode as WordProblemLevelPack).getSelectionPolicy());
                }

                // The application may need to know extra data about where in the progression the level
                // is for drawing purposes.
                var extraLevelProgressionData:Object = null;
                if (levelNode is WordProblemLevelLeaf)
                {
                    var wordProblemLeaf:WordProblemLevelLeaf = levelNode as WordProblemLevelLeaf;
                    extraLevelProgressionData = {
                        genreId: wordProblemLeaf.parentGenreLevelPack.getThemeId(),
                        chapterIndex: wordProblemLeaf.parentChapterLevelPack.index,
                        levelIndex: wordProblemLeaf.index,
                        skippable: wordProblemLeaf.getSkippable(),
                        isProblemCreate: wordProblemLeaf.getIsProblemCreate(),
                        previousCompletionStatus: wordProblemLeaf.completionValue,
                        tags: wordProblemLeaf.getTags()
                    };
                    
                    // If a node does not explicitly define rules to override check if parent node
                    // have this information. Inherit the entire rule set from the closest parent
                    getInheritedProperty(function(levelNode:WordProblemLevelNode):Boolean
                    {
                        var isInherited:Boolean = false;
                        if (levelNode.getOverriddenRules() != null)
                        {
                            extraLevelProgressionData["rules"] = levelNode.getOverriddenRules();
                            isInherited = true;
                        }
                        return isInherited;
                    }, wordProblemLeaf);
                    
                    // Search for the data about prepopulating the equation area
                    getInheritedProperty(function(levelNode:WordProblemLevelNode):Boolean
                    {
                        var isInherited:Boolean = false;
                        if (levelNode.getPrepopulateEquationData() != null)
                        {
                            extraLevelProgressionData["prepopulateEquation"] = levelNode.getPrepopulateEquationData();
                            isInherited = true;
                        }
                        return isInherited;
                    }, wordProblemLeaf);
                    
                    // Get the difficulty level
                    getInheritedProperty(function(levelNode:WordProblemLevelNode):Boolean
                    {
                        var isInherited:Boolean = false;
                        if (levelNode.getDifficultySet())
                        {
                            extraLevelProgressionData["difficulty"] = levelNode.getDifficulty();
                            isInherited = true;
                        }
                        return isInherited;
                    }, wordProblemLeaf);
                    
                    function getInheritedProperty(checkPropertyIsInherited:Function, startingNode:ICgsStatusNode):void
                    {
                        var trackingNode:ICgsStatusNode = wordProblemLeaf;
                        var continueSearch:Boolean = true;
                        while (trackingNode != null && trackingNode is WordProblemLevelNode && continueSearch)
                        {
                            var trackingNodeTemp:WordProblemLevelNode = trackingNode as WordProblemLevelNode;
                            if (checkPropertyIsInherited(trackingNodeTemp))
                            {
                                continueSearch = false;
                            }
                            else
                            {
                                if (trackingNode is WordProblemLevelLeaf)
                                {
                                    trackingNode = (trackingNode as WordProblemLevelLeaf).getParent();
                                }
                                else if (trackingNode is WordProblemLevelPack)
                                {
                                    trackingNode = (trackingNode as WordProblemLevelPack).getParent();
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    
                    var nodesContainingCurrentLevel:Vector.<ICgsLevelNode> = getNodesContainingCurrentLevel(wordProblemLeaf.nodeName);
                    var numNodesContainingThisLevel:int = nodesContainingCurrentLevel.length;
                    
                    // Check if there is an objective class that this node, we stop at the lowest level
                    // containing objectives (means objectives are not inherited right now)
                    for (i = 0; i < numNodesContainingThisLevel; i++)
                    {
                        nodeContainingLevel = nodesContainingCurrentLevel[i];
                        
                        var objectiveClassName:String = (nodeContainingLevel as WordProblemLevelNode).getObjectiveClass();
                        if (objectiveClassName != null)
                        {
                            // Create cloned copy of the objectives
                            var objectivesForNode:Vector.<BaseObjective> = m_objectiveClassIdToObjectives[objectiveClassName];
                            if (objectivesForNode != null)
                            {
                                var copyOfObjectives:Vector.<BaseObjective> = new Vector.<BaseObjective>();
                                for each (var objective:BaseObjective in objectivesForNode)
                                {
                                    copyOfObjectives.push(objective.clone());
                                }
                                extraLevelProgressionData["objectives"] = copyOfObjectives;
                            }
                            
                            break;
                        }
                    }
                    
                    if (wordProblemLeaf.getSavePerformanceStateAcrossInstances())
                    {
                        extraLevelProgressionData["performanceState"] = wordProblemLeaf.serializedPerformanceState;
                    }
                    
                    m_startLevelCallback(wordProblemLeaf.nodeName, wordProblemLeaf.fileName, extraLevelProgressionData);
                    
                    // Temp key-value map to delete unused edges
                    var edgeIdToEdgeObject:Object = {};
                    
                    // Intialize conditions for edges at this node
                    // Iterate through the start of the edge list and check for ones where the starting
                    // node is in one we are currently in.
                    // If a node in the path contains outgoing edges, update all the condition objects
                    var i:int;
                    var numEdges:int = m_nodeEdges.length;
                    var closestAncestorWithASpecifiedEdge:ICgsLevelNode = null;
                    for (i = 0; i < numEdges; i++)
                    {
                        var edgeObject:Object = m_nodeEdges[i];
                        edgeIdToEdgeObject[edgeObject.id] = edgeObject;
                        var startNodeIdForEdge:String = edgeObject.startId;
                        
                        // Check if an edges matches one of the set the current level node is contained within
                        var j:int;
                        for (j = 0; j < numNodesContainingThisLevel; j++)
                        {
                            // If an edge is outgoing from a set, we test whether we should take this edge
                            var nodeContainingLevel:ICgsLevelNode = nodesContainingCurrentLevel[j];
                            if (nodeContainingLevel.nodeName == startNodeIdForEdge)
                            {
                                closestAncestorWithASpecifiedEdge = nodeContainingLevel;
                                
                                // Create new condition objects for an edge
                                if (!m_edgeIdToConditionsList.hasOwnProperty(edgeObject.id))
                                {
                                    var conditionsList:Vector.<ICondition> = new Vector.<ICondition>();
                                    if (edgeObject.hasOwnProperty("conditions"))
                                    {
                                        var conditionsData:Array = edgeObject.conditions;
                                        var k:int;
                                        for (k = 0; k < conditionsData.length; k++)
                                        {
                                            conditionsList.push(createCondition(conditionsData[k]));
                                        }
                                    }
                                    
                                    m_edgeIdToConditionsList[edgeObject.id] = conditionsList;
                                }      
                            }
                        }
                    }
                    
                    // Discard edges that are no longer valid on start
                    // Identify the start node id of the existing edges being tracked
                    // If the start node id is not part of the nodes currently in, it should be removed
                    var edgeIdsToDelete:Vector.<String> = new Vector.<String>();
                    for (var existingEdgeId:String in m_edgeIdToConditionsList)
                    {
                        var startingNodeIdForEdge:String = edgeIdToEdgeObject[existingEdgeId].startId;
                        var edgeIsContainedInCurrentNode:Boolean = false;
                        for each (nodeContainingLevel in nodesContainingCurrentLevel)
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
                    
                    for each (var edgeIdToDelete:String in edgeIdsToDelete)
                    {
                        delete m_edgeIdToConditionsList[edgeIdToDelete];
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
        public function goToNextLevel():void
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
        private function getNodesContainingCurrentLevel(id:String):Vector.<ICgsLevelNode>
        {
             var currentLevelLeaf:WordProblemLevelLeaf = this.currentLevelProgression.getNodeByName(id) as WordProblemLevelLeaf;
            var nodesContainingCurrentLevel:Vector.<ICgsLevelNode> = new Vector.<ICgsLevelNode>();
            nodesContainingCurrentLevel.push(currentLevelLeaf);
            var parentLevelSet:ICgsLevelPack = currentLevelLeaf.getParent();
            
            // Trace up from current leaf and keep track of all nodes on the path
            while (parentLevelSet != null && parentLevelSet is WordProblemLevelPack)
            {
                nodesContainingCurrentLevel.push(parentLevelSet);
                parentLevelSet = (parentLevelSet as WordProblemLevelPack).getParent();
            }
            return nodesContainingCurrentLevel
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
        public function endLevel(id:String, data:LevelStatistics):void
        {
            // At this point we may need to figure out what the next level to play should be
            // The next level may depend on the player's performance in the current level
            var currentLevelLeaf:WordProblemLevelLeaf = this.currentLevelProgression.getNodeByName(id) as WordProblemLevelLeaf;
            var currentLevelLeafSaveData:Object = {};
            var currentCompletionStatus:int = currentLevelLeaf.completionValue;
            var newCompletionStatus:int = LevelNodeCompletionValues.UNKNOWN;
            
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
                currentLevelLeafSaveData[LevelNodeSaveKeys.COMPLETION_VALUE] = newCompletionStatus;
            }
            
            // Objectives+Score progress should only be updated if the player completed the level
            if (newCompletionStatus == LevelNodeCompletionValues.PLAYED_SUCCESS)
            {
                currentLevelLeafSaveData[LevelNodeSaveKeys.HIGH_SCORE] = data.gradeFromSummaryObjectives;
            }
            
            if (currentLevelLeaf.getSavePerformanceStateAcrossInstances())
            {
                currentLevelLeafSaveData[LevelNodeSaveKeys.PERFORMANCE_STATE] = data.serialize();
            }
            
            // Update the save data progress of the current level
            // Only need to do this if the completion status has increased or a better high score was achieved.
            currentLevelLeaf.updateNode(currentLevelLeaf.nodeLabel, currentLevelLeafSaveData);
            
            // Determine what the next level to play should be.
            // Transitions are based on edge information between nodes that was encoded in the level seqeunce json data.
            // If no edge were explicitly defined for the current state, we fallback to the default behavior of going to 
            // the next level leaf in the order specified in the json.
            var edgeSelected:Object = null;
            
            // The level just played might be nested in several level sets and each of those sets might have edge transitions too.
            // The edges involving nodes at upper nested levels take priority, check if we use those transitions first
            // Trace up to the layer of nodes just below the chapters, the nodes below this level form the level graph we care about.
            // This is the set of 'states' that the just completed level leaf is contained within so they are all possible candiate
            // to take transitions from.
            var nodesContainingCurrentLevel:Vector.<ICgsLevelNode> = getNodesContainingCurrentLevel(id);
            
            var parentLevelSet:ICgsLevelPack = currentLevelLeaf.getParent();
                 
            // Iterate through the start of the edge list and check for ones where the starting
            // node is in one we are currently in.
            // If a node in the path contains outgoing edges, update all the condition objects
            var i:int;
            var numEdges:int = m_nodeEdges.length;
            var closestAncestorWithASpecifiedEdge:ICgsLevelNode = null;
            for (i = 0; i < numEdges; i++)
            {
                var edgeObject:Object = m_nodeEdges[i];
                var startNodeIdForEdge:String = edgeObject.startId;
                
                // Check if an edges matches one of the set the current level node is contained within
                var numNodesToCheckEdges:int = nodesContainingCurrentLevel.length;
                var j:int;
                var k:int;
                for (j = 0; j < numNodesToCheckEdges; j++)
                {
                    // If an edge is outgoing from a set, we test whether we should take this edge
                    var nodeContainingLevel:ICgsLevelNode = nodesContainingCurrentLevel[j];
                    if (nodeContainingLevel.nodeName == startNodeIdForEdge)
                    {
                        closestAncestorWithASpecifiedEdge = nodeContainingLevel;

                        // Update all the conditions at that edge
                        var conditionsList:Vector.<ICondition> = m_edgeIdToConditionsList[edgeObject.id];
                        if (conditionsList != null)
                        {
                            for (k = 0; k < conditionsList.length; k++)
                            {
                                updateCondition(conditionsList[k], data, currentLevelLeaf);
                            }
                            
                            // If the conditions for an edge passed then we immediately take that transition
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
                    data.levelGraphEdgeIdTaken = edgeSelected.id
                    break;
                }
            }
            
            var nextLevelNode:WordProblemLevelLeaf = null;
            
            // If an edge was specified and the conditions passed then go to the end node of that edge
            if (edgeSelected != null)
            {
                // It is possible the node goes to a 'null' end value which means don't go to any next
                // level, which can be interpreted as kick the player back out to the level select the next time
                // the 'next' level is requested.
                var noNextLevelExplicitlyRequested:Boolean = edgeSelected.endId == "";
                if (!noNextLevelExplicitlyRequested)
                {
                    var nodeAtEnd:ICgsLevelNode = this.currentLevelProgression.getNodeByName(edgeSelected.endId);
                    if (nodeAtEnd != null && nodeAtEnd is WordProblemLevelLeaf)
                    {
                        nextLevelNode = nodeAtEnd as WordProblemLevelLeaf;    
                    }
                }
                
                // Edges may have actions bound to them we perform them
                if (edgeSelected.hasOwnProperty("actions"))
                {
                    var actions:Array = edgeSelected.actions;
                    for (i = 0; i < actions.length; i++)
                    {
                        var action:Object = actions[i];
                        var actionType:String = action.type;
                        
                        // Pick a random node at the new node that isn't marked as complete
                        if (actionType == LevelNodeActions.PICK_RANDOM_UNCOMPLETED_LEVEL)
                        {
                            nextLevelNode = getNextLeafFromSelectionPolicy(nodeAtEnd, actionType);
                        }
                        else if (actionType == LevelNodeActions.PICK_FIRST_LEVEL)
                        {
                            nextLevelNode = this.getNextLevel(currentLevelLeaf) as WordProblemLevelLeaf;
                        }
                        else if (actionType == LevelNodeActions.PICK_NEXT_IN_SET)
                        {
                            var outNodesInSet:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
                            WordProblemCgsLevelManager.getLevelNodes(outNodesInSet, nodeAtEnd);
                            var indexOfCurrent:int = outNodesInSet.indexOf(currentLevelLeaf);
                            if (outNodesInSet.length > 0 && indexOfCurrent >= 0)
                            {
                                var nextIndex:int = indexOfCurrent + 1;
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
                            var nodeName:String = action.name;
                            updateNodeWithNewCompletionValue(this.getNodeByName(nodeName), LevelNodeCompletionValues.PLAYED_SUCCESS);
                        }
                        else if (actionType == LevelNodeActions.SET_NODE_AVAILABLE)
                        {
                            nodeName = action.name;
                            updateNodeWithNewCompletionValue(this.getNodeByName(nodeName), LevelNodeCompletionValues.UNPLAYED);
                        }
                        // Action saying the app should send a message that mastery was achieved
                        else if (actionType == LevelNodeActions.SET_MASTERY)
                        {
                            // Mastery is a single numerical id that maps to some 'topic'
                            // HACKY:
                            // (Copilot cares about this data so it needs to be stuffed in some intermediary part)
                            var masteryId:int = action.masteryId;
                            data.masteryIdAchieved = masteryId;
                        }
                        else if (actionType == LevelNodeActions.CLEAR_CONDITIONS_FOR_EDGE)
                        {
                            // Search for edges matching the target id and clear all condition state
                            var edgeIdToClear:String = action.edgeId.toString();
                            if (m_edgeIdToConditionsList.hasOwnProperty(edgeIdToClear))
                            {
                                var conditionsToClear:Vector.<ICondition> = m_edgeIdToConditionsList[edgeIdToClear];
                                for each (var conditionToClear:ICondition in conditionsToClear)
                                {
                                    conditionToClear.clearState();
                                }
                            }
                        }
                        else if (actionType == LevelNodeActions.CLEAR_PERFORMANCE_STATE_FOR_NODE)
                        {
                            // For a particular leaf node or the children leaves, reset all saved performance data
                            // back to default starting values
                            nodeName = action.name;
                            var outLevelLeafNodes:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
                            WordProblemCgsLevelManager.getLevelNodes(outLevelLeafNodes, this.getNodeByName(nodeName));
                            for each (var outLevelLeaf:WordProblemLevelLeaf in outLevelLeafNodes)
                            {
                                var resetData:Object = {};
                                resetData[LevelNodeSaveKeys.PERFORMANCE_STATE] = null;
                                outLevelLeaf.updateNode(outLevelLeaf.nodeLabel, resetData);
                            }
                        }
                    }
                }
                
                // If an action did not end up picking the next level and the end node is a level set
                // we need to decide which node in the set to start, use the selection policy on that set
                // DO NOT do this if an edge explicitly marked an empty or null node as the end
                if (!noNextLevelExplicitlyRequested && nextLevelNode == null && nodeAtEnd is WordProblemLevelPack)
                {
                    nextLevelNode = this.getNextLeafFromSelectionPolicy(nodeAtEnd, (nodeAtEnd as WordProblemLevelPack).getSelectionPolicy());
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
                nextLevelNode = this.getNextLevel(currentLevelLeaf) as WordProblemLevelLeaf;
                
                // If the closest ancestor is the node itself then cannot auto progress since that would override the edge data
                if (closestAncestorWithASpecifiedEdge != null && currentLevelLeaf != closestAncestorWithASpecifiedEdge)
                {
                    // Make sure the next node is contained
                    var nextNodeContainedInAncestorWithEdge:Boolean = false;
                    var parentPack:ICgsLevelPack = nextLevelNode.getParent();
                    while (parentPack is WordProblemLevelPack)
                    {
                        if (parentPack == closestAncestorWithASpecifiedEdge)
                        {
                            nextNodeContainedInAncestorWithEdge = true;
                            break;
                        }
                        else
                        {
                            parentPack = (parentPack as WordProblemLevelPack).getParent();
                        }
                    }
                    
                    // Next node not allowed to go to a different part of the graph that is not contained
                    // in the ancestor. We are stuck at the node
                    if (!nextNodeContainedInAncestorWithEdge)
                    {
                        nextLevelNode = currentLevelLeaf;
                    }
                }
                // Important! We do not treat each genre as a linear sequence.
                // Once a player finished the last level in a genre, we jump them back to the
                // main level select screen
                // We check if the current finished level is the last in the genre
                else if (closestAncestorWithASpecifiedEdge == null)
                {
                    if (currentLevelLeaf.parentGenreLevelPack != null)
                    {
                        m_outLevelBuffer.length = 0;
                        WordProblemCgsLevelManager.getLevelNodes(m_outLevelBuffer, currentLevelLeaf.parentGenreLevelPack);
                        if (m_outLevelBuffer[m_outLevelBuffer.length - 1] == currentLevelLeaf)
                        {
                            nextLevelNode = null;
                        }
                    }
                }
                
                // If the exit condition is a quit and there is no edge selected, the next node should exactly be the
                // level that was just quit. If they disconnect at this point, the next level they go to should
                // be the one exited.
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
                var saveDataForAllEdges:Object = {}; // Blob for all conditions
                var numEdgesToSave:int = 0;
                var edgeIdsInTheNexLevel:Vector.<String> = new Vector.<String>();
                if (nextLevelNode != null)
                {
                    nodesContainingCurrentLevel.length = 0;
                    nodesContainingCurrentLevel.push(nextLevelNode);
                    parentLevelSet = nextLevelNode.getParent();
                    
                    // Trace up from current leaf and keep track of all nodes on the path
                    while (parentLevelSet != null && parentLevelSet is WordProblemLevelPack)
                    {
                        nodesContainingCurrentLevel.push(parentLevelSet);
                        parentLevelSet = (parentLevelSet as WordProblemLevelPack).getParent();
                    }
                    
                    // Want to identify all outgoing edges from the next level node,
                    // again need to iterate through all edges to find a match
                    for (i = 0; i < m_nodeEdges.length; i++)
                    {
                        edgeObject = m_nodeEdges[i];
                        startNodeIdForEdge = edgeObject.startId;
                        for (j = 0; j < nodesContainingCurrentLevel.length; j++)
                        {
                            if (startNodeIdForEdge == nodesContainingCurrentLevel[j].nodeName)
                            {
                                var edgeId:String = edgeObject.id;
                                edgeIdsInTheNexLevel.push(edgeId);
                                
                                // Only care about previously created conditions
                                // This is because the new nodes without conditions have starting
                                // values that are empty anyways
                                if (m_edgeIdToConditionsList.hasOwnProperty(edgeId))
                                {
                                    var saveForEdge:Object = null;
                                    var conditionsForEdge:Vector.<ICondition> = m_edgeIdToConditionsList[edgeId];
                                    for (k = 0; k < conditionsForEdge.length; k++)
                                    {
                                        var saveForCondition:Object = conditionsForEdge[k].serialize();
                                        if (saveForCondition != null)
                                        {
                                            if (saveForEdge == null)
                                            {
                                                saveForEdge = {};
                                            }
                                            
                                            // Index for condition maps to serialized version of that condition
                                            saveForEdge[k.toString()] = saveForCondition;
                                        }
                                    }
                                    
                                    if (saveForEdge != null)
                                    {
                                        numEdgesToSave++;
                                        
                                        // Edge id maps to collection of condition indices to serialized condition objects
                                        saveDataForAllEdges[edgeId] = saveForEdge;
                                    }
                                }
                                
                                // Assume nodes have unique names
                                break;
                            }
                        }
                    }
                }
                
                var newCurrentLevelStateSaveData:Object = {};
                if (nextLevelNode != null)
                {
                    newCurrentLevelStateSaveData[CURRENT_LEVEL_NAME_SAVE_KEY] = nextLevelNode.nodeName;
                }
                
                if (numEdgesToSave > 0)
                {
                    newCurrentLevelStateSaveData[CURRENT_LEVEL_CONDITIONS_SAVE_KEY] = saveDataForAllEdges;
                }
                m_cache.setSave(CURRENT_LEVEL_STATE_SAVE_KEY, newCurrentLevelStateSaveData, false);
                
                m_cache.flush();
            }
            
            // The edge id to condition map no longer needs conditions bound to nodes we are no longer in.
            // We need to identify which of these edges we no longer need and dispose of them
            if (edgeIdsInTheNexLevel != null)
            {
                for (edgeId in m_edgeIdToConditionsList)
                {
                    if (edgeIdsInTheNexLevel.indexOf(edgeId) < 0)
                    {
                        delete m_edgeIdToConditionsList[edgeId];
                    }
                }
            }
            
            // The next level should be saved until an explicit call to go to the next level is made
            // from outside this interface.
            // A null next level means there is no logical next level that could be determined
            m_savedNextLevelLeaf = nextLevelNode;
        }
        
        private function updateNodeWithNewCompletionValue(node:ICgsLevelNode, newCompletionValue:int):void
        {
            var newNextLevelStatus:Object = {};
            newNextLevelStatus[LevelNodeSaveKeys.COMPLETION_VALUE] = newCompletionValue;
            node.updateNode(node.nodeLabel, newNextLevelStatus);
        }
        
        private function getNextLeafFromSelectionPolicy(node:ICgsLevelNode, selectionPolicy:String):WordProblemLevelLeaf
        {
            var nextLeaf:WordProblemLevelLeaf = null;
            if (node is WordProblemLevelLeaf)
            {
                nextLeaf = node as WordProblemLevelLeaf;
            }
            else if (node is WordProblemLevelPack)
            {
                var levelPack:WordProblemLevelPack = node as WordProblemLevelPack;
                var childNodes:Vector.<ICgsLevelNode> = levelPack.nodes;
                var selectedChild:ICgsLevelNode = null;
                if (selectionPolicy == LevelNodeActions.PICK_RANDOM_UNCOMPLETED_LEVEL)
                {
                    var candidateNodes:Vector.<ICgsLevelNode> = new Vector.<ICgsLevelNode>();
                    var i:int;
                    var childNode:ICgsLevelNode;
                    for (i = 0; i < childNodes.length; i++)
                    {
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
                    for (i = 0; i < childNodes.length; i++)
                    {
                        childNode = childNodes[i];
                        if (!childNode.isComplete && !childNode.isLocked)
                        {
                            selectedChild = childNode;
                            break;
                        }
                    }
                    
                    // if none still fit then just pick the first one
                    if (selectedChild == null && childNodes.length > 0)
                    {
                        selectedChild = childNodes[0];
                    }
                }
                
                if (selectedChild != null)
                {
                    // Perform recursive selection until we get a level leaf representing a single level
                    var childSelectionPolicy:String = (selectedChild is WordProblemLevelPack) ?
                        (selectedChild as WordProblemLevelPack).getSelectionPolicy() : null;
                    nextLeaf = getNextLeafFromSelectionPolicy(selectedChild, childSelectionPolicy);
                }
            }
            
            return nextLeaf;
        }
        
        public function getGenreNodes(outGenreNodes:Vector.<GenreLevelPack>):void
        {
            _getGenreNodes(this.currentLevelProgression, outGenreNodes);
        }
        
        private function _getGenreNodes(root:ICgsLevelPack, outGenreNodes:Vector.<GenreLevelPack>):void
        {
            // Once we find a genre node, we can kill the search at this node.
            // This assumes a genre CANNOT be nested within another genre.
            if (root is GenreLevelPack)
            {
                outGenreNodes.push(root as GenreLevelPack);
            }
            else
            {
                var children:Vector.<ICgsLevelNode> = root.nodes;
                var i:int;
                var child:ICgsLevelNode;
                for (i = 0; i < children.length; i++)
                {
                    child = children[i];
                    
                    if (child is ICgsLevelPack)
                    {
                        _getGenreNodes(child as ICgsLevelPack, outGenreNodes);
                    }
                }
            }
        }
        
        /**
         * From json formatted string create a condition object that stores state and has logic to
         * determine if the condition for an edge has been satisfied.
         */
        private function createCondition(data:Object):ICondition
        {
            var type:String = data.type;
            var condition:ICondition = null;
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
        private function updateCondition(condition:ICondition, 
                                         data:LevelStatistics, 
                                         currentLevelLeaf:WordProblemLevelLeaf):void
        {
            var type:String = condition.getType();
            if (type == KOutOfNProficientCondition.TYPE)
            {
                var kOfNCondition:KOutOfNProficientCondition = condition as KOutOfNProficientCondition;
                var objectives:Vector.<BaseObjective> = m_objectiveClassIdToObjectives[kOfNCondition.getObjectiveClass()];
                kOfNCondition.update(currentLevelLeaf, data, objectives);
            }
            else if (type == NLevelsCompletedCondition.TYPE)
            {
                (condition as NLevelsCompletedCondition).update(data);
            }
            else if (type == NodeStatusCondition.TYPE)
            {
                (condition as NodeStatusCondition).update(this);
            }
        }
        
        /**
         * When determining the next level to play, the current node that was just played may have an outgoing
         * edge to a next level. Each edge has some condition that needs to be checked.
         * 
         * @return
         *      True if all conditions were satisfied or no conditions were specified in the list
         */
        private function edgeConditionsPassed(conditions:Vector.<ICondition>):Boolean
        {
            var allConditionsPassed:Boolean = true;
            var i:int;
            var numConditions:int = conditions.length;
            for (i = 0; i < numConditions; i++)
            {
                var condition:ICondition = conditions[i];
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
        public function init(levelData:Object = null):void 
        {
            // Level Progression
            m_rootLevelProgression = m_levelFactory.getNodeInstance(m_levelFactory.defaultLevelPackType) as ICgsLevelPack;
            m_rootLevelProgression.init(null, null, levelData);
        }
        
        /**
         * @inheritDoc
         */
        public function reset():void
        {
            m_levelFactory.recycleNodeInstance(m_rootLevelProgression);
            m_rootLevelProgression = null;
        }
        
        /**
         * @inheritDoc
         */
        public function get currentLevel():ICgsLevelLeaf
        {
            return m_savedNextLevelLeaf;
        }
        
        /**
         * @inheritDoc
         */
        public function get currentLevelProgression():ICgsLevelPack
        {
            return m_rootLevelProgression;
        }
        
        /**
         * @inheritDoc
         */
        public function get resourceManager():ICgsLevelResourceManager
        {
            return m_resourceManager;
        }
        
        /**
         * @inheritDoc
         */
        public function get achievementManager():ICgsAchievementManager
        {
            return m_userManager.userList[0];
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsCompleted():int
        {
            return m_rootLevelProgression.numLevelLeafsCompleted;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsUncompleted():int
        {
            return m_rootLevelProgression.numLevelLeafsUncompleted;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsPlayed():int
        {
            return m_rootLevelProgression.numLevelLeafsPlayed;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsUnplayed():int
        {
            return m_rootLevelProgression.numLevelLeafsUnplayed
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsLocked():int
        {
            return m_rootLevelProgression.numLevelLeafsLocked
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelLeafsUnlocked():int
        {
            return m_rootLevelProgression.numLevelLeafsUnlocked
        }
        
        /**
         * @inheritDoc
         */
        public function get numTotalLevelLeafs():int
        {
            return m_rootLevelProgression.numTotalLevelLeafs;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksCompleted():int
        {
            return m_rootLevelProgression.numLevelPacksCompleted;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksUncompleted():int
        {
            return m_rootLevelProgression.numLevelPacksUncompleted;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksFullyPlayed():int
        {
            return m_rootLevelProgression.numLevelPacksFullyPlayed;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksPlayed():int
        {
            return m_rootLevelProgression.numLevelPacksPlayed;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksUnplayed():int
        {
            return m_rootLevelProgression.numLevelPacksUnplayed;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksLocked():int
        {
            return m_rootLevelProgression.numLevelPacksLocked;
        }
        
        /**
         * @inheritDoc
         */
        public function get numLevelPacksUnlocked():int
        {
            return m_rootLevelProgression.numLevelPacksUnlocked;
        }
        
        /**
         * @inheritDoc
         */
        public function get numTotalLevelPacks():int
        {
            return m_rootLevelProgression.numTotalLevelPacks;
        }
        
        /**
         * @inheritDoc
         */
        public function getCompletionValueOfNode(nodeLabel:int):Number 
        {
            return m_rootLevelProgression.getNode(nodeLabel).completionValue;
        }
        
        /**
         * @inheritDoc
         */
        public function get isCompleteCompletionValue():Number
        {
            return m_isCompleteCompletionValue;
        }
        
        /**
         * @inheritDoc
         */
        public function set isCompleteCompletionValue(value:Number):void
        {
            m_isCompleteCompletionValue = value;
        }
        
        /**
         * @inheritDoc
         */
        public function get doCheckLocks():Boolean
        {
            return m_doCheckLocks;
        }
        
        /**
         * @inheritDoc
         */
        public function set doCheckLocks(value:Boolean):void
        {
            m_doCheckLocks = value;
        }
        
        /**
         * @inheritDoc
         */
        public function endCurrentLevel():void
        {
        }
        
        /**
         * @inheritDoc
         */
        public function playLevel(levelData:ICgsLevelLeaf, data:Object = null):void
        {
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsComplete():void
        {
            m_rootLevelProgression.markAllLevelLeafsAsComplete();
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsPlayed():void
        {
            m_rootLevelProgression.markAllLevelLeafsAsPlayed();
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsUnplayed():void
        {
            m_rootLevelProgression.markAllLevelLeafsAsUnplayed();
        }
        
        /**
         * @inheritDoc
         */
        public function markAllLevelLeafsAsCompletionValue(value:Number):void
        {
            m_rootLevelProgression.markAllLevelLeafsAsCompletionValue(value);
        }
        
        /**
         * @inheritDoc
         */
        public function markCurrentLevelLeafAsCompletionValue(value:Number):void
        {
        }
        
        /**
         * @inheritDoc
         */
        public function markCurrentLevelLeafAsComplete():void
        {
            markCurrentLevelLeafAsCompletionValue(isCompleteCompletionValue);
        }
        
        /**
         * @inheritDoc
         */
        public function markCurrentLevelLeafAsPlayed():void
        {
            markCurrentLevelLeafAsCompletionValue(0);
        }
        
        /**
         * @inheritDoc
         */
        public function markCurrentLevelLeafAsUnplayed():void
        {
            markCurrentLevelLeafAsCompletionValue(-1);
        }
        
        /**
         * @inheritDoc
         */
        public function markLevelLeafAsCompletionValue(nodeLabel:int, value:Number):void
        {
            var data:Object = new Object();
            data[LevelNodeSaveKeys.COMPLETION_VALUE] = value;
            m_rootLevelProgression.updateNode(nodeLabel, data);
        }
        
        /**
         * @inheritDoc
         */
        public function markLevelLeafAsComplete(nodeLabel:int):void
        {
            markLevelLeafAsCompletionValue(nodeLabel, isCompleteCompletionValue);
        }
        
        /**
         * @inheritDoc
         */
        public function markLevelLeafAsPlayed(nodeLabel:int):void
        {
            markLevelLeafAsCompletionValue(nodeLabel, 0);
        }
        
        /**
         * @inheritDoc
         */
        public function markLevelLeafAsUnplayed(nodeLabel:int):void
        {
            markLevelLeafAsCompletionValue(nodeLabel, -1);
        }
        
        /**
         * @inheritDoc
         */
        public function addNodeToProgression(nodeData:Object, parentPackName:String = null, index:int = -1):void
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
        public function editNodeInProgression(nameOfNode:String, newNodeData:Object):void
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
        public function removeNodeFromProgression(nodeName:String):void
        {
            m_rootLevelProgression.removeNodeFromProgression(nodeName);
        }
        
        /**
         * @inheritDoc
         */
        public function getNode(nodeLabel:int):ICgsLevelNode 
        {
            return m_rootLevelProgression.getNode(nodeLabel);
        }
        
        /**
         * @inheritDoc
         */
        public function getNodeByName(nodeName:String):ICgsLevelNode 
        {
            return m_rootLevelProgression.getNodeByName(nodeName);
        }
        
        /**
         * @inheritDoc
         */
        public function getNextLevel(presentLevel:ICgsLevelLeaf = null):ICgsLevelLeaf
        {
            var result:ICgsLevelLeaf;
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
        public function getNextLevelById(aNodeLabel:int = -1):ICgsLevelLeaf
        {
            return m_rootLevelProgression.getNextLevel(aNodeLabel);
        }
        
        /**
         * @inheritDoc
         */
        public function getPrevLevel(presentLevel:ICgsLevelLeaf = null):ICgsLevelLeaf
        {
            var result:ICgsLevelLeaf;
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
        public function getPrevLevelById(aNodeLabel:int = -1):ICgsLevelLeaf
        {
            return m_rootLevelProgression.getPrevLevel(aNodeLabel);
        }
    }
}