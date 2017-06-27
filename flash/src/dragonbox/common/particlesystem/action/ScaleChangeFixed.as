package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Apply change in the scal of a particle using fixed start and end values
     * 
     * Scale initialization is not needed for this action
     */
    public class ScaleChangeFixed extends Action
    {
        private var m_endScale:Number;
        private var m_deltaScale:Number;
        
        public function ScaleChangeFixed(startScale:Number, endScale:Number)
        {
            super();
            
            m_deltaScale = startScale - endScale;
            m_endScale = endScale;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            particle.scale = m_endScale + m_deltaScale * particle.energy;
        }
    }
}