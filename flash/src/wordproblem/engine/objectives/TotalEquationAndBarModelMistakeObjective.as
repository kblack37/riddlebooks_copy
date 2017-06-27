package wordproblem.engine.objectives
{
    import wordproblem.engine.level.LevelStatistics;
    
    /**
     * Objective that the player must finish a level with n or fewer number of
     * mistake submissions when doing either equation or bar modeling
     * 
     * (This is mostly a hidden objective)
     */
    public class TotalEquationAndBarModelMistakeObjective extends BaseObjective
    {
        public static const TYPE:String = "MaxMistakes";
        
        private var m_totalMistakesAllowed:int
        
        public function TotalEquationAndBarModelMistakeObjective(totalMistakesAllowed:int,
                                                                 useInSummary:Boolean)
        {
            super(TotalEquationAndBarModelMistakeObjective.TYPE, useInSummary);
            
            m_totalMistakesAllowed = totalMistakesAllowed;
        }
        
        override public function getDescription():String
        {
            var description:String = null;
            if (m_totalMistakesAllowed >= 1)
            {
                var mistake:String = (m_totalMistakesAllowed == 1) ?
                    "mistake" : "mistakes";
                description = "Made " + m_totalMistakesAllowed + " " + mistake + " or less.";
            }
            else
            {
                description = "Made no mistakes."
            }
            
            return description;
        }
        
        override public function end(statistics:LevelStatistics):void
        {
            var totalSubmissionMistakes:int = statistics.barModelFails + statistics.equationModelFails;
            
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
        
        override public function deserializeFromXml(element:XML):void
        {
            super.deserializeFromXml(element);
            m_totalMistakesAllowed = parseInt(element.@value);
        }
        
        override public function deserializeFromJson(data:Object):void
        {
            super.deserializeFromJson(data);
            m_totalMistakesAllowed = parseInt(data.value);
        }
        
        override public function clone():BaseObjective
        {
            var clone:BaseObjective = new TotalEquationAndBarModelMistakeObjective(m_totalMistakesAllowed, this.useInSummary);
            return clone;
        }
    }
}