package wordproblem.settings;


import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;
import openfl.text.TextFormat;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.ColorMatrixFilter;

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
class OptionsScreen extends Sprite
{
    /**
     * Hold reference to the skip button because each level might have a different option to
     * disable it.
     */
    private var m_skipButton : LabelButton;
    
    /**
     * Keep track of all the displayed buttons
     */
    private var m_buttons : Array<DisplayObject>;
    
    public function new(screenWidth : Float,
            screenHeight : Float,
            buttonWidth : Float,
            buttonHeight : Float,
            allowSkipping : Bool,
            allowExit : Bool,
            buttonColor : Int,
            assetManager : AssetManager,
            onResume : Dynamic->Void,
            onRestart : Dynamic->Void,
            onSkip : Dynamic->Void,
            onAudioToggle : Dynamic->Void,
            onExit : Dynamic->Void,
			onHelpSelected : Dynamic->Void = null)
    {
        super();
        
        // Create a disabling quad to block out the application behind
        var optionsBackingQuad : Bitmap = new Bitmap(new BitmapData(Std.int(screenWidth), Std.int(screenHeight), false, 0x000000));
        optionsBackingQuad.alpha = 0.5;
        addChild(optionsBackingQuad);
        
        var optionsButtonContainer : Sprite = new Sprite();
        var optionsBackground : Bitmap = new Bitmap(assetManager.getBitmapData("summary_background"));
        optionsButtonContainer.addChild(optionsBackground);
        
        // Button to close menu and resume the game
        m_buttons = new Array<DisplayObject>();
        
        var resumeButton : LabelButton = WidgetUtil.createGenericColoredButton(
                assetManager,
                buttonColor,
				// TODO: uncomment this once cgs library is finished
                "", //StringTable.lookup("resume"),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                );
        var resumeIconBitmapData : BitmapData = assetManager.getBitmapData("arrow_yellow_icon");
        var resumeIcon : Bitmap = new Bitmap(resumeIconBitmapData);
        var resumeIconScale : Float = (buttonHeight * 0.8) / resumeIconBitmapData.height;
        resumeIcon.scaleX = resumeIcon.scaleY = resumeIconScale;
        resumeButton.upState = resumeIcon;
		// TODO: openfl buttons don't have many features; this will need to be fixed
        //resumeButton.iconPosition = Button.ICON_POSITION_RIGHT;
        //resumeButton.iconOffsetX = -resumeIconBitmapData.width * resumeIconScale;
        resumeButton.width = buttonWidth;
        resumeButton.height = buttonHeight;
        resumeButton.addEventListener(MouseEvent.CLICK, onResume);
        m_buttons.push(resumeButton);
        
        if (onHelpSelected != null) 
        {
            var helpButton : LabelButton = WidgetUtil.createGenericColoredButton(
                    assetManager,
                    buttonColor,
                    // TODO: uncomment this once cgs library is finished
					"", //StringTable.lookup("help"),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                    );
            helpButton.width = buttonWidth;
            helpButton.height = buttonHeight;
            helpButton.addEventListener(MouseEvent.CLICK, onHelpSelected);
            m_buttons.push(helpButton);
        }  
		
		// Option to reset the current level from the beginning  
        var resetButton : LabelButton = WidgetUtil.createGenericColoredButton(
                assetManager,
                buttonColor,
				// TODO: uncomment this once cgs library is finished
                "", //StringTable.lookup("restart"),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                );
        resetButton.width = buttonWidth;
        resetButton.height = buttonHeight;
        resetButton.addEventListener(MouseEvent.CLICK, onRestart);
        m_buttons.push(resetButton);
        
        // Button to skip this level
        if (allowSkipping) 
        {
            var skipButton : LabelButton = WidgetUtil.createGenericColoredButton(
                    assetManager,
                    buttonColor,
					// TODO: uncomment this once cgs library is finished
                    "", //StringTable.lookup("skip"),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                    );
            var skipIconBitmapData : BitmapData = assetManager.getBitmapData("busy_icon");
            var skipIcon : Bitmap = new Bitmap(skipIconBitmapData);
            var skipIconScale : Float = (buttonHeight * 0.8) / skipIcon.height;
            skipIcon.scaleX = skipIcon.scaleY = skipIconScale;
            skipButton.upState = skipIcon;
			// TODO: openfl buttons don't have many features; this will need to be fixed
            //skipButton.iconPosition = Button.ICON_POSITION_RIGHT;
            //skipButton.iconOffsetX = -skipIconBitmapData.width * skipIconScale;
            skipButton.width = buttonWidth;
            skipButton.height = buttonHeight;
            skipButton.addEventListener(MouseEvent.CLICK, onSkip);
            m_buttons.push(skipButton);
            m_skipButton = skipButton;
        }
        
        var musicButton : MusicToggleButton = new MusicToggleButton(
			buttonWidth, 
			buttonHeight, 
			new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF), 
			new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF), 
			assetManager, 
			buttonColor
        );
        musicButton.addEventListener(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, onAudioToggle);
        m_buttons.push(musicButton);
        
        var sfxButton : SfxToggleButton = new SfxToggleButton(
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
            var exitButton : LabelButton = WidgetUtil.createGenericColoredButton(
                    assetManager,
                    buttonColor,
					// TODO: uncomment this once cgs library is finished
                    "", //StringTable.lookup("main_menu"),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF)
                    );
            exitButton.width = buttonWidth;
            exitButton.height = buttonHeight;
            exitButton.addEventListener(MouseEvent.CLICK, onExit);
            m_buttons.push(exitButton);
        }
        
        for (button in m_buttons)
        {
            optionsButtonContainer.addChild(button);
            
            // Add audio to each click
            button.addEventListener(MouseEvent.CLICK, function(event : Dynamic) : Void
                    {
                        Audio.instance.playSfx("button_click");
                    });
        }
		
		// Dimension of background depends on the total size of the buttons  
        // plus the spacing for level label name 
        var spacingForName : Float = 50;  //m_levelInformationText.height;  
        var buttonVerticalSpacing : Int = 20;
        var optionsButtonContainerWidth : Float = buttonWidth * 2;
        var optionsButtonContainerHeight : Float = m_buttons.length * (buttonHeight + buttonVerticalSpacing) + buttonVerticalSpacing;
        optionsBackground.width = optionsButtonContainerWidth;
        optionsBackground.height = optionsButtonContainerHeight + spacingForName;
        
		// TODO: uncomment once layout is redesigned
        //WidgetUtil.layoutInList(m_buttons, buttonWidth, buttonHeight, optionsButtonContainerWidth, optionsButtonContainerHeight, spacingForName, buttonVerticalSpacing);
        
        optionsButtonContainer.x = (screenWidth - optionsButtonContainerWidth) * 0.5;
        optionsButtonContainer.y = (screenHeight - optionsButtonContainerHeight) * 0.5;
        addChild(optionsButtonContainer);
    }
    
    public function dispose() : Void
    {
        for (button in m_buttons)
        {
			// TODO: openfl has no way to mass remove all event listeners;
			// this may not dispose of memory properly
			button = null;
            //button.removeEventListeners();
        }
		
		m_buttons = new Array<DisplayObject>();
    }
    
    public function toggleSkipButtonEnabled(value : Bool) : Void
    {
        if (m_skipButton != null) 
        {
            if (value) 
            {
				m_skipButton.filters = new Array<BitmapFilter>();
            }
            else 
            {
				var filters = m_skipButton.filters.copy();
				filters.push(XColor.getGrayscaleFilter());
				m_skipButton.filters = filters;
            }
            m_skipButton.enabled = value;
        }
    }
}
