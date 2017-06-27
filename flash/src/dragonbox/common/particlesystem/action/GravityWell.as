package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Pulls particles inward toward a specific point
     */
    public class GravityWell extends Action
    {
        private var m_gravityX:Number;
        private var m_gravityY:Number;
        private var m_power:Number;
        private var m_epsilonSquared:Number;
        
        public function GravityWell(x:Number, 
                                    y:Number, 
                                    power:Number, 
                                    epsilon:Number)
        {
            super();
            
            m_gravityX = x;
            m_gravityY = y;
            m_power = power * 10000;
            m_epsilonSquared = epsilon * epsilon;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            const deltaX:Number = m_gravityX - particle.xPosition;
            const deltaY:Number = m_gravityY - particle.yPosition;
            var distanceSquared:Number = deltaX * deltaX + deltaY * deltaY;
            if (distanceSquared != 0)
            {
                const distance:Number = Math.sqrt(distanceSquared);
                
                // Clamp to the minimal distance to prevent gravity being too strong
                // at small distances
                if (distanceSquared < m_epsilonSquared)
                {
                    distanceSquared = m_epsilonSquared;
                }
                
                const gravitationalForceFactor:Number = (m_power * time) / (distanceSquared * distance);
                particle.xVelocity += deltaX * gravitationalForceFactor;
                particle.yVelocity += deltaY * gravitationalForceFactor;
            }
        }
    }
}