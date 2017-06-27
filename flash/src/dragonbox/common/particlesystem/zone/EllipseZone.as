package dragonbox.common.particlesystem.zone
{
    import dragonbox.common.particlesystem.Particle;
    
    import flash.geom.Point;
    
    public class EllipseZone implements IZone
    {
        public function EllipseZone()
        {
        }
        
        public function contains(x:Number, y:Number):Boolean
        {
            return false;
        }
        
        public function getLocation():Point
        {
            return null;
        }
        
        public function getArea():Number
        {
            return 0;
        }
        
        public function collideParticle(particle:Particle, bounce:Number=1):Boolean
        {
            return false;
        }
    }
}