package wordproblem.scripts.expression.solving;


import flash.geom.Point;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.expression.BaseTermAreaScript;

/**
 * This scripts handles the condensing of two into a whole number or eliminating both altogether.
 */
class SimplifyNumbers extends BaseTermAreaScript
{
    private var m_globalPoint : Point;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_globalPoint = new Point();
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready && m_isActive) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalPoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            
            // On release, check if the dragged card is intersecting anything
            if (m_eventTypeBuffer.length > 0) 
            {
                var indexOfDragRelease : Int = m_eventTypeBuffer.indexOf(GameEvent.END_DRAG_EXISTING_TERM_WIDGET);
                if (indexOfDragRelease >= 0) 
                {
                    var params : Dynamic = m_eventParamBuffer[indexOfDragRelease];
                    var widget : BaseTermWidget = params.widget;
                    var originTermArea : TermAreaWidget = params.origin;
                    
                    // HACK: Make sure the dragged widget is part of the display list so we can get it's bounds
                    m_gameEngine.getSprite().addChild(widget);
                    
                    // Make sure the origin term area matches the one the mouse is over
                    var i : Int = 0;
                    var termArea : TermAreaWidget = null;
                    for (i in 0...m_termAreas.length){
                        termArea = m_termAreas[i];
                        if (termArea.containsObject(widget)) 
                        {
                            if (originTermArea == termArea) 
                            {
                                var hitWidget : BaseTermWidget = termArea.pickWidgetUnderPoint(m_globalPoint.x, m_globalPoint.y, false);
                                if (hitWidget != null) 
                                {
                                    var canSimplify : Bool = termArea.getTree().simplifyNodes(widget.getNode(), hitWidget.getNode());
                                    if (canSimplify) 
                                    {
                                        termArea.isReady = false;
                                        termArea.redrawAfterModification();
                                    }
                                }
                            }
                            break;
                        }
                    }  // Remove the dragged widget from view  
                    
                    
                    
                    widget.removeFromParent();
                }
                reset();
            }  /*
            else if (widgets.length > 2)
            {
            const nodes:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            for each (var widget:BaseTermWidget in widgets)
            {
            nodes.push(widget.getNode());
            }
            canSimplify = this.m_tree.simplifyCluster(nodes, m_vectorSpace);
            }
            */  
        }
        return status;
    }
}
