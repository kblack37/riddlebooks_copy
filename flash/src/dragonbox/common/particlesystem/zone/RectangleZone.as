package dragonbox.common.particlesystem.zone
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.particlesystem.Particle;
    
    public class RectangleZone implements IZone
    {
        private var m_rectangle:Rectangle;
        
        public function RectangleZone(topLeftX:Number, topLeftY:Number, width:Number, height:Number)
        {
            m_rectangle = new Rectangle();
            this.reset(topLeftX, topLeftY, width, height);
        }
        
        public function reset(topLeftX:Number, topLeftY:Number, width:Number, height:Number):void
        {
            m_rectangle.setTo(topLeftX, topLeftY, width, height);
        }
        
        public function contains(x:Number, y:Number):Boolean
        {
            return m_rectangle.contains(x, y);
        }
        
        public function getLocation():Point
        {
            return new Point(m_rectangle.left + Math.random() * m_rectangle.width,
                m_rectangle.top + Math.random() * m_rectangle.height);
        }
        
        public function getArea():Number
        {
            return m_rectangle.width * m_rectangle.height;
        }
        
        public function collideParticle(particle:Particle, bounce:Number=1):Boolean
        {
            return false;
        }
    }
}