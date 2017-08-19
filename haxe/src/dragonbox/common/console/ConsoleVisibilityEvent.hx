package dragonbox.common.console;


import openfl.events.Event;

class ConsoleVisibilityEvent extends Event
{
    public static inline var EVENT_TYPE : String = "CONSOLE_VISIBLITY";
    
    public var visible : Bool;
    
    public function new(visible : Bool, type : String = EVENT_TYPE, bubbles : Bool = false, cancelable : Bool = false)
    {
        super(type, bubbles, cancelable);
        
        this.visible = visible;
    }
}
