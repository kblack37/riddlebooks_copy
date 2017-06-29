package wordproblem.summary;


import flash.text.TextFormat;

import cgs.internationalization.StringTable;

import feathers.controls.Button;

import starling.animation.Juggler;
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Quad;
import starling.events.Event;
import starling.textures.Texture;

import wordproblem.display.Layer;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.player.ButtonColorData;
import wordproblem.resource.AssetManager;

/**
 * This probably contains too much logic that should instead be handled by the script
 */
class SummaryWidget extends Layer
{
    public var totalScreenWidth : Float;
    public var totalScreenHeight : Float;
    
    /**
     * Button for the player to go to the next level
     */
    public var nextButton : Button;
    
    /**
     * Button for the player to exit the game screen and return to either a level select
     * or waiting screen.
     */
    public var exitButton : Button;
    
    private var m_assetManager : AssetManager;
    
    /**
     * Keep a separate juggler for the large set of tweens
     */
    private var m_juggler : Juggler;
    
    /**
     * Callback when the next button is pressed
     */
    private var m_onNextPressedCallback : Function;
    
    /**
     * Callback when the exit button is pressed
     */
    private var m_onExitPressedCallback : Function;
    
    /**
     * A disabling background
     */
    private var m_obscuringBackground : Quad;
    
    /**
     * The background picture. Hold reference since we want to apply a tween to it later.
     */
    private var m_backgroundImage : DisplayObject;
    
    private var m_buttonColorData : ButtonColorData;
    
    public function new(assetManager : AssetManager,
            onNextPressedCallback : Function,
            onExitPressedCallback : Function,
            juggler : Juggler,
            allowExit : Bool,
            totalScreenWidth : Float,
            totalScreenHeight : Float,
            buttonColorData : ButtonColorData)
    {
        super();
        
        m_assetManager = assetManager;
        m_onNextPressedCallback = onNextPressedCallback;
        m_onExitPressedCallback = onExitPressedCallback;
        m_juggler = juggler;
        this.totalScreenWidth = totalScreenWidth;
        this.totalScreenHeight = totalScreenHeight;
        m_buttonColorData = buttonColorData;
        
        // Add a blackish blocking sprite to fill in the space not covered by the background
        m_obscuringBackground = new Quad(totalScreenWidth, totalScreenHeight, 0x000000);
        m_obscuringBackground.alpha = 0.3;
        
        // Add the actual background texture
        var backgroundTexture : Texture = m_assetManager.getTexture("summary_background");
        var backgroundImage : Image = new Image(backgroundTexture);
        backgroundImage.width = totalScreenWidth;
        backgroundImage.height = totalScreenHeight;
        backgroundImage.x = 0;
        backgroundImage.y = 0;
        
        m_backgroundImage = backgroundImage;
        
        if (allowExit) 
        {
            exitButton = WidgetUtil.createGenericColoredButton(
                            m_assetManager,
                            m_buttonColorData.getUpButtonColor(),
                            StringTable.lookup("exit"),
                            new TextFormat(GameFonts.DEFAULT_FONT_NAME, 
                            16, 
                            0xFFFFFF, 
                            ),
                            null
                            );
            exitButton.width = 80;
            exitButton.height = 30;
            exitButton.pivotX = exitButton.width * 0.5;
            exitButton.scaleWhenDown = 0.9;
            exitButton.addEventListener(Event.TRIGGERED, onExitClicked);
        }
        
        nextButton = WidgetUtil.createGenericColoredButton(
                        m_assetManager,
                        m_buttonColorData.getUpButtonColor(),
                        StringTable.lookup("next"),
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF),
                        null
                        );
        var nextIcon : Image = new Image(assetManager.getTexture("arrow_yellow_icon"));
        nextIcon.scaleX = nextIcon.scaleY = 1.5;
        nextButton.defaultIcon = nextIcon;
        nextButton.iconPosition = Button.ICON_POSITION_RIGHT;
        nextButton.iconOffsetX = -50;
        nextButton.width = 250;
        nextButton.height = 70;
        nextButton.pivotX = nextButton.width * 0.5;
        nextButton.scaleWhenDown = 0.9;
        nextButton.addEventListener(Event.TRIGGERED, onNextClicked);
    }
    
    public function show(onSlideComplete : Function) : Void
    {
        // Make sure the buttons are the right color
        WidgetUtil.changeColorForGenericButton(nextButton, m_buttonColorData.getUpButtonColor());
        if (exitButton != null) 
        {
            WidgetUtil.changeColorForGenericButton(exitButton, m_buttonColorData.getUpButtonColor());
        }  // Have the background slam downward  
        
        
        
        addChild(m_obscuringBackground);
        addChild(m_backgroundImage);
        m_backgroundImage.y = -800;
        var backgroundAppearTween : Tween = new Tween(m_backgroundImage, 0.7, Transitions.EASE_OUT_ELASTIC);
        backgroundAppearTween.animate("y", 0);
        backgroundAppearTween.onComplete = backgroundAppearTweenComplete;
        m_juggler.add(backgroundAppearTween);
        
        // Next and exit buttons are initially not visible
        if (exitButton != null) 
        {
            addChild(exitButton);
            exitButton.visible = false;
        }
        addChild(nextButton);
        nextButton.visible = false;
        
        function backgroundAppearTweenComplete() : Void
        {
            // Show buttons
            if (exitButton != null) 
            {
                exitButton.x = totalScreenWidth - exitButton.width - 50;
                exitButton.y = 540;
                exitButton.visible = true;
            }
            nextButton.x = 400;
            nextButton.y = 510;
            nextButton.visible = true;
            
            if (onSlideComplete != null) 
            {
                onSlideComplete();
            }
        };
    }
    
    /**
     * Clear out all previous assets so this widget can be reused later
     */
    public function reset() : Void
    {
        m_juggler.purge();
        
        this.removeChildren();
    }
    
    override public function dispose() : Void
    {
        m_obscuringBackground.removeFromParent(true);
        
        if (exitButton != null) 
        {
            exitButton.removeEventListener(Event.TRIGGERED, onExitClicked);
            exitButton.removeFromParent(true);
        }
        nextButton.removeEventListener(Event.TRIGGERED, onNextClicked);
        nextButton.removeFromParent(true);
        
        m_onNextPressedCallback = null;
        m_onExitPressedCallback = null;
        
        this.reset();
        
        super.dispose();
    }
    
    private function onNextClicked() : Void
    {
        if (m_onNextPressedCallback != null) 
        {
            m_onNextPressedCallback();
        }
    }
    
    private function onExitClicked() : Void
    {
        if (m_onExitPressedCallback != null) 
        {
            m_onExitPressedCallback();
        }
    }
}
