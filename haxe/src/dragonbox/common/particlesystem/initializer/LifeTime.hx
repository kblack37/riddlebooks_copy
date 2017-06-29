package dragonbox.common.particlesystem.initializer;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

class LifeTime extends Initializer
{
    private var m_maxLifetime : Float;
    private var m_minLifetime : Float;
    
    /**
     * Set the lifetime of the particle
     */
    public function new(maxLifetimeSec : Float, minLifetimeSec : Float)
    {
        super();
        
        m_maxLifetime = maxLifetimeSec;
        m_minLifetime = minLifetimeSec;
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        particle.lifeTime = m_minLifetime + Math.random() * (m_maxLifetime - m_minLifetime);
    }
}
