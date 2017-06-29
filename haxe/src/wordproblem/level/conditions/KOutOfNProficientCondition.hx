package wordproblem.level.conditions;


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
class KOutOfNProficientCondition implements ICondition
{
    public static inline var TYPE : String = "KOutOfNProficient";
    
    private var m_objectiveClass : String;
    
    private var m_k : Int;
    
    /**
     * If n is zero or less then the history becomes 'infinite'.
     * Essentially we just keep a global count.
     */
    private var m_n : Int;
    private var m_totalSuccessCount : Int = 0;
    
    /**
     * If tag is not null, then we only take into account levels that have a matching tag attribute
     * when updating the condition.
     */
    private var m_tag : String;
    
    /**
     * History of the last n levels.
     * 
     * First element of list is the oldest
     */
    private var m_wasLevelProficientHistory : Array<Bool>;
    
    public function new(k : Int = 0, n : Int = 0)
    {
        m_k = k;
        m_n = n;
        m_wasLevelProficientHistory = new Array<Bool>();
        m_objectiveClass = null;
        m_tag = null;
    }
    
    public function getLevelProficientHistory() : Array<Bool>{
        var ret : Array<Bool> = new Array<Bool>();
        for (i in 0...m_wasLevelProficientHistory.length){
            ret.push(m_wasLevelProficientHistory[i]);
        }
        return ret;
    }
    
    public function getSatisfied() : Bool
    {
        var numProficient : Int = 0;
        if (m_n > 0) 
        {
            var i : Int;
            for (i in 0...m_wasLevelProficientHistory.length){
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
    
    public function getType() : String
    {
        return KOutOfNProficientCondition.TYPE;
    }
    
    public function deserialize(data : Dynamic) : Void
    {
        m_k = parseInt(data.k);
        m_n = parseInt(data.n);
        m_objectiveClass = data.objectiveClass;
        
        if (data.exists("tagName")) 
        {
            m_tag = data.tagName;
        }  // Injecting save data  
        
        
        
        if (data.exists("save")) 
        {
            var saveBlob : Dynamic = data.save;
            if (saveBlob.exists("values")) 
            {
                var savedValues : Array<Dynamic> = saveBlob.values;
                for (i in 0...savedValues.length){
                    m_wasLevelProficientHistory.push(savedValues[i]);
                }
            }
            
            if (saveBlob.exists("count")) 
            {
                m_totalSuccessCount = saveBlob.count;
            }
        }
    }
    
    public function serialize() : Dynamic
    {
        var serializedSaveData : Dynamic = { };
        var savedValues : Array<Dynamic> = [];
        for (i in 0...m_wasLevelProficientHistory.length){
            savedValues.push(m_wasLevelProficientHistory[i]);
        }
        
        if (savedValues.length > 0) 
        {
            Reflect.setField(serializedSaveData, "values", savedValues);
        }  // of successfully completed levels    // If there is no threshold window, just keep a tally of the number  
        
        
        
        
        
        if (m_n == 0) 
        {
            Reflect.setField(serializedSaveData, "count", m_totalSuccessCount);
        }
        
        return serializedSaveData;
    }
    
    public function clearState() : Void
    {
        as3hx.Compat.setArrayLength(m_wasLevelProficientHistory, 0);
        m_totalSuccessCount = 0;
    }
    
    public function dispose() : Void
    {
    }
    
    public function getObjectiveClass() : String
    {
        return m_objectiveClass;
    }
    
    public function update(currentLevelLeaf : WordProblemLevelLeaf, stats : LevelStatistics, objectives : Array<BaseObjective>) : Void
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
            
            var lastLevelProficientlyCompleted : Bool = true;
            if (stats.endType == LevelEndTypes.SOLVED_ON_OWN) 
            {
                var i : Int;
                var numObjectives : Int = objectives.length;
                for (i in 0...numObjectives){
                    var objective : BaseObjective = objectives[i];
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
