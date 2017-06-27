package wordproblem.credits
{
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    import cgs.internationalization.StringTable;
    
    import feathers.controls.Button;
    
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.textures.Texture;
    
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.MeasuringTextField;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.resource.AssetManager;
    
    /**
     * A screen used to give credits to various parties for using their resources
     */
    public class CreditsWidget extends Sprite
    {
        private var m_onCloseCallback:Function;
        
        public function CreditsWidget(width:Number, 
                                      height:Number, 
                                      assetManager:AssetManager, 
                                      onCloseCallback:Function, 
                                      buttonColor:uint)
        {
            super();
            
            m_onCloseCallback = onCloseCallback;
            
            // Add darkened background sprite
            var backgroundQuad:Quad = new Quad(width, height, 0x000000);
            backgroundQuad.alpha = 0.5;
            addChild(backgroundQuad);
            
            // Add actual background image
            var backgroundContainer:Sprite = new Sprite();
            var backgroundContainerWidth:Number = 600;
            var backgroundContainerHeight:Number = 450;
            backgroundContainer.x = (width - backgroundContainerWidth) * 0.5;
            backgroundContainer.y = (height - backgroundContainerHeight) * 0.5;
            addChild(backgroundContainer);
            
            var backgroundImage:Image = new Image(assetManager.getTexture("summary_background"));
            backgroundImage.width = backgroundContainerWidth;
            backgroundImage.height = backgroundContainerHeight;
            backgroundContainer.addChild(backgroundImage);
            
            var measuringTextField:MeasuringTextField = new MeasuringTextField();
            var textFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF);
            measuringTextField.defaultTextFormat = textFormat;
            
            var titleText:String = StringTable.lookup("credits");
            var titleTextField:TextField = new TextField(
                300,
                70,
                titleText,
                textFormat.font,
                36,
                0x3399FF
            );
            titleTextField.underline = true;
            titleTextField.x = (backgroundContainerWidth - titleTextField.width) * 0.5;
            titleTextField.y = 10;
            backgroundContainer.addChild(titleTextField);
            
            var centerForGameScienceText:String = "Produced by the Center for Game Science at the University of Washington";
            var centerForGameScienceTextField:TextField = new TextField(
                450,
                100,
                centerForGameScienceText,
                textFormat.font,
                22,
                textFormat.color as uint
            );
            centerForGameScienceTextField.x = (backgroundContainerWidth - centerForGameScienceTextField.width) * 0.5;
            centerForGameScienceTextField.y = 50;
            backgroundContainer.addChild(centerForGameScienceTextField);
            
            var cgsLogoTexture:Texture = assetManager.getTexture("cgs_logo");
            var cgsLogo:Image = new Image(cgsLogoTexture);
            cgsLogo.x = (backgroundContainerWidth - cgsLogoTexture.width) * 0.5;
            cgsLogo.y = centerForGameScienceTextField.y + centerForGameScienceTextField.height;
            backgroundContainer.addChild(cgsLogo);
            
            // Add button to close this screen
            var backButton:Button = WidgetUtil.createGenericColoredButton(
                assetManager, buttonColor,
                StringTable.lookup("back"), 
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF)
            );
            backButton.addEventListener(Event.TRIGGERED, onTriggered);
            
            var backButtonWidth:Number = 200;
            backButton.width = backButtonWidth;
            backButton.x = (backgroundContainerWidth - backButtonWidth) * 0.5;
            backButton.y = backgroundContainerHeight - 70;
            backgroundContainer.addChild(backButton);
        }
        
        private function onTriggered():void
        {
            Audio.instance.playSfx("button_click");
            
            this.removeFromParent();
            
            if (m_onCloseCallback != null)
            {
                m_onCloseCallback();
            }
        }
    }
}