package wordproblem.engine.scripting.graph;


class ScriptStatus
{
    /**
     * Status indicating that a script successfully performed an action or has
     * finished executing all its logic
     */
    public static inline var SUCCESS : Int = 1;
    
    /**
     * Status indicating a script is in the middle of performing some action.
     */
    public static inline var RUNNING : Int = 2;
    
    /**
     * Status indicating a script has failed to perform its intended actions.
     */
    public static inline var FAIL : Int = 3;
    
    /**
     * Status indicating some unexpected condition interrupted the logic
     * (This isn't any different than fail really...)
     */
    public static inline var ERROR : Int = 4;

    public function new()
    {
    }
}
