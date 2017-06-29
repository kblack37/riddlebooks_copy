package wordproblem.hints.scripts;

import wordproblem.hints.scripts.IShowableScript;

import flash.geom.Rectangle;

import cgs.internationalization.StringTable;

import feathers.controls.Button;
import feathers.textures.Scale9Textures;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.filters.ColorMatrixFilter;
import starling.text.TextField;
import starling.textures.Texture;
import starling.utils.HAlign;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.hints.HintScript;
import wordproblem.player.ButtonColorData;
import wordproblem.resource.AssetManager;

/**
 * This class controls the rendering of the hint list that appears within the hint screen.
 * 
 * It is like the ui controller and the renderer for that section
 */
class HintsViewer extends ScriptNode implements IShowableScript
{
    private inline var NO_HINTS_AVAILABLE : String = "Sorry, I don't have any help right now!";
    private inline var NO_HINTS_UNLOCKED : String = "Click the button below to ask for help!";
    
    private var m_gameEngine : IGameEngine;
    private var m_assetManager : AssetManager;
    private var m_width : Float;
    private var m_height : Float;
    
    /**
     * List of all original hints that are viewable through the hint screen.
     */
    private var m_availableHints : Array<HintScript>;
    
    private var m_lockedHints : Array<HintScript>;
    
    private var m_unlockedHints : Array<HintScript>;
    
    /**
     * The container is which to draw everything to
     */
    private var m_canvas : DisplayObjectContainer;
    
    /**
     * Container for each hint's rendering of its description.
     * Appears in side the though bubble
     */
    private var m_descriptionContainer : Sprite;
    
    /**
     * Need to keep a reference to clean up the old hint after the index has already been updated
     */
    private var m_currentHintShown : HintScript;
    
    /**
     * The current rendered description object. Null if no description showing
     */
    private var m_currentDescriptionViewShown : DisplayObject;
    
    /**
     * Indicator for total number of hints available to view and the current hint
     * being viewed
     */
    private var m_pageIndicatorText : TextField;
    
    /**
     * From the set of unlocked hints that are visible
     */
    private var m_currentHintIndex : Int;
    
    /**
     * Button to request that the current hint contents be shown/executed while the
     * level contents are visible
     */
    private var m_showHintButton : Button;
    
    /**
     * Button to unlock a new hint
     */
    private var m_newHintButton : Button;
    
    /**
     * Button to scroll to the left if multiple hints available
     */
    private var m_leftScrollButton : Button;
    
    /**
     * Button to scroll to the right if multiple hints available
     */
    private var m_rightScrollButton : Button;
    
    /**
     * Text to show if no hint is available to display
     */
    private var m_noHintDescription : TextField;
    
    /*
    All visible hints re-use the same background assets so we can hold onto the same images
    to create the thought bubbles
    */
    private var m_thoughtBubbleA : Image;
    private var m_thoughtBubbleB : Image;
    private var m_thoughtBubbleMain : Image;
    
    private var m_thoughtBubbleWidth : Float = 510;
    private var m_thoughtBubbleHeight : Float = 330;
    
    /*
    Animations to make the screen appear less dull
    */
    private var m_expandContractThoughtBubble : Tween;
    private var m_newHintStarBurstTween : Tween;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            availableHints : Array<HintScript>,
            width : Float,
            height : Float,
            canvas : DisplayObjectContainer,
            buttonColorData : ButtonColorData,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_gameEngine = gameEngine;
        m_assetManager = assetManager;
        m_availableHints = availableHints;
        m_width = width;
        m_height = height;
        m_canvas = canvas;
        m_lockedHints = new Array<HintScript>();
        m_unlockedHints = new Array<HintScript>();
        
        var whiteButtonTexture : Texture = assetManager.getTexture("button_white");
        var whiteScale9Texture : Scale9Textures = new Scale9Textures(whiteButtonTexture, new Rectangle(8, 8, 16, 16));
        
        var lightbulbIconMaxHeight : Float = 60;
        
        // The star burst should play a spin animation when the mouse is over it
        var starBurst : DisplayObject = new Image(assetManager.getTexture("Art_StarBurst"));
        starBurst.pivotX = starBurst.width * 0.5;
        starBurst.pivotY = starBurst.height * 0.5;
        starBurst.scaleX = starBurst.scaleY = (lightbulbIconMaxHeight * 1.7 / starBurst.height);
        starBurst.x = starBurst.width * 0.5;
        starBurst.y = starBurst.height * 0.5;
        
