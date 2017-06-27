package wordproblem.level
{
    public class LevelNodeCompletionValues
    {
        /**
         * A node that is unknown is not necessarily locked, this value means we don't know
         * if the player has ever played it. Locked means the player cannot even access it
         * 
         * It is the default starting value.
         */
        public static const UNKNOWN:int = -1;
        
        /**
         * We are sure the player never attempted the level
         */
        public static const UNPLAYED:int = 0;
        
        /**
         * Player skipped the level, did not reach the end
         */
        public static const PLAYED_SKIPPED:int = 1;
        
        /**
         * Player attempted level and reached the end but they did achieve desired results.
         * This is for the case where they may have used a cheat.
         */
        public static const PLAYED_FAIL:int = 2;
        
        /**
         * The level manager assigns a single value to indicate whether something is fully complete.
         * This completion value is saved in the player's save data
         */
        public static const PLAYED_SUCCESS:int = 3;
    }
}