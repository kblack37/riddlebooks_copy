package wordproblem.scripts.barmodel;

import openfl.display.Bitmap;
import wordproblem.display.PivotSprite;
import wordproblem.engine.events.DataEvent;
import wordproblem.scripts.barmodel.BaseBarModelScript;
import wordproblem.scripts.barmodel.ICardOnSegmentEdgeScript;
import wordproblem.scripts.barmodel.IHitAreaScript;

import openfl.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.barmodel.model.BarModelData;
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
 * This script handles adding the new comparison segment to show the different
 * in value between a shorter and longer bar.
 */
class AddNewBarComparison extends BaseBarModelScript implements IHitAreaScript implements ICardOnSegmentEdgeScript
{
    /**
     * A buffer that stores the bar view that the comparison should add to
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    // Used to keep track of changes in which bars should be involved in the comparison
    private var m_currentTargetBarId : String;
    private var m_currentCompareToBarId : String;
    
    /**
     * Active hit areas on a given frame
     */
    private var m_hitAreas : Array<Rectangle>;
    private var m_hitAreaPool : Array<Rectangle>;
    
    /**
     * Extra list to map a hit area to a particular bar view
     */
    private var m_hitAreaBarIds : Array<String>;
    
    /**
     * Should hit areas for this action be shown in at the start of a frame
     */
    private var m_showHitAreas : Bool;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_outParamsBuffer = new Array<Dynamic>();
        m_hitAreas = new Array<Rectangle>();
        m_hitAreaPool = new Array<Rectangle>();
        m_hitAreaBarIds = new Array<String>();
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        m_showHitAreas = false;
        if (m_ready && m_isActive) 
        {
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_localMouseBuffer = m_barModelArea.globalToLocal(m_globalMouseBuffer);
			m_outParamsBuffer = new Array<Dynamic>();
            
            if (m_eventTypeBuffer.length > 0) 
            {
                var data : Dynamic = m_eventParamBuffer[0];
                var releasedWidget : BaseTermWidget = data.widget;
                
                if (Std.is(releasedWidget, SymbolTermWidget) && checkOverHitArea(m_outParamsBuffer)) 
                {
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    
                    var targetBarWholeView : BarWholeView = try cast(m_outParamsBuffer[0], BarWholeView) catch(e:Dynamic) null;
                    var barToCompareAgainst : BarWholeView = try cast(m_outParamsBuffer[1], BarWholeView) catch(e:Dynamic) null;
                    
                    var widthDifference : Float = barToCompareAgainst.segmentViews[barToCompareAgainst.segmentViews.length - 1].rigidBody.boundingRectangle.right -
                    targetBarWholeView.segmentViews[targetBarWholeView.segmentViews.length - 1].rigidBody.boundingRectangle.right;
                    var releasedExpressionNode : ExpressionNode = releasedWidget.getNode();
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    addNewBarComparison(targetBarWholeView.data, releasedExpressionNode.data, barToCompareAgainst.data, barToCompareAgainst.segmentViews.length - 1);
                    
                    m_eventDispatcher.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                                previousSnapshot : previousModelDataSnapshot
                            }));
                    m_barModelArea.redraw();
                    
