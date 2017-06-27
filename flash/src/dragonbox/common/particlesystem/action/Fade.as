package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Adjusts the alpha of a particle over time
     */
    public class Fade extends Action
    {
        private var m_endAlpha:Number;
        private var m_deltaAlpha:Number;
        
        public function Fade(startAlpha:Number, endAlpha:Number)
        {
            super();
            
            m_endAlpha = endAlpha;
            m_deltaAlpha = startAlpha - endAlpha;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            const alpha:Number = m_endAlpha + m_deltaAlpha * particle.energy;
            particle.alpha = alpha;
        }
    }
}