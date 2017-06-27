package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Apply change in the scal of a particle using that particle's start and end values
     * 
     * Scale initialization is not needed for this action
     */
    public class ScaleChangeDynamic extends Action
    {
        public function ScaleChangeDynamic()
        {
            super();
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            const startScale:Number = particle.startScale;
            const endScale:Number = particle.endScale;
            particle.scale = endScale + (startScale - endScale) * particle.energy;
        }
    }
}