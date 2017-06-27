package dragonbox.common.particlesystem.zone
{
    import flash.geom.Point;
    
    import dragonbox.common.particlesystem.Particle;
    
    /**
     * By default represents a ring region.
     * 
     * By adjusting the radius ratio it can be made into an ellipse
     */
    public class DiskZone implements IZone
    {
        private static const TWO_PI:Number = Math.PI * 2;
        
        private var m_center:Point;
        private var m_outerHorizontalRadius:Number;
        private var m_outerHorizontalRadiusSquared:Number;
        private var m_outerVerticalRadius:Number;
        private var m_outerVerticalRadiusSquared:Number;
        private var m_outerEllipseProduct:Number;
        
        private var m_innerHorizontalRadius:Number;
        private var m_innerHorizontalRadiusSquared:Number;
        private var m_innerVerticalRadius:Number;
        private var m_innerVerticalRadiusSquared:Number;
        private var m_innerEllipseProduct:Number;
        
        private var m_innerOuterRatio:Number;
        
        private var m_horizontalToVerticalRadiusRatio:Number;
        
        /**
         * @param radiusRatio
         *      How much larger is the vertical radius of the ellipse compared to the horizontal region
         *      If it is one we get a perfectly circular shape, otherwise the specified radii give us the horizontal radius
         */
        public function DiskZone(centerX:Number,
                                 centerY:Number,
                                 outerRadius:Number, 
                                 innerRadius:Number, 
                                 radiusRatio:Number)
        {
            reset(centerX, centerY, outerRadius, innerRadius, radiusRatio);
        }
        
        public function reset(centerX:Number,
                              centerY:Number,
                              outerRadius:Number, 
                              innerRadius:Number, 
                              radiusRatio:Number):void
        {
            m_center = new Point(centerX, centerY);
            if (radiusRatio == 1.0)
            {
                m_outerHorizontalRadius = outerRadius;
                m_outerHorizontalRadiusSquared = outerRadius * outerRadius;
                
                m_outerVerticalRadius = outerRadius;
                m_outerVerticalRadiusSquared = m_outerHorizontalRadiusSquared;
                
                m_innerHorizontalRadius = innerRadius;
                m_innerHorizontalRadiusSquared = innerRadius * innerRadius;
                
                m_innerVerticalRadius = innerRadius;
                m_innerVerticalRadiusSquared = m_innerHorizontalRadiusSquared;
                
                m_outerEllipseProduct = outerRadius * outerRadius;
                m_innerEllipseProduct = innerRadius * innerRadius;
            }
            else
            {
                m_outerHorizontalRadius = outerRadius;
                m_outerHorizontalRadiusSquared = outerRadius * outerRadius;
                
                m_outerVerticalRadius = outerRadius * radiusRatio;
                m_outerVerticalRadiusSquared = m_outerVerticalRadius * m_outerVerticalRadius;
                
                m_innerHorizontalRadius = innerRadius;
                m_innerHorizontalRadiusSquared = innerRadius * innerRadius;
                
                m_innerVerticalRadius = innerRadius * radiusRatio;
                m_innerVerticalRadiusSquared = m_innerVerticalRadius * m_innerVerticalRadius;
                
                m_outerEllipseProduct = m_outerHorizontalRadius * m_outerVerticalRadius;
                m_innerEllipseProduct = m_innerHorizontalRadius * m_innerVerticalRadius;
            }
            
            m_innerOuterRatio = innerRadius / outerRadius;
        }
        
        public function contains(x:Number, y:Number):Boolean
        {
            const deltaX:Number = x - m_center.x;
            const deltaY:Number = y - m_center.y;
            const deltaXSquared:Number = deltaX * deltaX;
            const deltaYSquared:Number = deltaY * deltaY;
            
            const outsideInner:Boolean = (m_innerHorizontalRadiusSquared > 0 && m_innerVerticalRadiusSquared > 0) ?
                (deltaXSquared / m_innerHorizontalRadiusSquared) + (deltaYSquared / m_innerVerticalRadiusSquared) > 1 : true;
            return outsideInner && (deltaXSquared / m_outerHorizontalRadiusSquared) + (deltaYSquared / m_outerVerticalRadiusSquared) <= 1;
        }
        
        public function getLocation():Point
        {
            const random:Number = Math.random();
            
            // Pick a random point inside a unit circle
            const randomLength:Number = random * (1 - m_innerOuterRatio) + m_innerOuterRatio;
            
            const point:Point = Point.polar(
               randomLength,
                Math.random() * TWO_PI
            );
            
            // Stretch the point out
            point.x *= m_outerHorizontalRadius;
            point.y *= m_outerVerticalRadius;
            
            // Translate to the center
            point.x += m_center.x;
            point.y += m_center.y;
            return point;
        }
        
        public function getArea():Number
        {
            return Math.PI * (m_outerEllipseProduct - m_innerEllipseProduct);
        }
        
        public function collideParticle(particle:Particle, bounce:Number=1):Boolean
        {
            return false;
        }
    }
}