package dragonbox.common.eventsequence;

import dragonbox.common.eventsequence.SequenceEvent;
import dragonbox.common.time.Time;
import dragonbox.common.eventsequence.endtriggers.EndTrigger;

import haxe.Constraints.Function;

/**
 * Sequence event that executes an arbitrary function up until the end trigger
 * has been fired.
 */
class CustomSequenceEvent extends SequenceEvent
{
    private var m_customExecuteFunction : Function;
    private var m_customExecuteParams : Array<Dynamic>;
    
    public function new(customExecuteFunction : Function,
            customExecuteParams : Array<Dynamic>,
            endTrigger : EndTrigger)
    {
        super(endTrigger);
        
        m_customExecuteFunction = customExecuteFunction;
        m_customExecuteParams = customExecuteParams;
    }
    
    override public function update(time : Time) : Void
    {
        if (currentState == SequenceEvent.ACTIVE) 
        {
            endTrigger.update(time);
            if (endTrigger.isComplete()) 
            {
                this.currentState = SequenceEvent.COMPLETE;
            }
            else 
            {
				m_customExecuteFunction(null, m_customExecuteParams);
            }
        }
    }
}
