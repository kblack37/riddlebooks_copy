package dragonbox.common.time;




class Time implements ITime
{
    public var lastTimeMilliseconds : Float;
    
    /** Get the current millisecond run since the flash player instance has started */
    public var currentTimeMilliseconds : Float;
    
    /** Get the amount of milliseconds that passed since the last update on this object */
    public var currentDeltaMilliseconds : Float;
    
    /** Get the amount of seconds elapsed since the last call to update */
    public var currentDeltaSeconds : Float;
    
    public function new()
    {
        this.reset();
    }
    
    public function update() : Void
    {
        // Use timer instead of constructing a new dateobject on every update tick
        this.currentTimeMilliseconds = Math.round(haxe.Timer.stamp() * 1000);
        
        this.currentDeltaMilliseconds = this.currentTimeMilliseconds - this.lastTimeMilliseconds;
        this.currentDeltaSeconds = this.currentDeltaMilliseconds * 0.001;
        this.lastTimeMilliseconds = this.currentTimeMilliseconds;
    }
    
    public function reset() : Void
    {
        this.currentTimeMilliseconds = Math.round(haxe.Timer.stamp() * 1000);
        this.lastTimeMilliseconds = this.currentTimeMilliseconds;
        this.currentDeltaMilliseconds = 0;
    }
    
    public function frameDeltaMs() : Float
    {
        return currentDeltaMilliseconds;
    }
    
    public function frameDeltaSecs() : Float
    {
        return currentDeltaSeconds;
    }
}
