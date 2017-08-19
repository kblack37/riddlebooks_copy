package wordproblem.scripts.barmodel;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.DataEvent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

//import wordproblem.engine.animation.RingPulseAnimation;

/**
 * The script adjust the length of the vertical labels, this means changing the number of whole bars the 
 * label spans over.
 */
// TODO: revisit animation when more basic display elements are working properly
class ResizeVerticalBarLabel extends BaseBarModelScript
{
    /**
     * Across multiple visits, we need to keep track of whether the player was in the middle of dragging
     * one of the edges of a label. This helps indicate that a release will force a redraw of the label.
     */
    private var m_previewBarLabelView : BarLabelView;
    
    /**
     * A buffer that stores the hit label and whether the start or end edge is dragged
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * Once the user presses down on the a label edge we record the anchor to check how far the
     * player has dragged it.
     */
    private var m_localMousePressAnchorY : Float;
    
    /**
     * The pivot y is the vertical coordinate at which one of the edges is fixed.
     * Dragging the top edge, the bottom is the pivot and vis versa
     * Frame of reference is the entire bar model area.
     */
    private var m_localLabelPivotY : Float;
    
    /**
     * This is the difference in y from the edge of the dragged label and the y when the
     * player first presses. This is used to determine the height of the label while a
     * drag is occurring.
     */
    private var m_yDeltaFromDragEdge : Float;
    
    /**
     * If the player is dragging an edge, true if they are dragging the top part.
     */
    private var m_draggingTopEdge : Bool;
    
    /**
     * Pulse that plays when user presses on an edge that resizes
     */
    //private var m_ringPulseAnimation : RingPulseAnimation;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_outParamsBuffer = new Array<Dynamic>();
        //m_ringPulseAnimation = new RingPulseAnimation(assetManager.getTexture("ring"), onRingPulseAnimationComplete);
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
			
            var barWholeViews : Array<BarWholeView> = new Array<BarWholeView>();
			var localY : Float = 0.0;
            if (m_previewBarLabelView != null) 
            {
                // Do not let the label go past the first or last bar whole edges
                barWholeViews = m_barModelArea.getBarWholeViews();
                var segmentsOfFirstBar : Array<BarSegmentView> = barWholeViews[0].segmentViews;
                var segmentsOfLastBar : Array<BarSegmentView> = barWholeViews[barWholeViews.length - 1].segmentViews;
                var topEdgeYLimit : Float = segmentsOfFirstBar[0].rigidBody.boundingRectangle.top;
                var bottomEdgeYLimit : Float = segmentsOfLastBar[0].rigidBody.boundingRectangle.bottom;
                localY = m_localMouseBuffer.y;
                if (m_localMouseBuffer.y < topEdgeYLimit) 
                {
                    localY = topEdgeYLimit;
                }
                else if (m_localMouseBuffer.y > bottomEdgeYLimit) 
                {
                    localY = bottomEdgeYLimit;
                }
            }
            
