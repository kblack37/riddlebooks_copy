package wordproblem.engine.text.model
{
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.text.TextParserUtil;

    /**
     * A terminal node representing a still image.
     * 
     * Note that the id of an image MUST be set since we will use that string to
     * link the image to the asset manager.
     */
    public class ImageNode extends DocumentNode
    {
        /**
         * In most cases this acts like the url to the image to be shown.
         * 
         * The object is of the form 
         * 
         * {
         * type: url or embed or symbol (describes how/where the resource is located), 
         * name: id to fetch loaded image,
         * 
         * ... Any other properties to apply to the resource such as nine-slice or tinting
         * }
         * 
         * Note on symbol type, describes whether or not the image should be rendered the same as one of the cards that are part of the
         * expression tree.
         */
        public var src:Object;
        
        public function ImageNode(src:String)
        {
            super(TextParser.TAG_IMAGE);
            this.src = TextParserUtil.parseResourceSourceString(src)[0];
        }
        
        /** Return the problem text in this document
         *   
         */
        override public function getText():String
        {
            return "";
        }
    }
}