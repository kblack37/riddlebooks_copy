package wordproblem.display;

import dragonbox.common.dispose.IDisposable;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * A simple button that will also display text. It probably needs some work,
 * but I just wanted to get a basic button able to display text
 * @author 
 */
class LabelButton extends PivotSprite implements IDisposable {
	
	/**
	 * Properties to interface directly with the backing text field
	 */
	public var label(get, set) : String;
	public var textFormatDefault(get, set) : TextFormat;
	public var textFormatHover(get, set) : TextFormat;
	
	/**
	 * Properties for the button icon
	 */
	public var upState(get, set) : DisplayObject;
	public var overState(get, set) : DisplayObject;
	public var downState(get, set) : DisplayObject;
	public var disabledState(get, set) : DisplayObject;
	public var enabled(get, set) : Bool;
	public var scaleWhenUp(get, set) : Float;
	public var scaleWhenOver(get, set) : Float;
	public var scaleWhenDown(get, set) : Float;
	
	private var m_currentState : DisplayObject;
	private var m_upState : DisplayObject;
	private var m_overState : DisplayObject;
	private var m_downState : DisplayObject;
	private var m_disabledState : DisplayObject;
	
	/**
	 * Whether the button receives events & displays the disabled state
	 */
	private var m_enabled : Bool = true;
	
	private var m_backingTextField : TextField;
	
	/**
	 * In case we want a different format when the player is over the button
	 */
	private var m_defaultTextFormat : TextFormat;
	private var m_hoverTextFormat : TextFormat;
	
	/**
	 * In case we want to scale differently when certain conditions are met
	 */
	private var upScale : Float = 1.0;
	private var overScale : Float = 1.0;
	private var downScale : Float = 1.0;
	
	public function new(upState:DisplayObject, overState:DisplayObject = null, downState:DisplayObject = null, disabledState:DisplayObject = null) {
		if (upState == null) throw "Null default button state";
		
		super();
		
		this.mouseChildren = false;
		this.buttonMode = true;
		
		m_upState = upState;
		m_overState = overState != null ? overState : upState;
		m_downState = downState != null ? downState : upState;
		m_disabledState = disabledState != null ? disabledState : upState;
		
		m_currentState = m_upState;
		addChild(m_currentState);
		
		m_backingTextField = new TextField();
		m_backingTextField.width = this.width;
		m_backingTextField.height = this.height;
		m_backingTextField.text = "";
		m_backingTextField.wordWrap = true;
		m_defaultTextFormat = m_backingTextField.getTextFormat(); // Make sure this is never null even if it's not set
		addChild(m_backingTextField);
		
		addListeners();
	}
	
	override public function dispose() {
		removeListeners();
		
		removeChild(m_currentState);
		removeChild(m_backingTextField);
		
		m_currentState = null;
		m_backingTextField = null;
		
		m_upState = null;
		m_overState = null;
		m_downState = null;
		m_disabledState = null;
		
		while (numChildren > 0) {
			var child = removeChildAt(0);
			if (Std.is(child, IDisposable)) {
				(try cast(child, IDisposable) catch (e : Dynamic) null).dispose();
			}
		}
	}
	
	private function onMouseUp(event : Dynamic) {
		changeStateTo(m_upState);
		
		scaleX = scaleY = upScale;
	}
	
	private function onMouseDown(event : Dynamic) {
		changeStateTo(m_downState);
		
		scaleX = scaleY = downScale;
	}
	
	private function onMouseOver(event : Dynamic) {
		changeStateTo(m_overState);
		
		scaleX = scaleY = overScale;
		
		if (m_hoverTextFormat != null) {
			m_backingTextField.setTextFormat(m_hoverTextFormat);
		}
	}
	
	private function onMouseOut(event : Dynamic) {
		changeStateTo(m_upState);
		
		scaleX = scaleY = upScale;
		
		m_backingTextField.setTextFormat(m_defaultTextFormat);
	}
	
	private function changeStateTo(newState : DisplayObject) {
		removeChild(m_currentState);
		m_currentState = newState;
		addChildAt(m_currentState, 0);
	}
	
	private function addListeners() {
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	private function removeListeners() {
		removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	/**** Text Field Properties ****/
	function set_label(text : String) : String {
		if (text == null) return null;
		return m_backingTextField.text = text;
	}
	
	function get_label() : String {
		return m_backingTextField.text;
	}
	
	function set_textFormatDefault(textFormat : TextFormat) : TextFormat {
		m_backingTextField.setTextFormat(textFormat);
		return m_defaultTextFormat = textFormat;
	}
	
	function get_textFormatDefault() : TextFormat {
		return m_defaultTextFormat;
	}
	
	function set_textFormatHover(textFormat : TextFormat) : TextFormat {
		return m_hoverTextFormat = textFormat;
	}
	
	function get_textFormatHover() : TextFormat {
		return m_hoverTextFormat;
	}
	
	/**** Button Properties ****/
	function set_upState(upState : DisplayObject) : DisplayObject {
		if (m_currentState == m_upState) changeStateTo(upState);
		if (m_downState == null) m_downState = upState;
		if (m_overState == null) m_overState = upState;
		if (m_disabledState == null) m_disabledState = upState;
		return m_upState = upState;
	}
	
	function get_upState() : DisplayObject {
		return m_upState;
	}
	
	function set_downState(downState : DisplayObject) : DisplayObject {
		if (m_currentState == m_downState) changeStateTo(downState);
		return m_downState = downState;
	}
	
	function get_downState() : DisplayObject {
		return m_downState;
	}
	
	function set_overState(overState : DisplayObject) : DisplayObject {
		if (m_currentState == m_overState) changeStateTo(overState);
		return m_overState = overState;
	}
	
	function get_overState() : DisplayObject {
		return m_overState;
	}
	
	function set_disabledState(disabledState : DisplayObject) : DisplayObject {
		if (m_currentState == m_disabledState) changeStateTo(disabledState);
		return m_disabledState = disabledState;
	}
	
	function get_disabledState() : DisplayObject {
		return m_disabledState;
	}
	
	function set_enabled(value : Bool) : Bool {
		if (value) {
			addListeners();
			this.buttonMode = true;
			m_currentState = m_upState;
		} else {
			removeListeners();
			this.buttonMode = false;
			m_currentState = m_disabledState;
		}
		return m_enabled = value;
	}
	
	function get_enabled() : Bool {
		return m_enabled;
	}
	
	function set_scaleWhenUp(value : Float) : Float {
		return upScale = value;
	}
	
	function get_scaleWhenUp() : Float {
		return upScale;
	}
	
	function set_scaleWhenOver(value : Float) : Float {
		return overScale = value;
	}
	
	function get_scaleWhenOver() : Float {
		return overScale;
	}
	
	function set_scaleWhenDown(value : Float) : Float {
		return downScale = value;
	}
	
	function get_scaleWhenDown() : Float {
		return downScale;
	}
}