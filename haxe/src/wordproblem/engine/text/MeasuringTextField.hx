package wordproblem.engine.text;


import flash.text.TextField;
import flash.text.TextFormat;

class MeasuringTextField extends TextField
{
    public function new()
    {
        super();
        this.wordWrap = false;
    }
    
    override private function set_defaultTextFormat(format : TextFormat) : TextFormat
    {
        // Whether or not to set the use embed flag depends on the font type used.
        // We need to loop through all the embedded fonts and check
        // fontType property
        this.embedFonts = GameFonts.getFontIsEmbedded(format.font);
        
        super.defaultTextFormat = format;
        return format;
    }
    
    override public function setTextFormat(format : TextFormat, beginIndex : Int = -1, endIndex : Int = -1) : Void
    {
        this.embedFonts = GameFonts.getFontIsEmbedded(format.font);
        super.setTextFormat(format, beginIndex, endIndex);
    }
    
    /**
     * Attempt to resize the text to fit the given dimensions
     * 
     * @return the required font size
     */
    public function resizeToDimensions(maxWidth : Float,
            maxHeight : Float,
            text : String) : Float
    {
        var fontSize : Float = try cast(this.defaultTextFormat.size, Float) catch(e:Dynamic) null;
        var fontName : String = this.defaultTextFormat.font;
        
        // Creating another textfield for measurement
        var tf : TextFormat = new TextFormat(fontName, Std.int(fontSize));
        var testingTextfield : MeasuringTextField = new MeasuringTextField();
        testingTextfield.width = this.width;
        testingTextfield.height = this.height;
        testingTextfield.wordWrap = this.wordWrap;
        testingTextfield.multiline = this.multiline;
        testingTextfield.embedFonts = this.embedFonts;
        testingTextfield.defaultTextFormat = tf;
        testingTextfield.text = text;
        
        // Check if the current font size is too big for the current dimensions
        var minimumFontSize : Float = 8;
        if (maxWidth > 0 && maxHeight > 0 && testingTextfield.textWidth > 0) 
        {
            if (testingTextfield.textWidth > maxWidth || testingTextfield.textHeight > maxHeight) 
            {
                while ((testingTextfield.textWidth > maxWidth || testingTextfield.textHeight > maxHeight) &&
                fontSize > minimumFontSize)
                {
                    fontSize -= 1;
                    tf.size = Std.int(fontSize);
                    testingTextfield.defaultTextFormat = tf;
                    testingTextfield.text = text;
                }
            }
            else if (testingTextfield.textWidth < maxWidth && testingTextfield.textHeight < maxHeight) 
            {
                // Scaling up is a bit screwed up, the multiplying factor is needed because as is
                // the increased font causes the text to overflow the max bounds of the starling text field
                var performedFontIncrease : Bool = false;
                var fontStepSize : Int = 1;
                while (testingTextfield.textWidth < maxWidth * 0.9 && testingTextfield.textHeight < maxHeight * 0.9)
                {
                    fontSize += fontStepSize;
                    tf.size = Std.int(fontSize);
                    testingTextfield.defaultTextFormat = tf;
                    testingTextfield.text = text;
                    performedFontIncrease = true;
                }  // Undo the last font increase.    // If we did an increase, then that last increase caused the overflow to be detected  
                
                
                
                
                
                if (performedFontIncrease) 
                {
                    fontSize -= fontStepSize;
                }
            }
        }
        
        var newFontSize : Int = Std.int(Math.max(minimumFontSize, fontSize));
        return newFontSize;
    }
}
