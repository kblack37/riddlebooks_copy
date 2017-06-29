package dragonbox.common.eventsequence;

import dragonbox.common.eventsequence.SequenceEvent;

import dragonbox.common.time.Time;

class Sequence
{
    public static inline var INACTIVE : Int = 0;
    public static inline var ACTIVE : Int = 1;
    public static inline var COMPLETE : Int = 2;
    
    private var currentState : Int;
    private var events : Array<SequenceEvent>;
    private var currentEventIndex : Int;
    
    public function new(sequenceEvents : Array<SequenceEvent>)
    {
        this.currentState = INACTIVE;
        this.currentEventIndex = 0;
        this.events = sequenceEvents;
    }
    
    public function start() : Void
    {
        currentState = ACTIVE;
        events[currentEventIndex].start();
    }
    
    public function update(time : Time) : Void
    {
        if (currentState == ACTIVE) 
        {
            events[currentEventIndex].update(time);
            while (currentState == ACTIVE && events[currentEventIndex].getCurrentState() == SequenceEvent.COMPLETE)
            {
                events[currentEventIndex].end();
                if (currentEventIndex + 1 < events.length) 
                {
                    events[++currentEventIndex].start();
                }
                else 
                {
                    currentState = COMPLETE;
                }
            }
        }
    }
    
    public function end() : Void
    {
        this.currentState = INACTIVE;
    }
    
    /**
     * This is useful if we want a looping sequence.
     */
    public function reset() : Void
    {
        this.currentState = ACTIVE;
        this.currentEventIndex = 0;
        for (event in events)
        {
            event.reset();
        }
    }
    
    public function getCurrentState() : Int
    {
        return currentState;
    }
    
    public function dispose() : Void
    {
        for (seqEvent in events)
        {
            seqEvent.dispose();
        }
        events = null;
    }
}
