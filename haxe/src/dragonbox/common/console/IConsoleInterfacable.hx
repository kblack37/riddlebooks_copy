package dragonbox.common.console;


import dragonbox.common.console.expression.MethodExpression;

interface IConsoleInterfacable
{

    function getObjectAlias() : String;
    function getSupportedMethods() : Array<String>;
    function getMethodDetails(methodName : String) : String;
    function invoke(methodExpression : MethodExpression) : Void;
}
