package dragonbox.common.particlesystem.initializer
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    public class LifeTime extends Initializer
    {
        private var m_maxLifetime:Number;
        private var m_minLifetime:Number;
        
        /**
         * Set the lifetime of the particle
         */
        public function LifeTime(maxLifetimeSec:Number, minLifetimeSec:Number)
        {
            super();
            
            m_maxLifetime = maxLifetimeSec;
            m_minLifetime = minLifetimeSec;
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            particle.lifeTime = m_minLifetime + Math.random() * (m_maxLifetime - m_minLifetime);
        }
    }
}