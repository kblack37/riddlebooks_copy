package dragonbox.common.ui;


import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;

import dragonbox.common.dispose.IDisposable;

/**
 * A button that is just a text field, it changes color on hover and has no background
 */
class TextButton extends Sprite implements IDisposable
{
    public var embedFonts(never, set) : Bool;
    public var text(never, set) : String;
    public var textFormat(never, set) : TextFormat;
    public var hoverTextFormat(never, set) : TextFormat;

    private var m_upTextField : TextField;
    private var m_hoverTextField : TextField;
    
    public function new()
    {
        super();
        
        m_upTextField = new TextField();
        m_upTextField.selectable = false;
        m_hoverTextField = new TextField();
        m_hoverTextField.selectable = false;
        
        this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        
        this.addChild(m_upTextField);
    }
    
    private function set_embedFonts(value : Bool) : Bool
    {
        m_upTextField.embedFonts = value;
        m_hoverTextField.embedFonts = value;
        return value;
    }
    
    private function set_text(value : String) : String
    {
        m_upTextField.text = value;
        m_upTextField.width = m_upTextField.textWidth * 1.1;
        m_upTextField.height = m_upTextField.textHeight;
        m_hoverTextField.text = value;
        m_hoverTextField.width = m_hoverTextField.textWidth * 1.1;
        m_hoverTextField.height = m_hoverTextField.textHeight;
        return value;
    }
    
    private function set_textFormat(value : TextFormat) : TextFormat
    {
        m_upTextField.defaultTextFormat = value;
        return value;
    }
    
    private function set_hoverTextFormat(value : TextFormat) : TextFormat
    {
        m_hoverTextField.defaultTextFormat = value;
        return value;
    }
    
    public function dispose() : Void
    {
        this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
    }
    
    private function onMouseOver(event : MouseEvent) : Void
    {
        if (m_upTextField.parent != null) 
        {
            this.removeChild(m_upTextField);
        }
        
        this.addChild(m_hoverTextField);
    }
    
    private function onMouseOut(event : MouseEvent) : Void
    {
        if (m_hoverTextField.parent != null) 
        {
            this.removeChild(m_hoverTextField);
        }
        
        this.addChild(m_upTextField);
    }
}
