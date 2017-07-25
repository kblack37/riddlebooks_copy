package wordproblem.player;

// TODO: uncomment once cgs library is ported
//import cgs.cache.ICgsUserCache;

/**
 * This class keeps track of persistent data about the player and their progress that is not
 * already part of the level progression structure.
 * 
 * This is separate from their inventory.
 * 
 * One usage is to use it to interpret the aggregated numbers to figure out if achievements
 * were acquired.
 * 
 * (Achievements may have rewards attached to them, need to remember when to give rewards and
 * when to show graphic that an achievement was unlocked)
 */
class PlayerStatsAndSaveData
{
    /**
     * Key to the associative map storing any persistent decisions the player
     * makes. Right now this is only used for the first couple tutorial levels.
     */
    private static inline var DECISIONS_SAVE_KEY : String = "decisions";
    
    /**
     * Key to the registration name of the cursor last equipped by the user
     */
    private static inline var CURSOR_SAVE_KEY : String = "cursor";
    
    /**
     * Key to the button color name equipped by the user
     */
    private static inline var BUTTON_COLOR_SAVE_KEY : String = "button_color";
    
    /**
     * Key to 0 or 1 to indicate whether hints should automatically appear
     * for some of the level if an incorrect answer is submitted.
     */
    private static inline var ENABLE_HINTS_ON_MISTAKES_KEY : String = "hints";
    
    /**
     * Keep track of whether the next level the player attempts to play should
     * have a partially completed model.
     */
    private static inline var PARTIAL_BAR_COMPLETION_KEY : String = "partial_bar";
    
    /**
     * The cache acts as the read/write interface for the persistent storage of
     * player save data.
     */
    private var m_cache : ICgsUserCache;
    
    /**
     * A volatile object containing any important decisions the player has 
     */
    private var m_playerDecisions : Dynamic;
    
    /**
     * Registered name of the cursor last equipped by player
     */
    private var m_cursorName : String;
    
    /**
     * Registered item id name of a color
     */
    private var m_buttonColorName : String;
    
    private var m_enableHintsOnMistakes : Bool;
    
    /**
     * The amount that the bar model should be partially completed.
     * A zero indicates no completion, higher numbers indicate more parts should be complete
     */
    private var m_partialBarCompletionDegree : Int;
    
    /**
     * HACK: The save data object has a reference to a data blob with the button colors selected
     * by the player. However, it is not
     */
    public var buttonColorData : ButtonColorData;
    
    /**
     * Some bar model levels have custom hints that override the default behavior.
     * If performing a/b testing to compare them with defaults this should be toggled.
     * If false, default hints are always used for bar model.
     */
    public var useCustomHints : Bool = true;
    
    /**
     * Some bar model levels have ai hints that override the default behavior by using 
		 * reinforcement learning to select hints.
     * If performing a/b testing to compare them with defaults this should be toggled.
     * If false, default or custom hints are always used for bar model.
     */
    public var useAiHints : Bool = false;
    
