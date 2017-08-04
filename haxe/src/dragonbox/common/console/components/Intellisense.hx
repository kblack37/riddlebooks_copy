package dragonbox.common.console.components;


import starling.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import starling.display.Sprite;

class Intellisense extends Sprite
{
    private static var ITEM : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    private var m_items : Array<String>;
    private var m_labels : Array<TextField>;
    private var m_selection : Int;
    
    private var m_background : Sprite;
    
    public function new()
    {
        super();
        m_items = new Array<String>();
        m_labels = new Array<TextField>();
        
        m_background = new Sprite();
        addChild(m_background);
    }
    
    public function getSelectedText() : String
    {
        return m_items[m_selection];
    }
    
    public function populate(items : Array<String>) : Void
    {
        m_items = items;
        m_selection = Std.int(Math.max(0, Math.min(m_selection, m_items.length - 1)));
        
        repaint();
    }
    
    public function selectNext() : Void
    {
        deselect(m_selection);
        m_selection = Std.int(Math.min(m_selection + 1, m_items.length - 1));
        select(m_selection);
    }
    
    public function selectPrevious() : Void
    {
        deselect(m_selection);
        m_selection = Std.int(Math.max(0, m_selection - 1));
        select(m_selection);
    }
    
    private function deselect(index : Int) : Void
    {
        if (m_labels.length > 0) 
        {
            var label : TextField = m_labels[index];
			// TODO: Starling TextFields don't have these equivalents
            //label.background = false;
        }
    }
    
    private function select(index : Int) : Void
    {
        if (m_labels.length > 0) 
        {
            var label : TextField = m_labels[index];
			// TODO: Starling TextFields don't have these equivalents
            //label.background = true;
            //label.backgroundColor = 0x7777dd;
        }
    }
    
    private function repaint() : Void
    {
        for (oldItemLabel in m_labels)
        {
            removeChild(oldItemLabel);
        }
        m_labels = new Array<TextField>();
        
        var backgroundWidth : Float = 0;
        var backgroundHeight : Float = 0;
        
        var y : Float = 0;
        for (item in m_items)
        {
            var itemLabel : TextField = new TextField(0, 0, "");
			// TODO: Starling TextFields don't have these equivalents
            //itemLabel.selectable = false;
            itemLabel.autoSize = TextFieldAutoSize.LEFT;
            itemLabel.text = item;
            //itemLabel.setTextFormat(ITEM);
            itemLabel.y = y;
            
            y += itemLabel.height;
            
            m_labels.push(itemLabel);
            this.addChild(itemLabel);
            
            backgroundHeight += itemLabel.height;
            if (itemLabel.width > backgroundWidth) 
            {
                backgroundWidth = itemLabel.width;
            }
        }
        
		// TODO: a Starling solution to this code would require more effort
		// that is better expended elsewhere, since it is going to be replaced
        //m_background.graphics.clear();
        //m_background.graphics.beginFill(0xdddd77, 0.95);
        //m_background.graphics.drawRect(0, 0, backgroundWidth, backgroundHeight);
        //m_background.graphics.endFill();
        
        select(m_selection);
    }
    private static var init = {
        ITEM.color = 0xffffff;
        ITEM.size = 14;
        ITEM.align = TextFormatAlign.LEFT;
    }

}
