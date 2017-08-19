
package wordproblem.engine.widget;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;

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

 // TODO: uncomment all scrollbar references after scrollbar is redesigned
class TextAreaWidget extends Sprite implements IBaseWidget
{
    public var componentManager(get, never) : ComponentManager;

    /**
     * Keep track of dynamic data properties of objects within the text area
     * 
     * Each portion of the textual content that has been identified can act as
     * an entity. This allows us to bind things like helper arrows or expressions
     * to certain portions of the text.
     */
    private var m_componentManager : ComponentManager;
    
    /**
     * Used to keep track of the dimension of the mask to apply on this object
     */
    private var m_totalWidth : Float;
    private var m_totalHeight : Float;
    
    /**
     * Dimension and location information about the viewable/interactable window
     */
    private var m_viewPort : Rectangle;
    
    /** The middle y value of the viewport is used for scroll limit calculations */
    private var m_viewPortMiddleY : Float;
    
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
    private var m_backgroundImageStack : Array<Bitmap>;
    
    /**
     * This layer contains the pages of text but not the background.
     * The scroll layer is the object that will get shifted up and down as the user
     * scroll through the contents of a page.
     * 
     * If the scroll container is positioned at y=0, it is exactly at the top border of
     * the registration point of this widget.
     */
    private var m_scrollContainerLayer : Sprite;
    
    /**
     * Used to display any blurring affect ontop of the text content
     */
    private var m_foregroundLayer : Sprite;
    
    /**
     * The number of pixels left to scroll on any given frame. The reason we have this is that
     * is that we may want to have a delayed smooth scroll.
     * 
     * For example we want to scroll to a particular card image in a level. We want to gradually move
     * to that view.
     */
    private var m_scrollAmount : Int;
    
    /**
     * Flag to determine whether or not each page should be autocentered within the viewport.
     * If false the page will always start at the very top of the viewport.
     */
    private var m_autoCenterPages : Bool;
    
    /**
     * Set whether the user can manually scroll the text area up and down.
     * This flag does not affect the ability of the application to scroll though.
     */
    private var m_allowUserScroll : Bool;
    
    /**
     * Keep track of all the text pages
     */
    private var m_textPages : Array<DocumentView>;
    
    /**
     * We assume that there is one 'page' visible on the screen at any one time
     */
    private var m_currentPageIndex : Int;
    
    private var m_nextPageButton : LabelButton;
    private var m_prevPageButton : LabelButton;
    private var m_prevNextButtonBounds : Rectangle;
    
    /**
     * The texture to use for the scrolling page background
     */
    private var m_pageBitmapData : BitmapData;
    
    /**
     * Keep track of whether this widget should be display information
     * pertinent to the modeling phase or to the solving phase.
     */
    private var m_isActive : Bool;
    
    /**
     * The ui component used by the player to manually scroll up and down.
     */
    //private var m_scrollbar : IScrollBar;
    
    /**
     * Unless the background is tileable, we should not allow the background to scroll.
     */
    private var m_backgroundScroll : Bool;
    private var m_backgroundRepeat : Bool;
    
    /**
     * Function that gets called when the text area widget goes to a new page
     */
    private var m_onGoToPageCallback : Function;
    
