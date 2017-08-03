package wordproblem.scripts.barmodel;


import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.system.RectanglePool;
import dragonbox.common.ui.MouseState;

import starling.display.DisplayObjectContainer;
import starling.display.Image;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.BarModelDataUtil;
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
 * This scripts handles making copies of an existing bar segement and appending them.
 * Note that this is just the 'box' images that is getting added.
 * For example, suppose a bar composed of variable sized segemnts a, b, and c. Multiplying by three
 * would create a bar sequenced abcabcabc, it would now have 9 total segments.
 */
class MultiplyBarSegments extends BaseBarModelScript implements IHitAreaScript
{
    /**
     * The is a constraint to prevent the creation of too many segments at once that might
     * cause the system to crash.
     * 
     * (At high numbers viewing each individual box is probably not useful anyways)
     */
    private static inline var MAX_ALLOWABLE_UNITS : Int = 30;
    
    /**
     * The limit to the number of barwholes that can be in the bar model area at the same time.
     * If less than zero, an unlimited number of bars are allowed.
     */
    private var m_maxBarsAllowed : Int;
    
    /**
     * All hit areas that when activated will cause the copy function to fire.
     */
    private var m_addBarCopiesHitAreas : Array<Rectangle>;
    
    /**
     * Pool to re-use the hit area rectangles
     */
    private var m_hitAreaPool : RectanglePool;
    
    /**
     * Buffer to keep track of multiple return values that are primitives
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * Keep track of the new bar segments that were created and shown in the preview
     */
    private var m_previewIds : Array<String>;
    
    /**
     * Should hit areas for this action be shown in at the start of a frame
     */
    private var m_showHitAreas : Bool;
    
