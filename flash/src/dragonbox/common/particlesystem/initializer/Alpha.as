package dragonbox.common.particlesystem.initializer
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    public class Alpha extends Initializer
    {
        private var m_minAlpha:Number;
        private var m_maxAlpha:Number;
        
        public function Alpha(minAlpha:Number, 
                              maxAlpha:Number)
        {
            super();
            
            m_minAlpha = minAlpha;
            m_maxAlpha = maxAlpha;
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            particle.alpha = Math.random() * (m_maxAlpha - m_minAlpha) + m_minAlpha;
        }
    }
}