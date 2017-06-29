package wordproblem.level.conditions;


import wordproblem.engine.level.LevelEndTypes;
import wordproblem.engine.level.LevelStatistics;

/**
 * This condition tracks whether N levels within the CURRENT node were completed in total
 */
class NLevelsCompletedCondition implements ICondition
{
    public static inline var TYPE : String = "NLevelsCompleted";
    
    private var m_n : Int;
    
    private var m_totalCompleted : Int;
    
    public function new(n : Int = 0)
    {
        m_n = n;
        m_totalCompleted = 0;
    }
    
    public function getSatisfied() : Bool
    {
        return m_totalCompleted >= m_n;
    }
    
    public function getType() : String
    {
        return NLevelsCompletedCondition.TYPE;
    }
    
    public function deserialize(data : Dynamic) : Void
    {
        m_n = parseInt(data.n);
        
        if (data.exists("save")) 
        {
            m_totalCompleted = data.save.total;
        }
    }
    
    public function serialize() : Dynamic
    {
        return {
            total : m_totalCompleted

        };
    }
    
    public function clearState() : Void
    {
        m_totalCompleted = 0;
    }
    
    public function dispose() : Void
    {
    }
    
    public function update(data : LevelStatistics) : Void
    {
        if (data.endType == LevelEndTypes.SOLVED_ON_OWN) 
        {
            m_totalCompleted++;
        }
    }
}
