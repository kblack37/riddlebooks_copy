package dragonbox.common.particlesystem.action;

import dragonbox.common.particlesystem.action.Action;

import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Applies a constant acceleration, units are in pixels per second squared.
 */
class Accelerate extends Action
{
    private var m_xAcceleration : Float;
    private var m_yAcceleration : Float;
    
    public function new(xAcceleration : Float, yAcceleration : Float)
    {
        super();
        
        m_xAcceleration = xAcceleration;
        m_yAcceleration = yAcceleration;
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        particle.xVelocity += m_xAcceleration * time;
        particle.yVelocity += m_yAcceleration * time;
    }
}
