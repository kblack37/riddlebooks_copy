package wordproblem.scripts.expression.solving;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;
import wordproblem.scripts.expression.BaseTermAreaScript;

/**
 * This script handles distributing a term inside a parenthesis
 */
class DistributeTerm extends BaseTermAreaScript
{
    /**
     * Need to figure out which card is being dragged around
     */
    private var m_widgetDragSystem : WidgetDragSystem;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    override public function visit() : Int
    {
        /*
        Check if the dragged card is part of a parenthesis group.
        Then check if all other additive terms in that group have that same value.
        
        On the first press of the card can immediately check whether a distribute is possible.
        If not, then we can ignore any action up until the card has been released.
        
        If is is possible then we need to check when the drag is occurring if it is within the proper
        bounds to trigger the distribution.
        
        For now the area is the segment outside the box formed by the parens. Another bigger box bounds
        this, if the mouse leaves.
        */
        var status : Int = ScriptStatus.FAIL;
        if (m_ready && m_isActive) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            
            if (m_eventTypeBuffer.length > 0) 
            {
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected()) 
                { }
        }
        return status;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_widgetDragSystem = try cast(this.getNodeById("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null;
    }
}
