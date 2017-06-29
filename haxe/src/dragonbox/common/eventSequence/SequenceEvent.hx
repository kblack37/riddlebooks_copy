package dragonbox.common.eventsequence;


import dragonbox.common.time.Time;
import dragonbox.common.eventsequence.endtriggers.EndTrigger;

/**
 * Base class for logic that should be executed on each frame up until
 * and end condition trigger has been fired.
 * 
 * Most of the times you want to create an instance of a subclass, however
 * if you just want a timer delay, create a normal sequence event and add a timer
 * end trigger.
 */
class SequenceEvent
{
    public static inline var INACTIVE : Int = 0;
    public static inline var ACTIVE : Int = 1;
    public static inline var COMPLETE : Int = 2;
    
    private var currentState : Int;
    
    private var endTrigger : EndTrigger;
    
    public function new(endTrigger : EndTrigger)
    {
        this.currentState = INACTIVE;
        this.endTrigger = endTrigger;
    }
    
    public function start() : Void
    {
        this.currentState = ACTIVE;
    }
    
    public function update(time : Time) : Void
    {
        if (currentState == ACTIVE) 
        {
            endTrigger.update(time);
            if (endTrigger.isComplete()) 
            {
                this.currentState = COMPLETE;
            }
        }
    }
    
    public function getCurrentState() : Int
    {
        return this.currentState;
    }
    
    public function end() : Void
    {
        this.currentState = COMPLETE;
    }
    
    public function reset() : Void
    {
        this.currentState = INACTIVE;
        if (this.endTrigger != null) 
        {
            this.endTrigger.reset();
        }
    }
    
    public function dispose() : Void
    {
        if (this.endTrigger != null) 
        {
            this.endTrigger.dispose();
        }
    }
}
