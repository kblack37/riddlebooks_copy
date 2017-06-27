package wordproblem.settings
{
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    import cgs.internationalization.StringTable;
    
    import feathers.controls.Button;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    
    import wordproblem.audio.AudioButton;
    import wordproblem.audio.MusicToggleButton;
    import wordproblem.audio.SfxToggleButton;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.resource.AssetManager;
    
    /**
     * The small ui segment for adjusting options.
     * 
     * It is just a single button that expands.
     * 
     * It can be adjusted to remove certain options.
     */
    public class OptionsWidget extends Sprite
    {
        public static const OPTION_MUSIC:String = "music";
        public static const OPTION_SFX:String = "sfx";
        public static const OPTION_CREDITS:String = "credits";
        public static const OPTION_RESET:String = "reset";
        
        /**
         * Button that opens the menu options (these are to toggle on and off sounds and show credits)
         */
        private var m_optionsButton:OptionButton;
        
        /**
         * This is the container for all the options. Fades in and out as the player presses the options.
         */
        private var m_optionsButtonContainer:Sprite;
        
        /**
         * Callback if the credits button was clicked
         */
        private var m_creditsClickedCallback:Function;
        
        /**
         * Callback if the reset button was clicked
         */
        private var m_resetClickedCallback:Function;
        
        /**
         * List of all buttons that should play click audio
         */
        private var m_buttonsAudio:Vector.<DisplayObject>;
        
        /**
         * @param options
         *      ordered list of options that should be displayed
         */
        public function OptionsWidget(assetManager:AssetManager, 
                                      options:Vector.<String>, 
                                      creditsClickedCallback:Function, 
                                      resetClickedCallback:Function, 
                                      color:uint)
        {
            super();
            
            m_buttonsAudio = new Vector.<DisplayObject>();
            
            // Add button to open options
            m_optionsButton = new OptionButton(assetManager, color, onOptionsButtonClicked);
            addChild(m_optionsButton);
            m_buttonsAudio.push(m_optionsButton);
            
            m_creditsClickedCallback = creditsClickedCallback;
            m_resetClickedCallback = resetClickedCallback;
            
            // Add a container for buttons representing the options
            // Options are just toggle music, toggle sound effects, show credits
            var optionsButtonContainer:Sprite = new Sprite();
            var optionsContainerWidth:Number = 100;
            
            var buttonWidth:Number = 92;
            var buttonHeight:Number = 33;
            var gap:Number = 10;
            var buttons:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            var audioDriver:Audio = Audio.instance;
            
            // Create each option make sure it is in the right order
            var i:int;
            var numOptions:int = options.length;
            var optionName:String;
            var button:DisplayObject;
            for (i < 0; i < numOptions; i++)
            {
                optionName = options[i];
                if (optionName == OPTION_MUSIC)
                {
                    button = new MusicToggleButton(
                        buttonWidth, 
                        buttonHeight, 
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 14, 0xFFFFFF),
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 14, 0xFFFFFF),
                        assetManager,
                        color
                    );
                }
                else if (optionName == OPTION_SFX)
                {
                    button = new SfxToggleButton(
                        buttonWidth, 
                        buttonHeight, 
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 14, 0xFFFFFF),
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 14, 0xFFFFFF),
                        assetManager,
                        color
                    );
                }
                else
                {
                    var callbackFunction:Function = null;
                    var buttonTextLabel:String = null;
                    if (optionName == OPTION_CREDITS)
                    {
                        callbackFunction = onCreditsClicked;
                        buttonTextLabel = StringTable.lookup("credits");
                    }
                    else if (optionName == OPTION_RESET)
                    {
                        callbackFunction = onResetClicked;
                        buttonTextLabel = StringTable.lookup("reset");
                    }
                    
                    button = WidgetUtil.createGenericColoredButton(
                        assetManager, 
                        color,
                        buttonTextLabel, 
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF)
                    );
                    button.width = buttonWidth;
                    button.height = buttonHeight;
                    button.addEventListener(Event.TRIGGERED, callbackFunction);
                }
                
                m_buttonsAudio.push(button);
                buttons.push(button);
                optionsButtonContainer.addChild(button);
            }
            
            var optionsContainerHeight:Number = (buttonHeight + gap) * buttons.length + gap;
            var optionsBackground:Quad = new Quad(optionsContainerWidth, optionsContainerHeight, 0x000000);
            optionsBackground.alpha = 0.5;
            optionsButtonContainer.addChildAt(optionsBackground, 0);
            m_optionsButtonContainer = optionsButtonContainer;
            
            // Layout in list
            WidgetUtil.layoutInList(buttons, buttonWidth, buttonHeight, optionsContainerWidth, optionsContainerHeight, 0);
            
            // Add audio to clicks on the buttons
            for each (button in m_buttonsAudio)
            {
                if (button is Button)
                {
                    button.addEventListener(Event.TRIGGERED, onButtonPlayClickAudio);
                }
                else if (button is AudioButton)
                {
                    (button as AudioButton).button.addEventListener(Event.TRIGGERED, onButtonPlayClickAudio);
                }
            }
        }
        
        public function isOpen():Boolean
        {
            return m_optionsButtonContainer.parent != null;
        }
        
        public function toggleOptionsOpen(value:Boolean):void
        {
            // Toggle show hide options button
            if (value && m_optionsButtonContainer.parent == null)
            {
                m_optionsButtonContainer.x = m_optionsButton.x;
                m_optionsButtonContainer.y = m_optionsButton.y - m_optionsButtonContainer.height;
                addChild(m_optionsButtonContainer);
                
                m_optionsButtonContainer.alpha = 0.0;
                Starling.juggler.tween(m_optionsButtonContainer, 0.3, {alpha: 1.0});
            }
            else if (!value)
            {
                Starling.juggler.tween(m_optionsButtonContainer, 0.3, {
                    alpha: 0.0,
                    onComplete: function():void
                    {
                        if (m_optionsButtonContainer.parent)
                        {
                            m_optionsButtonContainer.removeFromParent();
                        }
                    }
                });
            }
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            // Remove the audio click listeners for every button
            for each (var button:Button in m_buttonsAudio)
            {
                if (button is Button)
                {
                    button.removeEventListeners();
                }
                else if (button is AudioButton)
                {
                    (button as AudioButton).button.removeEventListeners();
                }
                button.dispose();
            }
            
            m_optionsButton.removeFromParent(true);
        }
        
        private function onOptionsButtonClicked():void
        {
            toggleOptionsOpen(!isOpen());
        }
        
        private function onCreditsClicked():void
        {
            onOptionsButtonClicked();
            
            if (m_creditsClickedCallback != null)
            {
                m_creditsClickedCallback();
            }
        }
        
        private function onResetClicked():void
        {
            onOptionsButtonClicked();
            
            if (m_resetClickedCallback != null)
            {
                m_resetClickedCallback();
            }
        }
        
        private function onButtonPlayClickAudio():void
        {
            Audio.instance.playSfx("button_click");
        }
    }
}