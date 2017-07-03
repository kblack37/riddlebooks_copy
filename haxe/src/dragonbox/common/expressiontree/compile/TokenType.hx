package utils.expressiontree.compile;

/**
 * @author Roy
 */
enum TokenType 
{
	Number;
	Operator;
	Variable;
	/**
	 * This particular type is a bit bizarre, in the algebra scratchpad there were terms in
	 * an expression that were prefixed with a special character. These terms could be mapped
	 * to any variable or operator name. I believe they were used just to keep track of
	 * what terms a player had injected into an expression.
	 * 
	 * The primary benefits of this type of symbol is that its value should be interpreted by
	 * an application differently than it would a variable. The best example of its use is in the
	 * case of wild cards. A wildcard is a placeholder for a variable, constant, or subexpression.
	 * The dynamic token can contain inside of it some instructions of how to extract whatever
	 * value it is standing in place of.
	 */
	DynamicVariable;
	LeftParen;
	RightParen;
}