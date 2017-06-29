package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

class CentripetalForce extends Action
{
    private var m_centerX : Float;
    private var m_centerY : Float;
    
    /**
     * This is the magnitude of the force from the particle directed to the
     * central point.
     */
    private var m_radialAcceleration : Float;
    
    /**
     * This is the acceleration tangential to the circular path taken by a particle
     */
    private var m_tangentialAcceleration : Float;
    
    public function new(centerX : Float,
            centerY : Float,
            radialAcceleration : Float,
            tangentialAcceleration : Float)
    {
        super();
        
        m_centerX = centerX;
        m_centerY = centerY;
        m_radialAcceleration = radialAcceleration;
        m_tangentialAcceleration = tangentialAcceleration;
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        var deltaX : Float = particle.xPosition - m_centerX;
        var deltaY : Float = particle.yPosition - m_centerY;
        var distance : Float = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        if (distance < 0.01) 
        {
            distance = 0.01;
        }
        
        var radialX : Float = deltaX / distance;
        var radialY : Float = deltaY / distance;
        
        var tangentialForceX : Float = radialX;
        var tangentialForceY : Float = radialY;
        var newY : Float = tangentialForceX;
        tangentialForceX = -tangentialForceY * m_tangentialAcceleration;
        tangentialForceY = newY * m_tangentialAcceleration;
        
        var radialForceX : Float = radialX * m_radialAcceleration;
        var radialForceY : Float = radialY * m_radialAcceleration;
        
        particle.xVelocity += (radialForceX + tangentialForceX) * time;
        particle.yVelocity += (radialForceY + tangentialForceY) * time;
    }
}