        var lightbulbTexture : Texture = assetManager.getTexture("light");
        var lightbulbIcon : Image = new Image(lightbulbTexture);
        lightbulbIcon.scaleX = lightbulbIcon.scaleY = lightbulbIconMaxHeight * 0.9 / lightbulbTexture.height;
        lightbulbIcon.x = (starBurst.width - lightbulbIcon.width) * 0.5;
        lightbulbIcon.y = (starBurst.height - lightbulbIcon.height) * 0.5;
        
        var newHintText : TextField = new TextField(starBurst.width, 30, StringTable.lookup("new_hint"), GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF);
        newHintText.hAlign = HAlign.RIGHT;
        newHintText.y = lightbulbIcon.y + lightbulbIcon.height;
        newHintText.x = 0;
        
        var newHintSkinContainer : Sprite = new Sprite();
        newHintSkinContainer.addChild(starBurst);
        newHintSkinContainer.addChild(lightbulbIcon);
        newHintSkinContainer.addChild(newHintText);
        
        m_newHintButton = new Button();
        m_newHintButton.width = newHintSkinContainer.width;
        m_newHintButton.height = newHintSkinContainer.height;
        m_newHintButton.defaultSkin = newHintSkinContainer;
        m_newHintButton.scaleWhenDown = 0.9;
        m_newHintButton.addEventListener(Event.TRIGGERED, onNewHintClicked);
        m_newHintButton.addEventListener(TouchEvent.TOUCH, onNewHintTouched);
        
        var showHintWidth : Float = 60;
        var showIconTexture : Texture = assetManager.getTexture("help_icon");
        var showIcon : Image = new Image(showIconTexture);
        showIcon.scaleX = showIcon.scaleY = showHintWidth * 0.9 / showIconTexture.height;
        
        m_showHintButton = new Button();
        m_showHintButton.defaultSkin = showIcon;
        m_showHintButton.width = m_showHintButton.height = showHintWidth;
        m_showHintButton.scaleWhenHovering = 1.1;
        m_showHintButton.scaleWhenDown = 0.9;
        m_showHintButton.addEventListener(Event.TRIGGERED, onShowHintClicked);
        
        var thoughtBubbleSmallTexture : Texture = m_assetManager.getTexture("thought_bubble_small");
        var thoughtBubbleSmallA : Image = new Image(thoughtBubbleSmallTexture);
        thoughtBubbleSmallA.scaleX = thoughtBubbleSmallA.scaleY = 0.8;
        thoughtBubbleSmallA.pivotX = thoughtBubbleSmallTexture.width * 0.5;
        thoughtBubbleSmallA.pivotY = thoughtBubbleSmallTexture.height * 0.5;
        m_thoughtBubbleA = thoughtBubbleSmallA;
        
        var thoughtBubbleSmallB : Image = new Image(thoughtBubbleSmallTexture);
        thoughtBubbleSmallB.scaleX = thoughtBubbleSmallB.scaleY = 0.5;
        thoughtBubbleSmallB.pivotX = thoughtBubbleSmallTexture.width * 0.5;
        thoughtBubbleSmallB.pivotY = thoughtBubbleSmallTexture.height * 0.5;
        m_thoughtBubbleB = thoughtBubbleSmallB;
        
        var thoughtBubbleTexture : Texture = m_assetManager.getTexture("thought_bubble");
        var thoughtBubble : Image = new Image(thoughtBubbleTexture);
        thoughtBubble.pivotX = thoughtBubbleTexture.width * 0.5;
        thoughtBubble.pivotY = thoughtBubbleTexture.height * 0.5;
        thoughtBubble.scaleX = m_thoughtBubbleWidth / thoughtBubbleTexture.width;
        thoughtBubble.scaleY = m_thoughtBubbleHeight / thoughtBubbleTexture.height;
        thoughtBubble.x = m_width * 0.5;
        thoughtBubble.y = thoughtBubble.height * 0.5;
        m_thoughtBubbleMain = thoughtBubble;
        
        m_descriptionContainer = new Sprite();
        m_descriptionContainer.x = (m_thoughtBubbleMain.x - m_thoughtBubbleWidth * 0.5) + m_thoughtBubbleWidth * 0.121;
        m_descriptionContainer.y = (m_thoughtBubbleMain.y - m_thoughtBubbleHeight * 0.5) + m_thoughtBubbleHeight * 0.215;
        
