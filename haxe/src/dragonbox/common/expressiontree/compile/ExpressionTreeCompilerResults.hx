package dragonbox.common.expressiontree.compile;


import dragonbox.common.expressiontree.ExpressionNode;

class ExpressionTreeCompilerResults
{
    /**
		 * The overall root node of the resultant expression tree
		 */
    public var head : ExpressionNode;
    
    public function new(head : ExpressionNode = null)
    {
        this.head = head;
    }
}
