package wordproblem.creator
{
    import feathers.controls.Button;
    
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.textures.Texture;
    
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.resource.AssetManager;
    
    /**
     * This component is used by the problem creation mode so the user can choose their own
     * background for the problem.
     * 
     * The user scrolls through each background one by one so it is assumed we won't have too many backgrounds to
     * pick from.
     */
    public class ScrollOptionsPicker extends Sprite
    {
        private var m_options:Vector.<Object>;
        
        private var m_scrollLeftButton:Button;
        private var m_scrollRightButton:Button;
        
        /**
         * Shows the name of the current selection
         */
        private var m_label:TextField;
        
        private var m_currentSelectedIndex:int;
        
        /**
         * Callback whenever the player changes the selected option by scrolling to
         * it or setting it manually.
         */
        private var m_optionChangedCallback:Function;
        
        public function ScrollOptionsPicker(assetManager:AssetManager, 
                                            optionChangedCallback:Function)
        {
            super();
            
            var arrowTexture:Texture = assetManager.getTexture("arrow_short");
            var scaleFactor:Number = 1.0;
            var leftUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor);
            var leftOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor, 0xCCCCCC);
            
            m_scrollLeftButton = WidgetUtil.createButtonFromImages(
                leftUpImage,
                leftOverImage,
                null,
                leftOverImage,
                null,
                null,
                null
            );
            m_scrollLeftButton.addEventListener(Event.TRIGGERED, onLeftClicked);
            m_scrollLeftButton.scaleWhenDown = 0.9;
            m_scrollLeftButton.scaleWhenHovering = 1.1;
            addChild(m_scrollLeftButton);
            
            var rightUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xFFFFFF);
            var rightOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xCCCCCC);
            m_scrollRightButton = WidgetUtil.createButtonFromImages(
                rightUpImage,
                rightOverImage,
                null,
                rightOverImage,
                null,
                null,
                null
            );
            m_scrollRightButton.addEventListener(Event.TRIGGERED, onRightClicked);
            m_scrollRightButton.scaleWhenDown = 0.9;
            m_scrollRightButton.scaleWhenHovering = 1.1;
            addChild(m_scrollRightButton);
            
            m_label = new TextField(200, 60, "", GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF);
            addChild(m_label);
            
            // TODO: Button widths do not get set here, alignment will not fit
            m_label.x = 40;//m_scrollLeftButton.width + m_scrollLeftButton.x;
            
            m_scrollRightButton.x = m_label.x + m_label.width;
            m_currentSelectedIndex = -1;
            
            setOptionChangedCallback(optionChangedCallback);
        }
        
        /**
         *
         * @param optionChangedCallback
         *      signature callback(index:int, data:Object):void
         */
        public function setOptionChangedCallback(value:Function):void
        {
            m_optionChangedCallback = value;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_scrollLeftButton.removeEventListener(Event.TRIGGERED, onLeftClicked);
            m_scrollRightButton.removeEventListener(Event.TRIGGERED, onRightClicked);
        }
        
        public function setOptions(options:Vector.<Object>):void
        {
            m_options = options;
        }
        
        public function showOptionAtIndex(index:int):void
        {
            if (index >= 0 && index < m_options.length)
            {
                // HACK: Assuming the data has a field
                var selectedOptionData:Object = m_options[index];
                m_label.text = selectedOptionData.text
                
                if (m_optionChangedCallback != null)
                {
                    m_optionChangedCallback(index, selectedOptionData);
                }
            }
            m_currentSelectedIndex = index;
        }
        
        public function getCurrentlySelectedOptionData():Object
        {
            var selectedOptionData:Object = null;
            if (m_currentSelectedIndex >= 0 && m_currentSelectedIndex < m_options.length)
            {
                selectedOptionData = m_options[m_currentSelectedIndex];
            }
            return selectedOptionData;
        }
        
        private function onLeftClicked():void
        {
            var nextIndex:int = m_currentSelectedIndex - 1;
            if (nextIndex < 0)
            {
                nextIndex = m_options.length - 1;
            }
            showOptionAtIndex(nextIndex);
        }
        
        private function onRightClicked():void
        {
            var nextIndex:int = m_currentSelectedIndex + 1;
            if (nextIndex > m_options.length - 1)
            {
                nextIndex = 0;
            }
            showOptionAtIndex(nextIndex);
        }
    }
}