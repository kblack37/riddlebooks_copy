package gameconfig.versions.replay.events
{
    public class ReplayEvents
    {
        /**
         * Exit a currently running replay
         */
        public static const EXIT_REPLAY:String = "exitReplay";
        
        /**
         * Go to a replay for a particular dqid
         * 
         * dqid
         */
        public static const GO_TO_REPLAY_FOR_DQID:String = "goToReplayDqid";
        
        /**
         * Go to a particular action with a replay of a level
         * 
         * actionIndex
         */
        public static const GO_TO_ACTION_AT_INDEX:String = "goActionAtIndex";
    }
}