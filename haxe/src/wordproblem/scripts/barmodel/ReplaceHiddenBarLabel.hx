package wordproblem.scripts.barmodel;


import flash.geom.Rectangle;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.component.BlinkComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

class ReplaceHiddenBarLabel extends BaseBarModelScript
{
    /**
     * On a given frame what is the segment id that was hit.
     */
    private var m_hitBarLabelId : String;
    
    /**
     * The first index is the bar label object
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * Temp buffer to store the bounds of the label description
     */
    private var m_labelDescriptionBounds : Rectangle;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
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
            
            if (m_bufferedEventTypes.length > 0) 
            {
                var data : Dynamic = m_bufferedEventParams[0];
                var releasedWidget : BaseTermWidget = data[0];
                var releasedWidgetOrigin : String = data[1];
                
                if (checkHitHidden(releasedWidget.getNode().data, m_outParamsBuffer)) 
                {
                    var hitBarLabel : BarLabel = try cast(m_outParamsBuffer[0], BarLabel) catch(e:Dynamic) null;
                    var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                    unhideBarLabel(m_barModelArea.getBarModelData(), hitBarLabel.id);
                    m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
                                previousSnapshot : previousModelDataSnapshot

                            });
                    
                    m_barModelArea.layout();
                    
                    status = ScriptStatus.SUCCESS;
                }
                
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected() != null) 
            {
                var draggedWidget : BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
                if (checkHitHidden(draggedWidget.getNode().data, m_outParamsBuffer)) 
                {
                    hitBarLabel = try cast(m_outParamsBuffer[0], BarLabel) catch(e:Dynamic) null;
                    
                    if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview || m_hitBarLabelId != hitBarLabel.id) 
                    {
                        m_hitBarLabelId = hitBarLabel.id;
                        
                        var previewBarModelView : BarModelView = m_barModelArea.getPreviewView(true);
                        unhideBarLabel(previewBarModelView.getBarModelData(), hitBarLabel.id);
                        m_barModelArea.showPreview(true);
                        
                        // Blink the previously hidden label
                        var unhiddenBarLabelView : BarLabelView = previewBarModelView.getBarLabelViewById(m_hitBarLabelId);
                        m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(m_hitBarLabelId));
                        var renderComponent : RenderableComponent = new RenderableComponent(m_hitBarLabelId);
                        renderComponent.view = unhiddenBarLabelView;
                        m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                        
                        m_didActivatePreview = true;
                        this.setDraggedWidgetVisible(false);
                    }
                    
                    status = ScriptStatus.SUCCESS;
                }
                else if (m_didActivatePreview) 
                {
                    m_barModelArea.showPreview(false);
                    m_didActivatePreview = false;
                    m_barModelArea.componentManager.removeAllComponentsFromEntity(m_hitBarLabelId);
                    m_hitBarLabelId = null;
                    this.setDraggedWidgetVisible(true);
                }
            }
        }
        
        return status;
    }
    
    override public function reset() : Void
    {
        super.reset();
        
        if (m_hitBarLabelId != null) 
        {
            m_barModelArea.componentManager.removeAllComponentsFromEntity(m_hitBarLabelId);
            m_hitBarLabelId = null;
        }
    }
    
    private function checkHitHidden(dataToMatch : String, outParams : Array<Dynamic>) : Bool
    {
        var hitHidden : Bool = false;
        
        // Go through all hidden labels that are contained within a bar
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        var i : Int;
        var barWholeView : BarWholeView;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            
            var barLabelViews : Array<BarLabelView> = barWholeView.labelViews;
            var numBarLabelViews : Int = barLabelViews.length;
            var j : Int;
            var barLabelView : BarLabelView;
            for (j in 0...numBarLabelViews){
                barLabelView = barLabelViews[j];
                if (barLabelView.data.hiddenValue != null) 
                {
                    // The hit area for a hidden label does not include the bracket so the ridgid body
                    // property is not usable in this instance
                    var labelDescriptionDisplay : DisplayObject = barLabelView.getDescriptionDisplay();
                    labelDescriptionDisplay.getBounds(m_barModelArea, m_labelDescriptionBounds);
                    if (m_labelDescriptionBounds.containsPoint(m_localMouseBuffer) && barLabelView.data.hiddenValue == dataToMatch) 
                    {
                        outParams.push(barLabelView.data);
                        hitHidden = true;
                        break;
                    }
                }
            }
            
            if (hitHidden) 
            {
                break;
            }
        }
        
        return hitHidden;
    }
    
    private function unhideBarLabel(barModelData : BarModelData, barLabelId : String) : Void
    {
        // Need to determine whether it was a vertical label or a label attached
        // to a bar.
        var foundBar : Bool = false;
        var numBarWholes : Int = barModelData.barWholes.length;
        var i : Int;
        for (i in 0...numBarWholes){
            var barLabels : Array<BarLabel> = barModelData.barWholes[i].barLabels;
            var numBarLabels : Int = barLabels.length;
            var j : Int;
            var barLabel : BarLabel;
            for (j in 0...numBarLabels){
                barLabel = barLabels[j];
                if (barLabel.id == barLabelId) 
                {
                    barLabel.hiddenValue = null;
                    foundBar = true;
                    break;
                }
            }
            
            if (foundBar) 
            {
                break;
            }
        }
        
        if (!foundBar) 
        {
            var numVerticalLabels : Int = barModelData.verticalBarLabels.length;
            var verticalBarLabel : BarLabel;
            for (i in 0...numVerticalLabels){
                verticalBarLabel = barModelData.verticalBarLabels[i];
                if (verticalBarLabel.id == barLabelId) 
                {
                    verticalBarLabel.hiddenValue = null;
                    break;
                }
            }
        }
    }
}
