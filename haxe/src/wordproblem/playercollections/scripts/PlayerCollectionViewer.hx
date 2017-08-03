package wordproblem.playercollections.scripts;


import dragonbox.common.ui.MouseState;

import starling.display.Button;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.events.Event;
import starling.text.TextField;
import starling.textures.Texture;

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
    private var m_backButton : Button;
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
    private var m_scrollLeftButton : Button;
    private var m_scrollLeftClickedLastFrame : Bool;
    
    /**
     * Button to go to the next page of content
     */
    private var m_scrollRightButton : Button;
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
        var arrowTexture : Texture = assetManager.getTexture("arrow_short.png");
        var scaleFactor : Float = 1.5;
        var leftUpImage : Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor);
        var leftOverImage : Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor, 0xCCCCCC);
        
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
        
        var rightUpImage : Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xFFFFFF);
        var rightOverImage : Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xCCCCCC);
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
        
        m_titleText = new TextField(800, 80, "", GameFonts.DEFAULT_FONT_NAME, 38, 0xFFFFFF);
        m_pageIndicatorText = new TextField(800, 80, "ffff", GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF);
        m_pageIndicatorText.x = 0;
        m_pageIndicatorText.y = 470;
    }
    
    public function show() : Void
    {
        this.setIsActive(true);
        m_scrollLeftButton.addEventListener(Event.TRIGGERED, onScrollLeftButtonClicked);
        m_scrollRightButton.addEventListener(Event.TRIGGERED, onScrollRightButtonClicked);
        
        if (m_backButton != null) 
        {
            m_backButton.addEventListener(Event.TRIGGERED, onBackButtonClicked);
        }
    }
    
    public function hide() : Void
    {
        this.setIsActive(false);
        m_scrollLeftButton.removeFromParent();
        m_scrollLeftButton.removeEventListener(Event.TRIGGERED, onScrollLeftButtonClicked);
        m_scrollRightButton.removeFromParent();
        m_scrollRightButton.removeEventListener(Event.TRIGGERED, onScrollRightButtonClicked);
        
        m_titleText.removeFromParent();
        m_pageIndicatorText.removeFromParent();
        
        if (m_backButton != null) 
        {
            m_backButton.removeEventListener(Event.TRIGGERED, onBackButtonClicked);
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
            m_scrollLeftButton.removeFromParent();
            m_scrollRightButton.removeFromParent();
        }
    }
    
    private function showPageIndicator(currentPage : Int, totalPages : Int) : Void
    {
        m_pageIndicatorText.text = currentPage + " / " + totalPages;
        m_canvasContainer.addChild(m_pageIndicatorText);
    }
    
    private function createBackButton() : Void
    {
        var arrowRotateTexture : Texture = m_assetManager.getTexture("arrow_rotate.png");
        var scaleFactor : Float = 0.65;
        var backUpImage : Image = new Image(arrowRotateTexture);
        backUpImage.color = 0xFBB03B;
        backUpImage.scaleX = backUpImage.scaleY = scaleFactor;
        var backOverImage : Image = new Image(arrowRotateTexture);
        backOverImage.color = 0xFDDDAC;
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
    
    private function onScrollLeftButtonClicked() : Void
    {
        m_scrollLeftClickedLastFrame = true;
    }
    
    private function onScrollRightButtonClicked() : Void
    {
        m_scrollRightClickedLastFrame = true;
    }
    
    private function onBackButtonClicked() : Void
    {
        // Buffer the click on the back button
        m_backButtonClickedLastFrame = true;
    }
}
