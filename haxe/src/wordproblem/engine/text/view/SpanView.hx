package wordproblem.engine.text.view;


import flash.geom.Point;

import wordproblem.engine.text.model.SpanNode;

/**
 * In our context spans can only be contained within a paragraph.
 * 
 * You can however nest spans inside each other, although normally they just wrap
 * around text and images.
 */
class SpanView extends DocumentView
{
    public function new(node : SpanNode)
    {
        super(node);
    }
    
    /**
     * HACK: If the span is set to not selectable, no way for one of its children to be selectable
     */
    override public function customHitTestPoint(globalPoint : Point, ignoreNonSelectable : Bool = true) : DocumentView
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
                
                targetChildView = childView.customHitTestPoint(globalPoint, ignoreNonSelectable);
                
                if (targetChildView != null) 
                {
                    break;
                }
                i--;
            }
        }
        return targetChildView;
    }
}
