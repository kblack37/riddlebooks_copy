package wordproblem.audio
{
    import flash.net.SharedObject;
    import flash.text.TextFormat;
    
    import feathers.controls.Button;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.resource.AssetManager;
    
    public class AudioButton extends Sprite
    {
        private var m_mainButton:Button;
        
        private var m_defaultSkinOn:DisplayObject;
        private var m_overSkinOn:DisplayObject;
        
        private var m_defaultSkinOff:DisplayObject;
        private var m_overSkinOff:DisplayObject;
        protected var m_localSharedObject:SharedObject;
        
        private var m_onIcon:Image;
        private var m_offIcon:Image;
        
        public function AudioButton(width:Number, 
                                    height:Number, 
                                    textFormatUp:TextFormat, 
                                    textFormatHover:TextFormat, 
                                    assetManager:AssetManager,
                                    labelValue:String,
                                    color:uint)
        {
            super();
            
            m_mainButton = WidgetUtil.createGenericColoredButton(assetManager, color,
                "", textFormatUp, textFormatHover);
            this.addChild(m_mainButton);

            var onIconTexture:Texture = assetManager.getTexture("correct");
            var iconScaleFactor:Number = height / onIconTexture.height * 0.65;
            var onIcon:Image = new Image(onIconTexture);
            onIcon.scaleX = onIcon.scaleY = iconScaleFactor;
            m_onIcon = onIcon;
            
            var offIconTexture:Texture = assetManager.getTexture("wrong");
            iconScaleFactor = height / offIconTexture.height * 0.65;
            var offIcon:Image = new Image(offIconTexture);
            offIcon.scaleX = offIcon.scaleY = iconScaleFactor;
            m_offIcon = offIcon;
            
            m_mainButton.width = width;
            m_mainButton.height = height;
            m_mainButton.label = labelValue;
            m_mainButton.iconPosition = Button.ICON_POSITION_RIGHT;
            m_mainButton.addEventListener(Event.TRIGGERED, onClick);
            m_mainButton.iconOffsetX = onIcon.width * -1;
            
            var preferencesSharedObject:SharedObject = SharedObject.getLocal("preferences");
            m_localSharedObject = preferencesSharedObject;
        }
        
        public function get button():Button
        {
            return m_mainButton;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_mainButton.removeEventListener(Event.TRIGGERED, onClick);
        }
        
        protected function handleClick():void
        {
        }
        
        protected function redrawLabel(value:Boolean):void
        {
            if (value) 
            {
                m_mainButton.defaultIcon = m_onIcon;
            }
            else
            {
                m_mainButton.defaultIcon = m_offIcon;
            }
        }
        
        private function onClick():void
        {
            handleClick();
        }
    }
}