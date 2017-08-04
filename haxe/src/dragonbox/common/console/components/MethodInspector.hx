package dragonbox.common.console.components;


import starling.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import starling.display.Sprite;

class MethodInspector extends Sprite
{
    public static inline var MAX_WIDTH : Int = 250;
    
    private static var FORMAT : TextFormat = new TextFormat("Kalinga");
    
    private var m_background : Sprite;
    private var m_contentLabel : TextField;
    
    public function new()
    {
        super();
        m_background = new Sprite();
        
        m_contentLabel = new TextField(0, 0, "");
		// TODO: Starling TextFields don't have these equivalents
        //m_contentLabel.selectable = false;
        //m_contentLabel.wordWrap = true;
        m_contentLabel.width = MAX_WIDTH;
        
        addChild(m_background);
        addChild(m_contentLabel);
    }
    
    public function populate(content : String) : Void
    {
        m_contentLabel.text = content;
        //m_contentLabel.setTextFormat(FORMAT);
        m_contentLabel.height = m_contentLabel.height + 5;  // Bug: Without the +5, the last line can't be displayed (flash bug?)  
        
		// TODO: a Starling solution to this code would require more effort
		// that is better expended elsewhere, since it is going to be replaced
        //m_background.graphics.clear();
        //m_background.graphics.beginFill(0x999977, 0.95);
        //m_background.graphics.drawRect(-1, -1, m_contentLabel.width + 2, m_contentLabel.height + 2);
        //m_background.graphics.endFill();
    }
    private static var init = {
        FORMAT.color = 0xffffff;
        FORMAT.size = 14;
        FORMAT.align = TextFormatAlign.LEFT;
    }

}
