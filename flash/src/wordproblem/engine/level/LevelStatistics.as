package wordproblem.engine.level
{
    /**
     * This is a data cluster of all common statistics and performance calculation that are related to a level.
     * This class is a bit of a hacky blob now as it acts more like a shared blackboard class where scripts
     * write information that other scripts access.
     * 
     * This type of data sharing requires that the ordering in which scripts read and write data is well defined.
     * Scripts that read data need to be sure that it has recieved relevant updates first.
     * For example: The value of masteryAchieved is only useful after some logic has done the performance
     * calculation after the level is completed. Thus scripts using that value can only do so after
     * the calculation is finished.
     * One way to guarantee this is to orders the script such that they buffer events and process them
     * on the same frame. I.e. Suppose the logic setting mastery does so on the end_level event and the logic reading
     * mastery does so on that same event. As long as the setting script occurs earlier in the list then
     * the read will get the correct value.
     */
    public class LevelStatistics
    {
        /**
         * How the player finished the level. Did they finish the level?
         * 
         * There should be just one point in the application that writes to this value
         * while several other scripts would read it.
         * 
         * Look at the LevelEndTypes.as file for possible values
         */
        public var endType:String;
        
        /**
         * The number of times the player attempted to model an equation that did not match an
         * expected target.
         */
        public var equationModelFails:int;
        
        /**
         * The number of times the player attempted to submit a bar model solution that did not
         * match an expected target.
         */
        public var barModelFails:int;
        
        /**
         * The number of new hints the player explicitly asks for.
         * Different from tutorial hints that normally automatically appear
         */
        public var additionalHintsUsed:int;
        
        /**
         * A level might have a hint that shows the exact bar model answer.
         * 
         * If we detect that those hints are used, we may want to mark the level as being failed
         * or not count it in the total number of equations used.
         */
        public var usedBarModelCheatHint:Boolean;
        
        /**
         * A level might have a hint that shows the exact equation model answer
         */
        public var usedEquationModelCheatHint:Boolean;
        
        /**
         * The total continuous number of milliseconds the player spent in the levels.
         * 
         * Count should be from the time the player first enters the level to the time they
         * have solved it.
         */
        public var totalMillisecondsPlayed:Number;

        /**
         * A normalized value between 0 and 100 indicating how well a player performed completing
         * all the objective that are visible in the summary screen.
         * 
         * This is something like a high score and should be calculated and set at the end of a level.
         */
        public var gradeFromSummaryObjectives:int;
        
        /**
         * Hack to keep track of the previous completion status of a level during a prior playthrough
         */
        public var previousCompletionStatus:int = 0;
        
        /**
         * This is the amount of xp that was earned since the start of the level.
         * This needs to be reset to zero.
         * 
         * The summary screen needs to know about xp earned since the start of the level because 
         * we need to show an animation.
         */
        public var xpEarnedForLevel:uint;
        
        /**
         * The completion of a level will sometimes require sending a concept 'mastery' message.
         * This is only for the completion of levels where some other decision logic has determined
         * mastery associated with a topic is achieved.
         * 
         * On solve that logic writes to this field and for the short amount of time after solve, this
         * has a valid value.
         * 
         * If -1 then no mastery was set, and this value is useless.
         */
        public var masteryIdAchieved:int;
        
        /**
         * In the level progression system, the user may navigate through the level graph
         * via explicitly defined edges.
         * 
         * When a level ends it might be useful to record thatan edge was taken.
         * 
         * If null then no explicit edge is taken.
         */
        public var levelGraphEdgeIdTaken:String;
        
        public function LevelStatistics()
        {
            this.endType = null;
            this.equationModelFails = 0;
            this.barModelFails = 0;
            this.totalMillisecondsPlayed = 0.0;
            this.gradeFromSummaryObjectives = 0;
            this.xpEarnedForLevel = 0;
            this.additionalHintsUsed = 0;
            this.usedBarModelCheatHint = false;
            this.usedEquationModelCheatHint = false;
            this.masteryIdAchieved = -1;
            this.levelGraphEdgeIdTaken = null;
        }
        
        /**
         * In some cases, a node in the progression may want to keep track of metrics from previous
         * instances played of that node. The node would pass along that data here so we can
         * pre-populate this object with initial values for mastery purposes
         */
        public function deserialize(data:Object):void
        {
            if (data != null)
            {
                if (data.hasOwnProperty("barModelFails"))
                {
                    this.barModelFails = data["barModelFails"];
                }
                
                if (data.hasOwnProperty("equationModelFails"))
                {
                    this.equationModelFails = data["equationModelFails"];
                }
                
                if (data.hasOwnProperty("hintsRequested"))
                {
                    this.additionalHintsUsed = data["hintsRequested"];
                }
            }
        }
        
        public function serialize():Object
        {
            var data:Object = {
                barModelFails: this.barModelFails,
                equationModelFails: this.equationModelFails,
                hintsRequested: this.additionalHintsUsed
            };
            return data;
        }
    }
}