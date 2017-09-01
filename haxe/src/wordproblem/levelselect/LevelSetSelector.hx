package wordproblem.levelselect;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import wordproblem.display.PivotSprite;

import cgs.audio.Audio;

import dragonbox.common.ui.MouseState;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;

import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.level.nodes.WordProblemLevelLeaf;
import wordproblem.resource.AssetManager;

/**
 * A sub-screen to allow the player to explicitly select an individual level from a button
 * in the level selection that has been marked as a set.
 * 
 * Useful for debugging sets and for giving the player more freedom in choosing to replay levels 
 */
class LevelSetSelector extends Sprite
{
    /**
     * The layout algorithm to use for buttons.
     */
    // TODO: uncomment once layout replacement is designed
	//private var m_buttonLayout : TiledRowsLayout;
    
    private var m_background : DisplayObject;
    private var m_backgroundBoundsBuffer : Rectangle;
    private var m_prevPageButton : LabelButton;
    private var m_nextPageButton : LabelButton;
    
    private var m_assetManager : AssetManager;
    private var m_onLevelSelectedCallback : Function;
    private var m_onDismissCallback : Function;
    
    private var m_selectorTitle : TextField;
    private var m_progressIndicator : TextField;
    private var m_buttonCanvas : Sprite;
    private var m_buttonCanvasBounds : Rectangle;
    
    /**
     * The current set of levels that should be displayed
     */
    private var m_currentLevelNodes : Array<WordProblemLevelLeaf>;
    
    private var m_currentPageIndex : Int;
    private inline static var MAX_ITEMS_PER_PAGE : Int = 9;
    
