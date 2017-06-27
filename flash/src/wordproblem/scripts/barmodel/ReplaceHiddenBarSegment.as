package wordproblem.scripts.barmodel
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.component.BlinkComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script has the logic to detect mouse over a hidden element and replacing it with it's correct value.
     * 
     * (This should only be active for certain tutorial levels)
     */
    public class ReplaceHiddenBarSegment extends BaseBarModelScript
    {
        /**
         * On a given frame what is the segment id that was hit.
         */
        private var m_hitBarSegmentId:String;
        
        /**
         * The first index is the id of the segment that was hit
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        public function ReplaceHiddenBarSegment(gameEngine:IGameEngine, 
                                                expressionCompiler:IExpressionTreeCompiler, 
                                                assetManager:AssetManager, 
                                                id:String=null, 
                                                isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_outParamsBuffer = new Vector.<Object>();
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            if (m_ready && m_isActive)
            {
                status = super.visit();
                var mouseState:MouseState = m_gameEngine.getMouseState();
                m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                m_outParamsBuffer.length = 0;
                
                if (m_bufferedEventTypes.length > 0)
                {
                    var data:Object = m_bufferedEventParams[0];
                    var releasedWidget:BaseTermWidget = data[0];
                    var releasedWidgetOrigin:String = data[1];
                    
                    // If a release occurs, check if the mouse in on top
                    if (checkHitHidden(releasedWidget.getNode().data, m_outParamsBuffer))
                    {
                        var hitHiddenBarSegmentId:String = m_outParamsBuffer[0] as String;
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        unhideBarSegment(m_barModelArea.getBarModelData(), hitHiddenBarSegmentId);
                        m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        
                        m_barModelArea.layout();
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null)
                {
                    // Need to get back the reference to the bar and the segment that was selected
                    if (checkHitHidden(m_widgetDragSystem.getWidgetSelected().getNode().data, m_outParamsBuffer))
                    {
                        hitHiddenBarSegmentId = m_outParamsBuffer[0] as String;
                        
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview || m_hitBarSegmentId != hitHiddenBarSegmentId)
                        {
                            m_hitBarSegmentId = hitHiddenBarSegmentId;
                            
                            // Show a preview with fill in
                            var previewBarModelView:BarModelView = m_barModelArea.getPreviewView(true);
                            unhideBarSegment(previewBarModelView.getBarModelData(), hitHiddenBarSegmentId);
                            m_barModelArea.showPreview(true);
                            
                            // Blink the previously hidden label
                            var unhiddenBarSegmentView:BarSegmentView = previewBarModelView.getBarSegmentViewById(m_hitBarSegmentId);
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(m_hitBarSegmentId));
                            var renderComponent:RenderableComponent = new RenderableComponent(m_hitBarSegmentId);
                            renderComponent.view = unhiddenBarSegmentView;
                            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                            
                            m_didActivatePreview = true;
                            this.setDraggedWidgetVisible(false);
                        }
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    else if (m_didActivatePreview)
                    {
                        // Hide the preview if it exists (only do so if this script activates the preview)
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        m_barModelArea.componentManager.removeAllComponentsFromEntity(m_hitBarSegmentId);
                        m_hitBarSegmentId = null;
                        
                        this.setDraggedWidgetVisible(true);
                    }
                }
            }
            
            return status;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            
        }
        
        override public function reset():void
        {
            super.reset();
            
            if (m_hitBarSegmentId != null)
            {
                m_barModelArea.componentManager.removeAllComponentsFromEntity(m_hitBarSegmentId);
            }
        }
        
        /**
         * Check whether the mouse is over
         */
        private function checkHitHidden(dataToMatch:String, outParams:Vector.<Object>):Boolean
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
                if (barWholeView.data.displayHiddenSegments)
                {
                    for (j = 0; j < numBarSegmentViews; j++)
                    {
                        barSegmentView = barSegmentViews[j];
                        
                        // Check that the segment is hidden and the mouse is over it
                        if (barSegmentView.data.hiddenValue == dataToMatch && barSegmentView.rigidBody.boundingRectangle.containsPoint(m_localMouseBuffer))
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
                else
                {
                    // If not show individual hidden segments, then a hit on any hidden segment will actually try
                    // to match with all other hidden segments
                    for (j = 0; j < numBarSegmentViews; j++)
                    {
                        barSegmentView = barSegmentViews[j];
                        if (barSegmentView.data.hiddenValue != null && barSegmentView.rigidBody.boundingRectangle.containsPoint(m_localMouseBuffer))
                        {
                            var k:int;
                            var otherBarSegmentView:BarSegmentView;
                            for (k = 0; k < numBarSegmentViews; k++)
                            {
                                otherBarSegmentView = barSegmentViews[k];
                                if (otherBarSegmentView.data.hiddenValue == dataToMatch)
                                {
                                    outParams.push(otherBarSegmentView.data.id);
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
                }
            }
            
            return hitHidden;
        }
        
        private function unhideBarSegment(barModelData:BarModelData, barSegmentId:String):void
        {
            var numBarWholes:int = barModelData.barWholes.length;
            var i:int;
            for (i = 0; i < numBarWholes; i++)
            {
                var barSegments:Vector.<BarSegment> = barModelData.barWholes[i].barSegments;
                var numBarSegments:int = barSegments.length;
                var j:int;
                var barSegment:BarSegment;
                for (j = 0; j < numBarSegments; j++)
                {
                    barSegment = barSegments[j];
                    if (barSegment.id == barSegmentId)
                    {
                        barSegment.hiddenValue = null;
                        break;
                    }
                }
            }
        }
    }
}