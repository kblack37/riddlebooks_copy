package wordproblem.engine.objectives
{
    import wordproblem.engine.level.LevelStatistics;
    
    /**
     * Objective telling the player the maximum number of new hints they can ask for in a level.
     */
    public class HintUsedObjective extends BaseObjective
    {
        public static const TYPE:String = "HintsUsed";
        
        /**
         * Maximum number of new hints used before the objective is marked as failed.
         */
        private var m_maxNewHints:int;
        
        public function HintUsedObjective(maxNewHints:int,
                                          useInSummary:Boolean=true)
        {
            super(TYPE, useInSummary);
            
            m_maxNewHints = maxNewHints;
        }
        
        override public function getDescription():String
        {
            var description:String = null;
            if (m_maxNewHints > 0)
            {
                description = "Used less than " + m_maxNewHints + " hints";
            }
            else
            {
                description = "No hints used.";
            }
            
            return description; 
        }
        
        override public function end(statistics:LevelStatistics):void
        {
            // Fail object if too many hints uses, also if one of the cheat hints used
            if (statistics.additionalHintsUsed > m_maxNewHints || 
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
            m_maxNewHints = parseInt(element.@value);
        }
        
        override public function deserializeFromJson(data:Object):void
        {
            super.deserializeFromJson(data);
            m_maxNewHints = parseInt(data.value);
        }
        
        override public function clone():BaseObjective
        {
            var clone:BaseObjective = new HintUsedObjective(m_maxNewHints, this.useInSummary);
            return clone;
        }
    }
}