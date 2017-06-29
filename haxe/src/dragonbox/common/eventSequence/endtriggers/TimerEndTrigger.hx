package dragonbox.common.eventsequence.endtriggers;


import dragonbox.common.time.Time;

class TimerEndTrigger extends EndTrigger
{
    private var m_durationMs : Float;
    private var m_timeUntilCompleteMs : Float;
    
    public function new(timeMs : Float)
    {
        super();
        
        m_durationMs = timeMs;
        m_timeUntilCompleteMs = timeMs;
    }
    
    override public function update(time : Time) : Void
    {
        if (!m_isComplete) 
        {
            m_timeUntilCompleteMs -= time.frameDeltaMs();
            if (m_timeUntilCompleteMs < 0) 
            {
                m_isComplete = true;
            }
        }
    }
    
    override public function reset() : Void
    {
        super.reset();
        
        m_timeUntilCompleteMs = m_durationMs;
    }
}