    /**
     *
     * @param cache
     *      Note that the cache can be a dummy source or the actual interface to the cgs servers
     * @param defaultPlayerDecisions
     *      This object is the way for different versions of the game to setup the defaults for
     *      decisions that affect how some of the tutorial levels are configured. The keys are the save
     *      properties, the value is the default if not found in the cache
     */
    public function new(cache : ICgsUserCache,
            defaultPlayerDecisions : Dynamic = null)
    {
        m_cache = cache;
        this.buttonColorData = new ButtonColorData();
        
        // Load data from cache
        if (m_cache != null) 
        {
            if (m_cache.saveExists(PlayerStatsAndSaveData.DECISIONS_SAVE_KEY)) 
            {
                m_playerDecisions = m_cache.getSave(PlayerStatsAndSaveData.DECISIONS_SAVE_KEY);
            }
            
            if (m_cache.saveExists(PlayerStatsAndSaveData.CURSOR_SAVE_KEY)) 
            {
                m_cursorName = m_cache.getSave(PlayerStatsAndSaveData.CURSOR_SAVE_KEY);
            }
            
            if (m_cache.saveExists(PlayerStatsAndSaveData.BUTTON_COLOR_SAVE_KEY)) 
            {
                m_buttonColorName = m_cache.getSave(PlayerStatsAndSaveData.BUTTON_COLOR_SAVE_KEY);
            }
            
            if (m_cache.saveExists(PlayerStatsAndSaveData.ENABLE_HINTS_ON_MISTAKES_KEY)) 
            {
                m_enableHintsOnMistakes = m_cache.getSave(PlayerStatsAndSaveData.ENABLE_HINTS_ON_MISTAKES_KEY) == 1;
            }
            else 
            {
                m_enableHintsOnMistakes = true;
            }
        }
        else 
        {
            m_enableHintsOnMistakes = true;
        }
        
        if (m_playerDecisions == null) 
        {
            m_playerDecisions = { };
        }
        
        m_partialBarCompletionDegree = 0;
        
        // Set up default decision values for things that don't exist in the cache
        if (defaultPlayerDecisions != null) 
        {
            for (decisionKey in Reflect.fields(defaultPlayerDecisions))
            {
                if (!m_playerDecisions.exists(decisionKey)) 
                {
                    Reflect.setField(m_playerDecisions, decisionKey, Reflect.field(defaultPlayerDecisions, decisionKey));
                }
            }
        }
    }
    
    /**
     * Save a decision made by the player during their playthrough of the levels.
     * 
     * For example, if the player chooses to be a girl, some of the text needs to know
     * to change to she
     */
    public function setPlayerDecision(property : String, value : Dynamic) : Void
    {
        Reflect.setField(m_playerDecisions, property, value);
        
        // Flush new decision to the cache.
        if (m_cache != null) 
        {
            m_cache.setSave(PlayerStatsAndSaveData.DECISIONS_SAVE_KEY, m_playerDecisions);
        }
    }
    
    /**
     * Get back the value of a decision made by a player.
     */
    public function getPlayerDecision(property : String) : Dynamic
    {
        return Reflect.field(m_playerDecisions, property);
    }
    
    public function setCursorName(cursorName : String) : Void
    {
        var prevName : String = m_cursorName;
        m_cursorName = cursorName;
        
        if (m_cache != null && prevName != m_cursorName) 
        {
            m_cache.setSave(PlayerStatsAndSaveData.CURSOR_SAVE_KEY, m_cursorName);
        }
    }
    
    /**
     * @return
     *      If null, stick with the current cursor or some known default
     */
    public function getCursorName() : String
    {
        return m_cursorName;
    }
    
    public function setButtonColorName(buttonColorName : String) : Void
    {
        m_buttonColorName = buttonColorName;
        
        if (m_cache != null) 
        {
            m_cache.setSave(PlayerStatsAndSaveData.BUTTON_COLOR_SAVE_KEY, m_buttonColorName);
        }
    }
    
    public function getButtonColorName() : String
    {
        return m_buttonColorName;
    }
    
    public function setEnableHintsOnMistake(value : Bool) : Void
    {
        if (m_enableHintsOnMistakes != value) 
        {
            m_enableHintsOnMistakes = value;
            
            if (m_cache != null) 
            {
                m_cache.setSave(PlayerStatsAndSaveData.ENABLE_HINTS_ON_MISTAKES_KEY, ((m_enableHintsOnMistakes)) ? 1 : 0);
            }
        }
    }
    
    public function getEnableHintsOnMistake() : Bool
    {
        return m_enableHintsOnMistakes;
    }
    
    /**
     * For bar model levels, the degree species how much of the target answer should be
     * initially shown to the player. The motivation is to provide extra help to a user
     * who is struggling with a problem.
     * 
     * @param value
     *      If zero or less, nothing extra is shown. The meaning of greater values depends on the
     *      bar model type, for example a value of 2 for one type might show half of all elements
     *      in it, while in another it shows the total answer.
     */
    public function setPartialBarCompletionDegree(value : Int) : Void
    {
        m_partialBarCompletionDegree = value;
    }
    
    /**
     * Get the degree at which a bar model should be initially completed.
     * 
     * @return
     *      If zero or less, nothing extra is shown.
     */
    public function getPartialBarCompletionDegree() : Int
    {
        return m_partialBarCompletionDegree;
    }
}
