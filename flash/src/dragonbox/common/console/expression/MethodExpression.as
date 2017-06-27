package dragonbox.common.console.expression
{
	public class MethodExpression
	{
		public var statement:String;
		public var wellFormed:Boolean;
		
		public var startAliasIndex:int;
		public var objectAlias:String; 
		public var endAliasIndex:int;
		
		public var startMethodIndex:int;
		public var methodAlias:String;
		public var endMethodIndex:int;
		
		public var startArgumentIndices:Vector.<int>;
		public var arguments:Vector.<String>; 
		public var endArgumentIndices:Vector.<int>;
		
		public function MethodExpression(statement:String, wellFormed:Boolean,
										 startAliasIndex:int, objectAlias:String, endAliasIndex:int,
										 startMethodIndex:int, methodName:String, endMethodIndex:int,
										 startArgumentIndices:Vector.<int>, arguments:Vector.<String>, endArgumentIndices:Vector.<int>)
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
}