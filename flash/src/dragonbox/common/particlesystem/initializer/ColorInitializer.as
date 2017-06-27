package dragonbox.common.particlesystem.initializer
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.util.XColor;

    /**
     * Set the initial color from some range
     * 
     * Can also optionally assign start and end value for each particle to remember
     * to allow for different color over time variation per particle.
     */
    public class ColorInitializer extends Initializer
    {
        private var m_startColorRange1:uint;
        private var m_startColorRange2:uint;
        private var m_endColorRange1:uint;
        private var m_endColorRange2:uint;
        private var m_assignStartEndToParticle:Boolean;
        
        public function ColorInitializer(startColorRange1:uint, 
                                         startColorRange2:uint,
                                         assignStartEndToParticle:Boolean,
                                         endColorRange1:uint = 0,
                                         endColorRange2:uint = 0
                                         )
        {
            super();
            
            m_startColorRange1 = startColorRange1;
            m_startColorRange2 = startColorRange2;
            m_endColorRange1 = endColorRange1;
            m_endColorRange2 = endColorRange2;
            
            m_assignStartEndToParticle = assignStartEndToParticle;
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            const startingColorToPick:uint = XColor.interpolateColors(m_startColorRange1, m_startColorRange2, Math.random());
            particle.color = startingColorToPick;
            
            if (m_assignStartEndToParticle)
            {
                particle.startColor = startingColorToPick;
                
                const endingColorToPick:uint = XColor.interpolateColors(m_endColorRange1, m_endColorRange2, Math.random());
                particle.endColor = endingColorToPick;
            }
        }
    }
}