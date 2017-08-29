package wordproblem.display;

import openfl.display.DisplayObject;
import openfl.geom.Rectangle;

/**
 * A wrapper class to replace the pivot property that Starling display
 * objects had
 * @author kristen autumn blackburn
 */
class PivotSprite extends DisposableSprite {

	public var pivotX(get, set) : Float;
	public var pivotY(get, set) : Float;
	
	private var m_pivotX : Float;
	private var m_pivotY : Float;
	
	public function new() {
		super();
		
		m_pivotX = 0;
		m_pivotY = 0;
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
	
	private function addChildPivot(child : DisplayObject) {
		child.x -= m_pivotX / this.scaleX;
		child.y -= m_pivotY / this.scaleY;
	}
	
	private function removeChildPivot(child : DisplayObject) {
		child.x += m_pivotX / this.scaleX;
		child.y += m_pivotY / this.scaleY;
	}
	
	/**
	 * We add the x position of the child to the difference of the current
	 * pivot and the new pivot to combine resetting to the original position 
	 * and setting the new position in one step
	 */
	function set_pivotX(pivotX : Float) {
		for (i in 0...numChildren) {
			var child = this.getChildAt(i);
			child.x += (m_pivotX - pivotX) / this.scaleX;
		}
		return m_pivotX = pivotX;
	}
	
	function set_pivotY(pivotY : Float) {
		for (i in 0...numChildren) {
			var child = this.getChildAt(i);
			child.y += (m_pivotY - pivotY) / this.scaleY;
		}
		return m_pivotY = pivotY;
	}
	
	function get_pivotX() {
		return m_pivotX;
	}
	
	function get_pivotY() {
		return m_pivotY;
	}
}