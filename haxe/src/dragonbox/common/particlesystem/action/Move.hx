package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Updates the particle's position based on its velocity
 */
class Move extends Action
{
    public function new()
    {
        super();
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        particle.xPosition += particle.xVelocity * time;
        particle.yPosition += particle.yVelocity * time;
    }
}
