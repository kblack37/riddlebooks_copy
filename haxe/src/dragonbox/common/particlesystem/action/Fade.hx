package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Adjusts the alpha of a particle over time
 */
class Fade extends Action
{
    private var m_endAlpha : Float;
    private var m_deltaAlpha : Float;
    
    public function new(startAlpha : Float, endAlpha : Float)
    {
        super();
        
        m_endAlpha = endAlpha;
        m_deltaAlpha = startAlpha - endAlpha;
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        var alpha : Float = m_endAlpha + m_deltaAlpha * particle.energy;
        particle.alpha = alpha;
    }
}
