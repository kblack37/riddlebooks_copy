package dragonbox.common.eventsequence;

import dragonbox.common.eventsequence.Sequence;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.time.Time;

class EventSequencer implements IDisposable
{
    public static inline var INACTIVE : Int = 0;
    public static inline var ACTIVE : Int = 1;
    public static inline var COMPLETE : Int = 2;
    
    private var sequences : Array<Sequence>;
    private var playing : Bool;
    private var currentState : Int;
    
    public function new(sequences : Array<Sequence>)
    {
        this.currentState = INACTIVE;
        this.sequences = sequences;
        this.playing = false;
    }
    
    public function start() : Void
    {
        this.currentState = ACTIVE;
        for (seq in sequences)
        {
            seq.start();
        }
    }
    
    public function update(time : Time) : Void
    {
        if (this.currentState == ACTIVE) 
        {
            var numCompleteSequence : Int = 0;
            for (seq in sequences)
            {
                seq.update(time);
                if (seq.getCurrentState() == Sequence.COMPLETE) 
                {
                    numCompleteSequence++;
                    seq.end();
                }
            }
            if (numCompleteSequence == sequences.length) 
            {
                this.currentState = COMPLETE;
            }
        }
    }
    
    public function getCurrentState() : Int
    {
        return currentState;
    }
    
    public function dispose() : Void
    {
        for (seq/* AS3HX WARNING could not determine type for var: seq exp: EField(EIdent(this),sequences) type: null */ in this.sequences)
        {
            seq.dispose();
        }
        sequences = null;
    }
}