            if (m_mouseState.leftMousePressedThisFrame) 
            {
                checkLabelEdgeHitPoint(m_localMouseBuffer, m_barModelArea.getVerticalBarLabelViews(), m_outParamsBuffer);
                if (m_outParamsBuffer.length > 0) 
                {
                    var originalBarLabelView : BarLabelView = try cast(m_outParamsBuffer[0], BarLabelView) catch(e:Dynamic) null;
                    m_draggingTopEdge = try cast(m_outParamsBuffer[1], Bool) catch(e:Dynamic) false;
                    m_localMousePressAnchorY = m_localMouseBuffer.y;
                    
                    var barWholeViews = m_barModelArea.getBarWholeViews();
                    
                    var segmentViewOfStartingBar : BarSegmentView = barWholeViews[originalBarLabelView.data.startSegmentIndex].segmentViews[0];
                    var segmentViewOfEndingBar : BarSegmentView = barWholeViews[originalBarLabelView.data.endSegmentIndex].segmentViews[0];
                    m_yDeltaFromDragEdge = ((m_draggingTopEdge)) ? 
                            segmentViewOfStartingBar.rigidBody.boundingRectangle.top - m_localMouseBuffer.y : 
                            segmentViewOfEndingBar.rigidBody.boundingRectangle.bottom - m_localMouseBuffer.y;
                    m_localLabelPivotY = ((m_draggingTopEdge)) ? 
                            segmentViewOfEndingBar.rigidBody.boundingRectangle.bottom : 
                            segmentViewOfStartingBar.rigidBody.boundingRectangle.top;
                    
                    // Create and show the preview
                    // We modify parameters of the preview and leave the regular view intact
                    // We want to manipulate the label of the preview (HACK need to show the preview before it refreshes the draw)
                    var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                    m_barModelArea.showPreview(true);
                    m_previewBarLabelView = getBarLabelViewFromId(originalBarLabelView.data.id, previewView.getVerticalBarLabelViews());
                    
                    // Show a small pulse on hit of the label
                    //m_ringPulseAnimation.reset(m_localMouseBuffer.x, m_localMouseBuffer.y, m_barModelArea, 0x00FF00);
                    //Starling.current.juggler.add(m_ringPulseAnimation);
                    
                    m_previewBarLabelView.addButtonImagesToEdges(m_assetManager.getBitmapData("card_background_circle"));
                    m_previewBarLabelView.colorEdgeButton(m_draggingTopEdge, 0x00FF00, 1.0);
                    
                    status = ScriptStatus.SUCCESS;
                }
            }
            else if (m_mouseState.leftMouseDraggedThisFrame && m_previewBarLabelView != null && m_mouseState.mouseDeltaThisFrame.y != 0) 
            {
                status = ScriptStatus.SUCCESS;
                
                // Whether or not the player is dragging the top edge is determined by whether the dragged edge
                // crosses the pivot point
                // Do not swap until the mouse actually crosses the new next pivot (unlike horizontal labels, we have variable
                // sized gaps in between all the bars) otherwise there is jittering
                if (m_draggingTopEdge && m_previewBarLabelView.data.endSegmentIndex + 1 < barWholeViews.length) 
                {
                    if (m_localMouseBuffer.y > barWholeViews[m_previewBarLabelView.data.endSegmentIndex + 1].segmentViews[0].rigidBody.boundingRectangle.top) 
                    {
                        m_previewBarLabelView.data.startSegmentIndex = m_previewBarLabelView.data.endSegmentIndex + 1;
                        m_previewBarLabelView.data.endSegmentIndex = m_previewBarLabelView.data.startSegmentIndex;
                        m_draggingTopEdge = false;
                        
                        // Pivot is the top of the starting bar
                        m_localLabelPivotY = barWholeViews[m_previewBarLabelView.data.startSegmentIndex].segmentViews[0].rigidBody.boundingRectangle.top;
                    }
                }
                // We need to update the graphic while the drag is occuring
                else if (m_localMouseBuffer.y < m_localLabelPivotY && !m_draggingTopEdge && m_previewBarLabelView.data.startSegmentIndex - 1 >= 0) 
                {
                    if (m_localMouseBuffer.y < barWholeViews[m_previewBarLabelView.data.startSegmentIndex - 1].segmentViews[0].rigidBody.boundingRectangle.bottom) 
                    {
                        m_previewBarLabelView.data.endSegmentIndex = m_previewBarLabelView.data.startSegmentIndex - 1;
                        m_previewBarLabelView.data.startSegmentIndex = m_previewBarLabelView.data.endSegmentIndex;
                        m_draggingTopEdge = true;
                        
                        // Pivot is the bottom of the ending bar
                        m_localLabelPivotY = barWholeViews[m_previewBarLabelView.data.endSegmentIndex].segmentViews[0].rigidBody.boundingRectangle.bottom;
                    }
                }
                
                
                
                getClosestSegmentIndexToPoint(m_localMouseBuffer.x, localY, m_outParamsBuffer);
                var closestBarIndex : Int = m_outParamsBuffer[0];
                var distanceFromBar : Float = try cast(m_outParamsBuffer[1], Float) catch(e:Dynamic) 0;
                var distanceThreshold : Float = 20;
                
                // If do not allow for a label to span nothing
                var validSpan : Bool = (m_draggingTopEdge && closestBarIndex <= m_previewBarLabelView.data.endSegmentIndex) ||
                (!m_draggingTopEdge && closestBarIndex >= m_previewBarLabelView.data.startSegmentIndex);
                
                if (Math.abs(distanceFromBar) < distanceThreshold && validSpan) 
                {
                    // Figure out the new length of the label
                    // Dragging top alters the starting edge of the label
                    // Dragging bottom alters the ending edge of the label
                    var endBarIndex : Int = ((m_draggingTopEdge)) ? m_previewBarLabelView.data.endSegmentIndex : closestBarIndex;
                    var startBarIndex : Int = ((m_draggingTopEdge)) ? closestBarIndex : m_previewBarLabelView.data.startSegmentIndex;
                    
                    // Resize the preview on snapping to an edge
                    resizeVerticalBarLabel(m_previewBarLabelView.data, startBarIndex, endBarIndex);
                    
                    // Need to resize the line AND reposition it based on which edge was clicked
                    var endBarBounds : Rectangle = barWholeViews[endBarIndex].segmentViews[0].rigidBody.boundingRectangle;
                    var startBarBounds : Rectangle = barWholeViews[startBarIndex].segmentViews[0].rigidBody.boundingRectangle;
                    
                    // A bit strange, need to take into account the scale factor, that bar model widget will auto apply a scale to the label
                    // so it's actual length should ignore the scale (you can think of it as being applied later)
                    var newLabelLength : Float = endBarBounds.bottom - startBarBounds.top;
                    m_previewBarLabelView.resizeToLength(newLabelLength / m_barModelArea.scaleFactor);
                    m_previewBarLabelView.y = startBarBounds.top / m_barModelArea.scaleFactor;
                }
                else 
                {
                    // Depending on which edge the player is dragging, figure out the new length and position of the label.
                    // Mouse-y combined with the delta on press combine to give the position where one edge should be
                    // The other edge is defined by the pivot
                    var edgeAY : Float = m_yDeltaFromDragEdge + localY;
                    var newLabelLength = Math.abs(edgeAY - m_localLabelPivotY);
                    
                    // Do not allow bar to squish into nothing at the very top or bottom (i.e. when it cannot cross the pivot)
                    // If the ends of the label span just one bar and that bar is at the very end then the label should not get
                    // any smaller
                    var allowResize : Bool = true;
                    var lastSegmentIndex : Int = m_barModelArea.getBarWholeViews().length - 1;
                    if (m_previewBarLabelView.data.startSegmentIndex == 0 && m_previewBarLabelView.data.endSegmentIndex == 0 &&
                        !m_draggingTopEdge && newLabelLength < barWholeViews[m_previewBarLabelView.data.startSegmentIndex].segmentViews[0].rigidBody.boundingRectangle.height) 
                    {
                        allowResize = false;
                    }
                    else if (m_previewBarLabelView.data.startSegmentIndex == lastSegmentIndex && m_previewBarLabelView.data.endSegmentIndex == lastSegmentIndex &&
                        m_draggingTopEdge && newLabelLength < barWholeViews[m_previewBarLabelView.data.startSegmentIndex].segmentViews[0].rigidBody.boundingRectangle.height) 
                    {
                        allowResize = false;
                    }
                    
                    if (allowResize) 
                    {
                        var scaleIndependentLength : Float = newLabelLength / m_barModelArea.scaleFactor;
                        m_previewBarLabelView.resizeToLength(scaleIndependentLength);
                        
                        // If dragging the top, we need to shift over the y
                        if (m_draggingTopEdge) 
                        {
                            m_previewBarLabelView.y = m_localLabelPivotY - newLabelLength;
                        }
                        // Other just snap it to top edge of the starting bar the preview has taken
                        else 
                        {
                            m_previewBarLabelView.y = barWholeViews[m_previewBarLabelView.data.startSegmentIndex].segmentViews[0].rigidBody.boundingRectangle.top;
                        }
                        
                        m_previewBarLabelView.y /= m_barModelArea.scaleFactor;
                    }
                }
            }
            else if (m_mouseState.leftMouseReleasedThisFrame && m_previewBarLabelView != null) 
            {
                status = ScriptStatus.SUCCESS;
                
                var originalBarLabelView = getBarLabelViewFromId(m_previewBarLabelView.data.id, m_barModelArea.getVerticalBarLabelViews());
                
                // Don't redraw if the indices did not change
                if (originalBarLabelView.data.startSegmentIndex != m_previewBarLabelView.data.startSegmentIndex ||
                    originalBarLabelView.data.endSegmentIndex != m_previewBarLabelView.data.endSegmentIndex) 
                {
                    // On a release we need to check the final edge the drag stopped at and update the label index
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    resizeVerticalBarLabel(originalBarLabelView.data, m_previewBarLabelView.data.startSegmentIndex, m_previewBarLabelView.data.endSegmentIndex);
                    m_eventDispatcher.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                                previousSnapshot : previousModelDataSnapshot
                            }));
                    m_barModelArea.redraw();
                    
                    // Log resizing of a label across the whole bars
                    m_eventDispatcher.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.RESIZE_VERTICAL_LABEL, {
                                barModel : m_barModelArea.getBarModelData().serialize()
                            }));
                }
                
                m_barModelArea.showPreview(false);
                m_previewBarLabelView = null;
            }
        }
        
        return status;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        
        if (m_ready && m_barModelArea != null) 
        {
            m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, onBarModelRedrawn);
            toggleButtonsOnEdges(m_barModelArea, false);
            if (value) 
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
     * If dragging the top side segments are checked on their top edge, if dragging bottom then segments
     * are checked on their bottom edge.
     * 
     * @param outParams
     *      First index is the index of the segment closest to the mouse, the second index is the distance
     *      to that segment
     */
    private function getClosestSegmentIndexToPoint(localX : Float, localY : Float, outParams : Array<Dynamic>) : Void
    {
        // The edges to snap to are the top and bottoms of each individual bar
        var barWholeView : BarWholeView = null;
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var closestSegmentIndex : Int = -1;
        var closestDistance : Float = 0;
        
        var i : Int = 0;
        var numBars : Int = barWholeViews.length;
        for (i in 0...numBars){
            barWholeView = barWholeViews[i];
            
            var segmentBound : Rectangle = barWholeView.segmentViews[0].rigidBody.boundingRectangle;
            var distance : Float = ((m_draggingTopEdge)) ? 
            Math.abs(segmentBound.top - localY) : Math.abs(segmentBound.bottom - localY);
            if (closestSegmentIndex == -1 || distance < closestDistance) 
            {
                closestSegmentIndex = i;
                closestDistance = distance;
            }
        }
        
        outParams.push(closestSegmentIndex);
        outParams.push(closestDistance);
        
    }
    
    private function resizeVerticalBarLabel(targetBarLabel : BarLabel,
            startSegmentIndex : Int,
            endSegmentIndex : Int) : Void
    {
        targetBarLabel.startSegmentIndex = startSegmentIndex;
        targetBarLabel.endSegmentIndex = endSegmentIndex;
    }
    
    /**
     * Function that checks if a point (the click point) hits a set of label views
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
            var labelViewBounds : Rectangle = labelView.rigidBody.boundingRectangle;
            
            // Have two central points at the ends of the labels.
            // A hit occurs if the mouse is within some radius
            // We have 'hit' circles at the edges of the labels
            var radiusSquared : Float = 200;
            
            var topCenterY : Float = labelViewBounds.top;
            var topCenterX : Float = labelViewBounds.left + labelViewBounds.width * 0.5;
            var topDeltaY : Float = topCenterY - point.y;
            var topDeltaX : Float = topCenterX - point.x;
            
            var bottomCenterX : Float = topCenterX;
            var bottomCenterY : Float = labelViewBounds.bottom;
            var bottomDeltaX : Float = bottomCenterX - point.x;
            var bottomDeltaY : Float = bottomCenterY - point.y;
            
            // If both of these intersect, pick the one that is closer
            var dragTop : Bool = false;
            var hitEdge : Bool = false;
            var topDifferenceSquared : Float = topDeltaX * topDeltaX + topDeltaY * topDeltaY;
            var bottomDifferenceSquared : Float = bottomDeltaX * bottomDeltaX + bottomDeltaY * bottomDeltaY;
            if (topDifferenceSquared <= radiusSquared && bottomDifferenceSquared <= radiusSquared) 
            {
                hitEdge = true;
                dragTop = (topDifferenceSquared < bottomDifferenceSquared);
            }
            else if (topDifferenceSquared <= radiusSquared) 
            {
                hitEdge = true;
                dragTop = true;
            }
            else if (bottomDifferenceSquared <= radiusSquared) 
            {
                hitEdge = true;
                dragTop = false;
            }
            
            if (hitEdge) 
            {
                outParams.push(labelView);
                outParams.push(dragTop);
                break;
            }
        }
    }
    
    private function getBarLabelViewFromId(barLabelId : String, barLabelViews : Array<BarLabelView>) : BarLabelView
    {
        var matchingBarLabelView : BarLabelView = null;
        var i : Int = 0;
        var barLabelView : BarLabelView = null;
        var numBarLabelViews : Int = barLabelViews.length;
        for (i in 0...numBarLabelViews){
            barLabelView = barLabelViews[i];
            if (barLabelView.data.id == barLabelId) 
            {
                matchingBarLabelView = barLabelView;
                break;
            }
        }
        
        return matchingBarLabelView;
    }
    
    private function onRingPulseAnimationComplete() : Void
    {
        // Make sure animation isn't showing
        //Starling.current.juggler.remove(m_ringPulseAnimation);
    }
    
    private function onBarModelRedrawn(event : Event) : Void
    {
        var barModelView : BarModelView = try cast(event.target, BarModelView) catch(e:Dynamic) null;
        toggleButtonsOnEdges(try cast(event.target, BarModelView) catch(e:Dynamic) null, true);
    }
    
    private function toggleButtonsOnEdges(barModelView : BarModelView, showButtons : Bool) : Void
    {
        // Look through all horizontal labels and add buttons to the edges
        var buttonBitmapData : BitmapData = m_assetManager.getBitmapData("card_background_circle");
        var verticalBarViews : Array<BarLabelView> = barModelView.getVerticalBarLabelViews();
        var numVerticalBarViews : Int = verticalBarViews.length;
        var i : Int = 0;
        var verticalBarView : BarLabelView = null;
        for (i in 0...numVerticalBarViews){
            verticalBarView = verticalBarViews[i];
            
            if (showButtons) 
            {
                verticalBarView.addButtonImagesToEdges(buttonBitmapData);
            }
            else 
            {
                verticalBarView.removeButtonImagesFromEdges();
            }
        }
    }
}
