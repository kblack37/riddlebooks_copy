package dragonbox.common.particlesystem.zone;


import flash.geom.Point;

import dragonbox.common.particlesystem.Particle;

class PointZone implements IZone
{
    private var m_point : Point;
    
    public function new(x : Float, y : Float)
    {
        m_point = new Point(x, y);
    }
    
    public function contains(x : Float, y : Float) : Bool
    {
        return m_point.x == x && m_point.y == y;
    }
    
    public function getLocation() : Point
    {
        return m_point;
    }
    
    public function getArea() : Float
    {
        return 1;
    }
    
    public function collideParticle(particle : Particle, bounce : Float = 1) : Bool
    {
        return false;
    }
}
