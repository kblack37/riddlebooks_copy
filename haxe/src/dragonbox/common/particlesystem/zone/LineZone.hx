package dragonbox.common.particlesystem.zone;


import flash.geom.Point;

import dragonbox.common.particlesystem.Particle;

class LineZone implements IZone
{
    private var m_startX : Float;
    private var m_startY : Float;
    private var m_endX : Float;
    private var m_endY : Float;
    private var m_lengthY : Float;
    private var m_lengthX : Float;
    private var m_length : Float;
    
    public function new(startX : Float, startY : Float, endX : Float, endY : Float)
    {
        reset(startX, startY, endX, endY);
    }
    
    public function reset(startX : Float, startY : Float, endX : Float, endY : Float) : Void
    {
        m_startX = startX;
        m_startY = startY;
        m_endX = endX;
        m_endY = endY;
        
        m_lengthX = m_endX - m_startX;
        m_lengthY = m_endY - m_startY;
        m_length = Math.sqrt(m_lengthX * m_lengthX + m_lengthY * m_lengthY);
    }
    
    public function contains(x : Float, y : Float) : Bool
    {
        
        var diffX : Float = x - m_startX;
        var diffY : Float = y - m_startY;
        var containedInLine : Bool = false;
        
        // Not on line if the dot product with the perpendicular is not zero
        if (diffX * m_lengthY - diffY * m_lengthX == 0) 
        {
            // Otherwise need to check if the dot product of the vectors toward each
            // point is negative
            containedInLine = (diffX * (x - m_endX) + diffY * (y - m_endY) <= 0);
        }
        
        return containedInLine;
    }
    
    public function getLocation() : Point
    {
        var scaleFactor : Float = Math.random();
        var x : Float = m_startX + m_lengthX * scaleFactor;
        var y : Float = m_startY + m_lengthY * scaleFactor;
        var location : Point = new Point(x, y);
        return location;
    }
    
    public function getArea() : Float
    {
        // Treat it as a pixel tall rectangle
        return m_length;
    }
    
    public function collideParticle(particle : Particle, bounce : Float = 1) : Bool
    {
        return false;
    }
}
