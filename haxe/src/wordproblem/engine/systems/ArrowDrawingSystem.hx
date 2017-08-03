package wordproblem.engine.systems;

import starling.display.Image;
import wordproblem.engine.systems.BaseSystemScript;

import flash.geom.Point;

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
class ArrowDrawingSystem extends BaseSystemScript
{
    private var m_assetManager : AssetManager;
    
    public function new(assetManager : AssetManager)
    {
        super("ArrowDrawingSystem");
        
        m_assetManager = assetManager;
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var arrowComponents : Array<Component> = componentManager.getComponentListForType(ArrowComponent.TYPE_ID);
        var numArrowComponents : Int = arrowComponents.length;
        var i : Int = 0;
        for (i in 0...numArrowComponents){
            var arrowComponent : ArrowComponent = try cast(arrowComponents[i], ArrowComponent) catch(e:Dynamic) null;
            var entityId : String = arrowComponent.entityId;
            
            if (arrowComponent.arrowView != null) 
            {
                arrowComponent.arrowView.removeFromParent();
            }  // it does not exist then it does not make sense for the arrow to exist    // The target view is the associated render component bound to the entity, if  
            
            
            
            
            
            if (componentManager.hasComponentType(RenderableComponent.TYPE_ID)) 
            {
                var renderComponent : RenderableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                
                if (renderComponent != null) 
                {
                    drawAndPositionArrow(arrowComponent, renderComponent.view);
                }
            }
            else if (componentManager.hasComponentType(RenderableListComponent.TYPE_ID)) 
            {
                var renderListComponent : RenderableListComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        RenderableListComponent.TYPE_ID
                        ), RenderableListComponent) catch(e:Dynamic) null;
                
                var j : Int = 0;
                var views : Array<DisplayObject> = renderListComponent.views;
                for (j in 0...views.length){
                    drawAndPositionArrow(arrowComponent, views[j]);
                }
            }
        }
    }
    
    private function drawAndPositionArrow(arrowComponent : ArrowComponent, targetView : DisplayObject) : Void
    {
        // If an arrow has not been drawn then add it to the display
        if (arrowComponent.arrowView == null) 
        {
			// TODO: this image will likely need to be fixed
            var arrowTexture : Texture = m_assetManager.getTexture("assets/ui/arrow_short.png");
            var arrowImage : Image = new Image(Texture.fromTexture(arrowTexture));
            
            arrowImage.pivotX = arrowImage.width * 0.5;
            arrowImage.pivotY = arrowImage.height * 0.5;
            arrowImage.rotation = arrowComponent.rotation;
            arrowComponent.arrowView = arrowImage;
        }  // Depending on whether the view to attach to is present we add or remove the arrow  
        
        
        
        if (targetView != null) 
        {
            // Only need to reposition if the position of the target view has been modified
            var canvasToAddArrow : DisplayObjectContainer = targetView.parent;
            var arrowView : DisplayObject = arrowComponent.arrowView;
            if (canvasToAddArrow != null) 
            {
                // Arrow needs to be placed at the mid point
                var midX : Float = arrowComponent.midPoint.x;
                var midY : Float = arrowComponent.midPoint.y;
                
                var lastTargetPosition : Point = arrowComponent.lastTargetPosition;
                var repositionArrow : Bool = (lastTargetPosition == null || lastTargetPosition.x != targetView.x || lastTargetPosition.y != targetView.y);
                if (repositionArrow) 
                {
                    if (lastTargetPosition == null) 
                    {
                        arrowComponent.lastTargetPosition = new Point();
                    }  // Position the arrow  
                    
                    
                    
                    arrowComponent.lastTargetPosition.setTo(targetView.x, targetView.y);
                    arrowView.x = midX + targetView.x;
                    arrowView.y = midY + targetView.y;
                    
                    // Scaling needs to occur after translation
                    arrowView.width = arrowComponent.length;
                }
                
                if (arrowComponent.animate && arrowComponent.animation == null) 
                {
                    var angleRadians : Float = Math.atan2(
                            arrowComponent.endPoint.y - arrowComponent.startPoint.y,
                            arrowComponent.endPoint.x - arrowComponent.startPoint.x
                            );
                    var animX : Float = Math.cos(angleRadians) * 50;
                    var animY : Float = Math.sin(angleRadians) * 50;
                    
                    var arrowTween : Tween = new Tween(arrowView, 0.6);
                    arrowTween.moveTo(midX + targetView.x - animX, midY + targetView.y - animY);
                    arrowTween.repeatCount = 0;
                    arrowTween.reverse = true;
                    Starling.current.juggler.add(arrowTween);
                    
                    arrowComponent.animation = arrowTween;
                }  // If it hasn't no need to do any repositioning    // Check if the position of the target view has changed.  
                
                
                
                
                
                canvasToAddArrow.addChild(arrowComponent.arrowView);
            }
            else 
            {
                arrowView.removeFromParent();
                if (arrowComponent.animation != null) 
                {
                    Starling.current.juggler.remove(arrowComponent.animation);
                    arrowComponent.animation = null;
                }
            }
        }
    }
}
