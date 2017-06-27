package wordproblem.engine.text.model
{
    import wordproblem.engine.text.TextParser;

    public class ParagraphNode extends DocumentNode
    {
        /**
         * The multiplier that will determine the pixel difference between lines of a paragraph.
         * A value of 1.0 means that each line will be stacked completely on top of each other.
         * 
         * The actual pixel height depends on the size of the font
         */
        public var lineHeight:Number = 1.0;
        
        public function ParagraphNode()
        {
            super(TextParser.TAG_PARAGRAPH);
        }
     
        /** Return the problem text in this document
         *   
         */
        override public function getText():String
        {
            var txt:String = "";
            
            for (var i:int = 0; i < children.length; i++) {
                txt += children[i].getText();
            }
            return txt;
        }
    }
}