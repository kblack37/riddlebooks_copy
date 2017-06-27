package dragonbox.common.eventSequence
{
	import dragonbox.common.dispose.IDisposable;
	import dragonbox.common.time.Time;

	public class EventSequencer implements IDisposable
	{	
		public static const INACTIVE:int = 0;
		public static const ACTIVE:int = 1;
		public static const COMPLETE:int = 2;
		
		private var sequences:Vector.<Sequence>;
		private var playing:Boolean;
		private var currentState:int;
		
		public function EventSequencer(sequences:Vector.<Sequence>)
		{
			this.currentState = INACTIVE;
			this.sequences = sequences;
			this.playing = false;
		}
		
		public function start():void
		{
			this.currentState = ACTIVE;
			for each(var seq:Sequence in sequences)
			{
				seq.start();
			}
		}
		
		public function update(time:Time):void
		{
			if(this.currentState == ACTIVE)
			{
				var numCompleteSequence:int = 0;
				for each(var seq:Sequence in sequences)
				{
					seq.update(time);
					if(seq.getCurrentState() == Sequence.COMPLETE)
					{
						numCompleteSequence++;
						seq.end();
					}
				}
				if(numCompleteSequence == sequences.length)
				{
					this.currentState = COMPLETE;
				}
			}
		}
		
		public function getCurrentState():int
		{
			return currentState;
		}
		
		public function dispose():void
		{
			for each(var seq:Sequence in this.sequences)
			{
				seq.dispose();
			}
			sequences = null;
		}
	}
}