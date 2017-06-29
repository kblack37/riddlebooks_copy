package dragonbox.common.particlesystem.initializer;

import dragonbox.common.particlesystem.initializer.Initializer;

import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

class Alpha extends Initializer
{
    private var m_minAlpha : Float;
    private var m_maxAlpha : Float;
    
    public function new(minAlpha : Float,
            maxAlpha : Float)
    {
        super();
        
        m_minAlpha = minAlpha;
        m_maxAlpha = maxAlpha;
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        particle.alpha = Math.random() * (m_maxAlpha - m_minAlpha) + m_minAlpha;
    }
}
