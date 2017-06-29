package dragonbox.common.eventsequence.endtriggers;


import dragonbox.common.time.Time;

class ExecuteOnceEndTrigger extends EndTrigger
{
    private var m_executedOnce : Bool;
    
    public function new()
    {
        super();
        
        m_executedOnce = false;
    }
    
    override public function update(time : Time) : Void
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
    
    override public function reset() : Void
    {
        super.reset();
        m_executedOnce = false;
    }
}
