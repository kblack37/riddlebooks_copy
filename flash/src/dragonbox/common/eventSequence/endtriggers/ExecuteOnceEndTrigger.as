package dragonbox.common.eventSequence.endtriggers
{
    import dragonbox.common.time.Time;

    public class ExecuteOnceEndTrigger extends EndTrigger
    {
        private var m_executedOnce:Boolean;
        
        public function ExecuteOnceEndTrigger()
        {
            super();
            
            m_executedOnce = false;
        }
        
        override public function update(time:Time):void
        {
            if (!m_isComplete)
            {
                if (!m_executedOnce)
                {
                    m_executedOnce = true;
                }
                else
                {
                    m_isComplete = true;
                }
            }
        }
        
        override public function reset():void
        {
            super.reset();
            m_executedOnce = false;
        }
    }
}