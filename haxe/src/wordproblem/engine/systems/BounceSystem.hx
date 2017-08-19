package wordproblem.engine.systems;

import motion.Actuate;
import motion.easing.Expo;

import openfl.display.DisplayObject;

import wordproblem.engine.component.BounceComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.MouseInteractableComponent;
import wordproblem.engine.component.RenderableComponent;

/**
 * Handle a bounce animation to be applied to a single widget.
 */
class BounceSystem extends BaseSystemScript
{
    public function new()
    {
        super("BounceSystem");
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var components : Array<Component> = componentManager.getComponentListForType(BounceComponent.TYPE_ID);
        var numBounceComponents : Int = components.length;
        var i : Int = 0;
        var bounceComponent : BounceComponent = null;
        for (i in 0...numBounceComponents){
            bounceComponent = try cast(components[i], BounceComponent) catch(e:Dynamic) null;
            
            if (bounceComponent.target == null) 
            {
                // Get the main render component that is supposed to be bounced
                var renderComponent : RenderableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        bounceComponent.entityId,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                
                // The bounce should ease to the apex and do a series of small bounces on the way down.
                var targetView : DisplayObject = renderComponent.view;
                bounceComponent.setOriginalPosition(targetView.x, targetView.y);
                
                var duration : Float = 1.0;
				Actuate.tween(targetView, duration, { x: targetView.x, y: targetView.y - targetView.height }).delay(1.0).repeat().reflect().ease(Expo.easeIn);
				bounceComponent.target = targetView;
            }  
			
			// If the user drags on the view, the bounce should be interuppted  
            // Check if the given entity has a mouse component  
            var mouseComponent : MouseInteractableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                    bounceComponent.entityId,
                    MouseInteractableComponent.TYPE_ID
                    ), MouseInteractableComponent) catch(e:Dynamic) null;
            if (mouseComponent != null) 
            {
                // If selected AND is playing then stop
                if (mouseComponent.selectedThisFrame && !bounceComponent.paused) 
                {
					Actuate.pause(bounceComponent.target);
                    bounceComponent.resetToOriginalPosition();
                    bounceComponent.paused = true;
                }
                // If not selected AND not playing then start
                else if (!mouseComponent.selectedThisFrame && bounceComponent.paused) 
                {
					Actuate.resume(bounceComponent.target);
                    bounceComponent.paused = false;
                }
            }
        }
    }
}
