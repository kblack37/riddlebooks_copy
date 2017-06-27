package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Update the rotation of the particles based on the angular velocity.
     */
    public class Rotate extends Action
    {
        public function Rotate()
        {
            super();
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            particle.rotation += particle.angularVelocity * time;
        }
    }
}