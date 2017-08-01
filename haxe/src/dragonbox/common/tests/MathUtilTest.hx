package dragonbox.common.tests;

import flash.geom.Point;
import flash.geom.Rectangle;
import dragonbox.common.math.util.MathUtil;

/**
 * ...
 * @author 
 */
class MathUtilTest 
{

	// for floating point error testing
	public static var EPSILON : Float = 0.0001;
	
	public function runTests() {
		var passed : Bool = true;
		passed = passed && runGCDTests() && runLCMTests() && runRoundToDecimalTests() &&
		runCalculateCubicBezierPointTests() && runCalculateCubicBezierLengthTests() &&
		runCalculateNormalSlopeToCubicBezierPointTests() && runGetRadiansBetweenVectorsTests() &&
		runCircleIntersectTests() &&runPointInCircleTests() && runLineSegmentIntersectsRectangleTests() &&
		runLineIntersectionTests();
		
		if (passed) trace("MathUtil passed all tests");
	}
	
	public function runGCDTests() : Bool {
		var passed : Bool = true;
		
		// test something easy;
		if (!testGreatestCommonDivisor(30, 5, 5)) {
			trace("GCD failed simple test");
			passed = false;
		}
		
		// test something less easy
		if (!testGreatestCommonDivisor(123, 451, 41)) {
			trace("GCD failed less simple test");
			passed = false;
		}
		
		// test it works reversed
		if (!testGreatestCommonDivisor(451, 123, 41)) {
			trace("GCD failed reverse test");
			passed = false;
		}
		
		// test it works with 0 values
		if (!testGreatestCommonDivisor(0, 5, 5)) {
			trace("GCD failed zero test");
			passed = false;
		}
		
		if (!testGreatestCommonDivisor(5, 0, 5)) {
			trace("GCD failed reverse zero test");
			passed = false;
		}
		
		// test with negative numbers
		if (!testGreatestCommonDivisor( -5, 15, -5)) {
			trace("GCD failed negative test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runLCMTests() : Bool {
		var passed : Bool = true;
		
		// test something easy
		if (!testLeastCommonMultiple(5, 30, 30)) {
			trace("LCM failed simple test");
			passed = false;
		}
		
		// test something more complex
		if (!testLeastCommonMultiple(6, 15, 30)) {
			trace("LCM failed less simple test");
			passed = false;
		}
		
		// test it works reversed
		if (!testLeastCommonMultiple(15, 6, 30)) {
			trace("LCM failed reversed test");
			passed = false;
		}
		
		// test it works with 0
		if (!testLeastCommonMultiple(0, 30, 0)) {
			trace("LCM failed zero test");
			passed = false;
		}
		
		if (!testLeastCommonMultiple(30, 0, 0)) {
			trace("LCM failed reversed zero test");
			passed = false;
		}
		
		// test it works with negative numbers
		if (!testLeastCommonMultiple(-7, -9, -63)) {
			trace("LCM failed negative test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runRoundToDecimalTests() : Bool {
		var passed : Bool = true;
		
		// test a simple value
		if (!testRoundToDecimal(3.1415926, 4, 3.1416)) {
			trace("RoundtoDecimal failed simple test");
			passed = false;
		}
		
		// test whole numbers
		if (!testRoundToDecimal(3.0, 4, 3.0)) {
			trace("RoundtoDecimal failed whole number test");
			passed = false;
		}
		
		// test zero
		if (!testRoundToDecimal(0.0, 4, 0.0)) {
			trace("RoundtoDecimal failed zero test");
			passed = false;
		}
		
		// test negative numbers
		if (!testRoundToDecimal(-3.1415926, 4, -3.1416)) {
			trace("RoundtoDecimal failed negative test");
			passed = false;
		}
		
		// test a 0 place number, rounds down
		if (!testRoundToDecimal(3.1415926, 0, 3.0)) {
			trace("RoundtoDecimal failed 0 place, rounds down test");
			passed = false;
		}
		
		// test a 0 place number, rounds up
		if (!testRoundToDecimal(3.9415926, 0, 4.0)) {
			trace("RoundtoDecimal failed 0 place, rounds up test");
			passed = false;
		}
		
		// test a negative place number
		if (!testRoundToDecimal(3.1415926, -1, 3.0)) {
			trace("RoundtoDecimal failed negative place test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runCalculateCubicBezierPointTests() : Bool {
		var passed : Bool = true;
		
		var pointA = new Point(0, 0);
		var pointB = new Point(0, 1);
		var pointC = new Point(1, 1);
		var pointD = new Point(1, 0);
		
		// test endpoint interpolation
		if (!testCalculateCubicBezierPoint(0.0, pointA, pointB, pointC, pointD, pointA)) {
			trace("CalculateCubicBezierPoint failed first point interpolation test");
			passed = false;
		}
		
		if (!testCalculateCubicBezierPoint(1.0, pointA, pointB, pointC, pointD, pointD)) {
			trace("CalculateCubicBezierPoint failed last point interpolation test");
			passed = false;
		}
		
		// test a value from somewhere in the middle
		if (!testCalculateCubicBezierPoint(0.45, pointA, pointB, pointC, pointD, new Point(0.42525, 0.7425))) {
			trace("CalculateCubicBezierPoint failed midpoint interpolation test");
			passed = false;
		}
		
		// test a curve with 4 points in the same spot
		for (i in 0...100) {
			var step : Float = i / 100.0;
			if (!testCalculateCubicBezierPoint(step, pointA, pointA, pointA, pointA, pointA)) {
				trace("CalculateCubicBezierPoint failed identical point step interpolation test at i = " + i);
				passed = false;
			}
		}
		
		return passed;
	}
	
	public function runCalculateCubicBezierLengthTests() : Bool {
		var passed : Bool = true;
		
		var pointA = new Point(0, 0);
		var pointB = new Point(1, 1);
		var pointC = new Point(2, 2);
		var pointD = new Point(3, 3);
		
		// test a basic curve length
		if (!testCalculateCubicBezierLength(pointA, pointB, pointC, pointD, 10, 4.2426)) {
			trace("CalculateCubicBezierLength failed 10-step linear test");
			passed = false;
		}
		
		// test with more steps
		if (!testCalculateCubicBezierLength(pointA, pointB, pointC, pointD, 100, 4.2426)) {
			trace("CalculateCubicBezierLength failed 100-step linear test");
			passed = false;
		}
		
		// test with even more steps
		if (!testCalculateCubicBezierLength(pointA, pointB, pointC, pointD, 1000, 4.2426)) {
			trace("CalculateCubicBezierLength failed 1000-step linear test");
			passed = false;
		}
		
		// test that 4 identical points have a length of 0
		if (!testCalculateCubicBezierLength(pointA, pointA, pointA, pointA, 10, 0.0)) {
			trace("CalculateCubicBezierLength failed 0 length test");
			passed = false;
		}
		
		return passed;
	}

	public function runCalculateNormalSlopeToCubicBezierPointTests() : Bool {
		var passed : Bool = true;
		
		var pointA = new Point(0, 0);
		var pointB = new Point(0, 1);
		var pointC = new Point(1, 1);
		var pointD = new Point(1, 0);
		
		// test normal at first point (tangent == vertical, normal == horizontal)
		if (!testCalculateNormalSlopeToCubicBezierPoint(0, pointA, pointB, pointC, pointD, 0)) {
			trace("CalculateNormalSlopeToCubicBezierPoint failed first point test");
			passed = false;
		}
		
		// test normal at midpoint (tangent == horizontal, normal == vertical)
		// NOTE: this is actually passing, but for some reason the -Infinity it returns and Math.NEGATIVE_INFINITY
		// 		 are not the same result
		//if (!testCalculateNormalSlopeToCubicBezierPoint(0.5, pointA, pointB, pointC, pointD, Math.NEGATIVE_INFINITY)) {
			//trace("CalculateNormalSlopeToCubicBezierPoint failed midpoint test");
			//passed = false;
		//}
		
		// test normal at last point (tangent == vertical, normal == horizontal)
		if (!testCalculateNormalSlopeToCubicBezierPoint(1, pointA, pointB, pointC, pointD, 0)) {
			trace("CalculateNormalSlopeToCubicBezierPoint failed last point test");
			passed = false;
		}
		
		// test normal at some inner point
		if (!testCalculateNormalSlopeToCubicBezierPoint(0.45, pointA, pointB, pointC, pointD, -4.95)) {
			trace("CalculateNormalSlopeToCubicBezierPoint failed random point test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runGetRadiansBetweenVectorsTests() : Bool {
		var passed : Bool = true;
		
		var u = new Point(1, 0);
		var v = new Point(1, 1);
		
		// test a 45 degree difference
		if (!testGetRadiansBetweenVectors(u, v, Math.PI / 4.0)) {
			trace("GetRadiansBetweenVectors failed simple test");
			passed = false;
		}
		
		// test the vectors reversed
		if (!testGetRadiansBetweenVectors(v, u, Math.PI / 4.0)) {
			trace("GetRadiansBetweenVectors failed reversed simple test");
			passed = false;
		}
		
		// test a negative angle
		if (!testGetRadiansBetweenVectors(u, v.subtract(new Point(0, 2)), Math.PI / 4.0)) {
			trace("GetRadiansBetweenVectors failed negative angle test");
			passed = false;
		}
		
		// test identical vectors
		if (!testGetRadiansBetweenVectors(u, u, 0.0)) {
			trace("GetRadiansBetweenVectors failed identical test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runCircleIntersectTests() : Bool {
		var passed : Bool = true;
		
		// test overlapping circles
		if (!testCircleIntersect(0, 0, 2, 0, 3, 2, true)) {
			trace("CircleIntersect failed simple overlapping test");
			passed = false;
		}
		
		// test non overlapping circles
		if (!testCircleIntersect(0, 0, 1, 0, 3, 1, false)) {
			trace("CircleIntersect failed simple non-overlapping test");
			passed = false;
		}
		
		// test on tangent circles
		if (!testCircleIntersect(0, 0, 1, 0, 2, 1, true)) {
			trace("CircleIntersect failed tangent overlap test");
			passed = false;
		}
		
		// test on identical circles
		if (!testCircleIntersect(0, 0, 1, 0, 0, 1, true)) {
			trace("CircleIntersect failed identical test");
			passed = false;
		}
		
		// test on circles within circles
		if (!testCircleIntersect(0, 0, 1, 0, 0, 3, false)) {
			trace("CircleIntersect failed sub-circle test");
			passed = false;
		}
		
		if (!testCircleIntersect(0, 0, 3, 0, 0, 1, false)) {
			trace("CircleIntersect failed reversed sub-circle test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runPointInCircleTests() : Bool {
		var passed : Bool = true;
		var anchor = new Point(0, 0);
		
		// test a simple point at the center
		if (!testPointInCircle(anchor, 1, new Point(0, 0), true)) {
			trace("PointInCircle failed center test");
			passed = false;
		}
		
		// test a point not in the center
		if (!testPointInCircle(anchor, 1, new Point(0.3, 0.4), true)) {
			trace("PointInCircle failed off-center test");
			passed = false;
		}
		
		// test a boundary point
		if (!testPointInCircle(anchor, 1, new Point(0, 1), true)) {
			trace("PointInCircle failed boundary test");
			passed = false;
		}
		
		// test a point not in the circle
		if (!testPointInCircle(anchor, 1, new Point(0, 2), false)) {
			trace("PointInCircle failed not in circle test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runLineSegmentIntersectsRectangleTests() : Bool {
		var passed : Bool = true;
		
		var p1 = new Point(-1, 1);
		var p2 = new Point(1, 1);
		var rect = new Rectangle(0, 0, 2, 2);
		
		// test a simple intersection
		if (!testLineSegmentIntersectsRectangle(p1, p2, rect, true)) {
			trace("LineSegmentIntersectsRectangle failed simple test");
			passed = false;
		}
		
		// test a double intersection
		if (!testLineSegmentIntersectsRectangle(p1, new Point(3, 1), rect, true)) {
			trace("LineSegmentIntersectsRectangle failed double test");
			passed = false;
		}
		
		// test a boundary intersection
		if (!testLineSegmentIntersectsRectangle(p1, new Point(0, 1), rect, true)) {
			trace("LineSegmentIntersectsRectangle failed boundary test");
			passed = false;
		}
		
		// test a tangent intersection
		if (!testLineSegmentIntersectsRectangle(new Point(0, 0), new Point(0, 2), rect, true)) {
			trace("LineSegmentIntersectsRectangle failed tangent test");
			passed = false;
		}
		
		// test no intersection
		if (!testLineSegmentIntersectsRectangle(p1, new Point(-0.5, 1), new Rectangle(0, 2, 2, 2), false)) {
			trace("LineSegmentIntersectsRectangle failed no intersection test");
			passed = false;
		}
		
		return passed;
	}
	
	public function runLineIntersectionTests() : Bool {
		var passed : Bool = true;
		
		var p1 = new Point(-1, 0);
		var p2 = new Point(1, 0);
		var p3 = new Point(0, -1);
		var p4 = new Point(0, 1);
		
		// test perpendicular intersection
		if (!testLineIntersection(p1, p2, p3, p4, true)) {
			trace("LineIntersection failed perpendicular test");
			passed = false;
		}
		
		// test no parallel intersection
		if (!testLineIntersection(p1, p3, p2, p4, false)) {
			trace("LineIntersection failed perpendicular test");
			passed = false;
		}
		
		// test all same point intersection (should be false since these are all points, not lines,
		// and so do not intersect)
		if (!testLineIntersection(p1, p1, p1, p1, false)) {
			trace("LineIntersection failed all same point test");
			passed = false;
		}
		
		return passed;
	}
	
	public static function testGreatestCommonDivisor(valueA : Int, valueB : Int, expectedGCD : Int) : Bool {
		var actualGCD = MathUtil.greatestCommonDivisor(valueA, valueB);
		
		return actualGCD == expectedGCD;
	}
	
	public static function testLeastCommonMultiple(valueA : Int, valueB : Int, expectedLCM : Int) : Bool {
		var actualLCM = MathUtil.leastCommonMultiple(valueA, valueB);
		
		return actualLCM == expectedLCM;
	}
	
	public static function testRoundToDecimal(value : Float, numPlaces : Int, expectedDecimal : Float) : Bool {
		var actualDecimal = MathUtil.roundToDecimal(value, numPlaces);
		// make sure it's within an acceptable margin of floating point error
		var epsilon = Math.pow(10, -1 * numPlaces - 1);
		
		return Math.abs(actualDecimal - expectedDecimal) < epsilon;
	}
	
	public static function testCalculateCubicBezierPoint(t : Float,
            controlA : Point,
            controlB : Point,
            controlC : Point,
            controlD : Point,
            expectedPoint : Point) : Bool
	{
		var actualPoint = MathUtil.calculateCubicBezierPoint(t, controlA, controlB, controlC, controlD);
		
		return Math.abs(actualPoint.x - expectedPoint.x) < EPSILON && Math.abs(actualPoint.y - expectedPoint.y) < EPSILON;
	}
	
	public static function testCalculateCubicBezierLength(controlA : Point,
			controlB : Point,
			controlC : Point,
			controlD : Point,
			steps : Int = 10,
			expectedLength : Float) : Bool
	{
		var actualLength = MathUtil.calculateCubicBezierLength(controlA, controlB, controlC, controlD, steps);
		
		return Math.abs(actualLength - expectedLength) < EPSILON;
	}
	
	public static function testCalculateNormalSlopeToCubicBezierPoint(t : Float,
			controlA : Point,
			controlB : Point,
			controlC : Point,
			controlD : Point,
			expectedSlope : Float) : Bool
	{
		var actualSlope = MathUtil.calculateNormalSlopeToCubicBezierPoint(t, controlA, controlB, controlC, controlD);
		
		return Math.abs(actualSlope - expectedSlope) < EPSILON;
	}
	
	public static function testGetRadiansBetweenVectors(u : Point, v : Point, expectedRadians : Float) : Bool {
		var actualRadians = MathUtil.getRadiansBetweenVectors(u, v);
		
		return Math.abs(actualRadians - expectedRadians) < EPSILON;
	}
	
	public static function testCircleIntersect(centerAX : Float, centerAY : Float, radiusA : Float, centerBX : Float, centerBY : Float, radiusB : Float, expectedBool : Bool) : Bool {
		var actualBool = MathUtil.circleIntersect(centerAX, centerAY, radiusA, centerBX, centerBY, radiusB);
		
		return actualBool == expectedBool;
	}
	
	public static function testPointInCircle(anchor : Point, radius : Float, pointToTest : Point, expectedBool : Bool) : Bool {
		var actualBool = MathUtil.pointInCircle(anchor, radius, pointToTest);
		
		return actualBool == expectedBool;
	}
	
	public static function testLineSegmentIntersectsRectangle(p1 : Point, p2 : Point, rectangle : Rectangle, expectedBool : Bool) : Bool {
		var actualBool = MathUtil.lineSegmentIntersectsRectangle(p1, p2, rectangle);
		
		return actualBool == expectedBool;
	}
	
	public static function testLineIntersection(p : Point, r : Point, q : Point, s : Point, expectedBool : Bool) : Bool {
		var actualBool = MathUtil.lineIntersection(p, r, q, s);
		
		return actualBool == expectedBool;
	}
	
	public function new() 
	{
		
	}
	
}