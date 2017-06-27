package dragonbox.common.particlesystem.initializer
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    public class ScaleInitializer extends Initializer
    {
        private var m_startMinScale:Number;
        private var m_startMaxScale:Number;
        private var m_endMinScale:Number;
        private var m_endMaxScale:Number;
        private var m_assignStartEndToParticle:Boolean;
        
        public function ScaleInitializer(startMinScale:Number, 
                                         startMaxScale:Number,
                                         assignStartEndToParticle:Boolean,
                                         endMinScale:Number, 
                                         endMaxScale:Number
                                         )
        {
            super();
            
            m_startMinScale = startMinScale;
            m_startMaxScale = startMaxScale;
            m_endMinScale = endMinScale;
            m_endMaxScale = endMaxScale;
            m_assignStartEndToParticle = assignStartEndToParticle;
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            const startScale:Number = (m_startMinScale == m_startMaxScale) ?
                m_startMinScale : m_startMinScale + Math.random() * (m_startMaxScale - m_startMinScale);
            particle.scale = startScale;
            if (m_assignStartEndToParticle)
            {
                particle.startScale = startScale;
                particle.endScale = m_endMinScale + Math.random() * (m_endMaxScale - m_endMinScale);
            }
        }
    }
}