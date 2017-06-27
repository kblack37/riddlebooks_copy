package dragonbox.common.particlesystem.clock
{
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Clock that emits particles at a steady rate
     */
    public class SteadyClock extends Clock
    {
        private var m_rate:Number;
        private var m_inverseRate:Number;
        
        /**
         * Seconds
         */
        private var m_timeToNextEmission:Number;
        
        /**
         * @param rate
         *      The number of particles per second to emit
         */
        public function SteadyClock(rate:Number)
        {
            super();
            
            m_rate = rate;
            m_inverseRate = 1 / rate;
        }
        
        override public function start(emitter:Emitter):uint
        {
            m_timeToNextEmission = m_inverseRate;
            return 0;
        }
        
        override public function update(emitter:Emitter, timeSinceLastUpdate:Number):uint
        {
            var emitCount:uint = 0;
            m_timeToNextEmission -= timeSinceLastUpdate;
            while (m_timeToNextEmission <= 0)
            {
                emitCount++;
                m_timeToNextEmission += m_inverseRate;
            }
            
            return emitCount;
        }
    }
}