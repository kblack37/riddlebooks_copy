package wordproblem.engine.scripting.graph.selector
{
	import wordproblem.engine.scripting.graph.ScriptNode;
	import wordproblem.engine.scripting.graph.ScriptStatus;
	
	/**
	 * Defines a strictly ordered execution of events. The execution of the children node
     * is not interrupted, so if all of the nodes can be successfully executed then
     * will all be run on the same frame.
	 * 
	 * Any nodes in a sequence cannot execute unless all nodes prior to it in
	 * the ordering were successful.
     * 
     * Unlike other selectors, the sequence remembers completed nodes and always resumes
     * at the last unfinished node at each visit. Once all children have completed it will
     * no longer execute any of it's logic.
	 */
	public class SequenceSelector extends ScriptNode
	{
		/**
		 * In a sequence we need to keep track of the node that is currently
		 * be executed so we know the proper resume point for events.
		 */
		private var m_indexOfCurrentRunningNode:int;
		
		public function SequenceSelector(id:String=null)
		{
			super(id);
            m_indexOfCurrentRunningNode = 0;
		}
		
        /**
         * If the currently running node has past the last child then this
         * sequence has finished running for the time being.
         */
        public function allChildrenFinished():Boolean
        {
            return m_indexOfCurrentRunningNode > m_children.length - 1;
        }
        
		override public function visit():int
		{
			var status:int = ScriptStatus.FAIL;
			
            if (m_isActive)
            {
    			// May need to resume visiting base on the currently running index
    			var startChildIndex:int = m_indexOfCurrentRunningNode;
    			for (var i:int = startChildIndex; i < m_children.length; i++)
    			{
    				var child:ScriptNode = m_children[i];
    				var childStatus:int = child.visit();
    				
    				// If a child successfully completed we visit and execute the next child
    				// in the sequence
    				if (childStatus == ScriptStatus.SUCCESS)
    				{
    					// Return success if the last child was successfully executed
    					// This means the whole sequence was completed
    					if (i == m_children.length - 1)
    					{
    						status = childStatus;
                            
                            // Do not execute anything more if we run off the last child
                            m_indexOfCurrentRunningNode = m_children.length;
    					}
    				}
    				else
    				{
    					// If a child is running or fails do not visit any more nodes
    					// The subtree needs more time to finish its action
    					m_indexOfCurrentRunningNode = i;
    					
    					// If a child in a sequence fails we mark the entire sequence as failing
                        // We return to the failed/running node at a later point in time
    					status = childStatus;
    					break;
    				}
    			}
            }
			
			return status;
		}
        
        override public function reset():void
        {
            m_indexOfCurrentRunningNode = 0;
            super.reset();
        }
	}
}