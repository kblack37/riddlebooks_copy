package dragonbox.common.eventSequence.endtriggers
{
    import dragonbox.common.time.Time;
    
    public class TimerEndTrigger extends EndTrigger
    {
        private var m_durationMs:Number;
        private var m_timeUntilCompleteMs:Number;
        
        public function TimerEndTrigger(timeMs:Number)
        {
            super();
            
            m_durationMs = timeMs;
            m_timeUntilCompleteMs = timeMs;
        }
        
        override public function update(time:Time):void
        {
            if (!m_isComplete)
            {
                m_timeUntilCompleteMs -= time.frameDeltaMs();
                if(m_timeUntilCompleteMs < 0)
                {
                    m_isComplete = true;
                }
            }
        }
        
        override public function reset():void
        {
            super.reset();
            
            m_timeUntilCompleteMs = m_durationMs;
        }
    }
}