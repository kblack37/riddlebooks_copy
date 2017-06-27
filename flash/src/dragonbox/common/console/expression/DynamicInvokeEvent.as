package dragonbox.common.console.expression
{
	import flash.events.Event;
	
	public class DynamicInvokeEvent extends Event
	{
		public static const EVENT_TYPE:String = "DYNAMIC_INVOKE_EVENT";
		
		public var methodExpression:MethodExpression;
		
		public function DynamicInvokeEvent(methodExpression:MethodExpression, type:String=EVENT_TYPE, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.methodExpression = methodExpression;
		}
	}
}