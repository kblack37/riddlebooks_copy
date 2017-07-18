package wordproblem.engine.objectives;


import haxe.xml.Fast;
import wordproblem.engine.level.LevelStatistics;

/**
 * Objective that the player must finish a level with n or fewer number of
 * mistake submissions when doing either equation or bar modeling
 * 
 * (This is mostly a hidden objective)
 */
class TotalEquationAndBarModelMistakeObjective extends BaseObjective
{
    public static inline var TYPE : String = "MaxMistakes";
    
    private var m_totalMistakesAllowed : Int;
    
    public function new(totalMistakesAllowed : Int,
            useInSummary : Bool)
    {
        super(TotalEquationAndBarModelMistakeObjective.TYPE, useInSummary);
        
        m_totalMistakesAllowed = totalMistakesAllowed;
    }
    
    override public function getDescription() : String
    {
        var description : String = null;
        if (m_totalMistakesAllowed >= 1) 
        {
            var mistake : String = ((m_totalMistakesAllowed == 1)) ? 
            "mistake" : "mistakes";
            description = "Made " + m_totalMistakesAllowed + " " + mistake + " or less.";
        }
        else 
        {
            description = "Made no mistakes.";
        }
        
        return description;
    }
    
    override public function end(statistics : LevelStatistics) : Void
    {
        var totalSubmissionMistakes : Int = statistics.barModelFails + statistics.equationModelFails;
        
        // Fail if a cheat hint was used or if
        if (totalSubmissionMistakes > m_totalMistakesAllowed ||
            statistics.usedBarModelCheatHint ||
            statistics.usedEquationModelCheatHint) 
        {
            m_grade = 0;
        }
        else 
        {
            m_grade = 100;
        }
    }
    
    override public function deserializeFromXml(element : Fast) : Void
    {
        super.deserializeFromXml(element);
        m_totalMistakesAllowed = Std.parseInt(element.att.value);
    }
    
    override public function deserializeFromJson(data : Dynamic) : Void
    {
        super.deserializeFromJson(data);
        m_totalMistakesAllowed = Std.parseInt(data.value);
    }
    
    override public function clone() : BaseObjective
    {
        var clone : BaseObjective = new TotalEquationAndBarModelMistakeObjective(m_totalMistakesAllowed, this.useInSummary);
        return clone;
    }
}
