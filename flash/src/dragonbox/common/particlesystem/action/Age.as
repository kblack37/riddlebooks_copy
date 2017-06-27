package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Action used to kill off particles after a certain amount of time has elapsed
     */
    public class Age extends Action
    {
        private var m_function:Function;
		public function Age(easingFunction:Function = null)
        {
            super();
			m_function = easingFunction;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
          
            particle.age += time;
            
            // Kill the particle if it exceed the provided lifetime limit
            if (particle.age >= particle.lifeTime)
            {
                particle.energy = 0;
                particle.isDead = true;
            }
            else
            {
                if (m_function == null)
                {
                    // Linear decay if no easing function given
					particle.energy = 1 - (particle.age / particle.lifeTime);
                }
				else 
                {
    				//easing funtion(t,d)	
    				particle.energy = m_function(particle.age, particle.lifeTime);
                }
            }
        }
    }
}