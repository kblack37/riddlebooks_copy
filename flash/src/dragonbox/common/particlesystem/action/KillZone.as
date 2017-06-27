package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.particlesystem.zone.IZone;

    /**
     * Killzone specifies an area that will mark particles as dead if it enters the zone.
     * 
     * Can also be inverted to indicate particles outside the zone are marked as dead.
     */
    public class KillZone extends Action
    {
        private var m_zone:IZone;
        private var m_isSafe:Boolean;
        
        public function KillZone(zone:IZone, isSafe:Boolean)
        {
            super();
            
            m_zone = zone;
            m_isSafe = isSafe;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            const inZone:Boolean = m_zone.contains(particle.xPosition, particle.yPosition);
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
}