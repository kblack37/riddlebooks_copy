package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.particlesystem.zone.IZone;

/**
 * Killzone specifies an area that will mark particles as dead if it enters the zone.
 * 
 * Can also be inverted to indicate particles outside the zone are marked as dead.
 */
class KillZone extends Action
{
    private var m_zone : IZone;
    private var m_isSafe : Bool;
    
    public function new(zone : IZone, isSafe : Bool)
    {
        super();
        
        m_zone = zone;
        m_isSafe = isSafe;
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        var inZone : Bool = m_zone.contains(particle.xPosition, particle.yPosition);
        if (m_isSafe) 
        {
            if (!inZone) 
            {
                particle.isDead = true;
            }
        }
        else 
        {
            if (inZone) 
            {
                particle.isDead = true;
            }
        }
    }
}
