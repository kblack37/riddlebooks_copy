package;

import dragonbox.common.tests.MathUtilTest;
import openfl.display.Sprite;
import openfl.Lib;

/**
 * ...
 * @author 
 */
class TestMain extends Sprite 
{

	public function new() 
	{
		super();
		
		// Assets:
		// openfl.Assets.getBitmapData("img/assetname.jpg");
		var mathUtilTests = new MathUtilTest();
		mathUtilTests.runTests();
	}

}
