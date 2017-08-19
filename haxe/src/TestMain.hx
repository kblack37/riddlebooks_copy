package;

import dragonbox.common.tests.MathUtilTest;
import openfl.Lib;

import openfl.display.Sprite;
import openfl.events.Event;

/**
 * ...
 * @author 
 */
class TestMain extends Sprite {
	
	public static function main() {
		// Before starting, run tests on MathUtil
		var mathUtilTests = new MathUtilTest();
		mathUtilTests.runTests();
		
		Lib.current.addChild(new TestApp());
	}

}
