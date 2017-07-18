package wordproblem.engine.objectives;


import haxe.xml.Fast;
import wordproblem.engine.level.LevelStatistics;

/**
 * Objective where the player tries to finish the level under some given time threshold
 */
class TimeLimitObjective extends BaseObjective
{
    public static inline var TYPE : String = "MaxTime";
    
    private var m_timeLimitSeconds : Int;
    
    public function new(timeLimitSeconds : Int, useInSummary : Bool)
    {
        super(TimeLimitObjective.TYPE, useInSummary);
        
        m_timeLimitSeconds = timeLimitSeconds;
    }
    
    override public function getDescription() : String
    {
        return "Finish in under " + m_timeLimitSeconds + " seconds";
    }
    
    override public function end(statistics : LevelStatistics) : Void
    {
        var secondsPlayed : Float = statistics.totalMillisecondsPlayed * 0.001;
        
        // If finish under target time, give a 100 grade
        if (secondsPlayed <= m_timeLimitSeconds) 
        {
            m_grade = 100;
        }
        // Otherwise incur a penalty for the amount of time that is over the limit
        else 
        {
            var timeOverLimit : Float = secondsPlayed - m_timeLimitSeconds;
            if (timeOverLimit > 2 * m_timeLimitSeconds) 
            {
                m_grade = 0;
            }
            else if (timeOverLimit > m_timeLimitSeconds) 
            {
                m_grade = Std.int(60 - (timeOverLimit - m_timeLimitSeconds) / m_timeLimitSeconds * 60);
            }
            else 
            {
                m_grade = Std.int(100 - (timeOverLimit / m_timeLimitSeconds) * 40);
            }
        }
    }
    
    override public function deserializeFromXml(element : Fast) : Void
    {
        super.deserializeFromXml(element);
        m_timeLimitSeconds = Std.parseInt(element.att.value);
    }
    
    override public function deserializeFromJson(data : Dynamic) : Void
    {
        super.deserializeFromJson(data);
        m_timeLimitSeconds = Std.parseInt(data.value);
    }
    
    override public function clone() : BaseObjective
    {
        var clone : BaseObjective = new TimeLimitObjective(m_timeLimitSeconds, this.useInSummary);
        return clone;
    }
}
