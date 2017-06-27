package dragonbox.common.particlesystem.clock
{
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * A blast will release all particles at once at startup
     */
    public class BlastClock extends Clock
    {
        private var m_particlesToRelease:uint;
        
        public function BlastClock(particlesToRelease:uint)
        {
            super();
            
            m_particlesToRelease = particlesToRelease;
        }
        
        override public function start(emitter:Emitter):uint
        {
            return m_particlesToRelease;
        }
        
        override public function update(emitter:Emitter, timeSinceLastUpdate:Number):uint
        {
            return 0;
        }
    }
}