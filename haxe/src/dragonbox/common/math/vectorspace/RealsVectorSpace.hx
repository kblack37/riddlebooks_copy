package dragonbox.common.math.vectorspace;


import flash.utils.Dictionary;

/**
 * Manipulation of scalars consisting of the set of real numbers.
 * 
 * HACK: We are treating equality as an operator even though is probably
 * an incorrect mathematical definition.
 */
class RealsVectorSpace implements IVectorSpace
{
    public var operators(get, never) : Array<String>;

    private static inline var ADDITION : String = "+";
    private static inline var SUBTRACTION : String = "-";
    private static inline var MULTIPLICATION : String = "*";
    private static inline var DIVISION : String = "/";
    private static inline var EQUALITY : String = "=";
    
    private var m_operatorList : Array<String>;
    private var m_operatorMap : Dictionary;
    
    public function new()
    {
        m_operatorList = new Array<String>();
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
        Reflect.setField(m_operatorMap, ADDITION, new RealsOperator(ADDITION, 10, true, true, true));
        Reflect.setField(m_operatorMap, SUBTRACTION, new RealsOperator(SUBTRACTION, 10, false, false, true));
        Reflect.setField(m_operatorMap, MULTIPLICATION, new RealsOperator(MULTIPLICATION, 15, true, true, true));
        Reflect.setField(m_operatorMap, DIVISION, new RealsOperator(DIVISION, 15, false, false, true));
        Reflect.setField(m_operatorMap, EQUALITY, new RealsOperator(EQUALITY, 5, true, true, false));
    }
    
    public function add(lhs : Dynamic, rhs : Dynamic) : Dynamic
    {
        return Std.parseFloat(lhs) + Std.parseFloat(rhs);
    }
    
    public function sub(lhs : Dynamic, rhs : Dynamic) : Dynamic
    {
        return Std.parseFloat(lhs) - Std.parseFloat(rhs);
    }
    
    public function mul(lhs : Dynamic, rhs : Dynamic) : Dynamic
    {
        return Std.parseFloat(lhs) * Std.parseFloat(rhs);
    }
    
    public function div(lhs : Dynamic, rhs : Dynamic) : Dynamic
    {
        return Std.parseFloat(lhs) / Std.parseFloat(rhs);
    }
    
    public function inv(rhs : Dynamic) : Dynamic
    {
        return -rhs;
    }
    
    public function zero() : Dynamic
    {
        return 0;
    }
    
    public function identity() : Dynamic
    {
        return 1;
    }
    
    public function valueOf(content : String) : Dynamic
    {
        var valueIsNumeric : Bool = !Math.isNaN(Std.parseFloat(content));
        if (valueIsNumeric) 
        {
            return Std.parseFloat(content);
        }
        // Value is symbolic
        else 
        {
            var isNegativeSymbol : Bool = content.charAt(0) == "-";
            var characterCode : Int = (isNegativeSymbol) ? content.charCodeAt(1) : content.charCodeAt(0);
            var value : Int = Int.MAX_VALUE - characterCode;
            return (isNegativeSymbol) ? -value : value;
        }
    }
    
    public function getAdditionOperator() : String
    {
        return ADDITION;
    }
    
    public function getSubtractionOperator() : String
    {
        return SUBTRACTION;
    }
    
    public function getMultiplicationOperator() : String
    {
        return MULTIPLICATION;
    }
    
    public function getDivisionOperator() : String
    {
        return DIVISION;
    }
    
    public function getEqualityOperator() : String
    {
        return EQUALITY;
    }
    
    private function get_operators() : Array<String>
    {
        return m_operatorList;
    }
    
    public function getContainsOperator(operator : String) : Bool
    {
        return m_operatorMap.exists(operator);
    }
    
    public function getOperatorPrecedence(operator : String) : Int
    {
        var precedence : Int = -1;
        if (m_operatorMap.exists(operator)) 
        {
            var operatorData : RealsOperator = try cast(Reflect.field(m_operatorMap, operator), RealsOperator) catch(e:Dynamic) null;
            precedence = operatorData.precedence;
        }
        return precedence;
    }
    
    /**
     * @inheritDoc
     */
    public function getOperatorIsCommunative(operator : String) : Bool
    {
        var isCommunative : Bool = false;
        if (m_operatorMap.exists(operator)) 
        {
            var operatorData : RealsOperator = try cast(Reflect.field(m_operatorMap, operator), RealsOperator) catch(e:Dynamic) null;
            isCommunative = operatorData.isCommunative;
        }
        
        return isCommunative;
    }
    
    /**
     * @inheritDoc
     */
    public function getOperatorIsAssociative(operator : String) : Bool
    {
        var isAssociative : Bool = false;
        if (m_operatorMap.exists(operator)) 
        {
            var operatorData : RealsOperator = try cast(Reflect.field(m_operatorMap, operator), RealsOperator) catch(e:Dynamic) null;
            isAssociative = operatorData.isAssociative;
        }
        
        return isAssociative;
    }
    
    /**
     * @inheritDoc
     */
    public function getOperatorIsLeftAssociative(operator : String) : Bool
    {
        var isLeftAssociative : Bool = false;
        if (m_operatorMap.exists(operator)) 
        {
            var operatorData : RealsOperator = try cast(Reflect.field(m_operatorMap, operator), RealsOperator) catch(e:Dynamic) null;
            isLeftAssociative = operatorData.isLeftAssociative;
        }
        return isLeftAssociative;
    }
}