        var arrowTexture : Texture = assetManager.getTexture("arrow_short");
        var arrowScale : Float = 1.5;
        var leftUpArrow : Image = WidgetUtil.createPointingArrow(arrowTexture, true, arrowScale, 0xFFFFFF);
        var leftDownArrow : Image = WidgetUtil.createPointingArrow(arrowTexture, true, arrowScale, 0xCCCCCC);
        m_leftScrollButton = WidgetUtil.createButtonFromImages(leftUpArrow, leftDownArrow, null, leftDownArrow, null, null);
        m_leftScrollButton.scaleWhenDown = 0.9;
        m_leftScrollButton.addEventListener(Event.TRIGGERED, onLeftScrollClick);
        
        var rightUpArrow : Image = WidgetUtil.createPointingArrow(arrowTexture, false, arrowScale, 0xFFFFFF);
        var rightDownArrow : Image = WidgetUtil.createPointingArrow(arrowTexture, false, arrowScale, 0xCCCCCC);
        m_rightScrollButton = WidgetUtil.createButtonFromImages(rightUpArrow, rightDownArrow, null, rightDownArrow, null, null);
        m_rightScrollButton.scaleWhenDown = m_leftScrollButton.scaleWhenDown;
        m_rightScrollButton.addEventListener(Event.TRIGGERED, onRightScrollClick);
        
        m_pageIndicatorText = new TextField(200, 80, "1/1", GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
        
        m_expandContractThoughtBubble = new Tween(m_thoughtBubbleMain, 2);
        m_expandContractThoughtBubble.animate("scaleX", m_thoughtBubbleMain.scaleX * 1.05);
        m_expandContractThoughtBubble.animate("scaleY", m_thoughtBubbleMain.scaleY * 1.05);
        m_expandContractThoughtBubble.repeatCount = 0;
        m_expandContractThoughtBubble.reverse = true;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_leftScrollButton.removeEventListener(Event.TRIGGERED, onLeftScrollClick);
        m_rightScrollButton.removeEventListener(Event.TRIGGERED, onRightScrollClick);
        m_newHintButton.removeEventListener(Event.TRIGGERED, onNewHintClicked);
        m_newHintButton.removeEventListener(TouchEvent.TOUCH, onNewHintTouched);
        m_showHintButton.removeEventListener(Event.TRIGGERED, onShowHintClicked);
    }
    
