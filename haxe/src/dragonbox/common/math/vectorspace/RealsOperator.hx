package dragonbox.common.math.vectorspace;

/**
 * A simple struct to store general properties of an operator
 * @author Roy
 */
class RealsOperator 
{
	public var symbol:String;
	public var precedence:Int;
	public var isCommunative:Bool;
	public var isAssociative:Bool;
	public var isLeftAssociative:Bool;
	
	public function new(symbol:String, 
                        precedence:Int,
                        isCommunative:Bool,
                        isAssociative:Bool,
                        isLeftAssociative:Bool) 
	{
		this.symbol = symbol;
		this.precedence = precedence;
		this.isCommunative = isCommunative;
		this.isAssociative = isAssociative;
		this.isLeftAssociative = isLeftAssociative;
	}
}