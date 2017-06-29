package gameconfig.versions.replay.events;


class ReplayEvents
{
    /**
     * Exit a currently running replay
     */
    public static inline var EXIT_REPLAY : String = "exitReplay";
    
    /**
     * Go to a replay for a particular dqid
     * 
     * dqid
     */
    public static inline var GO_TO_REPLAY_FOR_DQID : String = "goToReplayDqid";
    
    /**
     * Go to a particular action with a replay of a level
     * 
     * actionIndex
     */
    public static inline var GO_TO_ACTION_AT_INDEX : String = "goActionAtIndex";

    public function new()
    {
    }
}
