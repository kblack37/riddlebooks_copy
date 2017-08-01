package dragonbox.common.expressiontree.compile;
import haxe.ds.GenericStack;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.math.vectorspace.RealsVectorSpace;

/**
 * ...
 * @author Roy
 */
class LatexCompiler implements IExpressionTreeCompiler 
{
	private var m_vectorSpace:RealsVectorSpace;
	private var m_dynamicVariableCharacters:Array<String>;
    private var m_dynamicVariableCallback:RealsVectorSpace->String->ExpressionNode;
	
	public function new(vectorSpace:RealsVectorSpace) 
	{
		m_vectorSpace = vectorSpace;
		m_dynamicVariableCharacters = new Array<String>();
	}
	
	
	/* INTERFACE utils.expressiontree.compile.IExpressionTreeCompiler */
	
	public function getVectorSpace():RealsVectorSpace 
	{
		return m_vectorSpace;
	}
	
	public function setDynamicVariableInformation(dynamicVariableCharacters:Array<String>, nodeCreateCallback:RealsVectorSpace->String->ExpressionNode):Void 
	{
		m_dynamicVariableCharacters = dynamicVariableCharacters;
		m_dynamicVariableCallback = nodeCreateCallback;
	}
	
	public function compile(data:String):ExpressionNode 
	{
		if (data.indexOf("[") >= 0)
		{
			this.stripHeaderFooter(data);
		}
		var tokens:Array<Token> = runTokenizer(data);
			
		// Once we have the tokenized string, we will run the Shunting-yard algorithm
		// to transform it to Reverse-polish-notation. This will make it much easier
		// to construct the proper expression tree from it
		var rpnFormattedTokens:Array<Token> = runShuntingYardAlgorithm(tokens);
		var rootNode:ExpressionNode = runRpn(rpnFormattedTokens);
		
		if (rootNode != null)
		{
			// Try to push the division nodes upward
			ExpressionUtil.pushDivisionNodesUpward(rootNode, m_vectorSpace);
			
			// Trace up the root node, the reason is that pushing up division nodes causes the pointer
			// at the root to no longer point to the topmost root
			while (rootNode.parent != null)
			{
				rootNode = rootNode.parent;
			}
		}
		
		return rootNode;
	}
	
	public function decompileAtNode(expressionTreeNode:ExpressionNode, expandUnits:Bool = true):String 
	{
		// Decompiling the expression is simply a matter of doing an in-order traversal of the tree
		// Must also manually append parentheses if precedence rules force it
		var decompiledExpression:String = "";
		if (expressionTreeNode != null)
		{
			decompiledExpression = ExpressionUtil.print(expressionTreeNode, m_vectorSpace);
		}
		
		return decompiledExpression;
	}
	
	public function isOperator(data:String):Bool 
	{
		return m_vectorSpace.getContainsOperator(data);
	}
	
	private function stripHeaderFooter(latex:String):String
	{
		var headerStrip:String = latex.split("\\[")[1];
		var footerStrip:String = headerStrip.split("\\]")[0];
		
		return footerStrip;
	}
	
