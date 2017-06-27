package wordproblem.engine.expression.tree
{
    import dragonbox.common.dispose.IDisposable;
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.math.vectorspace.IVectorSpace;

    /**
     * Manage all the expression tree snapshots as it changes from some initial state.
     * 
     * For any given expression tree we first take a snapshot of the initial tree. 
     * After each successful modification we take another snapshot.
     * 
     * Example usage is that expression tree widget classes fire an event whenever the tree
     * has changed, the top level class housing this manager listens for these events and
     * creates snapshots when they are detected. The manager itself has no knowledge internally
     * of when to create new views.
     * 
     * The history MUST have at least one entry
     */
    public class HistoryManager implements IDisposable
    {
        /**
         * The top entry of the stack is intended to always represent the current state of
         * the game board. The bottom entry represents the starting state of the expression,
         * with all entries in between being the results of the modifications made by the player.
         * 
         * Note the history stack can contain null entries for when the expression is blank
         */
        private var m_historyStack:Vector.<ExpressionNode>;
        
        public function HistoryManager()
        {
            m_historyStack = new Vector.<ExpressionNode>();
        }
        
        /**
         * Note that depending on level configuration, snapshots containing wildcards may be filtered
         * out.
         * 
         * @return
         *      The root of the expression tree that represents the state of the expression
         *      if the last recorded change to the tree was undone. Returns null for blank expressions
         */
        public function undo(vectorSpace:IVectorSpace):ExpressionNode
        {
            var rootAfterUndo:ExpressionNode = null;
            
            // Remove the current state at the top
            // DO NOT do this for the first entry, we must remember what that entry is
            if (m_historyStack.length > 1)
            {
                m_historyStack.pop();
            }
			
            // Peek at the new top (this is the old state)
            if (m_historyStack.length > 0)
            {
                rootAfterUndo = m_historyStack[m_historyStack.length - 1];
            }
			
            
            // Return a peek of the previous state while keeping it on the stack
            // Create a copy so the tree is the stack doesn't get modified
            return ExpressionUtil.copy(rootAfterUndo, vectorSpace);
        }
        
        public function createHistorySnapshotEquation(leftRoot:ExpressionNode, 
                                                      rightRoot:ExpressionNode, 
                                                      vectorSpace:IVectorSpace):void
        {
            var equalityRoot:ExpressionNode = ExpressionUtil.createOperatorTree(
                leftRoot, 
                rightRoot, 
                vectorSpace, 
                vectorSpace.getEqualityOperator());
            m_historyStack.push(equalityRoot);
        }
        
        public function clear():void
        {
            while (m_historyStack.length > 0)
            {
                m_historyStack.pop();
            }
        }
        
        public function canUndo():Boolean
        {
            return m_historyStack.length > 1;
        }
        
        public function dispose():void
        {
            clear();
        }
    }
}