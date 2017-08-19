package dragonbox.common.console.expression;

import dragonbox.common.console.expression.MethodExpression;

import openfl.events.Event;

class DynamicInvokeEvent extends Event
{
    public static inline var EVENT_TYPE : String = "DYNAMIC_INVOKE_EVENT";
    
    public var methodExpression : MethodExpression;
    
    public function new(methodExpression : MethodExpression, type : String = EVENT_TYPE, bubbles : Bool = false, cancelable : Bool = false)
    {
        super(type, bubbles, cancelable);
        
        this.methodExpression = methodExpression;
    }
}
