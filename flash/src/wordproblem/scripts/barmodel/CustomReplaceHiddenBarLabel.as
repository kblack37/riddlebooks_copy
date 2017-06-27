package wordproblem.scripts.barmodel
{
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
    public class CustomReplaceHiddenBarLabel extends BaseBarModelScript
    {
        /**
         * Callback to the level script to check that a given value over a particular
         * bar segment should allow for replacement to show (either for preview or for
         * real modifications)
         * 
         * params-bar label id, boolean of whether label is vertical, data of card over the segment
         * return- true if a valid replacement is possible
         */
        private var m_checkReplacementValidCallback:Function;
        
        /**
         * Callback to the level script to apply a change
         * 
         * params-bar label id, boolean of whether label is vertical, data of card over the segment, barModelData to apply change to
         */
        private var m_applyReplacementCallback:Function;
        
        /**
         * The first index is the bar label id that was hit, second is boolean that is true if bar is a vertical
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        /**
         * Temp buffer to store the bounds of the label description
         */
        private var m_labelDescriptionBounds:Rectangle;
        
        public function CustomReplaceHiddenBarLabel(gameEngine:IGameEngine, 
                                                    expressionCompiler:IExpressionTreeCompiler, 
                                                    assetManager:AssetManager,
                                                    checkReplacementValidCallback:Function,
                                                    applyReplacementCallback:Function,
                                                    id:String=null, 
                                                    isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_checkReplacementValidCallback = checkReplacementValidCallback;
            m_applyReplacementCallback = applyReplacementCallback;
            m_outParamsBuffer = new Vector.<Object>();
            m_labelDescriptionBounds = new Rectangle();
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            if (m_ready)
            {
                var mouseState:MouseState = m_gameEngine.getMouseState();
                m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                m_outParamsBuffer.length = 0;
                
                if (m_eventTypeBuffer.length > 0)
                {
                    if (checkHitLabel(m_outParamsBuffer))
                    {
                        // Remove preview on release
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        this.setDraggedWidgetVisible(true);
                        
                        var hitLabelId:String = m_outParamsBuffer[0] as String;
                        var isVertical:Boolean = m_outParamsBuffer[1] as Boolean;
                        var eventParam:Object = m_eventParamBuffer[0];
                        var dataToAdd:String = (eventParam.widget as BaseTermWidget).getNode().data;
                        
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        m_applyReplacementCallback(hitLabelId, isVertical, dataToAdd, m_barModelArea.getBarModelData());
                        m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        
                        m_barModelArea.redraw();
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null)
                {
                    var noValidReplacementOnFrame:Boolean = false;
                    if (checkHitLabel(m_outParamsBuffer))
                    {
                        hitLabelId = m_outParamsBuffer[0] as String;
                        isVertical = m_outParamsBuffer[1] as Boolean;
                        dataToAdd = m_widgetDragSystem.getWidgetSelected().getNode().data;
                        if (m_checkReplacementValidCallback(hitLabelId, isVertical, dataToAdd))
                        {
                            if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview)
                            {
                                // Show a preview with fill in
                                var previewBarModelView:BarModelView = m_barModelArea.getPreviewView(true);
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
        
        private function checkHitLabel(outParams:Vector.<Object>):Boolean
        {
            var hitHidden:Boolean = false;
            
            // Iterate through every bar label (including verticals) and check if a hidden portion is selected
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var numBarWholeViews:int = barWholeViews.length;
            var i:int;
            var barWholeView:BarWholeView;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = barWholeViews[i];
                
                var barLabelViews:Vector.<BarLabelView> = barWholeView.labelViews;
                var numBarLabelViews:int = barLabelViews.length;
                var j:int;
                var barLabelView:BarLabelView;
                for (j = 0; j < numBarLabelViews; j++)
                {
                    barLabelView = barLabelViews[j];
                    
                    if (barLabelView.data.hiddenValue != null)
                    {
                        barLabelView.getDescriptionDisplay().getBounds(m_barModelArea, m_labelDescriptionBounds);
                        if (m_labelDescriptionBounds.containsPoint(m_localMouseBuffer))
                        {
                            outParams.push(barLabelView.data.id, false);
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
            
            // Check vertical labels
            if (!hitHidden)
            {
                var verticalBarLabelViews:Vector.<BarLabelView> = m_barModelArea.getVerticalBarLabelViews();
                var numVerticalBarLabelViews:int = verticalBarLabelViews.length;
                for (i = 0; i < numVerticalBarLabelViews; i++)
                {
                    barLabelView = verticalBarLabelViews[i];
                    
                    if (barLabelView.data.hiddenValue != null)
                    {
                        barLabelView.getDescriptionDisplay().getBounds(m_barModelArea, m_labelDescriptionBounds);
                        if (m_labelDescriptionBounds.containsPoint(m_localMouseBuffer))
                        {
                            outParams.push(barLabelView.data.id, true);
                            hitHidden = true;
                            break;
                        }
                    }
                }
            }
            
            return hitHidden;
        }
    }
}