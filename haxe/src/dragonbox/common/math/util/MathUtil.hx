package dragonbox.common.math.util;


import flash.geom.Point;
import flash.geom.Rectangle;

class MathUtil
{
    public static function greatestCommonDivisor(valueA : Int, valueB : Int) : Int
    {
        var divisor : Int = 0;
        if (valueB == 0) 
        {
            divisor = valueA;
        }
        else 
        {
            divisor = MathUtil.greatestCommonDivisor(valueB, valueA % valueB);
        }
        
        return divisor;
    }
    
    public static function leastCommonMultiple(valueA : Int, valueB : Int) : Int
    {
        return Std.int((valueA * valueB) / MathUtil.greatestCommonDivisor(valueA, valueB));
    }
    
    /**
     * Given a number round it to the given decimal place
     * 
     * @param numPlaces
     *      The decimal place to round to, for example if this is 2 then the number is
     *      rounded to the hundreths place
     */
    public static function roundToDecimal(value : Float, numPlaces : Int) : Float
    {
        var roundedValue : Float = Math.floor(value);
        var decimalAmount : Float = value - roundedValue;
        
        var multiplier : Float = Math.pow(10, numPlaces);
        decimalAmount *= multiplier;
        decimalAmount = Math.round(decimalAmount);
        decimalAmount /= multiplier;
        return roundedValue + decimalAmount;
    }
    
    /**
     * The function for a cubic bezier curve is
     * P=(1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)t^2*P2+t^3*P3
     * 
     * @param t
     *      Value between 0-1
     */
    public static function calculateCubicBezierPoint(t : Float,
            controlA : Point,
            controlB : Point,
            controlC : Point,
            controlD : Point,
            outPoint : Point = null) : Point
    {
        if (outPoint == null) 
        {
            outPoint = new Point();
        }
        
        var u : Float = 1 - t;
        var tt : Float = t * t;
        var ttt : Float = tt * t;
        var uu : Float = u * u;
        var uuu : Float = uu * u;
        
        var x : Float = uuu * controlA.x +
        3 * uu * t * controlB.x +
        3 * u * tt * controlC.x +
        ttt * controlD.x;
        var y : Float = uuu * controlA.y +
        3 * uu * t * controlB.y +
        3 * u * tt * controlC.y +
        ttt * controlD.y;
        outPoint.x = x;
        outPoint.y = y;
        
        return outPoint;
    }
    
    /**
     * Get an approximate length of a cubic bezier curve.
     */
    public static function calculateCubicBezierLength(controlA : Point,
            controlB : Point,
            controlC : Point,
            controlD : Point,
            steps : Int = 10) : Float
    {
        // Just sum up the length of several lines at different points in the curve
        var length : Float = 0;
        var i : Int = 0;
        var prevPointBuffer : Point = new Point();
        var pointBuffer : Point = new Point();
        for (i in 0...(steps + 1)){
            var t : Float = i / steps;
            MathUtil.calculateCubicBezierPoint(t, controlA, controlB, controlC, controlD, pointBuffer);
            
            if (i > 0) 
            {
                var deltaX : Float = pointBuffer.x - prevPointBuffer.x;
                var deltaY : Float = pointBuffer.y - prevPointBuffer.y;
                length += Math.sqrt(deltaX * deltaX + deltaY * deltaY);
            }
            
            prevPointBuffer.x = pointBuffer.x;
            prevPointBuffer.y = pointBuffer.y;
        }
        
        return length;
    }
    
    /**
     * A warning when converting to display coordinates, the increasing direction of y is flipped
     */
    public static function calculateNormalSlopeToCubicBezierPoint(t : Float,
            controlA : Point,
            controlB : Point,
            controlC : Point,
            controlD : Point) : Float
    {
        // The tangent of a cubic bezier curve is
        // -3*(1-t)^2 * P0 + (3*(1-t)^2 - 6 * (1-t)*t)*P1  + (6 * (1 - t) * t - 3*t^2)*P2 + 3 * t^2 * P3
        var u : Float = 1 - t;
        var uu : Float = u * u;
        var tt : Float = t * t;
        
        var tangentX : Float = -3 * uu * controlA.x +
        (3 * uu - 6 * u * t) * controlB.x +
        (6 * u * t - 3 * tt) * controlC.x +
        3 * tt * controlD.x;
        var tangentY : Float = -3 * uu * controlA.y +
        (3 * uu - 6 * u * t) * controlB.y +
        (6 * u * t - 3 * tt) * controlC.y +
        3 * tt * controlD.y;
        var slope : Float = tangentY / tangentX;
		
		return -1 / slope;
    }
    
    /**
     * Use function
     * cos(alpha) = (u1*v1 + u2*v2) / (sqrt(u1^2+u2^2) + sqrt(v1^2 + v2^2))
     */
    public static function getRadiansBetweenVectors(u : Point, v : Point) : Float
    {
        var uLength : Float = Math.sqrt(u.x * u.x + u.y * u.y);
        var vLength : Float = Math.sqrt(v.x * v.x + v.y * v.y);
        var cosineRadian : Float = (u.x * v.x + u.y * v.y) / (uLength * vLength);
        
        return Math.acos(cosineRadian);
    }
    
