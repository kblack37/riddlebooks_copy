package wordproblem.engine.text.model
{
    import wordproblem.engine.text.TextParser;

    public class SpanNode extends DocumentNode
    {
        public function SpanNode()
        {
            super(TextParser.TAG_SPAN);
        }
        
        /** Return the problem text in this document
         *   
         */
        override public function getText():String
        {
            var txt:String = " ";
            
            for (var i:int = 0; i < children.length; i++) {
                txt += children[i].getText();
            }
            return txt + " ";
        }
    }
}