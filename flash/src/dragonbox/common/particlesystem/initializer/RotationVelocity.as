package dragonbox.common.particlesystem.initializer
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Adding a rotational velocity applied on each particle, create a spin on the particle
     */
    public class RotationVelocity extends Initializer
    {
        private var m_minAngularVelocity:Number;
        private var m_maxAngularVelocity:Number;
        
        /**
         * @param minAngularVelocity
         *      Minimum angular velocity in radians per sec
         * @param maxAngularVelocity
         *      Max angular velocity in radians per sec
         */
        public function RotationVelocity(minAngularVelocity:Number, 
                                         maxAngularVelocity:Number=NaN)
        {
            super();
            
            m_minAngularVelocity = minAngularVelocity;
            m_maxAngularVelocity = (isNaN(maxAngularVelocity)) ? minAngularVelocity : maxAngularVelocity;
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            particle.angularVelocity = Math.random() * (m_maxAngularVelocity - m_minAngularVelocity) + m_minAngularVelocity;
        }
    }
}