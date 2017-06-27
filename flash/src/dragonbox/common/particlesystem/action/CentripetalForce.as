package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    public class CentripetalForce extends Action
    {
        private var m_centerX:Number;
        private var m_centerY:Number;
        
        /**
         * This is the magnitude of the force from the particle directed to the
         * central point.
         */
        private var m_radialAcceleration:Number;
        
        /**
         * This is the acceleration tangential to the circular path taken by a particle
         */
        private var m_tangentialAcceleration:Number;
        
        public function CentripetalForce(centerX:Number, 
                                         centerY:Number, 
                                         radialAcceleration:Number, 
                                         tangentialAcceleration:Number)
        {
            super();
            
            m_centerX = centerX;
            m_centerY = centerY;
            m_radialAcceleration = radialAcceleration;
            m_tangentialAcceleration = tangentialAcceleration;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            const deltaX:Number = particle.xPosition - m_centerX;
            const deltaY:Number = particle.yPosition - m_centerY;
            var distance:Number = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
            if (distance < 0.01)
            {
                distance = 0.01;
            }
            
            const radialX:Number = deltaX / distance;
            const radialY:Number = deltaY / distance;
            
            var tangentialForceX:Number = radialX;
            var tangentialForceY:Number = radialY;
            var newY:Number = tangentialForceX;
            tangentialForceX = -tangentialForceY * m_tangentialAcceleration;
            tangentialForceY = newY * m_tangentialAcceleration;
            
            const radialForceX:Number = radialX * m_radialAcceleration;
            const radialForceY:Number = radialY * m_radialAcceleration;
            
            particle.xVelocity += (radialForceX + tangentialForceX) * time;
            particle.yVelocity += (radialForceY + tangentialForceY) * time;
        }
    }
}