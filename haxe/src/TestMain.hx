package;

import dragonbox.common.tests.MathUtilTest;
import openfl.Assets;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.Lib;
import starling.core.Starling;
import starling.display.Image;
import wordproblem.resource.AssetManager;

/**
 * ...
 * @author 
 */
class TestMain extends Sprite {
	
	private var test_starling : Starling;
	
	public function new() 
	{
		super();
		
		// Assets:
		// openfl.Assets.getBitmapData("img/assetname.jpg");
		
		// MathUtil tests
		var mathUtilTests = new MathUtilTest();
		mathUtilTests.runTests();
		
		test_starling = new Starling(TestApp, stage);
		test_starling.start();
	}

}
