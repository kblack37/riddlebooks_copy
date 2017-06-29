package wordproblem.engine.systems;


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
class MovementSystem extends BaseSystemScript
{
    /** Arithmetic error when performing subtraction, things might not be exactly zero */
    private static inline var ERROR : Float = 0.0001;
    
    /** Number of pixels the entity needs to move before changing animation cycles */
    private static inline var ANIMATION_THRESHOLD : Float = 10;
    
    /**
     * We need to correctly fetch time deltas to correctly calculate how much to move
     * each entity.
     */
    private var m_time : ITime;
    
    public function new(time : ITime)
    {
        super("MovementSystem");
        
        m_time = time;
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var moveComponents : Array<Component> = componentManager.getComponentListForType(MoveableComponent.TYPE_ID);
        var numComponents : Int = moveComponents.length;
        var i : Int;
        for (i in 0...numComponents){
            var moveComponent : MoveableComponent = try cast(moveComponents[i], MoveableComponent) catch(e:Dynamic) null;
            if (moveComponent.isActive) 
            {
                var transformComponent : TransformComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        moveComponent.entityId,
                        TransformComponent.TYPE_ID
                        ), TransformComponent) catch(e:Dynamic) null;
                
                // Since the last update calculate the number of pixels the entity could
                // traverse with it's given velocity
                // This is the upper bound on how much it can move in this update frame
                var secondsElapsed : Float = m_time.frameDeltaSecs();
                var maxPixelsCanMove : Float = secondsElapsed * moveComponent.velocityPixelPerSecond;
                
                // Pick whether we should be moving horizontally or vertically
                var dx : Float = moveComponent.targetX - transformComponent.x;
                var dy : Float = moveComponent.targetY - transformComponent.y;
                var absolutePixelsMoved : Float = 0.0;
                
                var movedHorizontally : Bool = true;
                if (moveComponent.moveHorizontallyFirst) 
                {
                    if (Math.abs(dx) > ERROR) 
                    {
                        var amountToMoveX : Float = Math.min(maxPixelsCanMove, Math.abs(dx));
                        absolutePixelsMoved = amountToMoveX;
                        if (dx < 0) 
                        {
                            amountToMoveX *= -1;
                        }
                        
                        transformComponent.x += amountToMoveX;
                    }
                    else if (Math.abs(dy) > ERROR) 
                    {
                        var amountToMoveY : Float = Math.min(maxPixelsCanMove, Math.abs(dy));
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
                    }  // Figure out whether the entity move horizontally or vertically    // The value of the velocity will also determine the orientation (or facing direction)  
                    
                    
                    
                    
                    
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
