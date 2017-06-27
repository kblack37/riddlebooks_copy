package wordproblem.engine.systems
{
    import wordproblem.engine.animation.LinkToAnimation;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.LinkToDraggedObjectComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.component.RenderableListComponent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.drag.WidgetDragSystem;

    /**
     * This system is responsible for drawing a link between two separate dispay objects.
     * 
     * Right now this assumes only one active link animation can be present at any instance in time.
     */
    public class LinkToDrawingSystem extends BaseSystemScript
    {
        private var m_linkToAnimation:LinkToAnimation;
        private var m_widgetDragSystem:WidgetDragSystem;
        
        public function LinkToDrawingSystem(assetManager:AssetManager, 
                                            widgetDragSystem:WidgetDragSystem)
        {
            super("LinkToDrawingSystem");
            m_linkToAnimation = new LinkToAnimation(assetManager);
            m_widgetDragSystem = widgetDragSystem;
        }
        
        override public function update(componentManager:ComponentManager):void
        {
            const draggedWidget:BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
            
            const linkToComponents:Vector.<Component> = componentManager.getComponentListForType(LinkToDraggedObjectComponent.TYPE_ID);
            const numComponents:int = linkToComponents.length;
            var i:int;
            var linkToComponent:LinkToDraggedObjectComponent;
            var entityId:String;
            for (i = 0; i < numComponents; i++)
            {
                linkToComponent = linkToComponents[i] as LinkToDraggedObjectComponent;
                entityId = linkToComponent.entityId;
                
                // Bind the anchor display object to the component, only need to do this once after the component is first created
                if (linkToComponent.targetObjectDisplay == null)
                {
                    if (componentManager.hasComponentType(RenderableComponent.TYPE_ID))
                    {
                        const renderComponent:RenderableComponent = componentManager.getComponentFromEntityIdAndType(
                            entityId, 
                            RenderableComponent.TYPE_ID
                        ) as RenderableComponent;
                        linkToComponent.targetObjectDisplay = renderComponent.view;
                    }
                    else if (componentManager.hasComponentType(RenderableListComponent.TYPE_ID))
                    {
                        const renderListComponent:RenderableListComponent = componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            RenderableListComponent.TYPE_ID
                        ) as RenderableListComponent;
                        linkToComponent.targetObjectDisplay = (renderListComponent.views.length > 0) ?  renderListComponent.views[0] : null;
                    }
                }
                
                // Bind or unbind the dragged widget
                if (draggedWidget != null)
                {
                    if (linkToComponent.draggedObjectDisplay == null && !linkToComponent.animationPlaying && linkToComponent.draggedObjectId == draggedWidget.getNode().data)
                    {
                        linkToComponent.draggedObjectDisplay = draggedWidget;
                        m_linkToAnimation.play(
                            linkToComponent.draggedObjectDisplay,
                            linkToComponent.targetObjectDisplay,
                            linkToComponent.xOffset,
                            linkToComponent.yOffset
                        );
                        linkToComponent.animationPlaying = true;
                        linkToComponent.animation = m_linkToAnimation;
                    }
                }
                else
                {
                    if (linkToComponent.draggedObjectDisplay != null && linkToComponent.animationPlaying)
                    {
                        m_linkToAnimation.stop();
                        linkToComponent.animationPlaying = false;
                        
                    }
                    linkToComponent.draggedObjectDisplay = null;
                }
                
                break;
            }
            
            // TODO: If the component gets removed we need to be able to kill the animation
        }
    }
}