package dragonbox.common.particlesystem.zone;

import dragonbox.common.particlesystem.zone.IZone;

import flash.geom.Point;

import dragonbox.common.particlesystem.Particle;

/**
 * By default represents a ring region.
 * 
 * By adjusting the radius ratio it can be made into an ellipse
 */
class DiskZone implements IZone
{
    private static var TWO_PI : Float = Math.PI * 2;
    
    private var m_center : Point;
    private var m_outerHorizontalRadius : Float;
    private var m_outerHorizontalRadiusSquared : Float;
    private var m_outerVerticalRadius : Float;
    private var m_outerVerticalRadiusSquared : Float;
    private var m_outerEllipseProduct : Float;
    
    private var m_innerHorizontalRadius : Float;
    private var m_innerHorizontalRadiusSquared : Float;
    private var m_innerVerticalRadius : Float;
    private var m_innerVerticalRadiusSquared : Float;
    private var m_innerEllipseProduct : Float;
    
    private var m_innerOuterRatio : Float;
    
    private var m_horizontalToVerticalRadiusRatio : Float;
    
    /**
     * @param radiusRatio
     *      How much larger is the vertical radius of the ellipse compared to the horizontal region
     *      If it is one we get a perfectly circular shape, otherwise the specified radii give us the horizontal radius
     */
    public function new(centerX : Float,
            centerY : Float,
            outerRadius : Float,
            innerRadius : Float,
            radiusRatio : Float)
    {
        reset(centerX, centerY, outerRadius, innerRadius, radiusRatio);
    }
    
    public function reset(centerX : Float,
            centerY : Float,
            outerRadius : Float,
            innerRadius : Float,
            radiusRatio : Float) : Void
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
    
    public function contains(x : Float, y : Float) : Bool
    {
        var deltaX : Float = x - m_center.x;
        var deltaY : Float = y - m_center.y;
        var deltaXSquared : Float = deltaX * deltaX;
        var deltaYSquared : Float = deltaY * deltaY;
        
        var outsideInner : Bool = ((m_innerHorizontalRadiusSquared > 0 && m_innerVerticalRadiusSquared > 0)) ? 
        (deltaXSquared / m_innerHorizontalRadiusSquared) + (deltaYSquared / m_innerVerticalRadiusSquared) > 1 : true;
        return outsideInner && (deltaXSquared / m_outerHorizontalRadiusSquared) + (deltaYSquared / m_outerVerticalRadiusSquared) <= 1;
    }
    
    public function getLocation() : Point
    {
        var random : Float = Math.random();
        
        // Pick a random point inside a unit circle
        var randomLength : Float = random * (1 - m_innerOuterRatio) + m_innerOuterRatio;
        
        var point : Point = Point.polar(
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
    
    public function getArea() : Float
    {
        return Math.PI * (m_outerEllipseProduct - m_innerEllipseProduct);
    }
    
    public function collideParticle(particle : Particle, bounce : Float = 1) : Bool
    {
        return false;
    }
}
