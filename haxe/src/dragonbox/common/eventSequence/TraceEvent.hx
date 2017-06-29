package dragonbox.common.eventsequence;


import dragonbox.common.time.Time;

/**
	 * an example class of how to extends SequenceEvent and create a new event
	 */
class TraceEvent extends SequenceEvent
{
    private var msg : String;
    
    public function new(msg : String, timeShowMS : Int)
    {
        super(timeShowMS);
        this.msg = msg;
    }
    
    override public function start() : Void
    {
        super.start();
        trace(msg);
    }
    
    override public function update(time : Time) : Void
    {
        if (currentState == ACTIVE) 
        {
            timeShowMS -= time.frameDeltaMs();
            if (timeShowMS < 0) 
            {
                this.currentState = COMPLETE;
            }
        }
    }
    
    override public function end() : Void
    {
        super.end();
        trace(msg + " DONE");
    }
}
