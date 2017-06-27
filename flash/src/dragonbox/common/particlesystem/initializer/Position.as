package dragonbox.common.particlesystem.initializer
{
    import flash.geom.Point;
    
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.particlesystem.zone.IZone;

    public class Position extends Initializer
    {
        private var m_zone:IZone;
        
        public function Position(zone:IZone)
        {
            super();
            
            m_zone = zone;
        }
        
        public function getZone():IZone
        {
            return m_zone;
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            // Note the additive nature of this position. This is to take into account
            // changes in the position caused by the emitter itself.
            const location:Point = m_zone.getLocation();
            if (particle.rotation == 0)
            {
                particle.xPosition += location.x;
                particle.yPosition += location.y;
            }
            else
            {
                const sine:Number = Math.sin(particle.rotation);
                const cosine:Number = Math.cos(particle.rotation);
                
                particle.xPosition += cosine * location.x - sine * location.y;
                particle.yPosition += cosine * location.y + sine * location.x;
            }
        }
    }
}