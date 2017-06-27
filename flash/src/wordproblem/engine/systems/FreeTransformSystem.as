package wordproblem.engine.systems
{
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
    public class FreeTransformSystem extends BaseSystemScript
    {
        //private var m_transformJuggler:Juggler = new Juggler();
        
        /**
         * Keep pool of tweens to re-use, once a tween is done it should be returned to the pool
         */
        private var m_tweenPool:Vector.<Tween>;
        
        public function FreeTransformSystem()
        {
            super("FreeTransformSystem");
            m_tweenPool = new Vector.<Tween>();
        }
        
        override public function update(componentManager:ComponentManager):void
        {
            var transformComponent:TransformComponent;
            
            // Check if movement, rotation, or scale properties have requested an update
            var i:int;
            var rotatableComponents:Vector.<Component> = componentManager.getComponentListForType(RotatableComponent.TYPE_ID);
            var numRotatableComponents:int = rotatableComponents.length;
            var rotatableComponent:RotatableComponent;
            for (i = 0; i < numRotatableComponents; i++)
            {
                rotatableComponent = rotatableComponents[i] as RotatableComponent;
                if (rotatableComponent.isActive && !rotatableComponent.requestHandled)
                {
                    transformComponent = componentManager.getComponentFromEntityIdAndType(
                        rotatableComponent.entityId, 
                        TransformComponent.TYPE_ID
                    ) as TransformComponent;
                    
                    if (rotatableComponent.velocityRadiansPerSecond <= 0)
                    {
                        transformComponent.rotation = rotatableComponent.targetRotation;
                        onRotateComplete(null, rotatableComponent);
                    }
                    else
                    {
                        var rotateTween:Tween = getTween();
                        var rotationTime:Number = Math.abs((transformComponent.rotation - rotatableComponent.targetRotation) / rotatableComponent.velocityRadiansPerSecond);
                        rotateTween.reset(transformComponent, rotationTime);
                        rotateTween.onComplete = onRotateComplete;
                        rotateTween.onCompleteArgs = [rotateTween, rotatableComponent];
                        rotateTween.animate("rotation", rotatableComponent.targetRotation);
                        
                        Starling.juggler.add(rotateTween);
                    }
                    
                    rotatableComponent.requestHandled = true;
                }
            }
            
            var moveableComponents:Vector.<Component> = componentManager.getComponentListForType(MoveableComponent.TYPE_ID);
            var numMoveableComponents:int = moveableComponents.length;
            var moveableComponent:MoveableComponent;
            for (i = 0; i < numMoveableComponents; i++)
            {
                moveableComponent = moveableComponents[i] as MoveableComponent;
                if (moveableComponent.isActive && !moveableComponent.requestHandled)
                {
                    transformComponent = componentManager.getComponentFromEntityIdAndType(
                        moveableComponent.entityId, 
                        TransformComponent.TYPE_ID
                    ) as TransformComponent;
                    
                    if (moveableComponent.velocityPixelPerSecond <= 0)
                    {
                        transformComponent.x = moveableComponent.targetX;
                        transformComponent.y = moveableComponent.targetY;
                        onMoveComplete(null, moveableComponent);
                    }
                    else
                    {
                        var moveTween:Tween = getTween();
                        var xDelta:Number = (transformComponent.x - moveableComponent.targetX);
                        var yDelta:Number = (transformComponent.y - moveableComponent.targetY);
                        var moveTime:Number = Math.abs(Math.sqrt(xDelta * xDelta + yDelta * yDelta) / moveableComponent.velocityPixelPerSecond);
                        moveTween.reset(transformComponent, moveTime);
                        moveTween.onComplete = onMoveComplete;
                        moveTween.onCompleteArgs = [moveTween, moveableComponent];
                        moveTween.animate("x", moveableComponent.targetX);
                        moveTween.animate("y", moveableComponent.targetY);
                        
                        Starling.juggler.add(moveTween);
                    }
                    
                    moveableComponent.requestHandled = true;
                }
            }
        }
        
        private function onRotateComplete(tween:Tween, component:RotatableComponent):void
        {
            // Put back tween
            if (tween != null)
            {
                Starling.juggler.remove(tween);
                m_tweenPool.push(tween);
            }
            
            // Set component to not active
            component.isActive = false;
        }
        
        private function onMoveComplete(tween:Tween, component:MoveableComponent):void
        {
            if (tween != null)
            {
                Starling.juggler.remove(tween);
                m_tweenPool.push(tween);
            }
            
            component.isActive = false;
        }
        
        private function getTween():Tween
        {
            return (m_tweenPool.length == 0) ? new Tween(null, 0) : m_tweenPool.pop();
        }
    }
}