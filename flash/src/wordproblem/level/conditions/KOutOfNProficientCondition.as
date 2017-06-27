package wordproblem.level.conditions
{
    import wordproblem.engine.level.LevelEndTypes;
    import wordproblem.engine.level.LevelStatistics;
    import wordproblem.engine.objectives.BaseObjective;
    import wordproblem.level.nodes.WordProblemLevelLeaf;

    /**
     * This condition keeps track of the last N levels played for the CURRENT node and whether
     * or not they were completed with proficiency. We define proficiency as all specially marked
     * goals in a level, like finished in under X seconds or fewer than X mistake submissions,
     * being accomplished.
     * 
     * If configured with a non-positive n, this condition will simply check that the player has
     * completed K level across all instance (like an infinite history)
     * 
     * Condition can also be given a tag name to filter the types of levels it can accept, ex.) we
     * may only care about 'add' levels in one instant and 'subtract' levels in another
     * 
     */
    public class KOutOfNProficientCondition implements ICondition
    {
        public static const TYPE:String = "KOutOfNProficient";
        
        private var m_objectiveClass:String;
        
        private var m_k:int;
        
        /**
         * If n is zero or less then the history becomes 'infinite'.
         * Essentially we just keep a global count.
         */
        private var m_n:int;
        private var m_totalSuccessCount:int = 0;
        
        /**
         * If tag is not null, then we only take into account levels that have a matching tag attribute
         * when updating the condition.
         */
        private var m_tag:String;
        
        /**
         * History of the last n levels.
         * 
         * First element of list is the oldest
         */
        private var m_wasLevelProficientHistory:Vector.<Boolean>;
        
        public function KOutOfNProficientCondition(k:int=0, n:int=0)
        {
            m_k = k;
            m_n = n;
            m_wasLevelProficientHistory = new Vector.<Boolean>();
            m_objectiveClass = null;
            m_tag = null;
        }
        
        public function getLevelProficientHistory():Vector.<Boolean> {
            var ret:Vector.<Boolean> = new Vector.<Boolean>();
            for (var i:int = 0; i < m_wasLevelProficientHistory.length; i++ ) {
                ret.push(m_wasLevelProficientHistory[i]);
            }
            return ret;
        }
        
        public function getSatisfied():Boolean
        {
            var numProficient:int = 0;
            if (m_n > 0)
            {
                var i:int;
                for (i = 0; i < m_wasLevelProficientHistory.length; i++)
                {
                    if (m_wasLevelProficientHistory[i])
                    {
                        numProficient++;
                    }
                }
            }
            else
            {
                // If n is not positive, history becomes infinite just have a success count
                numProficient = m_totalSuccessCount;
            }
            return numProficient >= m_k;
        }
        
        public function getType():String
        {
            return KOutOfNProficientCondition.TYPE;
        }
        
        public function deserialize(data:Object):void
        {
            m_k = parseInt(data.k);
            m_n = parseInt(data.n);
            m_objectiveClass = data.objectiveClass;
            
            if (data.hasOwnProperty("tagName"))
            {
                m_tag = data.tagName;
            }
            
            // Injecting save data
            if (data.hasOwnProperty("save"))
            {
                var saveBlob:Object = data.save;
                if (saveBlob.hasOwnProperty("values"))
                {
                    var savedValues:Array = saveBlob.values;
                    for (var i:int = 0; i < savedValues.length; i++)
                    {
                        m_wasLevelProficientHistory.push(savedValues[i]);
                    }
                }
                
                if (saveBlob.hasOwnProperty("count"))
                {
                    m_totalSuccessCount = saveBlob.count;
                }
            }
        }
        
        public function serialize():Object
        {
            var serializedSaveData:Object = {};
            var savedValues:Array = [];
            for (var i:int = 0; i < m_wasLevelProficientHistory.length;i++)
            {
                savedValues.push(m_wasLevelProficientHistory[i]);
            }
            
            if (savedValues.length > 0)
            {
                serializedSaveData["values"] = savedValues;
            }
            
            // If there is no threshold window, just keep a tally of the number
            // of successfully completed levels
            if (m_n == 0)
            {
                serializedSaveData["count"] = m_totalSuccessCount;
            }
            
            return serializedSaveData;
        }
        
        public function clearState():void
        {
            m_wasLevelProficientHistory.length = 0;
            m_totalSuccessCount = 0;
        }
        
        public function dispose():void
        {
        }
        
        public function getObjectiveClass():String
        {
            return m_objectiveClass;
        }
        
        public function update(currentLevelLeaf:WordProblemLevelLeaf, stats:LevelStatistics, objectives:Vector.<BaseObjective>):void
        {
            if (m_tag == null || currentLevelLeaf.getTagWithNameExists(m_tag))
            {
                // Quit before solving doesn't count in the history
                // Without this line, brainpop experiment doesn't work as expected since it needs
                // one history entry per level.
                if (stats.endType == LevelEndTypes.QUIT_BEFORE_SOLVING)
                {
                    return;
                }
                
                var lastLevelProficientlyCompleted:Boolean = true;
                if (stats.endType == LevelEndTypes.SOLVED_ON_OWN)
                {
                    var i:int;
                    var numObjectives:int = objectives.length;
                    for (i = 0; i < numObjectives; i++)
                    {
                        var objective:BaseObjective = objectives[i];
                        objective.end(stats);
                        if (!objective.getCompleted())
                        {
                            lastLevelProficientlyCompleted = false;
                            break;
                        }
                    }
                }
                else
                {
                    // Failure to solve the level on their own is an auto fail.
                    lastLevelProficientlyCompleted = false;
                }
                
                if (lastLevelProficientlyCompleted)
                {
                    m_totalSuccessCount++;
                }
                
                m_wasLevelProficientHistory.push(lastLevelProficientlyCompleted);
                if (m_wasLevelProficientHistory.length > m_n)
                {
                    m_wasLevelProficientHistory.shift();
                }
            }
        }
    }
}