package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Applies a constant acceleration, units are in pixels per second squared.
     */
    public class Accelerate extends Action
    {
        private var m_xAcceleration:Number;
        private var m_yAcceleration:Number;
        
        public function Accelerate(xAcceleration:Number, yAcceleration:Number)
        {
            super();
            
            m_xAcceleration = xAcceleration;
            m_yAcceleration = yAcceleration;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            particle.xVelocity += m_xAcceleration * time;
            particle.yVelocity += m_yAcceleration * time;
        }
    }
}