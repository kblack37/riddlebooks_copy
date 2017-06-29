package wordproblem.scripts.expression;


import flash.geom.Point;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import wordproblem.resource.AssetManager;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.expression.widget.manager.CancelManager;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TermAreaWidget;

class StrokeCancelTerms extends BaseTermAreaScript
{
    private var m_cancelManagers : Array<CancelManager>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    private var mousePoint : Point = new Point();
    override public function visit() : Int
    {
        var mouseState : MouseState = m_gameEngine.getMouseState();
        mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
        
        // Assuming each term area has a snap and cancel component
        for (i in 0...m_termAreas.length){
            var cancelManager : CancelManager = m_cancelManagers[i];
            cancelManager.update(mouseState);
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_cancelManagers = new Array<CancelManager>();
        for (i in 0...m_termAreas.length){
            var termArea : TermAreaWidget = m_termAreas[i];
            m_cancelManagers.push(new CancelManager(
                    termArea, 
                    m_assetManager, 
                    onCancelStrokeFinished, 
                    ));
        }
    }
    
    private function onCancelStrokeFinished(cancelManager : CancelManager) : Void
    {
        // Look through the list of nodes that were marked for cancellation
        // Find out the combination of nodes that are able to simplify
        var cancelledWidgets : Array<BaseTermWidget> = cancelManager.getWidgetsMarkedForCancel();
        
        var nodes : Array<ExpressionNode> = new Array<ExpressionNode>();
        for (cancelledWidget in cancelledWidgets)
        {
            nodes.push(cancelledWidget.getNode());
        }
        
        var termAreaIndex : Int = Lambda.indexOf(m_cancelManagers, cancelManager);
        var termArea : TermAreaWidget = m_termAreas[termAreaIndex];
        termArea.simplify(cancelledWidgets);
        
        cancelManager.clear();
    }
}
