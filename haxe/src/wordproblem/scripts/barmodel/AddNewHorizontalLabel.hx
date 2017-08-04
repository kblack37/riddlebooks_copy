package wordproblem.scripts.barmodel;

import wordproblem.scripts.barmodel.BaseBarModelScript;
import wordproblem.scripts.barmodel.IHitAreaScript;

import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.system.RectanglePool;

import starling.display.DisplayObjectContainer;
import starling.textures.Texture;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarLabelView;
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
 * This script handles the addition of brand new horizontal labels in the model (visualized as brackets
 * spaning left to right)
 */
class AddNewHorizontalLabel extends BaseBarModelScript implements IHitAreaScript
{
    private static inline var PREVIEW_NEW_HORIZONTAL_LABEL_ID : String = "new_horizontal_label_id";
    
    /**
     * Restriction of the number of straight brackets that can be attached to a bar whole.
     * An example is we have tutorials where we just want a single label.
     * If negative, no limit to the number of brackets
     */
    private var m_maxBracketsPerBar : Int;
    
    /**
     * Keep a constantly updated list of the appropriate hit areas for each whole bar.
     * These are kept at the same index as the bar whole views
     */
    private var m_addNewHorizontalBarLabelHitAreas : Array<Rectangle>;
    
    private var m_hitAreaPool : RectanglePool;
    
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * Should hit areas for this action be shown in at the start of a frame
     */
    private var m_showHitAreas : Bool;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            maxBracketsPerBar : Int,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_maxBracketsPerBar = maxBracketsPerBar;
        m_addNewHorizontalBarLabelHitAreas = new Array<Rectangle>();
        m_outParamsBuffer = new Array<Dynamic>();
        m_hitAreaPool = new RectanglePool();
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        m_showHitAreas = false;
        if (this.m_ready && m_isActive) 
        {
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            
			m_outParamsBuffer = new Array<Dynamic>();
            
            if (m_eventTypeBuffer.length > 0) 
            {
                var data : Dynamic = m_eventParamBuffer[0];
                var releasedWidget : BaseTermWidget = data.widget;
                var releasedExpressionNode : ExpressionNode = releasedWidget.getNode();
                
                if (Std.is(releasedWidget, SymbolTermWidget) && checkHitArea(m_outParamsBuffer)) 
                {
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    
                    var hitBarWholeView : BarWholeView = try cast(m_outParamsBuffer[0], BarWholeView) catch(e:Dynamic) null;
                    var isTop : Bool = m_outParamsBuffer[1];
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    addNewHorizontalBracket(hitBarWholeView.data, releasedExpressionNode.data, hitBarWholeView.segmentViews.length - 1, isTop);
                    m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
                                previousSnapshot : previousModelDataSnapshot

                            });
                    m_barModelArea.redraw();
                    
                    // Log adding new label to segments in bar
                    m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL, false, {
                                barModel : m_barModelArea.getBarModelData().serialize(),
                                value : releasedExpressionNode.data,

                            });
                    