	/**
	 * The first step of the compilation process is to break the expression string
	 * down into a list of atomic segments. These will be the terms in our
	 * expression.
	 */
	private function runTokenizer(expression:String):Array<Token>
	{
		// Kill whitespace
		StringTools.replace(expression, " ", "");
		
		var numericRegex:EReg = ~/([0-9])/;
		var alphabetUnderscoreRegex:EReg = ~/([a-zA-Z_])/;
		
		// Need to first tokenize the expression string
		// A token can be a signed numeric value, a symbol, a variable,
		// a function or an operator
		// Go through each symbol one at a time and see if the current one
		// by itself or in conjunction with prior symbols forms a terminal
		// that we treat as one token.
		var tokens:Array<Token> = new Array<Token>();
		var currentToken:Token = null;
		var buildingNumber:Bool = false;
		var buildingVariable:Bool = false;
		var buildingDynamic:Bool = false;
		var makeNextValueNegative:Bool = false;
		for (i in 0...expression.length)
		{
			var nextSymbol:String = expression.charAt(i);
			if (makeNextValueNegative)
			{
				nextSymbol = "-" + nextSymbol;
				makeNextValueNegative = false;
			}
			
			// Find a 0-9
			if (numericRegex.match(nextSymbol))
			{
				// If not building anything, then we start a new number
				if (!buildingNumber && !buildingVariable && !buildingDynamic)
				{
					currentToken = new Token(TokenType.Number, nextSymbol);
					buildingNumber = true;
				}
				else if (buildingNumber || buildingDynamic || buildingVariable)
				{
					currentToken.symbol += nextSymbol;
				}
			}
			// Letters or dynamic variable
			else if (alphabetUnderscoreRegex.match(nextSymbol))
			{
				// If not building anything, then we start a new alphabetic symbol
				if (!buildingNumber && !buildingVariable && !buildingDynamic)
				{
					currentToken = new Token(TokenType.Variable, nextSymbol);
					buildingVariable = true;
				}
				else if (buildingVariable || buildingDynamic)
				{
					currentToken.symbol += nextSymbol;
				}
				// Appending a letter to a token that started with a number coverts it to a variable
				else if (buildingNumber)
				{
					currentToken.type = TokenType.Variable;
					currentToken.symbol += nextSymbol;
				}
			}
			else if (m_dynamicVariableCharacters.indexOf(nextSymbol) != -1)
			{
				// If not building anything, then we start a new dynamic variable
				if (!buildingNumber && !buildingVariable && !buildingDynamic)
				{
					currentToken = new Token(TokenType.DynamicVariable, nextSymbol);
					buildingDynamic = true;
				}
			}
			// The dot in most cases will indicate that a decimal number was found
			else if (nextSymbol == ".")
			{
				// If not building anything then start a new number
				if (!buildingNumber && !buildingVariable && !buildingDynamic)
				{
					currentToken = new Token(TokenType.Number, nextSymbol);
					buildingNumber = true;
				}
				else if (buildingNumber)
				{
					currentToken.symbol += nextSymbol;
				}
			}
			else
			{
				buildingDynamic = false;
				buildingNumber = false;
				buildingVariable = false;
				
				// At this point the current symbol cannot be part of a larger
				// token, the previous token we built up has terminated so we
				// can add it to the list
				if (currentToken != null)
				{
					tokens.push(currentToken);
					currentToken = null;
				}
				
				// If we come across a '-' it is either a negative modifier for a
				// value or the subtraction operator. The simplest way to determine
				// this is if the preceding token is an operator or left paren or blank then the minus is
				// a negative
				if (nextSymbol == "-")
				{
					var isOperator:Bool = true;
					if (tokens.length > 0)
					{
						var lastToken:Token = tokens[tokens.length - 1];
						if (lastToken.type == TokenType.Operator || lastToken.type == TokenType.LeftParen)
						{
							isOperator = false;
						}
					}
					else
					{
						isOperator = false;
					}
					
					if (isOperator)
					{
						tokens.push(new Token(TokenType.Operator, nextSymbol));
					}
					else
					{
						// Mark that we need to prepend a negative sign to the
						// next numeric/variable token
						makeNextValueNegative = true;
					}
				}
				else if (nextSymbol == "(")
				{
					tokens.push(new Token(TokenType.LeftParen, nextSymbol));
				}
				else if (nextSymbol == ")")
				{
					tokens.push(new Token(TokenType.RightParen, nextSymbol));
				}
				// If a symbol is an operator, push the token immediately
				// WARNING: we are assuming the contents of the vector space
				// will exactly match those in the expression string.
				// We also assume the operators are just a single token long
				else if (m_vectorSpace.getContainsOperator(nextSymbol))
				{
					tokens.push(new Token(TokenType.Operator, nextSymbol));
				}
			}
		}
		
		// Add the last token
		if (currentToken != null)
		{
			tokens.push(currentToken);
		}
		
		return tokens;
	}
	
