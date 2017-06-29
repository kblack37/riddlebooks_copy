package dragonbox.common.particlesystem.initializer;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

class Rotation extends Initializer
{
    private var m_minRotation : Float;
    private var m_maxRotation : Float;
    
    public function new(minRotation : Float,
            maxRotation : Float = Math.NaN)
    {
        super();
        
        m_minRotation = minRotation;
        m_maxRotation = ((Math.isNaN(maxRotation))) ? minRotation : maxRotation;
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        particle.rotation = Math.random() * (m_maxRotation - m_minRotation) + m_minRotation;
    }
}
