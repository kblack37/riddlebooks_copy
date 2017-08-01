package wordproblem.engine.systems;


import starling.animation.Tween;
import starling.core.Starling;

import wordproblem.engine.component.BlinkComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;

/**
 * System handles flashing the transparency of a target display object.
 */
class BlinkSystem extends BaseSystemScript
{
    public function new()
    {
        super("BlinkSystem");
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var blinkComponents : Array<Component> = componentManager.getComponentListForType(BlinkComponent.TYPE_ID);
        var numBlinkComponents : Int = blinkComponents.length;
        var i : Int = 0;
        var blinkComponent : BlinkComponent = null;
        for (i in 0...numBlinkComponents){
            blinkComponent = try cast(blinkComponents[i], BlinkComponent) catch(e:Dynamic) null;
            
            if (blinkComponent.tween == null) 
            {
                var renderComponent : RenderableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        blinkComponent.entityId,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                
                // Create a new tween and add it to the
                var blinkTween : Tween = new Tween(renderComponent.view, blinkComponent.duration);
                blinkTween.repeatCount = 0;
                blinkTween.reverse = true;
                blinkTween.animate("alpha", blinkComponent.minAlpha);
                Starling.current.juggler.add(blinkTween);
                
                blinkComponent.tween = blinkTween;
            }
        }
    }
}
