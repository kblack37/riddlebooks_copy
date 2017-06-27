package dragonbox.common.math.vectorspace
{
    import flash.utils.Dictionary;
    
    /**
     * Manipulation of scalars consisting of the set of real numbers.
     * 
     * HACK: We are treating equality as an operator even though is probably
     * an incorrect mathematical definition.
     */
    public class RealsVectorSpace implements IVectorSpace
    {
        private static const ADDITION:String = "+";
        private static const SUBTRACTION:String = "-";
        private static const MULTIPLICATION:String = "*";
        private static const DIVISION:String = "/";
        private static const EQUALITY:String = "=";
        
        private var m_operatorList:Vector.<String>;
        private var m_operatorMap:Dictionary;
        
        public function RealsVectorSpace()
        {
            m_operatorList = new Vector.<String>();
            m_operatorList.push(ADDITION);
            m_operatorList.push(SUBTRACTION);
            m_operatorList.push(MULTIPLICATION);
            m_operatorList.push(DIVISION);
            m_operatorList.push(EQUALITY);
            m_operatorList.push("?");
            
            // The precedence ordering is:
            // Highest (mult, div), (add, sub), (equality) Lowest
            // All except equality are left associative
            m_operatorMap = new Dictionary();
            m_operatorMap[ADDITION] = new RealsOperator(ADDITION, 10, true, true, true);
            m_operatorMap[SUBTRACTION] = new RealsOperator(SUBTRACTION, 10, false, false, true);
            m_operatorMap[MULTIPLICATION] = new RealsOperator(MULTIPLICATION, 15, true, true, true);
            m_operatorMap[DIVISION] = new RealsOperator(DIVISION, 15, false, false, true);
            m_operatorMap[EQUALITY] = new RealsOperator(EQUALITY, 5, true, true, false);
        }
        
        public function add(lhs:*, rhs:*):*
        {
            return Number(lhs)+Number(rhs);
        }
        
        public function sub(lhs:*, rhs:*):*
        {
            return Number(lhs)-Number(rhs);
        }
        
        public function mul(lhs:*, rhs:*):*
        {
            return Number(lhs)*Number(rhs);
        }
        
        public function div(lhs:*, rhs:*):*
        {
            return Number(lhs)/Number(rhs);
        }
        
        public function inv(rhs:*):*
        {
            return -rhs;
        }
        
        public function zero():*
        {
            return 0;
        }
        
        public function identity():*
        {
            return 1;
        }
        
        public function valueOf(content:String):*
        {
            const valueIsNumeric:Boolean = !isNaN(Number(content));
            if(valueIsNumeric)
            {
                return Number(content);
            }
            else // Value is symbolic
            {
                const isNegativeSymbol:Boolean = content.charAt(0) == "-";
                const characterCode:int = isNegativeSymbol ? content.charCodeAt(1) : content.charCodeAt(0);
                const value:int = int.MAX_VALUE - characterCode;
                return isNegativeSymbol ? -value : value;
            }
        }
        
        public function getAdditionOperator():String
        {
            return ADDITION;    
        }
        
        public function getSubtractionOperator():String
        {
            return SUBTRACTION;    
        }
        
        public function getMultiplicationOperator():String
        {
            return MULTIPLICATION;    
        }
        
        public function getDivisionOperator():String
        {
            return DIVISION;    
        }
        
        public function getEqualityOperator():String
        {
            return EQUALITY;
        }
        
        public function get operators():Vector.<String>
        {
            return m_operatorList;
        }
        
        public function getContainsOperator(operator:String):Boolean
        {
            return m_operatorMap.hasOwnProperty(operator);
        }
        
        public function getOperatorPrecedence(operator:String):int
        {
            var precedence:int = -1;
            if (m_operatorMap.hasOwnProperty(operator))
            {
                var operatorData:RealsOperator = m_operatorMap[operator] as RealsOperator;
                precedence = operatorData.precedence;
            }
            return precedence;
        }
        
        /**
         * @inheritDoc
         */
        public function getOperatorIsCommunative(operator:String):Boolean
        {
            var isCommunative:Boolean = false;
            if (m_operatorMap.hasOwnProperty(operator))
            {
                var operatorData:RealsOperator = m_operatorMap[operator] as RealsOperator;
                isCommunative = operatorData.isCommunative;
            }
            
            return isCommunative;
        }
        
        /**
         * @inheritDoc
         */
        public function getOperatorIsAssociative(operator:String):Boolean
        {
            var isAssociative:Boolean = false;
            if (m_operatorMap.hasOwnProperty(operator))
            {
                var operatorData:RealsOperator = m_operatorMap[operator] as RealsOperator;
                isAssociative = operatorData.isAssociative;
            }
            
            return isAssociative;
        }
        
        /**
         * @inheritDoc
         */
        public function getOperatorIsLeftAssociative(operator:String):Boolean
        {
            var isLeftAssociative:Boolean = false;
            if (m_operatorMap.hasOwnProperty(operator))
            {
                var operatorData:RealsOperator = m_operatorMap[operator] as RealsOperator;
                isLeftAssociative = operatorData.isLeftAssociative;
            }
            return isLeftAssociative;
        }
    }
}