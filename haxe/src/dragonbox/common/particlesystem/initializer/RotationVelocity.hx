package dragonbox.common.particlesystem.initializer;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Adding a rotational velocity applied on each particle, create a spin on the particle
 */
class RotationVelocity extends Initializer
{
    private var m_minAngularVelocity : Float;
    private var m_maxAngularVelocity : Float;
    
    /**
     * @param minAngularVelocity
     *      Minimum angular velocity in radians per sec
     * @param maxAngularVelocity
     *      Max angular velocity in radians per sec
     */
    public function new(minAngularVelocity : Float,
            maxAngularVelocity : Float = Math.NaN)
    {
        super();
        
        m_minAngularVelocity = minAngularVelocity;
        m_maxAngularVelocity = ((Math.isNaN(maxAngularVelocity))) ? minAngularVelocity : maxAngularVelocity;
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        particle.angularVelocity = Math.random() * (m_maxAngularVelocity - m_minAngularVelocity) + m_minAngularVelocity;
    }
}
