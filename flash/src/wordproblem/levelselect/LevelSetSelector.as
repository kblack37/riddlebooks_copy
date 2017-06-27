package wordproblem.levelselect
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    
    import dragonbox.common.ui.MouseState;
    
    import feathers.controls.Button;
    import feathers.layout.TiledRowsLayout;
    import feathers.layout.ViewPortBounds;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    
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
    public class LevelSetSelector extends Sprite
    {
        /**
         * The layout algorithm to use for buttons.
         */
        private var m_buttonLayout:TiledRowsLayout;
        
        private var m_background:DisplayObject;
        private var m_backgroundBoundsBuffer:Rectangle;
        private var m_prevPageButton:Button;
        private var m_nextPageButton:Button;
        
        private var m_assetManager:AssetManager;
        private var m_onLevelSelectedCallback:Function;
        private var m_onDismissCallback:Function;
        
        private var m_selectorTitle:TextField;
        private var m_progressIndicator:TextField;
        private var m_buttonCanvas:Sprite;
        private var m_buttonCanvasBounds:ViewPortBounds;
        
        /**
         * The current set of levels that should be displayed
         */
        private var m_currentLevelNodes:Vector.<WordProblemLevelLeaf>
        
        private var m_currentPageIndex:int;
        private const MAX_ITEMS_PER_PAGE:int = 9;
        
        public function LevelSetSelector(screenWidth:Number, 
                                         screenHeight:Number, 
                                         assetManager:AssetManager, 
                                         onLevelSelectedCallback:Function, 
                                         onDismissCallback:Function)
        {
            super();
            
            m_assetManager = assetManager;
            m_onLevelSelectedCallback = onLevelSelectedCallback;
            m_onDismissCallback = onDismissCallback;
            
            var arrowTexture:Texture = assetManager.getTexture("arrow_short");
            var disablingQuad:Quad = new Quad(screenWidth, screenHeight, 0x000000);
            disablingQuad.alpha = 0.5;
            addChild(disablingQuad);
            var background:Image = new Image(assetManager.getTexture("summary_background"));
            background.scaleX = background.scaleY = 0.75;
            background.x = (screenWidth - background.width) * 0.5;
            background.y = (screenHeight - background.height) * 0.5;
            addChild(background);
            m_background = background;
            m_backgroundBoundsBuffer = new Rectangle();
            
            m_selectorTitle = new TextField(screenWidth, 50, "", GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF);
            m_selectorTitle.hAlign = HAlign.CENTER;
            m_selectorTitle.y = background.y + 15; // extra space because of border around background image
            addChild(m_selectorTitle);
            m_buttonCanvas = new Sprite();
            addChild(m_buttonCanvas);
            m_buttonCanvasBounds = new ViewPortBounds();
            m_buttonCanvasBounds.maxWidth = background.width - (5 * arrowTexture.width);
            m_buttonCanvasBounds.maxHeight = background.height - m_selectorTitle.height;
            m_buttonCanvas.x = background.x + (background.width - m_buttonCanvasBounds.maxWidth) * 0.5;
            m_buttonCanvas.y = m_selectorTitle.y + m_selectorTitle.height;
            
            m_progressIndicator = new TextField(screenWidth, 50, "", GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF);
            m_progressIndicator.hAlign = HAlign.CENTER;
            m_progressIndicator.y = background.y + background.height - (m_progressIndicator.height + 5);
            addChild(m_progressIndicator);
            
            var pageChangeButtonScaleFactor:Number = 1.25;
            var leftUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, pageChangeButtonScaleFactor);
            var leftOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, pageChangeButtonScaleFactor, 0xCCCCCC);
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
            m_prevPageButton.addEventListener(Event.TRIGGERED, onPrevTriggered);
            m_prevPageButton.x = background.x + arrowTexture.width * 0.5;
            m_prevPageButton.y = background.y + (background.height - arrowTexture.height) * 0.5;
            
            var rightUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, pageChangeButtonScaleFactor, 0xFFFFFF);
            var rightOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, pageChangeButtonScaleFactor, 0xCCCCCC);
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
            m_nextPageButton.addEventListener(Event.TRIGGERED, onNextTriggered);
            m_nextPageButton.x = background.x + background.width - arrowTexture.width * 1.5;
            m_nextPageButton.y = m_prevPageButton.y;
            
            m_buttonLayout = new TiledRowsLayout();
            m_buttonLayout.useSquareTiles = true;
            m_buttonLayout.padding = 15;
            m_buttonLayout.verticalGap = 25;
            m_buttonLayout.horizontalGap = 25;
            m_buttonLayout.paging = TiledRowsLayout.PAGING_NONE;
            m_buttonLayout.tileHorizontalAlign = TiledRowsLayout.TILE_HORIZONTAL_ALIGN_CENTER;
            m_buttonLayout.tileVerticalAlign = TiledRowsLayout.TILE_VERTICAL_ALIGN_TOP;
            m_buttonLayout.horizontalAlign = TiledRowsLayout.HORIZONTAL_ALIGN_CENTER;
            m_buttonLayout.verticalAlign = TiledRowsLayout.VERTICAL_ALIGN_TOP;
            m_buttonLayout.useVirtualLayout = false;
        }
        
        public function update(mouseState:MouseState):void
        {
            // If clicked outside the background area, close the selector
            if (mouseState.leftMousePressedThisFrame)
            {
                m_background.getBounds(this.stage, m_backgroundBoundsBuffer);
                if (!m_backgroundBoundsBuffer.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y) &&
                    m_onDismissCallback != null)
                {
                    m_onDismissCallback();
                }
            }
        }
        
        public function open(setName:String, levels:Vector.<WordProblemLevelLeaf>):void
        {
            // Clear previous state
            clearPage();
            
            m_currentLevelNodes = levels;
            var completeCount:int = 0;
            for each (var level:WordProblemLevelLeaf in levels)
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
            
            var numPagesAvailable:int = Math.ceil(m_currentLevelNodes.length / MAX_ITEMS_PER_PAGE);
            if (numPagesAvailable > 1)
            {
                addChild(m_prevPageButton);
                addChild(m_nextPageButton);
            }
        }
        
        public function close():void
        {
            clearPage();
            m_prevPageButton.removeFromParent();
            m_nextPageButton.removeFromParent();
        }
        
        private function onPrevTriggered():void
        {
            Audio.instance.playSfx("button_click");
            
            // Go to previous page of button if possible
            var numPagesAvailable:int = Math.ceil(m_currentLevelNodes.length / MAX_ITEMS_PER_PAGE);
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
        
        private function onNextTriggered():void
        {
            Audio.instance.playSfx("button_click");
            
            // Go to next page of buttons if possible
            var numPagesAvailable:int = Math.ceil(m_currentLevelNodes.length / MAX_ITEMS_PER_PAGE);
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
        
        private function fillPageWithButtons(pageIndex:int):void
        {
            var startingLevelIndex:int = MAX_ITEMS_PER_PAGE * pageIndex;
            var endLevelIndex:int = startingLevelIndex + MAX_ITEMS_PER_PAGE;
            if (endLevelIndex > m_currentLevelNodes.length)
            {
                endLevelIndex = m_currentLevelNodes.length;
            }
            
            var buttonsToLayout:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            var i:int;
            for (i = startingLevelIndex; i < endLevelIndex; i++)
            {
                // Draw button for this level
                var levelButton:Button = WidgetUtil.createButtonFromImages(
                    new Image(m_assetManager.getTexture("fantasy_button_up")),
                    null,
                    null,
                    null,
                    (i + 1) + "",
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0x000000),
                    null
                );
                levelButton.scaleWhenDown = 0.9;
                levelButton.scaleWhenHovering = 1.1;
                levelButton.addEventListener(Event.TRIGGERED, onLevelSelected);
                
                // Draw the star or lock icon
                var levelNode:WordProblemLevelLeaf = m_currentLevelNodes[i];
                if (levelNode.isComplete)
                {
                    // If the level is completed, draw a star at the top left corner
                    var starImage:Image = new Image(m_assetManager.getTexture("level_button_star"));
                    starImage.pivotX = starImage.width * 0.5;
                    starImage.pivotY = starImage.height * 0.5;
                    starImage.x = 6;
                    starImage.y = 6;
                    levelButton.addChild(starImage);
                }
                
                m_buttonCanvas.addChild(levelButton);
                buttonsToLayout.push(levelButton);
            }
            
            m_buttonLayout.layout(buttonsToLayout, m_buttonCanvasBounds);
        }
        
        private function clearPage():void
        {
            while (m_buttonCanvas.numChildren > 0)
            {
                var child:DisplayObject = m_buttonCanvas.getChildAt(0);
                if (child is Button)
                {
                    child.removeEventListener(Event.TRIGGERED, onLevelSelected);
                }
                
                child.removeFromParent(true);
            }
        }
        
        private function onLevelSelected(event:Event):void
        {
            // Assum the label on the button will give us the index of the node to use
            var target:Button = event.target as Button;
            if (target != null)
            {
                Audio.instance.playSfx("button_click");
                var levelIndex:int = parseInt(target.label) - 1;
                if (levelIndex >= 0 && levelIndex < m_currentLevelNodes.length && m_onLevelSelectedCallback != null)
                {
                    m_onLevelSelectedCallback(m_currentLevelNodes[levelIndex]);
                }
            }
        }
    }
}