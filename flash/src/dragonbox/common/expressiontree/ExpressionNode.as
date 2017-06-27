package dragonbox.common.expressiontree
{
    import flash.geom.Vector3D;
    
    import dragonbox.common.math.vectorspace.IVectorSpace;
    import dragonbox.common.expressiontree.ExpressionUtil;

    /**
     * Note that the id of a cloned node will match that of the parent. This will allow us to find
     * a specific node across multiple snapshots of an expression tree.
     */
    public class ExpressionNode extends BaseNode
    {    
        /** Compiler will serialize and desrialize the node to a proper format */
        public var vectorSpace:IVectorSpace;
        
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
        public var wrapInParentheses:Boolean;
        
        /**
         * Should this node be hidden from view during rendering. Example usage is initially hiding
         * blank wild cards as done in dragonbox.
         */
        public var hidden:Boolean;
        
        public function ExpressionNode(vectorSpace:IVectorSpace, 
                                       data:String, 
                                       id:int=-1)
        {
            super(id);
            
            this.vectorSpace = vectorSpace;
            this.data = data;
            this.wrapInParentheses = false;
            this.hidden = false;
            this.position = new Vector3D();
            this.unit = null;
        }
        
        public function clone():ExpressionNode
        {
            const clone:ExpressionNode = new ExpressionNode(
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
        
        public function isLeaf():Boolean
        {
            return this.left == null && this.right == null;
        }
        
        public function isOperator():Boolean
        {
            return this.vectorSpace.getContainsOperator(this.data);
        }
        
        public function isSpecificOperator(operator:String):Boolean
        {
            return this.data == operator;
        }
        
        public function isNegative():Boolean
        {
            // The content has a negative sign in it
            const explictlyNegative:Boolean = this.data.charAt(0) == vectorSpace.getSubtractionOperator();
            
            // A subtraction operator causes negativity only if it is to the left of an immediate term
            var implicitlyNegative:Boolean = false;
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
         * Write out the complete tree recursively
         * 
         * @return 
         *      The string representation of the expression.
         */
        override public function toString():String
        {
            var returnString:String = "";
            if(this.isLeaf())
            {
                returnString = super.toString();
            }
            else {
                if (wrapInParentheses) {
                    returnString += "(";
                }
                returnString += (left != null) ? left.toString() : "";
                returnString += super.toString();
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
        public function evaluate():*
        {
            var returnValue:*;
            if(this.isLeaf()){
                if (ExpressionUtil.isNodeNumeric(this)) 
                {
                    returnValue = vectorSpace.valueOf(data);
                }
                else 
                {
                    trace ("Cannot evaluate variable expressions!");
                    return 0;
                }
            }
            else 
            {
                switch (data) 
                {
                    case vectorSpace.getAdditionOperator() : 
                        returnValue = left.evaluate() + right.evaluate();
                        break;
                    case vectorSpace.getMultiplicationOperator() :
                        returnValue = left.evaluate() * right.evaluate();
                        break;
                    case vectorSpace.getDivisionOperator() :
                        returnValue = left.evaluate() / right.evaluate();
                        break;
                    case vectorSpace.getSubtractionOperator() :
                        returnValue = left.evaluate() - right.evaluate();
                        break;
                    default: 
                        trace("Unsupported operator");
                }
            }
            return returnValue;
        }
    }
}