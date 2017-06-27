package wordproblem.engine.level
{
    import wordproblem.engine.component.WidgetAttributesComponent;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.objectives.BaseObjective;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.text.model.DocumentNode;

    /**
     * This class represents a single level for the word problem game.
     * 
     * Stores all data and configuration setting specific to just that level
     */
    public class WordProblemLevelData
    {
        /**
         * During the playthrough of a level there are potentially several different actions that
         * we want to remember happened. For example the number of times the player pressed
         * the hint button or made a mistake modelling. The detection of these actions is done through
         * scripts.
         * 
         * This provides a centralized point to get all important statistics information.
         */
        public var statistics:LevelStatistics;
        
        /**
         * Each level might have a set of goals/objectives that can be achieved by the player.
         * It is intended that the level script will write these objective into this buffer.
         * Objective to be saved cannot be determined just by looking at the completion status of a level.
         */
        public var objectives:Vector.<BaseObjective>;
        
        /**
         * For bar model levels we might have situations where an unknown variable maps to a numeric value.
         * Use if want an unknown to take an exact value when a segment is created from it.
         */
        public var termValueToBarModelValue:Object;
        
        /**
         * For bar model level we have situation where the player needs to create a several segments of
         * identical size already stacked together. We call this a unit bar.
         * 
         * For some levels, we need the size of these segments to take on a specific value.
         * If -1, then a level has not set the default unit.
         */
        public var defaultUnitValue:int;
        
        /**
         * Flag to indicate whether player should be allowed to skip this problem at
         * any point. A skipped problem will not be marked as complete.
         * 
         * Some levels, like tutorials, should not be skippable.
         * 
         * Default: true
         */
        public var skippable:Boolean;
        
        /**
         * Extra data to indicate that this problem needs to partially fill in the equation.
         * 
         * Properties:
         * side: left, right, random
         * 
         * For now, depending on the problem type we have a single way in mind to fill this in
         */
        public var prepopulateEquationData:Object;
        
        /**
         * This is the 'qid'
         */
        private var m_qid:int;
        
        /**
         * Index in the parent chapter or genre the level is in, used just for labeling the level correctly
         */
        private var m_levelIndex:int;
        
        /**
         * This information is required for something like determining how the summary screen should
         * be styled when this level is finished.
         */
        private var m_genreId:String;
        
        /**
         * Chapter index can be negative if none, used just for labeling the level correctly
         */
        private var m_chapterIndex:int;
        
        /**
         * Need some way to link the level data to an identifier in the level graph.
         */
        private var m_name:String;
        
        /**
         * The tree structure defining the textual representation of the problem.
         */
        public var m_rootDocumentNode:Vector.<DocumentNode>;
        
        /**
         * CSS-like formatted object defining how elements of the document node tree should
         * be styled and positioned. This is required if we want to change the style attributes
         * after the initial document parsing has completed.
         * 
         * For example, we want to color the spans in a level or make them larger after the
         * player requests a hint.
         */
        private var m_cssStyleObject:Object;
        
        /**
         * Custom card values to be used in the level.
         */
        private var m_symbolData:Vector.<SymbolData>;
        
        /**
         * The tree structure for custom logic to be executed for the level.
         */
        private var m_scriptRoot:ScriptNode;
        private var m_imagesToLoad:Vector.<String>;
        private var m_audioData:Vector.<Object>;
        private var m_textureAtlasesToLoad:Vector.<Vector.<String>>;
        
        /**
         * Definition of how various ui components in the level should be laid out
         */
        private var m_layoutRoot:WidgetAttributesComponent;
        
        /**
         * Information about how to render various cards
         */
        private var m_cardAttributes:CardAttributes;
        
        /**
         * Restrictions to place on the level
         */
        private var m_levelRules:LevelRules;
        
        /**
         * For the levels involving the bar model we need to get what category of model
         * is being used for data logging purposes as well as determining the proper
         * hints to show.
         * 
         * Null if unknown type or no bar model is used
         */
        private var m_barModelType:String;
        
        /**
         * Value in LevelNodeCompletionValues of the completion status of the level before the next
         * play through. Useful if a script has actions specific to whever the player replays a level
         * or finishes it for the first time.
         */
        public var previousCompletionStatus:int;
        
        /**
         * List of categorical properties belonging to this problem.
         * 
         * Can be null
         */
        private var m_tags:Vector.<String>;
        
        /**
         * An arbitrary number denoting how difficult the following level is to solve.
         * 
         * Exposed in case some of the script want to configure some of their settings to adjust for
         * how difficult a problem is determined to be.
         */
        private var m_difficulty:Number;
        
        /**
         * 
         * @param levelId
         *      The id used for data recording purposes, this id should be enough across
         *      all levels so we should be able to find the correct data file with just this value
         * @param name
         *      The identifier that maps to a node in the level progression
         */ 
        public function WordProblemLevelData(levelId:int,
                                             levelIndex:int,
                                             chapterIndex:int,
                                             genreId:String,
                                             name:String,
                                             rootDocumentNode:Vector.<DocumentNode>, 
                                             cssStyleObject:Object,
                                             symbolData:Vector.<SymbolData>, 
                                             scriptNode:ScriptNode, 
                                             imagesToLoad:Vector.<String>,
                                             audioData:Vector.<Object>,
                                             textureAtlasesToLoad:Vector.<Vector.<String>>,
                                             layoutRoot:WidgetAttributesComponent,
                                             cardAttributes:CardAttributes,
                                             levelRules:LevelRules,
                                             barModelType:String)
        {
            m_qid = levelId;
            m_levelIndex = levelIndex;
            m_chapterIndex = chapterIndex;
            m_genreId = genreId;
            m_name = name;
            m_rootDocumentNode = rootDocumentNode;
            m_cssStyleObject = cssStyleObject;
            m_symbolData = symbolData;
            m_scriptRoot = scriptNode;
            m_imagesToLoad = imagesToLoad;
            m_audioData = audioData;
            m_textureAtlasesToLoad = textureAtlasesToLoad;
            m_layoutRoot = layoutRoot;
            m_cardAttributes = cardAttributes;
            m_levelRules = levelRules;
            m_barModelType = barModelType;
            m_tags = null;
            m_difficulty = -1;
            
            this.statistics = new LevelStatistics();
            this.objectives = new Vector.<BaseObjective>();
            this.defaultUnitValue = -1;
            this.skippable = true;
            this.termValueToBarModelValue = {};
        }

        /**
         * Get back an unique integer id for a level configuration. This value is exactly the number that
         * should be used for a quest id.
         * 
         * (NOTE: this value (maybe confusingly so) is different from the level name and from the nodeLabel number that is used
         * in the cgs level progression library. This is because the level name is a string and the nodeLabel is
         * autogenerated.
         * 
         * @return
         *      The quest id for the level
         */
        public function getId():int 
        {
            return m_qid;
        }
        
        public function getLevelIndex():int
        {
            return m_levelIndex;
        }
        
        /**
         * Get back the id of the genre that contains this level
         * 
         * @return
         *      String id of the genre (the asset manager has a data object containing detailed info about the genre)
         */
        public function getGenreId():String
        {
            return m_genreId;
        }
        
        /**
         * Get back the id of the chapter that contains this chapter
         * 
         * @return
         *      String id of the chapter, can be null if the level is not part of a chapter
         *      (the asset manager has a data object containing detailed info about the chapter)
         */
        public function getChapterIndex():int
        {
            return m_chapterIndex;
        }
        
        /**
         * Get back the root nodes for the tree representation of the document structure.
         */
        public function getRootDocumentNodes():Vector.<DocumentNode>
        {
            return m_rootDocumentNode;
        }
        
        /**
         * Get back the attributes used to style the document node. The intention is
         * the game can modify this during play to change the appearance of the text.
         */
        public function getCssStyleObject():Object
        {
            return m_cssStyleObject;
        }
        
        /**
         * Get a list of terms that have custom rendering attributes.
         */
        public function getSymbolsData():Vector.<SymbolData>
        {
            return m_symbolData;
        }
        
        /**
         * Get the custom logic that should be executed for this level.
         */
        public function getScriptRoot():ScriptNode
        {
            return m_scriptRoot;
        }
        
        /**
         * Get list of all images to load for this level.
         * Right now these are just raw strings pointing out the url of the asset
         */
        public function getImagesToLoad():Vector.<String>
        {
            return m_imagesToLoad;
        }
        
        /**
         * Get list of audio data files to load
         * Note this should include any special background music that should be played
         * 
         * @return
         *      Each object element has
         *      {
         *          type: Describes how it should be loaded, 'url' means load at start of level.
         *          'streaming' means dynamically load while level playing
         *          src: Either the path to load for 'url' or name in the audio.xml
         *      }
         */
        public function getAudioData():Vector.<Object>
        {
            return m_audioData;
        }
        
        /**
         * Get list of texture atlas urls to load for this level.
         * 
         * The first element is the url to the spritesheet
         * The second element is the url to the xml file
         */
        public function getTextureAtlasesToLoad():Vector.<Vector.<String>>
        {
            return m_textureAtlasesToLoad;
        }
        
        public function getLayoutData():WidgetAttributesComponent
        {
            return m_layoutRoot;
        }
        
        /**
         * Get back custom style information for cards/tiles representing terms
         */
        public function getCardAttributes():CardAttributes
        {
            return m_cardAttributes;
        }
        
        public function getLevelRules():LevelRules
        {
            return m_levelRules;
        }
        
        /**
         *
         * @return
         *      null if level uses no bar model or unknown type. Otherwise return a string that
         *      should match a type found in BarModelTypes.as
         */
        public function getBarModelType():String
        {
            return m_barModelType;
        }
        
        /**
         * Get back a string identifier for this level that directly maps it to a node
         * in the level progression graph.
         * 
         * Some caveats, a single node might end up spawing several different level configurations, in
         * which case all the level data would have the same name. This might happen for an infinite level
         * node for example.
         * 
         * Note that this id is also different from the levelId number which should ideally be unique across every
         * different configuration of a level.
         * 
         * @return
         *      String name of the level as it is found in the level progression system.
         */
        public function getName():String
        {
            return m_name;
        }
        
        /**
         * Get back the difficulty level of this problem
         * 
         * @return
         *      Value between 0-10, where 0 is easiest and 10 is hardest, a negative value
         *      means difficulty is unknown.
         */
        public function get difficulty():Number
        {
            return m_difficulty;
        }
        
        public function set difficulty(value:Number):void
        {
            // Clamp so that 10 is the largest value possible
            if (value > 10)
            {
                value = 10;
            }
            m_difficulty = value;
        }
        
        /**
         * Get back categorical attributes about this level.
         * For example, the 'tutorial' tag indicates that this problem introduces some
         * important idea, other scripts may need to change settings to accomadate.
         */
        public function get tags():Vector.<String>
        {
            return m_tags;
        }
        
        public function set tags(value:Vector.<String>):void
        {
            m_tags = value;
        }
    }
}