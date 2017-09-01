package wordproblem.scripts.barmodel;


import openfl.geom.Point;
import openfl.geom.Rectangle;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.animation.SparklerAnimation;
import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarComparisonView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

/**
 * This script handles the resizing of the bar comparison view that is used to indicate
 * differences between bars.
 * 
 * We want the stopping point of the comparison span to always snap to an edge of another bar.
 * This way we have a very precise distance that is also independent of how the everything is drawn.
 */
class ResizeBarComparison extends BaseBarModelScript
{
    /**
     * The target bar that contains the comparison that should be resized
     */
    private var m_targetBarView : BarWholeView;
    
    /**
     * True if the user is dragging the left side of the comparison, false if the user is
     * dragging the right side.
     */
    private var m_draggingLeft : Bool;
    
    /**
     * On a press to start dragging we record the x value that acts as an anchor. As the player drags
     * we can compare distance relative to this.
     */
    private var m_localAnchorX : Float;
    
    /**
     * If the comparison did not snap to a new part, we need to restore the length of the view
     * to its original length
     */
    private var m_comparisonViewOriginalLength : Float;
    
    /**
     * Throw off sparks to give indication the user is dragging an edge.
     */
	// TODO: uncomment references to the sparkler animation once animation
	// issues are fixed
    //private var m_sparklerAnimation : SparklerAnimation;
    
    private var m_outParamsBuffer : Array<Dynamic>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_outParamsBuffer = new Array<Dynamic>();
        //m_sparklerAnimation = new SparklerAnimation(assetManager);
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_localMouseBuffer = m_barModelArea.globalToLocal(m_globalMouseBuffer);
			m_outParamsBuffer = new Array<Dynamic>();
            
            if (mouseState.leftMousePressedThisFrame) 
            {
                if (checkHitArea(m_outParamsBuffer)) 
                {
                    m_targetBarView = try cast(m_outParamsBuffer[0], BarWholeView) catch(e:Dynamic) null;
                    m_draggingLeft = try cast(m_outParamsBuffer[1], Bool) catch(e:Dynamic) false;
                    
                    var comparisonView : BarComparisonView = m_targetBarView.comparisonView;
                    m_comparisonViewOriginalLength = comparisonView.pixelLength;
                    
                    //m_sparklerAnimation.x = comparisonView.width;
                    //m_sparklerAnimation.y = comparisonView.y +comparisonView.height;  //* 0.5;  ;
                    //m_sparklerAnimation.play(comparisonView);
                    
                    // Assuming that the bar model cannot change while we are dragging,
                    // We can take a snapshot of all possible segments that the comparison edge can snap to.
                    // Search through every segment and get the one that is the closest
                    m_localAnchorX = mouseState.mousePositionThisFrame.x;
                    
                    status = ScriptStatus.SUCCESS;
                }
            }
            else if (mouseState.leftMouseDraggedThisFrame && m_targetBarView != null) 
            {
                if (checkClosestSegmentEdge(m_targetBarView.comparisonView, m_localMouseBuffer, m_outParamsBuffer)) 
                {
                    var closestBarWholeView : BarWholeView = try cast(m_outParamsBuffer[0], BarWholeView) catch(e:Dynamic) null;
                    var closestBarSegmentIndex : Int = m_outParamsBuffer[1];
                    var closestDistance : Float = Math.abs(try cast(m_outParamsBuffer[2], Float) catch(e:Dynamic) 0);
                    var barComparisonView : BarComparisonView = m_targetBarView.comparisonView;
                    var newLength : Float = 0;
                    if (closestDistance < 30 * m_barModelArea.scaleFactor) 
                    {
                        // Figure out the new length to morph the current comparison view
                        var leftEdge : Float = barComparisonView.rigidBody.boundingRectangle.left;
                        var rightEdge : Float = closestBarWholeView.segmentViews[closestBarSegmentIndex].rigidBody.boundingRectangle.right;
                        newLength = rightEdge - leftEdge;
                    }
                    else 
                    {
                        var deltaX : Float = m_localAnchorX - mouseState.mousePositionThisFrame.x;
                        newLength = barComparisonView.rigidBody.boundingRectangle.width - deltaX;
                    }
                    
                    if (newLength > 0) 
                    {
                        // Move sparkler over
                        newLength /= m_barModelArea.scaleFactor;
                        barComparisonView.resizeToLength(newLength);
                        //m_sparklerAnimation.x = newLength;
                    }
                }
                
                status = ScriptStatus.SUCCESS;
            }
            else if (mouseState.leftMouseReleasedThisFrame && m_targetBarView != null) 
            {
                if (checkClosestSegmentEdge(m_targetBarView.comparisonView, m_localMouseBuffer, m_outParamsBuffer)) 
                {
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    
                    var closestBarWholeView = try cast(m_outParamsBuffer[0], BarWholeView) catch(e:Dynamic) null;
                    var closestBarSegmentIndex = m_outParamsBuffer[1];
                    
                    // Write out the change and redraw
                    // TODO: If the data did not change no need to write it out
                    var barComparison : BarComparison = m_targetBarView.comparisonView.data;
                    if (barComparison.barWholeIdComparedTo != closestBarWholeView.data.id || barComparison.segmentIndexComparedTo != closestBarSegmentIndex) 
                    {
                        barComparison.barWholeIdComparedTo = closestBarWholeView.data.id;
                        barComparison.segmentIndexComparedTo = closestBarSegmentIndex;
                        m_gameEngine.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                                    previousSnapshot : previousModelDataSnapshot
                                }));
                        m_barModelArea.redraw();
                        