    private static inline var PREVIEW_ID_PREFIX : String = "preview_copy_";
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            maxBarsAllowed : Int,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_maxBarsAllowed = maxBarsAllowed;
        m_addBarCopiesHitAreas = new Array<Rectangle>();
        m_hitAreaPool = new RectanglePool();
        m_outParamsBuffer = new Array<Dynamic>();
        m_previewIds = new Array<String>();
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        m_showHitAreas = false;
        if (this.m_ready && m_isActive) 
        {
            // Convert mouse coordinate reference to that of the bar model
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            
			m_outParamsBuffer = new Array<Dynamic>();
            if (m_eventTypeBuffer.length > 0) 
            {
                var data : Dynamic = m_eventParamBuffer[0];
                var releasedWidget : BaseTermWidget = data.widget;
                var releasedExpressionNode : ExpressionNode = releasedWidget.getNode();
                if (Std.is(releasedWidget, SymbolTermWidget) &&
                    getMouseInHitAreas(m_outParamsBuffer) &&
                    this.nodeHasValidNumber(releasedExpressionNode)) 
                {
                    clearPreview();
                    
                    var barIndex : Int = Std.parseInt(m_outParamsBuffer[0]);
                    var barWholeView : BarWholeView = m_barModelArea.getBarWholeViews()[barIndex];
                    var numCopies : Int = Std.parseInt(releasedExpressionNode.data);
                    
                    // Get whether the copies would fit nicely in the view port, if not then do not allow the action
                    if (this.checkIfBarCopiesWouldFit(m_barModelArea.getBarModelData(), barWholeView.data, numCopies)) 
                    {
                        var newSegmentColor : Int = barWholeView.segmentViews[0].data.color;
                        
                        var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                        this.addBarCopies(barWholeView.data, m_barModelArea.getBarModelData(), numCopies, newSegmentColor);
                        
                        if (m_gameEngine.getCurrentLevel().getLevelRules().autoResizeHorizontalBrackets) 
                        {
                            BarModelDataUtil.stretchHorizontalBrackets(m_barModelArea.getBarModelData());
                        }
                        
                        m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
                                    previousSnapshot : previousModelDataSnapshot
                                });
                        m_barModelArea.redraw();
                        status = ScriptStatus.SUCCESS;
                        
                        // Log multiplication action
                        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.MULTIPLY_BAR, false, {
                                    barModel : m_barModelArea.getBarModelData().serialize(),
                                    value : releasedExpressionNode.data,
                                });
                    }
                }
                
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected() != null && Std.is(m_widgetDragSystem.getWidgetSelected(), SymbolTermWidget)) 
            {
                var draggedNode : ExpressionNode = m_widgetDragSystem.getWidgetSelected().getNode();
                var numCopies = Std.parseInt(draggedNode.data);
                
                if (this.nodeHasValidNumber(draggedNode)) 
                {
                    m_showHitAreas = true;
                    if (getMouseInHitAreas(m_outParamsBuffer)) 
                    {
                        var barIndex = Std.parseInt(m_outParamsBuffer[0]);
                        var barWholeView = m_barModelArea.getBarWholeViews()[barIndex];
                        
                        // Get whether the copies would fit nicely in the view port, if not then do not allow the preview
                        if (this.checkIfBarCopiesWouldFit(m_barModelArea.getBarModelData(), barWholeView.data, numCopies)) 
                        {
                            // This check shows the preview if either it was not showing already OR a lower priority
                            // script had activated it but we want to overwrite it.
                            if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview) 
                            {
                                var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                                
                                var newSegmentColor = barWholeView.segmentViews[0].data.color;
                                
                                // Generate ids for the new segments so we can apply visuals to them
								m_previewIds = new Array<String>();
                                var i : Int = 0;
                                var numNewSegmentsToCreate : Int = barWholeView.segmentViews.length * (numCopies - 1);
                                for (i in 0...numNewSegmentsToCreate){
                                    var newSegmentId : String = PREVIEW_ID_PREFIX + i;
                                    m_previewIds.push(newSegmentId);
                                }
                                
                                this.addBarCopies(
                                        previewView.getBarModelData().getBarWholeById(barWholeView.data.id),
                                        previewView.getBarModelData(),
                                        numCopies,
                                        newSegmentColor,
                                        m_previewIds
                                        );
                                
                                if (m_gameEngine.getCurrentLevel().getLevelRules().autoResizeHorizontalBrackets) 
                                {
                                    BarModelDataUtil.stretchHorizontalBrackets(previewView.getBarModelData());
                                }
                                
                                m_barModelArea.showPreview(true);
                                m_didActivatePreview = true;
                                
                                // Apply a blink to all added segment copies
                                for (i in 0...m_previewIds.length){
                                    var newSegmentId = m_previewIds[i];
                                    
                                    // Make sure old blink parts are removed
                                    m_barModelArea.componentManager.removeAllComponentsFromEntity(m_previewIds[i]);
                                    
                                    m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(newSegmentId));
                                    var renderComponent : RenderableComponent = new RenderableComponent(newSegmentId);
                                    renderComponent.view = previewView.getBarSegmentViewById(newSegmentId);
                                    m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                                }
                            }
                            
                            status = ScriptStatus.SUCCESS;
                        }
                    }
                    else if (m_didActivatePreview) 
                    {
                        clearPreview();
                    }
                }
            }
        }
        
        return status;
    }
    
    private function checkIfBarCopiesWouldFit(barModelData : BarModelData, targetBarWhole : BarWhole, numCopies : Int) : Bool
    {
        var clonedBarModel : BarModelData = barModelData.clone();
        var clonedBarWhole : BarWhole = clonedBarModel.getBarWholeById(targetBarWhole.id);
        this.addBarCopies(clonedBarWhole, clonedBarModel, numCopies, 0x000000);
        
        return m_barModelArea.checkAllBarSegmentsFitInView(clonedBarModel);
    }
    
    private function clearPreview() : Void
    {
        if (m_didActivatePreview) 
        {
            // Remove the preview if it was showing
            m_barModelArea.showPreview(false);
            m_didActivatePreview = false;
            
            // Remove generated preview segment ids
            var i : Int = 0;
            for (i in 0...m_previewIds.length){
                m_barModelArea.componentManager.removeAllComponentsFromEntity(m_previewIds[i]);
            }
        }
        
		m_previewIds = new Array<String>();
    }
    
    public function getActiveHitAreas() : Array<Rectangle>
    {
        this.calculateHitAreas();
        return m_addBarCopiesHitAreas;
    }
    
    public function getShowHitAreasForFrame() : Bool
    {
        return m_showHitAreas;
    }
    
    public function postProcessHitAreas(hitAreas : Array<Rectangle>, hitAreaGraphics : Array<DisplayObjectContainer>) : Void
    {
        for (i in 0...hitAreaGraphics.length){
            var icon : Image = new Image(m_assetManager.getTexture("multiply_x.png"));
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
        // Clear out previous active hit areas and return them to the pool
        m_hitAreaPool.returnRectangles(m_addBarCopiesHitAreas);
        
        // The number of hit areas is equal to the number of bars + 1, that is
        // we can append copies to all existing bar and create a brand new bar
        // The hit area should be directly left of the bar
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        
        var hitAreaWidth : Float = m_barModelArea.leftBarPadding;
        var hitAreaHeight : Float = 50;
        
        var i : Int = 0;
        for (i in 0...numBarWholeViews){
            var hitArea : Rectangle = m_hitAreaPool.getRectangle();
            var segmentViews : Array<BarSegmentView> = barWholeViews[i].segmentViews;
            if (segmentViews.length > 0) 
            {
                var firstSegmentBounds : Rectangle = segmentViews[0].rigidBody.boundingRectangle;
                hitArea.setTo(0, firstSegmentBounds.y, hitAreaWidth, hitAreaHeight);
            }
            m_addBarCopiesHitAreas.push(hitArea);
        }
    }
    
    private function nodeHasValidNumber(node : ExpressionNode) : Bool
    {
        var numberValid : Bool = false;
        if (ExpressionUtil.isNodeNumeric(node) && !node.isNegative()) 
        {
            var value : Float = Std.parseInt(node.data);
            numberValid = (value > 1 && value < MAX_ALLOWABLE_UNITS);
        }
        return numberValid;
    }
    
    /**
     * @param outParams
     *      First index is the index of the hit area
     */
    private function getMouseInHitAreas(outParams : Array<Dynamic>) : Bool
    {
        this.calculateHitAreas();
        
        var inhitArea : Bool = false;
        var i : Int = 0;
        var numHitAreas : Int = m_addBarCopiesHitAreas.length;
        for (i in 0...numHitAreas){
            if (m_addBarCopiesHitAreas[i].containsPoint(m_localMouseBuffer)) 
            {
                inhitArea = true;
                outParams.push(i);
                break;
            }
        }
        
        return inhitArea;
    }
    
    public function addBarCopies(barWhole : BarWhole,
            barModelData : BarModelData,
            numCopies : Int,
            color : Int,
            ids : Array<String> = null) : Void
    {
        // We want to duplicate the bar segments
        var barSegments : Array<BarSegment> = barWhole.barSegments;
        var i : Int = 0;
        var numSegmentsOriginally : Int = barSegments.length;
        var numNewSegmentsToCreate : Int = (numCopies - 1) * numSegmentsOriginally;
        for (i in 0...numNewSegmentsToCreate){
            var newSegmentId : String = null;
            if (ids != null && ids.length > i) 
            {
                newSegmentId = ids[i];
            }
            
            var segmentToCopy : BarSegment = barSegments[i % numSegmentsOriginally];
            var newBarSegment : BarSegment = new BarSegment(
            segmentToCopy.numeratorValue, segmentToCopy.denominatorValue, segmentToCopy.color, segmentToCopy.hiddenValue, newSegmentId);
            barSegments.push(newBarSegment);
        }
		
		// If the addition of the new segment causes the comparison to no longer be correct,  
		// it must be deleted OR comparison no longer is attached to a single bar  
		// To do this we check if the value of the target bar exceed the value of the other one 
		// If this is detected than the comparison must be removed because we are under the assumption the comparison
        // is always attached to the shorter bar.
        if (barWhole.barComparison != null) 
        {
            var otherBarWhole : BarWhole = barModelData.getBarWholeById(barWhole.barComparison.barWholeIdComparedTo);
            var totalValueUpToIndex : Float = otherBarWhole.getValue(0, barWhole.barComparison.segmentIndexComparedTo);
            
            // Check if the value of the target bar whole now exceeds the value up to the segment index that was compared against
            if (totalValueUpToIndex < barWhole.getValue()) 
            {
                barWhole.barComparison = null;
            }
        }
    }
}
