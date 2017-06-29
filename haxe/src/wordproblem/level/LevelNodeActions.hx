package wordproblem.level;


/**
 * Listing of possible actions that are executed when an edge in the progression graph is taken.
 * Actions are encoded within the edge portion of the progression json
 * 
 * Each type has unique set of parameters that needs custom code to interpret, so this class is more
 * like documentation.
 */
class LevelNodeActions
{
    /**
     * Mark and save a node having a complete.
     * Useful mainly for level packs where completion might be determined by complex conditions that
     * are difficult to reconstruct from current state.
     * 
     * params:
     * name-String name of node
     */
    public static inline var SET_NODE_COMPLETE : String = "SetNodeComplete";
    
    /**
     * params:
     * name-String name of node
     */
    public static inline var SET_NODE_AVAILABLE : String = "SetNodeAvailable";
    
    /**
     * Send a message that player
     * (Want to make sure mastery signal not sent multiple times, one way to prevent this is
     * to bind mastery to completion of a level pack. If the pack is marked as complete then
     * don't perform this action again)
     * 
     * params:
     * masteryId-String name of type of mastery
     */
    public static inline var SET_MASTERY : String = "SetMastery";
    
    /**
     * Pick a random level at the the current node that had the edge going into it.
     */
    public static inline var PICK_RANDOM_UNCOMPLETED_LEVEL : String = "PickRandomUncompletedLevel";
    
    /**
     * Treating levels as a linear sequence pick the first one in the list that is not completed
     * and not locked.
     */
    public static inline var PICK_FIRST_UNCOMPLETED_LEVEL : String = "PickFirstUncompletedLevel";
    
    /**
     * Treating levels as a linear sequence pick the first one regardless of completion value.
     */
    public static inline var PICK_FIRST_LEVEL : String = "PickFirstLevel";
    
    /**
     * Treating everything as a linear set, just pick the very next one. It will loop back to
     * the start when we reach the end of the set.
     */
    public static inline var PICK_NEXT_IN_SET : String = "PickNextInSet";
    
    /**
     * Clear all the state related to a condition.
     * Used specifically for brainpop experiment where we want to reset the k out of n conditions
     */
    public static inline var CLEAR_CONDITIONS_FOR_EDGE : String = "ClearConditionsForEdge";
    
    /**
     * For one of the release versions we want the behavior where for a particular problem, we keep
     * track of all mistakes and hints used across all instances and use that in the mastery calculation.
     * However at some points if the player loops back to that problem, the state should be cleared
     */
    public static inline var CLEAR_PERFORMANCE_STATE_FOR_NODE : String = "ClearPerformanceStateForNode";

    public function new()
    {
    }
}
