package wordproblem.level.nodes;

// TODO: uncomment once cgs library is ported
//import cgs.cache.ICgsUserCache;
//import cgs.levelprogression.ICgsLevelManager;
//import cgs.levelprogression.util.ICgsLockFactory;

import dragonbox.common.util.XString;

/**
 * Base class with all common data shared across every node used in the level progression system for
 * the application
 */
class WordProblemLevelNode
{
    //public var completionValue(get, never) : Float;
    //public var nodeName(get, never) : String;
    //public var nodeLabel(get, never) : Int;
    //public var isPlayed(get, never) : Bool;
    //public var isComplete(get, never) : Bool;
//
    ///**
     //* Need to reference another to read/write save data
     //*/
    //private var m_cache : ICgsUserCache;
    //
    //private var m_levelManager : ICgsLevelManager;
    //
    ///**
     //* Unique id for the game
     //*/
    //private var m_nodeLabel : Int;
    //private var m_lockFactory : ICgsLockFactory;
    //
    ///**
     //* Like regular level leaves, packs can also be marked with indicator of whether
     //* it is 'complete' or locked. Extra state is useful for the level select and also
     //* in the calculation of some edge conditions. (i.e. don't allow play in a chapter
     //* until this other set is marked as complete)
     //*/
    //private var m_completionValue : Float;
    //
    ///**
     //* For the purposes of this application, the name should be equivalent to the level id found
     //* within the level itself.
     //* 
     //* (This is set when levels data is parsed from external source)
     //*/
    //private var m_name : String;
    //
    /**
     * List of key properties regarding this node. For example, for levels it might contain
     * name of operators used in a level, whether or not this level is a tutorial, whether or
     * not this pack should be marked as practice so the application can handle it differently.
     * 
     * (For example, if you look at a question on Stackoverflow, you notice a collection of words
     * that tag categories the content relates to. Similarly the tags in the progression express
     * special binary properties about the level)
     * 
     * Null if no tags are associated
     */
    private var m_tags : Array<String>;
    //
    ///**
     //* If a node has an objective class, then it has a set of goal objectives that it should
     //* display to the user.
     //* (Note this is not related to the objectives used in edges)
     //*/
    //private var m_objectiveClass : String;
    //
    ///**
     //* Determine whether this node in the progression should be visible within the level selection screen,
     //* i.e. should there be a ui element for a player to go to the level or levels belonging to this node.
     //* Default behavior is that all are selectable, only indicate false if we want to hide
     //*/
    //private var m_canShowInLevelSelect : Bool;
    //
    ///**
     //* Mapping from rule name to a value. Used to mark an instance of a level or pack in the progression
     //* should have rules that override those defined in the level xml
     //*/
    //private var m_overrideRules : Dynamic;
    //
    ///**
     //* If true, then performance stats like hints requested or mistakes made are remembered across
     //* all instances of the level.
     //*/
    //private var m_savePerformanceStateAcrossInstances : Bool;
    //
    ///**
     //* If not null, this level or pack should have a portion of it's equation part already filled in.
     //*/
    //private var m_prepopulateEquationData : Dynamic;
    //
    ///**
     //* An somewhat arbitrary metric to indicate how difficult an individual level or even a level set
     //* is to solve. Higher numbers mean higher difficulty.
     //*/
    //private var m_difficulty : Float;
    //private var m_difficultySet : Bool;
    //
    //public function new(levelManager : ICgsLevelManager,
            //cache : ICgsUserCache,
            //lockFactory : ICgsLockFactory,
            //nodeLabel : Int)
    //{
        //m_levelManager = levelManager;
        //m_cache = cache;
        //m_lockFactory = lockFactory;
        //m_nodeLabel = nodeLabel;
        //m_completionValue = -1;
        //m_name = null;
        //m_tags = null;
        //m_objectiveClass = null;
        //m_canShowInLevelSelect = true;
        //m_overrideRules = null;
        //m_savePerformanceStateAcrossInstances = false;
        //m_difficulty = 0.0;
        //m_difficultySet = false;
    //}
    //
    ///**
     //* The level progression system in cgs common has an init call to parse the data from a file.
     //* Different types of nodes might share some common data properties that can be parsed without
     //* copying code, we do that here
     //* 
     //* @param data
     //*      json blob that should be parsed into a node
     //*/
    //public function parseCommonData(data : Dynamic) : Void
    //{
        //if (data != null) 
        //{
            //m_name = ((data.exists("name"))) ? data.name : null;
            //
            //if (data.exists("tags")) 
            //{
                //m_tags = new Array<String>();
                //for (tag/* AS3HX WARNING could not determine type for var: tag exp: EField(EIdent(data),tags) type: null */ in data.tags)
                //{
                    //if (tag != "") 
                    //{
                        //m_tags.push(tag);
                    //}
                //}
            //}
            //
            //if (data.exists("objectiveClass")) 
            //{
                //m_objectiveClass = data.objectiveClass;
            //}
            //
            //if (data.exists("levelselect")) 
            //{
                //m_canShowInLevelSelect = data.levelselect;
            //}  // override the rules defined in the level xml    // In the progression json, we may want custom rules that will  
            //
            //
            //
            //
            //
            //if (data.exists("rules")) 
            //{
                //m_overrideRules = { };
                //var overrideRules : Dynamic = data.rules;
                //for (ruleName in Reflect.fields(overrideRules))
                //{
                    //var ruleValue : String = Reflect.field(overrideRules, ruleName);
                    //if (ruleValue == "true" || ruleValue == "false") 
                    //{
                        //Reflect.setField(m_overrideRules, ruleName, XString.stringToBool(ruleValue));
                    //}
                    //else if (new EReg('^[0-9]+$', "").test(ruleValue)) 
                    //{
                        //Reflect.setField(m_overrideRules, ruleName, parseInt(ruleValue));
                    //}
                    //else 
                    //{
                        //Reflect.setField(m_overrideRules, ruleName, ruleValue);
                    //}
                //}
            //}
            //
            //if (data.exists("savePerformanceStateAcrossInstances")) 
            //{
                //m_savePerformanceStateAcrossInstances = data.savePerformanceStateAcrossInstances;
            //}  // Mark this level to prepopulate the equation  
            //
            //
            //
            //if (data.exists("prepopulateEquation")) 
            //{
                //// Create clone of the data
                //var prepopulateEquationTempData : Dynamic = Reflect.field(data, "prepopulateEquation");
                //m_prepopulateEquationData = { };
                //for (prepopulateKey in Reflect.fields(prepopulateEquationTempData))
                //{
                    //Reflect.setField(m_prepopulateEquationData, prepopulateKey, Reflect.field(prepopulateEquationTempData, prepopulateKey));
                //}
            //}
            //
            //if (data.exists("difficulty")) 
            //{
                //m_difficultySet = true;
                //m_difficulty = parseFloat(Reflect.field(data, "difficulty"));
            //}
        //}
    //}
    //
    ///**
     //* Get back copy of the tags
     //*/
    //public function getTags() : Array<String>
    //{
        //var tagsCopy : Array<String> = null;
        //if (m_tags != null) 
        //{
            //tagsCopy = new Array<String>();
            //for (tag in m_tags)
            //{
                //tagsCopy.push(tag);
            //}
        //}
        //return tagsCopy;
    //}
    //
    /**
     * Check whether a tag exists in a node.
     */
    public function getTagWithNameExists(tagName : String) : Bool
    {
        return m_tags != null && Lambda.indexOf(m_tags, tagName) >= 0;
    }
    //
    ///**
     //* Get the objective class name for this node to describe the 'goals' of this level that a player
     //* can accomplish. The level manager should have the mapping from a name to list of actual
     //* objectives.
     //* 
     //* @return
     //*      null if node has no objectives
     //*/
    //public function getObjectiveClass() : String
    //{
        //return m_objectiveClass;
    //}
    //
    ///**
     //* Get whether this node should be visible in the level selection screen
     //*/
    //public function canShowInLevelSelect() : Bool
    //{
        //return m_canShowInLevelSelect;
    //}
    //
    ///**
     //*
     //* @return
     //*      null if no rules to override
     //*/
    //public function getOverriddenRules() : Dynamic
    //{
        //return m_overrideRules;
    //}
    //
    ///**
     //*
     //* @return
     //*      true if we should keep track of the performance state for every attempt on
     //*      this problem. false if we don't care about that info.
     //*/
    //public function getSavePerformanceStateAcrossInstances() : Bool
    //{
        //return m_savePerformanceStateAcrossInstances;
    //}
    //
    ///**
     //* @return
     //*      null if level should not prepopulate the equation
     //*/
    //public function getPrepopulateEquationData() : Dynamic
    //{
        //return m_prepopulateEquationData;
    //}
    //
    ///**
     //* This number is only valid if, the difficultySet flag is true
     //* 
     //* @return
     //*      Numeric representation of how hard this level or level set is to solve
     //*/
    //public function getDifficulty() : Float
    //{
        //return m_difficulty;
    //}
    //
    ///**
     //* @return
     //*      True if the difficulty has been explicitly set for this node
     //*/
    //public function getDifficultySet() : Bool
    //{
        //return m_difficultySet;
    //}
    //
    //private function get_completionValue() : Float
    //{
        //return m_completionValue;
    //}
    //
    ///**
     //* Get the unique name bound to the node assigned beforehand in the data source
     //* describing the progression. Use this name when searching for specific node
     //*/
    //private function get_nodeName() : String
    //{
        //return m_name;
    //}
    //
    ///**
     //* Get runtime generated unique id for level
     //*/
    //private function get_nodeLabel() : Int
    //{
        //return m_nodeLabel;
    //}
    //
    ///**
     //* HACK: isPlayed actually means available
     //* 
     //*/
    //private function get_isPlayed() : Bool
    //{
        //return m_completionValue >= 0;
    //}
    //
    ///**
     //* Is this level node marked as completed
     //*/
    //private function get_isComplete() : Bool
    //{
        //return m_completionValue >= m_levelManager.isCompleteCompletionValue;
    //}
}
