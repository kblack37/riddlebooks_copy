package wordproblem.engine.widget
{
    import flash.text.TextFormat;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import starling.display.Sprite;
    import starling.text.TextField;
    
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.MeasuringTextField;
    
    /**
     * This is the textfield used to display a translation of the current expressions that are being modeled.
     */
    public class EquationToTextWidget extends Sprite
    {
        private var m_textField:TextField;
        private var m_vectorSpace:IVectorSpace;
        private var m_currentEquationRoot:ExpressionNode;
        
        private var m_maxWidth:Number;
        private var m_maxHeight:Number;
        private var m_measuringTextField:MeasuringTextField;
        private var m_defaultTextFormat:TextFormat;
        
        public function EquationToTextWidget()
        {
            super();
            
            m_maxWidth = 0;
            m_maxHeight = 0;
            
            const textColor:uint = 0xCCCCCC;
            m_defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, textColor);
            
            m_measuringTextField = new MeasuringTextField();
            m_measuringTextField.defaultTextFormat = m_defaultTextFormat;
            m_measuringTextField.setTextFormat(m_defaultTextFormat);
        }
        
        public function setDimensions(width:Number, height:Number):void
        {
            m_maxWidth = width;
            m_maxHeight = height;
        }
        
        /**
         * Override the text that should be displayed
         */
        public function setText(text:String, root:ExpressionNode):void
        {
            // Make sure that the text can fit in the maximum specified dimensions
            var targetFontSize:Number = m_measuringTextField.resizeToDimensions(m_maxWidth, m_maxHeight, text);
            if (m_textField != null)
            {
                m_textField.removeFromParent(true);
            }
            
            m_textField = new TextField(m_maxWidth, m_maxHeight, text, m_defaultTextFormat.font, targetFontSize, m_defaultTextFormat.color as uint);
            addChild(m_textField);
            
            m_currentEquationRoot = root;
        }
        
        public function getEquationRoot():ExpressionNode
        {
            return m_currentEquationRoot;
        }
        
        public function clear():void
        {
            if (m_textField != null)
            {
                m_textField.removeFromParent(true);
            }
        }
    }
}