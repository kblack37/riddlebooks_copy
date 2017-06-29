package wordproblem.engine.level;


/**
 * This is the list of 'exit codes' that are bound to a level based on the terminating condition
 */
class LevelEndTypes
{
    public static inline var SOLVED_ON_OWN : String = "solved";
    public static inline var SOLVED_USING_CHEAT : String = "solved_cheat";
    public static inline var SKIPPED : String = "skipped";
    public static inline var QUIT_BEFORE_SOLVING : String = "quit";

    public function new()
    {
    }
}
