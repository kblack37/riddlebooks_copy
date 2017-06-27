package dragonbox.common.particlesystem.zone
{
    import flash.geom.Point;
    
    import dragonbox.common.particlesystem.Particle;
    
    public class LineZone implements IZone
    {
        private var m_startX:Number;
        private var m_startY:Number;
        private var m_endX:Number;
        private var m_endY:Number;
        private var m_lengthY:Number;
        private var m_lengthX:Number;
        private var m_length:Number;
        
        public function LineZone(startX:Number, startY:Number, endX:Number, endY:Number)
        {
            reset(startX, startY, endX, endY);
        }
        
        public function reset(startX:Number, startY:Number, endX:Number, endY:Number):void
        {
            m_startX = startX;
            m_startY = startY;
            m_endX = endX;
            m_endY = endY;
            
            m_lengthX = m_endX - m_startX;
            m_lengthY = m_endY - m_startY;
            m_length = Math.sqrt(m_lengthX * m_lengthX + m_lengthY * m_lengthY);
        }
        
        public function contains(x:Number, y:Number):Boolean
        {
            
            const diffX:Number = x - m_startX;
            const diffY:Number = y - m_startY;
            var containedInLine:Boolean = false;
            
            // Not on line if the dot product with the perpendicular is not zero
            if (diffX * m_lengthY - diffY * m_lengthX == 0)
            {
                // Otherwise need to check if the dot product of the vectors toward each
                // point is negative
                containedInLine = (diffX * (x - m_endX) + diffY * (y - m_endY) <= 0)
            }
            
            return containedInLine;
        }
        
        public function getLocation():Point
        {
            const scaleFactor:Number = Math.random();
            const x:Number = m_startX + m_lengthX * scaleFactor;
            const y:Number = m_startY + m_lengthY * scaleFactor;
            const location:Point = new Point(x, y);
            return location;
        }
        
        public function getArea():Number
        {
            // Treat it as a pixel tall rectangle
            return m_length;
        }
        
        public function collideParticle(particle:Particle, bounce:Number=1):Boolean
        {
            return false;
        }
    }
}