    /**
     * Function returns whether two circles intersect each other
     * Circles are defined by their center and radius.
     * 
     * @return
     *      true if the two circles do interect
     */
    public static function circleIntersect(centerAX : Float, centerAY : Float, radiusA : Float, centerBX : Float, centerBY : Float, radiusB : Float) : Bool
    {
        var deltaX : Float = centerAX - centerBX;
        var deltaY : Float = centerAY - centerBY;
        var distanceSquared : Float = deltaX * deltaX + deltaY * deltaY;
        
        var deltaRadius : Float = radiusA - radiusB;
        var sumRadius : Float = radiusA + radiusB;
        
        return (deltaRadius * deltaRadius) <= distanceSquared && distanceSquared <= (sumRadius * sumRadius);
    }
    
    /**
     * @param anchor
     *      The central point of the circle
     * @param radius
     *      Radius of circle extending from the anchor
     * @param pointToTest
     * @return
     *      True if the point to test falls within the circle created by the anchor and
     *      given radius.
     */
    public static function pointInCircle(anchor : Point,
            radius : Float,
            pointToTest : Point) : Bool
    {
        var inCircle : Bool = true;
        var deltaX : Float = pointToTest.x - anchor.x;
        var deltaY : Float = pointToTest.y - anchor.y;
        var distXYsquared : Float = deltaX * deltaX + deltaY * deltaY;
        var errorAllowedSquared : Float = radius * radius;
        if (distXYsquared > errorAllowedSquared) 
        {
            inCircle = false;
        }
        
        return inCircle;
    }
    
    public static function lineSegmentIntersectsRectangle(p1 : Point,
            p2 : Point,
            rectangle : Rectangle) : Bool
    {
        var doesIntersect : Bool = true;
        
        var topLeft : Point = rectangle.topLeft;
        var topRight : Point = new Point(topLeft.x + rectangle.width, topLeft.y);
        var bottomRight : Point = rectangle.bottomRight;
        var bottomLeft : Point = new Point(bottomRight.x - rectangle.width, bottomRight.y);
        
        // Line completely to right
        if (p1.x > topRight.x && p2.x > topRight.x) 
        {
            doesIntersect = false;
        }  // Line completely to left  
        
        
        
        if (p1.x < bottomLeft.x && p2.x < bottomLeft.x) 
        {
            doesIntersect = false;
        }  // Line completely below  
        
        
        
        if (p1.y > bottomLeft.y && p2.y > bottomLeft.y) 
        {
            doesIntersect = false;
        }  // Line completely above  
        
        
        
        if (p1.y < topRight.y && p2.y < topRight.y) 
        {
            doesIntersect = false;
        }  // Check if corners are on the same side  
        
		function lineThroughStartEnd(x : Float, y : Float) : Float
        {
            return (p2.y - p1.y) * x + (p1.x - p2.x) * y +
            (p2.x * p1.y - p1.x * p2.y);
        };
        
        if (doesIntersect) 
        {
            var tlValue : Float = lineThroughStartEnd(topLeft.x, topLeft.y);
            var trValue : Float = lineThroughStartEnd(topRight.x, topRight.y);
            var brValue : Float = lineThroughStartEnd(bottomRight.x, bottomRight.y);
            var blValue : Float = lineThroughStartEnd(bottomLeft.x, bottomLeft.y);
            if (tlValue > 0 && trValue > 0 && brValue > 0 && blValue > 0 ||
                tlValue < 0 && trValue < 0 && brValue < 0 && blValue < 0) 
            {
                doesIntersect = false;
            }
        }
        
        return doesIntersect;
    }
    
    public static function lineIntersection(p : Point, r : Point, q : Point, s : Point) : Bool
    {
        // intersections occurs if we can find t and u such that
        // p + t * r = q + u * s
        // Solving this out we are trying to calculate
        // t = (q-p) <cross> s / (r <cross> s)
        // u = (q-p) <cross> r / (r <cross> s)
        // where t and u are between zero and one
        var doIntersect : Bool = false;
        var rsCross : Float = r.x * s.y - r.y * s.x;
        
        // If cross product between r and s is zero than the lines are
        // parallel
        if (rsCross != 0) 
        {
            var qpDiffX : Float = q.x - p.x;
            var qpDiffY : Float = q.y - p.y;
            var t : Float = (qpDiffX * s.y - qpDiffY * s.x) / rsCross;
            var u : Float = (qpDiffX * r.y - qpDiffY * r.x) / rsCross;
            doIntersect = (t >= 0 && t <= 1) && (u >= 0 && u <= 1);
        }
        
        return doIntersect;
    }

    public function new()
    {
    }
}