                    status = ScriptStatus.SUCCESS;
                }
                
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected() != null && Std.is(m_widgetDragSystem.getWidgetSelected(), SymbolTermWidget)) 
            {
                m_showHitAreas = true;
                if (checkHitArea(m_outParamsBuffer)) 
                {
                    // This check shows the preview if either it was not showing already OR a lower priority
                    // script had activated it but we want to overwrite it.
                    if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview) 
                    {
                        var hitBarWholeView = try cast(m_outParamsBuffer[0], BarWholeView) catch(e:Dynamic) null;
                        var isTop = m_outParamsBuffer[1];
                        var releasedExpressionNode = m_widgetDragSystem.getWidgetSelected().getNode();
                        var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                        var targetBarWholePreview : BarWhole = previewView.getBarModelData().getBarWholeById(hitBarWholeView.data.id);
                        addNewHorizontalBracket(targetBarWholePreview, releasedExpressionNode.data, targetBarWholePreview.barSegments.length - 1, isTop, PREVIEW_NEW_HORIZONTAL_LABEL_ID);
                        m_barModelArea.showPreview(true);
                        m_didActivatePreview = true;
                        
                        // Need to get at the new bar label view
                        var newBarLabelView : BarLabelView = previewView.getBarLabelViewById(PREVIEW_NEW_HORIZONTAL_LABEL_ID);
                        m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(PREVIEW_NEW_HORIZONTAL_LABEL_ID));
                        var renderComponent : RenderableComponent = new RenderableComponent(PREVIEW_NEW_HORIZONTAL_LABEL_ID);
                        renderComponent.view = newBarLabelView;
                        m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                        
                        super.setDraggedWidgetVisible(false);
                    }
                    
                    status = ScriptStatus.SUCCESS;
                }
                else if (m_didActivatePreview) 
                {
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_HORIZONTAL_LABEL_ID);
                    super.setDraggedWidgetVisible(true);
                }
            }
        }
        return status;
    }
    
    override public function reset() : Void
    {
        super.reset();
        
        m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_HORIZONTAL_LABEL_ID);
    }
    
    public function getActiveHitAreas() : Array<Rectangle>
    {
        calculateHitAreas();
        return m_addNewHorizontalBarLabelHitAreas;
    }
    
    public function getShowHitAreasForFrame() : Bool
    {
        return m_showHitAreas;
    }
    
    public function postProcessHitAreas(hitAreas : Array<Rectangle>, hitAreaGraphics : Array<DisplayObjectContainer>) : Void
    {
        var leftBracketTexture : Texture = m_assetManager.getTexture("brace_left_end");
        var rightBracketTexture : Texture = m_assetManager.getTexture("brace_right_end");
        var middleBracketTexture : Texture = m_assetManager.getTexture("brace_center");
        var fullBracketTexture : Texture = m_assetManager.getTexture("brace_full");
        var i : Int = 0;
        var numHitAreas : Int = hitAreas.length;
        for (i in 0...numHitAreas){
            var hitArea : Rectangle = hitAreas[i];
            var dummyBarLabel : BarLabel = new BarLabel(null, 0, 0, true, false, BarLabel.BRACKET_STRAIGHT, null);
            var bracketView : BarLabelView = new BarLabelView(dummyBarLabel, "Verdana", 0xFFFFFF, 
            leftBracketTexture, rightBracketTexture, middleBracketTexture, fullBracketTexture, 
            null, null, false, null);
            
            // Make sure there is some padding to the edges
            var horizontalPadding : Float = 5;
            bracketView.resizeToLength(hitArea.width - 2 * horizontalPadding);
            bracketView.x = horizontalPadding;
            
            // Make sure the bracket fits the height constraints
            if (bracketView.height > hitArea.height) 
            {
                bracketView.scaleY = hitArea.height / bracketView.height;
            }
            
            hitAreaGraphics[i].addChild(bracketView);
        }
    }
    
    private function calculateHitAreas() : Void
    {
        // Clear out previous active hit areas and return them to the pool
        m_hitAreaPool.returnRectangles(m_addNewHorizontalBarLabelHitAreas);
        
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        
        // Check horizontalBar hitArea for each bar segment hit area, if any found then return first
        // The hit area lies on top of the bar
        var hitAreaX : Float = 0;
        var hitAreaY : Float = 0;
        var hitAreaWidth : Float = 0;
        var hitAreaHeight : Float = 0;
        var hitBarWholeView : BarWholeView = null;
        for (i in 0...numBarWholeViews){
            var thisBarView : BarWholeView = barWholeViews[i];
            
            // Make sure there is no limit to the number of brackets that can be added
            var allowAddLabelToBarWhole : Bool = true;
            if (m_maxBracketsPerBar > 0) 
            {
                var labelViews : Array<BarLabelView> = thisBarView.labelViews;
                var numLabelViews : Int = labelViews.length;
                var j : Int = 0;
                var numBracketLabels : Int = 0;
                for (j in 0...numLabelViews){
                    if (labelViews[j].data.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                    {
                        numBracketLabels++;
                    }
                }
                
                allowAddLabelToBarWhole = m_maxBracketsPerBar > numBracketLabels;
            }
            
            if (allowAddLabelToBarWhole) 
            {
                var segmentViews : Array<BarSegmentView> = thisBarView.segmentViews;
                var segmentViewSampleBound : Rectangle = segmentViews[0].rigidBody.boundingRectangle;
                var topBound : Float = segmentViewSampleBound.bottom;
                var leftBound : Float = segmentViewSampleBound.left;
                var rightBound : Float = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle.right;
                
                // The height of the hit area is proportional to the gap, however
                // we limit it to be no larger than the height of the bar segment to prevent ugly overflow
                // of this hit area to bar BELOW it once the bar scales vertically
                var boundHeight : Float = Math.min(m_barModelArea.barGap, segmentViewSampleBound.height);
                
                hitAreaX = leftBound;
                hitAreaY = topBound;
                hitAreaWidth = rightBound - leftBound;
                hitAreaHeight = boundHeight;
                
                // Grab a rectangle from the pool
                var labelHitArea : Rectangle = m_hitAreaPool.getRectangle();
                labelHitArea.setTo(hitAreaX, hitAreaY, hitAreaWidth, hitAreaHeight);
                m_addNewHorizontalBarLabelHitAreas.push(labelHitArea);
            }
        }
    }
    
    /**
     * 
     * @param outParams
     *      The first index is the target bar view, the second is boolean that is true if hit on the top
     */
    private function checkHitArea(outParams : Array<Dynamic>) : Bool
    {
        // Hit areas need to adjust based on number of bars
        this.calculateHitAreas();
        var didHitArea : Bool = false;
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var i : Int = 0;
        var numHitAreas : Int = m_addNewHorizontalBarLabelHitAreas.length;
        var hitArea : Rectangle = null;
        for (i in 0...numHitAreas){
            hitArea = m_addNewHorizontalBarLabelHitAreas[i];
            if (hitArea.containsPoint(m_localMouseBuffer)) 
            {
                outParams.push(barWholeViews[i]);
                outParams.push(false);
                
                didHitArea = true;
                break;
            }
        }
        
        return didHitArea;
    }
    
    private function addNewHorizontalBracket(targetBarWhole : BarWhole, value : String, endIndex : Int, isTop : Bool, id : String = null) : Void
    {
        var newBarLabel : BarLabel = new BarLabel(value, 0, endIndex, true, isTop, BarLabel.BRACKET_STRAIGHT, null, id);
        targetBarWhole.barLabels.unshift(newBarLabel);
    }
}
