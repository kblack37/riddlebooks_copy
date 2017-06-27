package wordproblem.scripts.barmodel
{
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
    
    public class ReplaceHiddenBarLabel extends BaseBarModelScript
    {
        /**
         * On a given frame what is the segment id that was hit.
         */
        private var m_hitBarLabelId:String;
        
        /**
         * The first index is the bar label object
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        /**
         * Temp buffer to store the bounds of the label description
         */
        private var m_labelDescriptionBounds:Rectangle;
        
        public function ReplaceHiddenBarLabel(gameEngine:IGameEngine, 
                                              expressionCompiler:IExpressionTreeCompiler, 
                                              assetManager:AssetManager, 
                                              id:String=null, 
                                              isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
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
                
                if (m_bufferedEventTypes.length > 0)
                {
                    var data:Object = m_bufferedEventParams[0];
                    var releasedWidget:BaseTermWidget = data[0];
                    var releasedWidgetOrigin:String = data[1];
                    
                    if (checkHitHidden(releasedWidget.getNode().data, m_outParamsBuffer))
                    {
                        var hitBarLabel:BarLabel = m_outParamsBuffer[0] as BarLabel;
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        unhideBarLabel(m_barModelArea.getBarModelData(), hitBarLabel.id);
                        m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        
                        m_barModelArea.layout();
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null)
                {
                    var draggedWidget:BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
                    if (checkHitHidden(draggedWidget.getNode().data, m_outParamsBuffer))
                    {
                        hitBarLabel = m_outParamsBuffer[0] as BarLabel;
                        
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview || m_hitBarLabelId != hitBarLabel.id)
                        {
                            m_hitBarLabelId = hitBarLabel.id;
                            
                            var previewBarModelView:BarModelView = m_barModelArea.getPreviewView(true);
                            unhideBarLabel(previewBarModelView.getBarModelData(), hitBarLabel.id);
                            m_barModelArea.showPreview(true);
                            
                            // Blink the previously hidden label
                            var unhiddenBarLabelView:BarLabelView = previewBarModelView.getBarLabelViewById(m_hitBarLabelId);
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(m_hitBarLabelId));
                            var renderComponent:RenderableComponent = new RenderableComponent(m_hitBarLabelId);
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
        
        override public function reset():void
        {
            super.reset();
            
            if (m_hitBarLabelId != null)
            {
                m_barModelArea.componentManager.removeAllComponentsFromEntity(m_hitBarLabelId);
                m_hitBarLabelId = null;
            }
        }
        
        private function checkHitHidden(dataToMatch:String, outParams:Vector.<Object>):Boolean
        {
            var hitHidden:Boolean = false;
            
            // Go through all hidden labels that are contained within a bar
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
                        // The hit area for a hidden label does not include the bracket so the ridgid body
                        // property is not usable in this instance
                        var labelDescriptionDisplay:DisplayObject = barLabelView.getDescriptionDisplay();
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
        
        private function unhideBarLabel(barModelData:BarModelData, barLabelId:String):void
        {
            // Need to determine whether it was a vertical label or a label attached
            // to a bar.
            var foundBar:Boolean = false;
            var numBarWholes:int = barModelData.barWholes.length;
            var i:int;
            for (i = 0; i < numBarWholes; i++)
            {
                var barLabels:Vector.<BarLabel> = barModelData.barWholes[i].barLabels;
                var numBarLabels:int = barLabels.length;
                var j:int;
                var barLabel:BarLabel;
                for (j = 0; j < numBarLabels; j++)
                {
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
                var numVerticalLabels:int = barModelData.verticalBarLabels.length;
                var verticalBarLabel:BarLabel;
                for (i = 0; i < numVerticalLabels; i++)
                {
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
}