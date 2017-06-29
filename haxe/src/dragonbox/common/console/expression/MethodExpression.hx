package dragonbox.common.console.expression;


class MethodExpression
{
    public var statement : String;
    public var wellFormed : Bool;
    
    public var startAliasIndex : Int;
    public var objectAlias : String;
    public var endAliasIndex : Int;
    
    public var startMethodIndex : Int;
    public var methodAlias : String;
    public var endMethodIndex : Int;
    
    public var startArgumentIndices : Array<Int>;
    public var arguments : Array<String>;
    public var endArgumentIndices : Array<Int>;
    
    public function new(statement : String, wellFormed : Bool,
            startAliasIndex : Int, objectAlias : String, endAliasIndex : Int,
            startMethodIndex : Int, methodName : String, endMethodIndex : Int,
            startArgumentIndices : Array<Int>, arguments : Array<String>, endArgumentIndices : Array<Int>)
    {
        this.statement = statement;
        this.wellFormed = wellFormed;
        
        this.startAliasIndex = startAliasIndex;
        this.objectAlias = objectAlias;
        this.endAliasIndex = endAliasIndex;
        
        this.startMethodIndex = startMethodIndex;
        this.methodAlias = methodName;
        this.endMethodIndex = endMethodIndex;
        
        this.startArgumentIndices = startArgumentIndices;
        this.arguments = arguments;
        this.endArgumentIndices = endArgumentIndices;
    }
}
