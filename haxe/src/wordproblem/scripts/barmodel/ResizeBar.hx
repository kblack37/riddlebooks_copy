package wordproblem.scripts.barmodel;


import flash.geom.Rectangle;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

/**
 * This script handles the resizing of a whole bar. During a resize, the proportions of each
 * segment contained within it is maintained.
 */
class ResizeBar extends BaseBarModelScript
{
    private static inline var MINIMUM_UNIT_WIDTH : Float = 10;
    
    /**
     * The target bar that should be resized
     */
    private var m_targetBarView : BarWholeView;
    
    /**
     * The edge of the segment view that was pressed.
     */
    private var m_targetSegmentView : BarSegmentView;
    
    /**
     * At the point of a press we need to keep track of the vertical position, need this to
     * calculate the difference.
     */
    private var m_anchorX : Float;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready && m_isActive) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            
            if (mouseState.leftMousePressedThisFrame) 
            {
                m_anchorX = m_globalMouseBuffer.x;
                
                // Check if the mouse is pressed near one of the edges of a segment
                var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
                var barWholeView : BarWholeView = null;
                var i : Int = 0;
                var numBarWholeViews : Int = barWholeViews.length;
                var edgeHitArea : Rectangle = new Rectangle();
                for (i in 0...numBarWholeViews){
                    barWholeView = barWholeViews[i];
                    var segmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
                    
                    // Check the left most edge of the first segment
                    if (segmentViews.length > 0) 
                    {
                        var segmentView : BarSegmentView = null;
                        var j : Int = 0;
                        var numSegmentViews : Int = segmentViews.length;
                        for (j in 0...numSegmentViews){
                            segmentView = segmentViews[j];
                            if (checkSegmentEdgeHitMouse(segmentView, edgeHitArea, false)) 
                            {
                                // Show the preview, this is what we will be resizing
                                m_targetBarView = barWholeView;
                                m_targetSegmentView = segmentView;
                                var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                                m_barModelArea.showPreview(true);
                                
                                status = ScriptStatus.SUCCESS;
                                break;
                            }
                        }
                    }
                }
            }
            else if (mouseState.leftMouseDraggedThisFrame && m_targetBarView != null) 
            {
                // Calculate the difference of the mouse from its initial drag position to the end point.
                // From this difference we need to determine how to distribute it amongst all the different segments
                var distanceDelta : Float = m_globalMouseBuffer.x - m_anchorX;
                
                // Find the proportion of the total bar that was increased or decreased and apply that
                // factor to each individual segment. We just want the right edge of the target segment
                // to resize such that it sits at the end point.
                var originalWidthUpToTarget : Float = 0;
                numSegmentViews = m_targetBarView.segmentViews.length;
                for (i in 0...numSegmentViews){
                    segmentView = m_targetBarView.segmentViews[i];
                    originalWidthUpToTarget += segmentView.rigidBody.boundingRectangle.width;
                    if (segmentView == m_targetSegmentView) 
                    {
                        break;
                    }
                }
				
				// Need to clamp to some minimum value (i.e. a segment cannot be less than some minimum width)  
                var newWidthUpToTarget : Float = Math.max(1, distanceDelta + originalWidthUpToTarget);
                var scaleFactor : Float = newWidthUpToTarget / originalWidthUpToTarget;
                var newUnitLength : Float = scaleFactor * m_barModelArea.unitLength;
                
                // Only to to refresh if the new unit length is different
                previewBarModelView = m_barModelArea.getPreviewView(false);
                if (Math.abs(newUnitLength - previewBarModelView.unitLength) > 0.01) 
                {
                    resizeBarSegments(previewBarModelView.getBarModelData(), newUnitLength);
                    previewBarModelView.layout();
                }
                
                status = ScriptStatus.SUCCESS;
            }
            else if (mouseState.leftMouseReleasedThisFrame && m_targetBarView != null) 
            {
                // Look at the preview to see what the new unit value should be
                var previewBarModelView : BarModelView = m_barModelArea.getPreviewView(false);
                
                // Only update if the change is great enough
                if (Math.abs(previewBarModelView.unitLength - m_barModelArea.unitLength) > 0.01) 
                {
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    resizeBarSegments(m_barModelArea.getBarModelData(), previewBarModelView.unitLength);
                    m_gameEngine.dispatchEvent(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
                                previousSnapshot : previousModelDataSnapshot
                            });
                }
                
                m_barModelArea.showPreview(false);
                m_barModelArea.redraw();
                m_targetBarView = null;
                m_targetSegmentView = null;
                m_anchorX = 0;
                
                // Note that we must also do this to every other related bar in order to maintain all proportions
                status = ScriptStatus.SUCCESS;
            }
        }
        
        return status;
    }
    
    private function checkSegmentEdgeHitMouse(segmentView : BarSegmentView, edgeHitArea : Rectangle, useLeft : Bool) : Bool
    {
        var containsPoint : Bool = false;
        var hitAreaPadding : Float = 10;
        var segmentViewBounds : Rectangle = segmentView.rigidBody.boundingRectangle;
        var x : Float = ((useLeft)) ? segmentViewBounds.left - hitAreaPadding : segmentViewBounds.right - hitAreaPadding;
        edgeHitArea.setTo(
                x,
                segmentViewBounds.y,
                hitAreaPadding * 2,
                segmentViewBounds.height
                );
        if (edgeHitArea.containsPoint(m_localMouseBuffer)) 
        {
            containsPoint = true;
        }
        
        return containsPoint;
    }
    
    public function resizeBarSegments(barModelData : BarModelData, newUnitLength : Float) : Void
    {
        // We are assuming that all bar segments will scale proportionally with the change
        // Clamp to a minimum width
        if (newUnitLength < MINIMUM_UNIT_WIDTH) 
        {
            newUnitLength = MINIMUM_UNIT_WIDTH;
        }
        
        m_barModelArea.unitLength = newUnitLength;
    }
}
