package wordproblem.log;


import cgs.CgsApi;
import cgs.server.challenge.ChallengeService;
import cgs.server.data.TosData;
import cgs.server.logging.CGSServerProps;
import cgs.server.logging.actions.QuestAction;
import cgs.server.responses.QuestLogResponseStatus;
import cgs.user.CgsUserProperties;
import cgs.user.ICgsUser;

import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import starling.events.Event;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.LevelEndTypes;
import wordproblem.engine.level.LevelStatistics;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.event.CommandEvent;
import wordproblem.scripts.BaseBufferEventScript;
import wordproblem.scripts.level.BaseCustomLevelScript;
import wordproblem.state.WordProblemGameState;

/**
 * This class acts as the primary interface between the game and the logging/authentication libraries
 * located in CGSCommon
 */
class AlgebraAdventureLogger extends BaseBufferEventScript
{
    /**
     * A debug flag whether the log messages should be traced to the console.
     */
    private static var TRACE_LOG : Bool = false;
    
    /**
     * The number of milliseconds
     */
    private static inline var INACTIVE_TIME_THRESHOLD_MS : Int = 30000;
    
    /**
     * Main library to fetch the various services from the server.
     */
    private var m_cgsApi : CgsApi;
    
    /**
     * The config struct holds important logging information like category id and deployment settings
     */
    private var m_config : AlgebraAdventureConfig;
    
    /**
     * This is the object that handles recording information about how many levels completed
     * by the player
     */
    private var m_challengeService : ChallengeService;
    
    /**
     * Need a reference to the game engine since that is where all logged actions eminate from.
     */
    private var m_gameEngine : IGameEngine;
    
    /**
     * Flag to keep track of whether or not we are in the middle of quest
     */
    private var m_inMiddleOfQuest : Bool;
    
    /**
     * This timer is used to accumulate the number of seconds in the current quest
     */
    private var m_time : Time;
    
    /**
     * Mousestate is needed so we know if the player is active for some slice of time during play
     */
    private var m_mouseState : MouseState;
    
    /**
     * Record the time value of the start time, last time the mouse state change
     * and incremenatal and total idle times
     */
    private var m_questStartTime : Float;
    
    /**
     * ??? How is this different from quest start time
     */
    private var m_startTime : Float;
    
    private var m_lastMouseChangeTime : Float;
    private var m_incrementalIdleTime : Float;
    private var m_totalIdleTime : Float;
    
    /**
     * keep track of the current quest id
     */
    private var m_currentDqId : String;
    
    /**
     * Non-null if the game client should use a particular uid for anonymous users
     */
    private var m_forceUid : String;
    
    private var m_onUserAuthenticated : Function;
    
    public function new(config : AlgebraAdventureConfig,
            forceUid : String,
            onUserAuthenticated : Function,
            mouseState : MouseState)
    {
        super();
        
        m_cgsApi = new CgsApi(null, null, null, config.getUseHttps());
        m_config = config;
        m_forceUid = forceUid;
        m_onUserAuthenticated = onUserAuthenticated;
        m_mouseState = mouseState;
        m_time = new Time();
        
        m_inMiddleOfQuest = false;
        m_lastMouseChangeTime = m_time.currentTimeMilliseconds;
        m_incrementalIdleTime = 0;
        m_totalIdleTime = 0;
    }
    
    /**
     * Directly access to the functions of the cgs logging api. (Use this to directly authenticate users or
     * create the login dialog)
     */
    public function getCgsApi() : CgsApi
    {
        return m_cgsApi;
    }
    
    /**
     * Getting back the user object since it can be modified during the game from being anonymous
     * to being authenticated.
     */
    public function getCgsUser() : ICgsUser
    {
        var result : ICgsUser = null;
        if (m_cgsApi.userManager.userList.length > 0) 
        {
            result = m_cgsApi.userManager.userList[0];
        }
        return result;
    }
    
