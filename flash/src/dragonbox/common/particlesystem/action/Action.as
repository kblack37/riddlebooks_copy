package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Actions specify some sort of modifier to apply to the particle at each time step
     */
    public class Action
    {
        public function Action()
        {
        }
        
        /**
         * Update a particle each frame
         * 
         * @param time
         *      The duration of the frame. For example when apply a gravitational
         *      force, this is the length of time that force should be applied
         */
        public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            
        }
    }
}