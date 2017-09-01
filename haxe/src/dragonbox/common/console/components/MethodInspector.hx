package dragonbox.common.console.components;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import openfl.display.Sprite;

class MethodInspector extends Sprite
{
    public static inline var MAX_WIDTH : Int = 250;
    
    private static var FORMAT : TextFormat = new TextFormat("Kalinga");
    
    private var m_background : DisplayObject;
    private var m_contentLabel : TextField;
    
    public function new()
    {
        super();
        m_background = new Sprite();
        
        m_contentLabel = new TextField();
		m_contentLabel.width = 0;
		m_contentLabel.height = 0;
		m_contentLabel.text = "";
        m_contentLabel.selectable = false;
        m_contentLabel.wordWrap = true;
        m_contentLabel.width = MAX_WIDTH;
        
        addChild(m_background);
        addChild(m_contentLabel);
    }
    
    public function populate(content : String) : Void
    {
        m_contentLabel.text = content;
        m_contentLabel.setTextFormat(FORMAT);
        m_contentLabel.height = m_contentLabel.height + 5;  // Bug: Without the +5, the last line can't be displayed (flash bug?)  
        
		m_background = new Bitmap(new BitmapData(Std.int(m_contentLabel.width), Std.int(m_contentLabel.height), false, 0x999977));
		m_background.x = -1;
		m_background.y = -1;
    }
    private static var init = {
        FORMAT.color = 0xffffff;
        FORMAT.size = 14;
        FORMAT.align = TextFormatAlign.LEFT;
    }

}
