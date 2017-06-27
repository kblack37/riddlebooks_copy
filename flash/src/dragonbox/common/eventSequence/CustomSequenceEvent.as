package dragonbox.common.eventSequence
{
    import dragonbox.common.time.Time;
    import dragonbox.common.eventSequence.endtriggers.EndTrigger;

    /**
     * Sequence event that executes an arbitrary function up until the end trigger
     * has been fired.
     */
    public class CustomSequenceEvent extends SequenceEvent
    {
        private var m_customExecuteFunction:Function;
        private var m_customExecuteParams:Array;
        
        public function CustomSequenceEvent(customExecuteFunction:Function,
                                            customExecuteParams:Array,
                                            endTrigger:EndTrigger)
        {
            super(endTrigger);
            
            m_customExecuteFunction = customExecuteFunction;
            m_customExecuteParams = customExecuteParams;
        }
        
        override public function update(time:Time):void
        {
            if(currentState == ACTIVE)
            {
                endTrigger.update(time);
                if(endTrigger.isComplete())
                {
                    this.currentState = COMPLETE;
                }
                else
                {
                    m_customExecuteFunction.apply(null, m_customExecuteParams);
                }
            }
        }
    }
}