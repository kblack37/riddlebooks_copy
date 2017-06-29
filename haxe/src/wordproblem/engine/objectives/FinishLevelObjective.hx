package wordproblem.engine.objectives;


import wordproblem.engine.level.LevelStatistics;

/**
 * A baseline objective of the player just going through a level and solving on their own
 */
class FinishLevelObjective extends BaseObjective
{
    public static inline var TYPE : String = "Finish";
    
    public function new()
    {
        super(FinishLevelObjective.TYPE);
    }
    
    override public function getDescription() : String
    {
        return "Solved Level";
    }
    
    override public function end(statistics : LevelStatistics) : Void
    {
        // Automatically set to complete on solve
        if (statistics.usedBarModelCheatHint || statistics.usedEquationModelCheatHint) 
        {
            m_grade = 0;
        }
        else 
        {
            m_grade = 100;
        }
    }
    
    override public function clone() : BaseObjective
    {
        return new FinishLevelObjective();
    }
}
