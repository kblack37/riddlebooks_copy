package wordproblem.settings;


import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextFormat;
import wordproblem.display.DisposableSprite;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;

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
class OptionsWidget extends DisposableSprite
{
    public static inline var OPTION_MUSIC : String = "music";
    public static inline var OPTION_SFX : String = "sfx";
    public static inline var OPTION_CREDITS : String = "credits";
    public static inline var OPTION_RESET : String = "reset";
    
    /**
     * Button that opens the menu options (these are to toggle on and off sounds and show credits)
     */
    private var m_optionsButton : OptionButton;
    
    /**
     * This is the container for all the options. Fades in and out as the player presses the options.
     */
    private var m_optionsButtonContainer : Sprite;
    
    /**
     * Callback if the credits button was clicked
     */
    private var m_creditsClickedCallback : Function;
    
    /**
     * Callback if the reset button was clicked
     */
    private var m_resetClickedCallback : Function;
    
    /**
     * List of all buttons that should play click audio
     */
    private var m_buttonsAudio : Array<DisplayObject>;
    
    /**
     * @param options
     *      ordered list of options that should be displayed
     */
    public function new(assetManager : AssetManager,
            options : Array<String>,
            creditsClickedCallback : Function,
            resetClickedCallback : Function,
            color : Int)
    {
        super();
        
        m_buttonsAudio = new Array<DisplayObject>();
        
        // Add button to open options
        m_optionsButton = new OptionButton(assetManager, color, onOptionsButtonClicked);
        addChild(m_optionsButton);
        m_buttonsAudio.push(m_optionsButton);
        
        m_creditsClickedCallback = creditsClickedCallback;
        m_resetClickedCallback = resetClickedCallback;
        
        // Add a container for buttons representing the options
        // Options are just toggle music, toggle sound effects, show credits
        var optionsButtonContainer : Sprite = new Sprite();
        var optionsContainerWidth : Float = 100;
        
        var buttonWidth : Float = 92;
        var buttonHeight : Float = 33;
        var gap : Float = 10;
        var buttons : Array<DisplayObject> = new Array<DisplayObject>();
        var audioDriver : Audio = Audio.instance;
        
        // Create each option make sure it is in the right order
        var button : DisplayObject = null;
        for (optionName in options){
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
                var callbackFunction : Dynamic->Void = null;
                var buttonTextLabel : String = null;
                if (optionName == OPTION_CREDITS) 
                {
                    callbackFunction = onCreditsClicked;
					// TODO: uncomment when cgs library is finished
                    buttonTextLabel = "";// StringTable.lookup("credits");
                }
                else if (optionName == OPTION_RESET) 
                {
                    callbackFunction = onResetClicked;
                    // TODO: uncomment when cgs library is finished
					buttonTextLabel = "";// StringTable.lookup("reset");
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
                button.addEventListener(MouseEvent.CLICK, callbackFunction);
            }
            
            m_buttonsAudio.push(button);
            buttons.push(button);
            optionsButtonContainer.addChild(button);
        }
        
        var optionsContainerHeight : Float = (buttonHeight + gap) * buttons.length + gap;
        var optionsBackground : Bitmap = new Bitmap(new BitmapData(Std.int(optionsContainerWidth), Std.int(optionsContainerHeight), false, 0x000000));
        optionsBackground.alpha = 0.5;
        optionsButtonContainer.addChildAt(optionsBackground, 0);
        m_optionsButtonContainer = optionsButtonContainer;
        
        // Layout in list
		// TODO: uncomment when layout is redesigned
        //WidgetUtil.layoutInList(buttons, buttonWidth, buttonHeight, optionsContainerWidth, optionsContainerHeight, 0);
        
        // Add audio to clicks on the buttons
        for (button in m_buttonsAudio)
        {
            if (Std.is(button, LabelButton)) 
            {
                button.addEventListener(MouseEvent.CLICK, onButtonPlayClickAudio);
            }
            else if (Std.is(button, AudioButton)) 
            {
                (try cast(button, AudioButton) catch(e:Dynamic) null).button.addEventListener(MouseEvent.CLICK, onButtonPlayClickAudio);
            }
        }
    }
    
    public function isOpen() : Bool
    {
        return m_optionsButtonContainer.parent != null;
    }
    
    public function toggleOptionsOpen(value : Bool) : Void
    {
        // Toggle show hide options button
        if (value && m_optionsButtonContainer.parent == null) 
        {
            m_optionsButtonContainer.x = m_optionsButton.x;
            m_optionsButtonContainer.y = m_optionsButton.y - m_optionsButtonContainer.height;
            addChild(m_optionsButtonContainer);
            
            m_optionsButtonContainer.alpha = 0.0;
			Actuate.tween(m_optionsButtonContainer, 0.3, { alpha: 1 });
        }
        else if (!value) 
        {
			Actuate.tween(m_optionsButtonContainer, 0.3, { alpha: 0}).onComplete(function() : Void
                {
                    if (m_optionsButtonContainer.parent != null) 
                    {
                        if (m_optionsButtonContainer.parent != null) m_optionsButtonContainer.parent.removeChild(m_optionsButtonContainer);
                    }
                }
            );
        }
    }
    
    override public function dispose() : Void
    {
		super.dispose();
		
        // Remove the audio click listeners for every button
        for (button in m_buttonsAudio)
        {
            if (Std.is(button, LabelButton)) 
            {
				var castedButton = try cast(button, LabelButton) catch (e : Dynamic) null;
				castedButton.removeEventListener(MouseEvent.CLICK, onButtonPlayClickAudio);
				castedButton.dispose();
            }
            else if (Std.is(button, AudioButton)) 
            {
                var castedButton = try cast(button, AudioButton) catch (e:Dynamic) null;
				castedButton.button.removeEventListener(MouseEvent.CLICK, onButtonPlayClickAudio);
				castedButton.dispose();
            }
        }
        
		if (m_optionsButton.parent != null) m_optionsButton.parent.removeChild(m_optionsButton);
		m_optionsButton.dispose();
    }
    
    private function onOptionsButtonClicked() : Void
    {
        toggleOptionsOpen(!isOpen());
    }
    
    private function onCreditsClicked(event : Dynamic) : Void
    {
        onOptionsButtonClicked();
        
        if (m_creditsClickedCallback != null) 
        {
            m_creditsClickedCallback();
        }
    }
    
    private function onResetClicked(event : Dynamic) : Void
    {
        onOptionsButtonClicked();
        
        if (m_resetClickedCallback != null) 
        {
            m_resetClickedCallback();
        }
    }
    
    private function onButtonPlayClickAudio(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
    }
}
