package dragonbox.common.particlesystem.zone;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.particlesystem.Particle;

class RectangleZone implements IZone
{
    private var m_rectangle : Rectangle;
    
    public function new(topLeftX : Float, topLeftY : Float, width : Float, height : Float)
    {
        m_rectangle = new Rectangle();
        this.reset(topLeftX, topLeftY, width, height);
    }
    
    public function reset(topLeftX : Float, topLeftY : Float, width : Float, height : Float) : Void
    {
        m_rectangle.setTo(topLeftX, topLeftY, width, height);
    }
    
    public function contains(x : Float, y : Float) : Bool
    {
        return m_rectangle.contains(x, y);
    }
    
    public function getLocation() : Point
    {
        return new Point(m_rectangle.left + Math.random() * m_rectangle.width, 
        m_rectangle.top + Math.random() * m_rectangle.height);
    }
    
    public function getArea() : Float
    {
        return m_rectangle.width * m_rectangle.height;
    }
    
    public function collideParticle(particle : Particle, bounce : Float = 1) : Bool
    {
        return false;
    }
}