    public function new(screenWidth : Int,
            screenHeight : Int,
            assetManager : AssetManager,
            onLevelSelectedCallback : Function,
            onDismissCallback : Function)
    {
        super();
        
        m_assetManager = assetManager;
        m_onLevelSelectedCallback = onLevelSelectedCallback;
        m_onDismissCallback = onDismissCallback;
        
        var arrowBitmapData : BitmapData = assetManager.getBitmapData("arrow_short");
        var disablingQuad : Bitmap = new Bitmap(new BitmapData(screenWidth, screenHeight, false, 0x000000));
        disablingQuad.alpha = 0.5;
        addChild(disablingQuad);
		
        var background : Bitmap = new Bitmap(assetManager.getBitmapData("summary_background"));
        background.scaleX = background.scaleY = 0.75;
        background.x = (screenWidth - background.width) * 0.5;
        background.y = (screenHeight - background.height) * 0.5;
        addChild(background);
        m_background = background;
        m_backgroundBoundsBuffer = new Rectangle();
        
        m_selectorTitle = new TextField();
		m_selectorTitle.width = screenWidth;
		m_selectorTitle.height = 50;
		m_selectorTitle.text = "";
		m_selectorTitle.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF));
        m_selectorTitle.y = background.y + 15;  // extra space because of border around background image  
        addChild(m_selectorTitle);
		
        m_buttonCanvas = new Sprite();
        addChild(m_buttonCanvas);
        m_buttonCanvasBounds = new Rectangle(0, 0, background.width - (5 * arrowBitmapData.width), background.height - m_selectorTitle.height);
        m_buttonCanvas.x = background.x + (background.width - m_buttonCanvasBounds.width) * 0.5;
        m_buttonCanvas.y = m_selectorTitle.y + m_selectorTitle.height;
        
        m_progressIndicator = new TextField();
		m_progressIndicator.width = screenWidth;
		m_progressIndicator.height = 50;
		m_progressIndicator.text = "";
		m_progressIndicator.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER));
        m_progressIndicator.y = background.y + background.height - (m_progressIndicator.height + 5);
        addChild(m_progressIndicator);
        
        var pageChangeButtonScaleFactor : Float = 1.25;
        var leftUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, pageChangeButtonScaleFactor);
        var leftOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, pageChangeButtonScaleFactor, 0xCCCCCC);
        m_prevPageButton = WidgetUtil.createButtonFromImages(
                        leftUpImage,
                        leftOverImage,
                        null,
                        leftOverImage,
                        null,
                        null,
                        null
                        );
		m_prevPageButton.scaleWhenDown = 0.9;
        m_prevPageButton.addEventListener(MouseEvent.CLICK, onPrevTriggered);
        m_prevPageButton.x = background.x + arrowBitmapData.width * 0.5;
        m_prevPageButton.y = background.y + (background.height - arrowBitmapData.height) * 0.5;
        
        var rightUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, pageChangeButtonScaleFactor, 0xFFFFFF);
        var rightOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, pageChangeButtonScaleFactor, 0xCCCCCC);
        m_nextPageButton = WidgetUtil.createButtonFromImages(
                        rightUpImage,
                        rightOverImage,
                        null,
                        rightOverImage,
                        null,
                        null,
                        null
                        );
        m_nextPageButton.scaleWhenDown = m_prevPageButton.scaleWhenDown;
        m_nextPageButton.addEventListener(MouseEvent.CLICK, onNextTriggered);
        m_nextPageButton.x = background.x + background.width - arrowBitmapData.width * 1.5;
        m_nextPageButton.y = m_prevPageButton.y;
        
		// TODO: uncomment once layout replacement is designed
        //m_buttonLayout = new TiledRowsLayout();
        //m_buttonLayout.useSquareTiles = true;
        //m_buttonLayout.padding = 15;
        //m_buttonLayout.verticalGap = 25;
        //m_buttonLayout.horizontalGap = 25;
        //m_buttonLayout.paging = TiledRowsLayout.PAGING_NONE;
        //m_buttonLayout.tileHorizontalAlign = TiledRowsLayout.TILE_HORIZONTAL_ALIGN_CENTER;
        //m_buttonLayout.tileVerticalAlign = TiledRowsLayout.TILE_VERTICAL_ALIGN_TOP;
        //m_buttonLayout.horizontalAlign = TiledRowsLayout.HORIZONTAL_ALIGN_CENTER;
        //m_buttonLayout.verticalAlign = TiledRowsLayout.VERTICAL_ALIGN_TOP;
        //m_buttonLayout.useVirtualLayout = false;
    }
    
    public function update(mouseState : MouseState) : Void
    {
        // If clicked outside the background area, close the selector
        if (mouseState.leftMousePressedThisFrame) 
        {
            m_backgroundBoundsBuffer = m_background.getBounds(this.stage);
            if (!m_backgroundBoundsBuffer.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y) &&
                m_onDismissCallback != null) 
            {
                m_onDismissCallback();
            }
        }
    }
    
    public function open(setName : String, levels : Array<WordProblemLevelLeaf>) : Void
    {
        // Clear previous state
        clearPage();
        
        m_currentLevelNodes = levels;
        var completeCount : Int = 0;
        for (level in levels)
        {
            if (level.isComplete) 
            {
                completeCount++;
            }
        }
        
        m_selectorTitle.text = setName;
        m_progressIndicator.text = completeCount + " out of " + levels.length + " finished";
        
        m_currentPageIndex = 0;
        fillPageWithButtons(0);
        
        var numPagesAvailable : Int = Math.ceil(m_currentLevelNodes.length / MAX_ITEMS_PER_PAGE);
        if (numPagesAvailable > 1) 
        {
            addChild(m_prevPageButton);
            addChild(m_nextPageButton);
        }
    }
    
    public function close() : Void
    {
        clearPage();
        if (m_prevPageButton.parent != null) m_prevPageButton.parent.removeChild(m_prevPageButton);
        if (m_nextPageButton.parent != null) m_nextPageButton.parent.removeChild(m_nextPageButton);
    }
    
    private function onPrevTriggered(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        
        // Go to previous page of button if possible
        var numPagesAvailable : Int = Math.ceil(m_currentLevelNodes.length / MAX_ITEMS_PER_PAGE);
        if (m_currentPageIndex == 0) 
        {
            m_currentPageIndex = (numPagesAvailable - 1);
        }
        else 
        {
            m_currentPageIndex--;
        }
        
        clearPage();
        fillPageWithButtons(m_currentPageIndex);
    }
    
    private function onNextTriggered(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        
        // Go to next page of buttons if possible
        var numPagesAvailable : Int = Math.ceil(m_currentLevelNodes.length / MAX_ITEMS_PER_PAGE);
        if (m_currentPageIndex >= numPagesAvailable - 1) 
        {
            m_currentPageIndex = 0;
        }
        else 
        {
            m_currentPageIndex++;
        }
        
        clearPage();
        fillPageWithButtons(m_currentPageIndex);
    }
    
    private function fillPageWithButtons(pageIndex : Int) : Void
    {
        var startingLevelIndex : Int = MAX_ITEMS_PER_PAGE * pageIndex;
        var endLevelIndex : Int = startingLevelIndex + MAX_ITEMS_PER_PAGE;
        if (endLevelIndex > m_currentLevelNodes.length) 
        {
            endLevelIndex = m_currentLevelNodes.length;
        }
        
        var buttonsToLayout : Array<DisplayObject> = new Array<DisplayObject>();
        var i : Int = 0;
        for (i in startingLevelIndex...endLevelIndex){
            // Draw button for this level
            var levelButton : LabelButton = WidgetUtil.createButtonFromImages(
                    new Bitmap(m_assetManager.getBitmapData("fantasy_button_up")),
                    null,
                    null,
                    null,
                    (i + 1) + "",
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0x000000),
                    null
                    );
            levelButton.scaleWhenDown = 0.9;
            levelButton.scaleWhenOver = 1.1;
            levelButton.addEventListener(MouseEvent.CLICK, onLevelSelected);
            
            // Draw the star or lock icon
            var levelNode : WordProblemLevelLeaf = m_currentLevelNodes[i];
            if (levelNode.isComplete) 
            {
                // If the level is completed, draw a star at the top left corner
                var starImage : PivotSprite = new PivotSprite();
				starImage.addChild(new Bitmap(m_assetManager.getBitmapData("level_button_star")));
                starImage.pivotX = starImage.width * 0.5;
                starImage.pivotY = starImage.height * 0.5;
                starImage.x = 6;
                starImage.y = 6;
                levelButton.addChild(starImage);
            }
            
            m_buttonCanvas.addChild(levelButton);
            buttonsToLayout.push(levelButton);
        }
        
		// TODO: uncomment once layout replacement is designed
        //m_buttonLayout.layout(buttonsToLayout, m_buttonCanvasBounds);
    }
    
    private function clearPage() : Void
    {
        while (m_buttonCanvas.numChildren > 0)
        {
            var child : DisplayObject = m_buttonCanvas.getChildAt(0);
            if (Std.is(child, LabelButton)) 
            {
                child.removeEventListener(MouseEvent.CLICK, onLevelSelected);
            }
            
			if (child.parent != null) child.parent.removeChild(child);
			child = null;
        }
    }
    
    private function onLevelSelected(event : Dynamic) : Void
    {
        // Assum the label on the button will give us the index of the node to use
        var target : LabelButton = try cast(event.target, LabelButton) catch(e:Dynamic) null;
        if (target != null) 
        {
            Audio.instance.playSfx("button_click");
            var levelIndex : Int = Std.parseInt(target.label) - 1;
            if (levelIndex >= 0 && levelIndex < m_currentLevelNodes.length && m_onLevelSelectedCallback != null) 
            {
                m_onLevelSelectedCallback(m_currentLevelNodes[levelIndex]);
            }
        }
    }
}
