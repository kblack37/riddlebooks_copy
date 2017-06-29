package dragonbox.common.particlesystem.zone;

import dragonbox.common.particlesystem.zone.IZone;

import flash.geom.Point;

import dragonbox.common.particlesystem.Particle;

class DiskSectionZone implements IZone
{
    private var m_center : Point;
    private var m_outerRadius : Float;
    private var m_outRadiusSquared : Float;
    private var m_innerRadius : Float;
    private var m_innerRadiusSquared : Float;
    private var m_startAngleRad : Float;
    private var m_endAngleRad : Float;
    
    /**
     * The angles are measured relative to the 'positive x axis' and increases going
     * clockwise. ex.) pi/2 points in the positive y axis according to flash coordinates.
     */
    public function new(centerX : Float,
            centerY : Float,
            outerRadius : Float,
            innerRadius : Float,
            startAngleRad : Float,
            endAngleRad : Float)
    {
        m_center = new Point(centerX, centerY);
        m_outerRadius = outerRadius;
        m_outRadiusSquared = outerRadius * outerRadius;
        m_innerRadius = innerRadius;
        m_innerRadiusSquared = innerRadius * innerRadius;
        m_startAngleRad = startAngleRad;
        m_endAngleRad = endAngleRad;
    }
    
    public function contains(x : Float, y : Float) : Bool
    {
        var containedInZone : Bool;
        x -= m_center.x;
        y -= m_center.y;
        var distanceSquared : Float = x * x + y * y;
        if (distanceSquared > m_outerRadius || distanceSquared < m_innerRadius) 
        {
            containedInZone = false;
        }
        else 
        {
            var angle : Float = Math.atan2(y, x);
            containedInZone = angle >= m_startAngleRad;
        }
        return containedInZone;
    }
    
    public function getLocation() : Point
    {
        var random : Float = Math.random();
        var point : Point = Point.polar(
                m_innerRadius + (1 - random * random) * (m_outerRadius - m_innerRadius),
                m_startAngleRad + Math.random() * (m_endAngleRad - m_startAngleRad)
                );
        return point;
    }
    
    public function getArea() : Float
    {
        return (m_outRadiusSquared - m_innerRadiusSquared) * (m_endAngleRad - m_startAngleRad) * 0.5;
    }
    
    public function collideParticle(particle : Particle, bounce : Float = 1) : Bool
    {
        return false;
    }
}