	/**
	 * The second step of compilation is to re-format the token ordering so
	 * it becomes easier to build up a tree with the correct precedence
	 * ordering.
	 */
	private function runShuntingYardAlgorithm(tokens:Array<Token>):Array<Token>
	{
		var stack:GenericStack<Token> = new GenericStack<Token>();
		var outPutQueue:Array<Token> = new Array<Token>();
		
		// While there are tokens to be read
		var currentToken:Token;
		for (i in 0...tokens.length)
		{
			// Read the token
			currentToken = tokens[i];
			
			if (currentToken.isNumericOrVariable())
			{
				// If token is a number or variable then add it to the output
				outPutQueue.push(currentToken);
			}
			else if (currentToken.type == TokenType.LeftParen)
			{
				// If token is left parenthesis, push it to the stack
				stack.add(currentToken);
			}
			else if (currentToken.type == TokenType.Operator)
			{
				// If the token is an operator o1
				// While there is another operator o2 token on the stack AND
				// either o1 is left-associative AND its precedence is less
				// or equal to o2 OR
				// o1 has precedence strictly less than o2
				// we pop o2 off the stack and put it into the queue
				if (!stack.isEmpty())
				{
					var opOneIsLeftAssociative:Bool = m_vectorSpace.getOperatorIsLeftAssociative(currentToken.symbol);
					var opOnePrecedence:Int = m_vectorSpace.getOperatorPrecedence(currentToken.symbol);
					var doCheckStack:Bool = true;
					while (doCheckStack)
					{
						var topToken:Token = stack.first();
						var opTwoPrecedence:Int = m_vectorSpace.getOperatorPrecedence(topToken.symbol);
						if (topToken.type == TokenType.Operator && 
							(opOneIsLeftAssociative && opOnePrecedence <= opTwoPrecedence || 
								opOnePrecedence < opTwoPrecedence))
						{
							// Add the topToken
							outPutQueue.push(stack.pop());
							if (stack.isEmpty())
							{
								doCheckStack = false;
							}
						}
						else
						{
							doCheckStack = false;
						}
					}
				}
				
				// At the end push o1 onto the stack
				stack.add(currentToken);
			}
			// If the token is a right paren
			else if (currentToken.type == TokenType.RightParen)
			{
				
				var foundLeftParen:Bool = false;
				while (!foundLeftParen && !stack.isEmpty())
				{
					// Until a token at the top of the stack is a left paren,
					// pop operators from the stack and into the output
					// Also pop the left paren and discard it
					var top:Token = stack.pop();
					if (top.type == TokenType.LeftParen)
					{
						foundLeftParen = true;
					}
					else
					{
						outPutQueue.push(top);
					}
				}
				
				// Mark the token at the end of the output queue as being wrapped in a parenthesis
				outPutQueue[outPutQueue.length - 1].wrappedInParentheses = true;

				// If the token at the top is a function token then pop
				// and push to the output, not relevant in our case
				if (!stack.isEmpty())
				{
				}
				
				// If stack is empty without finding a left paren
				// we have a paren error
				if (!foundLeftParen)
				{
					throw "Paren malformed";
				}
			}
		}
		
		// After the first pass we look at the tokens in the stack
		// If the token at the top is a paren, we have a mismatched parenthesis
		// eror.
		// Otherwise push the operator onto the queue
		while (!stack.isEmpty())
		{
			var remainingToken:Token = stack.pop();
			if (remainingToken.type != TokenType.LeftParen &&
				remainingToken.type != TokenType.RightParen)
			{
				outPutQueue.push(remainingToken);
			}
			else
			{
				// Paren error
				throw "Paren malformed";
			}
		}
		
		return outPutQueue;
	}
	
	/**
	 * The final step in the compilation process.
	 * From a set of tokens formatted in Reverse-polish-notation we can
	 * easily either evaluate the expression or build the expression tre
	 * structure.
	 */
	private function runRpn(tokens:Array<Token>):ExpressionNode
	{
		var root:ExpressionNode = null;
		var nodeStack:GenericStack<ExpressionNode> = new GenericStack<ExpressionNode>();
		for (token in tokens)
		{
			// If the token is a dynamic variable and a dynamic variable callback has been
			// specified then use that callback, otherwise create a default expression node
			var node:ExpressionNode;
			if (token.type == TokenType.DynamicVariable && m_dynamicVariableCallback != null)
			{
				node = m_dynamicVariableCallback(m_vectorSpace, token.symbol);
			}
			else
			{
				node = new ExpressionNode(m_vectorSpace, token.symbol);
			}
			
			node.wrapInParentheses = token.wrappedInParentheses;
			
			// If token is a value then push it onto the stack
			if (token.isNumericOrVariable())
			{
				nodeStack.add(node);
			}
			else
			{
				// Its an operator in which case we take the top two values from the
				// stack as its left and right operands
				var rightOperand:ExpressionNode = nodeStack.pop();
				rightOperand.parent = node;
				node.right = rightOperand;
				
				var leftOperand:ExpressionNode = nodeStack.pop();
				leftOperand.parent = node;
				node.left = leftOperand;
				
				// After creating the subexpression, push the result back on the stack,
				// this subtree is an operand for another operator
				nodeStack.add(node);
			}
		}
		
		// Stack is only empty if the expression is empty
		// Otherwise we should get back the root
		if (!nodeStack.isEmpty())
		{
			root = nodeStack.pop();
		}
		
		// Additional stuff on the stack at this point is an error
		if (nodeStack.pop() != null)
		{
			throw "Malformed expression!";
		}
		
		return root;
	}
}