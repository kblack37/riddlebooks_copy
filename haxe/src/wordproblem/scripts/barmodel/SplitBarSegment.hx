package wordproblem.scripts.barmodel;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.component.BlinkComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

/**
 * This script handles taking an existing bar segment and dividing it up into n equal pieces.
 * The sum of the divided pieces will take up roughly the same area as it was before the split.
 */
class SplitBarSegment extends BaseBarModelScript implements ICardOnSegmentScript
{
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * Need to limit the total number of splits a segment can break into.
     * Reason is too many breaks will greatly slow down the game.
     */
    private var m_splitLimit : Int = 30;
    
    /**
     * The last index of the segment that is set to be split.
     * Keep track of this so we can detect if mouse is over a new segment without ever leaving the bounds
     * of a bar.
     */
    private var m_targetBarSegmentIndex : Int;
    
    /**
     * Keep track of all the segments that are part of the blink preview
     */
    private var m_segmentIdsBlinkingForPreview : Array<String>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_outParamsBuffer = new Array<Dynamic>();
        m_segmentIdsBlinkingForPreview = new Array<String>();
    }
    
    public function canPerformAction(cardValue : String, segmentId : String) : Bool
    {
        var canPerformAction : Bool = false;
        
        // Check that the card value is a number
        if (checkValueValid(cardValue) && m_isActive) 
        {
            canPerformAction = true;
        }
        
        return canPerformAction;
    }
    
    public function showPreview(cardValue : String, segmentId : String) : Void
    {
        var outIndices : Array<Int> = new Array<Int>();
        m_barModelArea.getBarModelData().getBarSegmentById(segmentId, outIndices);
        
        var targetBarWholeIndex : Int = outIndices[0];
        var targetBarSegmentIndex : Int = outIndices[1];
        var previewView : BarModelView = m_barModelArea.getPreviewView(true);
        var numSegmentsToSplitInto : Int = Std.parseInt(cardValue);
        splitBarSegment(targetBarWholeIndex,
                targetBarSegmentIndex, numSegmentsToSplitInto, previewView.getBarModelData());
        m_barModelArea.showPreview(true);
        
        // Add blinking to the new split segments
        var previewBarWholeWithSplit : BarWholeView = previewView.getBarWholeViews()[targetBarWholeIndex];
        var previewSegmentViews : Array<BarSegmentView> = previewBarWholeWithSplit.segmentViews;
        for (i in 0...numSegmentsToSplitInto){
            var previewNewSegmentView : BarSegmentView = previewSegmentViews[i + targetBarSegmentIndex];
            var newSegmentId : String = previewNewSegmentView.data.id;
            
            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(newSegmentId));
            var renderComponent : RenderableComponent = new RenderableComponent(newSegmentId);
            renderComponent.view = previewNewSegmentView;
            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
            m_segmentIdsBlinkingForPreview.push(newSegmentId);
        }
    }
    
    public function hidePreview() : Void
    {
        m_barModelArea.showPreview(false);
        
        // Remove the blinking parts
        for (blinkingSegmentId in m_segmentIdsBlinkingForPreview)
        {
            m_barModelArea.componentManager.removeAllComponentsFromEntity(blinkingSegmentId);
        }
        
		m_segmentIdsBlinkingForPreview = new Array<String>();
    }
    
    public function performAction(cardValue : String, segmentId : String) : Void
    {
        // Dispose the preview if it was shown
        hidePreview();
        
        var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
        
        var barModelData : BarModelData = m_barModelArea.getBarModelData();
        var outIndices : Array<Int> = new Array<Int>();
        barModelData.getBarSegmentById(segmentId, outIndices);
        splitBarSegment(outIndices[0], outIndices[1], Std.parseInt(cardValue), barModelData);
        m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
            previousSnapshot : previousModelDataSnapshot
        });
        m_barModelArea.redraw();
        
        // Log splitting on an existing segment
        m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.SPLIT_BAR_SEGMENT, false, {
            barModel : m_barModelArea.getBarModelData().serialize(),
            value : cardValue,
        });
    }
    
    public function getName() : String
    {
        return m_id;
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready && m_isActive) 
        {
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            
			m_outParamsBuffer = new Array<Dynamic>();
            if (m_eventTypeBuffer.length > 0) 
            {
                var args : Dynamic = m_eventParamBuffer[0];
                var releasedWidget : BaseTermWidget = args.widget;
                
                m_didActivatePreview = false;
                m_barModelArea.showPreview(false);
                m_targetBarSegmentIndex = -1;
                
                if (BarModelHitAreaUtil.checkPointInBarSegment(m_outParamsBuffer, m_barModelArea, m_localMouseBuffer) &&
                    checkDraggedWidgetValid(releasedWidget)) 
                {
                    var targetBarWholeIndex : Int = Std.parseInt(m_outParamsBuffer[0]);
                    var targetBarSegmentIndex : Int = Std.parseInt(m_outParamsBuffer[1]);
                    var value : Int = Std.parseInt(releasedWidget.getNode().data);
                    
                    // In order to see whether the box would fit we need to apply the change
                    // Give a bar model with target set
                    // Create a clone of it and perform the split on it
                    if (this.checkIfSplitBarsWouldFit(m_barModelArea.getBarModelData().clone(), targetBarWholeIndex, targetBarSegmentIndex, value)) 
                    {
                        var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                        splitBarSegment(targetBarWholeIndex, targetBarSegmentIndex, value, m_barModelArea.getBarModelData());
                        m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
                            previousSnapshot : previousModelDataSnapshot
                        });
                        
                        // Log splitting on an existing segment
                        m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.SPLIT_BAR_SEGMENT, false, {
                            barModel : m_barModelArea.getBarModelData().serialize(),
                            value : value,
                        });
                        
                        // Redraw at the end to refresh
                        m_barModelArea.redraw();
                        
                        status = ScriptStatus.SUCCESS;
                    }
                }
                
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected() != null) 
            {
                var releasedWidget = m_widgetDragSystem.getWidgetSelected();
                if (BarModelHitAreaUtil.checkPointInBarSegment(m_outParamsBuffer, m_barModelArea, m_localMouseBuffer)
                    && checkDraggedWidgetValid(releasedWidget)) 
                {
                    var targetBarWholeIndex = Std.parseInt(m_outParamsBuffer[0]);
                    var targetBarSegmentIndex = Std.parseInt(m_outParamsBuffer[1]);
                    var value = Std.parseInt(releasedWidget.getNode().data);
                    
                    // This check shows the preview if either it was not showing already OR a lower priority
                    // script had activated it but we want to overwrite it.
                    // This particular action also has a weird case where we don't leave the hit area but have
                    // a different segment in the same bar that we switch to.
                    if (!m_barModelArea.getPreviewShowing() ||
                        !m_didActivatePreview ||
                        (m_targetBarSegmentIndex != targetBarSegmentIndex)) 
                    {
                        m_targetBarSegmentIndex = targetBarSegmentIndex;
                        var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                        splitBarSegment(targetBarWholeIndex, targetBarSegmentIndex, value, previewView.getBarModelData());
                        
                        m_didActivatePreview = true;
                        m_barModelArea.showPreview(true);
                        super.setDraggedWidgetVisible(false);
                    }
                    
                    status = ScriptStatus.SUCCESS;
                }
                else if (m_didActivatePreview) 
                {
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    m_targetBarSegmentIndex = -1;
                    super.setDraggedWidgetVisible(true);
                }
            }
        }
        return status;
    }
    
    private function checkIfSplitBarsWouldFit(barModelData : BarModelData, barWholeIndex : Int, segmentIndex : Int, splits : Int) : Bool
    {
        var cloneBarModel : BarModelData = barModelData.clone();
        
        // Identify the same target in the clone
        splitBarSegment(barWholeIndex, segmentIndex, splits, cloneBarModel);
        
        // Show the preview for real only if we find that the resultant segments would fit
        return m_barModelArea.checkAllBarSegmentsFitInView(cloneBarModel);
    }
    
    private function checkDraggedWidgetValid(widget : BaseTermWidget) : Bool
    {
        var widgetValid : Bool = false;
        if (widget != null && widget.getNode() != null && Std.is(widget, SymbolTermWidget)) 
        {
            widgetValid = checkValueValid(widget.getNode().data);
        }
        
        return widgetValid;
    }
    
    private function checkValueValid(dataValue : String) : Bool
    {
        // Do not allow a segment to be split by a non-numeric value or any non-positive value
        // since it doesn't make sense how a split would occur in those situations.
        // Also ignore a split by one since that has no effect
        var value : Float = Std.parseInt(dataValue);
        return (!Math.isNaN(value) && value > 1 && value < m_splitLimit);
    }
    
    public function splitBarSegment(targetBarWholeIndex : Int,
            targetBarSegmentIndex : Int,
            numSplits : Int,
            barModelData : BarModelData) : Void
    {
        var targetBarWhole : BarWhole = barModelData.barWholes[targetBarWholeIndex];
        
        // Need to adjust the any bar comparisons that referenced the bar that has the split
        // Before splitting need to determine the total value of the segments covered by the span
        var barWholesWithComparison : Array<BarWhole> = new Array<BarWhole>();
        var originalComparisonValues : Array<Float> = new Array<Float>();
        var barWholes : Array<BarWhole> = barModelData.barWholes;
        var numBarWholes : Int = barWholes.length;
        var barWhole : BarWhole;
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            
            // We need to reset the index such that it covers roughly the same value
            // Sum the value of the previous bar
            // Sum the value of the other up to the target index
            // The difference is the true value of the comparison
            if (barWhole.barComparison != null && barWhole.barComparison.barWholeIdComparedTo == targetBarWhole.id) 
            {
                var targetBarWholeValue : Float = targetBarWhole.getValue(0, barWhole.barComparison.segmentIndexComparedTo);
                var comparisonValue : Float = Math.abs(targetBarWholeValue - barWhole.getValue());
                barWholesWithComparison.push(barWhole);
                originalComparisonValues.push(comparisonValue);
            }
        }  // Find the target segment and split it equally into the number of pieces as specified  
        
        
        
        var targetBarSegment : BarSegment = targetBarWhole.barSegments[targetBarSegmentIndex];
        
        // Create the specified number of new segments
        var targetNumeratorValue : Float = targetBarSegment.numeratorValue;
        var targetDenominatorValue : Float = targetBarSegment.denominatorValue * numSplits;
        var newSegmentsToAdd : Array<BarSegment> = new Array<BarSegment>();
        var i : Int;
        for (i in 0...numSplits){
            var newBarSegment : BarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, targetBarSegment.color, null);
            newSegmentsToAdd.push(newBarSegment);
        }
        
        var tempSegmentStack : Array<BarSegment> = new Array<BarSegment>();
        var lastIndex : Int = targetBarWhole.barSegments.length - 1;
        i = lastIndex;
        while (i > targetBarSegmentIndex){
            tempSegmentStack.push(targetBarWhole.barSegments.pop());
            i--;
        }  // Delete the old segment  
        
        
        
        targetBarWhole.barSegments.pop();
        
        // Add the new segments and the previous segment that came after the one that was deleted
        while (newSegmentsToAdd.length > 0)
        {
            targetBarWhole.barSegments.push(newSegmentsToAdd.pop());
        }
        
        while (tempSegmentStack.length > 0)
        {
            targetBarWhole.barSegments.push(tempSegmentStack.pop());
        }  // In addition we need to update any indices that came after the previous target bar segment index    // be a bracket that spans all of the new split items    // If a label was associated with that segment and it had no bracket, we need to alter it to  
        
        
        
        
        
        
        
        var barLabel : BarLabel;
        var numBarLabels : Int = targetBarWhole.barLabels.length;
        for (i in 0...numBarLabels){
            barLabel = targetBarWhole.barLabels[i];
            
            if (barLabel.endSegmentIndex >= targetBarSegmentIndex) 
            {
                if (barLabel.startSegmentIndex == targetBarSegmentIndex &&
                    barLabel.endSegmentIndex == targetBarSegmentIndex &&
                    barLabel.bracketStyle == BarLabel.BRACKET_NONE) 
                {
                    barLabel.bracketStyle = BarLabel.BRACKET_STRAIGHT;
                }
                
                barLabel.endSegmentIndex += numSplits - 1;
            }
            
            if (barLabel.startSegmentIndex > targetBarSegmentIndex) 
            {
                barLabel.startSegmentIndex += numSplits - 1;
            }
        }  // add up segments until we get something as close as possible to the true value    // Once the split is done the we need to re-adjust the bar comparisons  
        
        
        
        
        
        var numComparisons : Int = barWholesWithComparison.length;
        for (i in 0...numComparisons){
            // Take into account the additional value provided by the bar assuming that it is
            // always on the left end.
            barWhole = barWholesWithComparison[i];
            var comparisonValue = originalComparisonValues[i] + barWhole.getValue();
            
            var j : Int;
            var barSegments : Array<BarSegment> = targetBarWhole.barSegments;
            var numSegments : Int = barSegments.length;
            var segmentValueCounter : Float = 0.0;
            var newSegmentIndexToCompareTo : Int = -1;
            var smallestDelta : Float = 0;
            for (j in 0...numSegments){
                segmentValueCounter += barSegments[j].getValue();
                var valueDelta : Float = Math.abs(segmentValueCounter - comparisonValue);
                if (newSegmentIndexToCompareTo == -1 || valueDelta < smallestDelta) 
                {
                    smallestDelta = valueDelta;
                    newSegmentIndexToCompareTo = j;
                }
            }
            
            barWhole.barComparison.segmentIndexComparedTo = newSegmentIndexToCompareTo;
        }
    }
}
