package wordproblem.level;

import cgs.levelProgression.nodes.ICgsLevelNode;

class LevelNodeStatuses
{
    public static inline var LOCKED : String = "locked";
    public static inline var UNLOCKED : String = "unlocked";
    public static inline var PLAYED : String = "played";
    public static inline var UNPLAYED : String = "unplayed";
    public static inline var COMPLETED : String = "completed";
    public static inline var UNCOMPLETED : String = "uncompleted";
    
    /**
     * Used for locking in the level progression, we need to determine
     */
    public static function getNodeMatchesStatus(node : ICgsLevelNode, status : String) : Bool
    {
        var matches : Bool = false;
        switch (status)
        {
            case (LevelNodeStatuses.LOCKED):
                matches = node.isLocked;
            case (LevelNodeStatuses.UNLOCKED):
                matches = !node.isLocked;
            case (LevelNodeStatuses.PLAYED):
                matches = node.isPlayed;
            case (LevelNodeStatuses.UNPLAYED):
                matches = !node.isPlayed;
            case (LevelNodeStatuses.COMPLETED):
                matches = node.isComplete;
            case (LevelNodeStatuses.UNCOMPLETED):
                matches = !node.isComplete;
            // Default behavior is to match if the node is played
            default:
                matches = node.isPlayed;
        }
        
        return matches;
    }

    public function new()
    {
    }
}
