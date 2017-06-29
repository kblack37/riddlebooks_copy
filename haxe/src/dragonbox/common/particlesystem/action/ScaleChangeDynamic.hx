package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Apply change in the scal of a particle using that particle's start and end values
 * 
 * Scale initialization is not needed for this action
 */
class ScaleChangeDynamic extends Action
{
    public function new()
    {
        super();
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        var startScale : Float = particle.startScale;
        var endScale : Float = particle.endScale;
        particle.scale = endScale + (startScale - endScale) * particle.energy;
    }
}
