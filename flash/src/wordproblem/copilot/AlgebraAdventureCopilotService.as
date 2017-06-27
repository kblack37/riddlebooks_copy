package wordproblem.copilot 
{
    import flash.system.Security;
    import flash.utils.getTimer;
    
    import cgs.CgsApi;
    import cgs.teacherportal.CgsCopilotProperties;
    import cgs.teacherportal.CopilotService;
    import cgs.teacherportal.ICopilotLogger;
    import cgs.user.CgsUserProperties;
    import cgs.user.ICgsUser;
    
    import starling.display.DisplayObject;
    
    import wordproblem.WordProblemGameBase;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.log.AlgebraAdventureLogger;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.scripts.BaseBufferEventScript;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    
    /**
     * The class acts as the interface between the game and the copilot service, it handles the sending
     * and recieving of data between the two.
     * 
     * Game specific notes:
     * Normally a problem set is a single playable level of the game.
     * The 'problems' contained in the set are things that the player needs to model,
     * which is either create an equation or a bar model.
     * 
     * @author Rich
     */
    public class AlgebraAdventureCopilotService extends BaseBufferEventScript
    {
        /*
        HACK: Sending topic related to mastery
        */
        private var m_idToMasteryTopic:Object = {
            1: "Simple Addition",
            2: "Simple Subtraction",
            3: "Simple Multiplication and Division",
            4: "Multi-Operation Multiplication and Division",
            5: "Problems With Multiple Variables",
            6: "Simple Fractions",
            7: "Multi-Operation Fractions"
        };
        
        // State
        private var m_cgsCommonCopilotService:CopilotService;
        private var m_base:WordProblemGameBase;
        private var m_levelManager:WordProblemCgsLevelManager;
        private var m_logger:AlgebraAdventureLogger;
        
        // Flags
        private var m_isCopilotPaused:Boolean;
        
        /**
         * A problem id maps to a part/phase of a level.
         * 
         * We use the assumption that a part/phase is an attempt to model either a bar model or
         * an equation. We can use that fact that each part or phase is separated when the player
         * correctly solves a model. So there is no simultaneous solving of equations.
         * 
         * I.e.
         * We set a goal bar model. Any submission are related to that bar model. When they submit a right
         * answer the problem ends and another goal appears. New results map to that goal only.
         */
        private var m_currentProblemIdCounter:int;
        
        /**
         * If not null, an application has specialized logic it wants to execute on an activity start
         */
        private var m_onCopilotActivityStartCallback:Function;
        
        private var m_savedPreviousBarModelDatum:Object;
        private var m_textAreaOutBuffer:Vector.<DisplayObject>;
        
        /**
         * Want to only send bar model result when a change occurs (prevent seeing too many results if
         * the user just continuously clicks the submit button
         */
        private var m_barModelDiffersFromLastValidateAttempt:Boolean;
        
        /**
         * Similar to the bar model flag, only send result if the equation appears different from when the
         * last validation was sent
         */
        private var m_equationDiffersFromLastValidateAttempt:Boolean;
        
        /**
         * This is to rate limit the results that would come from the player rapidly clicking
         * the submit button without making any changes. It would be useful still to see
         * that such mistakes are sent to the copilot but we don't want too much traffic
         * from this action.
         */ 
        private var m_msTimeStampSinceLastResult:int;
        
        /**
         * This is the number of seconds between each accepted result
         */
        private var m_rateLimitThresholdMs:Number = 1500;
        
        /**
         * Initializes the copilot service
         * 
         * Need to be able to do this without the user having to authenticate.
         * 
         * @param onCopilotActivityStart
         *      Callback the 'main' application class should use in order to get back extra information
         */
        public function AlgebraAdventureCopilotService(cgsApi:CgsApi, 
                                                       props:CgsUserProperties,
                                                       base:WordProblemGameBase, 
                                                       levelManager:WordProblemCgsLevelManager, 
                                                       logger:AlgebraAdventureLogger, 
                                                       onCopilotActivityStart:Function=null) 
        {
            // Start copilot service
            Security.allowDomain("*");
            m_cgsCommonCopilotService = cgsApi.createCopilotService(props, getCopilotProps());
            
            m_base = base;
            m_levelManager = levelManager;
            m_logger = logger;
            m_onCopilotActivityStartCallback = onCopilotActivityStart;
            
            m_textAreaOutBuffer = new Vector.<DisplayObject>();
            
            // Ready event is buffered because other scripts have setup logic they want to perfrom first
            m_base.gameEngine.addEventListener(GameEvent.LEVEL_READY, bufferEvent); 
            m_base.gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
            m_base.gameEngine.addEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, bufferEvent);
            m_base.gameEngine.addEventListener(AlgebraAdventureLoggingConstants.VALIDATE_EQUATION_MODEL, bufferEvent);
            m_base.gameEngine.addEventListener(AlgebraAdventureLoggingConstants.VALIDATE_BAR_MODEL, bufferEvent);
            
            // Exit and skip also need to send a message to close the problem set
            // ?? This needs to send problem end, but also perhaps another result for problem failure
            m_base.gameEngine.addEventListener(AlgebraAdventureLoggingConstants.SKIP, bufferEvent);
            m_base.gameEngine.addEventListener(AlgebraAdventureLoggingConstants.EXIT_BEFORE_COMPLETION, bufferEvent);
            
            m_msTimeStampSinceLastResult = 0;
        }
        
        /**
         * This must be called to signal to the copilot that the application is ready for commands.
         * IMPORTANT: Should only call this after all game initialization has been finished
         */
        public function applicationReady():void
        {
            // Notify the copilot that we are ready for commands.
            // Add delay to prevent timing issue
            m_cgsCommonCopilotService.onWidgetReady();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_base.gameEngine.removeEventListener(GameEvent.LEVEL_READY, bufferEvent); 
            m_base.gameEngine.removeEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
            m_base.gameEngine.removeEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, bufferEvent);
            m_base.gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.VALIDATE_EQUATION_MODEL, bufferEvent);
            m_base.gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.VALIDATE_BAR_MODEL, bufferEvent);
            m_base.gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.SKIP, bufferEvent);
            m_base.gameEngine.removeEventListener(AlgebraAdventureLoggingConstants.EXIT_BEFORE_COMPLETION, bufferEvent);
        }
        
        private function logCopilotProblemSetStart(problemData:WordProblemLevelData, numResults:int):void
        {
            var data:Object = {world:problemData.getGenreId(), chapter:problemData.getChapterIndex(), level:problemData.getLevelIndex()};
            if (problemData.getBarModelType() != null)
            {
                data.barModelType = problemData.getBarModelType();
            }
            var cgsApi:CgsApi = m_logger.getCgsApi();
            for each (var aUser:ICgsUser in cgsApi.userManager.userList)
            {
                (aUser as ICopilotLogger).logProblemSetStart(problemData.getId().toString(), numResults, data);
            }
            
            // Reset the current problem counter on every new problem set
            m_currentProblemIdCounter = 1;
            
            // Reset the flags
            m_barModelDiffersFromLastValidateAttempt = true;
            m_equationDiffersFromLastValidateAttempt = true;
        }
        
        /*
        The assumption we are working on is that the game will send EVERYTHING that the copilot
        would want to display at any given step->
        This includes the student solution for a bar model and equation.
        And the expected equation for the bar model.
        At the equation step if a bar model was previously created just continue using that
        */
        private function logCopilotProblemResult(result:Number, extraResultData:Object):void
        {
            // A temp hack, we want to associate results with a particular phase/part of a problems
            var problemPartId:Array = [m_currentProblemIdCounter.toString()];
            
            if (extraResultData == null)
            {
                extraResultData = {};
            }
            
            extraResultData["gname"] = AlgebraAdventureLoggingConstants.GAME_NAME;
            
            var cgsApi:CgsApi = m_logger.getCgsApi();
            for each (var aUser:ICgsUser in cgsApi.userManager.userList)
            {
                (aUser as ICopilotLogger).logProblemResult(result, problemPartId, extraResultData);
            }
        }
        
        private function logCopilotProblemSetEnd(problemData:WordProblemLevelData):void
        {
            // At the end of a level send optional
            // {mastery: <mastery_id_number>}
            var endDetails:Object = null;
            if (problemData.statistics.masteryIdAchieved >= 0)
            {
                endDetails = {};
                
                var masteryId:int = problemData.statistics.masteryIdAchieved;
                endDetails.mastery = masteryId;
                
                if (m_idToMasteryTopic.hasOwnProperty(masteryId))
                {
                    endDetails.masteryTopic = m_idToMasteryTopic[masteryId];
                }
            }
            var cgsApi:CgsApi = m_logger.getCgsApi();
            for each (var aUser:ICgsUser in cgsApi.userManager.userList)
            {
                (aUser as ICopilotLogger).logProblemSetEnd(endDetails);
            }
        }
        
        /**
         * Returns the properties for the copilot to be created with.
         */
        private function getCopilotProps():CgsCopilotProperties
        {
            return new CgsCopilotProperties(
                startCallback, 
                stopCallback, 
                setPauseCallback, 
                addUserCallback, 
                removeUserCallback, 
                commandToWidget
            );
        }
        
        /**
         * Get back whether the copilot should be in a paused state,
         * the app decides what should happen.
         * 
         * @return
         *      true if the copilot should be paused
         */
        public function get isPaused():Boolean
        {
            return m_isCopilotPaused;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            var currentLevelData:WordProblemLevelData = m_base.gameEngine.getCurrentLevel();
            if (eventType == GameEvent.LEVEL_READY)
            {
                // Log the start
                // The number of results is the number of equations the player will solve
                
                // We enforce the behavior that levels must define the number of 'problems' contained in them
                // at the very start.
                var levelScript:BaseCustomLevelScript = currentLevelData.getScriptRoot() as BaseCustomLevelScript;
                var numProblems:int = levelScript.getNumCopilotProblems();
                
                this.logCopilotProblemSetStart(currentLevelData, numProblems);
                m_savedPreviousBarModelDatum = null;
            }
            else if (eventType == GameEvent.LEVEL_SOLVED)
            {
                // Log copilot end, if attached to copilot (MUST BE AFTER QUEST END)
                this.logCopilotProblemSetEnd(currentLevelData);
            }
            else if (eventType == GameEvent.BAR_MODEL_AREA_CHANGE)
            {
                m_barModelDiffersFromLastValidateAttempt = true;
            }
            else if (eventType == GameEvent.EQUATION_CHANGED)
            {
                m_equationDiffersFromLastValidateAttempt = true;
            }
            else if (eventType == AlgebraAdventureLoggingConstants.VALIDATE_EQUATION_MODEL)
            {
                var msSinceLastResultSent:Number = getTimer() - m_msTimeStampSinceLastResult;
                
                var isCorrect:Boolean = param.isCorrect;
                if (!isCorrect || (isCorrect && currentLevelData.statistics.usedEquationModelCheatHint))
                {
                    var result:int = 0;
                }
                else
                {
                    result = 1;
                }
                
                if (m_equationDiffersFromLastValidateAttempt || msSinceLastResultSent > m_rateLimitThresholdMs)
                {
                    m_msTimeStampSinceLastResult = getTimer();
                    
                    // The completion of the equation checking phase depends on whether the player has finished
                    // modeling some target set of equations
                    // Send the equation snapshot along with the result
                    var problemText:String = getTextForCurrentPage()
                    var equationResultData:Object = {equation: param.equation, refEquation: param.goalEquation, problemText: problemText};
                    
                    if (m_savedPreviousBarModelDatum != null)
                    {
                        // If there is a previous bar model that is linked to this equation,
                        // send it as well
                        equationResultData["barModel"] = m_savedPreviousBarModelDatum;
                    }
                    
                    this.logCopilotProblemResult(result, equationResultData);
                }
                
                if (param.setComplete as Boolean)
                {
                    // Increment the id to the next value if the 'equation phase' is complete
                    m_currentProblemIdCounter++;
                }
                
                m_equationDiffersFromLastValidateAttempt = false;
            }
            else if (eventType == AlgebraAdventureLoggingConstants.VALIDATE_BAR_MODEL)
            {
                isCorrect = param.isCorrect;
                msSinceLastResultSent = getTimer() - m_msTimeStampSinceLastResult;
                
                // Always send a result when they try to submit, correctness just depends on whether
                // that submission is correct.
                // However a correct submission is wrong if the cheat hint was used
                if (!isCorrect || (isCorrect && currentLevelData.statistics.usedBarModelCheatHint))
                {
                    result = 0;
                }
                else
                {
                    result = 1;
                }
                
                if (m_barModelDiffersFromLastValidateAttempt || msSinceLastResultSent > m_rateLimitThresholdMs)
                {
                    m_msTimeStampSinceLastResult = getTimer();
                    
                    // Save this data so the equation can use this later
                    m_savedPreviousBarModelDatum = param.barModel;
                    
                    // Send the bar model snapshot to the copilot
                    problemText = getTextForCurrentPage();
                    var barModelResultData:Object = {barModel: param.barModel, problemText: problemText};
                    this.logCopilotProblemResult(result, barModelResultData);
                }
                
                // Assume submission of a correct bar model ends the problem phase
                if (isCorrect)
                {
                    // Increment the id to the next value if the 'bar model phase' is complete
                    m_currentProblemIdCounter++;
                }
                
                m_barModelDiffersFromLastValidateAttempt = false;
            }
            else if (eventType == AlgebraAdventureLoggingConstants.EXIT_BEFORE_COMPLETION ||
                eventType == AlgebraAdventureLoggingConstants.SKIP)
            {
                // Termination without solving the problem
                currentLevelData = m_base.gameEngine.getCurrentLevel();
                this.logCopilotProblemSetEnd(currentLevelData);
            }
        }
        
        private function getTextForCurrentPage():String
        {
            var currentText:String = "";
            m_textAreaOutBuffer.length = 0;
            m_base.gameEngine.getUiEntitiesByClass(TextAreaWidget, m_textAreaOutBuffer);
            if (m_textAreaOutBuffer.length > 0)
            {
                var targetTextArea:TextAreaWidget = m_textAreaOutBuffer[0] as TextAreaWidget;
                var currentPageInText:DocumentView = targetTextArea.getPageViews()[targetTextArea.getCurrentPageIndex()];
                if (currentPageInText != null)
                {
                    currentText = currentPageInText.node.getText();
                }
            }
            return currentText;
        }
        
        /**
         *
         * @param callback
         *      Signature callback(success:Boolean, data:Object):void
         *      success is whether the pause did something, data is extra params to the copilot
         */
        private function setPauseCallback(callback:Function, value:Boolean, details:Object):void
        {
            if (value)
            {
                if (!m_isCopilotPaused)
                {
                    // Log the pause, but only if logging is on AND we are in a level
                    
                    // Mark as paused
                    m_isCopilotPaused = true;
                }
            }
            else
            {
                if (m_isCopilotPaused)
                {
                    // Log the resume, but only if logging is on AND we are in a level
                    m_isCopilotPaused = false;
                }
            }
            
            if (callback != null)
            {
                callback(true, details);
            }
        }
        
        /**
         * Callback for copilot start command.
         * @param callback
         *      Signature callback(success:Boolean, data:Object):void
         *      success is whether the pause did something, data is extra params to the copilot
         */
        private function startCallback(callback:Function, activityDefinition:Object, details:Object):void
        {
            if (callback != null)
            {
                callback(true);
            }
            
            if (m_onCopilotActivityStartCallback != null)
            {
                m_onCopilotActivityStartCallback(activityDefinition, details);
            }
            else
            {
                // Default behavior is to immediately start a level
                var levelPack:String = activityDefinition.activityData;
                
                // Only do anything if no level is active or we have orders to interrupt
                if (!m_base.isLevelRunning() || details.interruptCurrentPlay)
                {
                    // Stop the current level, if any
                    m_base.stopCurrentLevel();
                    
                    // Replace the current level pack with the given one, if the new one exists.
                    if (m_levelManager.resourceManager.resourceExists(levelPack))
                    {
                        //m_levelManager.setToNewLevelProgression(levelPack);
                    }
                    
                    // Start
                    m_levelManager.goToNextLevel();
                }
            }
        }
        
        /**
         * Callback for copilot stop command.
         * @param callback
         *      Signature callback(success:Boolean, data:Object):void
         *      success is whether the pause did something, data is extra params to the copilot
         */
        private function stopCallback(callback:Function, details:Object):void
        {
            // Stop the level if we are in one
            if (m_base.isLevelRunning())
            {
                // Log the stop, but only if logging is on AND we are in a level
                
                // Stop current level
                m_base.stopCurrentLevel();
            }
            
            if (callback != null)
            {
                callback(true);
            }
        }
        
        /**
         *
         * @param callback
         *      Signature callback(success:Boolean, data:Object):void
         *      success is whether the pause did something, data is extra params to the copilot
         */
        private function addUserCallback(callback:Function, user:ICgsUser):void
        {
            if (callback != null)
            {
                callback(true);
            }
        }
        
        /**
         * @param callback
         *      Signature callback(success:Boolean, data:Object):void
         *      success is whether the pause did something, data is extra params to the copilot
         */
        private function removeUserCallback(callback:Function, user:ICgsUser):void
        {
            if (callback != null)
            {
                callback(true);
            }
        }
        
        /**
         *
         * @param callback
         *      Signature callback(success:Boolean, data:Object):void
         *      success is whether the pause did something, data is extra params to the copilot
         */
        private function commandToWidget(callback:Function, command:String, args:String):void
        {
            if (callback != null)
            {
                callback(true);
            }
        }
    }
}