package wordproblem.engine.scripting.graph.selector
{
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    
    /**
     * Runs children in priority order until one of then returns success or running.
     * A success or running will prevent lower priority nodes from executing their visit function during
     * that frame.
     * 
     * One usage is to define an if/else chain
     * Where the root priority node contains a list of concurrent nodes, the first concurrent node
     * that returns success causes us to exit.
     * 
     * Always restarts from the beginning of the list of script nodes during each visit.
     * IMPORTANT DETAIL: if a node never executes a reset function still gets called, this is necessary
     * since that node might have executed on the previous frame and state that it wanted to carry over
     * still needs to be cleared out. Reset is not called on a node that executed a visit, regardless of
     * whether the visit return success or fail.
     */
    public class PrioritySelector extends ScriptNode
    {
        public function PrioritySelector(id:String=null, isActive:Boolean=true)
        {
            super(id, isActive);
        }
        
        override public function visit():int
        {
            // Return failure only if all nodes failed
            var status:int = ScriptStatus.FAIL;
            
            // Always start from the beginnning of the list, lower priority nodes that are never
            // executed still get reset to clear any unused data.
            var numChildren:int = m_children.length;
            var foundRunningChild:Boolean = false;
            
            if (super.m_isActive)
            {
                for (var i:int = 0; i < numChildren; i++)
                {
                    var child:ScriptNode = m_children[i];
                    
                    if (!foundRunningChild)
                    {
                        var childStatus:int = child.visit();
                        if (childStatus == ScriptStatus.SUCCESS ||
                            childStatus == ScriptStatus.RUNNING)
                        {
                            status = childStatus;
                            foundRunningChild = true;
                        }
                    }
                    else
                    {
                        child.reset();
                    }
                }
            }
            
            return status;
        }
    }
}