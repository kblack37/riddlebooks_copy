package wordproblem.hints;


/**
 * This node class encapsulates the proper selection of the a hint process base on the current
 * game state.
 * 
 * This should be subclassed anytime we have custom picking logic
 */
class HintSelectorNode
{
    private var m_children : Array<HintSelectorNode>;
    
    private var m_customGetHintFunction : Function;
    private var m_customGetHintParameters : Array<Dynamic>;
    
    public function new()
    {
        m_children = new Array<HintSelectorNode>();
    }
    
    public function addChild(child : HintSelectorNode) : Void
    {
        m_children.push(child);
    }
    
    /**
     * Subclasses of this hint selector may need the visit function in order to
     * update or poll state on each frame. For example the selector might need to manually
     * examine clicks on the ui to figure out if it should give a hint.
     */
    public function visit() : Void
    {
        var i : Int;
        var numChildren : Int = m_children.length;
        for (i in 0...numChildren){
            m_children[i].visit();
        }
    }
    
    /**
     * Used if we want to inject custom logic in the caller object of how the hint script should
     * be generated
     * 
     * @param customGetHintFunction
     *      Must return null or a hint script
     * @param customGetHintParameters
     *      Array of objects to be passed to the custom function
     */
    public function setCustomGetHintFunction(customGetHintFunction : Function, customGetHintParameters : Array<Dynamic>) : Void
    {
        m_customGetHintFunction = customGetHintFunction;
        m_customGetHintParameters = customGetHintParameters;
    }
    
    /**
     *
     * @return
     *      null if this node or any of its children do not have an appropriate hint at
     *      the time this function was called given the current game state.
     */
    public function getHint() : HintScript
    {
        var hint : HintScript = null;
        
        if (m_customGetHintFunction != null) 
        {
            hint = m_customGetHintFunction.apply(null, m_customGetHintParameters);
        }
        else 
        {
            var i : Int;
            for (i in 0...m_children.length){
                hint = m_children[i].getHint();
                if (hint != null) 
                {
                    break;
                }
            }
        }
        
        return hint;
    }
    
    public function dispose() : Void
    {
        var i : Int;
        for (i in 0...m_children.length){
            m_children[i].dispose();
        }
    }
}
