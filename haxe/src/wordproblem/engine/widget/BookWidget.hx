package wordproblem.engine.widget;


import flash.utils.Dictionary;

import dragonbox.common.dispose.IDisposable;

import starling.display.Sprite;

/**
 * The widget attempts to treat multiple screens like the pages in a book.
 * Following through with this book analogy, there is always a left and right visible screen that
 * can be flipped through.
 * 
 * For now this class also handles the layout and possible animations for the pages. We take the x registration
 * point to be the 'spine' of the book and y registration is the top of the book.
 * 
 * One important config setting is whether one or two pages are visible at the start. The case of one would
 * be like having a front cover, the left side has nothing in this case.
 */
class BookWidget extends Sprite implements IDisposable
{
    /**
     * Stack of screens on the left side. Only the very top is visible.
     */
    private var m_leftPageStack : Array<Sprite>;
    
    /**
     * Stack of screens on the right side. Only the very top is visible
     */
    private var m_rightPageStack : Array<Sprite>;
    
    /**
     * The book has a left and right side, keep track of zero-based index
     * of the page that is currently at the top of the right side.
     * 
     * Even values indicates the first page is like a cover, no contents on the other side
     * Odd value indices indicate the book always has a pair of pages visible at the start
     */
    private var m_currentPageIndexVisibleOnRight : Int;
    
    /**
     * Flag to indicate whether the first page should be on the left (no cover page)
     */
    private var m_firstPageOnLeft : Bool;
    
    /**
     * Map from the sprite object to it's fixed width
     */
    private var m_pageToWidthMap : Dictionary<String, Float>;
    
    public function new(firstPageOnLeft : Bool)
    {
        super();
        
        m_leftPageStack = new Array<Sprite>();
        m_rightPageStack = new Array<Sprite>();
        m_currentPageIndexVisibleOnRight = 0;
        m_pageToWidthMap = new Dictionary();
        
        m_firstPageOnLeft = firstPageOnLeft;
    }
    
    /**
     * This adds a brand new page.
     * 
     * For simplicity we just expect every page to be rendered and added to the
     * list at the initialization of this book. We also assume each page has roughly
     * the same dimensions
     * 
     * @param pageWidth
     *      The width of a page is a fixed value, this is to prevent resizing issues when
     *      the book is redrawn.
     */
    public function addPage(page : Sprite, pageWidth : Float) : Void
    {
        // For first page, check if it should be on the left or right
        if (m_leftPageStack.length == 0 && m_rightPageStack.length == 0 && m_firstPageOnLeft) 
        {
            m_leftPageStack.push(page);
        }
        else 
        {
            m_rightPageStack.unshift(page);
        }
        
        Reflect.setField(m_pageToWidthMap, Std.string(page), pageWidth);
        
        this.redraw();
    }
    
    /**
     * Make it so that the page at a particular index is visible.
     * To be visible the page could be on the left or right.
     * 
     * A hack if we want everything to appear on the right is to just inject blank pages.
     * And have the left pages be of zero width
     * 
     * @param pageIndex
     *      A value of zero is the first page or the cover of the book
     */
    public function goToPageIndex(pageIndex : Int) : Void
    {
        // Shift things over by two.
        // Meaning if we are 'flipping' forward, the page below the right top becomes the left top
        // and the page below that one becomes the right top.
        
        // page index needs to be clamped between zero to the total number of pages
        pageIndex = Std.int(Math.min(pageIndex, (m_leftPageStack.length + m_rightPageStack.length) - 1));
        pageIndex = Std.int(Math.max(0, pageIndex));
        
        // Check if the page is already visible, don't do anything if it is
        if (pageIndex != m_currentPageIndexVisibleOnRight &&
            pageIndex != m_currentPageIndexVisibleOnRight - 1) 
        {
            // Otherwise figure out how much to shift
            // If first page on the right then odd page indices are visible on the left and even are on the right
            // The opposite is true if the first page is on the left
            // To simplify things we make the page index to go to even (ok since two pages are
            // always visible)
            var requestedPageIsOdd : Bool = pageIndex % 2 == 1;
            if (requestedPageIsOdd && !m_firstPageOnLeft || !requestedPageIsOdd && m_firstPageOnLeft) 
            {
                pageIndex += 1;
            }  // positive value indicates the number of times to flip right    // A negative value indicates the number of times to flip left and    // Due to the above increment, delta is always a multiple of two.  
            
            
            
            
            
            
            
            var delta : Int = Std.int((pageIndex - m_currentPageIndexVisibleOnRight) / 2);
            
            // Re-arrange the stacks such that new pages are on top and visible
            var stackToPopFrom : Array<Sprite>;
            var stackToPushTo : Array<Sprite>;
            if (delta < 0) 
            {
                stackToPopFrom = m_leftPageStack;
                stackToPushTo = m_rightPageStack;
            }
            else 
            {
                stackToPopFrom = m_rightPageStack;
                stackToPushTo = m_leftPageStack;
            }
            
            delta = Std.int(Math.abs(delta));
            while (delta > 0)
            {
                // Need to shift over two pages for every single flip
                if (stackToPopFrom.length > 0) 
                {
                    stackToPushTo.push(stackToPopFrom.pop());
                    
                    if (stackToPopFrom.length > 0) 
                    {
                        stackToPushTo.push(stackToPopFrom.pop());
                    }
                }
                
                delta--;
            }
            
            m_currentPageIndexVisibleOnRight = pageIndex;
            
            // Redraw the new visible pages
            this.redraw();
        }
    }
    
    public function getCurrentPageIndexOnRight() : Int
    {
        return m_currentPageIndexVisibleOnRight;
    }
    
    /**
     * 'Flip' one page on the right side
     */
    public function goToNextPage() : Void
    {
        goToPageIndex(m_currentPageIndexVisibleOnRight + 2);
    }
    
    /**
     * 'Flip' one page on the left side
     */
    public function goToPreviousPage() : Void
    {
        goToPageIndex(m_currentPageIndexVisibleOnRight - 2);
    }
    
    /**
     * Check whether there are more pages not visible after the current page to flip to
     */
    public function canGoToNextPage() : Bool
    {
        return m_rightPageStack.length >= 2;
    }
    
    /**
     * Check whether there are more pages not visible before the current page to flip to
     */
    public function canGoToPreviousPage() : Bool
    {
        return m_leftPageStack.length >= 2;
    }
    
    override public function dispose() : Void
    {
        while (this.numChildren > 0)
        {
            this.removeChildAt(0, true);
        }
        
        super.dispose();
    }
    
    /**
     * Draw whatever the visible pages, which are convienently at the top of the
     * left and right stacks.
     */
    private function redraw() : Void
    {
        // Need to remove previous pages
		function removePages(pageStack : Array<Sprite>) : Void
        {
            var page : Sprite;
            for (page in pageStack)
            {
                page.removeFromParent();
            }
        };
		
        removePages(m_leftPageStack);
        removePages(m_rightPageStack);
        
        if (m_leftPageStack.length > 0) 
        {
            var leftPage : Sprite = m_leftPageStack[m_leftPageStack.length - 1];
            leftPage.x = try cast(-1 * Reflect.field(m_pageToWidthMap, Std.string(leftPage)), Float) catch(e:Dynamic) null;
            addChild(leftPage);
        }
        
        if (m_rightPageStack.length > 0) 
        {
            var rightPage : Sprite = m_rightPageStack[m_rightPageStack.length - 1];
            rightPage.x = 0;
            addChild(rightPage);
        }
    }
}
