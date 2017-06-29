package dragonbox.common.particlesystem.initializer;


import flash.geom.Point;

import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.particlesystem.zone.IZone;

/**
 * Set the initial velocity of a particle. Like position it uses a
 * zone to determine values, however in this case a zone refers to
 * ranges of velocity vectors.
 */
class VelocityInitializer extends Initializer
{
    private var m_zone : IZone;
    
    public function new(zone : IZone)
    {
        super();
        
        m_zone = zone;
    }
    
    public function getZone() : IZone
    {
        return m_zone;
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        var velocityValue : Point = m_zone.getLocation();
        var particleRotation : Float = particle.rotation;
        if (particleRotation == 0) 
        {
            particle.xVelocity = velocityValue.x;
            particle.yVelocity = velocityValue.y;
        }
        else 
        {
            var sin : Float = Math.sin(particleRotation);
            var cos : Float = Math.cos(particleRotation);
            particle.xVelocity = cos * velocityValue.x - sin * velocityValue.y;
            particle.yVelocity = cos * velocityValue.y + sin * velocityValue.x;
        }
    }
}
