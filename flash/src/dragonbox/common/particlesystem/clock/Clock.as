package dragonbox.common.particlesystem.clock
{
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * The clock is the class that tells the emitter the number of particles
     * to emit at any given time.
     * 
     * This is an abstract class.
     */
    public class Clock
    {
        public function Clock()
        {
        }
        
        /**
         * Called when an emitter starts
         * 
         * @return
         *      The number of particles to be created
         */
        public function start(emitter:Emitter):uint
        {
            return 0;
        }
        
        /**
         * Called every frame after the emitter has started
         * 
         * @param timeSinceLastUpdate
         *      The number of milliseconds since the last call to this update
         */
        public function update(emitter:Emitter, timeSinceLastUpdate:Number):uint
        {
            return 0;
        }
    }
}