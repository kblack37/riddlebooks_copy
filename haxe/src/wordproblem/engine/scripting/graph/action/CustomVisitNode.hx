package wordproblem.engine.scripting.graph.action;

import haxe.Constraints.Function;

import wordproblem.engine.scripting.graph.ScriptNode;

/**
 * This node is made to allow for very small bits of logic that are embedded within
 * another node.
 * 
 * This essentially builds up a large if/else chain of logic that gets run on every frame.
 * Primary usage for this is in level scripts where we want very specific actions to be executed
 * on a particular update.
 */
class CustomVisitNode extends ScriptNode
{
    /**
     * Function should return status of the visit
     */
    private var m_customVisitFunction : Function;
    
    /**
     * Data to pass on visit
     */
    private var m_customVisitParams : Dynamic;
    
    public function new(customVisitFunction : Function,
            customVisitParams : Dynamic,
            id : String = null)
    {
        super(id);
        
        m_customVisitFunction = customVisitFunction;
        m_customVisitParams = customVisitParams;
    }
    
    override public function visit() : Int
    {
        return m_customVisitFunction(m_customVisitParams);
    }
}
