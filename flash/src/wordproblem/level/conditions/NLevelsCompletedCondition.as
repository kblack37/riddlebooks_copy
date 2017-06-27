package wordproblem.level.conditions
{
    import wordproblem.engine.level.LevelEndTypes;
    import wordproblem.engine.level.LevelStatistics;

    /**
     * This condition tracks whether N levels within the CURRENT node were completed in total
     */
    public class NLevelsCompletedCondition implements ICondition
    {
        public static const TYPE:String = "NLevelsCompleted";
        
        private var m_n:int;
        
        private var m_totalCompleted:int;
        
        public function NLevelsCompletedCondition(n:int=0)
        {
            m_n = n;
            m_totalCompleted = 0;
        }
        
        public function getSatisfied():Boolean
        {
            return m_totalCompleted >= m_n;
        }
        
        public function getType():String
        {
            return NLevelsCompletedCondition.TYPE;
        }
        
        public function deserialize(data:Object):void
        {
            m_n = parseInt(data.n);
            
            if (data.hasOwnProperty("save"))
            {
                m_totalCompleted = data.save.total;
            }
        }
        
        public function serialize():Object
        {
            return {total: m_totalCompleted};
        }
        
        public function clearState():void
        {
            m_totalCompleted = 0;
        }
        
        public function dispose():void
        {
        }
        
        public function update(data:LevelStatistics):void
        {
            if (data.endType == LevelEndTypes.SOLVED_ON_OWN)
            {
                m_totalCompleted++;
            }
        }
    }
}