package wordproblem.hints.processes;


import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;

/**
 * Action to highlight or change the color a particular ui element in the bar modeling screen
 */
class HighlightUiElementProcess extends ScriptNode
{
    private var m_gameEngine : IGameEngine;
    private var m_targetUiElementId : String;
    private var m_color : Int;
    
    public function new(gameEngine : IGameEngine,
            targetUiId : String,
            color : Int,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        m_gameEngine = gameEngine;
        m_targetUiElementId = targetUiId;
        m_color = color;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (!value) 
        {
            // Clean up the highlight or color shift
            var uiComponents : ComponentManager = m_gameEngine.getUiComponentManager();
            uiComponents.removeComponentFromEntity(m_targetUiElementId, HighlightComponent.TYPE_ID);
        }
    }
    
    override public function visit() : Int
    {
        var uiComponents : ComponentManager = m_gameEngine.getUiComponentManager();
        var highlightComponent : Component = uiComponents.getComponentFromEntityIdAndType(m_targetUiElementId, HighlightComponent.TYPE_ID);
        var renderComponent : RenderableComponent = try cast(uiComponents.getComponentFromEntityIdAndType(m_targetUiElementId, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null;
        if (highlightComponent == null && renderComponent != null) 
        {
            uiComponents.addComponentToEntity(new HighlightComponent(m_targetUiElementId, m_color, 1));
        }
        return ScriptStatus.SUCCESS;
    }
}
