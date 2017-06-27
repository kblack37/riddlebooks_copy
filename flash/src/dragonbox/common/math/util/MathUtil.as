package dragonbox.common.math.util
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

	public class MathUtil
	{
		public static function greatestCommonDivisor(valueA:int, valueB:int):int
		{
			var divisor:int;
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
        
        public static function leastCommonMultiple(valueA:int, valueB:int):int
        {
            return (valueA * valueB) / MathUtil.greatestCommonDivisor(valueA, valueB);
        }
        
        /**
         * Given a number round it to the given decimal place
         * 
         * @param numPlaces
         *      The decimal place to round to, for example if this is 2 then the number is
         *      rounded to the hundreths place
         */
        public static function roundToDecimal(value:Number, numPlaces:int):Number
        {
            var roundedValue:Number = Math.floor(value);
            var decimalAmount:Number = value - roundedValue;
            
            var multiplier:Number = Math.pow(10, numPlaces);
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
        public static function calculateCubicBezierPoint(t:Number, 
                                                         controlA:Point, 
                                                         controlB:Point, 
                                                         controlC:Point, 
                                                         controlD:Point, 
                                                         outPoint:Point=null):Point
        {
            if (outPoint == null)
            {
                outPoint = new Point();
            }
            
            var u:Number = 1 - t;
            var tt:Number = t * t;
            var ttt:Number = tt * t;
            var uu:Number = u * u;
            var uuu:Number = uu * u;
            
            var x:Number = uuu * controlA.x + 
                3 * uu * t * controlB.x +
                3 * u * tt * controlC.x +
                ttt * controlD.x;
            var y:Number = uuu * controlA.y + 
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
        public static function calculateCubicBezierLength(controlA:Point, 
                                                          controlB:Point, 
                                                          controlC:Point, 
                                                          controlD:Point,
                                                          steps:Number=10.0):Number
        {
            // Just sum up the length of several lines at different points in the curve
            var length:Number = 0;
            var i:int;
            var prevPointBuffer:Point = new Point();
            var pointBuffer:Point = new Point();
            for (i = 0; i < steps; i++)
            {
                var t:Number = i / steps;
                MathUtil.calculateCubicBezierPoint(t, controlA, controlB, controlC, controlD, pointBuffer);
                
                if (i > 0)
                {
                    var deltaX:Number = pointBuffer.x - prevPointBuffer.x;
                    var deltaY:Number = pointBuffer.y - prevPointBuffer.y;
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
        public static function calculateNormalSlopeToCubicBezierPoint(t:Number, 
                                                                      controlA:Point, 
                                                                      controlB:Point, 
                                                                      controlC:Point, 
                                                                      controlD:Point):Number
        {
            // The tangent of a cubic bezier curve is
            // -3*(1-t)^2 * P0 + (3*(1-t)^2 - 6 * (1-t)*t)*P1  + (6 * (1 - t) * t - 3*t^2)*P2 + 3 * t^2 * P3
            var u:Number = 1 - t;
            var uu:Number = u * u;
            var tt:Number = t * t;
            
            var tangentX:Number = -3 * uu * controlA.x +
                (3 * uu - 6 * u * t) * controlB.x +
                (6 * u * t - 3 * tt) * controlC.x +
                3 * tt * controlD.x;
            var tangentY:Number = -3 * uu * controlA.y +
                (3 * uu - 6 * u * t) * controlB.y +
                (6 * u * t - 3 * tt) * controlC.y +
                3 * tt * controlD.y;
            var slope:Number = tangentY / tangentX;
            
            return (slope == 0 || tangentX == 0) ? -1 : -1 / slope;
        }
        
        /**
         * Use function
         * cos(alpha) = (u1*v1 + u2*v2) / (sqrt(u1^2+u2^2) + sqrt(v1^2 + v2^2))
         */
        public static function getRadiansBetweenVectors(u:Point, v:Point):Number
        {
            var uLength:Number = Math.sqrt(u.x * u.x + u.y * u.y);
            var vLength:Number = Math.sqrt(v.x * v.x + v.y * v.y);
            var cosineRadian:Number = (u.x * v.x + u.y * v.y) / (uLength * vLength);
            
            return Math.acos(cosineRadian);
        }
        
        /**
         * Function returns whether two circles intersect each other
         * Circles are defined by their center and radius.
         * 
         * @return
         *      true if the two circles do interect
         */
        public static function circleIntersect(centerAX:Number, centerAY:Number, radiusA:Number, centerBX:Number, centerBY:Number, radiusB:Number):Boolean
        {
            const deltaX:Number = centerAX - centerBX;
            const deltaY:Number = centerAY - centerBY;
            const distanceSquared:Number = deltaX * deltaX + deltaY * deltaY;
            
            const deltaRadius:Number = radiusA - radiusB;
            const sumRadius:Number = radiusA + radiusB;
            
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
        public static function pointInCircle(anchor:Point, 
                                             radius:Number, 
                                             pointToTest:Point):Boolean
        {
            var inCircle:Boolean = true;
            var deltaX:Number = pointToTest.x - anchor.x;
            var deltaY:Number = pointToTest.y - anchor.y;
            var distXYsquared:Number = deltaX * deltaX + deltaY * deltaY;
            var errorAllowedSquared:Number = radius * radius;
            if (distXYsquared > errorAllowedSquared)
            {
                inCircle = false;
            }
            
            return inCircle;
        }
        
        public static function lineSegmentIntersectsRectangle(p1:Point, 
                                                              p2:Point, 
                                                              rectangle:Rectangle):Boolean
        {
            var doesIntersect:Boolean = true;
            
            const topLeft:Point = rectangle.topLeft;
            const topRight:Point = new Point(topLeft.x + rectangle.width, topLeft.y);
            const bottomRight:Point = rectangle.bottomRight;
            const bottomLeft:Point = new Point(bottomRight.x - rectangle.width, bottomRight.y);
            
            // Line completely to right
            if (p1.x > topRight.x && p2.x > topRight.x)
            {
                doesIntersect = false;
            }
            
            // Line completely to left
            if (p1.x < bottomLeft.x && p2.x < bottomLeft.x)
            {
                doesIntersect = false;
            }
            
            // Line completely below
            if (p1.y > bottomLeft.y && p2.y > bottomLeft.y)
            {
                doesIntersect = false;
            }
            
            // Line completely above
            if (p1.y < topRight.y && p2.y < topRight.y)
            {
                doesIntersect = false;
            }
            
            // Check if corners are on the same side
            if (doesIntersect)
            {
                const tlValue:Number = lineThroughStartEnd(topLeft.x, topLeft.y);
                const trValue:Number = lineThroughStartEnd(topRight.x, topRight.y);
                const brValue:Number = lineThroughStartEnd(bottomRight.x, bottomRight.y);
                const blValue:Number = lineThroughStartEnd(bottomLeft.x, bottomLeft.y);
                if (tlValue > 0 && trValue > 0 && brValue > 0 && blValue > 0 ||
                    tlValue < 0 && trValue < 0 && brValue < 0 && blValue < 0)
                {
                    doesIntersect = false;
                }
            }
            
            function lineThroughStartEnd(x:Number, y:Number):Number
            {
                return (p2.y - p1.y) * x + (p1.x - p2.x) * y +
                    (p2.x * p1.y - p1.x * p2.y);
            }
            
            return doesIntersect;
        }
        
        public static function lineIntersection(p:Point, r:Point, q:Point, s:Point):Boolean
        {
            // intersections occurs if we can find t and u such that
            // p + t * r = q + u * s
            // Solving this out we are trying to calculate
            // t = (q-p) <cross> s / (r <cross> s)
            // u = (q-p) <cross> r / (r <cross> s)
            // where t and u are between zero and one
            var doIntersect:Boolean = false;
            var rsCross:Number = r.x * s.y - r.y * s.x;
            
            // If cross product between r and s is zero than the lines are
            // parallel
            if (rsCross != 0)
            {
                var qpDiffX:Number = q.x - p.x;
                var qpDiffY:Number = q.y - p.y;
                var t:Number = (qpDiffX * s.y - qpDiffY * s.x) / rsCross;
                var u:Number = (qpDiffX * r.y - qpDiffY * r.x) / rsCross;
                doIntersect = (t >= 0 && t <= 1) && (u >= 0 && u <= 1);
            }
            
            return doIntersect;
        }
	}
}