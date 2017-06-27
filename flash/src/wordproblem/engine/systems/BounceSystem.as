package wordproblem.engine.systems
{
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    
    import wordproblem.engine.component.BounceComponent;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.MouseInteractableComponent;
    import wordproblem.engine.component.RenderableComponent;

    /**
     * Handle a bounce animation to be applied to a single widget.
     */
    public class BounceSystem extends BaseSystemScript
    {
        public function BounceSystem()
        {
            super("BounceSystem");
        }
        
        override public function update(componentManager:ComponentManager):void
        {
            const components:Vector.<Component> = componentManager.getComponentListForType(BounceComponent.TYPE_ID);
            const numBounceComponents:int = components.length;
            var i:int;
            var bounceComponent:BounceComponent;
            for (i = 0; i < numBounceComponents; i++)
            {
                bounceComponent = components[i] as BounceComponent;
                
                if (bounceComponent.tween == null)
                {
                    // Get the main render component that is supposed to be bounced
                    const renderComponent:RenderableComponent = componentManager.getComponentFromEntityIdAndType(
                        bounceComponent.entityId,
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    
                    // The bounce should ease to the apex and do a series of small bounces on the way down.
                    const targetView:DisplayObject = renderComponent.view;
                    bounceComponent.setOriginalPosition(targetView.x, targetView.y);
                    
                    const duration:Number = 1.0;
                    var bounceTween:Tween = new Tween(targetView, duration, Transitions.EASE_IN);
                    bounceTween.moveTo(targetView.x, targetView.y - targetView.height);
                    bounceTween.delay = 1.0;
                    bounceTween.reverse = true;
                    bounceTween.repeatCount = 0;
                    bounceComponent.tween = bounceTween;
                    Starling.juggler.add(bounceComponent.tween);
                }
                
                // If the user drags on the view, the bounce should be interuppted
                // Check if the given entity has a mouse component
                const mouseComponent:MouseInteractableComponent = componentManager.getComponentFromEntityIdAndType(
                    bounceComponent.entityId, 
                    MouseInteractableComponent.TYPE_ID
                ) as MouseInteractableComponent;
                if (mouseComponent != null)
                {
                    // If selected AND is playing then stop
                    if (mouseComponent.selectedThisFrame && !bounceComponent.paused)
                    {
                        Starling.juggler.remove(bounceComponent.tween);
                        bounceComponent.resetToOriginalPosition();
                        bounceComponent.paused = true;
                    }
                    // If not selected AND not playing then start
                    else if (!mouseComponent.selectedThisFrame && bounceComponent.paused)
                    {
                        Starling.juggler.add(bounceComponent.tween);
                        bounceComponent.paused = false;
                    }
                }
            }
        }
    }
}