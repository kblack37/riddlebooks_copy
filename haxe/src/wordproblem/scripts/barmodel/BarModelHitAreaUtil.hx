package wordproblem.scripts.barmodel;


import flash.geom.Point;
import flash.geom.Rectangle;

import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarComparisonView;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;

/**
 * A bit of a hack: Common hit test functions for the bar model scripts are grouped here
 */
class BarModelHitAreaUtil
{
    public function new()
    {
    }
    
    /**
     * Determine whether the buffered release event was within the hit area
     * 
     * @param outParamsBuffer
     *      The first index is the index of the target bar, the second is the index of the segment in the bar
     * @return
     *      true if the mouse hit the designated area and successfully triggered the action
     */
    public static function checkPointInBarSegment(outParamsBuffer : Array<Dynamic>, barModelView : BarModelView, localPoint : Point) : Bool
    {
        // Just iterate through all the segment views and check if the mouse on a release hits one of them
        var pointIsInSegmentView : Bool = false;
        var targetBarSegmentIndex : Int = -1;
        var barWholeViews : Array<BarWholeView> = barModelView.getBarWholeViews();
        var i : Int;
        var barWholeView : BarWholeView;
        var numBarWholeViews : Int = barWholeViews.length;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            
            var j : Int;
            var barSegmentView : BarSegmentView;
            var barSegmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
            var numBarSegmentViews : Int = barSegmentViews.length;
            for (j in 0...numBarSegmentViews){
                barSegmentView = barSegmentViews[j];
                var barSegmentBounds : Rectangle = barSegmentView.rigidBody.boundingRectangle;
                if (barSegmentBounds.containsPoint(localPoint)) 
                {
                    var targetBarWhole : BarWhole = barWholeView.data;
                    targetBarSegmentIndex = targetBarWhole.barSegments.indexOf(barSegmentView.data);
                    outParamsBuffer.push(i);
                    outParamsBuffer.push(targetBarSegmentIndex);
                    
                    pointIsInSegmentView = true;
                    break;
                }
            }
        }
        
        return pointIsInSegmentView;
    }
    
    /**
     * For a given segment id, get back the bar label id of a label that appears on top of it IF it does exist
     * 
     * @return
     *      null if no bar label is on top already
     */
    public static function getBarLabelIdOnTopOfSegment(barModelView : BarModelView, targetBarWholeIndex : Int, targetBarSegmentIndex : Int) : String
    {
        var matchingBarLabelId : String = null;
        var barWhole : BarWhole = barModelView.getBarWholeViews()[targetBarWholeIndex].data;
        var i : Int;
        var barLabel : BarLabel;
        var numLabels : Int = barWhole.barLabels.length;
        for (i in 0...numLabels){
            barLabel = barWhole.barLabels[i];
            if (barLabel.startSegmentIndex == targetBarSegmentIndex &&
                barLabel.endSegmentIndex == targetBarSegmentIndex &&
                barLabel.bracketStyle == BarLabel.BRACKET_NONE) 
            {
                matchingBarLabelId = barLabel.id;
                break;
            }
        }
        
        return matchingBarLabelId;
    }
    
    /**
     * 
     * @param outParams
     *      First index is the display object that was selected. Second index is the index of the list that the
     *      object is contained in. Third index is the bar whole view containing the selected element (null if not part of a bar)
     * @param localPoint
     *      Coordinates relative to the bar model view's frame of reference
     * @param prioritizeLabels
     *      If true, then when it comes to overlapping elements the label view is checked first in the hit test. Success
     *      will terminate further tests.
     * @return
     *      true if some element of the bar model was selected
     */
    public static function getBarElementUnderPoint(outParams : Array<Dynamic>,
            barModelView : BarModelView,
            localPoint : Point,
            rectBuffer : Rectangle,
            prioritizeLabels : Bool) : Bool
    {
        var hitElement : Bool = false;
        var barWholeViews : Array<BarWholeView> = barModelView.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        var i : Int;
        var barWholeView : BarWholeView;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            
            if (prioritizeLabels) 
            {
                hitElement = getHitLabels(outParams, barModelView, barWholeView.labelViews, localPoint, rectBuffer);
                if (!hitElement) 
                {
                    hitElement = getHitSegments(outParams, barModelView, barWholeView.segmentViews, localPoint, rectBuffer);
                }
            }
            else 
            {
                hitElement = getHitSegments(outParams, barModelView, barWholeView.segmentViews, localPoint, rectBuffer);
                if (!hitElement) 
                {
                    hitElement = getHitLabels(outParams, barModelView, barWholeView.labelViews, localPoint, rectBuffer);
                }
            }
            
            if (!hitElement) 
            {
                var barComparisonView : BarComparisonView = barWholeView.comparisonView;
                if (barComparisonView != null) 
                {
                    // Check if hit a comparison view
                    // The rigid body does not take into account the textfield so we just take the bound of the
                    // view directly
                    barComparisonView.getBounds(barModelView, rectBuffer);
                    if (rectBuffer.containsPoint(localPoint)) 
                    {
                        outParams.push(barComparisonView);
                        outParams.push(0);
                        
                        hitElement = true;
                    }
                }
            }
            
            if (hitElement) 
            {
                outParams.push(barWholeView);
                break;
            }
        }  // If did not hit any part of a bar, check if hit vertical labels  
        
        
        
        if (!hitElement) 
        {
            if (getHitLabels(outParams, barModelView, barModelView.getVerticalBarLabelViews(), localPoint, rectBuffer)) 
            {
                outParams.push(null);
                hitElement = true;
            }
        }
        
        return hitElement;
    }
    
    public static function getHitSegments(outParams : Array<Dynamic>,
            barModelArea : BarModelView,
            segmentViews : Array<BarSegmentView>,
            localPoint : Point,
            rectBuffer : Rectangle) : Bool
    {
        var hitElement : Bool = false;
        var numSegmentViews : Int = segmentViews.length;
        var j : Int;
        var segmentView : BarSegmentView;
        for (j in 0...numSegmentViews){
            segmentView = segmentViews[j];
            if (segmentView.rigidBody.boundingRectangle.containsPoint(localPoint)) 
            {
                outParams.push(segmentView);
                outParams.push(j);
                
                hitElement = true;
                break;
            }
        }
        
        return hitElement;
    }
    
    public static function getHitLabels(outParams : Array<Dynamic>,
            barModelArea : BarModelView,
            barLabelViews : Array<BarLabelView>,
            localPoint : Point,
            rectBuffer : Rectangle) : Bool
    {
        var numBarLabelViews : Int = barLabelViews.length;
        var barLabelView : BarLabelView;
        var j : Int;
        for (j in 0...numBarLabelViews){
            barLabelView = barLabelViews[j];
            if (barLabelView.rigidBody.boundingRectangle.containsPoint(localPoint)) 
            {
                outParams.push(barLabelView);
                outParams.push(j);
                
                break;
            }
            else if (barLabelView.getDescriptionDisplay().stage != null) 
            {
                barLabelView.getDescriptionDisplay().getBounds(barModelArea, rectBuffer);
                if (rectBuffer.containsPoint(localPoint)) 
                {
                    outParams.push(barLabelView);
                    outParams.push(j);
                    
                    break;
                }
            }
        }
        
        return outParams.length > 0;
    }
}
