package;

import dragonbox.common.tests.MathUtilTest;
import openfl.display.Sprite;
import starling.core.Starling;

/**
 * ...
 * @author 
 */
class TestMain extends Sprite {
	
	private var test_starling : Starling;
	
	public function new() 
	{
		super();
		
		// MathUtil tests
		var mathUtilTests = new MathUtilTest();
		mathUtilTests.runTests();
		
		test_starling = new Starling(TestApp, this.stage);
		test_starling.start();
	}

}
