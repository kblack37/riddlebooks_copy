package wordproblem.level.conditions
{
    import dragonbox.common.dispose.IDisposable;
    
    /**
     * If you think of the level progression as a finite state machine,
     * conditions are like the inputs in the transitions.
     * 
     * The transitions are not taken unless the set of conditions attached to
     * it have all passed.
     */
    public interface ICondition extends IDisposable
    {
        /**
         *
         * @return
         *      true if this condition has satisfied its constraints
         */
        function getSatisfied():Boolean;
        
        /**
         * @return
         *      name of the type of condition
         */
        function getType():String;
        
        /**
         * Normally we expect conditions to encoded in the level progression json.
         * This function is used to parse out the parameter values in a condition
         * 
         * @param data
         *      json formatted data object for a condition
         */
        function deserialize(data:Object):void;
        
        /**
         * For saving additional progress data
         * 
         * @return
         *      Data block with all important state stored inside.
         *      Null if this condition does not require separate save info
         */
        function serialize():Object;
        
        /**
         * Reset all state values to initial values. (Required to clear condition
         * history for one of the experiment progressions)
         */
        function clearState():void;
    }
}