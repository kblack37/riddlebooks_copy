package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Pulls particles inward toward a specific point
 */
class GravityWell extends Action
{
    private var m_gravityX : Float;
    private var m_gravityY : Float;
    private var m_power : Float;
    private var m_epsilonSquared : Float;
    
    public function new(x : Float,
            y : Float,
            power : Float,
            epsilon : Float)
    {
        super();
        
        m_gravityX = x;
        m_gravityY = y;
        m_power = power * 10000;
        m_epsilonSquared = epsilon * epsilon;
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        var deltaX : Float = m_gravityX - particle.xPosition;
        var deltaY : Float = m_gravityY - particle.yPosition;
        var distanceSquared : Float = deltaX * deltaX + deltaY * deltaY;
        if (distanceSquared != 0) 
        {
            var distance : Float = Math.sqrt(distanceSquared);
            
            // Clamp to the minimal distance to prevent gravity being too strong
            // at small distances
            if (distanceSquared < m_epsilonSquared) 
            {
                distanceSquared = m_epsilonSquared;
            }
            
            var gravitationalForceFactor : Float = (m_power * time) / (distanceSquared * distance);
            particle.xVelocity += deltaX * gravitationalForceFactor;
            particle.yVelocity += deltaY * gravitationalForceFactor;
        }
    }
}
