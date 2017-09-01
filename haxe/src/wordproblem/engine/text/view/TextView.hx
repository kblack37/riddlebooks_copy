package wordproblem.engine.text.view;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import openfl.display.DisplayObject;
import openfl.text.TextField;

import wordproblem.engine.text.model.DocumentNode;

/**
 * A view for a single span of text that all fits into one line.
 * 
 * Note that a text node might have its contents broken up into several text views.
 * if it spans across several lines. In this case all these different view still
 * reference a single backing node.
 */
class TextView extends DocumentView
{
    private var m_textField : TextField;
    
    private var m_textDecorationDisplay : DisplayObject;
    
    public function new(node : DocumentNode)
    {
        super(node);
    }
    
    public function setTextContents(text : String,
            width : Float,
            height : Float,
            fontName : String,
            color : Int,
            size : Int) : Void
    {
        if (m_textField != null) 
        {
			if (m_textField.parent != null) m_textField.parent.removeChild(m_textField);
			m_textField = null;
        }
        
        var textField : TextField = new TextField();
		textField.width = Std.int(width);
		textField.height = Std.int(height);
		textField.text = text;
		textField.setTextFormat(new TextFormat(fontName, size, color, null, null, null, null, null, TextFormatAlign.LEFT));
		textField.selectable = false;
        addChild(textField);
        
        m_textField = textField;
    }
    
    override private function setTextDecoration(textDecoration : String) : Void
    {
        // Remove and dispose old decoration
        if (m_textDecorationDisplay != null) 
        {
			if (m_textDecorationDisplay.parent != null) m_textDecorationDisplay.parent.removeChild(m_textDecorationDisplay);
            m_textDecorationDisplay = null;
        }
        
        if (textDecoration == "line-through") 
        {
            // Places a rectangular sprite over the the textfield
            // The color is a darker shade of the original text
            var textFromField : String = m_textField.text;
            var lineWidth : Float = m_textField.width;
            var lineThickness : Float = Math.max(m_textField.height * 0.05, 1.0);
            
            // If text ends in a space, do not have the line go through the whitespace
            if (textFromField.charAt(textFromField.length - 1) == " ") 
            {
                lineWidth -= 10;
            }
            
			var bitmap = new Bitmap(new BitmapData(Std.int(m_textField.width), Std.int(lineThickness), false, shade(m_textField.textColor, .5)));
            bitmap.x = m_textField.x;
            bitmap.y = m_textField.y + m_textField.height * 0.5;
            addChild(bitmap);
            m_textDecorationDisplay = bitmap;
        }
    }
    
    public function getTextField() : TextField
    {
        return m_textField;
    }
    
    override public function customHitTestPoint(globalPoint : Point, ignoreNonSelectable : Bool = true) : DocumentView
    {
        var hitView : Bool = this.hitTestPoint(globalPoint.x, globalPoint.y);
        var viewToReturn : DocumentView = null;
        if (hitView && (this.node.getSelectable() || !ignoreNonSelectable)) 
        {
            viewToReturn = this;
        }
        return viewToReturn;
    }
    
    /**
     * Modify the shad of an original color 
     * @param    color: a uint color code
     * @param    intensity: the shade manipulator the closer to zero the darker the shade
     * @return the color as a uint
     */
    public function shade(color : Int, intensity : Float) : Int
    {
        var transform : ColorTransform = new ColorTransform(intensity, intensity, intensity, intensity, (color >> 16 & 0xFF) * intensity, (color >> 8 & 0xFF) * intensity, (color & 0xFF) * intensity);
        return try cast(transform.color, Int) catch(e:Dynamic) 0xFFFFFF;
    }
}
