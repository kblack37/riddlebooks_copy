package wordproblem.scripts.barmodel;


import flash.geom.Rectangle;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

/**
 * This script is intended to give control 
 */
class CustomReplaceHiddenBarLabel extends BaseBarModelScript
{
    /**
     * Callback to the level script to check that a given value over a particular
     * bar segment should allow for replacement to show (either for preview or for
     * real modifications)
     * 
     * params-bar label id, boolean of whether label is vertical, data of card over the segment
     * return- true if a valid replacement is possible
     */
    private var m_checkReplacementValidCallback : Function;
    
    /**
     * Callback to the level script to apply a change
     * 
     * params-bar label id, boolean of whether label is vertical, data of card over the segment, barModelData to apply change to
     */
    private var m_applyReplacementCallback : Function;
    
    /**
     * The first index is the bar label id that was hit, second is boolean that is true if bar is a vertical
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * Temp buffer to store the bounds of the label description
     */
    private var m_labelDescriptionBounds : Rectangle;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            checkReplacementValidCallback : Function,
            applyReplacementCallback : Function,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_checkReplacementValidCallback = checkReplacementValidCallback;
        m_applyReplacementCallback = applyReplacementCallback;
        m_outParamsBuffer = new Array<Dynamic>();
        m_labelDescriptionBounds = new Rectangle();
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            as3hx.Compat.setArrayLength(m_outParamsBuffer, 0);
            
            if (m_eventTypeBuffer.length > 0) 
            {
                if (checkHitLabel(m_outParamsBuffer)) 
                {
                    // Remove preview on release
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    this.setDraggedWidgetVisible(true);
                    
                    var hitLabelId : String = try cast(m_outParamsBuffer[0], String) catch(e:Dynamic) null;
                    var isVertical : Bool = try cast(m_outParamsBuffer[1], Bool) catch(e:Dynamic) null;
                    var eventParam : Dynamic = m_eventParamBuffer[0];
                    var dataToAdd : String = (try cast(eventParam.widget, BaseTermWidget) catch(e:Dynamic) null).getNode().data;
                    
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    m_applyReplacementCallback(hitLabelId, isVertical, dataToAdd, m_barModelArea.getBarModelData());
                    m_gameEngine.dispatchEvent(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
                                previousSnapshot : previousModelDataSnapshot

                            });
                    
                    m_barModelArea.redraw();
                    
                    status = ScriptStatus.SUCCESS;
                }
                
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected() != null) 
            {
                var noValidReplacementOnFrame : Bool = false;
                if (checkHitLabel(m_outParamsBuffer)) 
                {
                    hitLabelId = try cast(m_outParamsBuffer[0], String) catch(e:Dynamic) null;
                    isVertical = try cast(m_outParamsBuffer[1], Bool) catch(e:Dynamic) null;
                    dataToAdd = m_widgetDragSystem.getWidgetSelected().getNode().data;
                    if (m_checkReplacementValidCallback(hitLabelId, isVertical, dataToAdd)) 
                    {
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview) 
                        {
                            // Show a preview with fill in
                            var previewBarModelView : BarModelView = m_barModelArea.getPreviewView(true);
                            m_applyReplacementCallback(hitLabelId, isVertical, dataToAdd, previewBarModelView.getBarModelData());
                            m_barModelArea.showPreview(true);
                            
                            m_didActivatePreview = true;
                            this.setDraggedWidgetVisible(false);
                        }
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    else 
                    {
                        noValidReplacementOnFrame = true;
                    }
                }
                else 
                {
                    noValidReplacementOnFrame = true;
                }
                
                if (noValidReplacementOnFrame && m_didActivatePreview) 
                {
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    this.setDraggedWidgetVisible(true);
                }
            }
        }
        
        return status;
    }
    
    private function checkHitLabel(outParams : Array<Dynamic>) : Bool
    {
        var hitHidden : Bool = false;
        
        // Iterate through every bar label (including verticals) and check if a hidden portion is selected
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            
            var barLabelViews : Array<BarLabelView> = barWholeView.labelViews;
            var numBarLabelViews : Int = barLabelViews.length;
            var j : Int = 0;
            var barLabelView : BarLabelView = null;
            for (j in 0...numBarLabelViews){
                barLabelView = barLabelViews[j];
                
                if (barLabelView.data.hiddenValue != null) 
                {
                    m_labelDescriptionBounds = barLabelView.getDescriptionDisplay().getBounds(m_barModelArea);
                    if (m_labelDescriptionBounds.containsPoint(m_localMouseBuffer)) 
                    {
                        outParams.push(barLabelView.data.id);
                        outParams.push(false);
                        
                        hitHidden = true;
                        break;
                    }
                }
            }
            
            if (hitHidden) 
            {
                break;
            }
        }  // Check vertical labels  
        
        
        
        if (!hitHidden) 
        {
            var verticalBarLabelViews : Array<BarLabelView> = m_barModelArea.getVerticalBarLabelViews();
            var numVerticalBarLabelViews : Int = verticalBarLabelViews.length;
            for (i in 0...numVerticalBarLabelViews){
                barLabelView = verticalBarLabelViews[i];
                
                if (barLabelView.data.hiddenValue != null) 
                {
                    m_labelDescriptionBounds = barLabelView.getDescriptionDisplay().getBounds(m_barModelArea);
                    if (m_labelDescriptionBounds.containsPoint(m_localMouseBuffer)) 
                    {
                        outParams.push(barLabelView.data.id);
                        outParams.push(true);
                        
                        hitHidden = true;
                        break;
                    }
                }
            }
        }
        
        return hitHidden;
    }
}
