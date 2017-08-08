package;

import dragonbox.common.tests.MathUtilTest;
import openfl.display.Sprite;
import starling.core.Starling;
import starling.events.Event;

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
		test_starling.addEventListener(Event.ROOT_CREATED, onRootCreated);
	}
	
	public function onRootCreated(event : Event, data : Dynamic) {
		var app = try cast(data, TestApp) catch (e : Dynamic) null;
		app.run();
	}

}
