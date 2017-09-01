package wordproblem.playercollections.scripts;


import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.text.TextFormat;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;

import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.player.ButtonColorData;
import wordproblem.resource.AssetManager;

/**
 * This is the base class used for screens that want to scroll through possibly multiple pages of
 * contents.
 * 
 * Class used to group all common data elements between all the different viewer screens.
 */
class PlayerCollectionViewer extends ScriptNode
{
    /**
     * Button used to back out of all the various view levels
     */
    private var m_backButton : LabelButton;
    private var m_backButtonClickedLastFrame : Bool;
    
    /**
     * This is container in which all graphics should be added to
     */
    private var m_canvasContainer : DisplayObjectContainer;
    
    private var m_assetManager : AssetManager;
    
    private var m_mouseState : MouseState;
    
    /**
     * Button to go to the previous page of content
     */
    private var m_scrollLeftButton : LabelButton;
    private var m_scrollLeftClickedLastFrame : Bool;
    
    /**
     * Button to go to the next page of content
     */
    private var m_scrollRightButton : LabelButton;
    private var m_scrollRightClickedLastFrame : Bool;
    
    /**
     * A title textfield that explains what the current screen is showing,
     * mainly just to say the category being viewed and whether the player is at the 
     * category select screen
     */
    private var m_titleText : TextField;
    
    /**
     * Some text at the bottom of the screen showing the user the page number the player is on
     */
    private var m_pageIndicatorText : TextField;
    
    /**
     * The current page of items currently visible
     */
    private var m_activeItemPageIndex : Int;
    
    private var m_buttonColorData : ButtonColorData;
    
    public function new(canvasContainer : DisplayObjectContainer,
            assetManager : AssetManager,
            mouseState : MouseState,
            buttonColorData : ButtonColorData,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_canvasContainer = canvasContainer;
        m_assetManager = assetManager;
        m_mouseState = mouseState;
        m_buttonColorData = buttonColorData;
        
        var sidePadding : Float = 15;
        var arrowBitmapData : BitmapData = assetManager.getBitmapData("arrow_short");
        var scaleFactor : Float = 1.5;
        var leftUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, scaleFactor);
        var leftOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, scaleFactor, 0xCCCCCC);
        
        m_scrollLeftButton = WidgetUtil.createButtonFromImages(
                        leftUpImage,
                        leftOverImage,
                        null,
                        leftOverImage,
                        null,
                        null,
                        null
                        );
        m_scrollLeftButton.x = sidePadding;
        m_scrollLeftButton.y = 200;
        m_scrollLeftButton.scaleWhenDown = 0.9;
        m_scrollLeftClickedLastFrame = false;
        
        var rightUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, scaleFactor, 0xFFFFFF);
        var rightOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, scaleFactor, 0xCCCCCC);
        m_scrollRightButton = WidgetUtil.createButtonFromImages(
                        rightUpImage,
                        rightOverImage,
                        null,
                        rightOverImage,
                        null,
                        null,
                        null
                        );
        m_scrollRightButton.x = (800 - rightUpImage.width) - sidePadding;
        m_scrollRightButton.y = m_scrollLeftButton.y;
        m_scrollRightButton.scaleWhenDown = m_scrollLeftButton.scaleWhenDown;
        m_scrollRightClickedLastFrame = false;
        
        m_titleText = new TextField();
		m_titleText.width = 800;
		m_titleText.height = 80;
		m_titleText.text = "";
		m_titleText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 38, 0xFFFFFF));
        m_pageIndicatorText = new TextField();
		m_pageIndicatorText.width = 800;
		m_pageIndicatorText.height = 80;
		m_pageIndicatorText.text = "ffff";
		m_pageIndicatorText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF));
        m_pageIndicatorText.x = 0;
        m_pageIndicatorText.y = 470;
    }
    
    public function show() : Void
    {
        this.setIsActive(true);
        m_scrollLeftButton.addEventListener(MouseEvent.CLICK, onScrollLeftButtonClicked);
        m_scrollRightButton.addEventListener(MouseEvent.CLICK, onScrollRightButtonClicked);
        
        if (m_backButton != null) 
        {
            m_backButton.addEventListener(MouseEvent.CLICK, onBackButtonClicked);
        }
    }
    
    public function hide() : Void
    {
        this.setIsActive(false);
        if (m_scrollLeftButton.parent != null) m_scrollLeftButton.parent.removeChild(m_scrollLeftButton);
        m_scrollLeftButton.removeEventListener(MouseEvent.CLICK, onScrollLeftButtonClicked);
        if (m_scrollRightButton.parent != null) m_scrollRightButton.parent.removeChild(m_scrollRightButton);
        m_scrollRightButton.removeEventListener(MouseEvent.CLICK, onScrollRightButtonClicked);
        
        if (m_titleText.parent != null) m_titleText.parent.removeChild(m_titleText);
        if (m_pageIndicatorText.parent != null) m_pageIndicatorText.parent.removeChild(m_pageIndicatorText);
        
        if (m_backButton != null) 
        {
            m_backButton.removeEventListener(MouseEvent.CLICK, onBackButtonClicked);
        }
    }
    
    private function showScrollButtons(doShow : Bool) : Void
    {
        if (doShow) 
        {
            m_canvasContainer.addChild(m_scrollLeftButton);
            m_canvasContainer.addChild(m_scrollRightButton);
        }
        else 
        {
            if (m_scrollLeftButton.parent != null) m_scrollLeftButton.parent.removeChild(m_scrollLeftButton);
            if (m_scrollRightButton.parent != null) m_scrollRightButton.parent.removeChild(m_scrollRightButton);
        }
    }
    
    private function showPageIndicator(currentPage : Int, totalPages : Int) : Void
    {
        m_pageIndicatorText.text = currentPage + " / " + totalPages;
        m_canvasContainer.addChild(m_pageIndicatorText);
    }
    
    private function createBackButton() : Void
    {
        var arrowRotateBitmapData : BitmapData = m_assetManager.getBitmapData("arrow_rotate");
        var scaleFactor : Float = 0.65;
        var backUpImage : Bitmap = new Bitmap(arrowRotateBitmapData);
		backUpImage.transform.colorTransform = XColor.rgbToColorTransform(0xFBB03B);
        backUpImage.scaleX = backUpImage.scaleY = scaleFactor;
        var backOverImage : Bitmap = new Bitmap(arrowRotateBitmapData);
		backOverImage.transform.colorTransform = XColor.rgbToColorTransform(0xFDDDAC);
        backOverImage.scaleX = backOverImage.scaleY = scaleFactor;
        m_backButton = WidgetUtil.createButtonFromImages(
                        backUpImage,
                        backOverImage,
                        null,
                        backOverImage,
                        null,
                        null
                        );
        m_backButtonClickedLastFrame = false;
    }
    
    private function onScrollLeftButtonClicked(event : Dynamic) : Void
    {
        m_scrollLeftClickedLastFrame = true;
    }
    
    private function onScrollRightButtonClicked(event : Dynamic) : Void
    {
        m_scrollRightClickedLastFrame = true;
    }
    
    private function onBackButtonClicked(event : Dynamic) : Void
    {
        // Buffer the click on the back button
        m_backButtonClickedLastFrame = true;
    }
}
