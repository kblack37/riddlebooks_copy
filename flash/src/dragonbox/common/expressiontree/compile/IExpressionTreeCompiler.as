package dragonbox.common.expressiontree.compile
{
	import dragonbox.common.math.vectorspace.IVectorSpace;
	import dragonbox.common.expressiontree.ExpressionNode;

	/**
	 * The compiler can convert back and forth between some string format of an expression
	 * and the actual data structure representing the tree for an expression.
     * 
     * Some important notes:
     * All variable values are composed entirely of alpha-numeric characters or underscores and must start with an alphabetic letter
     * There are special prefix characters that can be used to further distinguish a particular term from other variables.
     * Past this prefix it contains letters, numbers, and underscores.
     * Dynamic variables cannot be marked as negative however (prefixed with a '-'), since their values are ill-defined 
     * it does not make sense for them to be marked as positive and negative.
	 */
	public interface IExpressionTreeCompiler
	{
		function getVectorSpace():IVectorSpace;
		
        /**
         * Set up initial properties for the parsing and creation of dynamic variable nodes.
         * A dynamic variable is just a token that signals a term is really a place holder for
         * another value. The example most used in app is ? to represent a wildcard.
         * 
         * @param dynamicVariableCharacters
         *      Special prefix characters that are placed in front of a term to indicate that
         *      it is a dynamic variable, (i.e. its true value can be bound later on). Cannot be
         *      an alpha-numeric character or an underscore. Multiple values can be passed if we
         *      want to allow for several different prefix characters
         * @param nodeCreateCallback
         *      A function callback used to create dynamic variable nodes if their data needs to be parsed
         *      differently than other types of nodes
         *      function f(vectorSpace:IVectorSpace, data:String):ExpressionNode
         */
        function setDynamicVariableInformation(dynamicVariableCharacters:Vector.<String>, nodeCreateCallback:Function):void;
        
		/**
		 * Convert some string representation of the tree into a tree data structure
		 * that the program can render and modify.
		 * 
		 * @param data
		 * 		String representation of the expression. Whitespace is ignored.
		 */
		function compile(data:String):ExpressionTreeCompilerResults;
		
		/**
		 * Convert the tree data structure into a string representation of the expression for
		 * easier serialization or storage. String will be rooted at the given node
		 * 
		 * @param expressionTreeNode
         *      Root of the tree
         * @param expandUnits
         *      If true, any node containing a non-null unit value will be expanded out into the
         *      form (data * unit_value).
		 * @return
		 * 		String representation of the tree rooted at the given node
		 */
		function decompileAtNode(expressionTreeNode:ExpressionNode, expandUnits:Boolean=true):String;
		
		/**
		 * @param data
		 * 		String value to check against
		 * @return
		 * 		True if the given data is an operator, false otherwise
		 */
		function isOperator(data:String):Boolean;
	}
}