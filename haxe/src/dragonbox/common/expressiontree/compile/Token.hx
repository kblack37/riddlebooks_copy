package utils.expressiontree.compile;

/**
 * ...
 * @author Roy
 */
class Token 
{
	/* All categories of tokens detected by the scanner 
		
	public static var NUMBER:Int = 1;
	public static var OPERATOR:Int = 2;
	public static var VARIABLE:Int = 3;
	
	public static var DYNAMIC:Int = 4;
	public static var LEFT_PAREN:Int = 5;
	public static var RIGHT_PAREN:Int = 6;*/
	
	/**
	 * The category group for this token.
	 */
	public var type:TokenType;
	
	/**
	 * The actual data represented by the token
	 */
	public var symbol:String;
	
	/**
	 * Whether or not this token was supposed to be wrapped in parentheses.
	 * Refers to the highest precedence token within a subtree.
	 */
	public var wrappedInParentheses:Bool;
	
	public function new(type:TokenType, symbol:String)
	{
		this.type = type;
		this.symbol = symbol;
		this.wrappedInParentheses = false;
	}
	
	public function isNumericOrVariable():Bool
	{
		return this.type == TokenType.Number || this.type == TokenType.Variable || this.type == TokenType.DynamicVariable;
	}
}