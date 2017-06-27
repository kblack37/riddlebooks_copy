package wordproblem.engine.systems
{
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
    public class ScanSystem extends BaseSystemScript
    {
        public function ScanSystem()
        {
            super("ScanSystem");
        }
        
        override public function update(componentManager:ComponentManager):void
        {
            var scanComponents:Vector.<Component> = componentManager.getComponentListForType(ScanComponent.TYPE_ID);
            var i:int;
            var scanComponent:ScanComponent;
            const numComponents:int = scanComponents.length;
            for (i = 0; i < numComponents; i++)
            {
                scanComponent = scanComponents[i] as ScanComponent;
                
                if (scanComponent.animation == null)
                {
                    var renderComponent:RenderableComponent = componentManager.getComponentFromEntityIdAndType(
                        scanComponent.entityId, 
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    
                    // In the case of scanning over a document view, we may need to work with a list of display objects
                    if (renderComponent.view is DocumentView)
                    {
                        var childViews:Vector.<DocumentView> = new Vector.<DocumentView>();
                        (renderComponent.view as DocumentView).getDocumentViewLeaves(childViews);
                        
                        // Change list of document views to display objects
                        var childViewsAsDisplayObject:Vector.<DisplayObject> = new Vector.<DisplayObject>();
                        for each (var childView:DocumentView in childViews)
                        {
                            childViewsAsDisplayObject.push(childView);
                        }
                        
                        var animation:ScanAnimation = new ScanAnimation(
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
}