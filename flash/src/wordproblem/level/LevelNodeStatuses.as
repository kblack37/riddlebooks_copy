package wordproblem.level
{
    import cgs.levelProgression.nodes.ICgsLevelNode;

    public class LevelNodeStatuses
    {
        public static const LOCKED:String = "locked";
        public static const UNLOCKED:String = "unlocked";
        public static const PLAYED:String = "played";
        public static const UNPLAYED:String = "unplayed";
        public static const COMPLETED:String = "completed";
        public static const UNCOMPLETED:String = "uncompleted";
        
        /**
         * Used for locking in the level progression, we need to determine
         */
        public static function getNodeMatchesStatus(node:ICgsLevelNode, status:String):Boolean
        {
            var matches:Boolean = false;
            switch(status)
            {
                case(LevelNodeStatuses.LOCKED):
                    matches = node.isLocked;
                    break;
                case(LevelNodeStatuses.UNLOCKED):
                    matches = !node.isLocked;
                    break;
                case(LevelNodeStatuses.PLAYED):
                    matches = node.isPlayed;
                    break;
                case(LevelNodeStatuses.UNPLAYED):
                    matches = !node.isPlayed;
                    break;
                case(LevelNodeStatuses.COMPLETED):
                    matches = node.isComplete;
                    break;
                case(LevelNodeStatuses.UNCOMPLETED):
                    matches = !node.isComplete;
                    break;
                // Default behavior is to match if the node is played
                default:
                    matches = node.isPlayed;
                    break;
            }
            
            return matches;
        }
    }
}