package dragonbox.common.eventSequence
{
	import dragonbox.common.time.Time;

	public class Sequence
	{		
		public static const INACTIVE:int = 0;
		public static const ACTIVE:int = 1;
		public static const COMPLETE:int = 2;
		
		private var currentState:int;
		private var events:Vector.<SequenceEvent>;
		private var currentEventIndex:int;
		
		public function Sequence(sequenceEvents:Vector.<SequenceEvent>)
		{
			this.currentState = INACTIVE;
			this.currentEventIndex = 0;
			this.events = sequenceEvents;
		}
		
		public function start():void
		{
			currentState = ACTIVE;
			events[currentEventIndex].start();
		}
		
		public function update(time:Time):void
		{
			if(currentState == ACTIVE)
			{
				events[currentEventIndex].update(time);
				while(currentState == ACTIVE && events[currentEventIndex].getCurrentState() == SequenceEvent.COMPLETE)
				{
					events[currentEventIndex].end();
					if(currentEventIndex + 1 < events.length)
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
		
		public function end():void
		{
			this.currentState = INACTIVE;
		}
        
        /**
         * This is useful if we want a looping sequence.
         */
        public function reset():void
        {
            this.currentState = ACTIVE;
            this.currentEventIndex = 0;
            for each (var event:SequenceEvent in events)
            {
                event.reset();
            }
        }
		
		public function getCurrentState():int
		{
			return currentState;
		}
		
		public function dispose():void
		{
			for each(var seqEvent:SequenceEvent in events)
			{
				seqEvent.dispose();
			}
			events = null;
		}
	}
}