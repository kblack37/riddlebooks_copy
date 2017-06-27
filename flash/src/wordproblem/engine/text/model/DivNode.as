package wordproblem.engine.text.model
{
    import wordproblem.engine.text.TextParser;

    /**
     * A div will simply act as a wrapper container to aggregate paragraphs and image.
     * It is desgined mostly just to allow content to be laid out in a flexible manner.
     * For example using divs we should be able to create comic book style panels as well
     * as more traditional looking picture book layouts
     * 
     */
    public class DivNode extends DocumentNode
    {
        public static const LAYOUT_RELATIVE:String = "relative";
        
        /**
         * absolute layout means that this container taken out of the document flow and 
         * will not affect other elements position. x and y must be explicitly set otherwise
         * elements will probably overlap
         */
        public static const LAYOUT_ABSOLUTE:String = "absolute";
        
        /**
         * The layout type for items in this container, default is absolute
         * 
         * If not set layout it should inherit from the parent
         */
        private var m_layout:String;
        
        /**
         * The define flag is used when performing the inheritance pass, any nodes not
         * explicitly marked with a layout attribute should inherit this property.
         */
        public var layoutDefined:Boolean = false;
        
        public function DivNode()
        {
            super(TextParser.TAG_DIV);
            m_layout = LAYOUT_ABSOLUTE;
        }
        
        public function setLayout(layout:String):void
        {
            this.layoutDefined = true;
            m_layout = layout;
        }
        
        public function getLayout():String
        {
            return m_layout;
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