                    m_eventDispatcher.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON,
                            {
                                barModel : m_barModelArea.getBarModelData().serialize(),
                                value : releasedExpressionNode.data,
                            }));
                    
                    m_currentTargetBarId = null;
                    m_currentCompareToBarId = null;
                    
                    status = ScriptStatus.SUCCESS;
                }
                
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected() != null && Std.is(m_widgetDragSystem.getWidgetSelected(), SymbolTermWidget)) 
            {
                m_showHitAreas = true;
                if (checkOverHitArea(m_outParamsBuffer)) 
                {
                    var targetBarWholeView = try cast(m_outParamsBuffer[0], BarWholeView) catch(e:Dynamic) null;
                    var barToCompareAgainst = try cast(m_outParamsBuffer[1], BarWholeView) catch(e:Dynamic) null;
                    var barsInComparisonDifferFromLastVisit : Bool = m_currentCompareToBarId != barToCompareAgainst.data.id ||
                    m_currentTargetBarId != targetBarWholeView.data.id;
                    
                    // This check shows the preview if either it was not showing already OR a lower priority
                    // script had activated it but we want to overwrite it.
                    // Also redraw if the values changed from last time
                    if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview || barsInComparisonDifferFromLastVisit) 
                    {
                        m_currentTargetBarId = targetBarWholeView.data.id;
                        m_currentCompareToBarId = barToCompareAgainst.data.id;
                        
                        var widthDifference = barToCompareAgainst.segmentViews[barToCompareAgainst.segmentViews.length - 1].rigidBody.boundingRectangle.right -
                                targetBarWholeView.segmentViews[targetBarWholeView.segmentViews.length - 1].rigidBody.boundingRectangle.right;
                        var releasedExpressionNode = m_widgetDragSystem.getWidgetSelected().getNode();
                        
                        var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                        var previewBarWhole : BarWhole = previewView.getBarModelData().getBarWholeById(targetBarWholeView.data.id);
                        addNewBarComparison(previewBarWhole, releasedExpressionNode.data, barToCompareAgainst.data, barToCompareAgainst.segmentViews.length - 1);
                        m_barModelArea.showPreview(true);
                        m_didActivatePreview = true;
                        
                        // Blink the new comparison
                        var previewBarWholeWithComparison : BarWholeView = previewView.getBarWholeViewById(m_currentTargetBarId);
                        m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(m_currentTargetBarId));
                        var renderComponent : RenderableComponent = new RenderableComponent(m_currentTargetBarId);
                        renderComponent.view = previewBarWholeWithComparison.comparisonView;
                        m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                        
                        super.setDraggedWidgetVisible(false);
                    }
                    
                    status = ScriptStatus.SUCCESS;
                }
                else if (m_didActivatePreview) 
                {
                    // Remove the preview
                    m_barModelArea.componentManager.removeAllComponentsFromEntity(m_currentTargetBarId);
                    m_currentTargetBarId = null;
                    m_currentCompareToBarId = null;
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    super.setDraggedWidgetVisible(true);
                }
            }
        }
        return status;
    }
    
    override public function reset() : Void
    {
        super.reset();
        
        m_showHitAreas = false;
        m_barModelArea.componentManager.removeAllComponentsFromEntity(m_currentTargetBarId);
    }
    
    public function getActiveHitAreas() : Array<Rectangle>
    {
        calculateHitAreas();
        return m_hitAreas;
    }
    
    public function getShowHitAreasForFrame() : Bool
    {
        return m_showHitAreas;
    }
    
    public function postProcessHitAreas(hitAreas : Array<Rectangle>, hitAreaGraphics : Array<DisplayObjectContainer>) : Void
    {
        for (i in 0...hitAreas.length){
            var icon : PivotSprite = new PivotSprite();
			icon.addChild(new Bitmap(m_assetManager.getBitmapData("subtract")));
            var hitArea : Rectangle = hitAreas[i];
            icon.pivotX = icon.width * 0.5;
            icon.pivotY = icon.height * 0.5;
            icon.x = hitArea.width * 0.5;
            icon.y = hitArea.height * 0.5;
            hitAreaGraphics[i].addChild(icon);
        }
    }
    
    private function calculateHitAreas() : Void
    {
        while (m_hitAreas.length > 0)
        {
            m_hitAreaPool.push(m_hitAreas.pop());
        }
        
		m_hitAreaBarIds = new Array<String>();
        
        // For each individual bar, the hit area starts at the edge of the end and
        // extends to the edge of the longest bar
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var i : Int = 0;
        var numBarWholeViews : Int = barWholeViews.length;
        var barWholeView : BarWholeView = null;
        
        // First find the end of the longest bar, the is the rightmost limit for all bars
        var longestBarViewIndex : Int = -1;
        var furthestRightEdgeX : Float = 0;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            var segmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
            var rightEdgeX : Float = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle.right;
            if (longestBarViewIndex == -1 || rightEdgeX > furthestRightEdgeX) 
            {
                longestBarViewIndex = i;
                furthestRightEdgeX = rightEdgeX;
            }
        }
		
		// With the proper end, go through each bar and treat each having a hit area  
        // extending horizontally from its last segment edge to the furthest edge of the longest bar
		// and vertically from the top and bottom of its segments
        for (i in 0...numBarWholeViews){
            // No hit area for the longest bar since we define the comparison to always span from
            // a smaller value to a larger one.
            if (i != longestBarViewIndex) 
            {
                barWholeView = barWholeViews[i];
                var segmentViews = barWholeView.segmentViews;
                var lastSegmentBounds : Rectangle = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle;
                var leftEdgeX : Float = lastSegmentBounds.right;
                var topEdgeY : Float = lastSegmentBounds.top;
                var hitAreaHeight : Float = lastSegmentBounds.height;
                var hitAreaWidth : Float = furthestRightEdgeX - leftEdgeX;
                
                // Grab a rectangle from the pool
                var hitArea : Rectangle = ((m_hitAreaPool.length > 0)) ? m_hitAreaPool.pop() : new Rectangle();
                hitArea.setTo(leftEdgeX, topEdgeY, hitAreaWidth, hitAreaHeight);
                m_hitAreas.push(hitArea);
                
                m_hitAreaBarIds.push(barWholeView.data.id);
            }
        }
    }
    
    /**
     *
     * @param outParams
     *      First index is the target bar whole view that was hit
     *      Second index is the bar to compare against (should always be longer than the first)
     */
    private function checkOverHitArea(outParams : Array<Dynamic>) : Bool
    {
        var doAddComparison : Bool = false;
        calculateHitAreas();
        
        var i : Int = 0;
        var numHitAreas : Int = m_hitAreas.length;
        var hitArea : Rectangle = null;
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        for (i in 0...numHitAreas){
            hitArea = m_hitAreas[i];
            
            if (hitArea.width > 0.01 && hitArea.containsPoint(m_localMouseBuffer)) 
            {
                // If we are in the hit area we now need to determine which bar this one should
                // compare against.
                // We can do this by finding the rightmost edge of every OTHER bar and figuring out
                // which one is closest to the current mouse x.
                // The mouse x must also be to the left of that edge and right of the current bar's
                // right edge (i.e. can only compare with bars longer than it)
                var j : Int = 0;
                var closestBarIndex : Int = -1;
                var closestDistance : Float = 0;
                for (j in 0...numBarWholeViews){
                    var otherBarWholeView : BarWholeView = barWholeViews[j];
                    if (otherBarWholeView.data.id != m_hitAreaBarIds[i]) 
                    {
                        var otherBarSegmentViews : Array<BarSegmentView> = otherBarWholeView.segmentViews;
                        var rightEdgeXOtherBar : Float = otherBarSegmentViews[otherBarSegmentViews.length - 1].rigidBody.boundingRectangle.right;
                        if (m_localMouseBuffer.x < rightEdgeXOtherBar && rightEdgeXOtherBar > hitArea.left) 
                        {
                            var mouseDeltaFromEdge : Float = rightEdgeXOtherBar - m_localMouseBuffer.x;
                            if (closestBarIndex == -1 || mouseDeltaFromEdge < closestDistance) 
                            {
                                closestBarIndex = j;
                                closestDistance = mouseDeltaFromEdge;
                            }
                        }
                    }
                }
                
                if (closestBarIndex != -1) 
                {
                    doAddComparison = true;
                    var targetBarWholeView : BarWholeView = m_barModelArea.getBarWholeViewById(m_hitAreaBarIds[i]);
                    outParams.push(targetBarWholeView);
                    outParams.push(barWholeViews[closestBarIndex]);
                    
                }
                
                break;
            }
        }
        
        return doAddComparison;
    }
    
    public function addNewBarComparison(barWhole : BarWhole,
            value : String,
            barWholeToCompareTo : BarWhole,
            segmentIndexToCompareTo : Int) : Void
    {
        var newBarComparison : BarComparison = new BarComparison(value, barWholeToCompareTo.id, segmentIndexToCompareTo);
        barWhole.barComparison = newBarComparison;
    }
    
    public function canPerformAction(draggedWidget : DisplayObject, barWholeId : String) : Bool
    {
        // Find the given bar whole
        var canPerformAction : Bool = false;
        
        // Only allow comparison is currently dragged widget is card and the target bar is not the longest
        // (User can also drag boxes, which do not make sense in terms of creating a comparison)
        if (Std.is(draggedWidget, SymbolTermWidget)) 
        {
            var matchingBarWholeView : BarWholeView = m_barModelArea.getBarWholeViewById(barWholeId);
            var otherBarWhole : BarWhole = getLongestOtherBarWholeIdToCompare(barWholeId);
            canPerformAction = matchingBarWholeView != null && matchingBarWholeView.data != otherBarWhole && otherBarWhole != null;
        }
        
        return canPerformAction;
    }
    
    public function performAction(draggedWidget : DisplayObject, extraParams : Dynamic, barWholeId : String) : Void
    {
        // Dispose the preview if it was shown
        if (Std.is(draggedWidget, SymbolTermWidget)) 
        {
            hidePreview();
            
            var cardValue : String = (try cast(draggedWidget, SymbolTermWidget) catch(e:Dynamic) null).getNode().data;
            var matchingBarWholeView : BarWholeView = m_barModelArea.getBarWholeViewById(barWholeId);
            var otherBarWhole : BarWhole = getLongestOtherBarWholeIdToCompare(barWholeId);
            if (otherBarWhole != null && matchingBarWholeView != null) 
            {
                var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                this.addNewBarComparison(matchingBarWholeView.data, cardValue, otherBarWhole, otherBarWhole.barSegments.length - 1);
                
                m_eventDispatcher.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                            previousSnapshot : previousModelDataSnapshot
                        }));
                
                // Redraw at the end to refresh
                m_barModelArea.redraw();
                
                // Log splitting on an existing segment
                m_eventDispatcher.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, {
                            barModel : m_barModelArea.getBarModelData().serialize(),
                            value : cardValue,
                        }));
            }
        }
    }
    
    private function getLongestOtherBarWholeIdToCompare(barWholeId : String) : BarWhole
    {
        var otherBarWhole : BarWhole = null;
        var matchingBarWholeView : BarWholeView = m_barModelArea.getBarWholeViewById(barWholeId);
        if (matchingBarWholeView != null) 
        {
            // A comparison can be added only if there is another bar that is longer. If there are multiple ones,
            // we pick the longest one
            var valueOfCurrentBarWhole : Float = matchingBarWholeView.data.getValue();
            var otherBarWholeViewToCompare : BarWholeView = null;
            for (otherBarWholeView in m_barModelArea.getBarWholeViews())
            {
                if (otherBarWholeView != matchingBarWholeView) 
                {
                    var valueOfOtherBarWhole : Float = otherBarWholeView.data.getValue();
                    if (valueOfOtherBarWhole > valueOfCurrentBarWhole) 
                    {
                        otherBarWhole = otherBarWholeView.data;
                        break;
                    }
                }
            }
        }
        
        return otherBarWhole;
    }
    
    public function showPreview(draggedWidget : DisplayObject, extraParams : Dynamic, barWholeId : String) : Void
    {
        if (Std.is(draggedWidget, SymbolTermWidget)) 
        {
            var cardValue : String = (try cast(draggedWidget, SymbolTermWidget) catch(e:Dynamic) null).getNode().data;
            var targetBarWholeView : BarWhole = m_barModelArea.getBarModelData().getBarWholeById(barWholeId);
            var otherBarWholeToCompare : BarWhole = getLongestOtherBarWholeIdToCompare(barWholeId);
            
            var previewView : BarModelView = m_barModelArea.getPreviewView(true);
            var previewTargetBarWhole : BarWhole = previewView.getBarModelData().getBarWholeById(barWholeId);
            var previewOtherBarWhole : BarWhole = previewView.getBarModelData().getBarWholeById(otherBarWholeToCompare.id);
            this.addNewBarComparison(previewTargetBarWhole, cardValue, previewOtherBarWhole, previewOtherBarWhole.barSegments.length - 1);
            
            m_barModelArea.showPreview(true);
            
            // Blink the new comparison
            var previewBarWholeWithComparison : BarWholeView = previewView.getBarWholeViewById(barWholeId);
            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(barWholeId));
            var renderComponent : RenderableComponent = new RenderableComponent(barWholeId);
            renderComponent.view = previewBarWholeWithComparison.comparisonView;
            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
            m_currentTargetBarId = barWholeId;
        }
    }
    
    public function hidePreview() : Void
    {
        m_barModelArea.showPreview(false);
        
        // Remove the blink from the preview comparison
        m_barModelArea.componentManager.removeAllComponentsFromEntity(m_currentTargetBarId);
    }
}
