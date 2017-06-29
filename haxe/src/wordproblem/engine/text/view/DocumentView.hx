package wordproblem.engine.text.view;


import flash.geom.Point;
import flash.geom.Rectangle;

import starling.display.DisplayObject;
import starling.display.Quad;
import starling.display.Sprite;

import wordproblem.engine.text.model.DocumentNode;

/**
 * Document views will have the same general structure as the document node
 * model that they represent.
 * 
 * (Note that this base class represents the views for paragraph, page, and div tags)
 */
class DocumentView extends Sprite
{
    public var node : DocumentNode;
    
    /**
     * The direct parent container view of this view
     */
    public var parentView : DocumentView;
    
    /**
     * List of direct children view contained within this view.
     * Is empty if this view is a leaf, should never be null.
     */
    public var childViews : Array<DocumentView>;
    
    /**
     * Keep track of background contents attached to this view
     */
    private var m_backgroundImages : Array<DisplayObject>;
    
    /**
     * Get the total height of the view including parts that have been hidden,
     * must be set manually after all layout is finished
     */
    public var totalHeight : Float;
    
    /**
     * Get the total width of the view including parts that have been hidden,
     * must be set manually after all layout is finished
     */
    public var totalWidth : Float;
    
    /**
     * Line number is used to figure out which document views are part of the 
     * same horizontal line. An example usage is to we want to apply a single
     * background covering multiple views without any break, thus we need to know
     * all views that are part of the line.
     * 
     * If zero, its not part of a line
     */
    public var lineNumber : Int;
    
    public function new(node : DocumentNode)
    {
        super();
        this.node = node;
        this.parentView = null;
        this.childViews = new Array<DocumentView>();
        
        m_backgroundImages = new Array<DisplayObject>();
        
        this.totalHeight = this.height;
        this.totalWidth = this.width;
        
        // Reset the dirty values on the node
        node.backgroundColorDirty = true;
        node.visibleDirty = true;
        node.textDecorationDirty = true;
    }
    
    /**
     * This function acts as an update loop to make sure what is displayed by the view
     * is in sync with the data present in the document node
     */
    public function visit() : Void
    {
        _visit(this);
    }
    
    private function _visit(view : DocumentView) : Void
    {
        // Since this is a recursive function, need to be wary of using this keyword
        if (view.node.visibleDirty) 
        {
            // We completely remove the object from the display list if its not
            // visible
            if (!view.node.getIsVisible() && view.parent != null) 
            {
                view.parent.removeChild(view);
            }
            
            view.node.visibleDirty = false;
        }
        
        if (view.node.backgroundColorDirty && this.stage != null) 
        {
            var backgroundColor : String = view.node.getBackgroundColor();
            if (backgroundColor == null || backgroundColor == "transparent") 
            {
                view.removeBoxesAroundSegment();
            }
            else 
            {
                view.drawBoxesAroundSegment(parseInt(view.node.getBackgroundColor(), 16));
            }
            view.node.backgroundColorDirty = false;
        }
        
        if (view.node.textDecorationDirty) 
        {
            view.node.textDecorationDirty = false;
            view.setTextDecoration(view.node.getTextDecoration());
        }
        
        var childViews : Array<DocumentView> = view.childViews;
        for (i in 0...childViews.length){
            _visit(childViews[i]);
        }
    }
    
    /**
     * When adding document views on top of each other always use this function
     * and not the add child directly
     */
    public function addChildView(view : DocumentView) : Void
    {
        view.parentView = this;
        childViews.push(view);
        this.addChild(view);
    }
    
    /**
     * A recursive hit test function attempts to find the inner most nested
     * object that was hit if this is a container.
     * 
     * The result is always either an image view,
     * a text view, or null
     * 
     * @param globalPoint
     *      Coordinates in the global reference frame of the hit point.
     * @param ignoreNonSelectable
     *      If true, the hit test will ignore all elements that are marked as not being
     *      selectable.
     * @return
     *      The lowest level document view in this display heirarchy, null if none
     *      of the children of this node hit or the hit view is not visible
     */
    public function hitTestPoint(globalPoint : Point, ignoreNonSelectable : Bool = true) : DocumentView
    {
        var targetChildView : DocumentView = null;
        
        // First make sure the node is on the display list
        // Note that even if a parent node is not selectable, one of it's children might be
        if (this.parent != null) 
        {
            // To match the display list layer of children we will iterate from
            // the top most child first (which is the end of the list
            var numChildren : Int = this.childViews.length;
            var i : Int = numChildren - 1;
            while (i >= 0){
                // Assumes no overlap between view terms
                var childView : DocumentView = this.childViews[i];
                targetChildView = childView.hitTestPoint(globalPoint, ignoreNonSelectable);
                
                if (targetChildView != null) 
                {
                    break;
                }
                i--;
            }
        }
        return targetChildView;
    }
    
