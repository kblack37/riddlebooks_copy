package utils.math;

/**
 * Manipulation of scalars consisting of the set of real numbers.
 * 
 * HACK: We are treating equality as an operator even though is probably
 * an incorrect mathematical definition.
 * 
 * @author Roy
 */
class RealsVectorSpace
{
	private static var ADDITION:String = "+";
	private static var SUBTRACTION:String = "-";
	private static var MULTIPLICATION:String = "*";
	private static var DIVISION:String = "/";
	private static var EQUALITY:String = "=";
	
	private var m_operatorList:Array<String>;
	private var m_operatorMap:Map<String, RealsOperator>;
	
	public function new() 
	{
		m_operatorList = new Array<String>();
		m_operatorList.push(RealsVectorSpace.ADDITION);
		m_operatorList.push(RealsVectorSpace.SUBTRACTION);
		m_operatorList.push(RealsVectorSpace.MULTIPLICATION);
		m_operatorList.push(RealsVectorSpace.DIVISION);
		m_operatorList.push(RealsVectorSpace.EQUALITY);
		m_operatorList.push("?");
		
		// The precedence ordering is:
		// Highest (mult, div), (add, sub), (equality) Lowest
		// All except equality are left associative
		m_operatorMap = new Map();
		m_operatorMap.set(RealsVectorSpace.ADDITION, new RealsOperator(RealsVectorSpace.ADDITION, 10, true, true, true));
		m_operatorMap.set(RealsVectorSpace.SUBTRACTION, new RealsOperator(RealsVectorSpace.SUBTRACTION, 10, false, false, true));
		m_operatorMap.set(RealsVectorSpace.MULTIPLICATION, new RealsOperator(RealsVectorSpace.MULTIPLICATION, 15, true, true, true));
		m_operatorMap.set(RealsVectorSpace.DIVISION, new RealsOperator(RealsVectorSpace.DIVISION, 15, false, false, true));
		m_operatorMap.set(RealsVectorSpace.EQUALITY, new RealsOperator(RealsVectorSpace.EQUALITY, 5, true, true, false));
	}
	
	public function add(lhs:Float, rhs:Float):Float
	{
		return lhs + rhs;
	}
	
	public function sub(lhs:Float, rhs:Float):Float
	{
		return lhs - rhs;
	}
	
	public function mul(lhs:Float, rhs:Float):Float
	{
		return lhs * rhs;
	}
	
	public function div(lhs:Float, rhs:Float):Float
	{
		return lhs / rhs;
	}
	
	public function inv(rhs:Float):Float
	{
		return -1 * rhs;
	}
	
	public function zero():Float
	{
		return 0;
	}
	
	public function identity():Float
	{
		return 1;
	}
	
	public function valueOf(content:String):Float
	{
		var parsedValue:Float = Std.parseFloat(content);
		var isValueNumeric:Bool = !Math.isNaN(parsedValue);
		
		// Symbolic values like 'a' or 'x' need to return some character value
		if (!isValueNumeric)
		{
			var hasNegativeSign:Bool = content.charAt(0) == "-";
			var leadingCharacterCode:Int = hasNegativeSign ? content.charCodeAt(1) : content.charCodeAt(0);
			
			// HACK: Using a value close to int.max (cannot use INFINITY in arithmatic operations)
			parsedValue = 2400000 - leadingCharacterCode;
			if (hasNegativeSign)
			{
				parsedValue *= -1;
			}
		}
		
		return parsedValue;
	}
	
	public function getAdditionOperator():String
	{
		return RealsVectorSpace.ADDITION;
	}
	
	public function getSubtractionOperator():String
	{
		return RealsVectorSpace.SUBTRACTION;
	}
	
	public function getMultiplicationOperator():String
	{
		return RealsVectorSpace.MULTIPLICATION;
	}
	
	public function getDivisionOperator():String
	{
		return RealsVectorSpace.DIVISION;
	}
	
	public function getEqualityOperator():String
	{
		return RealsVectorSpace.EQUALITY;
	}
	
	public function getOperators():Array<String>
	{
		return m_operatorList;
	}
	
	/**
	 * @return
	 *         True if the operator is valid in this space, false otherwise
	 */
	public function getContainsOperator(operator:String):Bool
	{
		return m_operatorMap.exists(operator);
	}
	
	/**
	 * @param
	 *         The string representation of the operator as defined in the
	 *         oeprators list in this space
	 * @return
	 *         The precedence value of the operator is not useful by itself,
	 *         it should only be used for comparison. Returns -1 if the operator
	 *         is invalid, otherwise it is always a non-negative value.
	 */
	public function getOperatorPrecedence(operator:String):Int
	{
		var precedence:Int = -1;
		if (m_operatorMap.exists(operator))
		{
			precedence = m_operatorMap.get(operator).precedence;
		}
		return precedence;
	}
	
	/**
	 * http://en.wikipedia.org/wiki/Commutative_property#Mathematical_definitions
	 */
	public function getOperatorIsCommunative(operator:String):Bool
	{
		var isCommunative:Bool = false;
		if (m_operatorMap.exists(operator))
		{
			isCommunative = m_operatorMap.get(operator).isCommunative;
		}
		return isCommunative;
	}
	
	/**
	 * http://en.wikipedia.org/wiki/Associative_property
	 */
	public function getOperatorIsAssociative(operator:String):Bool
	{
		var isAssociative:Bool = false;
		if (m_operatorMap.exists(operator))
		{
			isAssociative = m_operatorMap.get(operator).isAssociative;
		}
		return isAssociative;
	}
	
	/**
	 * An operator that is left associative means that we can correctly evaluate an expression consisting of just
	 * that operator going from left to right. I.e. x-y-z = (x-y)-z
	 * 
	 * HACK: saying equality is not left associative
	 * 
	 * @param operator
	 *         The string representation of the operator as defined in the
	 *         oeprators list in this space
	 * @return
	 *         True if the given operator is left-associative, false if it is
	 *         right associative
	 */
	public function getOperatorIsLeftAssociative(operator:String):Bool
	{
		var isLeftAssociative:Bool = false;
		if (m_operatorMap.exists(operator))
		{
			isLeftAssociative = m_operatorMap.get(operator).isLeftAssociative;
		}
		return isLeftAssociative;
	}
}