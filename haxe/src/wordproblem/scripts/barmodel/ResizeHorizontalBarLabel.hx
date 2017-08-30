package wordproblem.scripts.barmodel;


import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.events.Event;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.animation.RingPulseAnimation;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

/**
 * This script handles the resizing of both the horizontal labels on a
 * bar. For the horizontal labels resizing just means adjusting the number of segments
 * within a bar that a label spans over.
 * 
 * Each label at a minimum must span over one segment/bar. Labels edges also automatically snap
 * to the bounds of each segment/bar
 */
class ResizeHorizontalBarLabel extends BaseBarModelScript
{
    /**
     * Across multiple visits, we need to keep track of whether the player was in the middle of dragging
     * one of the edges of a label. This helps indicate that a release will force a redraw of the label.
     * 
     * This references the label in the preview as that is what will be redrawn
     */
    private var m_previewBarLabelView : BarLabelView;
    
    /**
     * We need to keep a reference to the whole bar as this has the segments that define the edges that
     * are allowable for a label to span. This does not need to reference the preview since it should
     * never change.
     */
    private var m_targetBarWholeView : BarWholeView;
    
    /**
     * Once the user presses down on the a label edge we record the anchor to check how far the
     * player has dragged it.
     * Frame of reference is the entire bar model area
     */
    private var m_localMousePressAnchorX : Float;
    
    /**
     * The pivot x is the horizontal coordinate at which one of the label edges is fixed at.
     * If dragging the left edge, the right edge x is the pivot and vis versa.
     * This number lets us know when the player has 'flipped' the label on its other side
     * 
     * Frame of reference is the entire bar model area
     */
    private var m_localLabelPivotX : Float;
    
    /**
     * Right now we are shifting around the original label, we need to keep track of the x of the
     * edge being dragged.
     * Value is relative to the containing bar whole
     */
    private var m_originalLabelViewDraggedEdgeX : Float;
    
    /**
     * If the player is dragging an edge, true if they are dragging the left part.
     * This changes value as the player crosses one edge over another
     */
    private var m_draggingLeftEdge : Bool;
    