    /**
     * Need to set the game engine so we can link into events from it
     * 
     * @param gameEngine
     *      The black box that will fire all the events that we care about logging
     */
    public function setGameEngine(gameEngine : IGameEngine, gameState : WordProblemGameState) : Void
    {
        m_gameEngine = gameEngine;
        
        /*
        All these non-action events should be buffered and then processed on the next frame
        */
        
        // Start and end events
        m_gameEngine.addEventListener(GameEvent.LEVEL_READY, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.LEVEL_COMPLETE, bufferEvent);
        
        // Triggered if the player selects the skip option
        gameState.addEventListener(CommandEvent.LEVEL_SKIP, bufferEvent);
        
        // This actually comes from the summary screen in addition to the option
        gameState.addEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
        gameState.addEventListener(CommandEvent.LEVEL_QUIT_AFTER_COMPLETION, bufferEvent);
        
        // At this stage the player has finished all required objectives in the level.
        // For the challenge stat recording this means logging an equation completion if the level consisted of
        // only a single equation
        m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        
        // Quest actions to log
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.PHRASE_PICKUP_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.PHRASE_DROP_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.EXPRESSION_PICKUP_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.EXPRESSION_DROP_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.VALIDATE_EQUATION_MODEL, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.EXPRESSION_FOUND_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ALL_EXPRESSIONS_FOUND_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.NEGATE_EXPRESSION_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.EQUATION_CHANGED_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.EQUALS_CLICKED_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.TUTORIAL_PROGRESS_EVENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.UNDO_EQUATION, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.RESET_EQUATION, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.UNDO_BAR_MODEL, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.RESET_BAR_MODEL, onGameAction);
        
