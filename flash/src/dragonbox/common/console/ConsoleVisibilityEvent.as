package dragonbox.common.console
{
	import flash.events.Event;
	
	public class ConsoleVisibilityEvent extends Event
	{
		public static const EVENT_TYPE:String = "CONSOLE_VISIBLITY";
		
		public var visible:Boolean;
		
		public function ConsoleVisibilityEvent(visible:Boolean, type:String=EVENT_TYPE, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.visible = visible;
		}
	}
}