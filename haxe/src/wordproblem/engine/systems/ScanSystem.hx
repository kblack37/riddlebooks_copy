package wordproblem.engine.systems;


import starling.display.DisplayObject;

import wordproblem.engine.animation.ScanAnimation;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.component.ScanComponent;
import wordproblem.engine.text.view.DocumentView;

/**
 * This system handles applying the scan animation to one of the entities
 */
class ScanSystem extends BaseSystemScript
{
    public function new()
    {
        super("ScanSystem");
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var scanComponents : Array<Component> = componentManager.getComponentListForType(ScanComponent.TYPE_ID);
        var i : Int = 0;
        var scanComponent : ScanComponent = null;
        var numComponents : Int = scanComponents.length;
        for (i in 0...numComponents){
            scanComponent = try cast(scanComponents[i], ScanComponent) catch(e:Dynamic) null;
            
            if (scanComponent.animation == null) 
            {
                var renderComponent : RenderableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        scanComponent.entityId,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                
                // In the case of scanning over a document view, we may need to work with a list of display objects
                if (Std.is(renderComponent.view, DocumentView)) 
                {
                    var childViews : Array<DocumentView> = new Array<DocumentView>();
                    (try cast(renderComponent.view, DocumentView) catch(e:Dynamic) null).getDocumentViewLeaves(childViews);
                    
                    // Change list of document views to display objects
                    var childViewsAsDisplayObject : Array<DisplayObject> = new Array<DisplayObject>();
                    for (childView in childViews)
                    {
                        childViewsAsDisplayObject.push(childView);
                    }
                    
                    var animation : ScanAnimation = new ScanAnimation(
                    scanComponent.color, 
                    scanComponent.velocity, 
                    scanComponent.width, 
                    scanComponent.delay
                    );
                    animation.play(childViewsAsDisplayObject);
                    scanComponent.animation = animation;
                }
            }
        }
    }
}
