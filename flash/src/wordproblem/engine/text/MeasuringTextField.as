package wordproblem.engine.text
{
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    public class MeasuringTextField extends TextField
    {
        public function MeasuringTextField()
        {
            super();
            this.wordWrap = false;
        }
        
        override public function set defaultTextFormat(format:TextFormat):void
        {
            // Whether or not to set the use embed flag depends on the font type used.
            // We need to loop through all the embedded fonts and check
            // fontType property
            this.embedFonts = GameFonts.getFontIsEmbedded(format.font);
            
            super.defaultTextFormat = format;
        }
        
        override public function setTextFormat(format:TextFormat, beginIndex:int=-1, endIndex:int=-1):void
        {
            this.embedFonts = GameFonts.getFontIsEmbedded(format.font);
            super.setTextFormat(format, beginIndex, endIndex);
        }
        
        /**
         * Attempt to resize the text to fit the given dimensions
         * 
         * @return the required font size
         */
        public function resizeToDimensions(maxWidth:Number, 
                                           maxHeight:Number, 
                                           text:String):Number
        {
            var fontSize:Number = this.defaultTextFormat.size as Number;
            var fontName:String = this.defaultTextFormat.font;
            
            // Creating another textfield for measurement
            var tf:TextFormat = new TextFormat(fontName, fontSize);
            var testingTextfield:MeasuringTextField = new MeasuringTextField();
            testingTextfield.width = this.width;
            testingTextfield.height = this.height;
            testingTextfield.wordWrap = this.wordWrap;
            testingTextfield.multiline = this.multiline;
            testingTextfield.embedFonts = this.embedFonts;
            testingTextfield.defaultTextFormat = tf;
            testingTextfield.text = text;
            
            // Check if the current font size is too big for the current dimensions
            var minimumFontSize:Number = 8;
            if (maxWidth > 0 && maxHeight > 0 && testingTextfield.textWidth > 0)
            {
                if (testingTextfield.textWidth > maxWidth || testingTextfield.textHeight > maxHeight)
                {
                    while ((testingTextfield.textWidth > maxWidth || testingTextfield.textHeight > maxHeight) && 
                        fontSize > minimumFontSize)
                    {
                        fontSize -= 1;
                        tf.size = fontSize;
                        testingTextfield.defaultTextFormat = tf;
                        testingTextfield.text = text;
                    }
                }
                else if (testingTextfield.textWidth < maxWidth && testingTextfield.textHeight < maxHeight)
                {
                    // Scaling up is a bit screwed up, the multiplying factor is needed because as is
                    // the increased font causes the text to overflow the max bounds of the starling text field
                    var performedFontIncrease:Boolean = false;
                    var fontStepSize:int = 1;
                    while (testingTextfield.textWidth < maxWidth * 0.9 && testingTextfield.textHeight < maxHeight * 0.9)
                    {
                        fontSize += fontStepSize;
                        tf.size = fontSize;
                        testingTextfield.defaultTextFormat = tf;
                        testingTextfield.text = text;
                        performedFontIncrease = true;
                    }
                    
                    // If we did an increase, then that last increase caused the overflow to be detected
                    // Undo the last font increase.
                    if (performedFontIncrease)
                    {
                        fontSize -= fontStepSize;
                    }
                }
            }
            
            var newFontSize:int = Math.max(minimumFontSize, fontSize);
            return newFontSize;
        }
    }
}