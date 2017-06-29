package wordproblem.engine.component;


import dragonbox.common.expressiontree.ExpressionNode;

/**
 * Indicate that an entity is bound to an expression or equation.
 * 
 * Mostly use for inventory item type entities
 */
class ExpressionComponent extends Component
{
    public static inline var TYPE_ID : String = "ExpressionComponent";
    
    public var expressionString : String;
    public var root : ExpressionNode;
    
    /**
     * Flag to indicate whether whatever rendering of this expression should draw it
     * as a hidden component.
     */
    public var hasBeenModeled : Bool;
    
    /**
     * Associated view for the equation needs to look at this dirty bit to determine
     * whether it needs to redraw itself.
     */
    public var dirty : Bool;
    
    /**
     * If this expression is supposed to be treated as a goal, should comparisons against it
     * strictly match the tree structure or do they just need to be semantically equal.
     */
    public var strictMatch : Bool = false;
    
    public function new(id : String,
            equationString : String,
            root : ExpressionNode,
            hasBeenModeled : Bool = false)
    {
        super(id, TYPE_ID);
        this.hasBeenModeled = hasBeenModeled;
        
        if (equationString != null) 
        {
            setDecompiledEquation(equationString, root);
        }
    }
    
    public function setDecompiledEquation(equationString : String, root : ExpressionNode) : Void
    {
        // Note that the root is not altered yet here
        this.expressionString = equationString;
        this.root = root;
        this.dirty = true;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        // TODO: HACKY: The decompiled root needs to be set later since the component does not have
        // access to a decompiler
        
    }
}
