package wordproblem.display;

import dragonbox.common.dispose.IDisposable;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.EventDispatcher;

/**
 * ...
 * @author 
 */
class PivotSprite extends DisposableSprite {

	@:isVar public var pivotX(get, set) : Float;
	@:isVar public var pivotY(get, set) : Float;
	
	public function new() {
		super();
		
		pivotX = 0;
		pivotY = 0;
	}
	
	/**
	 * We need to overwrite the add methods to make sure the children are
	 * at the correct location according to the pivot
	 */
	override public function addChild(child : DisplayObject) : DisplayObject {
		// If we're adding a child that already has a parent to this just to gain
		// the pivot properties, we need to make sure we maintain the hierarchy properly
		if (child.parent != null && this.parent == null) {
			this.parent = child.parent;
			child.parent = null;
		}
		super.addChild(child);
		addChildPivot(child);
		return child;
	}
	
	override public function addChildAt(child : DisplayObject, index : Int) : DisplayObject {
		super.addChildAt(child, index);
		addChildPivot(child);
		return child;
	}
	
	/**
	 * We need to overwrite the remove methods to reset the childrens' positions
	 * from the pivoted positions
	 */
	override public function removeChild(child : DisplayObject) : DisplayObject {
		removeChildPivot(child);
		return super.removeChild(child);
	}
	
	override public function removeChildAt(index : Int) : DisplayObject {
		var child = this.getChildAt(index);
		removeChildPivot(child);
		return super.removeChildAt(index);
	}
	
	override public function removeChildren(beginIndex : Int = 0, endIndex : Int = 0x7FFFFFFF) : Void {
		for (i in beginIndex...Std.int(Math.min(endIndex, numChildren))) {
			var child = this.getChildAt(i);
			removeChildPivot(child);
		}
		super.removeChildren(beginIndex, endIndex);
	}
	
	override public function dispose() {
		while (numChildren > 0) {
			var child = removeChildAt(0);
			if (Std.is(child, IDisposable)) {
				cast(child, IDisposable).dispose();
			}
		}
	}
	
	private function addChildPivot(child : DisplayObject) {
		child.x -= pivotX / this.scaleX;
		child.y -= pivotY / this.scaleY;
	}
	
	private function removeChildPivot(child : DisplayObject) {
		child.x += pivotX / this.scaleX;
		child.y += pivotY / this.scaleY;
	}
	
	/**
	 * We add the x position of the child to the difference of the current
	 * pivot and the new pivot to combine resetting to the original position 
	 * and setting the new position in one step
	 */
	function set_pivotX(pivotX : Float) {
		for (i in 0...numChildren) {
			var child = this.getChildAt(i);
			child.x += (this.pivotX - pivotX) / this.scaleX;
		}
		return this.pivotX = pivotX;
	}
	
	function set_pivotY(pivotY : Float) {
		for (i in 0...numChildren) {
			var child = this.getChildAt(i);
			child.y += (this.pivotY - pivotY) / this.scaleY;
		}
		return this.pivotY = pivotY;
	}
	
	function get_pivotX() {
		return pivotX;
	}
	
	function get_pivotY() {
		return pivotY;
	}
}