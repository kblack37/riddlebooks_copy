package wordproblem.scripts.barmodel;


import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.display.DisplayObject;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
//import wordproblem.engine.animation.RingPulseAnimation;
import wordproblem.engine.animation.ShatterAnimation;
import wordproblem.engine.barmodel.BarModelDataUtil;
import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

/**
 * This scripts handles the removal of a bar segment
 */
// TODO: revisit animation when more basic elements are working
class RemoveBarSegment extends BaseBarModelScript implements IRemoveBarElement
{
    /**
     * Maintain a list of the segment ids that cannot be removed in the current level.
     * Used in tutorials where we want to restrict what the player can delete.
     */
    public var segmentIdsCannotRemove : Array<String>;
    
    /**
     * A buffer that stores the bar view that the comparison should add to.
     * First index is the segment view that was hit
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * The bar segment view the player has selected
     */
    private var m_hitSegmentView : BarSegmentView;
    
    /**
     * Pulse that plays when user presses on an edge that resizes
     */
    //private var m_ringPulseAnimation : RingPulseAnimation;
    
    /**
     * Keep track of area the mouse pressed down on
     */
    private var m_hitAnchor : Point;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        this.segmentIdsCannotRemove = new Array<String>();
        
        m_outParamsBuffer = new Array<Dynamic>();
        //m_ringPulseAnimation = new RingPulseAnimation(assetManager.getTexture("ring"), onRingPulseAnimationComplete);
        m_hitAnchor = new Point();
    }
    
    public function removeElement(element : DisplayObject) : Bool
    {
        var canRemove : Bool = false;
        if (Std.is(element, BarSegmentView)) 
        {
            // Remember the index of the bar and the view
            var hitSegmentView : BarSegmentView = try cast(element, BarSegmentView) catch(e:Dynamic) null;
            var foundSegment : Bool = false;
            var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
			var i = 0;
			var j = 0;
			for (barWhole in barWholes) {
				for (barSegment in barWhole.barSegments) {
                    if (barSegment == hitSegmentView.data) 
                    {
                        foundSegment = true;
                        break;
                    }
                }
                
                if (foundSegment) 
                {
                    break;
                }
            }  
			
			// Get the segment and single label (if applicable) and play the shatter animation on it  
            hitSegmentView.alpha = 1.0;
            
            //var segmentViewBounds : Rectangle = hitSegmentView.rigidBody.boundingRectangle;
            //var renderTexture : RenderTexture = new RenderTexture(Std.int(segmentViewBounds.width), Std.int(segmentViewBounds.height), false);
            //var barLabelId : String = BarModelHitAreaUtil.getBarLabelIdOnTopOfSegment(m_barModelArea, i, j);
            //if (barLabelId != null) 
            //{
                //var labelViewToRemove : BarLabelView = m_barModelArea.getBarLabelViewById(barLabelId);
                //renderTexture.drawBundled(function(DisplayObject, Matrix, Float) : Void
                        //{
                            //renderTexture.draw(hitSegmentView, new Matrix(1, 0, 0, 1, 0, 0));
                            //renderTexture.draw(labelViewToRemove, new Matrix(1, 0, 0, 1, 0, 0));
                        //});
            //}
            //else 
            //{
                //renderTexture.draw(hitSegmentView, new Matrix(1, 0, 0, 1, 0, 0));
            //}
            
			// TODO: uncomment when animation issues are fixed
            //var shatterAnimation : ShatterAnimation = new ShatterAnimation(renderTexture, onShatterAnimationComplete, 0.7);
            //shatterAnimation.play(m_barModelArea.getForegroundLayer(), segmentViewBounds.x, segmentViewBounds.y);
            
            var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
            removeBarSegment(m_barModelArea.getBarModelData(), hitSegmentView.data.id);
            BarModelDataUtil.stretchHorizontalBrackets(m_barModelArea.getBarModelData());
            m_eventDispatcher.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                        previousSnapshot : previousModelDataSnapshot
                    }));
            m_barModelArea.redraw();
            
            // Log removal of a bar segment
            m_eventDispatcher.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.REMOVE_BAR_SEGMENT, {
                        barModel : m_barModelArea.getBarModelData().serialize()
                    }));
            
            canRemove = true;
        }
		
        return canRemove;
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready && m_isActive && !Layer.getDisplayObjectIsInInactiveLayer(m_barModelArea)) 
        {
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_localMouseBuffer = m_barModelArea.globalToLocal(m_globalMouseBuffer);
			m_outParamsBuffer = new Array<Dynamic>();
            
            if (m_mouseState.leftMousePressedThisFrame) 
            {
                if (checkHitSegment(m_outParamsBuffer)) 
                {
                    // Make the hit segment view transparent
                    m_hitSegmentView = m_barModelArea.getBarWholeViews()[m_outParamsBuffer[0]].segmentViews[m_outParamsBuffer[1]];
                    m_hitSegmentView.alpha = 0.3;
                    
                    //m_ringPulseAnimation.reset(m_localMouseBuffer.x, m_localMouseBuffer.y, m_barModelArea.getForegroundLayer(), 0xFF0000);
                    //Starling.current.juggler.add(m_ringPulseAnimation);
                    status = ScriptStatus.SUCCESS;
                    
                    m_hitAnchor.x = m_localMouseBuffer.x;
                    m_hitAnchor.y = m_localMouseBuffer.y;
                }
            }
            else if ((m_mouseState.leftMouseDraggedThisFrame || m_mouseState.leftMouseReleasedThisFrame) && m_hitSegmentView != null) 
            {
                removeElement(m_hitSegmentView);
                m_hitSegmentView = null;
                status = ScriptStatus.SUCCESS;
            }
        }
        
        return status;
    }
    
    override public function reset() : Void
    {
        super.reset();
        
        // Restore transparency to clicked piece
        if (m_hitSegmentView != null) 
        {
            m_hitSegmentView.alpha = 1.0;
        }
    }
    
    private function checkHitSegment(outParams : Array<Dynamic>) : Bool
    {
        var hitSegment : Bool = BarModelHitAreaUtil.checkPointInBarSegment(outParams, m_barModelArea, m_localMouseBuffer);
        
        // Check that the segment is not part of the list marked as unremovable
        if (hitSegment) 
        {
            var targetBarWhole : BarWhole = m_barModelArea.getBarWholeViews()[m_outParamsBuffer[0]].data;
            var hitSegmentId : String = targetBarWhole.barSegments[m_outParamsBuffer[1]].id;
            hitSegment = this.segmentIdsCannotRemove.indexOf(hitSegmentId) < 0;
        }
        
        return hitSegment;
    }
    
    /**
     * @param outParams
     *      Will contain:
     *      targetBarWholeIndex
     *      targetBarSegmentIndex
     */
    private function getBarWholeIndexFromSegmentId(outParams : Array<Dynamic>, barWholes : Array<BarWhole>, barSegmentId : String) : Void
    {
        var targetBarWholeIndex : Int = -1;
        var targetBarSegmentIndex : Int = -1;
        
        var foundSegment : Bool = false;
        var numBarWholes : Int = barWholes.length;
        var barWhole : BarWhole = null;
        var i : Int = 0;
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            var barSegments : Array<BarSegment> = barWhole.barSegments;
            var numBarSegments : Int = barSegments.length;
            var j : Int = 0;
            var barSegment : BarSegment = null;
            for (j in 0...numBarSegments){
                barSegment = barSegments[j];
                if (barSegment.id == barSegmentId) 
                {
                    foundSegment = true;
                    targetBarWholeIndex = i;
                    targetBarSegmentIndex = j;
                    outParams.push(targetBarWholeIndex);
                    outParams.push(targetBarSegmentIndex);
                    
                    break;
                }
            }
            
            if (foundSegment) 
            {
                break;
            }
        }
    }
    
    private function removeBarSegment(barModelData : BarModelData, barSegmentId : String) : Void
    {
		m_outParamsBuffer = new Array<Dynamic>();
        getBarWholeIndexFromSegmentId(m_outParamsBuffer, barModelData.barWholes, barSegmentId);
        
        var targetBarWholeIndex : Int = m_outParamsBuffer[0];
        var targetBarSegmentIndex : Int = m_outParamsBuffer[1];
        
        // Remove the target segment
        var barWhole : BarWhole = barModelData.barWholes[targetBarWholeIndex];
        barWhole.barSegments.splice(targetBarSegmentIndex, 1);
        
        // Remove any the labels attached to that segment
        readjustLabelsFromDeletedIndex(barWhole.barLabels, targetBarSegmentIndex);
        
        // Delete the entire bar if it was the last segment
        if (barWhole.barSegments.length == 0) 
        {
            var barWholeIndexToRemove : Int = barModelData.barWholes.indexOf(barWhole);
            barModelData.barWholes.splice(barWholeIndexToRemove, 1);
            
            // The deletion of a bar might cascade to affect the vertical labels
            readjustLabelsFromDeletedIndex(barModelData.verticalBarLabels, barWholeIndexToRemove);
        } 
		
		// Remove/alter bar comparisons based on removal  
        readjustBarComparison(barModelData, barWhole.id, targetBarSegmentIndex);
    }
    
    private function readjustBarComparison(barModelData : BarModelData,
            barWholeIdWithRemovedSegment : String,
            segmentIndexRemoved : Int) : Void
    {
        var barWholes : Array<BarWhole> = barModelData.barWholes;
        var i : Int = 0;
        var barWhole : BarWhole = null;
        var numBarWholes : Int = barWholes.length;
        var barWholeWithRemovedSegment : BarWhole = null;
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            if (barWhole.id == barWholeIdWithRemovedSegment) 
            {
                barWholeWithRemovedSegment = barWhole;
                break;
            }
        }  
		
		// Search through all bar comparisons that reference the bar that had an object deleted  
		// We want to check if the deletion of the segment forces the comparison to alter the segment index   
		// it would point to.   
		// If the bar with the removed segment had a comparison, nothing needs to change since the comparison   
        // is always assumed to be at the right edge of the bar.  
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            var barComparison : BarComparison = barWhole.barComparison;
            if (barComparison != null && barComparison.barWholeIdComparedTo == barWholeIdWithRemovedSegment) 
            {
                // If deleting the segment also removed the entire bar, then the comparison can be completely discarded
                if (barWholeWithRemovedSegment == null) 
                {
                    barWhole.barComparison = null;
                }
                else if (barComparison.segmentIndexComparedTo >= segmentIndexRemoved) 
                {
                    // Decrease the index if it points past the last segment
                    if (barComparison.segmentIndexComparedTo >= barWholeWithRemovedSegment.barSegments.length) 
                    {
                        barComparison.segmentIndexComparedTo = barWholeWithRemovedSegment.barSegments.length - 1;
                    }  
					
					// Remove bar comparison, if values of the bar up to the new index is less than or the same as the  
                    // value of the whole bar. There is no valid difference  
                    if (barComparison.segmentIndexComparedTo < 0) 
                    {
                        barWhole.barComparison = null;
                    }
                    else 
                    {
                        var totalValueUpToIndex : Float = barWholeWithRemovedSegment.getValue(0, barComparison.segmentIndexComparedTo);
                        if (barWhole.getValue() >= totalValueUpToIndex) 
                        {
                            barWhole.barComparison = null;
                        }
                    }
                }
            }
        }
    }
    
    private function readjustLabelsFromDeletedIndex(barLabels : Array<BarLabel>, segmentIndexRemoved : Int) : Void
    {
        var numBarLabels : Int = barLabels.length;
        var barLabel : BarLabel = null;
        var i : Int = 0;
        while (i < numBarLabels) {
            barLabel = barLabels[i];
            
            // If label is only pointing to the bar that was deleted then it should be removed
            if (barLabel.startSegmentIndex == segmentIndexRemoved &&
                barLabel.endSegmentIndex == segmentIndexRemoved) 
            {
                barLabels.splice(i, 1);
                numBarLabels--;
                i--;
            }
            else 
            {
                // All indices that occur AFTER the removed one need to be shifted down by one
                if (barLabel.startSegmentIndex > segmentIndexRemoved) 
                {
                    barLabel.startSegmentIndex--;
                }
                
                if (barLabel.endSegmentIndex >= segmentIndexRemoved) 
                {
                    barLabel.endSegmentIndex--;
                }
            }
			i++;
        }
    }
    
    private function onShatterAnimationComplete(animation : ShatterAnimation) : Void
    {
        animation.dispose();
        animation.activeTexture.dispose();
    }
    
    private function onRingPulseAnimationComplete() : Void
    {
        // Make sure animation isn't showing
        //Starling.current.juggler.remove(m_ringPulseAnimation);
    }
}
