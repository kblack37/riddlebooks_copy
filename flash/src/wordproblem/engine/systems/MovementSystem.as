package wordproblem.engine.systems
{
	import dragonbox.common.time.ITime;
	
	import wordproblem.engine.component.Component;
	import wordproblem.engine.component.ComponentManager;
	import wordproblem.engine.component.MoveableComponent;
	import wordproblem.engine.component.TransformComponent;
	import wordproblem.engine.constants.Direction;

	/**
	 * This system is responsible for readjusting the orientation and position of the
	 * moveable pieces of the world
     * 
     * It also has the pick the proper animation cycle during the movement phase.
     * For simplicity, entities can only move in the four cardinal directions and
     * will always try to move horizontally first.
     * 
     * (DEPRECATED: this was only used for the levels with the simple character sprites in the
     * rpg like levels)
	 */
	public class MovementSystem extends BaseSystemScript
	{
        /** Arithmetic error when performing subtraction, things might not be exactly zero */
        private static const ERROR:Number = 0.0001;
        
        /** Number of pixels the entity needs to move before changing animation cycles */
        private static const ANIMATION_THRESHOLD:Number = 10;
        
        /**
         * We need to correctly fetch time deltas to correctly calculate how much to move
         * each entity.
         */
        private var m_time:ITime;
        
		public function MovementSystem(time:ITime)
		{
            super("MovementSystem");
            
            m_time = time;
		}
		
		override public function update(componentManager:ComponentManager):void
		{
            const moveComponents:Vector.<Component> = componentManager.getComponentListForType(MoveableComponent.TYPE_ID);
            const numComponents:int = moveComponents.length;
            var i:int;
            for (i = 0; i < numComponents; i++)
            {
                var moveComponent:MoveableComponent = moveComponents[i] as MoveableComponent;
                if (moveComponent.isActive)
                {
                    var transformComponent:TransformComponent = componentManager.getComponentFromEntityIdAndType(
                        moveComponent.entityId,
                        TransformComponent.TYPE_ID
                    ) as TransformComponent;
                    
                    // Since the last update calculate the number of pixels the entity could
                    // traverse with it's given velocity
                    // This is the upper bound on how much it can move in this update frame
                    const secondsElapsed:Number = m_time.frameDeltaSecs();
                    const maxPixelsCanMove:Number = secondsElapsed * moveComponent.velocityPixelPerSecond;
                    
                    // Pick whether we should be moving horizontally or vertically
                    var dx:Number = moveComponent.targetX - transformComponent.x;
                    var dy:Number = moveComponent.targetY - transformComponent.y;
                    var absolutePixelsMoved:Number = 0.0;
                    
                    var movedHorizontally:Boolean = true;
                    if (moveComponent.moveHorizontallyFirst)
                    {
                        if (Math.abs(dx) > ERROR)
                        {
                            var amountToMoveX:Number = Math.min(maxPixelsCanMove, Math.abs(dx));
                            absolutePixelsMoved = amountToMoveX;
                            if (dx < 0)
                            {
                                amountToMoveX *= -1;
                            }
                            
                            transformComponent.x += amountToMoveX;
                        }
                        else if (Math.abs(dy) > ERROR)
                        {
                            var amountToMoveY:Number = Math.min(maxPixelsCanMove, Math.abs(dy));
                            absolutePixelsMoved = amountToMoveY;
                            if (dy < 0)
                            {
                                amountToMoveY *= -1;
                            }
                            
                            transformComponent.y += amountToMoveY;
                            movedHorizontally = false;
                        }
                    }
                    else
                    {
                        if (Math.abs(dy) > ERROR)
                        {
                            amountToMoveY = Math.min(maxPixelsCanMove, Math.abs(dy));
                            absolutePixelsMoved = amountToMoveY;
                            if (dy < 0)
                            {
                                amountToMoveY *= -1;
                            }
                            
                            transformComponent.y += amountToMoveY;
                            movedHorizontally = false;
                        }
                        else if (Math.abs(dx) > ERROR)
                        {
                            amountToMoveX = Math.min(maxPixelsCanMove, Math.abs(dx));
                            absolutePixelsMoved = amountToMoveX;
                            if (dx < 0)
                            {
                                amountToMoveX *= -1;
                            }
                            
                            transformComponent.x += amountToMoveX;
                        }
                    }
                    
                    if (absolutePixelsMoved > 0.0)
                    {
                        // Update the animation cycle of the object as it moves
                        // This can be a bit touchy, for now movement is based on how much pixel distance was covered
                        // since the last time the animation cycle was adjusted
                        // Idea is that a fast moving entity should cycle through their animations faster
                        moveComponent.pixelsMovedSinceAnimationCycle += absolutePixelsMoved;
                        if (moveComponent.pixelsMovedSinceAnimationCycle > ANIMATION_THRESHOLD)
                        {
                            moveComponent.pixelsMovedSinceAnimationCycle = 0;
                            transformComponent.animationCycle++;
                            if (transformComponent.animationCycle > 3)
                            {
                                transformComponent.animationCycle = 0;
                            }
                        }
                        
                        // The value of the velocity will also determine the orientation (or facing direction)
                        // Figure out whether the entity move horizontally or vertically
                        if (movedHorizontally)
                        {
                            if (dx > ERROR)
                            {
                                transformComponent.direction = Direction.EAST;
                            }
                            else if (dx < -ERROR)
                            {
                                transformComponent.direction = Direction.WEST;
                            }
                        }
                        else
                        {
                            if (dy > ERROR)
                            {
                                transformComponent.direction = Direction.SOUTH;
                            }
                            else if (dy < -ERROR)
                            {
                                transformComponent.direction = Direction.NORTH;
                            }
                        }
                    }
                    // This extra condition is for the situation where the time object has not been primed yet.
                    // It is returning no time elapsed at the start
                    else if (secondsElapsed > 0)
                    {
                        // Once an entity reaches it's destination the movement component should be shut off
                        moveComponent.isActive = false;
                        moveComponent.pixelsMovedSinceAnimationCycle = 0.0;
                        transformComponent.animationCycle = 0;
                    }
                }
            }
		}
	}
}