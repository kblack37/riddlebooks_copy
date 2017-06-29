package wordproblem.event;


class CommandEvent
{
    /**
     * Go a specific level. This is primarily a signal sent from the level selection screen.
     * 
     * params: the string id
     */
    public static inline var GO_TO_LEVEL : String = "go_to_level";
    
    /**
     * Go to the next marked level in a sequence. This command is a bit strange because
     * it requires properly ending the 'current' level
     */
    public static inline var GO_TO_NEXT_LEVEL : String = "go_to_next_level";
    
    /**
     * Terminate the current level. In the normal game play flow this occurs when the player
     * presses an exit button. Differs from skip in that this will return the player to the main menu
     * rather than continuing to the next level.
     * 
     * params: Object
     * level: WordProblemLevelData object that was used for the level to termainate. Can be null if no level that is valid.
     */
    public static inline var LEVEL_QUIT_BEFORE_COMPLETION : String = "level_quit";
    
    /**
     * Special case event where the player quits after finishing the level.
     * This is right now exclusively fired from the end of game summary.
     * 
     * The only difference between this and LEVEL_QUIT is that we presumably already marked the level as done
     * through some other logic.
     * 
     * params: Object
     * level: WordProblemLevelData object that was used. Can be null if no level that is valid
     */
    public static inline var LEVEL_QUIT_AFTER_COMPLETION : String = "level_quit_after_completion";
    
    /**
     * Fired to indicate the current level the player is on should restart from the beginning
     * 
     * params:
     *      level: WordProblemLevelData of the level to reset to
     */
    public static inline var LEVEL_RESTART : String = "level_reset";
    
    /**
     * When this event is fired, it indicates that the current level played was skipped before
     * the player properly finished all required steps or actions
     * 
     * THis should not exit the level yet
     * 
     * params: Object
     * level:WordProblemLevelData that was skipped
     */
    public static inline var LEVEL_SKIP : String = "level_skipped";
    
    /**
     * Fired when the user has successfully authenticated their account.
     * When we see this signal we interpret it as meaning the player can now start the game.
     * 
     * params:
     * Optional-grade: The grade level the authenticated user has, use only for demo versions
     */
    public static inline var USER_AUTHENTICATED : String = "user_authenticated";
    
    /**
     * Command the game to show a generic waiting screen
     * 
     * Occurs while waiting for authentication and loading of level resources
     */
    public static inline var WAIT_SHOW : String = "wait_show";
    
    
    /**
     * Command the game to hide the generic waiting screen
     * 
     * Occurs after some asynchronous loading has been completed.
     */
    public static inline var WAIT_HIDE : String = "wait_hide";
    
    /**
     * Occurs if the player wants to sign out of their current account.
     * After doing this they should be able to login with different credentials and the
     * game should load up new data for that account.
     */
    public static inline var SIGN_OUT : String = "sign_out";
    
    /**
     * Occurs when the player wants to reset their save data.
     */
    public static inline var RESET_DATA : String = "reset_data";
    
    /**
     * The the user does not have credentials then they may have an option where they can
     * click some button on the game to create the account. This show the account
     * create screen.
     */
    public static inline var SHOW_ACCOUNT_CREATE : String = "show_account_create";
    
    /**
     * Go to the screen showing player stats and the items they have collected
     */
    public static inline var GO_TO_PLAYER_COLLECTIONS : String = "go_to_player_collections";
    
    /**
     * The user save data has been applied to the level progression system. After this point
     * the runtime representation of the level progress should be initialized to the correct value.
     * Listen for this to know when the save data and the level manager class have been synced
     */
    public static inline var LEVEL_PROGRESS_SAVE_UPLOADED : String = "level_progress_save_uploaded";
    
    /**
     * Changes to the level progress have finished being sent.
     * 
     * Listen for this to know when changes to the level progress save data have all been finished.
     * Immediately after this event is fired the level progress should be in a consistent state.
     */
    public static inline var LEVEL_PROGRESS_SAVE_UPDATED : String = "level_progress_save_updated";

    public function new()
    {
    }
}
