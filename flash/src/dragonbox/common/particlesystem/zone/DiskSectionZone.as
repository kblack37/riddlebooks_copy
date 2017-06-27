package dragonbox.common.particlesystem.zone
{
    import flash.geom.Point;
    
    import dragonbox.common.particlesystem.Particle;
    
    public class DiskSectionZone implements IZone
    {
        private var m_center:Point;
        private var m_outerRadius:Number;
        private var m_outRadiusSquared:Number;
        private var m_innerRadius:Number;
        private var m_innerRadiusSquared:Number;
        private var m_startAngleRad:Number;
        private var m_endAngleRad:Number;
        
        /**
         * The angles are measured relative to the 'positive x axis' and increases going
         * clockwise. ex.) pi/2 points in the positive y axis according to flash coordinates.
         */
        public function DiskSectionZone(centerX:Number,
                                        centerY:Number,
                                        outerRadius:Number, 
                                        innerRadius:Number, 
                                        startAngleRad:Number, 
                                        endAngleRad:Number)
        {
            m_center = new Point(centerX, centerY);
            m_outerRadius = outerRadius;
            m_outRadiusSquared = outerRadius * outerRadius;
            m_innerRadius = innerRadius;
            m_innerRadiusSquared = innerRadius * innerRadius;
            m_startAngleRad = startAngleRad;
            m_endAngleRad = endAngleRad;
        }
        
        public function contains(x:Number, y:Number):Boolean
        {
            var containedInZone:Boolean;
            x -= m_center.x;
            y -= m_center.y;
            const distanceSquared:Number = x * x + y * y;
            if (distanceSquared > m_outerRadius || distanceSquared < m_innerRadius)
            {
                containedInZone = false;
            }
            else
            {
                const angle:Number = Math.atan2(y, x);
                containedInZone = angle >= m_startAngleRad;
            }
            return containedInZone;
        }
        
        public function getLocation():Point
        {
            const random:Number = Math.random();
            const point:Point = Point.polar(
                m_innerRadius + (1 - random * random) * (m_outerRadius - m_innerRadius),
                m_startAngleRad + Math.random() * (m_endAngleRad - m_startAngleRad)
            );
            return point;
        }
        
        public function getArea():Number
        {
            return (m_outRadiusSquared - m_innerRadiusSquared) * (m_endAngleRad - m_startAngleRad) * 0.5;
        }
        
        public function collideParticle(particle:Particle, bounce:Number=1):Boolean
        {
            return false;
        }
    }
}