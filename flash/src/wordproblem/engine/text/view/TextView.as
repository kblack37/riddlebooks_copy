package wordproblem.engine.text.view
{
    import flash.geom.ColorTransform;
    import flash.geom.Point;
    
    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.text.TextField;
    import starling.utils.HAlign;
    
    import wordproblem.engine.text.model.DocumentNode;
    
    /**
     * A view for a single span of text that all fits into one line.
     * 
     * Note that a text node might have its contents broken up into several text views.
     * if it spans across several lines. In this case all these different view still
     * reference a single backing node.
     */
    public class TextView extends DocumentView
    {
        private var m_textField:TextField;
        
        private var m_textDecorationDisplay:DisplayObject;
        
        public function TextView(node:DocumentNode)
        {
            super(node);
            
            // The setting of the text and its format need to be done later.
            // Some other measuring function will have to determine the proper
            // width and height.
        }
        
        public function setTextContents(text:String, 
                                        width:Number, 
                                        height:Number, 
                                        fontName:String, 
                                        color:uint, 
                                        size:int):void
        {
            if (m_textField != null)
            {
                m_textField.removeFromParent(true);
            }
            
            const textField:TextField = new TextField(width, height, text, fontName, size, color);
            textField.hAlign = HAlign.LEFT;
            addChild(textField);
            
            m_textField = textField;
            
        }
        
        override protected function setTextDecoration(textDecoration:String):void
        {
            // Remove and dispose old decoration
            if (m_textDecorationDisplay != null)
            {
                m_textDecorationDisplay.removeFromParent(true);
                m_textDecorationDisplay = null;
            }
            
            if (textDecoration == "line-through")
            {
                // Places a rectangular sprite over the the textfield 
                // The color is a darker shade of the original text
                
                var textFromField:String = m_textField.text;
                var lineWidth:Number = m_textField.width;
                var lineThinkness:Number = Math.max(m_textField.height * 0.05, 1.0);
                
                // If text ends in a space, do not have the line go through the whitespace
                if (textFromField.charAt(textFromField.length - 1) == ' ')
                {
                    lineWidth -= 10;
                }

                var quad:Quad = new Quad(m_textField.width, lineThinkness, shade(m_textField.color, .5));
                quad.x = m_textField.x;
                quad.y = m_textField.y + m_textField.height * 0.5;
                addChild(quad);
                m_textDecorationDisplay = quad;
            }
        }
        
        public function getTextField():TextField
        {
            return m_textField;
        }
        
        override public function hitTestPoint(globalPoint:Point, ignoreNonSelectable:Boolean=true):DocumentView
        {
            var hitView:Boolean = this.hitTest(this.globalToLocal(globalPoint)) != null;
            var viewToReturn:DocumentView = null;
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
        public function shade(color:uint, intensity:Number):uint
        {
            var transform:ColorTransform = new ColorTransform(intensity, intensity, intensity, intensity, (color  >> 16 & 0xFF) * intensity , (color >> 8 & 0xFF) * intensity, (color & 0xFF)*intensity);
            return transform.color as uint;
        }
    }
}