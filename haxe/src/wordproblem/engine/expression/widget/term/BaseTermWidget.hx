package wordproblem.engine.expression.widget.term;


import openfl.geom.Rectangle;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.expressiontree.ExpressionNode;

import openfl.display.Sprite;
import wordproblem.resource.AssetManager;

import wordproblem.engine.component.RigidBodyComponent;

/**
 * NOTE: We make the assumption that all graphics we add on top of this widget will
 * be centered at the registration point (0, 0).
 * 
 * So a call to addChild already positions the graphic in the correct spot
 */
class BaseTermWidget extends Sprite implements IDisposable
{
    /** 
		 * This component always gives the body location relative to the main tree container,
		 * even if this widget is nested.
     * 
     * If a widget is nested then this component factors in the bounds contributed by those
     * other pieces as well.
     * 
     * This is essentially a acts like a cached copy of the rectangle returned from
     * the getBounds() call in starling
		 */
    public var rigidBodyComponent : RigidBodyComponent;
    
    public var parentWidget : BaseTermWidget;
    public var leftChildWidget : BaseTermWidget;
    public var rightChildWidget : BaseTermWidget;
    
    /**
		 * Determine whether this widget needs to wrap its contents within a set of
		 * parentheses.
		 */
    public var m_parenthesesCanvas : Sprite;
    
    /** 
     * This represents the logical boundary of just this widget's visualization,
     * however its reference is in terms of the widget itself so it should
     * probably not be used for the positioning of this widget
     * 
     * For example if a widget is a division, this is the bounds of just the divison
     * graphic.
     */
    public var mainGraphicBounds : Rectangle;
    
    /** Main area where child widgets are added */
    private var m_childrenTermWidgetCanvas : Sprite;
    
    private var m_node : ExpressionNode;
    
    private var m_enabled : Bool;
    
    /** Extra flag to indicate whether the symbol needs to be hidden from view*/
    private var m_hideSymbol : Bool;
    
    /** Used to fetch graphics to add on top */
    private var m_assetManager : AssetManager;
    
    public function new(node : ExpressionNode, assetManager : AssetManager)
    {
        super();
        
        m_node = node;
        rigidBodyComponent = new RigidBodyComponent(Std.string(node.id));
        m_childrenTermWidgetCanvas = new Sprite();
        addChild(m_childrenTermWidgetCanvas);
        
        m_parenthesesCanvas = new Sprite();
        addChild(m_parenthesesCanvas);
        
        m_assetManager = assetManager;
        
        setEnabled(true);
        setIsHidden(false);
    }
    
    public function getNode() : ExpressionNode
    {
        return m_node;
    }
    
    public function getIsEnabled() : Bool
    {
        return m_enabled;
    }
    
    public function setEnabled(enabled : Bool) : Void
    {
        m_enabled = enabled;
        
        if (m_enabled) 
        {
            this.alpha = 1;
        }
        else 
        {
            this.alpha = 0.3;
        }
    }
    
    public function getIsHidden() : Bool
    {
        return m_hideSymbol;
    }
    
    public function setIsHidden(hidden : Bool) : Void
    {
        m_hideSymbol = hidden;
    }
    
    public function addChildWidget(widget : BaseTermWidget) : Void
    {
        m_childrenTermWidgetCanvas.addChildAt(widget, 0);
    }
    
    public function removeChildWidgets() : Void
    {
        while (m_childrenTermWidgetCanvas.numChildren > 0)
        {
            m_childrenTermWidgetCanvas.removeChildAt(0);
        }
    }
    
    public function dispose() : Void
    {
    }
}
