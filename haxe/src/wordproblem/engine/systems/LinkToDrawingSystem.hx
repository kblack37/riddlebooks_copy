package wordproblem.engine.systems;


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
class LinkToDrawingSystem extends BaseSystemScript
{
    private var m_linkToAnimation : LinkToAnimation;
    private var m_widgetDragSystem : WidgetDragSystem;
    
    public function new(assetManager : AssetManager,
            widgetDragSystem : WidgetDragSystem)
    {
        super("LinkToDrawingSystem");
        m_linkToAnimation = new LinkToAnimation(assetManager);
        m_widgetDragSystem = widgetDragSystem;
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var draggedWidget : BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
        
        var linkToComponents : Array<Component> = componentManager.getComponentListForType(LinkToDraggedObjectComponent.TYPE_ID);
        var numComponents : Int = linkToComponents.length;
        var i : Int;
        var linkToComponent : LinkToDraggedObjectComponent;
        var entityId : String;
        for (i in 0...numComponents){
            linkToComponent = try cast(linkToComponents[i], LinkToDraggedObjectComponent) catch(e:Dynamic) null;
            entityId = linkToComponent.entityId;
            
            // Bind the anchor display object to the component, only need to do this once after the component is first created
            if (linkToComponent.targetObjectDisplay == null) 
            {
                if (componentManager.hasComponentType(RenderableComponent.TYPE_ID)) 
                {
                    var renderComponent : RenderableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            RenderableComponent.TYPE_ID
                            ), RenderableComponent) catch(e:Dynamic) null;
                    linkToComponent.targetObjectDisplay = renderComponent.view;
                }
                else if (componentManager.hasComponentType(RenderableListComponent.TYPE_ID)) 
                {
                    var renderListComponent : RenderableListComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            RenderableListComponent.TYPE_ID
                            ), RenderableListComponent) catch(e:Dynamic) null;
                    linkToComponent.targetObjectDisplay = ((renderListComponent.views.length > 0)) ? renderListComponent.views[0] : null;
                }
            }  // Bind or unbind the dragged widget  
            
            
            
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
        }  // TODO: If the component gets removed we need to be able to kill the animation  
    }
}
