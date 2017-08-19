package dragonbox.common.console.components;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import openfl.display.Sprite;

class Intellisense extends Sprite
{
    private static var ITEM : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    private var m_items : Array<String>;
    private var m_labels : Array<TextField>;
    private var m_selection : Int;
    
    private var m_background : DisplayObject;
    
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
            label.background = false;
        }
    }
    
    private function select(index : Int) : Void
    {
        if (m_labels.length > 0) 
        {
            var label : TextField = m_labels[index];
            label.background = true;
            label.backgroundColor = 0x7777dd;
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
            var itemLabel : TextField = new TextField();
			itemLabel.width = 0;
			itemLabel.height = 0;
			itemLabel.text = "";
            itemLabel.selectable = false;
            itemLabel.autoSize = TextFieldAutoSize.LEFT;
            itemLabel.text = item;
            itemLabel.setTextFormat(ITEM);
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
        
		m_background = new Bitmap(new BitmapData(Std.int(backgroundWidth), Std.int(backgroundHeight), false, 0xdddd77));
        
        select(m_selection);
    }
    private static var init = {
        ITEM.color = 0xffffff;
        ITEM.size = 14;
        ITEM.align = TextFormatAlign.LEFT;
    }

}
