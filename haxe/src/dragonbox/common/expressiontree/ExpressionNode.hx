package dragonbox.common.expressiontree;


import flash.geom.Vector3D;

import dragonbox.common.math.vectorspace.IVectorSpace;
import dragonbox.common.expressiontree.ExpressionUtil;

/**
 * Note that the id of a cloned node will match that of the parent. This will allow us to find
 * a specific node across multiple snapshots of an expression tree.
 */
class ExpressionNode extends BaseNode
{
    /** Compiler will serialize and desrialize the node to a proper format */
    public var vectorSpace : IVectorSpace;
    
    /** 
     * Describes the units of this node, for example it could be in seconds or meters.
     * Is null if the node has no units, which is true for any non-leaf node and
     * some constant values that do not directly describe a quantity.
     */
    public var unit : String;
    
    public var parent : ExpressionNode;
    public var left : ExpressionNode;
    public var right : ExpressionNode;
    
    /**
     * Indicate whether this node should be wrapped in a set of parentheses.
     * If the node is an operator then left parentheses will be left of the left-most
     * child of this node. The right parentheses will be to the right of the right-most
     * child of this node.
     */
    public var wrapInParentheses : Bool;
    
    /**
     * Should this node be hidden from view during rendering. Example usage is initially hiding
     * blank wild cards as done in dragonbox.
     */
    public var hidden : Bool;
    
    public function new(vectorSpace : IVectorSpace,
            data : String,
            id : Int = -1)
    {
        super(id);
        
        this.vectorSpace = vectorSpace;
        this.data = data;
        this.wrapInParentheses = false;
        this.hidden = false;
        this.position = new Vector3D();
        this.unit = null;
    }
    
    public function clone() : ExpressionNode
    {
        var clone : ExpressionNode = new ExpressionNode(
        this.vectorSpace, 
        this.data, 
        this.id, 
        );
        clone.wrapInParentheses = this.wrapInParentheses;
        clone.hidden = hidden;
        clone.unit = this.unit;
        clone.position = new Vector3D(this.position.x, this.position.y);
        return clone;
    }
    
    public function isLeaf() : Bool
    {
        return this.left == null && this.right == null;
    }
    
    public function isOperator() : Bool
    {
        return this.vectorSpace.getContainsOperator(this.data);
    }
    
    public function isSpecificOperator(operator : String) : Bool
    {
        return this.data == operator;
    }
    
    public function isNegative() : Bool
    {
        // The content has a negative sign in it
        var explictlyNegative : Bool = this.data.charAt(0) == vectorSpace.getSubtractionOperator();
        
        // A subtraction operator causes negativity only if it is to the left of an immediate term
        var implicitlyNegative : Bool = false;
        if (this.parent != null) 
        {
            implicitlyNegative = (this.parent.isSpecificOperator(vectorSpace.getSubtractionOperator()) && this.parent.right == this);
        }
        
        return !(explictlyNegative && implicitlyNegative) && (explictlyNegative || implicitlyNegative);
    }
    
    /**
     * Get the opposite data value.
     * 
     * @return
     *      If the node is positive, returns a negative representation of the data and vis versa
     */
    public function getOppositeValue() : String
    {
        var oppositeValue : String = "";
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
     * Write out the complete tree recursively
     * 
     * @return 
     *      The string representation of the expression.
     */
    override public function toString() : String
    {
        var returnString : String = "";
        if (this.isLeaf()) 
        {
            returnString = Std.string(super);
        }
        else {
            if (wrapInParentheses) {
                returnString += "(";
            }
            (returnString != null += (left != null)) ? Std.string(left) : "";
            returnString += Std.string(super);
            (returnString != null += (right != null)) ? Std.string(right) : "";
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
    public function evaluate() : Dynamic
    {
        var returnValue : Dynamic;
        if (this.isLeaf()) {
            if (ExpressionUtil.isNodeNumeric(this)) 
            {
                returnValue = vectorSpace.valueOf(data);
            }
            else 
            {
                trace("Cannot evaluate variable expressions!");
                return 0;
            }
        }
        else 
        {
            switch (data)
            {
                case vectorSpace.getAdditionOperator():
                    returnValue = left.evaluate() + right.evaluate();
                case vectorSpace.getMultiplicationOperator():
                    returnValue = left.evaluate() * right.evaluate();
                case vectorSpace.getDivisionOperator():
                    returnValue = left.evaluate() / right.evaluate();
                case vectorSpace.getSubtractionOperator():
                    returnValue = left.evaluate() - right.evaluate();
                default:
                    trace("Unsupported operator");
            }
        }
        return returnValue;
    }
}