                        // Log resizing of a bar comparison
                        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.RESIZE_BAR_COMPARISON, {
                                    barModel : m_barModelArea.getBarModelData().serialize()
                                }));
                    }
                    // Make sure if no change occured, the comparison view is restored to its original width
                    else 
                    {
                        m_targetBarView.comparisonView.resizeToLength(m_comparisonViewOriginalLength);
                    }
                }
                
                //m_sparklerAnimation.stop();
                m_targetBarView = null;
                status = ScriptStatus.SUCCESS;
            }
        }
        
        return status;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready && !value) 
        {
            //m_sparklerAnimation.stop();
        }
    }
    
    /**
     * Check if the mouse is hitting a comparison view
     * 
     * @param outParams
     *      The first index is the target bar view containing the selected comparison, the second index
     *      is the true if the user dragged the left edge and false if dragged the right edge.
     */
    private function checkHitArea(outParams : Array<Dynamic>) : Bool
    {
        var doHitArea : Bool = false;
        var outBounds : Rectangle = new Rectangle();
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        var numBarWholeViews : Int = barWholeViews.length;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            if (barWholeView.comparisonView != null) 
            {
                // Check whether the user has clicked on one of the edges of the comparison line.
                var barComparisonView : BarComparisonView = barWholeView.comparisonView;
                barComparisonView.getRightBounds(outBounds);
                if (outBounds.containsPoint(m_localMouseBuffer)) 
                {
                    outParams.push(barWholeView);
                    outParams.push(false);
                    
                    doHitArea = true;
                    break;
                }
            }
        }
        
        return doHitArea;
    }
    
    /**
     * Check what segment a dragged point is closest to
     * 
     * @param targetBarComparison
     *      The bar comparison that is being resized
     * @param targetPoint
     *      The drag point to check against with the frame of reference of the modeling area
     * @param outParams
     *      The first index is the bar whole view with the closest, the second index is the index of the segment
     *      that is closest. The third is the distance to that segment.
     * @return
     *      true if there is a valid closest segment to the point
     */
    private function checkClosestSegmentEdge(targetBarComparisonView : BarComparisonView,
            targetPoint : Point,
            outParams : Array<Dynamic>) : Bool
    {
        // Which bar has the segment edge closest to the edge
        var barViewWithClosestSegment : BarWholeView = null;
        var closestSegmentIndex : Int = -1;
        
        // The absolute value of the smallest possible distance
        var smallestDelta : Float = Math.pow(2, 30);
        
        var barComparisonBounds : Rectangle = targetBarComparisonView.rigidBody.boundingRectangle;
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        var numBarWholeViews : Int = barWholeViews.length;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            
            // Ignore the bar that contains the comparison we are checking against
            if (barWholeView != m_targetBarView) 
            {
                var segmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
                var numSegmentViews : Int = segmentViews.length;
                var j : Int = 0;
                var segmentView : BarSegmentView = null;
                var segmentBounds : Rectangle = null;
                for (j in 0...numSegmentViews){
                    segmentView = segmentViews[j];
                    segmentBounds = segmentView.rigidBody.boundingRectangle;
                    
                    // Ignore segments whose right edges are to the left of bar comparison
                    if (segmentBounds.right > barComparisonBounds.left) 
                    {
                        var distanceDelta : Float = Math.abs(segmentBounds.right - targetPoint.x);
                        if (barViewWithClosestSegment == null || distanceDelta < smallestDelta) 
                        {
                            barViewWithClosestSegment = barWholeView;
                            smallestDelta = distanceDelta;
                            closestSegmentIndex = j;
                        }
                    }  // once we see a delta larger than the previous one    // Since the segment edges are ordered already we can discontinue the search earlier    // TODO:  
                }
            }
        }
        
        if (barViewWithClosestSegment != null) 
        {
            outParams.push(barViewWithClosestSegment);
            outParams.push(closestSegmentIndex);
            outParams.push(smallestDelta);
            
        }
        
        return barViewWithClosestSegment != null;
    }
}
