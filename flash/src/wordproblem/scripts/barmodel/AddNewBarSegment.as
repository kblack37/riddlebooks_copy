package wordproblem.scripts.barmodel
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.BarModelDataUtil;
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarLabel;
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
     * This script handles the adding of a new bar segments at the end of an existing whole bar
     */
    public class AddNewBarSegment extends BaseBarModelScript implements IHitAreaScript, ICardOnSegmentEdgeScript
    {
        private static const PREVIEW_NEW_BAR_SEGMENT_ID:String = "preview_new_segment";
        
        private var m_outParamsBuffer:Vector.<Object>;
        
        /**
         * The color that is used for the preview should be the same one used when the actual
         * segment is created.
         */
        private var m_previewColor:uint;
        
        /**
         * Keep a constantly updated list of the appropriate hit areas for each whole bar.
         * These are kept at the same index as the bar whole views
         */
        private var m_addNewBarSegmentHitAreas:Vector.<Rectangle>;
        
        private var m_hitAreaPool:Vector.<Rectangle>;
        
        /**
         * Used to check the last bar whole the preview of the new segment was added to
         */
        private var m_targetBarWholeIdInPreview:String;
        
        /**
         * For tutorial level we may want the addition of a new segment to trigger several other changes.
         * For example, it would auto-resize the label to fit the new segment
         */
        private var m_customAddNewBarSegmentFunction:Function;
        
        /**
         * Should hit areas for this action be shown in at the start of a frame
         */
        private var m_showHitAreas:Boolean;
        private var m_bufferedExtraDragParams:Object;
        
        /**
         *
         * @param customAddNewBarSegment
         *      Signature callback(barModelData:BarModelData, targetBarWhole:BarWhole, data:String, color:uint, addLabelOnTop:Boolean, id:String=null):void
         */
        public function AddNewBarSegment(gameEngine:IGameEngine, 
                                         expressionCompiler:IExpressionTreeCompiler, 
                                         assetManager:AssetManager, 
                                         id:String=null, 
                                         isActive:Boolean=true, 
                                         customAddNewBarSegmentFunction:Function=null)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_outParamsBuffer = new Vector.<Object>();
            m_previewColor = 0xFFFFFF;
            
            m_addNewBarSegmentHitAreas = new Vector.<Rectangle>();
            m_hitAreaPool = new Vector.<Rectangle>();
            
            m_customAddNewBarSegmentFunction = (customAddNewBarSegmentFunction != null) ? customAddNewBarSegmentFunction : addNewBarSegment;
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            m_showHitAreas = false;
            if (m_ready && m_isActive)
            {
                m_outParamsBuffer.length = 0;
                
                var mouseState:MouseState = m_gameEngine.getMouseState();
                m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                
                if (m_eventTypeBuffer.length > 0)
                {
                    if (checkHitArea(m_outParamsBuffer))
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        m_targetBarWholeIdInPreview = null;
                        
                        var data:Object = m_eventParamBuffer[0];
                        var releasedWidget:BaseTermWidget = data.widget;
                        var releasedExpressionNode:ExpressionNode = releasedWidget.getNode();
                        var targetBarWhole:BarWhole = m_outParamsBuffer[0] as BarWhole;
                        
                        performAction(releasedWidget, m_bufferedExtraDragParams, targetBarWhole.id);
                        m_bufferedExtraDragParams = null;

                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null)
                {
                    m_showHitAreas = true;
                    if (checkHitArea(m_outParamsBuffer))
                    {
                        targetBarWhole = m_outParamsBuffer[0] as BarWhole;
                        
                        // This check shows the preview if either it was not showing already OR a lower priority
                        // script had activated it but we want to overwrite it.
                        // Also redraw the preview if the hit bar is different
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview || m_targetBarWholeIdInPreview != targetBarWhole.id)
                        {
                            var draggedWidget:BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
                            
                            // Find the corresponding bar in the preview
                            m_targetBarWholeIdInPreview = targetBarWhole.id;
                            var extraDragParams:Object = m_widgetDragSystem.getExtraParams();
                            m_bufferedExtraDragParams = extraDragParams;
                            
                            this.showPreview(draggedWidget, extraDragParams, m_targetBarWholeIdInPreview);
                            m_didActivatePreview = true;
                            
                            // Hide the dragged card
                            super.setDraggedWidgetVisible(false);
                        }
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    else if (m_didActivatePreview)
                    {
                        // Hide the preview if it exists (only do so if this script activates the preview)
                        this.hidePreview();
                        m_didActivatePreview = false;
                        m_targetBarWholeIdInPreview = null;
                        
                        // Make dragged card visible again
                        super.setDraggedWidgetVisible(true);
                    }
                }
            }
            return status;
        }
        
        override public function reset():void
        {
            super.reset();
            
            m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_BAR_SEGMENT_ID);
        }
        
        /**
         * Determine whether the buffered release event was within the hit area
         * 
         * @param outParams
         *      First index is the target whole bar object if hit
         * @return
         *      true if the mouse hit the designated area and successfully triggered the action
         */
        private function checkHitArea(outParams:Vector.<Object>):Boolean
        {
            // If the player drags a card to the left of the final segment in a whole bar then
            // we add a brand new segment at the very end of that bar.
            // The hit box has the same height as the bar and either a arbitrary width if it is the longest bar
            // or width equal to the difference of the widths of the target bar and the longest bar
            var targetBarWhole:BarWhole = null;
            
            var modelAreaBounds:Rectangle = m_barModelArea.getBounds(m_barModelArea);
            if (modelAreaBounds.containsPoint(m_localMouseBuffer))
            {
                this.calculateHitAreas();
                var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
                var numHitAreas:int = m_addNewBarSegmentHitAreas.length;
                var i:int;
                var hitArea:Rectangle;
                for (i = 0; i < numHitAreas; i++)
                {
                    hitArea = m_addNewBarSegmentHitAreas[i];
                    if (hitArea.containsPoint(m_localMouseBuffer))
                    {
                        targetBarWhole = barWholeViews[i].data;
                        outParams.push(targetBarWhole);
                        break;
                    }
                }
            }
            
            return (targetBarWhole != null);
        }
        
        /**
         * Exposed this so other scripts can visualize where each hit area is located.
         * This is by default not part of this script since hit area graphics can quickly clutter the screen
         * 
         * @return
         *      List of hit boxes (DO NOT MODIFY THE LIST OR CONTENTS)
         */
        public function getActiveHitAreas():Vector.<Rectangle>
        {
            calculateHitAreas();
            return m_addNewBarSegmentHitAreas;
        }
        
        public function getShowHitAreasForFrame():Boolean
        {
            return m_showHitAreas;
        }
        
        public function postProcessHitAreas(hitAreas:Vector.<Rectangle>, hitAreaGraphics:Vector.<DisplayObjectContainer>):void
        {
            for (var i:int = 0; i < hitAreas.length; i++)
            {
                var icon:Image = new Image(m_assetManager.getTexture("add"));
                var hitArea:Rectangle = hitAreas[i];
                icon.pivotX = icon.width * 0.5;
                icon.pivotY = icon.height * 0.5;
                icon.x = hitArea.width * 0.5;
                icon.y = hitArea.height * 0.5;
                hitAreaGraphics[i].addChild(icon);
            }
        }
        
        private function calculateHitAreas():void
        {
            // Clear out previous active hit areas and return them to the pool
            while (m_addNewBarSegmentHitAreas.length > 0)
            {
                m_hitAreaPool.push(m_addNewBarSegmentHitAreas.pop());
            }
            
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var i:int;
            var barWholeView:BarWholeView;
            var numBarWholeViews:int = barWholeViews.length;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = barWholeViews[i];
                
                var segmentViews:Vector.<BarSegmentView> = barWholeView.segmentViews;
                var hitAreaX:Number = 0;
                var hitAreaY:Number = 0;
                var hitAreaWidth:Number = 0;
                var hitAreaHeight:Number = 0;
                if (segmentViews.length > 0)
                {
                    // Depending on the device, this hit area
                    
                    // The right edge of the last segment view acts as the anchor point
                    var lastSegmentViewBounds:Rectangle = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle;
                    var firstSegmentViewBounds:Rectangle = segmentViews[0].rigidBody.boundingRectangle;
                    var rightOffsetXFromAnchor:Number = 40;
                    var xInsetIntoSegment:Number = 20;
                    var maxHeight:Number = lastSegmentViewBounds.height * 1.5;
                    hitAreaX = lastSegmentViewBounds.right - xInsetIntoSegment;
                    hitAreaY = lastSegmentViewBounds.top - (maxHeight - lastSegmentViewBounds.height) * 0.5;
                    hitAreaWidth = rightOffsetXFromAnchor + xInsetIntoSegment;
                    hitAreaHeight = maxHeight;
                }
                
                // Grab a rectangle from the pool
                var segmentHitArea:Rectangle = (m_hitAreaPool.length > 0) ? m_hitAreaPool.pop() : new Rectangle();
                segmentHitArea.setTo(hitAreaX, hitAreaY, hitAreaWidth, hitAreaHeight);
                m_addNewBarSegmentHitAreas.push(segmentHitArea);
            }
        }
        
        public function addNewBarSegment(barModelData:BarModelData, 
                                         targetBarWhole:BarWhole, 
                                         data:String, 
                                         color:uint, 
                                         labelOnTop:String, 
                                         id:String=null):void
        {
            var value:Number = parseFloat(data);
            var barSegmentWidth:Number = 0;
            
            // Make non-numeric values into segments of unit one by default
            var targetNumeratorValue:Number = 1;
            var targetDenominatorValue:Number = 1;
            if (!isNaN(value))
            {
                // Possible the data is a negative value, we do not take this as affecting
                targetNumeratorValue = Math.abs(value);
                targetDenominatorValue = m_barModelArea.normalizingFactor;
            }
            else
            {
                // Check later if the non-numeric values have a value it should bind to
                var termToValueMap:Object = m_gameEngine.getCurrentLevel().termValueToBarModelValue;
                if (termToValueMap != null && termToValueMap.hasOwnProperty(data))
                {
                    targetNumeratorValue = termToValueMap[data];
                    targetDenominatorValue = m_barModelArea.normalizingFactor;
                }
            }
            
            var newBarSegment:BarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, color, null, id);
            targetBarWhole.barSegments.push(newBarSegment);
            
            if (labelOnTop != null)
            {
                var newBarSegmentIndex:int = targetBarWhole.barSegments.length - 1;
                var newBarLabel:BarLabel = new BarLabel(labelOnTop, newBarSegmentIndex, newBarSegmentIndex, true, false, BarLabel.BRACKET_NONE, null);
                targetBarWhole.barLabels.push(newBarLabel);
            }
            
            // If the addition of the new segment causes the comparison to no longer be correct,
            // it must be deleted OR comparison no longer is attached to a single bar
            // To do this we check if the value of the target bar exceed the value of the other one
            // If this is detected than the comparison must be removed because we are under the assumption the comparison
            // is always attached to the shorter bar.
            if (targetBarWhole.barComparison != null)
            {
                var barComparison:BarComparison = targetBarWhole.barComparison;
                var otherBarWhole:BarWhole = barModelData.getBarWholeById(barComparison.barWholeIdComparedTo);
                var totalValueUpToIndex:Number = otherBarWhole.getValue(0, barComparison.segmentIndexComparedTo);
                
                // Check if the value of the target bar whole now exceeds the value up to the segment index that was compared against
                if (totalValueUpToIndex <= targetBarWhole.getValue())
                {
                    targetBarWhole.barComparison = null;
                }
            }
        }
        
        public function canPerformAction(draggedWidget:DisplayObject, barWholeId:String):Boolean
        {
            // Can perform the add as long as the bar whole container exists
            return m_barModelArea.getBarModelData().getBarWholeById(barWholeId) != null;
        }
        
        public function performAction(draggedWidget:DisplayObject, extraParams:Object, barWholeId:String):void
        {
            // Dispose the preview if it was shown
            hidePreview();
            
            if (draggedWidget is BaseTermWidget)
            {
                var cardValue:String = (draggedWidget as BaseTermWidget).getNode().data;
                var targetBarWhole:BarWhole = m_barModelArea.getBarModelData().getBarWholeById(barWholeId);
                if (targetBarWhole != null)
                {
                    var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                    m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                    
                    var labelOnTop:String = null;
                    if (draggedWidget is SymbolTermWidget)
                    {
                        labelOnTop = cardValue;
                    }
                    else if (extraParams.hasOwnProperty("label"))
                    {
                        labelOnTop = extraParams["label"];
                    }
                    var color:uint = getBarColor(labelOnTop, extraParams);
                    m_customAddNewBarSegmentFunction(m_barModelArea.getBarModelData(), targetBarWhole, cardValue, color, labelOnTop);
                    
                    if (m_gameEngine.getCurrentLevel().getLevelRules().autoResizeHorizontalBrackets)
                    {
                        BarModelDataUtil.stretchHorizontalBrackets(m_barModelArea.getBarModelData());
                    }
                    
                    // Redraw at the end to refresh
                    m_barModelArea.redraw();
                    
                    // Log action
                    m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_SEGMENT, false, {
                        barModel:m_barModelArea.getBarModelData().serialize(),
                        value:cardValue
                    }); 
                }
            }
        }
        
        public function showPreview(draggedWidget:DisplayObject, extraParams:Object, barWholeId:String):void
        {
            if (draggedWidget is BaseTermWidget)
            {
                var cardValue:String = (draggedWidget as BaseTermWidget).getNode().data;
                var targetBarWholeView:BarWhole = m_barModelArea.getBarModelData().getBarWholeById(barWholeId);
                
                var previewView:BarModelView = m_barModelArea.getPreviewView(true);
                var previewTargetBarWhole:BarWhole = previewView.getBarModelData().getBarWholeById(barWholeId);
                
                var labelOnTop:String = null;
                if (draggedWidget is SymbolTermWidget)
                {
                    labelOnTop = cardValue;
                }
                else if (extraParams.hasOwnProperty("label"))
                {
                    labelOnTop = extraParams["label"];
                }
                
                var color:uint = getBarColor(labelOnTop, extraParams);
                m_customAddNewBarSegmentFunction(previewView.getBarModelData(), previewTargetBarWhole, cardValue, color, labelOnTop, PREVIEW_NEW_BAR_SEGMENT_ID);
                
                if (m_gameEngine.getCurrentLevel().getLevelRules().autoResizeHorizontalBrackets)
                {
                    BarModelDataUtil.stretchHorizontalBrackets(previewView.getBarModelData());
                }
                
                m_barModelArea.showPreview(true);
                
                // Blink the newly added segment
                var newBarSegmentView:BarSegmentView = previewView.getBarSegmentViewById(PREVIEW_NEW_BAR_SEGMENT_ID);
                m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(PREVIEW_NEW_BAR_SEGMENT_ID));
                var renderComponent:RenderableComponent = new RenderableComponent(PREVIEW_NEW_BAR_SEGMENT_ID);
                renderComponent.view = newBarSegmentView;
                m_barModelArea.componentManager.addComponentToEntity(renderComponent);
            }
        }
        
        public function hidePreview():void
        {
            m_barModelArea.showPreview(false);
            
            // Remove blink from added preview
            m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_BAR_SEGMENT_ID);
        }
    }
}