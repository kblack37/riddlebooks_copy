package wordproblem.engine.scripting.graph.selector
{
	import wordproblem.engine.scripting.graph.ScriptNode;
	import wordproblem.engine.scripting.graph.ScriptStatus;
	
    /**
     * Concurrent attempts to visit every child during its traversal. A certain number of
     * nodes need to fail before this node also returns a failure.
     * 
     * Does not necessarily run in parallel since there might be a very specific traversal
     * order to the child nodes. For example we might place condition nodes first then when
     * failed prevent the next siblings from being executed. This helps to create a simple
     * 'if' statement.
     * 
     * Always restarts from the beginning during each visit.
     */
	public class ConcurrentSelector extends ScriptNode
	{
		private var m_failThreshold:int;
        
        /**
         *
         * @param failThreshold
         *      The number of children nodes needs to exceed this threshold value for this node
         *      to return as failed.
         *      If less than zero all children are visited and run regardless of the fail threshold.
         *      Otherwise children are run in sequential order and the iteration is stopped once the
         *      fail threshold if reached for this frame
         * 
         */
		public function ConcurrentSelector(failThreshold:int,
                                           id:String=null)
		{
			super(id);
            m_failThreshold = failThreshold;
		}
		
		override public function visit():int
		{
			var status:int = ScriptStatus.FAIL;
			
			// Visit all children in linear order, return failure only if some set number
			// of children failed. Otherwise return running if at least one is running
			// and success if non are running but we did not cross the failure threshold
            // Child nodes must be immediately reset if they are not running
			var amountFailed:int = 0;
			var amountRunning:int = 1;
			var amountSuccessful:int = 0;
            
            if (m_isActive)
            {
                var numChildren:int = m_children.length
    			for (var i:int = 0; i < numChildren; i++)
    			{
    				var child:ScriptNode = m_children[i];
    				var childStatus:int = child.visit();
    				if (childStatus == ScriptStatus.FAIL)
    				{
                        child.reset();
    					amountFailed++;
    					if (amountFailed > m_failThreshold && m_failThreshold >= 0)
    					{
    						break;
    					}
    				}
    				else if (childStatus == ScriptStatus.RUNNING)
    				{
    					amountRunning++;
    				}
    				else if (childStatus == ScriptStatus.SUCCESS)
    				{
                        // If a child successfully completes then reset all transient data for the next frame
                        child.reset();
    					amountSuccessful++;
    				}
    			}
    			
                // If we did not cross the fail threshold, success is returned if at least
                // one node succeeded
    			if (m_failThreshold < 0 || amountFailed <= m_failThreshold)
    			{
    				status = (amountSuccessful >= 1) ? ScriptStatus.SUCCESS : ScriptStatus.RUNNING;
    			}
            }
			
			return status;
		}
	}
}