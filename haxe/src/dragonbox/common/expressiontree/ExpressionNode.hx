package utils.expressiontree;

import openfl.geom.Vector3D;
import utils.math.RealsVectorSpace;
import utils.system.Identifiable;

/**
 * ...
 * @author Roy
 */
class ExpressionNode extends Identifiable 
{
	public static var UID_COUNTER:Int = 0;
	private static var ID_COUNTER:Int = 0;
	
	/**
	 * A uid is created for every created node regardless of
	 * whether it is a clone. Every node has this unique identifier.
	 */
	public var uid:Int;
	
	/**
	 * The main value for this node
	 */
	public var data:String;
	
	/**
	 * Get the current location of this node. Used for rendering and any other
	 * simulation for this node.
	 */
	public var position:Vector3D;
	
	/** Compiler will serialize and desrialize the node to a proper format */
	public var vectorSpace:RealsVectorSpace;
	
	/** 
	 * Describes the units of this node, for example it could be in seconds or meters.
	 * Is null if the node has no units, which is true for any non-leaf node and
	 * some constant values that do not directly describe a quantity.
	 */
	public var unit:String;
	
	public var parent:ExpressionNode;
	public var left:ExpressionNode;
	public var right:ExpressionNode;
	
	/**
	 * Indicate whether this node should be wrapped in a set of parentheses.
	 * If the node is an operator then left parentheses will be left of the left-most
	 * child of this node. The right parentheses will be to the right of the right-most
	 * child of this node.
	 */
	public var wrapInParentheses:Bool;

	/**
	 * Should this node be hidden from view during rendering. Example usage is initially hiding
	 * blank wild cards as done in dragonbox.
	 */
	public var hidden:Bool;
	
	public function new(vectorSpace:RealsVectorSpace, data:String, id:Int=-1) 
	{
		this.uid = ExpressionNode.UID_COUNTER;
		ExpressionNode.UID_COUNTER++;
		
		if (id < 0)
		{
			id = this.generateId();
		}
		
		super(id);
		
		this.vectorSpace = vectorSpace;
		this.data = data;
		this.wrapInParentheses = false;
		this.hidden = false;
		this.position = new Vector3D();
		this.unit = null;
	}
	
	public function generateId():Int
	{
		return ExpressionNode.ID_COUNTER++;
	}
	
	public function clone():ExpressionNode
	{
		var clone:ExpressionNode = new ExpressionNode(
			this.vectorSpace, 
			this.data, 
			this.id
		);
		clone.wrapInParentheses = this.wrapInParentheses;
		clone.hidden = hidden;
		clone.unit = this.unit;
		clone.position = new Vector3D(this.position.x, this.position.y);
		return clone;
	}
	
	public function isLeaf():Bool
	{
		return this.left == null && this.right == null;
	}
	
	public function isOperator():Bool
	{
		return this.vectorSpace.getContainsOperator(this.data);
	}
	
	public function isSpecificOperator(operator:String):Bool
	{
		return this.data == operator;
	}
	
	public function isNegative():Bool
	{
		// The content has a negative sign in it
		var explictlyNegative:Bool = this.data.charAt(0) == vectorSpace.getSubtractionOperator();
		
		// A subtraction operator causes negativity only if it is to the left of an immediate term
		var implicitlyNegative:Bool = false;
		if (this.parent != null)
		{
			implicitlyNegative = (this.parent.isSpecificOperator(vectorSpace.getSubtractionOperator()) && this.parent.right == this);
		}
		
		return !(explictlyNegative && implicitlyNegative) && (explictlyNegative || implicitlyNegative) ;
	}
	
	/**
	 * Get the opposite data value.
	 * 
	 * @return
	 *      If the node is positive, returns a negative representation of the data and vis versa
	 */
	public function getOppositeValue():String
	{
		var oppositeValue:String = "";
		if (isNegative())
		{
			oppositeValue = this.data.substr(1);
		}
		else
		{
			oppositeValue = vectorSpace.getSubtractionOperator() + this.data;
		}
		
		return oppositeValue;
	}
	
	/**
	 * Get back the string representation for this node. This is very important for
	 * decompiling an expression node subtree into a string format.
	 * 
	 * Should be overriden if the term value is not the same as its main data, for
	 * example in the case of wild card nodes the value is a composite of a wildcard
	 * prefix and its intended value.
	 *
	 * Write out the complete tree recursively
	 * 
	 * @return 
	 *      The string representation of the expression.
	 */
	public function toString():String
	{
		var returnString:String = "";
		if(this.isLeaf())
		{
			returnString = this.data;
		}
		else {
			if (wrapInParentheses) {
				returnString += "(";
			}
			returnString += (left != null) ? left.toString() : "";
			returnString += this.data;
			returnString += (right != null) ? right.toString() : "";
			if (wrapInParentheses) {
				returnString += ")";
			}
		}
		return returnString;
	}
	
	/**
	 * Evaluate the expression rooted at this node. Note that this treats any variable values
	 * as zero.
	 * 
	 * @return
	 *      The numeric result of the evaluation
	 */
	public function evaluate():Float
	{
		var returnValue:Float = 0;
		if(this.isLeaf()){
			if (ExpressionUtil.isNodeNumeric(this)) 
			{
				returnValue = vectorSpace.valueOf(data);
			}
			else 
			{
				trace ("Cannot evaluate variable expressions!");
			}
		}
		else 
		{
			if (this.data == this.vectorSpace.getAdditionOperator())
			{
				returnValue = left.evaluate() + right.evaluate();
			}
			else if (this.data == this.vectorSpace.getSubtractionOperator())
			{
				returnValue = left.evaluate() - right.evaluate();
			}
			else if (this.data == this.vectorSpace.getMultiplicationOperator())
			{
				returnValue = left.evaluate() * right.evaluate();
			}
			else if (this.data == this.vectorSpace.getDivisionOperator())
			{
				returnValue = left.evaluate() / right.evaluate();
			}
			else
			{
				trace("Unsupported operator");
			}
		}
		return returnValue;
	}
}