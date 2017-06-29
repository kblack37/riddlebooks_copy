package wordproblem.hints.processes;


import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TextAreaWidget;

/**
 * Action that highlights a specific span of text
 */
class HighlightTextProcess extends ScriptNode
{
    private var m_textArea : TextAreaWidget;
    private var m_documentIds : Array<String>;
    private var m_highlightColor : Int;
    private var m_animationPeriodSeconds : Float;
    
    public function new(textArea : TextAreaWidget,
            documentIds : Array<String>,
            highlightColor : Int,
            animationPeriod : Float = 2,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_textArea = textArea;
        m_documentIds = documentIds;
        m_highlightColor = highlightColor;
        m_animationPeriodSeconds = animationPeriod;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (!value) 
        {
            var textComponentManager : ComponentManager = m_textArea.componentManager;
            var i : Int;
            var numDocumentIds : Int = m_documentIds.length;
            for (i in 0...numDocumentIds){
                var documentId : String = m_documentIds[i];
                if (textComponentManager.getComponentFromEntityIdAndType(documentId, HighlightComponent.TYPE_ID) != null) 
                {
                    textComponentManager.removeComponentFromEntity(documentId, HighlightComponent.TYPE_ID);
                }
            }
        }
    }
    
    override public function visit() : Int
    {
        // Process can finish on a single frame
        var textComponentManager : ComponentManager = m_textArea.componentManager;
        var i : Int;
        var numDocumentIds : Int = m_documentIds.length;
        for (i in 0...numDocumentIds){
            var documentId : String = m_documentIds[i];
            if (textComponentManager.getComponentFromEntityIdAndType(documentId, HighlightComponent.TYPE_ID) == null &&
                textComponentManager.getComponentFromEntityIdAndType(documentId, RenderableComponent.TYPE_ID) != null) 
            {
                var highlightComponent : HighlightComponent = new HighlightComponent(
                documentId, 
                m_highlightColor, 
                m_animationPeriodSeconds, 
                );
                textComponentManager.addComponentToEntity(highlightComponent);
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
}