    public function new(assetManager : AssetManager,
            pageBitmapData : BitmapData,
            backgroundScroll : String,
            backgroundRepeat : String,
            autoCenterPages : Bool,
            allowScroll : Bool)
    {
        super();
        m_scrollContainerLayer = new Sprite();
        m_foregroundLayer = new Sprite();
        m_pageBitmapData = pageBitmapData;
        //m_scrollbar = WidgetUtil.createScrollbar(assetManager);
        //m_scrollbar.addEventListener(Event.CHANGE, onScrollbarChange);
        
        m_isActive = true;
        
        m_backgroundScroll = (backgroundScroll == "scroll");
        m_backgroundRepeat = (backgroundRepeat == "repeat");
        
        var arrowTexture : BitmapData = assetManager.getBitmapData("arrow_short");
        var scaleFactor : Float = 1.5;
        var leftUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor);
        var leftOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor, 0xCCCCCC);
        
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
        m_prevPageButton.addEventListener(MouseEvent.CLICK, onClickPrevPage);
        
        var rightUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xFFFFFF);
        var rightOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xCCCCCC);
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
        m_nextPageButton.addEventListener(MouseEvent.CLICK, onClickNextPage);
        
        m_prevNextButtonBounds = new Rectangle(0, 0, arrowTexture.width * scaleFactor, arrowTexture.height * scaleFactor);
        
        m_allowUserScroll = allowScroll;
        m_autoCenterPages = autoCenterPages;
        m_onGoToPageCallback = defaultOnGoToPageCallback;
        m_textPages = new Array<DocumentView>();
        
        // Prepare the text area to be able to add dynamic properties
        m_componentManager = new ComponentManager();
    }
    
    public function dispose() : Void
    {
        m_componentManager.clear();
        
        m_isActive = false;
        
        // TODO: Proper cleanup of all the assets
        for (textPage in m_textPages)
        {
			if (textPage.parent != null) textPage.parent.removeChild(textPage);
			textPage = null;
        }
		this.removeChildren(0, -1);
    }
    
    public function getDocumentIdToExpressionMap() : Dynamic
    {
        var expressionComponents : Array<Component> = this.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var i : Int = 0;
        var documentIdToExpressionMap : Dynamic = { };
        for (i in 0...expressionComponents.length){
            var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
			Reflect.setField(documentIdToExpressionMap, expressionComponent.entityId, expressionComponent.expressionString);
        }
        
        return documentIdToExpressionMap;
    }
    
    private function get_componentManager() : ComponentManager
    {
        return m_componentManager;
    }
    
    public function getViewport() : Rectangle
    {
        return m_viewPort;
    }
    
    public function setDimensions(width : Float,
            height : Float,
            viewPortWidth : Float,
            viewPortHeight : Float,
            viewPortX : Float,
            viewPortY : Float) : Void
    {
        m_totalWidth = width;
        m_totalHeight = height;
        m_viewPort = new Rectangle(viewPortX, viewPortY, viewPortWidth, viewPortHeight);
        m_viewPortMiddleY = viewPortY + viewPortHeight / 2;
        
        // Partially cover up text at the top and bottom edges of the view port
        m_foregroundLayer.removeChildren();
        
        // Position the scrollbar off to the furthest right limit
        var scrollWidth : Float = 22;
        //m_scrollbar.x = viewPortWidth - scrollWidth + viewPortX;
        //m_scrollbar.y = viewPortY;
        //m_scrollbar.height = viewPortHeight;
        
        // Position the prev and next page buttons to the left and right edges of the viewport respectively
        // Note that height and width of buttons are not set until after they have been added to the stage
        m_prevPageButton.x = m_viewPort.left;
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
    public function setOnGoToPageCallback(callback : Function) : Void
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
    public function setIsActive(isActive : Bool) : Void
    {
        m_isActive = isActive;
    }
    
    public function getIsActive() : Bool
    {
        return m_isActive;
    }
    
    public function getNextPageButton() : DisplayObject
    {
        return m_nextPageButton;
    }
    
    public function getPrevPageButton() : DisplayObject
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
    public function setScrollLayerY(yValue : Float) : Void
    {
        m_scrollContainerLayer.y = yValue;
    }
    
    /**
     * Get back all active root document views
     * 
     * @return
     *      List of all root views for each page of displayable text content
     */
    public function getPageViews() : Array<DocumentView>
    {
        return m_textPages;
    }
    
    /**
     *
     * @return
     *      A value between zero and the maximum number of pages input for the level
     */
    public function getCurrentPageIndex() : Int
    {
        return m_currentPageIndex;
    }
    
    /**
     * This is like an init function to let the widget know it is ok to start showing the pages
     * 
     * A call will still need to be made to showPageAtIndex
     */
    public function renderText() : Void
    {
        // Dispose of previous contents
        super.removeChildren();
        
        m_backgroundImageStack = new Array<Bitmap>();
        
        if (m_pageBitmapData != null) 
        {
            var pageTextureHeight : Float = m_pageBitmapData.height;
            
            // If we repeat we initially create as many background texture display block as needed,
            // otherwise we just create one
            var numTexturesNeeded : Int = Std.int(((m_backgroundRepeat)) ? Math.ceil(m_viewPort.height / pageTextureHeight) + 1 : 1);
            var i : Int = 0;
            for (i in 0...numTexturesNeeded){
                var backgroundImage : Bitmap = new Bitmap(m_pageBitmapData);
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
        this.scrollRect = new Rectangle(0, 0, m_totalWidth, m_totalHeight);
        
        if (m_textPages.length > 0) 
        {
            showPageAtIndex(0);
        } 
		
		// Signal that the text area has finished redrawing a set of pages  
        this.dispatchEvent(new Event(GameEvent.TEXT_AREA_REDRAWN));
    }
    
    public function showPageAtIndex(pageIndex : Int) : Void
    {
        var numPages : Int = m_textPages.length;
        if (pageIndex >= 0 && pageIndex < numPages) 
        {
            // Clear all previous contents
            m_scrollContainerLayer.removeChildren();
            
            var textPageView : DocumentView = m_textPages[pageIndex];
            
            // Force a visit to so initial properties like text-decoration and visibility are
            // applied immediately on a page change. This is to fix a bug in tutorial levels where
            // after replacing parts of the text and redrawing it, it takes one frame for settings
            // to be applied. Incorrect view flashes briefly at this time.
            textPageView.visit();
            
            var pageHeight : Float = textPageView.totalHeight;
            m_scrollContainerLayer.addChild(textPageView);
            
            m_currentPageIndex = pageIndex;
            
            // Only show buttons if there are in fact pages either before or after this one
            m_onGoToPageCallback(pageIndex);
            
            // If scroll not enabled, center the contents and hide the scrollbar
            // Otherwise position the contents to give just enough padding to the text area
            if (m_autoCenterPages) 
            {
                var pageNeedsToScroll : Bool = pageHeight > m_viewPort.height;
                if (!pageNeedsToScroll) 
                {
                    m_scrollContainerLayer.y = m_viewPortMiddleY - pageHeight * 0.5;
                }
                else 
                {
                    m_scrollContainerLayer.y = m_viewPortMiddleY * 0.5;
                }
            }
            else 
            {
                m_scrollContainerLayer.y = m_viewPort.top;
            }  // The bottom most allowable scroll needs to take into account the view port  
            
            
            
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
    public function getDocumentViewsAtPageIndexById(viewId : String,
            outDocumentViews : Array<DocumentView> = null,
            pageIndex : Int = -1) : Array<DocumentView>
    {
        var idSelector : String = "#" + viewId;
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
    public function getDocumentViewsByClass(className : String,
            outDocumentViews : Array<DocumentView> = null,
            pageIndex : Int = -1) : Array<DocumentView>
    {
        var classSelector : String = "." + className;
        return getViewsMatchingSelector(classSelector, outDocumentViews, pageIndex);
    }
    
    /**
     * Get all views in a page matching an element
     */
    public function getDocumentViewsByElement(elementName : String,
            outDocumentViews : Array<DocumentView> = null,
            pageIndex : Int = -1) : Array<DocumentView>
    {
        return getViewsMatchingSelector(elementName, outDocumentViews, pageIndex);
    }
    
    private function getViewsMatchingSelector(selectorName : String,
            outDocumentViews : Array<DocumentView> = null,
            pageIndex : Int = -1) : Array<DocumentView>
    {
        if (outDocumentViews == null) 
        {
            outDocumentViews = new Array<DocumentView>();
        }
        
        if (pageIndex < 0 || pageIndex >= m_textPages.length) 
        {
            pageIndex = m_currentPageIndex;
        }
        
        var currentPage : DocumentView = m_textPages[pageIndex];
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
    public function getTextContentById(viewId : String) : String
    {
        var result : String = "";
        var targetViews : Array<DocumentView> = this.getDocumentViewsAtPageIndexById(viewId);
        if (targetViews.length > 0) 
        {
            var targetView : DocumentView = targetViews[0];
            var node : DocumentNode = targetView.node;
            var textNodes : Array<TextNode> = new Array<TextNode>();
			// Need to recursively gather all the text nodes that are contained
            // within the view.
            function getTextNodes(node : DocumentNode, outTextNodes : Array<TextNode>) : Void
            {
                if (Std.is(node, TextNode)) 
                {
                    outTextNodes.push(try cast(node, TextNode) catch (e:Dynamic) null);
                }
                else 
                {
                    var children : Array<DocumentNode> = node.children;
                    for (i in 0...children.length){
                        getTextNodes(children[i], outTextNodes);
                    }
                }
            };
			
            getTextNodes(node, textNodes);
            
            if (textNodes.length >= 0) 
            {
                result += textNodes[0].content;
                for (i in 1...textNodes.length){
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
    public function hitTestDocumentView(globalPoint : Point, ignoreNonSelectable : Bool = true) : DocumentView
    {
        var currentPage : DocumentView = m_textPages[m_currentPageIndex];
        var hitView : DocumentView = currentPage.customHitTestPoint(globalPoint, ignoreNonSelectable);
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
    public function getViewIsInContainer(view : DocumentView,
            containerId : String) : Bool
    {
        var isInContainer : Bool = false;
        
        // create a chained list of view from child to parent representing all possible containers
        // the clicked view could be part of
        var possibleContainerViews : Array<DocumentView> = new Array<DocumentView>();
        var currentView : DocumentView = view;
        while (currentView != null)
        {
            possibleContainerViews.push(currentView);
            currentView = currentView.parentView;
        }
        
        for (j in 0...possibleContainerViews.length){
            var containerView : DocumentView = possibleContainerViews[j];
            var containerNodeId : String = containerView.node.id;
            if (containerNodeId == containerId) 
            {
                isInContainer = true;
                break;
            }
        }
        
        return isInContainer;
    }
    
    private var mousePoint : Point = new Point();
    private var scrollContainerBuffer : Rectangle = new Rectangle();
    public function update(time : Time, mouseState : MouseState) : Void
    {
        if (!m_isActive) 
        {
            return;
        }  // It is only on the update loop can we correctly determine the correct  
        
        
        
        scrollContainerBuffer = m_scrollContainerLayer.getBounds(this);
        var heightOfVisibleTextContent : Float = scrollContainerBuffer.height;
        
        // Set a new bottom scroll limit
        setBottomScrollLimit();
        
        // Add scrollbar floating above all the contents.
        // Since it is a feathers component, objects above it will automatically block mouse events
        var pageNeedsToScroll : Bool = heightOfVisibleTextContent > m_viewPort.height;
        //if (m_allowUserScroll && pageNeedsToScroll && m_scrollbar.parent == null) 
        //{
            //addChild(try cast(m_scrollbar, DisplayObject) catch(e:Dynamic) null);
            //
            //m_scrollbar.value = this.currentLocationToRatio(m_scrollContainerLayer.y);
        //}
        //// Iterate through the document views and apply updates to the backing data
        //else if (!pageNeedsToScroll && m_scrollbar.parent != null) 
        //{
            //if (m_scrollbar.parent != null) m_scrollbar.parent.removeChild(m_scrollbar);
        //}
        
        
        
        var numPages : Int = m_textPages.length;
        var i : Int = 0;
        var textPage : DocumentView = null;
        for (i in 0...numPages){
            textPage = m_textPages[i];
            textPage.visit();
        }
        
        var mouseWheelDelta : Int = mouseState.mouseWheelDeltaThisFrame;
        if (mouseWheelDelta != 0 && m_allowUserScroll) 
        {
            // Adding positive values scrolls up
            // Adding negative values scrolls down
            var scrollDelta = mouseWheelDelta * 20;
            //m_scrollbar.value = this.currentLocationToRatio(scrollDelta + m_scrollContainerLayer.y);
        }
        else if (m_scrollAmount != 0) 
        {
            // This should funnel through a call to change the scrollbar value
            // Figure out the new location, convert it to a ratio, and allow the scrollbar change callback to alter
            // the actual position
            var scrollDelta : Float = 20;
            var negativeModifier : Int = ((m_scrollAmount > 0)) ? 1 : -1;
            var scrollDelta = Math.min(scrollDelta, Math.abs(m_scrollAmount)) * negativeModifier;
            //m_scrollAmount -= scrollDelta;
            //m_scrollbar.value = this.currentLocationToRatio(scrollDelta + m_scrollContainerLayer.y);
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
    public function setScrollEnabled(value : Bool) : Void
    {
        m_allowUserScroll = value;
        
        // Hide scrollbar if it is visible
        //var scrollbarDisplay : DisplayObject = try cast(m_scrollbar, DisplayObject) catch(e:Dynamic) null;
        //if (scrollbarDisplay.parent && !value) 
        //{
            //if (scrollbarDisplay.parent != null) scrollbarDisplay.parent.removeChild(scrollbarDisplay);
        //}
    }
    
    /**
     * Scroll to a particular document id such that it is centered in the screen.
     * 
     * The scrolling for now occurs smoothly. By calling this function, we will override
     * the scroll setting for the text area.
     */
    public function scrollToDocumentNode(documentId : String) : Void
    {
        // Right now we just pick the first visible node
        var documentViews : Array<DocumentView> = this.getDocumentViewsAtPageIndexById(documentId);
        var i : Int = 0;
        var numViews : Int = documentViews.length;
        for (i in 0...numViews){
            var documentView : DocumentView = documentViews[i];
            if (documentView.node.getIsVisible()) 
            {
                // Find the scroll y position of the document view
                // Normalize to global coordinates
                var documentViewLocal : Point = new Point();
                var documentViewGlobal : Point = new Point();
                documentViewLocal.setTo(documentView.x, documentView.y);
                documentViewGlobal = documentView.parent.localToGlobal(documentViewLocal);
                
                // Find the current scroll position
                var scrollLocal : Point = new Point();
                var scrollGlobal : Point = new Point();
                scrollLocal.setTo(0, m_viewPortMiddleY);
                scrollGlobal = m_scrollContainerLayer.parent.localToGlobal(scrollLocal);
                
                // Calculate the difference between the midpoint y and and the target y
                var scrollAmount : Float = Math.floor(scrollGlobal.y - documentViewGlobal.y);
                m_scrollAmount = Std.int(scrollAmount);
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
    private function scrollByAmount(scrollDelta : Float) : Void
    {
        var yAfterScroll : Float = m_scrollContainerLayer.y + scrollDelta;
        
        if (scrollDelta != 0) 
        {
            m_scrollContainerLayer.y += scrollDelta;
            
            // We assume the visible background is composed of n-tiled textures on top of each other
            // If we shift the backgrounds up or down we will create visible gaps in we need to fill,
            // however the number of tiles to clip be enough to fill in the gaps
            if (m_backgroundScroll) 
            {
                var clipBackground : Bool = false;
                var imageHeight : Float = m_backgroundImageStack[0].height;
                var numIterations : Int = m_backgroundImageStack.length;
                var maxIndexClippedTop : Int = -1;
                var minIndexClippedBottom : Int = -1;
                var gapAtTop : Bool = false;
                var gapAtBottom : Bool = false;
                var i : Int = 0;
                for (i in 0...numIterations){
                    var image : Bitmap = m_backgroundImageStack[i];
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
                
                var clippedImage : Bitmap = null;
                var shiftAmountY : Float = 0.0;
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
                    var limit : Int = m_backgroundImageStack.length;
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
    private function positionImages(imageStack : Array<Bitmap>) : Void
    {
        if (imageStack.length > 0) 
        {
            var anchorImage : Bitmap = imageStack[0];
            var imageHeight : Float = anchorImage.height;
            var yOffset : Float = anchorImage.y + imageHeight;
            for (i in 1...imageStack.length){
                var image : Bitmap = imageStack[i];
                image.y = yOffset;
                yOffset += imageHeight;
            }
        }
    }
    
    /**
     * Need to expose this function to re-adjust bounds of the visible text content.
     * The bottom limit gives an the y value of the visible content
     */
    public function setBottomScrollLimit() : Void
    {
        var currentPage : DocumentView = m_textPages[m_currentPageIndex];
        var furthestView : DocumentView = currentPage.getFurthestDocumentView();
        scrollContainerBuffer.setTo(0, 0, 0, 0);
        if (furthestView != null && furthestView.stage != null) 
        {
            scrollContainerBuffer = furthestView.getBounds(m_scrollContainerLayer);
        }
        
        var bounds : Rectangle = scrollContainerBuffer;
        
        // The top most edge should ensure you can't go so far up all text goes out of view
        // which is why we need to add extra space from the view port
        m_possibleScrollLocations.top = (m_possibleScrollLocations.bottom - bounds.bottom) + m_viewPortMiddleY;
    }
    
    public function getAllDocumentIdsTiedToExpression() : Array<Dynamic>
    {
        var expressionComponents : Array<Component> = this.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var numComponents : Int = expressionComponents.length;
        var targetDocIds : Array<Dynamic> = [];
        var i : Int = 0;
        for (i in 0...numComponents){
            targetDocIds.push((try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null).entityId);
        }
        
        return targetDocIds;
    }
    
    /**
     * This callback is triggered whenever the user either interacts with the actual scrollbar ui
     * OR when the value property of the scrollbar is altered.
     * 
     * This means it can be triggered
     */
    private function onScrollbarChange(event : Event) : Void
    {
        //var target : IScrollBar = try cast(event.currentTarget, IScrollBar) catch(e:Dynamic) null;
        //var ratio : Float = target.value;
        //
        //// Use the ratio and the total pixel height of the content to figure out the exact location
        //// to scroll to. The delta between that location and the current one is the amount to scroll by
        //// A value of 0.0 means the content is scrolled to the top as far as possible, while a value of
        //// 1.0 means the content is scrolled to the bottom as far as possible.
        //var scrollToYLocation : Int = this.currentRatioToLocation(ratio);
        //this.scrollByAmount(scrollToYLocation - m_scrollContainerLayer.y);
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
    private var m_possibleScrollLocations : Rectangle = new Rectangle();
    
    /**
     * 
     * @return
     *      A value between 0.0 and 1.0 to indicate the position the scroll bar should be set to
     */
    private function currentLocationToRatio(locationY : Float) : Float
    {
        // The ratio needs to be clamped from zero to one
        var ratio : Float = (locationY - m_possibleScrollLocations.bottom) / -m_possibleScrollLocations.height;
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
    private function currentRatioToLocation(ratio : Float) : Float
    {
        return -ratio * m_possibleScrollLocations.height + m_possibleScrollLocations.bottom;
    }
    
    private function onClickNextPage(params : Dynamic) : Void
    {
        this.showPageAtIndex(m_currentPageIndex + 1);
    }
    
    private function onClickPrevPage(params : Dynamic) : Void
    {
        this.showPageAtIndex(m_currentPageIndex - 1);
    }
    
    /**
     * Default callback behavior of whether to show the buttons to go to previous or next page.
     * Always show a button if there is a page to go to in that direction.
     */
    private function defaultOnGoToPageCallback(pageIndex : Int) : Void
    {
        m_prevPageButton.visible = (pageIndex > 0);
        m_nextPageButton.visible = (pageIndex < m_textPages.length - 1 && m_textPages.length > 1);
    }
    
    private function _addComponentsForDocumentView(view : DocumentView) : Void
    {
        // For each text page view, find every part that is tagged with an id and add a
        // re-adjust the render component view since we just created a brand new one.
        var entityId : String = view.node.id;
        if (entityId != null) 
        {
            // Need to make sure the render component is created for this entity as well
            // as each part must have a view associated with it.
            var renderComponent : RenderableComponent = try cast(m_componentManager.getComponentFromEntityIdAndType(entityId, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent == null) 
            {
                renderComponent = new RenderableComponent(entityId);
                m_componentManager.addComponentToEntity(renderComponent);
            }
            renderComponent.view = view;
            
            // Automatically add the mouse component
            var mouseComponent : MouseInteractableComponent = try cast(m_componentManager.getComponentFromEntityIdAndType(entityId, MouseInteractableComponent.TYPE_ID), MouseInteractableComponent) catch(e:Dynamic) null;
            if (mouseComponent == null) 
            {
                mouseComponent = new MouseInteractableComponent(entityId);
                m_componentManager.addComponentToEntity(mouseComponent);
            }
            m_componentManager.addComponentToEntity(mouseComponent);
        }
        
        var i : Int = 0;
        var childViews : Array<DocumentView> = view.childViews;
        for (i in 0...childViews.length){
            _addComponentsForDocumentView(childViews[i]);
        }
    }
}
