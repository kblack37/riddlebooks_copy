package wordproblem.display;

import dragonbox.common.dispose.IDisposable;
import openfl.display.Sprite;

/**
 * ...
 * @author 
 */
class DisposableSprite extends Sprite implements IDisposable {

	public function new() {
		super();
	}
	
	public function dispose() : Void {
		while (numChildren > 0) {
			var child = removeChildAt(0);
			if (Std.is(child, DisposableSprite)) {
				(try cast(child, DisposableSprite) catch (e : Dynamic) null).dispose();
			}
		}
	}
	
}