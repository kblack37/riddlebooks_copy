package wordproblem.engine.widget;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.system.RectanglePool;

import starling.animation.Tween;
import starling.display.DisplayObject;
import starling.display.Sprite;

/**
 * One important note is that we are assuming that any added component will
 * have its registration point in the center of the object.
 * 
 * Note that by using the starling feathers layout algorithms, it is not possible to
 * specify the exact number of objects per row or column.
 * 
 * For simplicity we will just always assume things are a single row.
 */
class ScrollGridWidget extends Sprite
{
    public static inline var EVENT_LAYOUT_COMPLETE : String = "event_layout_complete";
    
    /**
     * When performing the layout we will operate on a dummy set of rectangles
     * rather than manipulating the actual object.
     * 
     * The reason is there might be many steps or passes to calculate the position
     * and we only want to set the positions when everything has been finalized
     */
    private var m_dummyBoundsPool : RectanglePool;
    
    /**
     * A temp buffer used during the layout, it stores all the bounds of the objects
     * that need to be laid out. The index of each bound should map to the index
     * of the real object list.
     * 
     * HACK: After every layout we keep this populated so we know the original position of
     * each of the elements. We combine this with an xoffset to properly determine position after
     * scrolling
     */
    private var m_dummyBoundsBuffer : Array<Rectangle>;
    
    /**
     * This is the layer that actually contains the items in the grid as children. It is
     * separate because we want to apply a mask to it.
     * 
     * This layer will always have its registration point anchored at the top-left and
     * is fixed in place for its entire lifetime. It is the objects contained in this layer
     * that are moved around.
     */
    private var m_objectLayer : Sprite;
    
    /**
     * A list of all objects that are to be displayed in the widget
     */
    private var m_objects : Array<DisplayObject>;
    
    /**
     * Visible view port bounds, objects not contained in the bounds are clipped
     */
    private var m_viewPort : Rectangle;
    
    /**
     * True if the player scrolls up/down to view overflowing items, false if the player scrolls
     * left/right
     */
    private var m_scrollVertically : Bool;
    
    /**
     * Pixel gap in between elements
     */
    private var m_gap : Float;
    
    /**
     * Is non-null if each item in this widget should have a fixed size bounding box.
     * This is to prevent object from appearing to shift too much if the graphics inside
     * of it change. For example, a card with a hidden texture that changes to it's normal
     * texture should stay in the same spot even if the texture sizes differ slightly.
     */
    private var m_fixedItemBounds : Rectangle;
    
    /**
     * Number of pixels per second any scrolls should attempt to go through
     * 
     * Used to animate smooth scrolling
     */
    private var m_scrollVelocity : Float = 400.0;
    
    /**
     * The animation object to get the objects to scroll smoothly
     */
    private var m_scrollTween : Tween;
    
    /**
     * This is the amount the user has shifted over contents from their default positions
     */
    private var m_scrollXOffset : Float;
    
    private var m_localPointBuffer : Point = new Point();
    private var m_globalPointBuffer : Point = new Point();
    private var m_objectBoundsBuffer : Rectangle = new Rectangle();
    
    /**
     * If true, each element in the grid can be assumed to have its pivot moved to the center.
     * Need to remember this during the final positioning of the items as changes if pivot cause
     * an offset when changing the object coordinates
     */
    private var m_itemPivotInCenter : Bool;
    
    /**
     * Temp background storage
     */
    private var m_backgroundImage : DisplayObject;
    
    /**
     *
     * @param tiled
     *      If true, then the layout of objects will be tiled to fit the view port bounds.
     *      If false, then the objects will be layed out in one line
     * @param gap
     *      The number of pixels between each item
     * @param scrollVertically
     *      True if the player should scroll up/down to view items
     * @param background
     * @param fixedItemBounds
     *      If non-null this value specifies that all objects in this scroller should be laid
     *      out with the assumption that they fit inside these bounds
     * @param itemPivotInCenter
     *      If true each of the items is assumed to have had its pivot point moved to the center.
     *      If false the pivot is at the normal top left
     */
    public function new(gap : Float,
            scrollVertically : Bool,
            background : DisplayObject,
            fixedItemBounds : Rectangle,
            itemPivotInCenter : Bool)
    {
        super();
        
        if (background != null) 
        {
            addChild(background);
            m_backgroundImage = background;
        }
        
        m_objects = new Array<DisplayObject>();
        m_objectLayer = new Sprite();
        addChild(m_objectLayer);
        
        m_scrollTween = new Tween(m_objectLayer, 0);
        
        m_gap = gap;
        m_scrollVertically = scrollVertically;
        m_fixedItemBounds = fixedItemBounds;
        m_itemPivotInCenter = itemPivotInCenter;
        
        m_dummyBoundsPool = new RectanglePool();
        m_dummyBoundsBuffer = new Array<Rectangle>();
        m_scrollXOffset = 0;
    }
    
