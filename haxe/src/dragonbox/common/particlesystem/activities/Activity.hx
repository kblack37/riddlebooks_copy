package dragonbox.common.particlesystem.activities;


import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Activities are transformation to be applied to each emitter on an update
 */
class Activity
{
    /**
     * The emitter must initialize an activity for it to start
     * Used internally when the emitter starts
     * 
     * @param emitter
     *      The emitter using this activity
     */
    public function initialize(emitter : Emitter) : Void
    {
    }
    
    /**
     * An update that is applied by to the emitter at each timestep
     * 
     * @param emitter
     *      The emitter that is registered with this activity
     * @param time
     *      The amount of time to elapse in seconds for this timestep
     */
    public function update(emitter : Emitter, time : Float) : Void
    {
    }

    public function new()
    {
    }
}
