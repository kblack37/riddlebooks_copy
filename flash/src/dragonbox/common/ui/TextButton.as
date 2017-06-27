package dragonbox.common.ui
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    import dragonbox.common.dispose.IDisposable;
    
    /**
     * A button that is just a text field, it changes color on hover and has no background
     */
    public class TextButton extends Sprite implements IDisposable
    {
        private var m_upTextField:TextField;
        private var m_hoverTextField:TextField;
        
        public function TextButton()
        {
            super();
            
            m_upTextField = new TextField();
            m_upTextField.selectable = false;
            m_hoverTextField = new TextField();
            m_hoverTextField.selectable = false;
            
            this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
            this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            
            this.addChild(m_upTextField);
        }
        
        public function set embedFonts(value:Boolean):void
        {
            m_upTextField.embedFonts = value;
            m_hoverTextField.embedFonts = value;
        }
        
        public function set text(value:String):void
        {
            m_upTextField.text = value;
            m_upTextField.width = m_upTextField.textWidth * 1.1;
            m_upTextField.height = m_upTextField.textHeight;
            m_hoverTextField.text = value;
            m_hoverTextField.width = m_hoverTextField.textWidth * 1.1;
            m_hoverTextField.height = m_hoverTextField.textHeight;
        }
        
        public function set textFormat(value:TextFormat):void
        {
            m_upTextField.defaultTextFormat = value;
        }
        
        public function set hoverTextFormat(value:TextFormat):void
        {
            m_hoverTextField.defaultTextFormat = value;
        }
        
        public function dispose():void
        {
            this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
            this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        }
        
        private function onMouseOver(event:MouseEvent):void
        {
            if (m_upTextField.parent)
            {
                this.removeChild(m_upTextField);
            }
            
            this.addChild(m_hoverTextField);
        }
        
        private function onMouseOut(event:MouseEvent):void
        {
            if (m_hoverTextField.parent)
            {
                this.removeChild(m_hoverTextField);
            }
            
            this.addChild(m_upTextField);
        }
    }
}