package dragonbox.common.expressiontree.compile
{
	import dragonbox.common.expressiontree.ExpressionNode;
	import dragonbox.common.expressiontree.ExpressionUtil;
	import dragonbox.common.math.vectorspace.IVectorSpace;
	import dragonbox.common.system.Stack;

	public class LatexCompiler implements IExpressionTreeCompiler
	{
		private var m_vectorSpace:IVectorSpace;
        private var m_dynamicVariableCharacters:Vector.<String>;
        private var m_dynamicVariableCallback:Function;
		
		public function LatexCompiler(vectorSpace:IVectorSpace)
		{
			m_vectorSpace = vectorSpace;
            m_dynamicVariableCharacters = new Vector.<String>();
		}
		
		public function getVectorSpace():IVectorSpace
		{
			return m_vectorSpace;
		}
		
		public function isOperator(data:String):Boolean
		{
			return m_vectorSpace.getContainsOperator(data);
		}
        
        public function setDynamicVariableInformation(dynamicVariableCharacters:Vector.<String>, 
                                                      nodeCreateCallback:Function):void
        {
            m_dynamicVariableCharacters = dynamicVariableCharacters;
            m_dynamicVariableCallback = nodeCreateCallback;
        }
		
		public function compile(data:String):ExpressionTreeCompilerResults
		{
			// Note: It would probably be better in the long terms to use
			// a compiler tool like ANTLR to generate the scanner and parser
			// rather than hand coding the rules
			if (data.search("[") != -1)
			{
				data = stripHeaderFooter(data);
			}
			var tokens:Vector.<Token> = runTokenizer(data);
			
			// Once we have the tokenized string, we will run the Shunting-yard algorithm
			// to transform it to Reverse-polish-notation. This will make it much easier
			// to construct the proper expression tree from it
			var rpnFormattedTokens:Vector.<Token> = runShuntingYardAlgorithm(tokens);
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
			
			var compilerResults:ExpressionTreeCompilerResults = new ExpressionTreeCompilerResults(rootNode);
			return compilerResults;
		}
		
		private function stripHeaderFooter(latex:String):String
		{
			const headerStrip:String = latex.split("\[")[1];
			const footerStrip:String = headerStrip.split("\]")[0];
			
			return footerStrip;
		}
		
		public function decompileAtNode(node:ExpressionNode, expandUnits:Boolean=true):String
		{
			// Decompiling the expression is simply a matter of doing an in-order traversal of the tree
			// Must also manually append parentheses if precedence rules force it
            var decompiledExpression:String = "";
            if (node != null)
            {
                decompiledExpression = ExpressionUtil.print(node, m_vectorSpace);
            }
            
			return decompiledExpression;
		}
		
		/**
		 * The first step of the compilation process is to break the expression string
		 * down into a list of atomic segments. These will be the terms in our
		 * expression.
		 */
		private function runTokenizer(expression:String):Vector.<Token>
		{
			// Kill whitespace
			expression.replace(" ", "");
			
			var numericRegex:RegExp = /([0-9])/;
			var alphabetUnderscoreRegex:RegExp = /([a-zA-Z_])/;
			
			// Need to first tokenize the expression string
			// A token can be a signed numeric value, a symbol, a variable,
			// a function or an operator
			// Go through each symbol one at a time and see if the current one
			// by itself or in conjunction with prior symbols forms a terminal
			// that we treat as one token.
			var tokens:Vector.<Token> = new Vector.<Token>();
			var currentToken:Token = null;
			var buildingNumber:Boolean = false;
			var buildingVariable:Boolean = false;
			var buildingDynamic:Boolean = false;
			var makeNextValueNegative:Boolean = false;
			for (var i:int = 0; i < expression.length; i++)
			{
				var nextSymbol:String = expression.charAt(i);
				if (makeNextValueNegative)
				{
					nextSymbol = "-" + nextSymbol;
					makeNextValueNegative = false;
				}
				
				// Find a 0-9
				if (nextSymbol.search(numericRegex) != -1)
				{
					// If not building anything, then we start a new number
					if (!buildingNumber && !buildingVariable && !buildingDynamic)
					{
						currentToken = new Token(Token.NUMBER, nextSymbol);
						buildingNumber = true;
					}
					else if (buildingNumber || buildingDynamic || buildingVariable)
					{
						currentToken.symbol += nextSymbol;
					}
				}
				// Letters or dynamic variable
				else if (nextSymbol.search(alphabetUnderscoreRegex) != -1)
				{
					// If not building anything, then we start a new alphabetic symbol
					if (!buildingNumber && !buildingVariable && !buildingDynamic)
					{
						currentToken = new Token(Token.VARIABLE, nextSymbol);
						buildingVariable = true;
					}
					else if (buildingVariable || buildingDynamic)
					{
						currentToken.symbol += nextSymbol;
					}
                    // Appending a letter to a token that started with a number coverts it to a variable
                    else if (buildingNumber)
                    {
                        currentToken.type = Token.VARIABLE;
                        currentToken.symbol += nextSymbol;
                    }
				}
				else if (m_dynamicVariableCharacters.indexOf(nextSymbol) != -1)
				{
					// If not building anything, then we start a new dynamic variable
					if (!buildingNumber && !buildingVariable && !buildingDynamic)
					{
						currentToken = new Token(Token.DYNAMIC, nextSymbol);
						buildingDynamic = true;
					}
				}
                // The dot in most cases will indicate that a decimal number was found
                else if (nextSymbol == ".")
                {
                    // If not building anything then start a new number
                    if (!buildingNumber && !buildingVariable && !buildingDynamic)
                    {
                        currentToken = new Token(Token.NUMBER, nextSymbol);
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
						var isOperator:Boolean = true;
						if (tokens.length > 0)
						{
							var lastToken:Token = tokens[tokens.length - 1];
							if (lastToken.type == Token.OPERATOR || lastToken.type == Token.LEFT_PAREN)
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
							tokens.push(new Token(Token.OPERATOR, nextSymbol));
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
						tokens.push(new Token(Token.LEFT_PAREN, nextSymbol));
					}
					else if (nextSymbol == ")")
					{
						tokens.push(new Token(Token.RIGHT_PAREN, nextSymbol));
					}
					// If a symbol is an operator, push the token immediately
					// WARNING: we are assuming the contents of the vector space
					// will exactly match those in the expression string.
					// We also assume the operators are just a single token long
					else if (m_vectorSpace.getContainsOperator(nextSymbol))
					{
						tokens.push(new Token(Token.OPERATOR, nextSymbol));
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
		private function runShuntingYardAlgorithm(tokens:Vector.<Token>):Vector.<Token>
		{
			var stack:Stack = new Stack();
			var outPutQueue:Vector.<Token> = new Vector.<Token>();
			
			// While there are tokens to be read
			var currentToken:Token;
			for (var i:int = 0; i < tokens.length; i++)
			{
				// Read the token
				currentToken = tokens[i];
				
				if (currentToken.isNumericOrVariable())
				{
					// If token is a number or variable then add it to the output
					outPutQueue.push(currentToken);
				}
				else if (currentToken.type == Token.LEFT_PAREN)
				{
					// If token is left parenthesis, push it to the stack
					stack.push(currentToken);
				}
				else if (currentToken.type == Token.OPERATOR)
				{
					// If the token is an operator o1
					// While there is another operator o2 token on the stack AND
					// either o1 is left-associative AND its precedence is less
					// or equal to o2 OR
					// o1 has precedence strictly less than o2
					// we pop o2 off the stack and put it into the queue
					if (stack.count > 0)
					{
						var opOneIsLeftAssociative:Boolean = m_vectorSpace.getOperatorIsLeftAssociative(currentToken.symbol);
						var opOnePrecedence:int = m_vectorSpace.getOperatorPrecedence(currentToken.symbol);
						var doCheckStack:Boolean = true;
						while (doCheckStack)
						{
							var topToken:Token = stack.peek();
							var opTwoPrecedence:int = m_vectorSpace.getOperatorPrecedence(topToken.symbol);
							if (topToken.type == Token.OPERATOR && 
								(opOneIsLeftAssociative && opOnePrecedence <= opTwoPrecedence || 
									opOnePrecedence < opTwoPrecedence))
							{
								stack.pop();
								outPutQueue.push(topToken);
								if (stack.count == 0)
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
					stack.push(currentToken);
				}
				// If the token is a right paren
				else if (currentToken.type == Token.RIGHT_PAREN)
				{
					
					var foundLeftParen:Boolean = false;
					while (!foundLeftParen && stack.count > 0)
					{
						// Until a token at the top of the stack is a left paren,
						// pop operators from the stack and into the output
						// Also pop the left paren and discard it
						var top:Token = stack.pop() as Token;
						if (top.type == Token.LEFT_PAREN)
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
					if (stack.count > 0)
					{
					}
					
					// If stack is empty without finding a left paren
					// we have a paren error
					if (!foundLeftParen)
					{
						throw new Error("Paren malformed");
					}
				}
			}
			
			// After the first pass we look at the tokens in the stack
			// If the token at the top is a paren, we have a mismatched parenthesis
			// eror.
			// Otherwise push the operator onto the queue
			while (stack.count > 0)
			{
				var remainingToken:Token = stack.pop() as Token;
				if (remainingToken.type != Token.LEFT_PAREN &&
					remainingToken.type != Token.RIGHT_PAREN)
				{
					outPutQueue.push(remainingToken);
				}
				else
				{
					// Paren error
					throw new Error("Paren malformed");
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
		private function runRpn(tokens:Vector.<Token>):ExpressionNode
		{
			var root:ExpressionNode;
			var nodeStack:Stack = new Stack();
			for each (var token:Token in tokens)
			{
                // If the token is a dynamic variable and a dynamic variable callback has been
                // specified then use that callback, otherwise create a default expression node
                var node:ExpressionNode;
                if (token.type == Token.DYNAMIC && m_dynamicVariableCallback != null)
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
					nodeStack.push(node);
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
					nodeStack.push(node);
				}
			}
			
			if (nodeStack.count == 1)
			{
				root = nodeStack.pop();
			}
			else if (nodeStack.count == 0)
			{
				// Stack is empty if the expression is empty
			}
            else
            {
                throw new Error("Malformed expression!");
            }
			
			return root;
		}
	}
}