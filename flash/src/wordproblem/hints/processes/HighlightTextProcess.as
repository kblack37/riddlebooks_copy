package wordproblem.hints.processes
{
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.HighlightComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.TextAreaWidget;
    
    /**
     * Action that highlights a specific span of text
     */
    public class HighlightTextProcess extends ScriptNode
    {
        private var m_textArea:TextAreaWidget;
        private var m_documentIds:Vector.<String>;
        private var m_highlightColor:uint;
        private var m_animationPeriodSeconds:Number;
        
        public function HighlightTextProcess(textArea:TextAreaWidget,
                                             documentIds:Vector.<String>,
                                             highlightColor:uint,
                                             animationPeriod:Number = 2,
                                             id:String=null, 
                                             isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_textArea = textArea;
            m_documentIds = documentIds;
            m_highlightColor = highlightColor;
            m_animationPeriodSeconds = animationPeriod;;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (!value)
            {
                var textComponentManager:ComponentManager = m_textArea.componentManager;
                var i:int;
                var numDocumentIds:int = m_documentIds.length;
                for (i = 0; i < numDocumentIds; i++)
                {
                    var documentId:String = m_documentIds[i];
                    if (textComponentManager.getComponentFromEntityIdAndType(documentId, HighlightComponent.TYPE_ID) != null)
                    {
                        textComponentManager.removeComponentFromEntity(documentId, HighlightComponent.TYPE_ID);
                    }
                }
            }
        }
        
        override public function visit():int
        {
            // Process can finish on a single frame
            var textComponentManager:ComponentManager = m_textArea.componentManager;
            var i:int;
            var numDocumentIds:int = m_documentIds.length;
            for (i = 0; i < numDocumentIds; i++)
            {
                var documentId:String = m_documentIds[i];
                if (textComponentManager.getComponentFromEntityIdAndType(documentId, HighlightComponent.TYPE_ID) == null &&
                    textComponentManager.getComponentFromEntityIdAndType(documentId, RenderableComponent.TYPE_ID) != null)
                {
                    var highlightComponent:HighlightComponent = new HighlightComponent(
                        documentId,
                        m_highlightColor,
                        m_animationPeriodSeconds
                    );
                    textComponentManager.addComponentToEntity(highlightComponent);
                }
            }
            
            return ScriptStatus.SUCCESS;
        }
    }
}