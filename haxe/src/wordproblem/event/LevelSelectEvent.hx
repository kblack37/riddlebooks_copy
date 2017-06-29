package wordproblem.event;


class LevelSelectEvent
{
    /**
     * Event fired when the player opens up levels belonging to a specific genre
     * 
     * params:
     * The GenreLevelPack node that was opened
     */
    public static inline var OPEN_GENRE : String = "open_genre";
    
    /**
     * Event fired when the player closes the genre widget
     */
    public static inline var CLOSE_GENRE : String = "close_genre";

    public function new()
    {
    }
}
