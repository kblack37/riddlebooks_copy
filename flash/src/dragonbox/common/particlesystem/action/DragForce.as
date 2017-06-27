package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * This is like a force applied in direction opposite of the movement
     */
    public class DragForce extends Action
    {
        private var m_force:Number;
        
        /**
         * @param magnitude
         *      multiplier to apply to velocity to slow it down
         */
        public function DragForce(magnitude:Number)
        {
            super();
            
            m_force = magnitude;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            const dragInfluence:Number = 1 - m_force * time;
            if (dragInfluence < 0)
            {
                particle.xVelocity = 0;
                particle.yVelocity = 0;
            }
            else
            {
                particle.xVelocity *= dragInfluence;
                particle.yVelocity *= dragInfluence;
            }
        }
    }
}