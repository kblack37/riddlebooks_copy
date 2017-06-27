package wordproblem.engine.systems
{
    import starling.animation.Tween;
    import starling.core.Starling;
    
    import wordproblem.engine.component.BlinkComponent;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.RenderableComponent;

    /**
     * System handles flashing the transparency of a target display object.
     */
    public class BlinkSystem extends BaseSystemScript
    {
        public function BlinkSystem()
        {
            super("BlinkSystem");
        }
        
        override public function update(componentManager:ComponentManager):void
        {
            var blinkComponents:Vector.<Component> = componentManager.getComponentListForType(BlinkComponent.TYPE_ID);
            var numBlinkComponents:int = blinkComponents.length;
            var i:int;
            var blinkComponent:BlinkComponent;
            for (i = 0; i < numBlinkComponents; i++)
            {
                blinkComponent = blinkComponents[i] as BlinkComponent;
                
                if (blinkComponent.tween == null)
                {
                    var renderComponent:RenderableComponent = componentManager.getComponentFromEntityIdAndType(
                        blinkComponent.entityId, 
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    
                    // Create a new tween and add it to the 
                    var blinkTween:Tween = new Tween(renderComponent.view, blinkComponent.duration);
                    blinkTween.repeatCount = 0;
                    blinkTween.reverse = true;
                    blinkTween.animate("alpha", blinkComponent.minAlpha);
                    Starling.juggler.add(blinkTween);
                    
                    blinkComponent.tween = blinkTween;
                }
            }
        }
    }
}