        // Actions as part of the bar modeling portion
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_SEGMENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.ADD_LABEL_ON_BAR_SEGMENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.MULTIPLY_BAR, onGameAction);
        
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_BAR_COMPARISON, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_BAR_SEGMENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_HORIZONTAL_LABEL, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_VERTICAL_LABEL, onGameAction);
        
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.RESIZE_BAR_COMPARISON, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.RESIZE_HORIZONTAL_LABEL, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.RESIZE_VERTICAL_LABEL, onGameAction);
        
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.SPLIT_BAR_SEGMENT, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.VALIDATE_BAR_MODEL, onGameAction);
        
        // Hint requested
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.HINT_REQUESTED_BARMODEL, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.HINT_REQUESTED_EQUATION, onGameAction);
        m_gameEngine.addEventListener(AlgebraAdventureLoggingConstants.HINT_BUTTON_HIGHLIGHTED, onGameAction);
    }
    
    /**
     * The challenge service can only be created after a user has been authenticated
     */
    public function getChallengeService() : ChallengeService
    {
        return m_challengeService;
    }
    
    private function logQuestStart(problemData : WordProblemLevelData) : Void
    {
        // Record start time, so we can compute the time at which each action occurs
        m_startTime = Date.now().time;
        
        var details : Dynamic = ((Std.is(problemData.getScriptRoot(), BaseCustomLevelScript))) ? 
        (try cast(problemData.getScriptRoot(), BaseCustomLevelScript) catch(e:Dynamic) null).getQuestStartDetails() : { };
        
        // TODO:
        // The random seed used to configure some of the elements of the problem need to be determined
        
        if (m_config.getDoLogQuests()) 
        {
            for (aUser/* AS3HX WARNING could not determine type for var: aUser exp: EField(EField(EIdent(m_cgsApi),userManager),userList) type: null */ in m_cgsApi.userManager.userList)
            {
                aUser.logQuestStart(problemData.getId(), "hash", details, onLogQuestStartComplete);
            }
        }
        
        if (TRACE_LOG) 
        {
            trace("Debug logging: " + problemData.getId() + " hash " + Reflect.field(details, "goalEquation"));
        }
        
        this.m_inMiddleOfQuest = true;
        
        // Reset all timers
        m_time.reset();
        m_lastMouseChangeTime = m_time.currentTimeMilliseconds;
        m_questStartTime = m_time.currentTimeMilliseconds;
        m_totalIdleTime = 0;
        m_incrementalIdleTime = 0;
    }
    
    private function onLogQuestStartComplete(response : QuestLogResponseStatus) : Void
    {
        this.m_currentDqId = response.dqid;
    }
    
    /**
     * The logger needs to update on each frame to correctly measure the amount of active time
     * spent within a quest. Also need to process buffered events.
     */
    override public function visit() : Int
    {
        // Look at buffered events
        super.iterateThroughBufferedEvents();
        
        // Make sure the time object updates itself if the player is in the middle of a level
        if (m_inMiddleOfQuest) 
        {
            m_time.update();
            
            // Detect if the mouse has moved or has been pressed, this means that the player performed an
            // active action.
            if (m_mouseState.mouseDeltaThisFrame.x != 0 || m_mouseState.mouseDeltaThisFrame.y != 0 || m_mouseState.leftMousePressedThisFrame) 
            {
                m_lastMouseChangeTime = m_time.currentTimeMilliseconds;
            }
            
            if (m_time.currentTimeMilliseconds - m_lastMouseChangeTime <= INACTIVE_TIME_THRESHOLD_MS) 
            {
                // the user has been idle for more than 30 seconds
                if (m_incrementalIdleTime > INACTIVE_TIME_THRESHOLD_MS) 
                {
                    // only increment the total idle time once we get moving again.
                    m_totalIdleTime += m_incrementalIdleTime;
                    m_incrementalIdleTime = 0;
                }
            }
            else 
            {  // if idle keep track of for how long during this incremental idle period  
                m_incrementalIdleTime = m_time.currentTimeMilliseconds - m_lastMouseChangeTime;
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.LEVEL_READY) 
        {
            // Register quest start, at this point the entire level and its required resources have been setup
            this.logQuestStart(m_gameEngine.getCurrentLevel());
        }
        else if (eventType == GameEvent.LEVEL_COMPLETE) 
        {
            onGameStateEnd();
        }
        else if (eventType == CommandEvent.LEVEL_SKIP) 
        {
            onGameStateEnd();
        }
        else if (eventType == GameEvent.LEVEL_SOLVED) 
        {
            // Log the level finished
            // Get the equation data and other parameters
            var loggingDetails : Dynamic = { };
            Reflect.setField(loggingDetails, "isComplete", true);
            this.logQuestAction(AlgebraAdventureLoggingConstants.LEVEL_FINISHED_EVENT, loggingDetails);
        }
        else if (eventType == CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION) 
        {
            onGameStateEnd();
        }
    }
    
    /**
     * Get the properties needed to build a logging config. 
     * Adds the properties that the Copilot needs to hook up correctly.
     * Namely, the completeCallback so users can be registered.
     */
    public function getCgsUserProperties(savePlayerDataToServer : Bool, noSqlSaveKey : String) : CgsUserProperties
    {
        // This should read in a configuration from the logging file
        // The main pieces to load are the version id and the category id
        var cgsUserProps : CgsUserProperties = new CgsUserProperties(
        AlgebraAdventureLoggingConstants.SKEY, 
        AlgebraAdventureLoggingConstants.SKEY_HASH, 
        AlgebraAdventureLoggingConstants.GAME_NAME, 
        AlgebraAdventureLoggingConstants.GAME_ID, 
        m_config.getLoggingVersionId(), 
        m_config.getLoggingCategoryId(), 
        m_config.getServerDeployment(), 
        ((m_config.getUseActiveServer())) ? CGSServerProps.CURRENT_VERSION : CGSServerProps.VERSION_DEV, 
        );
        
        // Enable AB Testing
        // By toggling the first parameter to true, then a user will not load any new tests
        // However any new users will also never load a new test either
        if (m_config.getEnableABTesting()) 
        {
            cgsUserProps.enableAbTesting(false);
            
            // If the game uses ab testing, we can use an experiment id.
            // This id must match a category id bound to an active test. By using this any
            // cid in the game can match up with the test regardless of whether we explicitly
            // associated the cid with a test
            if (m_config.getABExperimentId() > -1) 
            {
                cgsUserProps.experimentId = m_config.getABExperimentId();
            }
        }  // This is important if an anonymous player switches between games    // For anonymous users we can force the same uid to be re-used  
        
        
        
        
        
        cgsUserProps.forceUid = m_forceUid;
        
        // Specify the terms of service to use
        if (m_config.getTosKey() != null && m_config.getTosKey().length > 0) 
        {
            cgsUserProps.tosKey = TosData.THIRTEEN_OLDER_TOS_41035_TERMS;
        }  // Enable saving/loading to server  
        
        
        
        cgsUserProps.saveCacheDataToServer = savePlayerDataToServer;
        cgsUserProps.cacheUid = false;
        
        // Tell the server to use the no sql storage
        if (noSqlSaveKey != null && noSqlSaveKey.length > 0) 
        {
            cgsUserProps.enableV2Caching(true, noSqlSaveKey);
        }  // Changing the previous flag is not sufficient by itself    // This is a bit redundant, but in some cases we need to save to local cache instead  
        
        
        
        
        
        if (!savePlayerDataToServer) 
        {
            cgsUserProps.enableCaching(savePlayerDataToServer);
        }
        
        return cgsUserProps;
    }
    
    /**
     * Get the 'active' time the player spent in the quest up to the point when this function was called
     * 
     * @return
     *      Millisecond of active time player has spent in this current level
     */
    public function totalActiveTime() : Float
    {
        return (m_time.currentTimeMilliseconds - m_questStartTime - m_totalIdleTime);
    }
    
    /**
     * Log a quest action.
     * 
     * @param loggingEventType
     *      Name of the action
     * @param details
     *      A blob of data related to just that particular action
     */
    private function logQuestAction(loggingEventType : String, details : Dynamic) : Void
    {
        // Ensure we work on non-null details
        if (details == null) 
        {
            details = new Dynamic();
        }  // also serialize the action data into a string format    // For each action, from its name we need to get the appropriate action id and  
        
        
        
        
        
        if (m_inMiddleOfQuest) 
        {
            var aid : Int = AlgebraAdventureLoggingConstants.getAidForLogEvent(loggingEventType);
            
            if (m_config.getDoLogQuests()) 
            {
                // Compute the time since the quest began, use it in the action
                var currentTime : Float = Date.now().time;
                var deltaTime : Int = (Int)(currentTime - m_startTime);
                
                var questAction : QuestAction = new QuestAction(aid, deltaTime, deltaTime);
                questAction.setDetail(details);
                
                for (aUser/* AS3HX WARNING could not determine type for var: aUser exp: EField(EField(EIdent(m_cgsApi),userManager),userList) type: null */ in m_cgsApi.userManager.userList)
                {
                    aUser.logQuestAction(questAction);
                }
            }
            
            if (TRACE_LOG) 
            {
                trace("Debug logging: Quest action: " + loggingEventType + " id: " + aid);
            }
        }
    }
    
    private function onGameStateEnd() : Void
    {
        // Log quest end with the equation data
        // TODO: Should fetch the exact quest end details from the game script for a particular level
        var levelDataStats : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
        var endType : String = levelDataStats.endType;
        var loggingDetails : Dynamic = { };
        Reflect.setField(loggingDetails, "isComplete", (endType == LevelEndTypes.SOLVED_ON_OWN));
        Reflect.setField(loggingDetails, "endType", endType);
        
        if (levelDataStats.levelGraphEdgeIdTaken != null) 
        {
            Reflect.setField(loggingDetails, "edgeIdTaken", levelDataStats.levelGraphEdgeIdTaken);
        }
        
        if (levelDataStats.masteryIdAchieved > -1) 
        {
            Reflect.setField(loggingDetails, "masteryId", levelDataStats.masteryIdAchieved);
        }  // If a level is successfully solved we want to immediately log the quest end    // Should NOT record the time the player spends looking at the summary screen  
        
        
        
        
        
        var totalActiveTime : Float = m_time.currentTimeMilliseconds - m_questStartTime - m_totalIdleTime;
        Reflect.setField(loggingDetails, "timeInQuest", Std.string(totalActiveTime));
        
        // If a user successfully completed a level, mark it as a completed equation
        // It is also possible that a player did not correctly solve a level, however we still
        // want to increment the total amount of time they spent.
        if (m_challengeService != null) 
        {
            if (endType == LevelEndTypes.SOLVED_ON_OWN) 
            {
                m_challengeService.saveUserEquationWithPlaytime(totalActiveTime, 1);
            }
            else 
            {
                // If they did not finish, still update the playtime
                m_challengeService.updateUserPlaytime(totalActiveTime);
            }
        }
        
        if (m_config.getDoLogQuests()) 
        {
            for (aUser/* AS3HX WARNING could not determine type for var: aUser exp: EField(EField(EIdent(m_cgsApi),userManager),userList) type: null */ in m_cgsApi.userManager.userList)
            {
                aUser.logQuestEnd(loggingDetails, onQuestEndComplete);
            }
        }
        
        if (TRACE_LOG) 
        {
            trace("Debug logging: Quest end. " + endType + " timeInQuest: " + totalActiveTime);
        }
        
        function onQuestEndComplete(response : QuestLogResponseStatus) : Void
        {
            if (TRACE_LOG) 
            {
                trace("Quest end dqid: " + response.dqid);
            }
        };
        
        m_inMiddleOfQuest = false;
    }
    
    private function onGameAction(event : Event, params : Dynamic = null) : Void
    {
        this.logQuestAction(event.type, params);
    }
}

