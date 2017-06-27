package dragonbox.common.particlesystem.zone
{
    import flash.geom.Point;
    
    import dragonbox.common.particlesystem.Particle;
    
    public class PointZone implements IZone
    {
        private var m_point:Point;
        
        public function PointZone(x:Number, y:Number)
        {
            m_point = new Point(x, y);
        }
        
        public function contains(x:Number, y:Number):Boolean
        {
            return m_point.x == x && m_point.y == y;
        }
        
        public function getLocation():Point
        {
            return m_point;
        }
        
        public function getArea():Number
        {
            return 1;
        }
        
        public function collideParticle(particle:Particle, bounce:Number=1):Boolean
        {
            return false;
        }
    }
}