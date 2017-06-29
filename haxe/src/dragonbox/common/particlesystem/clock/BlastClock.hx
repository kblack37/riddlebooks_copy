package dragonbox.common.particlesystem.clock;

import dragonbox.common.particlesystem.clock.Clock;

import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * A blast will release all particles at once at startup
 */
class BlastClock extends Clock
{
    private var m_particlesToRelease : Int;
    
    public function new(particlesToRelease : Int)
    {
        super();
        
        m_particlesToRelease = particlesToRelease;
    }
    
    override public function start(emitter : Emitter) : Int
    {
        return m_particlesToRelease;
    }
    
    override public function update(emitter : Emitter, timeSinceLastUpdate : Float) : Int
    {
        return 0;
    }
}
