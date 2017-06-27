package dragonbox.common.eventSequence
{
	import dragonbox.common.time.Time;
	import dragonbox.common.eventSequence.endtriggers.EndTrigger;

    /**
     * Base class for logic that should be executed on each frame up until
     * and end condition trigger has been fired.
     * 
     * Most of the times you want to create an instance of a subclass, however
     * if you just want a timer delay, create a normal sequence event and add a timer
     * end trigger.
     */
	public class SequenceEvent
	{
		public static const INACTIVE:int = 0;
		public static const ACTIVE:int = 1;
		public static const COMPLETE:int = 2;
		
		protected var currentState:int;
        
        protected var endTrigger:EndTrigger;
		
		public function SequenceEvent(endTrigger:EndTrigger)
		{
			this.currentState = INACTIVE;
            this.endTrigger = endTrigger;
		}
		
		public function start():void
		{
			this.currentState = ACTIVE;	
		}
		
		public function update(time:Time):void
		{
			if(currentState == ACTIVE)
			{
				endTrigger.update(time);
				if(endTrigger.isComplete())
				{
					this.currentState = COMPLETE;
				}
			}
		}
		
		public function getCurrentState():int
		{
			return this.currentState;
		}
		
		public function end():void
		{
			this.currentState = COMPLETE;
		}
        
        public function reset():void
        {
            this.currentState = INACTIVE;
            if (this.endTrigger != null)
            {
                this.endTrigger.reset();
            }
        }
		
		public function dispose():void
		{
            if (this.endTrigger != null)
            {
                this.endTrigger.dispose();
            }
		}
	}
}