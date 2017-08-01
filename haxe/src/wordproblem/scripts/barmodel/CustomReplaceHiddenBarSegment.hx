package wordproblem.scripts.barmodel;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

/**
 * This script is intended to give control to a level about how hidden segments should be replaced
 */
class CustomReplaceHiddenBarSegment extends BaseBarModelScript
{
    /**
     * Callback to the level script to check that a given value over a particular
     * bar segment should allow for replacement to show (either for preview or for
     * real modifications)
     * 
     * params-bar segment id, data of card over the segment
     * return- true if a valid replacement is possible
     */
    private var m_checkReplacementValidCallback : Function;
    
    /**
     * Callback to the level script to apply a change
     */
    private var m_applyReplacementCallback : Function;
    
    /**
     * The first index is the bar segment id that was hit
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
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
                if (checkHitSegment(m_outParamsBuffer)) 
                {
                    // Remove preview on release
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    this.setDraggedWidgetVisible(true);
                    
                    var hitSegmentId : String = try cast(m_outParamsBuffer[0], String) catch(e:Dynamic) null;
                    var eventParam : Dynamic = m_eventParamBuffer[0];
                    var dataToAdd : String = (try cast(eventParam.widget, BaseTermWidget) catch(e:Dynamic) null).getNode().data;
                    
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    m_applyReplacementCallback(hitSegmentId, dataToAdd, m_barModelArea.getBarModelData());
                    m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
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
                if (checkHitSegment(m_outParamsBuffer)) 
                {
                    hitSegmentId = try cast(m_outParamsBuffer[0], String) catch(e:Dynamic) null;
                    dataToAdd = m_widgetDragSystem.getWidgetSelected().getNode().data;
                    if (m_checkReplacementValidCallback(hitSegmentId, dataToAdd)) 
                    {
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview) 
                        {
                            // Show a preview with fill in
                            var previewBarModelView : BarModelView = m_barModelArea.getPreviewView(true);
                            m_applyReplacementCallback(hitSegmentId, dataToAdd, previewBarModelView.getBarModelData());
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
    
    override public function reset() : Void
    {
        super.reset();
    }
    
    private function checkHitSegment(outParams : Array<Dynamic>) : Bool
    {
        var hitHidden : Bool = false;
        
        // Iterate through every bar and check if a hidden portion is selected
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            
            var barSegmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
            var numBarSegmentViews : Int = barSegmentViews.length;
            var j : Int = 0;
            var barSegmentView : BarSegmentView = null;
            for (j in 0...numBarSegmentViews){
                barSegmentView = barSegmentViews[j];
                
                // Check that the segment is hidden and the mouse is over it
                if (barSegmentView.data.hiddenValue != null && barSegmentView.rigidBody.boundingRectangle.containsPoint(m_localMouseBuffer)) 
                {
                    outParams.push(barSegmentView.data.id);
                    hitHidden = true;
                    break;
                }
            }
            
            if (hitHidden) 
            {
                break;
            }
        }
        
        return hitHidden;
    }
}
