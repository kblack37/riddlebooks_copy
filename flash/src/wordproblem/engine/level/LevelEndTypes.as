package wordproblem.engine.level
{
    /**
     * This is the list of 'exit codes' that are bound to a level based on the terminating condition
     */
    public class LevelEndTypes
    {
        public static const SOLVED_ON_OWN:String = "solved";
        public static const SOLVED_USING_CHEAT:String = "solved_cheat";
        public static const SKIPPED:String = "skipped";
        public static const QUIT_BEFORE_SOLVING:String = "quit";
    }
}