    /**
     * Redraw the contents of the viewer at the current page
     */
    public function show() : Void
    {
        // Background for hints is we will have a still of
        // one of the helper character and hints that have been unlocked
        // will appear on top of a thought bubble background
        var offset : Float = 32;
        m_thoughtBubbleA.x = m_thoughtBubbleMain.x - m_thoughtBubbleWidth * 0.5 + offset;
        m_thoughtBubbleA.y = m_thoughtBubbleMain.y + m_thoughtBubbleHeight * 0.5 - offset;
        m_canvas.addChild(m_thoughtBubbleA);
        
        offset = 20;
        m_thoughtBubbleB.x = m_thoughtBubbleA.x - m_thoughtBubbleA.width + offset;
        m_thoughtBubbleB.y = m_thoughtBubbleA.y + m_thoughtBubbleA.height - offset;
        m_canvas.addChild(m_thoughtBubbleB);
        m_canvas.addChild(m_thoughtBubbleMain);
        
        m_leftScrollButton.x = 0;
        m_leftScrollButton.y = (m_thoughtBubbleHeight - m_leftScrollButton.defaultSkin.height) * 0.5;
        m_rightScrollButton.x = m_width - m_rightScrollButton.defaultSkin.width;
        m_rightScrollButton.y = m_leftScrollButton.y;
        
        // Randomly pick one of the characters
        var targetCharacterHeight : Float = 130;
        var characterStillName : String = ((Math.random() > 0.5)) ? "cookie_happy_still" : "taco_happy_still";
        var characterStillTexture : Texture = m_assetManager.getTexture(characterStillName);
        var characterImage : Image = new Image(characterStillTexture);
        characterImage.pivotX = characterStillTexture.width * 0.5;
        characterImage.pivotY = characterStillTexture.height * 0.5;
        characterImage.scaleX = characterImage.scaleY = (targetCharacterHeight / characterStillTexture.height);
        characterImage.x = characterImage.width * 0.5;
        characterImage.y = m_thoughtBubbleB.y + characterImage.height * 0.5 + 10;
        m_canvas.addChild(characterImage);
        
        m_pageIndicatorText.x = (m_width - m_pageIndicatorText.width) * 0.5 - 100;
        m_pageIndicatorText.y = m_thoughtBubbleMain.y + m_thoughtBubbleHeight * 0.5 + 20;
        m_canvas.addChild(m_pageIndicatorText);
        
        m_newHintButton.x = m_width - m_newHintButton.width - 100;
        m_newHintButton.y = m_pageIndicatorText.y - 20;
        //m_canvas.addChild(m_newHintButton);
        
        m_canvas.addChild(m_descriptionContainer);
        
        // Position show hint in the bottom of the thought bubble
        // (Determine if visible only after a hint on a page in rendered, they all share the same button)
        m_showHintButton.x = m_thoughtBubbleMain.x - m_showHintButton.width * 0.5;
        m_showHintButton.y = m_thoughtBubbleMain.y + m_thoughtBubbleHeight * 0.5 - m_showHintButton.height * 1.4;
        
        // Parse out what hints are currently viewable
        as3hx.Compat.setArrayLength(m_lockedHints, 0);
        as3hx.Compat.setArrayLength(m_unlockedHints, 0);
        
        var i : Int;
        for (i in 0...m_availableHints.length){
            var hintScript : HintScript = m_availableHints[i];
            if (hintScript.unlocked) 
            {
                m_unlockedHints.push(hintScript);
            }
            else 
            {
                m_lockedHints.push(hintScript);
            }
        }  // (Although there should always be some generic hints)    // If no hints are visible, say none are available  
        
        
        
        
        
        if (m_unlockedHints.length == 0) 
        {
            if (m_noHintDescription == null) 
            {
                var contentWidth : Float = m_thoughtBubbleMain.width * 0.75;
                var contentHeight : Float = m_thoughtBubbleMain.height * 0.64;
                m_noHintDescription = new TextField(contentWidth, contentHeight, 
                        "", 
                        GameFonts.DEFAULT_FONT_NAME, 28, 0, 
                        );
            }
            
            m_noHintDescription.text = ((m_availableHints.length > 0)) ? NO_HINTS_UNLOCKED : NO_HINTS_AVAILABLE;
            m_descriptionContainer.addChild(m_noHintDescription);
        }
        // Use the current hint index to show the last visible hint
        else 
        {
            if (m_currentHintIndex < 0) 
            {
                m_currentHintIndex = 0;
            }
            
            showHintAtIndex(m_currentHintIndex);
        }  // Start up the tweens  
        
        
        
        Starling.juggler.add(m_expandContractThoughtBubble);
    }
    
    public function hide() : Void
    {
        m_newHintButton.removeFromParent();
        
        m_leftScrollButton.removeFromParent();
        m_rightScrollButton.removeFromParent();
        
        // Clear the canvas completely
        m_canvas.removeChildren();
        
        // Clean up the previously selected view
        if (m_currentHintShown != null) 
        {
            m_currentHintShown.disposeDescription(m_currentDescriptionViewShown);
            m_currentDescriptionViewShown.removeFromParent(true);
            m_currentHintShown = null;
            m_currentDescriptionViewShown = null;
        }  // Remove the tweens  
        
        
        
        Starling.juggler.remove(m_expandContractThoughtBubble);
    }
    
    private function showHintAtIndex(index : Int) : Void
    {
        if (index >= 0 && index < m_unlockedHints.length) 
        {
            // Clean up the previously selected view
            if (m_currentHintShown != null) 
            {
                m_currentHintShown.disposeDescription(m_currentDescriptionViewShown);
                m_currentDescriptionViewShown.removeFromParent(true);
            }
            m_descriptionContainer.removeChildren();
            
            // Refresh page indicator
            m_pageIndicatorText.text = (index + 1) + "/" + m_unlockedHints.length;
            
            // The dimensions of the content area equals the box that is completely contained by the thought bubble
            var contentWidth : Float = m_thoughtBubbleMain.width * 0.75;
            var contentHeight : Float = m_thoughtBubbleMain.height * 0.64;
            var hintToShow : HintScript = m_unlockedHints[index];
            var hintDescription : DisplayObject = hintToShow.getDescription(contentWidth, contentHeight);
            m_descriptionContainer.addChild(hintDescription);
            
            m_currentHintShown = hintToShow;
            m_currentDescriptionViewShown = hintDescription;
            
            // Figure out whether the new hint has logic where it can be shown in the level
            if (hintToShow.canShow()) 
            {
                m_canvas.addChild(m_showHintButton);
            }
            else 
            {
                m_canvas.removeChild(m_showHintButton);
            }
        }  // If no new hints are available, disable it and make transparent  
        
        
        
        var newHintEnabled : Bool = false;
        for (lockedHint in m_lockedHints)
        {
            if (lockedHint.isUsefulForCurrentState()) 
            {
                newHintEnabled = true;
            }
        }
        
        m_newHintButton.isEnabled = newHintEnabled;
        if (newHintEnabled) 
        {
            m_newHintButton.alpha = 1.0;
            m_newHintButton.filter = null;
        }
        else 
        {
            m_newHintButton.alpha = 0.5;
            var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter();
            colorMatrixFilter.adjustSaturation(-1);
            m_newHintButton.filter = colorMatrixFilter;
            
            // Kill the animation on the button if playing
            if (m_newHintStarBurstTween != null) 
            {
                Starling.juggler.remove(m_newHintStarBurstTween);
                m_newHintStarBurstTween = null;
            }
        }  // If more than one hint unlocked then show the scroll button.  
        
        
        
        if (m_unlockedHints.length > 1) 
        {
            m_canvas.addChild(m_leftScrollButton);
            m_canvas.addChild(m_rightScrollButton);
        }
        else 
        {
            m_leftScrollButton.removeFromParent();
            m_rightScrollButton.removeFromParent();
        }
    }
    
