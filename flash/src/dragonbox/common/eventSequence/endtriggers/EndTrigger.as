package dragonbox.common.eventSequence.endtriggers
{
    import dragonbox.common.dispose.IDisposable;
    import dragonbox.common.time.Time;
    
    /**
     * A trigger simply sets itself as complete once a specific condition has
     * been. This could be that a certain amount of time has elapsed or a specific
     * event has been fired.
     */
    public class EndTrigger implements IDisposable
    {
        protected var m_isComplete:Boolean;
        
        public function EndTrigger()
        {
            m_isComplete = false;
        }
        
        /**
         * An periodic update on the trigger, useful for some timer based triggers.
         */
        public function update(time:Time):void
        {
        }
        
        /**
         * @return
         *      true if the trigger has successfully fired, false if not
         */
        public function isComplete():Boolean
        {
            return m_isComplete;
        }
        
        /**
         * Override to add additional properties that need to be set to initial values
         */
        public function reset():void
        {
            m_isComplete = false;
        }
        
        public function dispose():void
        {
        }
    }
}