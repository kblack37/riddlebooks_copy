package wordproblem.engine.text.model
{
    /**
     * This is a contiguous run of text, it can range from containing only a single character
     * or hundreds that span several lines.
     */
    public class TextNode extends DocumentNode
    {
        public var content:String;
        
        public function TextNode(content:String)
        {
            super("text");
            this.content = content;
        }
        
        /** 
         * Return the problem text in this document
         */
        override public function getText():String
        {
            return this.content;
        }
    }
}