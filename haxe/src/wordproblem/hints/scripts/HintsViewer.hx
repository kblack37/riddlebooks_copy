package wordproblem.hints.scripts;

import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import wordproblem.display.PivotSprite;
import wordproblem.engine.events.DataEvent;
import wordproblem.hints.scripts.IShowableScript;

import openfl.geom.Rectangle;

import cgs.internationalization.StringTable;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.ColorMatrixFilter;
import openfl.text.TextField;

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
    private inline static var NO_HINTS_AVAILABLE : String = "Sorry, I don't have any help right now!";
    private inline static var NO_HINTS_UNLOCKED : String = "Click the button below to ask for help!";
    
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
    private var m_showHintButton : LabelButton;
    
    /**
     * Button to unlock a new hint
     */
    private var m_newHintButton : LabelButton;
    
    /**
     * Button to scroll to the left if multiple hints available
     */
    private var m_leftScrollButton : LabelButton;
    
    /**
     * Button to scroll to the right if multiple hints available
     */
    private var m_rightScrollButton : LabelButton;
    
    /**
     * Text to show if no hint is available to display
     */
    private var m_noHintDescription : TextField;
    
    /*
    All visible hints re-use the same background assets so we can hold onto the same images
    to create the thought bubbles
    */
    private var m_thoughtBubbleA : DisplayObject;
    private var m_thoughtBubbleB : DisplayObject;
    private var m_thoughtBubbleMain : DisplayObject;
    
    private var m_thoughtBubbleWidth : Float = 510;
    private var m_thoughtBubbleHeight : Float = 330;
	
	/**
	 * Used to track if a tween is running
	 */
	private var m_isStarBurstAnimating : Bool;
    
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
        
        var lightbulbIconMaxHeight : Float = 60;
        
        // The star burst should play a spin animation when the mouse is over it
		// TODO: previously this was Art_Starburst, however that asset is missing at the moment
        var starBurst : PivotSprite = new PivotSprite();
		starBurst.addChild(new Bitmap(assetManager.getBitmapData("burst_purple")));
        starBurst.pivotX = starBurst.width * 0.5;
        starBurst.pivotY = starBurst.height * 0.5;
        starBurst.scaleX = starBurst.scaleY = (lightbulbIconMaxHeight * 1.7 / starBurst.height);
        starBurst.x = starBurst.width * 0.5;
        starBurst.y = starBurst.height * 0.5;
        
        var lightbulbBitmapData : BitmapData = assetManager.getBitmapData("light");
        var lightbulbIcon : Bitmap = new Bitmap(lightbulbBitmapData);
        lightbulbIcon.scaleX = lightbulbIcon.scaleY = lightbulbIconMaxHeight * 0.9 / lightbulbBitmapData.height;
        lightbulbIcon.x = (starBurst.width - lightbulbIcon.width) * 0.5;
        lightbulbIcon.y = (starBurst.height - lightbulbIcon.height) * 0.5;
        
		// TODO: uncomment once cgs library is ported
        var newHintText : TextField = new TextField();
		newHintText.width = starBurst.width;
		newHintText.height = 30;
		newHintText.text = /*StringTable.lookup("new_hint")*/ "";
		newHintText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.RIGHT));
        newHintText.y = lightbulbIcon.y + lightbulbIcon.height;
        newHintText.x = 0;
        
        var newHintSkinContainer : Sprite = new Sprite();
        newHintSkinContainer.addChild(starBurst);
        newHintSkinContainer.addChild(lightbulbIcon);
        newHintSkinContainer.addChild(newHintText);
        
        m_newHintButton = new LabelButton(newHintSkinContainer);
        m_newHintButton.width = newHintSkinContainer.width;
        m_newHintButton.height = newHintSkinContainer.height;
		m_newHintButton.scaleWhenDown = 0.9;
        m_newHintButton.addEventListener(MouseEvent.CLICK, onNewHintClicked);
        m_newHintButton.addEventListener(MouseEvent.MOUSE_OVER, onNewHintMouseover);
		m_newHintButton.addEventListener(MouseEvent.MOUSE_OUT, onNewHintMouseout);
        
        var showHintWidth : Float = 60;
        var showIconBitmapData : BitmapData = assetManager.getBitmapData("help_icon");
        var showIcon : Bitmap = new Bitmap(showIconBitmapData);
        showIcon.scaleX = showIcon.scaleY = showHintWidth * 0.9 / showIconBitmapData.height;
        
        m_showHintButton = new LabelButton(showIcon);
        m_showHintButton.width = m_showHintButton.height = showHintWidth;
		m_showHintButton.scaleWhenOver = 1.1;
		m_showHintButton.scaleWhenDown = 0.9;
        m_showHintButton.addEventListener(MouseEvent.CLICK, onShowHintClicked);
        
        var thoughtBubbleSmallBitmapData : BitmapData = m_assetManager.getBitmapData("thought_bubble_small");
        var thoughtBubbleSmallA : PivotSprite = new PivotSprite();
		thoughtBubbleSmallA.addChild(new Bitmap(thoughtBubbleSmallBitmapData));
        thoughtBubbleSmallA.scaleX = thoughtBubbleSmallA.scaleY = 0.8;
        thoughtBubbleSmallA.pivotX = thoughtBubbleSmallBitmapData.width * 0.5;
        thoughtBubbleSmallA.pivotY = thoughtBubbleSmallBitmapData.height * 0.5;
        m_thoughtBubbleA = thoughtBubbleSmallA;
        
        var thoughtBubbleSmallB : PivotSprite = new PivotSprite();
		thoughtBubbleSmallB.addChild(new Bitmap(thoughtBubbleSmallBitmapData));
        thoughtBubbleSmallB.scaleX = thoughtBubbleSmallB.scaleY = 0.5;
        thoughtBubbleSmallB.pivotX = thoughtBubbleSmallBitmapData.width * 0.5;
        thoughtBubbleSmallB.pivotY = thoughtBubbleSmallBitmapData.height * 0.5;
        m_thoughtBubbleB = thoughtBubbleSmallB;
        
        var thoughtBubbleBitmapData : BitmapData = m_assetManager.getBitmapData("thought_bubble");
        var thoughtBubble : PivotSprite = new PivotSprite();
		thoughtBubble.addChild(new Bitmap(thoughtBubbleBitmapData));
        thoughtBubble.pivotX = thoughtBubbleBitmapData.width * 0.5;
        thoughtBubble.pivotY = thoughtBubbleBitmapData.height * 0.5;
        thoughtBubble.scaleX = m_thoughtBubbleWidth / thoughtBubbleBitmapData.width;
        thoughtBubble.scaleY = m_thoughtBubbleHeight / thoughtBubbleBitmapData.height;
        thoughtBubble.x = m_width * 0.5;
        thoughtBubble.y = thoughtBubble.height * 0.5;
        m_thoughtBubbleMain = thoughtBubble;
        
        m_descriptionContainer = new Sprite();
        m_descriptionContainer.x = (m_thoughtBubbleMain.x - m_thoughtBubbleWidth * 0.5) + m_thoughtBubbleWidth * 0.121;
        m_descriptionContainer.y = (m_thoughtBubbleMain.y - m_thoughtBubbleHeight * 0.5) + m_thoughtBubbleHeight * 0.215;
        
        var arrowBitmapData : BitmapData = assetManager.getBitmapData("arrow_short");
        var arrowScale : Float = 1.5;
        var leftUpArrow : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, arrowScale, 0xFFFFFF);
        var leftDownArrow : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, arrowScale, 0xCCCCCC);
        m_leftScrollButton = WidgetUtil.createButtonFromImages(leftUpArrow, leftDownArrow, null, leftDownArrow, null, null);
		m_leftScrollButton.scaleWhenDown = 0.9;
        m_leftScrollButton.addEventListener(MouseEvent.CLICK, onLeftScrollClick);
        
        var rightUpArrow : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, arrowScale, 0xFFFFFF);
        var rightDownArrow : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, arrowScale, 0xCCCCCC);
        m_rightScrollButton = WidgetUtil.createButtonFromImages(rightUpArrow, rightDownArrow, null, rightDownArrow, null, null);
		m_rightScrollButton.scaleWhenDown = m_leftScrollButton.scaleWhenDown;
        m_rightScrollButton.addEventListener(MouseEvent.CLICK, onRightScrollClick);
        
        m_pageIndicatorText = new TextField();
		m_pageIndicatorText.width = 200;
		m_pageIndicatorText.height = 80;
		m_pageIndicatorText.text = "1/1";
		m_pageIndicatorText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF));
        
		Actuate.tween(m_thoughtBubbleMain, 2, { scaleX: m_thoughtBubbleMain.scaleX * 1.05, scaleY: m_thoughtBubbleMain.scaleY * 1.05}).repeat().reflect();
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_leftScrollButton.removeEventListener(MouseEvent.CLICK, onLeftScrollClick);
        m_rightScrollButton.removeEventListener(MouseEvent.CLICK, onRightScrollClick);
        m_newHintButton.removeEventListener(MouseEvent.CLICK, onNewHintClicked);
        m_newHintButton.removeEventListener(MouseEvent.MOUSE_OVER, onNewHintMouseover);
		m_newHintButton.removeEventListener(MouseEvent.MOUSE_OUT, onNewHintMouseout);
        m_showHintButton.removeEventListener(MouseEvent.CLICK, onShowHintClicked);
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
        m_leftScrollButton.y = (m_thoughtBubbleHeight - m_leftScrollButton.upState.height) * 0.5;
        m_rightScrollButton.x = m_width - m_rightScrollButton.upState.width;
        m_rightScrollButton.y = m_leftScrollButton.y;
        
        // Randomly pick one of the characters
        var targetCharacterHeight : Float = 130;
        var characterStillName : String = ((Math.random() > 0.5)) ? "cookie_happy_still" : "taco_happy_still";
        var characterStillBitmapData : BitmapData = m_assetManager.getBitmapData(characterStillName);
        var characterImage : PivotSprite = new PivotSprite();
		characterImage.addChild(new Bitmap(characterStillBitmapData));
        characterImage.pivotX = characterStillBitmapData.width * 0.5;
        characterImage.pivotY = characterStillBitmapData.height * 0.5;
        characterImage.scaleX = characterImage.scaleY = (targetCharacterHeight / characterStillBitmapData.height);
        characterImage.x = characterImage.width * 0.5;
        characterImage.y = m_thoughtBubbleB.y + characterImage.height * 0.5 + 10;
        m_canvas.addChild(characterImage);
        
        m_pageIndicatorText.x = (m_width - m_pageIndicatorText.width) * 0.5 - 100;
        m_pageIndicatorText.y = m_thoughtBubbleMain.y + m_thoughtBubbleHeight * 0.5 + 20;
        m_canvas.addChild(m_pageIndicatorText);
        
        m_newHintButton.x = m_width - m_newHintButton.width - 100;
        m_newHintButton.y = m_pageIndicatorText.y - 20;
        m_canvas.addChild(m_newHintButton);
        
        m_canvas.addChild(m_descriptionContainer);
        
        // Position show hint in the bottom of the thought bubble
        // (Determine if visible only after a hint on a page in rendered, they all share the same button)
        m_showHintButton.x = m_thoughtBubbleMain.x - m_showHintButton.width * 0.5;
        m_showHintButton.y = m_thoughtBubbleMain.y + m_thoughtBubbleHeight * 0.5 - m_showHintButton.height * 1.4;
        
        // Parse out what hints are currently viewable
		m_lockedHints = new Array<HintScript>();
		m_unlockedHints = new Array<HintScript>();
        
        var i : Int = 0;
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
        }
		
		// If no hints are visible, say none are available  
        // (Although there should always be some generic hints)
        if (m_unlockedHints.length == 0) 
        {
            if (m_noHintDescription == null) 
            {
                var contentWidth : Float = m_thoughtBubbleMain.width * 0.75;
                var contentHeight : Float = m_thoughtBubbleMain.height * 0.64;
                m_noHintDescription = new TextField();
				m_noHintDescription.width = contentWidth;
				m_noHintDescription.height = contentHeight;
				m_noHintDescription.text = "";
				m_noHintDescription.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0));
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
        }
		
		// Start up the tweens  
		Actuate.tween(m_thoughtBubbleMain, 2, { scaleX: m_thoughtBubbleMain.scaleX * 1.05, scaleY: m_thoughtBubbleMain.scaleY * 1.05}).repeat().reflect();
    }
    
    public function hide() : Void
    {
        if (m_newHintButton.parent != null) m_newHintButton.parent.removeChild(m_newHintButton);
        
        if (m_leftScrollButton.parent != null) m_leftScrollButton.parent.removeChild(m_leftScrollButton);
        if (m_rightScrollButton.parent != null) m_rightScrollButton.parent.removeChild(m_rightScrollButton);
        
        // Clear the canvas completely
        m_canvas.removeChildren();
        
        // Clean up the previously selected view
        if (m_currentHintShown != null) 
        {
            m_currentHintShown.disposeDescription(m_currentDescriptionViewShown);
			if (m_currentDescriptionViewShown.parent != null) m_currentDescriptionViewShown.parent.removeChild(m_currentDescriptionViewShown);
            m_currentHintShown = null;
            m_currentDescriptionViewShown = null;
        } 
		
		// Remove the tweens  
		Actuate.stop(m_thoughtBubbleMain);
    }
    
    private function showHintAtIndex(index : Int) : Void
    {
        if (index >= 0 && index < m_unlockedHints.length) 
        {
            // Clean up the previously selected view
            if (m_currentHintShown != null) 
            {
                m_currentHintShown.disposeDescription(m_currentDescriptionViewShown);
				if (m_currentDescriptionViewShown.parent != null) m_currentDescriptionViewShown.parent.removeChild(m_currentDescriptionViewShown);
				m_currentDescriptionViewShown = null;
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
        }  
		
		// If no new hints are available, disable it and make transparent
        var newHintEnabled : Bool = false;
        for (lockedHint in m_lockedHints)
        {
            if (lockedHint.isUsefulForCurrentState()) 
            {
                newHintEnabled = true;
            }
        }
        
        m_newHintButton.enabled = newHintEnabled;
        if (newHintEnabled) 
        {
            m_newHintButton.alpha = 1.0;
			m_newHintButton.filters = new Array<BitmapFilter>();
        }
        else 
        {
            m_newHintButton.alpha = 0.5;
			// TODO: this greyscale matrix is probably not correct
			var matrix : Array<Float> = new Array<Float>();
			for (i in 0...3) matrix = matrix.concat([1 / 3, 1 / 3, 1 / 3, 0, 0]);
			matrix = matrix.concat([0, 0, 0, 1, 0]);
            var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter(matrix);
            var filters = m_newHintButton.filters;
			filters.push(colorMatrixFilter);
			m_newHintButton.filters = filters;
            
            // Kill the animation on the button if playing
            if (m_isStarBurstAnimating) 
            {
				Actuate.stop(m_newHintButton);
				m_isStarBurstAnimating = false;
            }
        } 
		
		// If more than one hint unlocked then show the scroll button.  
        if (m_unlockedHints.length > 1) 
        {
            m_canvas.addChild(m_leftScrollButton);
            m_canvas.addChild(m_rightScrollButton);
        }
        else 
        {
            if (m_leftScrollButton.parent != null) m_leftScrollButton.parent.removeChild(m_leftScrollButton);
            if (m_rightScrollButton.parent != null) m_rightScrollButton.parent.removeChild(m_rightScrollButton);
        }
    }
    
    private function onNewHintClicked(event : Dynamic) : Void
    {
        // Making several assumptions:
        // -the list of locked hints is ordered so the first ones are more important to show
        // -the first 'useful' hint will be the most helpful
        var bestNextHint : HintScript = null;
        var i : Int = 0;
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
            m_gameEngine.dispatchEvent(new Event(GameEvent.GET_NEW_HINT));
            
            // Redraw the screen so that the new hint is used
            m_currentHintIndex = m_unlockedHints.length - 1;
            showHintAtIndex(m_currentHintIndex);
        }
    }
    
    private function onNewHintMouseover(event : Dynamic) : Void
    {
        var iconToAnimate : DisplayObject = m_newHintButton;
        if (!m_isStarBurstAnimating && m_newHintButton.enabled) 
        {
			Actuate.tween(iconToAnimate, 3, { rotation: 360 }).smartRotation().repeat();
        }
    }
	
	private function onNewHintMouseout(event : Dynamic) : Void {
		var iconToAnimate : DisplayObject = m_newHintButton;
		if (m_isStarBurstAnimating) {
			Actuate.stop(iconToAnimate);
		}
	}
    
    private function onShowHintClicked(event : Dynamic) : Void
    {
        var params : Dynamic = {
            hint : m_currentHintShown
        };
        m_gameEngine.dispatchEvent(new DataEvent(GameEvent.SHOW_HINT, params));
    }
    
    private function onLeftScrollClick(event : Dynamic) : Void
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
    
    private function onRightScrollClick(event : Dynamic) : Void
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
