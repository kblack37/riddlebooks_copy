package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Update the rotation of the particles based on the angular velocity.
 */
class Rotate extends Action
{
    public function new()
    {
        super();
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        particle.rotation += particle.angularVelocity * time;
    }
}
