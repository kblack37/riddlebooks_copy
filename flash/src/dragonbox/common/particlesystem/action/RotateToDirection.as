package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Update the rotation of the particle so that it points in the direction that
     * it is traveling
     */
    public class RotateToDirection extends Action
    {
        public function RotateToDirection()
        {
            super();
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            particle.rotation = Math.atan2(particle.yVelocity, particle.xVelocity);
        }
    }
}