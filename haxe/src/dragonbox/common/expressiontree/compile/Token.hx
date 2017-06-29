package dragonbox.common.expressiontree.compile;


class Token
{
    /* All categories of tokens detected by the scanner */
    
    public static inline var NUMBER : Int = 1;
    public static inline var OPERATOR : Int = 2;
    public static inline var VARIABLE : Int = 3;
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
    public static inline var DYNAMIC : Int = 4;
    public static inline var LEFT_PAREN : Int = 5;
    public static inline var RIGHT_PAREN : Int = 6;
    
    /**
     * The category group for this token.
     */
    public var type : Int;
    
    /**
     * The actual data represented by the token
     */
    public var symbol : String;
    
    /**
     * Whether or not this token was supposed to be wrapped in parentheses.
     * Refers to the highest precedence token within a subtree.
     */
    public var wrappedInParentheses : Bool;
    
    public function new(type : Int, symbol : String)
    {
        this.type = type;
        this.symbol = symbol;
        this.wrappedInParentheses = false;
    }
    
    public function isNumericOrVariable() : Bool
    {
        return this.type == NUMBER || this.type == VARIABLE || this.type == DYNAMIC;
    }
}