    /**
     * Note that in order this function call to work, this page must be added as part of the
     * display list first.
     * 
     * @return
     *      null if the furthest view is not visible
     */
    public function getFurthestDocumentView() : DocumentView
    {
        var furthestDocumentView : DocumentView = _getFurthestDocumentView(this, this, new Rectangle(0, 0, 0, 0));
        if (!furthestDocumentView.node.getIsVisible()) 
        {
            return null;
        }
        return furthestDocumentView;
    }
    
    /**
     * Recursively get the furthest leaf view
     * 
     * @param currentView
     * @param inFurthestView
     *      The furthest view found so far
     * @param inOutFurthestRectangle
     *      This gives us the current furthest y value found across all recursive calls
     * @return
     *      The furthest view found, if the current view is not further down it just gives
     *      back inFurthestView.
     */
    private function _getFurthestDocumentView(currentView : DocumentView,
            inFurthestView : DocumentView,
            inOutFurthestRectangle : Rectangle) : DocumentView
    {
        var furthestView : DocumentView = inFurthestView;
        if (currentView != null && currentView.node.getIsVisible()) 
        {
            var childViews : Array<DocumentView> = currentView.childViews;
            var numChildViews : Int = childViews.length;
            if (numChildViews == 0) 
            {
                // For leaf views we compare whether the further has a bottom bound further
                // down than the current furthest bound
                var currentViewBound : Rectangle = ((currentView.stage)) ? currentView.getBounds(this) : new Rectangle();
                if (currentViewBound.bottom > inOutFurthestRectangle.bottom) 
                {
                    furthestView = currentView;
                    inOutFurthestRectangle.setTo(
                            currentViewBound.x,
                            currentViewBound.y,
                            currentViewBound.width,
                            currentViewBound.height
                            );
                }
            }
            else 
            {
                var i : Int;
                var childView : DocumentView;
                for (i in 0...numChildViews){
                    childView = childViews[i];
                    furthestView = _getFurthestDocumentView(childView, furthestView, inOutFurthestRectangle);
                }
            }
        }
        
        return furthestView;
    }
    
    /**
     * Get list of document view objects that match a given selector
     * 
     * @param selector
     *      css-like name for the selector to filter the search
     */
    public function getDocumentViewsBySelector(selector : String,
            documentView : DocumentView,
            outDocumentViews : Array<DocumentView>) : Void
    {
        if (documentView.node.getMatchesSelector(selector)) 
        {
            outDocumentViews.push(documentView);
        }
        
        var childViews : Array<DocumentView> = documentView.childViews;
        for (i in 0...childViews.length){
            var childView : DocumentView = childViews[i];
            getDocumentViewsBySelector(selector, childView, outDocumentViews);
        }
    }
    
    /**
     * Get all terminal views rooted at a particular view
     * 
     * @param outViews
     *      List to add the leaf views of this view
     */
    public function getDocumentViewLeaves(outViews : Array<DocumentView>) : Void
    {
        _getDocumentViewLeaves(this, outViews);
    }
    
    private function _getDocumentViewLeaves(view : DocumentView, outViews : Array<DocumentView>) : Void
    {
        if (view != null) 
        {
            var i : Int = 0;
            var childViews : Array<DocumentView> = view.childViews;
            if (childViews.length == 0) 
            {
                outViews.push(view);
            }
            else 
            {
                for (i in 0...childViews.length){
                    _getDocumentViewLeaves(childViews[i], outViews);
                }
            }
        }
    }
    
    /**
     * Subclasses should override to actually perform the drawing.
     * This abstract version just passes off responsibility to child nodes
     */
    private function setTextDecoration(textDecoration : String) : Void
    {
        var i : Int;
        var numChildViews : Int = childViews.length;
        for (i in 0...numChildViews){
            childViews[i].setTextDecoration(textDecoration);
        }
    }
    
    // TODO:
    // We may want to inject a background texture in between the content and the color
    // Currently no way inject something in between the two layers
    // Need an entire layer devoted to background, this causes layering issues though
    private function drawBoxesAroundSegment(color : Int) : Void
    {
        var stageReference : DisplayObject = this.stage;
        if (stageReference == null) 
        {
            return;
        }
        
        removeBoxesAroundSegment();
        this.getBounds(stageReference, bounds);
        
        var quad : Quad = new Quad(bounds.width, bounds.height, color);
        this.addChildAt(quad, 0);
        m_backgroundImages.push(quad);
    }
    
    private function removeBoxesAroundSegment() : Void
    {
        while (m_backgroundImages.length > 0)
        {
            var image : DisplayObject = m_backgroundImages.pop();
            if (image.parent != null) 
            {
                image.parent.removeChild(image);
            }
        }
    }
}
