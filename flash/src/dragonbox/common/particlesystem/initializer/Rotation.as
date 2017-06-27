package dragonbox.common.particlesystem.initializer
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    public class Rotation extends Initializer
    {
        private var m_minRotation:Number;
        private var m_maxRotation:Number;
        
        public function Rotation(minRotation:Number, 
                                 maxRotation:Number=NaN)
        {
            super();
            
            m_minRotation = minRotation;
            m_maxRotation = (isNaN(maxRotation)) ? minRotation : maxRotation;
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            particle.rotation = Math.random() * (m_maxRotation - m_minRotation) + m_minRotation;
        }
    }
}