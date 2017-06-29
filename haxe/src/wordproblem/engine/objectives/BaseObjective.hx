package wordproblem.engine.objectives;


import dragonbox.common.dispose.IDisposable;

import wordproblem.engine.level.LevelStatistics;

/**
 * An objective is some single goal/task that the player can complete in any given level.
 * 
 * This is a super class of all possible objectives.
 * 
 * There are are two primary uses of the objectives.
 * The first is defining the parameters the player needs to meets for the final performance calculation
 * used in the adaptive level progression. (i.e. player needs to meet a set of objective to advance to a
 * new level set tier.
 * The second is defining player goals that they can accomplish for personal level score or in-game bonuses.
 */
class BaseObjective implements IDisposable
{
    /**
     * If true, then this objective should be shown in the summary screen and it should be
     * used to calculate the overall grade that is saved as the player's score
     */
    public var useInSummary : Bool;
    
    /**
     * Unique id describing the type of this objective
     */
    private var m_type : String;
    
    /**
     * A value between 0 and 100 to indicate a player's performance in
     * accomplishing an objective.
     * 
     * Grade should be calculated at the end of a level.
     */
    private var m_grade : Int;
    
    public function new(type : String,
            useInSummary : Bool = true)
    {
        m_type = type;
        m_grade = 0;
        this.useInSummary = useInSummary;
    }
    
    public function dispose() : Void
    {
    }
    
    /**
     * When this function is called, this objective should stop recording information
     * and can now evaluate whether it has been successfully completed.
     * 
     * This function should write out the grade achived
     * 
     * @param statistics
     *      Upon completion of a level, some objectives might want to look at the play stats
     *      to determine successful completion. For example an objective of finishing the level
     *      with fewer than 3 mistakes would look at the times the player modeled the equation incorrectly
     *      at the end.
     */
    public function end(statistics : LevelStatistics) : Void
    {
    }
    
    /**
     * Each objective has a grade score between 0 and 100 to indicate how well the
     * player did in completing the objective.
     * 
     * @return
     *      A grade of 100 means the player fully completed an objective.
     *      Score becomes lower from there depending on how far the player was from the goal.
     *      For example if the objective was make no modeling mistakes, the grade would decrease
     *      for every incorrect submission.
     */
    public function getGrade() : Int
    {
        return m_grade;
    }
    
    /**
     * Assuming no partial completion of an objective.
     * 
     * @return
     *      True if the player successfully completed this objective
     */
    public function getCompleted() : Bool
    {
        // A perfect score on object would mean they did everything they possibly could in
        // finishing the objective
        return (m_grade == 100);
    }
    
    /**
     * Get back a description of how well the player performed
     * 
     * @return
     *      An example is if the objective is finishing under some time this description
     *      returns the time they achieved.
     */
    public function getPerformanceDescription() : String
    {
        return null;
    }
    
    /**
     * Get back details about this objective, tells user what was a goal in the level.
     * 
     * @return
     *      A description of this objective, used for the summary
     */
    public function getDescription() : String
    {
        return null;
    }
    
    /**
     * Extract data/settings for an objective from xml structure.
     * (Objectives baked in the level xml)
     * 
     * Subclasses should override AND call this super method if they have more
     * data to parse.
     */
    public function deserializeFromXml(element : FastXML) : Void
    {
        if (element.node.exists.innerData("@useInSummary")) 
        {
            this.useInSummary = (element.att.useInSummary == "true");
        }
    }
    
    /**
     * Extract data/settings for an objective from xml structure.
     * (Objectives baked in the level progression json)
     * 
     * Subclasses should override AND call this super method if they have more
     * data to parse.
     */
    public function deserializeFromJson(data : Dynamic) : Void
    {
        if (data.exists("useInSummary")) 
        {
            this.useInSummary = data.useInSummary;
        }
    }
    
    /**
     * Create a new copy of this objective, subclasses should override.
     */
    public function clone() : BaseObjective
    {
        return null;
    }
    
    /**
     * Convert the progress achieved in this objective into a compressed format that
     * can be saved on the server
     * 
     */
    public function serialize() : Dynamic
    {
        return null;
    }
}