    /**
     * A buffer that stores the hit label and whether the start or end edge is dragged
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * Pulse that plays when user presses on an edge that resizes
     */
    private var m_ringPulseAnimation : RingPulseAnimation;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_outParamsBuffer = new Array<Dynamic>();
        m_ringPulseAnimation = new RingPulseAnimation(assetManager.getBitmapData("ring"), onRingPulseAnimationComplete);
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready && m_isActive) 
        {
            // On a mouse down check that the player has hit within an area of label edge, this initiates a drag
            // The horizontal labels have priority over the verical labels
			m_outParamsBuffer = new Array<Dynamic>();
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_localMouseBuffer = m_barModelArea.globalToLocal(m_globalMouseBuffer);
            var segmentViews : Array<BarSegmentView> = null;
			var localX : Float = 0;
			
            if (m_previewBarLabelView != null) 
            {
                // Do not let the label go past the first or last segment edges
                segmentViews = m_targetBarWholeView.segmentViews;
                var leftEdgeXLimit : Float = segmentViews[0].rigidBody.boundingRectangle.left;
                var rightEdgeXLimit : Float = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle.right;
                localX = m_localMouseBuffer.x;
                if (m_localMouseBuffer.x < leftEdgeXLimit) 
                {
                    localX = leftEdgeXLimit;
                }
                else if (m_localMouseBuffer.x > rightEdgeXLimit) 
                {
                    localX = rightEdgeXLimit;
                }
            }
            
            if (m_mouseState.leftMousePressedThisFrame) 
            {
                var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
                var i : Int = 0;
                var barWholeView : BarWholeView = null;
                var numBarWholeViews : Int = barWholeViews.length;
                for (i in 0...numBarWholeViews){
                    barWholeView = barWholeViews[i];
                    var labelViews : Array<BarLabelView> = barWholeView.labelViews;
                    checkLabelEdgeHitPoint(m_localMouseBuffer, labelViews, m_outParamsBuffer);
                    if (m_outParamsBuffer.length > 0) 
                    {
                        var originalTargetBarLabelView : BarLabelView = try cast(m_outParamsBuffer[0], BarLabelView) catch(e:Dynamic) null;
                        m_draggingLeftEdge = try cast(m_outParamsBuffer[1], Bool) catch(e:Dynamic) false;
                        m_originalLabelViewDraggedEdgeX = ((m_draggingLeftEdge)) ? 
                                originalTargetBarLabelView.x : 
                                originalTargetBarLabelView.x + originalTargetBarLabelView.rigidBody.boundingRectangle.width;
                        m_targetBarWholeView = barWholeView;
                        var segmentViews = m_targetBarWholeView.segmentViews;
                        m_localLabelPivotX = ((m_draggingLeftEdge)) ? 
                                segmentViews[originalTargetBarLabelView.data.endSegmentIndex].rigidBody.boundingRectangle.right : 
                                segmentViews[originalTargetBarLabelView.data.startSegmentIndex].rigidBody.boundingRectangle.left;
                        m_localMousePressAnchorX = m_localMouseBuffer.x;
                        
                        // Create and show the preview
                        // We modify parameters of the preview and leave the regular view intact
                        // We want to manipulate the label of the preview (HACK need to show the preview before it refreshes the draw)
                        var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                        m_barModelArea.showPreview(true);
                        m_previewBarLabelView = getBarLabelViewFromId(originalTargetBarLabelView.data.id, previewView.getBarWholeViews());
                        
                        status = ScriptStatus.SUCCESS;
                        
                        // Show a small pulse on hit of the label
                        m_ringPulseAnimation.reset(m_localMouseBuffer.x, m_localMouseBuffer.y, m_barModelArea, 0x00FF00);
                        
                        m_previewBarLabelView.addButtonImagesToEdges(m_assetManager.getBitmapData("card_background_circle"));
                        m_previewBarLabelView.colorEdgeButton(m_draggingLeftEdge, 0x00FF00, 1.0);
                        m_eventDispatcher.dispatchEvent(new Event(GameEvent.START_RESIZE_HORIZONTAL_LABEL));
                        break;
                    }
                }
            }
            else if (m_mouseState.leftMouseDraggedThisFrame && m_previewBarLabelView != null && m_mouseState.mouseDeltaThisFrame.x != 0) 
            {
                status = ScriptStatus.SUCCESS;
                
                // Whether or not the player is currently dragging the left edge is determined whether the mouse crosses
                // the other edge of the label.
                if (m_localMouseBuffer.x > m_localLabelPivotX && m_draggingLeftEdge && m_previewBarLabelView.data.endSegmentIndex + 1 < segmentViews.length) 
                {
                    // Dragging the right edge now
                    // Start increases by one
                    // Reflect the x mouse anchor relative to the pivot if a dragged label went to the
                    // other side. Do the same for the original x
                    m_previewBarLabelView.data.startSegmentIndex = m_previewBarLabelView.data.endSegmentIndex + 1;
                    m_draggingLeftEdge = false;
                    m_localMousePressAnchorX = m_localLabelPivotX + (m_localLabelPivotX - m_localMousePressAnchorX);
                    
                    // Manipulating values of different frame of reference, need to transform to reference of the bar whole
                    var transformedPivotX : Float = m_localLabelPivotX - m_targetBarWholeView.x;
                    m_originalLabelViewDraggedEdgeX = transformedPivotX + (transformedPivotX - m_originalLabelViewDraggedEdgeX);
                    
                    // Change the color of the dragged button
                    m_previewBarLabelView.colorEdgeButton(m_draggingLeftEdge, 0x00FF00, 1.0);
                    m_previewBarLabelView.colorEdgeButton(!m_draggingLeftEdge, 0xFFFFFF, 0.3);
                }
                // We need to update the graphic while the drag is occuring
                else if (m_localMouseBuffer.x < m_localLabelPivotX && !m_draggingLeftEdge && m_previewBarLabelView.data.startSegmentIndex - 1 >= 0) 
                {
                    // Dragging the left edge now
                    // End decreases by one
                    m_previewBarLabelView.data.endSegmentIndex = m_previewBarLabelView.data.startSegmentIndex - 1;
                    m_previewBarLabelView.data.startSegmentIndex = m_previewBarLabelView.data.endSegmentIndex;
                    m_draggingLeftEdge = true;
                    
                    // Convert the press and drag point to appear
                    m_localMousePressAnchorX = m_localLabelPivotX - (m_localMousePressAnchorX - m_localLabelPivotX);
                    
                    var transformedPivotX = (m_localLabelPivotX - m_targetBarWholeView.x);
                    m_originalLabelViewDraggedEdgeX = (transformedPivotX) - (m_originalLabelViewDraggedEdgeX - transformedPivotX);
                    
                    // Change the color of the dragged button
                    m_previewBarLabelView.colorEdgeButton(m_draggingLeftEdge, 0x00FF00, 1.0);
                    m_previewBarLabelView.colorEdgeButton(!m_draggingLeftEdge, 0xFFFFFF, 0.3);
                }
                
                getClosestSegmentIndexToCurrentMouse(localX, m_localMouseBuffer.y, m_outParamsBuffer);
                var closestSegmentIndex : Int = m_outParamsBuffer[0];
                var distanceFromSegment : Float = try cast(m_outParamsBuffer[1], Float) catch(e:Dynamic) 0;
                
                // If do not allow for a label to span nothing
                var validSpan : Bool = (m_draggingLeftEdge && closestSegmentIndex <= m_previewBarLabelView.data.endSegmentIndex) ||
                (!m_draggingLeftEdge && closestSegmentIndex >= m_previewBarLabelView.data.startSegmentIndex);
                
                // If distance is within some threshold then the edge should snap to the segment
                // Otherwise just redraw the label so the edge goes to the mouse
                var snapThreshold : Float = 30 * m_barModelArea.scaleFactor;
                if (Math.abs(distanceFromSegment) < snapThreshold && validSpan) 
                {
                    // Figure out the new length of the label
                    // Dragging left alters the starting edge of the label
                    // Dragging right alters the ending edge of the label
                    var endSegmentIndex : Int = ((m_draggingLeftEdge)) ? m_previewBarLabelView.data.endSegmentIndex : closestSegmentIndex;
                    var startSegmentIndex : Int = ((m_draggingLeftEdge)) ? closestSegmentIndex : m_previewBarLabelView.data.startSegmentIndex;
                    
                    // Resize the preview on snapping to an edge
                    resizeHorizontalBarLabel(m_previewBarLabelView.data, startSegmentIndex, endSegmentIndex);
                    
                    // Need to resize the line AND reposition it based on which edge was clicked
                    var startSegmentBounds : Rectangle = segmentViews[startSegmentIndex].rigidBody.boundingRectangle;
                    var endSegmentBounds : Rectangle = segmentViews[endSegmentIndex].rigidBody.boundingRectangle;
                    
                    var newLabelLength : Float = endSegmentBounds.right - startSegmentBounds.left;
                    m_previewBarLabelView.resizeToLength(newLabelLength / m_barModelArea.scaleFactor);
                    
                    // The segment view position is relative to the containing whole bar (which is the same
                    // parent as the label view) so we use that coordinate rather than the bounding rectangle
                    // which is relative to the entire bar model view area.
                    m_previewBarLabelView.x = segmentViews[startSegmentIndex].x;
                }
                else 
                {
                    // If we don't snap to an edge we just redraw the label to a new length.
                    var deltaX : Float = m_localMousePressAnchorX - localX;
                    
                    // Apply the difference to the original length of the label
                    var originalTargetBarLabelView = getBarLabelViewFromId(m_previewBarLabelView.data.id, m_barModelArea.getBarWholeViews());
                    var endSegmentIndex = originalTargetBarLabelView.data.endSegmentIndex;
                    var startSegmentIndex = originalTargetBarLabelView.data.startSegmentIndex;
                    var startSegmentBounds = segmentViews[startSegmentIndex].rigidBody.boundingRectangle;
                    var endSegmentBounds = segmentViews[endSegmentIndex].rigidBody.boundingRectangle;
                    
                    var originalSpanningWidth : Float = endSegmentBounds.right - startSegmentBounds.left;
                    var newLabelLength = ((m_draggingLeftEdge)) ? originalSpanningWidth + deltaX : originalSpanningWidth - deltaX;
                    
                    // This should fail in the instance where the label is spanning just one segment that is at the very
                    // end of the bar and the drag tries to make the span even smaller.
                    // (i.e. the movement is in the direction of the last edge and there is not way to snap to that edge)
                    var allowResize : Bool = true;
                    var lastSegmentIndex : Int = m_targetBarWholeView.segmentViews.length - 1;
                    if (m_previewBarLabelView.data.startSegmentIndex == 0 && m_previewBarLabelView.data.endSegmentIndex == 0 &&
                        !m_draggingLeftEdge && newLabelLength < segmentViews[0].rigidBody.boundingRectangle.width) 
                    {
                        allowResize = false;
                    }
                    else if (m_previewBarLabelView.data.startSegmentIndex == lastSegmentIndex && m_previewBarLabelView.data.endSegmentIndex == lastSegmentIndex &&
                        m_draggingLeftEdge && newLabelLength < segmentViews[lastSegmentIndex].rigidBody.boundingRectangle.width) 
                    {
                        allowResize = false;
                    }
                    
                    if (allowResize) 
                    {
                        m_previewBarLabelView.resizeToLength(newLabelLength / m_barModelArea.scaleFactor);
                        
                        // If dragging the left, we need to shift the x of the label
                        if (m_draggingLeftEdge) 
                        {
                            // A bit strange, but the coordinates of the bar model are 'unscaled' from its reference point, however
                            // outside values like mouse movements need to take into account the bar model scale.
                            // essentially it needs to translate itself to the frame of the bar model area
                            m_previewBarLabelView.x = m_originalLabelViewDraggedEdgeX - (deltaX / m_barModelArea.scaleFactor);
                        }
                        // Otherwise it is just anchored at the start
                        else 
                        {
                            m_previewBarLabelView.x = segmentViews[m_previewBarLabelView.data.startSegmentIndex].x;
                        }
                    }
                }
            }
            else if (m_mouseState.leftMouseReleasedThisFrame && m_previewBarLabelView != null) 
            {
                status = ScriptStatus.SUCCESS;
                
                // Check if the changes applied to the preview differ from the original bar
                // Do not dispatch event if the indices do not change
                var originalTargetBarLabelView = getBarLabelViewFromId(m_previewBarLabelView.data.id, m_barModelArea.getBarWholeViews());
                if (originalTargetBarLabelView.data.startSegmentIndex != m_previewBarLabelView.data.startSegmentIndex ||
                    originalTargetBarLabelView.data.endSegmentIndex != m_previewBarLabelView.data.endSegmentIndex) 
                {
                    // On a release we need to check the final edge the drag stopped at and update the label index
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    resizeHorizontalBarLabel(originalTargetBarLabelView.data, m_previewBarLabelView.data.startSegmentIndex, m_previewBarLabelView.data.endSegmentIndex);
                    m_eventDispatcher.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                                previousSnapshot : previousModelDataSnapshot
                            }));
                    m_barModelArea.redraw();
                    
                    // Log resizing of a label on the bar segments
                    m_eventDispatcher.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.RESIZE_HORIZONTAL_LABEL, {
                                barModel : m_barModelArea.getBarModelData().serialize()
                            }));
                } 
				
				// Remove the preview  
                m_barModelArea.showPreview(false);
                m_previewBarLabelView = null;
                m_targetBarWholeView = null;
                
                m_eventDispatcher.dispatchEvent(new Event(GameEvent.END_RESIZE_HORIZONTAL_LABEL));
            }
        }
        
        return status;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        
        // Whether or not the buttons appear is actually dependent on whether the logic in here is active
        if (m_ready && m_barModelArea != null) 
        {
            m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, onBarModelRedrawn);
            toggleButtonsOnEdges(m_barModelArea, false);
            
            if (m_isActive) 
            {
                // Listen for redraw of bar model area, at this point we re-add all the buttons
                m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, onBarModelRedrawn);
                toggleButtonsOnEdges(m_barModelArea, true);
            }
        }
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        // Due to timing issue, the first redraw event is not caught,
        // so if the bar model area initially has object we need to process the initial set
        setIsActive(m_isActive);
    }
    
    /**
     * Looking at the current mouse position, get the index of the segment that the mouse is closest to.
     * If dragging the left side segments are checked on their left edge, if dragging right then segments
     * are checked on their right edge.
     * 
     * @param outParams
     *      First index is the index of the segment, second index is distance to that segment
     *      from the mouse point
     */
    private function getClosestSegmentIndexToCurrentMouse(localX : Float, localY : Float, outParams : Array<Dynamic>) : Void
    {
        // Horizontal means that we should be snapping to the edges of segment
        var segmentView : BarSegmentView = null;
        var segmentViews : Array<BarSegmentView> = m_targetBarWholeView.segmentViews;
        var closestSegmentIndex : Int = -1;
        var closestDistance : Float = 0;
        
        // We need to check for every segment edge (to allow for one edge to roll over into another)
        // Dragging the left side of the label means we are searching for a new start
        var i : Int = 0;
        var numSegments : Int = segmentViews.length;
        for (i in 0...numSegments){
            segmentView = segmentViews[i];
            var segmentBound : Rectangle = segmentView.rigidBody.boundingRectangle;
            var distance : Float = ((m_draggingLeftEdge)) ? 
            Math.abs(segmentBound.left - localX) : Math.abs(segmentBound.right - localX);
            if (closestSegmentIndex == -1 || distance < closestDistance) 
            {
                closestSegmentIndex = i;
                closestDistance = distance;
            }
        }
        
        outParams.push(closestSegmentIndex);
        outParams.push(closestDistance);
        
    }
    
    private function resizeHorizontalBarLabel(targetBarLabel : BarLabel,
            startSegmentIndex : Int,
            endSegmentIndex : Int) : Void
    {
        targetBarLabel.startSegmentIndex = startSegmentIndex;
        targetBarLabel.endSegmentIndex = endSegmentIndex;
    }
    
    /**
     * Function that checks if a point (the click point) hits a set of label views
     * The hit area incorporates a small amount of padding to the left and right of each edge and should
     * be two boxes on either edge.
     * 
     * @param point
     *      A point whole coordinates are relative to the bar model widget
     * @param labelViews
     * @param outParams
     *      First index is the label that was hit, the second index is true if the start edge was hit, false if the end edge was hit
     *      Empty if none of the views hit
     */
    private function checkLabelEdgeHitPoint(point : Point, labelViews : Array<BarLabelView>, outParams : Array<Dynamic>) : Void
    {
        var i : Int = 0;
        var labelView : BarLabelView = null;
        var numLabelViews : Int = labelViews.length;
        for (i in 0...numLabelViews){
            labelView = labelViews[i];
            
            // Ignore the labels that are placed directly on the segment
            if (labelView.data.bracketStyle != BarLabel.BRACKET_NONE &&
                (m_restrictedElementIds.length == 0 || Lambda.indexOf(m_restrictedElementIds, labelView.data.value) > -1)) 
            {
                var labelViewBounds : Rectangle = labelView.rigidBody.boundingRectangle;
                
                // We have 'hit' circles at the edges of the labels
                var radiusSquared : Float = 15 * 15;
                
                var leftCenterX : Float = labelViewBounds.left;
                var leftCenterY : Float = labelViewBounds.top + labelViewBounds.height * 0.5;
                var leftDeltaX : Float = leftCenterX - point.x;
                var leftDeltaY : Float = leftCenterY - point.y;
                
                var rightCenterX : Float = labelViewBounds.right;
                var rightCenterY : Float = leftCenterY;
                var rightDeltaX : Float = rightCenterX - point.x;
                var rightDeltaY : Float = rightCenterY - point.y;
                
                var hitEdge : Bool = false;
                var dragLeft : Bool = false;
                var leftDifferenceSquared : Float = leftDeltaX * leftDeltaX + leftDeltaY * leftDeltaY;
                var rightDifferenceSquared : Float = rightDeltaX * rightDeltaX + rightDeltaY * rightDeltaY;
                
                if (leftDifferenceSquared <= radiusSquared && rightDifferenceSquared <= radiusSquared) 
                {
                    hitEdge = true;
                    dragLeft = leftDifferenceSquared < rightDifferenceSquared;
                }
                else if (leftDifferenceSquared <= radiusSquared) 
                {
                    hitEdge = true;
                    dragLeft = true;
                }
                else if (rightDifferenceSquared <= radiusSquared) 
                {
                    hitEdge = true;
                    dragLeft = false;
                }
                
                if (hitEdge) 
                {
                    outParams.push(labelView);
                    outParams.push(dragLeft);
                    break;
                }
            }
        }
    }
    
    private function getBarLabelViewFromId(barLabelId : String, barWholeViews : Array<BarWholeView>) : BarLabelView
    {
        var matchingBarLabelView : BarLabelView = null;
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        var numBarWholeViews : Int = barWholeViews.length;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            var j : Int = 0;
            var barLabelViews : Array<BarLabelView> = barWholeView.labelViews;
            var numBarLabelViews : Int = barLabelViews.length;
            for (j in 0...numBarLabelViews){
                if (barLabelViews[j].data.id == barLabelId) 
                {
                    matchingBarLabelView = barLabelViews[j];
                    break;
                }
            }
            
            if (matchingBarLabelView != null) 
            {
                break;
            }
        }
        
        return matchingBarLabelView;
    }
    
    private function onRingPulseAnimationComplete() : Void
    {
        // Make sure animation isn't showing
		m_ringPulseAnimation.stop();
    }
    
    private function onBarModelRedrawn(event : Event) : Void
    {
        var barModelView : BarModelView = try cast(event.target, BarModelView) catch(e:Dynamic) null;
        toggleButtonsOnEdges(try cast(event.target, BarModelView) catch(e:Dynamic) null, true);
    }
    
    private function toggleButtonsOnEdges(barModelView : BarModelView,
            showButtons : Bool) : Void
    {
        // Look through all horizontal labels and add buttons to the edges
        var buttonBitmapData : BitmapData = m_assetManager.getBitmapData("card_background_circle");
        var barWholeViews : Array<BarWholeView> = barModelView.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        var i : Int = 0;
        for (i in 0...numBarWholeViews){
            var barLabelViews : Array<BarLabelView> = barWholeViews[i].labelViews;
            var numBarLabelViews : Int = barLabelViews.length;
            var j : Int = 0;
            var barLabelView : BarLabelView = null;
            var barLabelViewBounds : Rectangle = null;
            for (j in 0...numBarLabelViews){
                barLabelView = barLabelViews[j];
                if (barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE) 
                {
                    if (showButtons) 
                    {
                        // Do not add button is a restriction is placed
                        if (m_restrictedElementIds.length == 0 || Lambda.indexOf(m_restrictedElementIds, barLabelView.data.value) > -1) 
                        {
                            barLabelView.addButtonImagesToEdges(buttonBitmapData);
                        }
                    }
                    else 
                    {
                        barLabelView.removeButtonImagesFromEdges();
                    }
                }
            }
        }
    }
}
