package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Updates the particle's position based on its velocity
     */
    public class Move extends Action
    {
        public function Move()
        {
            super();
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            particle.xPosition += particle.xVelocity * time;
            particle.yPosition += particle.yVelocity * time;
        }
    }
}