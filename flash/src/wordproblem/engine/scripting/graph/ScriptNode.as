package wordproblem.engine.scripting.graph
{
    import dragonbox.common.dispose.IDisposable;

	public class ScriptNode implements IDisposable
	{
		/** List of child nodes, empty if it is a leaf */
		protected var m_children:Vector.<ScriptNode>;
		
        /**
         * Get the parent of the current node. It's primary usage is to trace up to a
         * desired root.
         * 
         * If null, then this node is an overall root.
         */
        protected var m_parent:ScriptNode;
        
        /** 
         * Flag to indicate whether the logic contained in this node should be executed.
         * If it is false, the visit should return a failure. By default it should be true
         */
        protected var m_isActive:Boolean;
        
        /**
         * Get the unique identifier for this node. Its primary usage is to tag scripts
         * that we want to set active and inactive throughout the course of a level.
         */
        protected var m_id:String;
        
        /**
         * Several types of nodes will want to iterate through its children during a visit call.
         * However children nodes may freely add/remove more nodes to this one during a visit.
         * Depending on how a node implements this iteration this could be problematic, suppose we use
         * a simple for loop and a child node on visit adds several new script nodes to this one.
         * It might add them to the start of the list which pushes existing scripts later. This node is already in
         * the middle of going through the children
         * 
         * The solution is to buffer changes so this node can adjust iteration while in the middle of visit.
         * Change types are just 'add' and 'remove'
         * 
         * IMPORTANT: By default this is not initialized since not all nodes need it
         */
        protected var m_childrenListModifyTypeBuffer:Vector.<String>;
        
        /**
         * The index of an element, where it was added or deleted in the child node list
         * 
         * IMPORTANT: By default this is not initialized since not all nodes need it
         */
        protected var m_childrenListModifyIndexBuffer:Vector.<int>;
        
		public function ScriptNode(id:String=null, isActive:Boolean=true)
		{
			m_children = new Vector.<ScriptNode>();
            m_id = id;
            
            // By default all script nodes are automatically set as active
            setIsActive(isActive);
		}
        
        /**
         * This function is used to inform the script about any arbitrary extra data
         * the script should internally know how to parse out.
         * 
         * A very hacky function, ideally the extra data should just be passed along in the constructor.
         * It's main usage is to allow for custom level scripts to accept any xml chunks needed
         * to extend the level behavior.
         * 
         * This is a prototype that should be overridden by each subclass.
         */
        public function setExtraData(data:Object):void
        {
        }
        
		/**
		 * Calling this function indicates that the logic inside this node
		 * and its children should be executed based on the semantics of this node.
		 * 
		 * For example:
		 * A node to move the character would be a leaf and most contain the calls to
		 * start moving the said character while a sequencer node would call visit
		 * on its children in a well-defined order.
		 * 
		 * @return
		 * 		A status code of the results of visiting this node
		 */
		public function visit():int
		{
			return ScriptStatus.ERROR;
		}
		
        /**
         * Add new child script.
         * If a custom child script requires fetching another script via a getByNodeId then this
         * function must be called as this is the only way the parent pointer is set
         * 
         * @param child
         * @param index
         *      The index in the child list to add the new child to. -1 means at to the end
         */
		public function pushChild(child:ScriptNode, index:int=-1):void
		{
            // Add new child at the end
			m_children.push(child);
            child.m_parent = this;
            
            // Might need to shift objects to have the new child at a particular index
            if (index >=0 && index < m_children.length)
            {
                var totalChildren:int = m_children.length;
                var i:int;
                for (i = totalChildren - 1; i > index; i--)
                {
                    m_children[i] = m_children[i - 1];
                }
                
                m_children[index] = child;
            }
            
            if (m_childrenListModifyTypeBuffer != null)
            {
                m_childrenListModifyTypeBuffer.push("add");
                m_childrenListModifyIndexBuffer.push((index >= 0) ? index : m_children.length - 1);
            }
		}
        
        public function getChildren():Vector.<ScriptNode>
        {
            return m_children;
        }
        
        /**
         * Should always try to use this function to toggle whether a script should
         * execute it's logic rather than setting the variable directly. 
         * 
         * If nodes have event listeners then this function should be overidden with the listeners
         * being added and removed here (Make sure the flag is still altered).
         */
        public function setIsActive(value:Boolean):void
        {
            m_isActive = value;
            
            for each (var childScriptNode:ScriptNode in m_children)
            {
                childScriptNode.setIsActive(value);
            }
        }
        
        public function getIsActive():Boolean
        {
            return m_isActive;
        }
        
        /**
         * Clears any currently running state within a node. Be careful not to
         * call reset on any nodes are currently running as the persistent state in
         * that case is desired.
         * 
         * For selectors that will re-execute nodes (like concurrent selectors) it is very 
         * important this is called to prevent nodes from using stale data.
         */
        public function reset():void
        {
            var i:int;
            var numChildren:int = m_children.length;
            for (i = 0; i < numChildren; i++)
            {
                m_children[i].reset();
            }
        }
        
        /**
         * Get a node matching the given id within the entire subtree that this node is contained within.
         * 
         * In order for this to work ALL SCRIPTS MUST BE LINKED IN THE SAME TREE
         */
        public function getNodeById(id:String):ScriptNode
        {
            // First trace up to the root then perform a search from that root
            var trackerNode:ScriptNode = this;
            while (trackerNode.m_parent != null)
            {
                trackerNode = trackerNode.m_parent;
            }
            
            return trackerNode._getNodeById(id);
        }
        
        protected function _getNodeById(id:String):ScriptNode
        {
            // If the node matches the id we can break immediately, otherwise we need to search the children
            var targetNode:ScriptNode = null;
            if (this.m_id == id)
            {
                targetNode = this;
            }
            else
            {
                var i:int;
                const numChildren:int = m_children.length;
                for (i = 0; i < numChildren; i++)
                {
                    targetNode = m_children[i]._getNodeById(id);
                    if (targetNode != null)
                    {
                        break;
                    }
                }
            }
            
            return targetNode;
        }
        
        /**
         * Dynamically remove a given node from the child list of this script.
         */
        public function deleteChild(nodeToRemove:ScriptNode):void
        {
            var indexToRemove:int = m_children.indexOf(nodeToRemove);
            if (indexToRemove >= 0)
            {
                m_children.splice(indexToRemove, 1);
                nodeToRemove.dispose();
                
                if (m_childrenListModifyTypeBuffer != null)
                {
                    m_childrenListModifyTypeBuffer.push("remove");
                    m_childrenListModifyIndexBuffer.push(indexToRemove);
                }
            }
        }
        
        /**
         * By default it will set the node to inactive and calls dispose on each child.
         * 
         * Should be overriden if the script contains other resources it needs to release.
         * We will just say that by convention if a script has event listeners, then setting it inactive should
         * release them.
         */
        public function dispose():void
        {
            var i:int;
            const numChildren:int = m_children.length;
            for (i = 0; i < numChildren; i++)
            {
                m_children[i].dispose();
            }
            
            this.setIsActive(false);
            
            m_parent = null;
        }
	}
}