package wordproblem.scripts.barmodel
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.component.BlinkComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.SymbolTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script handles the action of changing a label that appears directly on top of a bar segment.
     */
    public class AddNewLabelOnSegment extends BaseBarModelScript implements ICardOnSegmentScript
    {
        private var m_outParamsBuffer:Vector.<Object>;
        
        /**
         * The last index of the segment that is set to be split.
         * Keep track of this so we can detect if mouse is over a new segment without ever leaving the bounds
         * of a bar.
         */
        private var m_targetBarSegmentIndex:int;
        
        /**
         * If true, existing label on top of a segment can be directly replaced by putting a label
         * of a different name.
         */
        private var m_allowReplacement:Boolean = true;
        
        /**
         * If not null, this will point to the label that has been added on top of the preview bar model
         */
        private var m_barLabelIdBlinking:String;
        
        /**
         * If not null, this points to the segment id that has the new label (differs from the above because this way
         * the blinking is more obvious)
         */
        private var m_segmentWithLabelBlinkingId:String;
        
        public function AddNewLabelOnSegment(gameEngine:IGameEngine, 
                                             expressionCompiler:IExpressionTreeCompiler, 
                                             assetManager:AssetManager, 
                                             id:String=null, 
                                             isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_outParamsBuffer = new Vector.<Object>();
            m_targetBarSegmentIndex = -1;
        }
        
        public function canPerformAction(cardValue:String, segmentId:String):Boolean
        {
            var canPerformAction:Boolean = false;
            
            if (m_isActive)
            {
                // Make sure a label does not already exist on top of the target segment
                // The util function requires getting the index of the bar whole and the segment
                var outIndices:Vector.<int> = new Vector.<int>();
                var targetSegment:BarSegment = m_barModelArea.getBarModelData().getBarSegmentById(segmentId, outIndices);
                if (targetSegment != null && (m_restrictedElementIds.length == 0 || m_restrictedElementIds.indexOf(segmentId) > -1))
                {
                    var barLabelIdOnSegment:String = BarModelHitAreaUtil.getBarLabelIdOnTopOfSegment(m_barModelArea, outIndices[0], outIndices[1]);
                    if (!m_allowReplacement)
                    {
                        canPerformAction = (barLabelIdOnSegment == null);
                    }
                    else
                    {
                        var matchingLabel:BarLabel = m_barModelArea.getBarModelData().getBarLabelById(barLabelIdOnSegment);
                        canPerformAction = barLabelIdOnSegment == null || (matchingLabel != null && matchingLabel.value != cardValue);
                    }
                }
            }
            
            return canPerformAction;
        }
        
        public function showPreview(cardValue:String, segmentId:String):void
        {
            var outIndices:Vector.<int> = new Vector.<int>();
            m_barModelArea.getBarModelData().getBarSegmentById(segmentId, outIndices);
            
            var targetBarWholeIndex:int = outIndices[0];
            var targetBarSegmentIndex:int = outIndices[1];
            var previewView:BarModelView = m_barModelArea.getPreviewView(true);
            var color:uint = getColorForTermValue(cardValue);
            addLabelOnTopOfSegment(previewView.getBarModelData(), targetBarWholeIndex, targetBarSegmentIndex, cardValue, null, color);
            m_barModelArea.showPreview(true);
            
            var previewSegmentViewWithLabel:BarSegmentView = previewView.getBarWholeViews()[targetBarWholeIndex].segmentViews[targetBarSegmentIndex];
            var previewSegmentId:String = previewSegmentViewWithLabel.data.id;
            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(previewSegmentId));
            var renderComponent:RenderableComponent = new RenderableComponent(previewSegmentId);
            renderComponent.view = previewSegmentViewWithLabel;
            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
            m_segmentWithLabelBlinkingId = previewSegmentId;
        }
        
        public function hidePreview():void
        {
            m_barModelArea.showPreview(false);
            
            if (m_segmentWithLabelBlinkingId)
            {
                m_barModelArea.componentManager.removeAllComponentsFromEntity(m_segmentWithLabelBlinkingId);
                m_segmentWithLabelBlinkingId = null;
            }
        }
        
        public function performAction(cardValue:String, segmentId:String):void
        {
            // Dispose of the preview if it was showing
            hidePreview();
            
            var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
            var barModelData:BarModelData = m_barModelArea.getBarModelData();
            var outIndices:Vector.<int> = new Vector.<int>();
            barModelData.getBarSegmentById(segmentId, outIndices);
            
            var color:uint = getColorForTermValue(cardValue);
            addLabelOnTopOfSegment(barModelData, outIndices[0], outIndices[1], cardValue, null, color);
            m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
            
            // Redraw at the end to refresh
            m_barModelArea.redraw();
            
            // Log splitting on an existing segment
            m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_LABEL_ON_BAR_SEGMENT, false, {
                barModel:m_barModelArea.getBarModelData().serialize(),
                value:cardValue
            });
        }
        
        public function getName():String
        {
            return m_id;
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            if (m_ready && m_isActive)
            {
                m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                
                m_outParamsBuffer.length = 0;
                if (m_eventTypeBuffer.length > 0)
                {
                    var args:Object = m_eventParamBuffer[0];
                    var releasedWidget:BaseTermWidget = args.widget;
                    
                    m_didActivatePreview = false;
                    m_barModelArea.showPreview(false);
                    m_targetBarSegmentIndex = -1;
                    
                    if (releasedWidget is SymbolTermWidget && BarModelHitAreaUtil.checkPointInBarSegment(m_outParamsBuffer, m_barModelArea, m_localMouseBuffer))
                    {
                        var targetBarWholeIndex:int = m_outParamsBuffer[0] as int;
                        var targetBarSegmentIndex:int = m_outParamsBuffer[1] as int;
                        var value:String = releasedWidget.getNode().data;
                        var targetBarSegment:BarSegment = m_barModelArea.getBarModelData().barWholes[targetBarWholeIndex].barSegments[targetBarSegmentIndex];
                        
                        // In order to see whether the box would fit we need to apply the change
                        // Give a bar model with target set
                        // Create a clone of it and perform the replace on it
                        if (canPerformAction(value, targetBarSegment.id))
                        {
                            var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                            color = getColorForTermValue(value);
                            addLabelOnTopOfSegment(m_barModelArea.getBarModelData(), targetBarWholeIndex, targetBarSegmentIndex, value, null, color);
                            m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                            
                            // Redraw at the end to refresh
                            m_barModelArea.redraw();
                            
                            // Log replace label on an existing segment
                            m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_LABEL_ON_BAR_SEGMENT, false, {
                                barModel:m_barModelArea.getBarModelData().serialize(),
                                value:value
                            });
                            
                            status = ScriptStatus.SUCCESS;
                        }
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected())
                {
                    releasedWidget = m_widgetDragSystem.getWidgetSelected();
                    if (releasedWidget is SymbolTermWidget && BarModelHitAreaUtil.checkPointInBarSegment(m_outParamsBuffer, m_barModelArea, m_localMouseBuffer))
                    {
                        targetBarWholeIndex = m_outParamsBuffer[0] as int;
                        targetBarSegmentIndex = m_outParamsBuffer[1] as int;
                        value = releasedWidget.getNode().data;
                        targetBarSegment = m_barModelArea.getBarModelData().barWholes[targetBarWholeIndex].barSegments[targetBarSegmentIndex];
                        
                        // This check shows the preview if either it was not showing already OR a lower priority
                        // script had activated it but we want to overwrite it.
                        // This particular action also has a weird case where we don't leave the hit area but have
                        // a different segment in the same bar that we switch to.
                        var mouseOverValidSegment:Boolean = canPerformAction(value, targetBarSegment.id);
                        if (mouseOverValidSegment &&
                            (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview || m_targetBarSegmentIndex != targetBarSegmentIndex))
                        {
                            var previewView:BarModelView = m_barModelArea.getPreviewView(true);
                            var color:uint = getColorForTermValue(value);
                            m_barLabelIdBlinking = addLabelOnTopOfSegment(previewView.getBarModelData(), targetBarWholeIndex, targetBarSegmentIndex, value, null, color);
                            
                            m_didActivatePreview = true;
                            m_barModelArea.showPreview(true);
                            m_targetBarSegmentIndex = targetBarSegmentIndex;
                            super.setDraggedWidgetVisible(false);
                            
                            // The new or replaced label should be blinking
                            var changedBarLabelView:BarLabelView = previewView.getBarLabelViewById(m_barLabelIdBlinking);
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(m_barLabelIdBlinking));
                            var renderComponent:RenderableComponent = new RenderableComponent(m_barLabelIdBlinking);
                            renderComponent.view = changedBarLabelView;
                            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                        }
                        
                        if (mouseOverValidSegment)
                        {
                            status = ScriptStatus.SUCCESS;
                        }
                        // The branch fixes the case when two segments are next to each other and one has a label on top and the other
                        // doesn't. If we switch from the unlabeled to the label segment, the old preview label is stuck
                        else if (m_didActivatePreview)
                        {
                            m_barModelArea.showPreview(false);
                            m_didActivatePreview = false;
                            m_targetBarSegmentIndex = -1;
                            super.setDraggedWidgetVisible(true);
                            
                            if (m_barLabelIdBlinking != null)
                            {
                                m_barModelArea.componentManager.removeAllComponentsFromEntity(m_barLabelIdBlinking);
                                m_barLabelIdBlinking = null;
                            }
                        }
                    }
                    else if (m_didActivatePreview)
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        m_targetBarSegmentIndex = -1;
                        super.setDraggedWidgetVisible(true);
                    }
                }
            }
            return status;
        }
        
        /**
         * @return
         *      id of the element that was modified
         */
        public function addLabelOnTopOfSegment(barModelData:BarModelData, 
                                               barWholeIndex:int, 
                                               barSegmentIndex:int, 
                                               value:String, 
                                               id:String=null, 
                                               color:uint=0xFFFFFF):String
        {
            var labelId:String = null;
            var barWholes:Vector.<BarWhole> = barModelData.barWholes;
            var targetBarWhole:BarWhole = barWholes[barWholeIndex];
            
            // The new term value has its own size (which should match up with the size created when adding a new bar or segment)
            // The target segment should change to this new size
            var segmentsInTarget:Vector.<BarSegment> = targetBarWhole.barSegments;
            if (barSegmentIndex >= 0 && barSegmentIndex < segmentsInTarget.length)
            {
                var numericaValue:Number = parseFloat(value);
                
                // Make non-numeric values into segments of unit one by default
                var targetNumeratorValue:Number = 1;
                var targetDenominatorValue:Number = 1;
                if (!isNaN(numericaValue))
                {
                    // Possible the data is a negative value, we do not take this as affecting
                    targetNumeratorValue = Math.abs(numericaValue);
                    targetDenominatorValue = m_barModelArea.normalizingFactor;
                }
                else
                {
                    // Check later if the non-numeric values have a value it should bind to
                    var termToValueMap:Object = (m_gameEngine != null) ? m_gameEngine.getCurrentLevel().termValueToBarModelValue : null;
                    if (termToValueMap != null && termToValueMap.hasOwnProperty(value))
                    {
                        targetNumeratorValue = termToValueMap[value];
                        targetDenominatorValue = m_barModelArea.normalizingFactor;
                    }
                }
                
                var targetSegmentToChange:BarSegment = segmentsInTarget[barSegmentIndex]
                var prevSegmentValue:Number = targetSegmentToChange.getValue();
                
                // Modify the values of the segment
                targetSegmentToChange.denominatorValue = targetDenominatorValue;
                targetSegmentToChange.numeratorValue = targetNumeratorValue;
                targetSegmentToChange.color = color;
                
                // If a label on top already exists, its value should be replaced
                var barLabelAtIndexExists:Boolean = false;
                for each(var barLabel:BarLabel in targetBarWhole.barLabels)
                {
                    if (barLabel.endSegmentIndex == barSegmentIndex && barLabel.startSegmentIndex == barSegmentIndex && barLabel.bracketStyle == BarLabel.BRACKET_NONE)
                    {
                        barLabel.value = value;
                        barLabelAtIndexExists = true;
                        labelId = barLabel.id;
                    }
                }
                
                // Only create a new label if an existing one was not overwritten, otherwise we get duplicates
                if (!barLabelAtIndexExists)
                {
                    var newLabel:BarLabel = new BarLabel(value, barSegmentIndex, barSegmentIndex, true, false, BarLabel.BRACKET_NONE, null, id, color);
                    targetBarWhole.barLabels.push(newLabel);
                    labelId = newLabel.id;
                }
                
                // Search for all bar segements that have NO label directly on top. Interpret these segments as not having an explicit name association.
                // Check if they had the same size as the segment that was just changed.
                // If they do, then their size should change to fit the new size of the changed segment.
                var segmentIndexToBarOnTop:Vector.<Boolean> = new Vector.<Boolean>();
                var i:int;
                var numBarWholes:int = barWholes.length;
                for (i = 0; i < numBarWholes; i++)
                {
                    var barWhole:BarWhole = barWholes[i];
                    
                    // Assuming no segments have label on top at start
                    segmentIndexToBarOnTop.length = 0;
                    var barSegments:Vector.<BarSegment> = barWhole.barSegments;
                    var numSegments:int = barSegments.length;
                    var j:int;
                    for (j = 0; j < numSegments; j++)
                    {
                        segmentIndexToBarOnTop.push(false);
                    }
                    
                    // Determine which segments actually do have a label on top.
                    // The sizes of these remain fixed
                    var barLabels:Vector.<BarLabel> = barWhole.barLabels;
                    var numLabels:int = barLabels.length;
                    for (j = 0; j < numLabels; j++)
                    {
                        barLabel = barLabels[j];
                        if (barLabel.bracketStyle == BarLabel.BRACKET_NONE && barLabel.endSegmentIndex == barLabel.startSegmentIndex)
                        {
                            segmentIndexToBarOnTop[barLabel.startSegmentIndex] = true;
                        }
                    }
                    
                    // Change the value of the segments that were the same size as the target segment and had no label on top
                    for (j = 0; j < numSegments; j++)
                    {
                        var barSegment:BarSegment = barSegments[j];
                        if (!segmentIndexToBarOnTop[j] && barSegment.getValue() == prevSegmentValue)
                        {
                            barSegment.denominatorValue = targetDenominatorValue;
                            barSegment.numeratorValue = targetNumeratorValue;
                            barSegment.color = color;
                        }
                    }
                }
                
                // Delete stray bar comparisons
                // Consider the case where we have a larger and smaller bar and a bar comparison.
                // Now we replace the larger part with something that transforms it something smaller,
                // the comparison is no longer valid and should be deleted
                for (i = 0; i < barWholes.length; i++)
                {
                    barWhole = barWholes[i];
                    if (barWhole.barComparison != null)
                    {
                        var otherBarId:String = barWhole.barComparison.barWholeIdComparedTo;
                        for each (var otherBarWhole:BarWhole in barWholes)
                        {
                            if (otherBarWhole.id == otherBarId)
                            {
                                // If the row with the comparison becomes longer or the same length
                                // as the row it is compared against, the comparison should be removed
                                if (barWhole.getValue() >= otherBarWhole.getValue())
                                {
                                    barWhole.barComparison = null;
                                }
                                break;
                            }
                        }
                    }
                }
            }
            
            return labelId;
        }
        
        private function getColorForTermValue(termValue:String):uint
        {
            // Figure out what color of the bar should be used, this should be saved
            var color:uint = 0xFFFFFF;
            var symbolDataForDragged:SymbolData = (m_gameEngine != null) ? m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(termValue) : null;
            if (symbolDataForDragged != null && symbolDataForDragged.useCustomBarColor)
            {
                color = symbolDataForDragged.customBarColor;
            }
            else
            {
                // If no extra information about the color for a dropped object, then randomly pick one
                // and then remember it so that same color is used in the future
                color = super.getRandomColorForSegment();
                if (symbolDataForDragged != null)
                {
                    symbolDataForDragged.customBarColor = color;
                    symbolDataForDragged.useCustomBarColor = true;
                }
            }
            
            return color;
        }
    }
}