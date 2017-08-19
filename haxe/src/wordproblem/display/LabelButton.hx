package wordproblem.display;

import dragonbox.common.dispose.IDisposable;
import openfl.display.SimpleButton;

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
	 * Properties to interface directly with the backing button
	 */
	public var upState(get, set) : DisplayObject;
	public var overState(get, set) : DisplayObject;
	public var downState(get, set) : DisplayObject;
	public var hitTestState(get, set) : DisplayObject;
	public var enabled(get, set) : Bool;
	public var scaleWhenUp(get, set) : Float;
	public var scaleWhenOver(get, set) : Float;
	public var scaleWhenDown(get, set) : Float;
	
	private var m_backingButton : SimpleButton;
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
	
	public function new(upState:DisplayObject = null, overState:DisplayObject = null, downState:DisplayObject = null, hitTestState:DisplayObject = null) {
		super();
		
		m_backingButton = new SimpleButton(upState, overState, downState, hitTestState);
		addChild(m_backingButton);
		
		m_backingTextField = new TextField();
		m_backingTextField.wordWrap = true;
		m_backingTextField.mouseEnabled = false;
		m_defaultTextFormat = m_backingTextField.getTextFormat(); // Make sure this is never null even if it's not set
		addChild(m_backingTextField);
		
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	override public function dispose() {
		super.dispose();
		
		removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		
		m_backingButton = null;
		m_backingTextField = null;
	}
	
	private function onMouseDown(event : Dynamic) {
		var mouseEvent = cast(event, MouseEvent);
		if (this.hitTestPoint(mouseEvent.stageX, mouseEvent.stageY)) {
			this.scaleX = this.scaleY = downScale;
		}
	}
	
	private function onMouseOver(event : Dynamic) {
		var mouseEvent = cast(event, MouseEvent);
		if (!mouseEvent.buttonDown) {
			this.scaleX = this.scaleY = overScale;
		}
		
		if (m_hoverTextFormat != null) {
			m_backingTextField.setTextFormat(m_hoverTextFormat);
		}
	}
	
	private function onMouseOut(event : Dynamic) {
		this.scaleX = this.scaleY = upScale;
		m_backingTextField.setTextFormat(m_defaultTextFormat);
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
		return m_backingButton.upState = upState;
	}
	
	function get_upState() : DisplayObject {
		return m_backingButton.upState;
	}
	
	function set_downState(downState : DisplayObject) : DisplayObject {
		return m_backingButton.downState = downState;
	}
	
	function get_downState() : DisplayObject {
		return m_backingButton.downState;
	}
	
	function set_overState(overState : DisplayObject) : DisplayObject {
		return m_backingButton.overState = overState;
	}
	
	function get_overState() : DisplayObject {
		return m_backingButton.overState;
	}
	
	function set_hitTestState(hitTestState : DisplayObject) : DisplayObject {
		return m_backingButton.hitTestState = hitTestState;
	}
	
	function get_hitTestState() : DisplayObject {
		return m_backingButton.hitTestState;
	}
	
	function set_enabled(value : Bool) : Bool {
		return m_backingButton.enabled = value;
	}
	
	function get_enabled() : Bool {
		return m_backingButton.enabled;
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