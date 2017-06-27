package wordproblem.engine.systems
{
    import flash.geom.Point;
    
    import feathers.display.Scale3Image;
    import feathers.textures.Scale3Textures;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.textures.Texture;
    
    import wordproblem.engine.component.ArrowComponent;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.component.RenderableListComponent;
    import wordproblem.resource.AssetManager;

    /**
     * This system handles drawing arrows pointing at a particular component.
     * 
     * This is primarily used to help emphasize items in tutorials or for hints.
     */
    public class ArrowDrawingSystem extends BaseSystemScript
    {
        private var m_assetManager:AssetManager;
        
        public function ArrowDrawingSystem(assetManager:AssetManager)
        {
            super("ArrowDrawingSystem");
            
            m_assetManager = assetManager;
        }
        
        override public function update(componentManager:ComponentManager):void
        {
            const arrowComponents:Vector.<Component> = componentManager.getComponentListForType(ArrowComponent.TYPE_ID);
            const numArrowComponents:int = arrowComponents.length;
            var i:int;
            for (i = 0; i < numArrowComponents; i++)
            {
                const arrowComponent:ArrowComponent = arrowComponents[i] as ArrowComponent;
                const entityId:String = arrowComponent.entityId;
                
                if (arrowComponent.arrowView != null)
                {
                    arrowComponent.arrowView.removeFromParent();
                }
                
                // The target view is the associated render component bound to the entity, if
                // it does not exist then it does not make sense for the arrow to exist
                if (componentManager.hasComponentType(RenderableComponent.TYPE_ID))
                {
                    const renderComponent:RenderableComponent = componentManager.getComponentFromEntityIdAndType(
                        entityId, 
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    
                    if (renderComponent != null)
                    {
                        drawAndPositionArrow(arrowComponent, renderComponent.view);
                    }
                }
                else if (componentManager.hasComponentType(RenderableListComponent.TYPE_ID))
                {
                    const renderListComponent:RenderableListComponent = componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        RenderableListComponent.TYPE_ID
                    ) as RenderableListComponent;
                    
                    var j:int;
                    var views:Vector.<DisplayObject> = renderListComponent.views;
                    for (j = 0; j < views.length; j++)
                    {
                        drawAndPositionArrow(arrowComponent, views[j]);
                    }
                }
            }
        }
        
        private function drawAndPositionArrow(arrowComponent:ArrowComponent, targetView:DisplayObject):void
        {
            // If an arrow has not been drawn then add it to the display
            if (arrowComponent.arrowView == null)
            {
                const arrowTexture:Texture = m_assetManager.getTexture("arrow_short");
                const arrowImage:Scale3Image = new Scale3Image(new Scale3Textures(arrowTexture, 20, 30));
                
                arrowImage.pivotX = arrowImage.width * 0.5;
                arrowImage.pivotY = arrowImage.height * 0.5;
                arrowImage.rotation = arrowComponent.rotation;
                arrowComponent.arrowView = arrowImage;
            }
            
            // Depending on whether the view to attach to is present we add or remove the arrow
            if (targetView != null)
            {
                // Only need to reposition if the position of the target view has been modified
                var canvasToAddArrow:DisplayObjectContainer = targetView.parent;
                var arrowView:DisplayObject = arrowComponent.arrowView;
                if (canvasToAddArrow != null)
                {
                    // Arrow needs to be placed at the mid point
                    const midX:Number = arrowComponent.midPoint.x;
                    const midY:Number = arrowComponent.midPoint.y;
                    
                    const lastTargetPosition:Point = arrowComponent.lastTargetPosition;
                    var repositionArrow:Boolean = (lastTargetPosition == null || lastTargetPosition.x != targetView.x || lastTargetPosition.y != targetView.y);
                    if (repositionArrow)
                    {
                        if (lastTargetPosition == null)
                        {
                            arrowComponent.lastTargetPosition = new Point();
                        }
                        
                        // Position the arrow
                        arrowComponent.lastTargetPosition.setTo(targetView.x, targetView.y);
                        arrowView.x = midX + targetView.x;
                        arrowView.y = midY + targetView.y;
                        
                        // Scaling needs to occur after translation
                        arrowView.width = arrowComponent.length;
                    }
                    
                    if (arrowComponent.animate && arrowComponent.animation == null)
                    {
                        const angleRadians:Number = Math.atan2(
                            arrowComponent.endPoint.y - arrowComponent.startPoint.y,
                            arrowComponent.endPoint.x - arrowComponent.startPoint.x 
                        );
                        const animX:Number = Math.cos(angleRadians) * 50;
                        const animY:Number = Math.sin(angleRadians) * 50;
                        
                        var arrowTween:Tween = new Tween(arrowView, 0.6);
                        arrowTween.moveTo(midX + targetView.x - animX, midY + targetView.y - animY);
                        arrowTween.repeatCount = 0;
                        arrowTween.reverse = true;
                        Starling.juggler.add(arrowTween);
                        
                        arrowComponent.animation = arrowTween;
                    }
                    
                    // Check if the position of the target view has changed.
                    // If it hasn't no need to do any repositioning
                    canvasToAddArrow.addChild(arrowComponent.arrowView);
                }
                else
                {
                    arrowView.removeFromParent();
                    if (arrowComponent.animation != null)
                    {
                        Starling.juggler.remove(arrowComponent.animation);
                        arrowComponent.animation = null;
                    }
                }
            }
        }
    }
}