    /**
     * Needs to be called before adding anything to set the visible area for this
     * widget. Not part of the constructor since layout of widgets is done as a separate
     * pass after construction.
     */
    public function setViewport(xOffset : Float, yOffset : Float, viewPortWidth : Float, viewPortHeight : Float) : Void
    {
        m_viewPort = new Rectangle(xOffset, yOffset, viewPortWidth, viewPortHeight);
        
        // Set a clipping mask for the scroll contents
        m_objectLayer.clipRect = m_viewPort;
        
        if (m_backgroundImage != null) 
        {
            m_backgroundImage.x = xOffset;
            m_backgroundImage.y = yOffset;
            m_backgroundImage.width = viewPortWidth;
            m_backgroundImage.height = viewPortHeight;
        }
    }
    
    public function getViewport() : Rectangle
    {
        return m_viewPort;
    }
    
    /**
     * Scroll the contents by some number of objects
     * 
     * @param objectToScroll
     *      Number of objects to shift over
     *      A positive value means reveal items that are further down/right
     *      A negative value means reveal items that are further up/left
     */
    public function scrollByObjectAmount(objectsToScroll : Float) : Void
    {
        if (m_objects.length > 0) 
        {
            scrollByPixelAmount(150 * objectsToScroll);
        }
    }
    
    /**
     * Scroll the contents by some number of pixels.
     * 
     * @param pixelsToScroll
     *      Number of pixels to scroll objects by
     *      A positive value means reveal items that are further down/right
     *      A negative value means reveal items that are further up/left
     */
    public function scrollByPixelAmount(pixelsToScroll : Float) : Void
    {
        // Check for scroll clamping limits
        if (m_objects.length > 0 && m_scrollVelocity > 0) 
        {
            var firstObjectStartBounds : Rectangle = m_dummyBoundsBuffer[0];
            var lastObjectStartBounds : Rectangle = m_dummyBoundsBuffer[m_dummyBoundsBuffer.length - 1];
            var viewPortMidX : Float = (m_viewPort.right - m_viewPort.left) * 0.5 + m_viewPort.x;
            
            if (m_scrollVertically) 
            {
                // For vertical scroll
                // The bottom most edge of the first object cannot pass the bottom viewport edge
                // the top most edge of the last object cannot pass the top viewport edge
                
            }
            else 
            {
                // Take all active view objects and reset their positions
                m_scrollXOffset += pixelsToScroll;
                
                // The left most edge of the first object cannot pass the mid-point of the viewport
                if (firstObjectStartBounds.left + m_scrollXOffset > viewPortMidX) 
                {
                    // Calculate delta such that the first object is at the midpoint
                    m_scrollXOffset = viewPortMidX - firstObjectStartBounds.x;
                }
                // The right most edge of the last object cannot pass the mid-point of the viewport
                // Apply offset to the original bounds to get the new position
                else if (lastObjectStartBounds.right + m_scrollXOffset < viewPortMidX) 
                {
                    // The target should be the right edge touching the midpoint
                    m_scrollXOffset = -(lastObjectStartBounds.x - (viewPortMidX - lastObjectStartBounds.width));
                }
                
                
                
                var i : Int = 0;
                var numObjects : Int = m_objects.length;
                for (i in 0...numObjects){
                    var displayObject : DisplayObject = m_objects[i];
                    displayObject.x = m_dummyBoundsBuffer[i].x + m_scrollXOffset;
                    
                    if (m_itemPivotInCenter) 
                    {
                        displayObject.x += m_dummyBoundsBuffer[i].width * 0.5;
                    }
                }
            }  // This determines whether the buttons should be enabled    // Check if it is possible to scroll anymore to the left or right  
            
            
            
            
            
            var shouldLeftBeEnabled : Bool = firstObjectStartBounds.left + m_scrollXOffset < viewPortMidX;
            var shouldRightBeEnabled : Bool = lastObjectStartBounds.right + m_scrollXOffset > viewPortMidX;
            scrollButtonsEnabled(shouldLeftBeEnabled, shouldRightBeEnabled);
        }
    }
    
    /**
     * Override this function to change behavior of how the scroll buttons should be
     * enabled or disabled when scrolling is no longer possible.
     */
    private function scrollButtonsEnabled(leftEnabled : Bool, rightEnabled : Bool) : Void
    {
    }
    
    override public function dispose() : Void
    {
        super.dispose();
    }
    
    // The grid widget is a fairly dumb class:
    // Its only responsibility is to properly layout containing objects
    // Scroll through objects
    // Dispatch events when it thinks an object may pressed, clicked, or dragged
    // (includes the mouse point when the object is in fact selected if further hit tests are needed)
    // It will do nothing to alter the state of the objects
    
