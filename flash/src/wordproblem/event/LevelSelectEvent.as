package wordproblem.event
{
    public class LevelSelectEvent
    {
        /**
         * Event fired when the player opens up levels belonging to a specific genre
         * 
         * params:
         * The GenreLevelPack node that was opened
         */
        public static const OPEN_GENRE:String = "open_genre";
        
        /**
         * Event fired when the player closes the genre widget
         */
        public static const CLOSE_GENRE:String = "close_genre";
    }
}