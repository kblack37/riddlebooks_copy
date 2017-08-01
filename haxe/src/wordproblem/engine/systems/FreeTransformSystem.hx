package wordproblem.engine.systems;


import starling.animation.Tween;
import starling.core.Starling;

import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.MoveableComponent;
import wordproblem.engine.component.RotatableComponent;
import wordproblem.engine.component.TransformComponent;

/**
 * System handles adjusting the transformation properties an entity across any direction along the 2-d plane.
 * 
 * For simplicity it leverages the starling tween components to update each property
 */
class FreeTransformSystem extends BaseSystemScript
{
    //private var m_transformJuggler:Juggler = new Juggler();
    
    /**
     * Keep pool of tweens to re-use, once a tween is done it should be returned to the pool
     */
    private var m_tweenPool : Array<Tween>;
    
    public function new()
    {
        super("FreeTransformSystem");
        m_tweenPool = new Array<Tween>();
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var transformComponent : TransformComponent = null;
        
        // Check if movement, rotation, or scale properties have requested an update
        var i : Int = 0;
        var rotatableComponents : Array<Component> = componentManager.getComponentListForType(RotatableComponent.TYPE_ID);
        var numRotatableComponents : Int = rotatableComponents.length;
        var rotatableComponent : RotatableComponent = null;
        for (i in 0...numRotatableComponents){
            rotatableComponent = try cast(rotatableComponents[i], RotatableComponent) catch(e:Dynamic) null;
            if (rotatableComponent.isActive && !rotatableComponent.requestHandled) 
            {
                transformComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                                rotatableComponent.entityId,
                                TransformComponent.TYPE_ID
                                ), TransformComponent) catch(e:Dynamic) null;
                
                if (rotatableComponent.velocityRadiansPerSecond <= 0) 
                {
                    transformComponent.rotation = rotatableComponent.targetRotation;
                    onRotateComplete(null, rotatableComponent);
                }
                else 
                {
                    var rotateTween : Tween = getTween();
                    var rotationTime : Float = Math.abs((transformComponent.rotation - rotatableComponent.targetRotation) / rotatableComponent.velocityRadiansPerSecond);
                    rotateTween.reset(transformComponent, rotationTime);
                    rotateTween.onComplete = onRotateComplete;
                    rotateTween.onCompleteArgs = [rotateTween, rotatableComponent];
                    rotateTween.animate("rotation", rotatableComponent.targetRotation);
                    
                    Starling.current.juggler.add(rotateTween);
                }
                
                rotatableComponent.requestHandled = true;
            }
        }
        
        var moveableComponents : Array<Component> = componentManager.getComponentListForType(MoveableComponent.TYPE_ID);
        var numMoveableComponents : Int = moveableComponents.length;
        var moveableComponent : MoveableComponent = null;
        for (i in 0...numMoveableComponents){
            moveableComponent = try cast(moveableComponents[i], MoveableComponent) catch(e:Dynamic) null;
            if (moveableComponent.isActive && !moveableComponent.requestHandled) 
            {
                transformComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                                moveableComponent.entityId,
                                TransformComponent.TYPE_ID
                                ), TransformComponent) catch(e:Dynamic) null;
                
                if (moveableComponent.velocityPixelPerSecond <= 0) 
                {
                    transformComponent.x = moveableComponent.targetX;
                    transformComponent.y = moveableComponent.targetY;
                    onMoveComplete(null, moveableComponent);
                }
                else 
                {
                    var moveTween : Tween = getTween();
                    var xDelta : Float = (transformComponent.x - moveableComponent.targetX);
                    var yDelta : Float = (transformComponent.y - moveableComponent.targetY);
                    var moveTime : Float = Math.abs(Math.sqrt(xDelta * xDelta + yDelta * yDelta) / moveableComponent.velocityPixelPerSecond);
                    moveTween.reset(transformComponent, moveTime);
                    moveTween.onComplete = onMoveComplete;
                    moveTween.onCompleteArgs = [moveTween, moveableComponent];
                    moveTween.animate("x", moveableComponent.targetX);
                    moveTween.animate("y", moveableComponent.targetY);
                    
                    Starling.current.juggler.add(moveTween);
                }
                
                moveableComponent.requestHandled = true;
            }
        }
    }
    
    private function onRotateComplete(tween : Tween, component : RotatableComponent) : Void
    {
        // Put back tween
        if (tween != null) 
        {
            Starling.current.juggler.remove(tween);
            m_tweenPool.push(tween);
        }  // Set component to not active  
        
        
        
        component.isActive = false;
    }
    
    private function onMoveComplete(tween : Tween, component : MoveableComponent) : Void
    {
        if (tween != null) 
        {
            Starling.current.juggler.remove(tween);
            m_tweenPool.push(tween);
        }
        
        component.isActive = false;
    }
    
    private function getTween() : Tween
    {
        return ((m_tweenPool.length == 0)) ? new Tween(null, 0) : m_tweenPool.pop();
    }
}
