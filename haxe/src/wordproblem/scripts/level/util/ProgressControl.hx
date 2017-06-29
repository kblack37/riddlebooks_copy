package wordproblem.scripts.level.util;


import wordproblem.engine.scripting.graph.ScriptStatus;

/**
 * The class wraps together all the data necessary for a level to keep track of various progress
 * flags in a level.
 * 
 * For example we might want to keep track of the 'stage' a player is in during a multi-step
 * level as the hints may change
 */
class ProgressControl
{
    /**
     * value property is a counter of what part of the problem we are at.
     * Need the wrapper object so the changing of the value can be scheduled in a scripted action event
     */
    private var m_problemStageWrapper : Dynamic;
    
    public function new()
    {
        m_problemStageWrapper = {
                    value : 0

                };
    }
    
    public function incrementProgress() : Void
    {
        setProgress(m_problemStageWrapper.value + 1);
    }
    
    public function setProgress(value : Int) : Void
    {
        m_problemStageWrapper.value = value;
    }
    
    public function getProgress() : Int
    {
        return m_problemStageWrapper.value;
    }
    
    /**
     * Used if you want to include in the custom action nodes.
     */
    public function getProgressEquals(stage : Int) : Int
    {
        var status : Int = ((m_problemStageWrapper.value == stage)) ? 
        ScriptStatus.SUCCESS : ScriptStatus.FAIL;
        return status;
    }
    
    public function getProgressValue(key : String) : Dynamic
    {
        var value : Dynamic = null;
        if (m_problemStageWrapper.exists(key)) 
        {
            value = Reflect.field(m_problemStageWrapper, key);
        }
        return value;
    }
    
    public function setProgressValue(key : String, value : Dynamic) : Void
    {
        Reflect.setField(m_problemStageWrapper, key, value);
    }
    
    public function getProgressValueEquals(key : String, valueToCompare : Dynamic) : Bool
    {
        return getProgressValue(key) == valueToCompare;
    }
    
    // Use so this can be injected into a script sequence more easily
    public function getProgressValueEqualsCallback(params : Dynamic) : Int
    {
        var key : String = params.key;
        var valueToCompare : Dynamic = params.value;
        return ((getProgressValueEquals(key, valueToCompare))) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
    }
}
