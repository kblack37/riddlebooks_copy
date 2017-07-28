package;

import dragonbox.common.tests.MathUtilTest;
import starling.core.Starling;
import starling.display.Sprite;

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
		
		test_starling = new Starling(TestApp, stage);
		test_starling.start();
	}

}
