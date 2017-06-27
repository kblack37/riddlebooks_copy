package dragonbox.common.time
{
    import flash.utils.getTimer;

	public class Time implements ITime
	{
		public var lastTimeMilliseconds:Number;
        
        /** Get the current millisecond run since the flash player instance has started */
		public var currentTimeMilliseconds:Number;
        
        /** Get the amount of milliseconds that passed since the last update on this object */
		public var currentDeltaMilliseconds:Number;
        
        /** Get the amount of seconds elapsed since the last call to update */
        public var currentDeltaSeconds:Number;
		
		public function Time()
		{
			this.reset();
		}
		
		public function update():void
		{
            // Use timer instead of constructing a new dateobject on every update tick
			this.currentTimeMilliseconds = getTimer();
            
			this.currentDeltaMilliseconds = this.currentTimeMilliseconds - this.lastTimeMilliseconds;
            this.currentDeltaSeconds = this.currentDeltaMilliseconds * 0.001;
			this.lastTimeMilliseconds = this.currentTimeMilliseconds;
		}
        
        public function reset():void
        {
            this.currentTimeMilliseconds = getTimer();
            this.lastTimeMilliseconds = this.currentTimeMilliseconds;
            this.currentDeltaMilliseconds = 0;
        }
        
        public function frameDeltaMs():Number
        {
            return currentDeltaMilliseconds;
        }
        
        public function frameDeltaSecs():Number
        {
            return currentDeltaSeconds;
        }
	}
}