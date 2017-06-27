package wordproblem.scripts.barmodel
{
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
    public class CustomReplaceHiddenBarSegment extends BaseBarModelScript
    {
        /**
         * Callback to the level script to check that a given value over a particular
         * bar segment should allow for replacement to show (either for preview or for
         * real modifications)
         * 
         * params-bar segment id, data of card over the segment
         * return- true if a valid replacement is possible
         */
        private var m_checkReplacementValidCallback:Function;
        
        /**
         * Callback to the level script to apply a change
         */
        private var m_applyReplacementCallback:Function;
        
        /**
         * The first index is the bar segment id that was hit
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        public function CustomReplaceHiddenBarSegment(gameEngine:IGameEngine, 
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
                    if (checkHitSegment(m_outParamsBuffer))
                    {
                        // Remove preview on release
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        this.setDraggedWidgetVisible(true);
                        
                        var hitSegmentId:String = m_outParamsBuffer[0] as String;
                        var eventParam:Object = m_eventParamBuffer[0];
                        var dataToAdd:String = (eventParam.widget as BaseTermWidget).getNode().data;
                        
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        m_applyReplacementCallback(hitSegmentId, dataToAdd, m_barModelArea.getBarModelData());
                        m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        
                        m_barModelArea.redraw();
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null)
                {
                    var noValidReplacementOnFrame:Boolean = false;
                    if (checkHitSegment(m_outParamsBuffer))
                    {
                        hitSegmentId = m_outParamsBuffer[0] as String;
                        dataToAdd = m_widgetDragSystem.getWidgetSelected().getNode().data;
                        if (m_checkReplacementValidCallback(hitSegmentId, dataToAdd))
                        {
                            if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview)
                            {
                                // Show a preview with fill in
                                var previewBarModelView:BarModelView = m_barModelArea.getPreviewView(true);
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
        
        override public function reset():void
        {
            super.reset();
            /*
            if (m_hitBarSegmentId != null)
            {
                m_barModelArea.componentManager.removeAllComponentsFromEntity(m_hitBarSegmentId);
            }
            */
        }
        
        private function checkHitSegment(outParams:Vector.<Object>):Boolean
        {
            var hitHidden:Boolean = false;
            
            // Iterate through every bar and check if a hidden portion is selected
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var numBarWholeViews:int = barWholeViews.length;
            var i:int;
            var barWholeView:BarWholeView;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = barWholeViews[i];
                
                var barSegmentViews:Vector.<BarSegmentView> = barWholeView.segmentViews;
                var numBarSegmentViews:int = barSegmentViews.length;
                var j:int;
                var barSegmentView:BarSegmentView;
                for (j = 0; j < numBarSegmentViews; j++)
                {
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
}