package dragonbox.common.eventSequence
{
	import dragonbox.common.time.Time;
	
	/**
	 * an example class of how to extends SequenceEvent and create a new event
	 */
	public class TraceEvent extends SequenceEvent
	{
		private var msg:String;
		
		public function TraceEvent(msg:String, timeShowMS:int)
		{
			super(timeShowMS);
			this.msg = msg;
		}
		
		public override function start():void
		{
			super.start();
			trace(msg);
		}
		
		public override function update(time:Time):void
		{
			if(currentState == ACTIVE)
			{
				timeShowMS -= time.frameDeltaMs();
				if(timeShowMS < 0)
				{
					this.currentState = COMPLETE;
				}
			}
		}
		
		public override function end():void
		{
			super.end();
			trace(msg + " DONE");
		}
		
	}
}