    // It will attempt to layout items in the order that they were first added
    // To simplify the layout the user must specify layout restrictions
    // Fixed number of items per visible row and/or visible column
    // If scrolling up/down
    
    public function getObjects() : Array<DisplayObject>
    {
        return m_objects;
    }
    
    /**
     * Return the total pixel width of all objects. It is used to determine if buttons are needed for
     * scrolling.
     */
    public function getObjectTotalWidth() : Float
    {
        var totalWidth : Float = 0;
        if (m_objects.length > 0) 
        {
            var firstObjectBounds : Rectangle = m_dummyBoundsBuffer[0];
            var lastObjectBounds : Rectangle = m_dummyBoundsBuffer[m_dummyBoundsBuffer.length - 1];
            totalWidth = lastObjectBounds.right - firstObjectBounds.left + 2 * m_gap;
        }
        return totalWidth;
    }
    
    /**
     * Given an x and y coordinate in global space, determine if that point is directly
     * over one of the scroll list objects.
     * 
     * If an object is outside the clipping bounds it cannot be selected
     */
    public function getObjectUnderPoint(globalX : Float, globalY : Float) : DisplayObject
    {
        var objectUnderPoint : DisplayObject = null;
        
        // First check if the point is within the bounds of the view port
        // Need to convert the global to local
        m_globalPointBuffer.x = globalX;
        m_globalPointBuffer.y = globalY;
        this.globalToLocal(m_globalPointBuffer, m_localPointBuffer);
        if (m_viewPort.containsPoint(m_localPointBuffer)) 
        {
            var renderComponents : Array<DisplayObject> = this.getObjects();
            var i : Int = 0;
            var renderComponent : DisplayObject = null;
            var numObjects : Int = renderComponents.length;
            for (i in 0...numObjects){
                renderComponent = renderComponents[i];
                renderComponent.getBounds(this, m_objectBoundsBuffer);
                if (m_objectBoundsBuffer.containsPoint(m_localPointBuffer)) 
                {
                    objectUnderPoint = renderComponent;
                    break;
                }
            }
        }
        
        return objectUnderPoint;
    }
    
    public function addObject(object : DisplayObject, layoutImmediately : Bool) : Void
    {
        m_objects.push(object);
        
        if (layoutImmediately) 
        {
            this.layoutObjects();
        }
    }
    
    public function removeObject(object : DisplayObject, layoutImmediately : Bool) : Void
    {
        var indexToRemove : Int = Lambda.indexOf(m_objects, object);
        if (indexToRemove >= 0) 
        {
            object.removeFromParent();
            
            m_objects.splice(indexToRemove, 1);
            
            if (layoutImmediately) 
            {
                this.layoutObjects();
            }
        }
    }
    
    public function removeAllObjects() : Void
    {
        while (m_objects.length > 0)
        {
            var renderComponent : DisplayObject = m_objects.pop();
            renderComponent.removeFromParent();
            renderComponent.dispose();
        }
    }
    
    public function batchAddRemove(objectsToAdd : Array<DisplayObject>, objectsToRemove : Array<DisplayObject>, layoutImmediately : Bool) : Void
    {
        var i : Int = 0;
        if (objectsToAdd != null) 
        {
            for (i in 0...objectsToAdd.length){
                this.addObject(objectsToAdd[i], false);
            }
        }
        
        if (objectsToRemove != null) 
        {
            var objectToRemove : DisplayObject = null;
            for (i in 0...objectsToRemove.length){
                this.removeObject(objectsToRemove[i], false);
            }
        }
        
        if (layoutImmediately) 
        {
            this.layoutObjects();
        }
    }
    
