
package wordproblem.engine.widget
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    import feathers.controls.Button;
    import feathers.controls.IScrollBar;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.component.MouseInteractableComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.text.model.DocumentNode;
    import wordproblem.engine.text.model.TextNode;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.resource.AssetManager;
    
    /**
     * General purpose display for text and image content representing a word problem.
     * 
     * It is a composition of page views and exposes an interface to allow for
     * the visual manipulation of items in each page as well as provide access
     * to the backing document model.
     * 
     * Some notes about the layout:
     * Scrolling
     * 
     * It is made up a visible portion determined by the viewport and possibly obscured
     * regions outside of it.
     * 
     * The viewport determines the window that is interactable and most clearly visible
     * to the player.
     */
    public class TextAreaWidget extends Sprite implements IBaseWidget
    {
        /**
         * Keep track of dynamic data properties of objects within the text area
         * 
         * Each portion of the textual content that has been identified can act as
         * an entity. This allows us to bind things like helper arrows or expressions
         * to certain portions of the text.
         */
        private var m_componentManager:ComponentManager;
        
        /**
         * Used to keep track of the dimension of the mask to apply on this object
         */
        private var m_totalWidth:Number;
        private var m_totalHeight:Number;
        
        /**
         * Dimension and location information about the viewable/interactable window
         */
        private var m_viewPort:Rectangle;
        
        /** The middle y value of the viewport is used for scroll limit calculations */
        private var m_viewPortMiddleY:Number;
        
        /**
         * This represents the texture for the background that scrolls along with
         * the text. The texture should be repeatable/tileable and is used for sampling
         * purposes.
         * 
         * A possible future extension would be to create unique textures for the top
         * and bottom of the page with the middle be tileable. For this to work we
         * would need to look at the y location of the scroll container, after it reaches
         * certain limits we sample from the start or end textures instead.
         * 
         * This requires all textures to be the same dimensions though
         */
        private var m_backgroundImageStack:Vector.<Image>;
        
        /**
         * This layer contains the pages of text but not the background.
         * The scroll layer is the object that will get shifted up and down as the user
         * scroll through the contents of a page.
         * 
         * If the scroll container is positioned at y=0, it is exactly at the top border of
         * the registration point of this widget.
         */
        private var m_scrollContainerLayer:Sprite;
        
        /**
         * Used to display any blurring affect ontop of the text content
         */
        private var m_foregroundLayer:Sprite;
        
        /**
         * The number of pixels left to scroll on any given frame. The reason we have this is that
         * is that we may want to have a delayed smooth scroll.
         * 
         * For example we want to scroll to a particular card image in a level. We want to gradually move
         * to that view.
         */
        private var m_scrollAmount:int;
        
        /**
         * Flag to determine whether or not each page should be autocentered within the viewport.
         * If false the page will always start at the very top of the viewport.
         */
        private var m_autoCenterPages:Boolean;
        
        /**
         * Set whether the user can manually scroll the text area up and down.
         * This flag does not affect the ability of the application to scroll though.
         */
        private var m_allowUserScroll:Boolean;
        
        /**
         * Keep track of all the text pages
         */
        private var m_textPages:Vector.<DocumentView>;
        
        /**
         * We assume that there is one 'page' visible on the screen at any one time
         */
        private var m_currentPageIndex:int;
        
        private var m_nextPageButton:Button;
        private var m_prevPageButton:Button;
        private var m_prevNextButtonBounds:Rectangle;
        
        /**
         * The texture to use for the scrolling page background
         */
        private var m_pageTexture:Texture;
        
        /**
         * Keep track of whether this widget should be display information
         * pertinent to the modeling phase or to the solving phase.
         */
        private var m_isActive:Boolean;
        
        /**
         * The ui component used by the player to manually scroll up and down.
         */
        private var m_scrollbar:IScrollBar;
        
        /**
         * Unless the background is tileable, we should not allow the background to scroll.
         */
        private var m_backgroundScroll:Boolean;
        private var m_backgroundRepeat:Boolean;
        
        /**
         * Function that gets called when the text area widget goes to a new page
         */
        private var m_onGoToPageCallback:Function;
        
        public function TextAreaWidget(assetManager:AssetManager,
                                       pageTexture:Texture, 
                                       backgroundScroll:String, 
                                       backgroundRepeat:String, 
                                       autoCenterPages:Boolean,
                                       allowScroll:Boolean)
        {
            m_scrollContainerLayer = new Sprite();
            m_foregroundLayer = new Sprite();
            m_pageTexture = pageTexture;
            m_scrollbar = WidgetUtil.createScrollbar(assetManager);
            m_scrollbar.addEventListener(Event.CHANGE, onScrollbarChange);
            
            m_isActive = true;
            
            m_backgroundScroll = (backgroundScroll == "scroll");
            m_backgroundRepeat = (backgroundRepeat == "repeat");
            
            var arrowTexture:Texture = assetManager.getTexture("arrow_short");
            var scaleFactor:Number = 1.5;
            var leftUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor);
            var leftOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor, 0xCCCCCC);
            
            m_prevPageButton = WidgetUtil.createButtonFromImages(
                leftUpImage,
                leftOverImage,
                null,
                leftOverImage,
                null,
                null,
                null
            );
            m_prevPageButton.scaleWhenDown = scaleFactor * 0.9;
            m_prevPageButton.addEventListener(Event.TRIGGERED, onClickPrevPage);

            var rightUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xFFFFFF);
            var rightOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xCCCCCC);
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
            m_nextPageButton.addEventListener(Event.TRIGGERED, onClickNextPage);
            
            m_prevNextButtonBounds = new Rectangle(0, 0, arrowTexture.width * scaleFactor, arrowTexture.height * scaleFactor);
            
            m_allowUserScroll = allowScroll;
            m_autoCenterPages = autoCenterPages;
            m_onGoToPageCallback = defaultOnGoToPageCallback;
            m_textPages = new Vector.<DocumentView>();
            
            // Prepare the text area to be able to add dynamic properties
            m_componentManager = new ComponentManager();
        }
        
        override public function dispose():void
        {
            m_componentManager.clear();
            
            m_isActive = false;
            super.dispose();
            
            // TODO: Proper cleanup of all the assets
            for each (var textPage:DocumentView in m_textPages)
            {
                textPage.removeFromParent(true);
            }
            this.removeChildren(0, -1, true);
        }
        
        public function getDocumentIdToExpressionMap():Object
        {
            var expressionComponents:Vector.<Component> = this.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var i:int;
            var documentIdToExpressionMap:Object = {};
            for (i = 0; i < expressionComponents.length; i++)
            {
                var expressionComponent:ExpressionComponent = expressionComponents[i] as ExpressionComponent;
                documentIdToExpressionMap[expressionComponent.entityId] = expressionComponent.expressionString;
            }
            
            return documentIdToExpressionMap;
        }
        
        public function get componentManager():ComponentManager
        {
            return m_componentManager;
        }
        
        public function getViewport():Rectangle
        {
            return m_viewPort;
        }
        
        public function setDimensions(width:Number, 
                                      height:Number, 
                                      viewPortWidth:Number, 
                                      viewPortHeight:Number,
                                      viewPortX:Number,
                                      viewPortY:Number):void
        {
            m_totalWidth = width;
            m_totalHeight = height;
            m_viewPort = new Rectangle(viewPortX, viewPortY, viewPortWidth, viewPortHeight);
            m_viewPortMiddleY = viewPortY + viewPortHeight / 2;
            
            // Partially cover up text at the top and bottom edges of the view port
            m_foregroundLayer.removeChildren();
            
            // Position the scrollbar off to the furthest right limit
            const scrollWidth:Number = 22;
            m_scrollbar.x = viewPortWidth - scrollWidth + viewPortX;
            m_scrollbar.y = viewPortY;
            m_scrollbar.height = viewPortHeight;
            
            // Position the prev and next page buttons to the left and right edges of the viewport respectively
            // Note that height and width of buttons are not set until after they have been added to the stage
            m_prevPageButton.x  = m_viewPort.left;
            m_prevPageButton.y = (m_viewPort.height - m_prevNextButtonBounds.height) * 0.5 + m_viewPort.y;
            m_nextPageButton.x = m_viewPort.right - m_prevNextButtonBounds.width - scrollWidth;
            m_nextPageButton.y = (m_viewPort.height - m_prevNextButtonBounds.height) * 0.5 + m_viewPort.y;
        }
        
        /**
         * This callback should be overridden for any situation where we do not the next/prev page
         * buttons to automatically appear
         * 
         * @param callback
         *      Params to function are the index of the page
         */
        public function setOnGoToPageCallback(callback:Function):void
        {
            if (callback == null)
            {
                callback = defaultOnGoToPageCallback;
            }
                
            m_onGoToPageCallback = callback;
            
            // Immediately call the function with the current page, to handle case where a page is already rendered
            m_onGoToPageCallback(getCurrentPageIndex());
        }
        
        /**
         * Toggle whether the paragraph text should be active in updating itself with regards
         * to input.
         */
        public function setIsActive(isActive:Boolean):void
        {
            m_isActive = isActive;
        }
        
        public function getIsActive():Boolean
        {
            return m_isActive;
        }
        
        public function getNextPageButton():DisplayObject
        {
            return m_nextPageButton;
        }
        
        public function getPrevPageButton():DisplayObject
        {
            return m_prevPageButton;
        }
        
        /**
         * Some levels do not want the auto-centering that occurs for some pages.
         * In this situation, some external. In addition they may not want the next/prev
         * page buttons to appear.
         * 
         * External scripts should be able to modify the visibility of the buttons
         * as well as the initial scroll position
         */
        public function setScrollLayerY(yValue:Number):void
        {
            m_scrollContainerLayer.y = yValue;
        }
        
        /**
         * Get back all active root document views
         * 
         * @return
         *      List of all root views for each page of displayable text content
         */
        public function getPageViews():Vector.<DocumentView>
        {
            return m_textPages;
        }
        
        /**
         *
         * @return
         *      A value between zero and the maximum number of pages input for the level
         */
        public function getCurrentPageIndex():int
        {
            return m_currentPageIndex;
        }
        
        /**
         * This is like an init function to let the widget know it is ok to start showing the pages
         * 
         * A call will still need to be made to showPageAtIndex
         */
        public function renderText():void
        {
            // Dispose of previous contents
            super.removeChildren();

            m_backgroundImageStack = new Vector.<Image>();
			
			if (m_pageTexture != null)
			{
				const pageTextureHeight:Number = m_pageTexture.height;
				
				// If we repeat we initially create as many background texture display block as needed,
				// otherwise we just create one
				const numTexturesNeeded:Number = (m_backgroundRepeat) ? Math.ceil(m_viewPort.height / pageTextureHeight) + 1 : 1;
				var i:int;
				for (i = 0; i < numTexturesNeeded; i++)
				{
					const backgroundImage:Image = new Image(m_pageTexture);
					m_backgroundImageStack.push(backgroundImage);
					addChildAt(backgroundImage, 0);
				}
			}
            
            positionImages(m_backgroundImageStack);
            
            // The scroll container will always initially start anchored at the same registration point as this overall
            // page container
            addChild(m_scrollContainerLayer);
            
            // Add foreground graphics
            addChild(m_foregroundLayer);
            
            // Buttons are only useful if there are multiple pages.
            // Even then we may have situations where the level script will want to hide them
            // For example: a level may want to hide the buttons until they finish a particular stage of the level
            m_foregroundLayer.addChild(m_nextPageButton);
            m_foregroundLayer.addChild(m_prevPageButton);
            
            // Add mask
            this.clipRect = new Rectangle(0, 0, m_totalWidth, m_totalHeight);
            
            if (m_textPages.length > 0)
            {
                showPageAtIndex(0);
            }
            
            // Signal that the text area has finished redrawing a set of pages
            this.dispatchEventWith(GameEvent.TEXT_AREA_REDRAWN);
        }
        
        public function showPageAtIndex(pageIndex:int):void
        {
            const numPages:int =  m_textPages.length;
            if (pageIndex >= 0 && pageIndex < numPages)
            {
                // Clear all previous contents
                m_scrollContainerLayer.removeChildren();
                
                var textPageView:DocumentView = m_textPages[pageIndex];
                
                // Force a visit to so initial properties like text-decoration and visibility are
                // applied immediately on a page change. This is to fix a bug in tutorial levels where
                // after replacing parts of the text and redrawing it, it takes one frame for settings
                // to be applied. Incorrect view flashes briefly at this time.
                textPageView.visit();
                
                var pageHeight:Number = textPageView.totalHeight;
                m_scrollContainerLayer.addChild(textPageView);
                
                m_currentPageIndex = pageIndex;
                
                // Only show buttons if there are in fact pages either before or after this one
                m_onGoToPageCallback(pageIndex);
                
                // If scroll not enabled, center the contents and hide the scrollbar
                // Otherwise position the contents to give just enough padding to the text area
                if (m_autoCenterPages)
                {
                    const pageNeedsToScroll:Boolean = pageHeight > m_viewPort.height
                    if (!pageNeedsToScroll)
                    {
                        m_scrollContainerLayer.y = m_viewPortMiddleY - pageHeight * 0.5; 
                    }
                    else
                    {
                        m_scrollContainerLayer.y = m_viewPortMiddleY * 0.5
                    }
                }
                else
                {
                    m_scrollContainerLayer.y = m_viewPort.top;
                }
                
                // The bottom most allowable scroll needs to take into account the view port
                m_possibleScrollLocations.bottom = m_scrollContainerLayer.y;
                
                // TODO: It is at this point that we reset all components
                // Text area only has components for the active page
                _addComponentsForDocumentView(textPageView);
            }
        }
        
        /**
         * Get all views in the current page that match a given id.
         * 
         * IMPORTANT: Do not assume that id's are unique
         * 
         * @param id
         *      The id name of the document views to match
         * @param outDocumentViews
         *      A list that will contain all of the document views that matches the given id.
         *      Will be empty if nothing matches
         * @param pageIndex
         *      If -1, look at the current active page
         */
        public function getDocumentViewsAtPageIndexById(viewId:String, 
                                                        outDocumentViews:Vector.<DocumentView> = null, 
                                                        pageIndex:int = -1):Vector.<DocumentView>
        {
            var idSelector:String = "#" + viewId;
            return getViewsMatchingSelector(idSelector, outDocumentViews, pageIndex);
        }
        
        /**
         * Get all views in the current page that match a given class name
         * 
         * @param class
         *      The name of the class of the document views to match
         * @param pageIndex
         *      If -1, use current page
         */
        public function getDocumentViewsByClass(className:String, 
                                                outDocumentViews:Vector.<DocumentView> = null, 
                                                pageIndex:int = -1):Vector.<DocumentView>
        {
            var classSelector:String = "." + className;
            return getViewsMatchingSelector(classSelector, outDocumentViews, pageIndex);
        }
        
        /**
         * Get all views in a page matching an element
         */
        public function getDocumentViewsByElement(elementName:String, 
                                                  outDocumentViews:Vector.<DocumentView> = null, 
                                                  pageIndex:int = -1):Vector.<DocumentView>
        {
            return getViewsMatchingSelector(elementName, outDocumentViews, pageIndex);
        }
        
        private function getViewsMatchingSelector(selectorName:String, 
                                                  outDocumentViews:Vector.<DocumentView> = null, 
                                                  pageIndex:int = -1):Vector.<DocumentView>
        {
            if (outDocumentViews == null)
            {
                outDocumentViews = new Vector.<DocumentView>();
            }
            
            if (pageIndex < 0 || pageIndex >= m_textPages.length)
            {
                pageIndex = m_currentPageIndex;
            }
            
            var currentPage:DocumentView = m_textPages[pageIndex];
            currentPage.getDocumentViewsBySelector(selectorName, currentPage, outDocumentViews);
            
            return outDocumentViews;
        }
        
        /**
         * Get back the textual content of a particular view
         * 
         * @param viewId
         *      Id of the document to fetch
         * @return
         *      A string representation of the content contained in the view
         */
        public function getTextContentById(viewId:String):String
        {
            var result:String = "";
            const targetViews:Vector.<DocumentView> = this.getDocumentViewsAtPageIndexById(viewId);
            if (targetViews.length > 0)
            {
                const targetView:DocumentView = targetViews[0];
                const node:DocumentNode = targetView.node;
                const textNodes:Vector.<TextNode> = new Vector.<TextNode>();
                getTextNodes(node, textNodes);
                
                // Need to recursively gather all the text nodes that are contained
                // within the view.
                function getTextNodes(node:DocumentNode, outTextNodes:Vector.<TextNode>):void
                {
                    if (node is TextNode)
                    {
                        outTextNodes.push(node);
                    }
                    else
                    {
                        const children:Vector.<DocumentNode> = node.children;
                        for (var i:int = 0; i < children.length; i++)
                        {
                            getTextNodes(children[i], outTextNodes);
                        }
                    }
                }
                
                if (textNodes.length >= 0)
                {
                    result += textNodes[0].content;
                    for (var i:int = 1; i < textNodes.length; i++)
                    {
                        result += (" " + textNodes[i].content);
                    }
                }
                
            }
            
            return result;
        }
        
        /**
         * Given a point in global coordinates, get back the document view hit by
         * that point.
         * 
         * @return
         *      null if no display was hit in the current page of text
         */
        public function hitTestDocumentView(globalPoint:Point, ignoreNonSelectable:Boolean=true):DocumentView
        {
            var currentPage:DocumentView = m_textPages[m_currentPageIndex];
            const hitView:DocumentView = currentPage.hitTestPoint(globalPoint, ignoreNonSelectable);
            return hitView;
        }
        
        /**
         * Get whether a given document view is inside another view with a given id.
         * 
         * @param view
         *      Reference of the child view to check
         * @param containerId
         *      The id value of the document view containing the child view
         * @return
         *      True if a document view with the matching container id is either the
         *      same as the given view or is a parent of it.
         */
        public function getViewIsInContainer(view:DocumentView, 
                                             containerId:String):Boolean
        {
            var isInContainer:Boolean = false;
            
            // create a chained list of view from child to parent representing all possible containers
            // the clicked view could be part of
            const possibleContainerViews:Vector.<DocumentView> = new Vector.<DocumentView>();
            var currentView:DocumentView = view;
            while (currentView != null)
            {
                possibleContainerViews.push(currentView);
                currentView = currentView.parentView;
            }
            
            for (var j:int = 0; j < possibleContainerViews.length; j++)
            {
                const containerView:DocumentView = possibleContainerViews[j];
                const containerNodeId:String = containerView.node.id;
                if (containerNodeId == containerId)
                {
                    isInContainer = true;
                    break;
                }
            }
            
            return isInContainer;
        }
        
        private const mousePoint:Point = new Point();
        private const scrollContainerBuffer:Rectangle = new Rectangle();
        public function update(time:Time, mouseState:MouseState):void
        {
            if (!m_isActive)
            {
                return;
            }
            
            // It is only on the update loop can we correctly determine the correct
            m_scrollContainerLayer.getBounds(this, scrollContainerBuffer);
            var heightOfVisibleTextContent:Number = scrollContainerBuffer.height;
            
            // Set a new bottom scroll limit
            setBottomScrollLimit();
            
            // Add scrollbar floating above all the contents.
            // Since it is a feathers component, objects above it will automatically block mouse events
            const pageNeedsToScroll:Boolean = heightOfVisibleTextContent > m_viewPort.height
            if (m_allowUserScroll && pageNeedsToScroll && m_scrollbar.parent == null)
            {
                addChild(m_scrollbar as DisplayObject);
                
                m_scrollbar.value = this.currentLocationToRatio(m_scrollContainerLayer.y);
            }
            else if (!pageNeedsToScroll && m_scrollbar.parent != null)
            {
                m_scrollbar.removeFromParent();
            }
            
            // Iterate through the document views and apply updates to the backing data
            const numPages:int = m_textPages.length;
            var i:int;
            var textPage:DocumentView;
            for (i = 0; i < numPages; i++)
            {
                textPage = m_textPages[i];
                textPage.visit();
            }
            
            const mouseWheelDelta:int = mouseState.mouseWheelDeltaThisFrame;
            if (mouseWheelDelta != 0 && m_allowUserScroll)
            {
                // Adding positive values scrolls up
                // Adding negative values scrolls down
                scrollDelta = mouseWheelDelta * 20;
                m_scrollbar.value = this.currentLocationToRatio(scrollDelta + m_scrollContainerLayer.y);
            }
            else if (m_scrollAmount != 0)
            {
                // This should funnel through a call to change the scrollbar value
                // Figure out the new location, convert it to a ratio, and allow the scrollbar change callback to alter
                // the actual position
                var scrollDelta:Number = 20;
                var negativeModifier:int = (m_scrollAmount > 0) ? 1 : -1;
                scrollDelta = Math.min(scrollDelta, Math.abs(m_scrollAmount)) * negativeModifier;
                m_scrollAmount -= scrollDelta;
                m_scrollbar.value = this.currentLocationToRatio(scrollDelta + m_scrollContainerLayer.y);
            }
        }
        
        /**
         * Toggle whether or not the player should be able to scroll at all
         * 
         * @param value
         *      If false, even if the page contents is not all visible in the viewport, there is no
         *      scrollbar to move the contents.
         *      If true, the page contents do not fit the viewport, a scrollbar appears 
         */
        public function setScrollEnabled(value:Boolean):void
        {
            m_allowUserScroll = value;
            
            // Hide scrollbar if it is visible
            var scrollbarDisplay:DisplayObject = m_scrollbar as DisplayObject;
            if (scrollbarDisplay.parent && !value)
            {
                scrollbarDisplay.removeFromParent();
            }
        }
        
        /**
         * Scroll to a particular document id such that it is centered in the screen.
         * 
         * The scrolling for now occurs smoothly. By calling this function, we will override
         * the scroll setting for the text area.
         */
        public function scrollToDocumentNode(documentId:String):void
        {
            // Right now we just pick the first visible node
            const documentViews:Vector.<DocumentView> = this.getDocumentViewsAtPageIndexById(documentId);
            var i:int;
            const numViews:int = documentViews.length;
            for (i = 0; i < numViews; i++)
            {
                var documentView:DocumentView = documentViews[i];
                if (documentView.node.getIsVisible())
                {
                    // Find the scroll y position of the document view
                    // Normalize to global coordinates
                    const documentViewLocal:Point = new Point();
                    const documentViewGlobal:Point = new Point();
                    documentViewLocal.setTo(documentView.x, documentView.y);
                    documentView.parent.localToGlobal(documentViewLocal, documentViewGlobal);
                    
                    // Find the current scroll position
                    const scrollLocal:Point = new Point();
                    const scrollGlobal:Point = new Point();
                    scrollLocal.setTo(0, m_viewPortMiddleY);
                    m_scrollContainerLayer.parent.localToGlobal(scrollLocal, scrollGlobal);
                    
                    // Calculate the difference between the midpoint y and and the target y
                    const scrollAmount:Number = Math.floor(scrollGlobal.y - documentViewGlobal.y);
                    m_scrollAmount = scrollAmount;
                    break;
                }
            }
        }
        
        /**
         * Tell the widget to scroll by a particular amount. This immediately updates the position of the content
         * BUT does not update the scrollbar
         * 
         * @param scrollDelta
         *      The amount to scroll the content. A positive value scrolls downward.
         */
        private function scrollByAmount(scrollDelta:Number):void
        {
            const yAfterScroll:Number = m_scrollContainerLayer.y + scrollDelta;
            
            if (scrollDelta != 0)
            {
                m_scrollContainerLayer.y += scrollDelta;
                
                // We assume the visible background is composed of n-tiled textures on top of each other
                // If we shift the backgrounds up or down we will create visible gaps in we need to fill,
                // however the number of tiles to clip be enough to fill in the gaps
                if (m_backgroundScroll)
                {
                    var clipBackground:Boolean = false;
                    const imageHeight:Number = m_backgroundImageStack[0].height;
                    var numIterations:int = m_backgroundImageStack.length;
                    var maxIndexClippedTop:int = -1;
                    var minIndexClippedBottom:int = -1;
                    var gapAtTop:Boolean = false;
                    var gapAtBottom:Boolean = false;
                    var i:int;
                    for (i = 0; i < numIterations; i++)
                    {
                        const image:Image = m_backgroundImageStack[i];
                        image.y += scrollDelta;
                        
                        if (i == 0 && image.y > 0)
                        {
                            gapAtTop = true;
                        }
                        
                        if (i == numIterations - 1 && image.y + imageHeight < m_viewPort.height)
                        {
                            gapAtBottom = true;
                        }
                        
                        // Image gets clipped entirely at the top
                        if (image.y + imageHeight < 0)
                        {
                            // Shift it to the end
                            maxIndexClippedTop = i;
                            clipBackground = true;
                        }
                            // Image gets clipped entirely at the bottom
                        else if (image.y > m_viewPort.height && minIndexClippedBottom == -1 && gapAtTop)
                        {
                            // Shift it to the zero index
                            minIndexClippedBottom = i;
                            clipBackground = true;
                        }
                    }
                    
                    var clippedImage:Image;
                    var shiftAmountY:Number;
                    if (maxIndexClippedTop >= 0)
                    {
                        shiftAmountY = (maxIndexClippedTop + 2) * imageHeight;
                        while (maxIndexClippedTop >= 0)
                        {
                            clippedImage = m_backgroundImageStack.shift();
                            clippedImage.y += shiftAmountY;
                            m_backgroundImageStack.push(clippedImage);
                            maxIndexClippedTop--;
                        }
                    }
                    else if (minIndexClippedBottom >= 0)
                    {
                        const limit:int = m_backgroundImageStack.length;
                        shiftAmountY = limit * imageHeight;
                        while (minIndexClippedBottom < limit)
                        {
                            clippedImage = m_backgroundImageStack.pop();
                            clippedImage.y -= shiftAmountY;
                            m_backgroundImageStack.unshift(clippedImage);
                            minIndexClippedBottom++;
                        }
                    }
                }
            }
        }
        
        /**
         * Reorient the background 
         */
        private function positionImages(imageStack:Vector.<Image>):void
        {
			if (imageStack.length > 0)
			{
	            const anchorImage:Image = imageStack[0];
	            const imageHeight:Number = anchorImage.height;
	            var yOffset:Number = anchorImage.y + imageHeight;
	            for (var i:int = 1; i < imageStack.length; i++)
	            {
	                const image:Image = imageStack[i];
	                image.y = yOffset;
	                yOffset += imageHeight;
	            }
			}
        }
        
        /**
         * Need to expose this function to re-adjust bounds of the visible text content.
         * The bottom limit gives an the y value of the visible content
         */
        public function setBottomScrollLimit():void
        {
            var currentPage:DocumentView = m_textPages[m_currentPageIndex];
            var furthestView:DocumentView = currentPage.getFurthestDocumentView();
            scrollContainerBuffer.setTo(0, 0, 0, 0);
            if (furthestView != null && furthestView.stage != null)
            {
                furthestView.getBounds(m_scrollContainerLayer, scrollContainerBuffer);
            }
            
            var bounds:Rectangle = scrollContainerBuffer;
            
            // The top most edge should ensure you can't go so far up all text goes out of view
            // which is why we need to add extra space from the view port
            m_possibleScrollLocations.top = (m_possibleScrollLocations.bottom - bounds.bottom) + m_viewPortMiddleY;
        }
        
        public function getAllDocumentIdsTiedToExpression():Array
        {
            var expressionComponents:Vector.<Component> = this.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var numComponents:int = expressionComponents.length;
            var targetDocIds:Array = [];
            var i:int;
            for (i = 0; i < numComponents; i++)
            {
                targetDocIds.push((expressionComponents[i] as ExpressionComponent).entityId);
            }
            
            return targetDocIds;
        }
        
        /**
         * This callback is triggered whenever the user either interacts with the actual scrollbar ui
         * OR when the value property of the scrollbar is altered.
         * 
         * This means it can be triggered
         */
        private function onScrollbarChange(event:Event):void
        {
            const target:IScrollBar = event.currentTarget as IScrollBar;
            const ratio:Number = target.value;
            
            // Use the ratio and the total pixel height of the content to figure out the exact location
            // to scroll to. The delta between that location and the current one is the amount to scroll by
            // A value of 0.0 means the content is scrolled to the top as far as possible, while a value of
            // 1.0 means the content is scrolled to the bottom as far as possible.
            const scrollToYLocation:int = this.currentRatioToLocation(ratio);
            this.scrollByAmount(scrollToYLocation - m_scrollContainerLayer.y);
        }
        
        /**
         * Prevents scrolling to a point where no content is visible.
         * 
         * This rectangle provide the possible range of y-values that only TOP edge of the scroll container can
         * take, note that the numbers at the top edge are smaller than those at the bottom edge.
         * 
         * I.e. the top value of this rectangle is the value such that nearly all text content is scrolled as
         * far up as possible, the bottom value of the rectangle is the value such that nearly all text content
         * is scrolled as far down as possible. There is no case where we want all text to be completely hidden
         * in either direction so the height of this should never be greater than the height of the visible
         * text content.
         * 
         * A ratio of 0.0 maps to the bottom edge, while a ratio of 1.0 maps to the top edge
         */
        private const m_possibleScrollLocations:Rectangle = new Rectangle();
        
        /**
         * 
         * @return
         *      A value between 0.0 and 1.0 to indicate the position the scroll bar should be set to
         */
        private function currentLocationToRatio(locationY:Number):Number
        {
            // The ratio needs to be clamped from zero to one
            var ratio:Number = (locationY - m_possibleScrollLocations.bottom) / -m_possibleScrollLocations.height;
            if (ratio < 0.0)
            {
                ratio = 0.0;
            }
            else if (ratio > 1.0)
            {
                ratio = 1.0;
            }
            
            return ratio;
        }
        
        /**
         * 
         * @return
         *      The y location that matches the given ratio.
         */
        private function currentRatioToLocation(ratio:Number):Number
        {
            return -ratio * m_possibleScrollLocations.height + m_possibleScrollLocations.bottom;
        }
        
        private function onClickNextPage():void
        {
            this.showPageAtIndex(m_currentPageIndex + 1);
        }
        
        private function onClickPrevPage():void
        {
            this.showPageAtIndex(m_currentPageIndex - 1);
        }
        
        /**
         * Default callback behavior of whether to show the buttons to go to previous or next page.
         * Always show a button if there is a page to go to in that direction.
         */
        private function defaultOnGoToPageCallback(pageIndex:int):void
        {
            m_prevPageButton.visible = (pageIndex > 0);
            m_nextPageButton.visible = (pageIndex < m_textPages.length - 1 && m_textPages.length > 1);
        }
        
        private function _addComponentsForDocumentView(view:DocumentView):void
        {
            // For each text page view, find every part that is tagged with an id and add a
            // re-adjust the render component view since we just created a brand new one.
            var entityId:String = view.node.id;
            if (entityId != null)
            {
                // Need to make sure the render component is created for this entity as well
                // as each part must have a view associated with it.
                var renderComponent:RenderableComponent = m_componentManager.getComponentFromEntityIdAndType(entityId, RenderableComponent.TYPE_ID) as RenderableComponent;
                if (renderComponent == null)
                {
                    renderComponent = new RenderableComponent(entityId);
                    m_componentManager.addComponentToEntity(renderComponent);
                }
                renderComponent.view = view;
                
                // Automatically add the mouse component
                var mouseComponent:MouseInteractableComponent = m_componentManager.getComponentFromEntityIdAndType(entityId, MouseInteractableComponent.TYPE_ID) as MouseInteractableComponent;
                if (mouseComponent == null)
                {
                    mouseComponent = new MouseInteractableComponent(entityId);
                    m_componentManager.addComponentToEntity(mouseComponent);
                }
                m_componentManager.addComponentToEntity(mouseComponent);
            }
            
            var i:int;
            var childViews:Vector.<DocumentView> = view.childViews;
            for (i = 0; i < childViews.length; i++)
            {
                _addComponentsForDocumentView(childViews[i]);
            }
        }
    }
}