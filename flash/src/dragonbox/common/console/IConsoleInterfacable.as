package dragonbox.common.console
{
	import dragonbox.common.console.expression.MethodExpression;

	public interface IConsoleInterfacable
	{
		function getObjectAlias():String;
		function getSupportedMethods():Vector.<String>;
		function getMethodDetails(methodName:String):String;
		function invoke(methodExpression:MethodExpression):void;
	}
}