package wordproblem.playercollections.scripts
{
    import dragonbox.common.ui.MouseState;
    
    import feathers.controls.Button;
    
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
    public class PlayerCollectionViewer extends ScriptNode
    {
        /**
         * Button used to back out of all the various view levels
         */
        protected var m_backButton:Button;
        protected var m_backButtonClickedLastFrame:Boolean;
        
        /**
         * This is container in which all graphics should be added to
         */
        protected var m_canvasContainer:DisplayObjectContainer;
        
        protected var m_assetManager:AssetManager;
        
        protected var m_mouseState:MouseState;
        
        /**
         * Button to go to the previous page of content
         */
        protected var m_scrollLeftButton:Button;
        protected var m_scrollLeftClickedLastFrame:Boolean;
        
        /**
         * Button to go to the next page of content
         */
        protected var m_scrollRightButton:Button;
        protected var m_scrollRightClickedLastFrame:Boolean;
        
        /**
         * A title textfield that explains what the current screen is showing,
         * mainly just to say the category being viewed and whether the player is at the 
         * category select screen
         */
        protected var m_titleText:TextField;
        
        /**
         * Some text at the bottom of the screen showing the user the page number the player is on
         */
        protected var m_pageIndicatorText:TextField;
        
        /**
         * The current page of items currently visible
         */
        protected var m_activeItemPageIndex:int;
        
        protected var m_buttonColorData:ButtonColorData;
        
        public function PlayerCollectionViewer(canvasContainer:DisplayObjectContainer,
                                               assetManager:AssetManager, 
                                               mouseState:MouseState,
                                               buttonColorData:ButtonColorData,
                                               id:String=null, 
                                               isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_canvasContainer = canvasContainer;
            m_assetManager = assetManager;
            m_mouseState = mouseState;
            m_buttonColorData = buttonColorData;
            
            var sidePadding:Number = 15;
            var arrowTexture:Texture = assetManager.getTexture("arrow_short");
            var scaleFactor:Number = 1.5;
            var leftUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor);
            var leftOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor, 0xCCCCCC);
            
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
            
            var rightUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xFFFFFF);
            var rightOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xCCCCCC);
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
        
        public function show():void
        {
            this.setIsActive(true);
            m_scrollLeftButton.addEventListener(Event.TRIGGERED, onScrollLeftButtonClicked);
            m_scrollRightButton.addEventListener(Event.TRIGGERED, onScrollRightButtonClicked);
            
            if (m_backButton != null)
            {
                m_backButton.addEventListener(Event.TRIGGERED, onBackButtonClicked);
            }
        }
        
        public function hide():void
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
        
        protected function showScrollButtons(doShow:Boolean):void
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
        
        protected function showPageIndicator(currentPage:int, totalPages:int):void
        {
            m_pageIndicatorText.text = currentPage + " / " + totalPages;
            m_canvasContainer.addChild(m_pageIndicatorText);
        }
        
        protected function createBackButton():void
        {
            var arrowRotateTexture:Texture = m_assetManager.getTexture("arrow_rotate");
            var scaleFactor:Number = 0.65;
            var backUpImage:Image = new Image(arrowRotateTexture);
            backUpImage.color = 0xFBB03B;
            backUpImage.scaleX = backUpImage.scaleY = scaleFactor;
            var backOverImage:Image = new Image(arrowRotateTexture);
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
        
        private function onScrollLeftButtonClicked():void
        {
            m_scrollLeftClickedLastFrame = true;
        }
        
        private function onScrollRightButtonClicked():void
        {
            m_scrollRightClickedLastFrame = true;
        }
        
        private function onBackButtonClicked():void
        {
            // Buffer the click on the back button
            m_backButtonClickedLastFrame = true;
        }
    }
}