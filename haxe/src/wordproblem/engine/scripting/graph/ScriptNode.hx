package wordproblem.engine.scripting.graph;


import dragonbox.common.dispose.IDisposable;
import haxe.xml.Fast;

class ScriptNode implements IDisposable
{
    /** List of child nodes, empty if it is a leaf */
    private var m_children : Array<ScriptNode>;
    
    /**
     * Get the parent of the current node. It's primary usage is to trace up to a
     * desired root.
     * 
     * If null, then this node is an overall root.
     */
    private var m_parent : ScriptNode;
    
    /** 
     * Flag to indicate whether the logic contained in this node should be executed.
     * If it is false, the visit should return a failure. By default it should be true
     */
    private var m_isActive : Bool;
    
    /**
     * Get the unique identifier for this node. Its primary usage is to tag scripts
     * that we want to set active and inactive throughout the course of a level.
     */
    private var m_id : String;
    
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
    private var m_childrenListModifyTypeBuffer : Array<String>;
    
    /**
     * The index of an element, where it was added or deleted in the child node list
     * 
     * IMPORTANT: By default this is not initialized since not all nodes need it
     */
    private var m_childrenListModifyIndexBuffer : Array<Int>;
    
    public function new(id : String = null, isActive : Bool = true)
    {
        m_children = new Array<ScriptNode>();
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
    public function setExtraData(data : Iterator<Fast>) : Void
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
    public function visit() : Int
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
    public function pushChild(child : ScriptNode, index : Int = -1) : Void
    {
        // Add new child at the end
        m_children.push(child);
        child.m_parent = this;
        
        // Might need to shift objects to have the new child at a particular index
        if (index >= 0 && index < m_children.length) 
        {
            var totalChildren : Int = m_children.length;
            var i : Int = 0;
            i = totalChildren - 1;
            while (i > index){
                m_children[i] = m_children[i - 1];
                i--;
            }
            
            m_children[index] = child;
        }
        
        if (m_childrenListModifyTypeBuffer != null) 
        {
            m_childrenListModifyTypeBuffer.push("add");
            m_childrenListModifyIndexBuffer.push(((index >= 0)) ? index : m_children.length - 1);
        }
    }
    
    public function getChildren() : Array<ScriptNode>
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
    public function setIsActive(value : Bool) : Void
    {
        m_isActive = value;
        
        for (childScriptNode in m_children)
        {
            childScriptNode.setIsActive(value);
        }
    }
    
    public function getIsActive() : Bool
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
    public function reset() : Void
    {
        var i : Int = 0;
        var numChildren : Int = m_children.length;
        for (i in 0...numChildren){
            m_children[i].reset();
        }
    }
    
    /**
     * Get a node matching the given id within the entire subtree that this node is contained within.
     * 
     * In order for this to work ALL SCRIPTS MUST BE LINKED IN THE SAME TREE
     */
    public function getNodeById(id : String) : ScriptNode
    {
        // First trace up to the root then perform a search from that root
        var trackerNode : ScriptNode = this;
        while (trackerNode.m_parent != null)
        {
            trackerNode = trackerNode.m_parent;
        }
        
        return trackerNode._getNodeById(id);
    }
    
    private function _getNodeById(id : String) : ScriptNode
    {
        // If the node matches the id we can break immediately, otherwise we need to search the children
        var targetNode : ScriptNode = null;
        if (this.m_id == id) 
        {
            targetNode = this;
        }
        else 
        {
            var i : Int = 0;
            var numChildren : Int = m_children.length;
            for (i in 0...numChildren){
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
    public function deleteChild(nodeToRemove : ScriptNode) : Void
    {
        var indexToRemove : Int = Lambda.indexOf(m_children, nodeToRemove);
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
    public function dispose() : Void
    {
        var i : Int = 0;
        var numChildren : Int = m_children.length;
        for (i in 0...numChildren){
            m_children[i].dispose();
        }
        
        this.setIsActive(false);
        
        m_parent = null;
    }
}