    private function onNewHintClicked() : Void
    {
        // Making several assumptions:
        // -the list of locked hints is ordered so the first ones are more important to show
        // -the first 'useful' hint will be the most helpful
        var bestNextHint : HintScript = null;
        var i : Int;
        var totalLockedHints : Int = m_lockedHints.length;
        for (i in 0...totalLockedHints){
            var hintScript : HintScript = m_lockedHints[i];
            if (hintScript.isUsefulForCurrentState()) 
            {
                bestNextHint = hintScript;
                break;
            }
        }
        
        if (bestNextHint != null) 
        {
            // Remove the hint from locked and into unlocked
            m_lockedHints.splice(i, 1);
            m_unlockedHints.push(bestNextHint);
            bestNextHint.unlocked = true;
            
            // New hint is just for logging/stats
            m_gameEngine.dispatchEventWith(GameEvent.GET_NEW_HINT, false, null);
            
            // Redraw the screen so that the new hint is used
            m_currentHintIndex = m_unlockedHints.length - 1;
            showHintAtIndex(m_currentHintIndex);
        }
    }
    
    private function onNewHintTouched(event : TouchEvent) : Void
    {
        var hoverTouch : Touch = event.getTouch(m_newHintButton, TouchPhase.HOVER);
        var iconToAnimate : DisplayObject = (try cast(m_newHintButton.defaultSkin, Sprite) catch(e:Dynamic) null).getChildAt(0);
        if (m_newHintStarBurstTween == null && m_newHintButton.isEnabled) 
        {
            m_newHintStarBurstTween = new Tween(iconToAnimate, 3);
            m_newHintStarBurstTween.animate("rotation", Math.PI * 2);
            m_newHintStarBurstTween.repeatCount = 0;
            Starling.juggler.add(m_newHintStarBurstTween);
        }
        else if (hoverTouch == null && m_newHintStarBurstTween != null) 
        {
            iconToAnimate.rotation = 0.0;
            Starling.juggler.remove(m_newHintStarBurstTween);
            m_newHintStarBurstTween = null;
        }
    }
    
    private function onShowHintClicked() : Void
    {
        var params : Dynamic = {
            hint : m_currentHintShown

        };
        m_gameEngine.dispatchEventWith(GameEvent.SHOW_HINT, false, params);
    }
    
    private function onLeftScrollClick() : Void
    {
        // Change index and show new unlocked hint
        var newHintIndex : Int = m_currentHintIndex - 1;
        if (newHintIndex < 0) 
        {
            newHintIndex = m_unlockedHints.length - 1;
        }
        
        if (m_currentHintIndex != newHintIndex) 
        {
            m_currentHintIndex = newHintIndex;
            showHintAtIndex(m_currentHintIndex);
        }
    }
    
    private function onRightScrollClick() : Void
    {
        // Change index and show new unlocked hint
        var newHintIndex : Int = m_currentHintIndex + 1;
        if (newHintIndex >= m_unlockedHints.length) 
        {
            newHintIndex = 0;
        }
        
        if (m_currentHintIndex != newHintIndex) 
        {
            m_currentHintIndex = newHintIndex;
            showHintAtIndex(m_currentHintIndex);
        }
    }
}
