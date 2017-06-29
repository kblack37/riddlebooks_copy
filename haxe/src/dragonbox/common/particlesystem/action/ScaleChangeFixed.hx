package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Apply change in the scal of a particle using fixed start and end values
 * 
 * Scale initialization is not needed for this action
 */
class ScaleChangeFixed extends Action
{
    private var m_endScale : Float;
    private var m_deltaScale : Float;
    
    public function new(startScale : Float, endScale : Float)
    {
        super();
        
        m_deltaScale = startScale - endScale;
        m_endScale = endScale;
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        particle.scale = m_endScale + m_deltaScale * particle.energy;
    }
}
