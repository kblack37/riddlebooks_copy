package wordproblem.engine.text
{
    import flash.display.BitmapData;
    import flash.filters.BitmapFilter;
    import flash.filters.GlowFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    /**
     * This is a display object that shows text with an outline glow around the characters.
     * 
     * It uses regular flash textfields and glow filters to create a texture that is to be displayed
     */
    public class OutlinedTextField extends Sprite
    {
        private var m_backingTextfield:TextField;
        private var m_outlineFilter:BitmapFilter;
        
        /**
         * This is the visual piece that is actually displayed within starling
         */
        private var m_displayedImage:Image;
        
        public function OutlinedTextField(width:Number, 
                                          height:Number,
                                          font:String, 
                                          size:Number, 
                                          textColor:uint, 
                                          outlineColor:uint)
        {
            super();
            
            m_backingTextfield = new TextField();
            m_backingTextfield.defaultTextFormat = new TextFormat(font, size, textColor, true, null, null, null, null, TextFormatAlign.CENTER);
            m_backingTextfield.wordWrap = true;
            m_backingTextfield.embedFonts = GameFonts.getFontIsEmbedded(font);
            m_outlineFilter = new GlowFilter(outlineColor, 1.0, 6, 6);
            
            this.setMaxWidth(width);
            this.setMaxHeight(height);
            this.touchable = false;
        }
        
        /**
         * Change the text contents. This will force a redraw of the texture.
         */
        public function setText(text:String):void
        {
            if (m_displayedImage != null)
            {
                m_displayedImage.texture.dispose();
            }
            
            if (text != null && text != "")
            {
                m_backingTextfield.text = text;
                
                const backingFieldDimensions:Rectangle = new Rectangle(0, 0, m_backingTextfield.width, m_backingTextfield.height);
                var bitmapData:BitmapData = new BitmapData(backingFieldDimensions.width, backingFieldDimensions.height, true, 0x000000);
                bitmapData.draw(m_backingTextfield);
                bitmapData.applyFilter(bitmapData, backingFieldDimensions, new Point(0, 0), m_outlineFilter);
                
                var texture:Texture = Texture.fromBitmapData(bitmapData);
                if (m_displayedImage == null)
                {
                    m_displayedImage = new Image(texture);
                    addChild(m_displayedImage);
                }
                
                m_displayedImage.texture = texture;
                m_displayedImage.y = (m_backingTextfield.height - m_backingTextfield.textHeight) * 0.6;
            }
        }
        
        public function setMaxWidth(width:Number):void
        {
            m_backingTextfield.width = width;
        }
        
        public function setMaxHeight(height:Number):void
        {
            m_backingTextfield.height = height;    
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            if (m_displayedImage != null)
            {
                m_displayedImage.texture.dispose();
            }
        }
    }
}