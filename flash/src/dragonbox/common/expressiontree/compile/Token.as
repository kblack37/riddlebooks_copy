package dragonbox.common.expressiontree.compile
{
	public class Token
	{
		/* All categories of tokens detected by the scanner */
		
		public static const NUMBER:int = 1;
		public static const OPERATOR:int = 2;
		public static const VARIABLE:int = 3;
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
		public static const DYNAMIC:int = 4;
		public static const LEFT_PAREN:int = 5;
		public static const RIGHT_PAREN:int = 6;
		
        /**
         * The category group for this token.
         */
		public var type:int;
        
        /**
         * The actual data represented by the token
         */
		public var symbol:String;
        
        /**
         * Whether or not this token was supposed to be wrapped in parentheses.
         * Refers to the highest precedence token within a subtree.
         */
        public var wrappedInParentheses:Boolean;
		
		public function Token(type:int, symbol:String)
		{
			this.type = type;
			this.symbol = symbol;
            this.wrappedInParentheses = false;
		}
		
		public function isNumericOrVariable():Boolean
		{
			return this.type == NUMBER || this.type == VARIABLE || this.type == DYNAMIC;
		}
	}
}