    public function layoutObjects() : Void
    {
        // Put all bounds back
        m_dummyBoundsPool.returnRectangles(m_dummyBoundsBuffer);
        m_scrollXOffset = 0;
        
        // Check if we are treating every object as having the same bounds
        var maxWidth : Float = 0;
        var maxHeight : Float = 0;
        if (m_fixedItemBounds != null) 
        {
            maxWidth = m_fixedItemBounds.width;
            maxHeight = m_fixedItemBounds.height;
        }  // Get the bounds to use for layout  
        
        
        
        var i : Int = 0;
        var actualObject : DisplayObject = null;
        var numActualObjects : Int = m_objects.length;
		m_dummyBoundsBuffer = new Array<Rectangle>();
        for (i in 0...numActualObjects){
            actualObject = m_objects[i];
            
            // Get a rectangle and set its dimensions to either match the real object's
            // dimension or that of the fixed bounds
            var dummyBounds : Rectangle = m_dummyBoundsPool.getRectangle();
            if (m_fixedItemBounds == null) 
            {
                dummyBounds.setTo(0, 0, actualObject.width, actualObject.height);
            }
            else 
            {
                dummyBounds.setTo(0, 0, m_fixedItemBounds.width, m_fixedItemBounds.height);
            }
            m_dummyBoundsBuffer.push(dummyBounds);
        }  // line. If it spills over the width limit then we need to create a new row    // First pass, go through each bounds and just try to position them in a single  
        
        
        
        
        
        var itemsPerRow : Array<Int> = new Array<Int>();
        if (numActualObjects > 0) 
        {
            itemsPerRow.push(0);
        }
        var activeRowIndex : Int = 0;
        var xOffset : Float = m_gap + m_viewPort.x;
        var yOffset : Float = 0;
        for (i in 0...numActualObjects){
            var dummyBounds = m_dummyBoundsBuffer[i];
            dummyBounds.x = xOffset;
            
            // If the object spills over the horizontal limit, then reset to a new row
            if (dummyBounds.right > Math.pow(2, 30)) 
            {
                // Place the object as the first item in the next row.
                xOffset = m_gap;
                dummyBounds.x = 0;
                activeRowIndex++;
                itemsPerRow.push(1);
            }
            else 
            {
                // Place the object in the current row
                itemsPerRow[activeRowIndex] = itemsPerRow[activeRowIndex] + 1;
                xOffset += dummyBounds.width + m_gap;
            }
        }  // The last pass tries to just center the contents of each row  
        
        
        
        var currentItemIndex : Int = 0;
        var numRows : Int = itemsPerRow.length;
        
        // After the first pass, we assume everything is set to the correct row
        // Now we need to position the item in each row to the correct y value
        // as well as position the rows relative to each other
        for (i in 0...numRows){
            // For a row find the max height of the bounds, attempt to center all objects
            var numItemsInRow : Int = itemsPerRow[i];
            var lastItemInRowIndex : Int = currentItemIndex + numItemsInRow;
            var j : Int = 0;
            var maxHeightInRow : Float = 0;
            for (j in currentItemIndex...lastItemInRowIndex){
                var dummyBounds = m_dummyBoundsBuffer[j];
                if (dummyBounds.height > maxHeightInRow) 
                {
                    maxHeightInRow = dummyBounds.height;
                }
            }
            
            for (j in currentItemIndex...lastItemInRowIndex){
                var dummyBounds = m_dummyBoundsBuffer[j];
                dummyBounds.y = (maxHeightInRow - dummyBounds.height) * 0.5 + (m_viewPort.height - maxHeightInRow) * 0.5 + m_viewPort.y;
            }
            
            currentItemIndex += numItemsInRow;
        }  // HACK: Assuming everything in one row  
        
        
        
        var maxRowWidth : Float = 0;
        if (m_dummyBoundsBuffer.length > 0) 
        {
            maxRowWidth = m_dummyBoundsBuffer[m_dummyBoundsBuffer.length - 1].right - m_dummyBoundsBuffer[0].left + m_gap * 2;
        }  // This only applies if the total row width fits in the viewport    // Find the xOffset needed to center all the items in the view and apply them to all the objects  
        
        
        
        
        
        if (maxRowWidth < m_viewPort.width) 
        {
            currentItemIndex = 0;
            for (i in 0...numRows){
                var numItemsInRow = itemsPerRow[i];
                var firstItemInRow : Rectangle = m_dummyBoundsBuffer[currentItemIndex];
                
                var lastItemInRowIndex = currentItemIndex + numItemsInRow - 1;
                var lastItemInRow : Rectangle = m_dummyBoundsBuffer[lastItemInRowIndex];
                var totalRowWidth : Float = lastItemInRow.right - firstItemInRow.left + m_gap * 2;
                xOffset = (m_viewPort.width - totalRowWidth) * 0.5;
                
                for (j in currentItemIndex...lastItemInRowIndex + 1){
                    var dummyBounds = m_dummyBoundsBuffer[j];
                    dummyBounds.x += xOffset;
                }
                currentItemIndex += numItemsInRow;
            }
        }
        else 
        {
            // More items in row then what is visible in the viewport, we need to show
            // scroll buttons so the user can view all options
            
        }  // the dummy bounds to the pool    // Set the objects to use the determined x and y bounds and return  
        
        
        
        
        
        for (i in 0...numActualObjects){
            actualObject = m_objects[i];
            var dummyBounds = m_dummyBoundsBuffer[i];
            
            // If the object has changed its pivot then we need to re-adjust the coordinates again
            actualObject.x = dummyBounds.x;
            if (m_itemPivotInCenter) 
            {
                actualObject.x += dummyBounds.width * 0.5;
            }
            actualObject.y = dummyBounds.y;
            if (m_itemPivotInCenter) 
            {
                actualObject.y += dummyBounds.height * 0.5;
            }
            m_objectLayer.addChild(actualObject);
        }
        
        this.dispatchEventWith(ScrollGridWidget.EVENT_LAYOUT_COMPLETE);
    }
}
