package dragonbox.common.math.vectorspace
{
    /**
     * A simple struct to store general properties of an operator
     */
    public class RealsOperator
    {
        public var symbol:String;
        public var precedence:int;
        public var isCommunative:Boolean;
        public var isAssociative:Boolean;
        public var isLeftAssociative:Boolean;
        
        public function RealsOperator(symbol:String, 
                                      precedence:int,
                                      isCommunative:Boolean,
                                      isAssociative:Boolean,
                                      isLeftAssociative:Boolean)
        {
            this.symbol = symbol;
            this.precedence = precedence;
            this.isCommunative = isCommunative;
            this.isAssociative = isAssociative;
            this.isLeftAssociative = isLeftAssociative;
        }
    }
}