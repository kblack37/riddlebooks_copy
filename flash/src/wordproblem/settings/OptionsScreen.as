package wordproblem.settings
{
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    import cgs.internationalization.StringTable;
    
    import feathers.controls.Button;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.filters.ColorMatrixFilter;
    import starling.textures.Texture;
    
    import wordproblem.audio.MusicToggleButton;
    import wordproblem.audio.SfxToggleButton;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    /**
     * While playing a level, the user can option up a menu of options that will pause
     * and disable the application behind it.
     * 
     * The options available will include things like quiting, restarting, or adjusting sound
     */
    public class OptionsScreen extends Sprite
    {
        /**
         * Hold reference to the skip button because each level might have a different option to
         * disable it.
         */
        private var m_skipButton:Button;
        
        /**
         * Keep track of all the displayed buttons
         */
        private var m_buttons:Vector.<DisplayObject>;
        
        public function OptionsScreen(screenWidth:Number, 
                                      screenHeight:Number, 
                                      buttonWidth:Number, 
                                      buttonHeight:Number, 
                                      allowSkipping:Boolean,
                                      allowExit:Boolean,
                                      buttonColor:uint,
                                      assetManager:AssetManager,
                                      onResume:Function, 
                                      onRestart:Function, 
                                      onSkip:Function, 
                                      onAudioToggle:Function, 
                                      onExit:Function, onHelpSelected:Function=null)
        {
            super();
            
            // Create a disabling quad to block out the application behind
            var optionsBackingQuad:Quad = new Quad(screenWidth, screenHeight, 0x000000);
            optionsBackingQuad.alpha = 0.5;
            addChild(optionsBackingQuad);
            
            var optionsButtonContainer:Sprite = new Sprite();
            var optionsBackground:Image = new Image(assetManager.getTexture("summary_background"));
            optionsButtonContainer.addChild(optionsBackground);
            
            // Button to close menu and resume the game
            m_buttons = new Vector.<DisplayObject>();
            
            var resumeButton:Button = WidgetUtil.createGenericColoredButton(
                assetManager,
                buttonColor,
                StringTable.lookup("resume"), 
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
            );
            var resumeIconTexture:Texture = assetManager.getTexture("arrow_yellow_icon");
            var resumeIcon:Image = new Image(resumeIconTexture);
            var resumeIconScale:Number = (buttonHeight * 0.8) / resumeIconTexture.height;
            resumeIcon.scaleX = resumeIcon.scaleY = resumeIconScale;
            resumeButton.defaultIcon = resumeIcon;
            resumeButton.iconPosition = Button.ICON_POSITION_RIGHT;
            resumeButton.iconOffsetX = -resumeIconTexture.width * resumeIconScale;
            resumeButton.width = buttonWidth;
            resumeButton.height = buttonHeight;
            resumeButton.addEventListener(Event.TRIGGERED, onResume);
            m_buttons.push(resumeButton);
            
            if (onHelpSelected != null)
            {
                var helpButton:Button = WidgetUtil.createGenericColoredButton(
                    assetManager,
                    buttonColor,
                    StringTable.lookup("help"), 
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                );
                helpButton.width = buttonWidth;
                helpButton.height = buttonHeight;
                helpButton.addEventListener(Event.TRIGGERED, onHelpSelected);
                m_buttons.push(helpButton);
            }
            
            // Option to reset the current level from the beginning
            var resetButton:Button = WidgetUtil.createGenericColoredButton(
                assetManager,
                buttonColor,
                StringTable.lookup("restart"), 
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
            );
            resetButton.width = buttonWidth;
            resetButton.height = buttonHeight;
            resetButton.addEventListener(Event.TRIGGERED, onRestart);
            m_buttons.push(resetButton);
            
            // Button to skip this level
            if (allowSkipping)
            {
                var skipButton:Button = WidgetUtil.createGenericColoredButton(
                    assetManager,
                    buttonColor,
                    StringTable.lookup("skip"),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                );
                var skipIconTexture:Texture = assetManager.getTexture("busy_icon");
                var skipIcon:Image = new Image(skipIconTexture);
                var skipIconScale:Number = (buttonHeight * 0.8) / skipIcon.height;
                skipIcon.scaleX = skipIcon.scaleY = skipIconScale;
                skipButton.defaultIcon = skipIcon;
                skipButton.iconPosition = Button.ICON_POSITION_RIGHT;
                skipButton.iconOffsetX = -skipIconTexture.width * skipIconScale;
                skipButton.width = buttonWidth;
                skipButton.height = buttonHeight;
                skipButton.addEventListener(Event.TRIGGERED, onSkip);
                m_buttons.push(skipButton);
                m_skipButton = skipButton;
            }
            
            var musicButton:MusicToggleButton = new MusicToggleButton(
                buttonWidth, 
                buttonHeight, 
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF), 
                assetManager,
                buttonColor
            );
            musicButton.addEventListener(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, onAudioToggle);
            m_buttons.push(musicButton);
            
            var sfxButton:SfxToggleButton = new SfxToggleButton(
                buttonWidth, 
                buttonHeight,
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF), 
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF), 
                assetManager,
                buttonColor
            );
            sfxButton.addEventListener(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, onAudioToggle);
            m_buttons.push(sfxButton);
            
            if (allowExit)
            {
                var exitButton:Button = WidgetUtil.createGenericColoredButton(
                    assetManager,
                    buttonColor,
                    StringTable.lookup("main_menu"), 
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                );
                exitButton.width = buttonWidth;
                exitButton.height = buttonHeight;
                exitButton.addEventListener(Event.TRIGGERED, onExit);
                m_buttons.push(exitButton);
            }
            
            for each (var button:DisplayObject in m_buttons)
            {                
                optionsButtonContainer.addChild(button);
                
                // Add audio to each click
                button.addEventListener(Event.TRIGGERED, function():void
                {
                    Audio.instance.playSfx("button_click"); 
                });
            }
            
            // Dimension of background depends on the total size of the buttons
            // plus the spacing for level label name
            var spacingForName:Number = 50;//m_levelInformationText.height;
            var buttonVerticalSpacing:int = 20;
            var optionsButtonContainerWidth:Number = buttonWidth * 2;
            var optionsButtonContainerHeight:Number = m_buttons.length * (buttonHeight + buttonVerticalSpacing) + buttonVerticalSpacing;
            optionsBackground.width = optionsButtonContainerWidth;
            optionsBackground.height = optionsButtonContainerHeight + spacingForName;
            
            WidgetUtil.layoutInList(m_buttons, buttonWidth, buttonHeight, optionsButtonContainerWidth, optionsButtonContainerHeight, spacingForName, buttonVerticalSpacing);
            
            optionsButtonContainer.x = (screenWidth - optionsButtonContainerWidth) * 0.5;
            optionsButtonContainer.y = (screenHeight - optionsButtonContainerHeight) * 0.5;
            addChild(optionsButtonContainer);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            for each (var button:DisplayObject in m_buttons)
            {
                button.removeEventListeners();
            }
        }
        
        public function toggleSkipButtonEnabled(value:Boolean):void
        {
            if (m_skipButton != null)
            {
                if (value)
                {
                    m_skipButton.filter = null; 
                }
                else
                {
                    var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter();
                    colorMatrixFilter.adjustSaturation(-1);
                    m_skipButton.filter = colorMatrixFilter;
                }
                m_skipButton.isEnabled = value;
            }
        }
    }
}