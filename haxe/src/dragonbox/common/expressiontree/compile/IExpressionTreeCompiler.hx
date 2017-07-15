package dragonbox.common.expressiontree.compile;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.math.vectorspace.RealsVectorSpace;

/**
 * @author Roy
 */
interface IExpressionTreeCompiler 
{
	public function getVectorSpace():RealsVectorSpace;
	
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
	public function setDynamicVariableInformation(dynamicVariableCharacters:Array<String>, nodeCreateCallback:RealsVectorSpace->String->ExpressionNode):Void;
	
	/**
	 * Convert some string representation of the tree into a tree data structure
	 * that the program can render and modify.
	 * 
	 * @param data
	 * 		String representation of the expression. Whitespace is ignored.
	 * @return
	 * 		The root of the expression tree
	 */
	public function compile(data:String):ExpressionNode;
	
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
	public function decompileAtNode(expressionTreeNode:ExpressionNode, expandUnits:Bool=true):String;
	
	/**
	 * @param data
	 * 		String value to check against
	 * @return
	 * 		True if the given data is an operator, false otherwise
	 */
	public function isOperator(data:String):Bool;
}