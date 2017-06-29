package dragonbox.common.particlesystem.clock;


import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Clock that emits particles at a steady rate
 */
class SteadyClock extends Clock
{
    private var m_rate : Float;
    private var m_inverseRate : Float;
    
    /**
     * Seconds
     */
    private var m_timeToNextEmission : Float;
    
    /**
     * @param rate
     *      The number of particles per second to emit
     */
    public function new(rate : Float)
    {
        super();
        
        m_rate = rate;
        m_inverseRate = 1 / rate;
    }
    
    override public function start(emitter : Emitter) : Int
    {
        m_timeToNextEmission = m_inverseRate;
        return 0;
    }
    
    override public function update(emitter : Emitter, timeSinceLastUpdate : Float) : Int
    {
        var emitCount : Int = 0;
        m_timeToNextEmission -= timeSinceLastUpdate;
        while (m_timeToNextEmission <= 0)
        {
            emitCount++;
            m_timeToNextEmission += m_inverseRate;
        }
        
        return emitCount;
    }
}
