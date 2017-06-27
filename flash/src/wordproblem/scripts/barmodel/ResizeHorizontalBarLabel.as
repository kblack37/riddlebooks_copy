package wordproblem.scripts.barmodel
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.core.Starling;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.animation.RingPulseAnimation;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script handles the resizing of both the horizontal labels on a
     * bar. For the horizontal labels resizing just means adjusting the number of segments
     * within a bar that a label spans over.
     * 
     * Each label at a minimum must span over one segment/bar. Labels edges also automatically snap
     * to the bounds of each segment/bar
     */
    public class ResizeHorizontalBarLabel extends BaseBarModelScript
    {
        /**
         * Across multiple visits, we need to keep track of whether the player was in the middle of dragging
         * one of the edges of a label. This helps indicate that a release will force a redraw of the label.
         * 
         * This references the label in the preview as that is what will be redrawn
         */
        private var m_previewBarLabelView:BarLabelView;
        
        /**
         * We need to keep a reference to the whole bar as this has the segments that define the edges that
         * are allowable for a label to span. This does not need to reference the preview since it should
         * never change.
         */
        private var m_targetBarWholeView:BarWholeView;
        
        /**
         * Once the user presses down on the a label edge we record the anchor to check how far the
         * player has dragged it.
         * Frame of reference is the entire bar model area
         */
        private var m_localMousePressAnchorX:Number;
        
        /**
         * The pivot x is the horizontal coordinate at which one of the label edges is fixed at.
         * If dragging the left edge, the right edge x is the pivot and vis versa.
         * This number lets us know when the player has 'flipped' the label on its other side
         * 
         * Frame of reference is the entire bar model area
         */
        private var m_localLabelPivotX:Number;
        
        /**
         * Right now we are shifting around the original label, we need to keep track of the x of the
         * edge being dragged.
         * Value is relative to the containing bar whole
         */
        private var m_originalLabelViewDraggedEdgeX:Number;
        
        /**
         * If the player is dragging an edge, true if they are dragging the left part.
         * This changes value as the player crosses one edge over another
         */
        private var m_draggingLeftEdge:Boolean;
        
        /**
         * A buffer that stores the hit label and whether the start or end edge is dragged
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        /**
         * Pulse that plays when user presses on an edge that resizes
         */
        private var m_ringPulseAnimation:RingPulseAnimation;
        
        public function ResizeHorizontalBarLabel(gameEngine:IGameEngine, 
                                       expressionCompiler:IExpressionTreeCompiler, 
                                       assetManager:AssetManager, 
                                       id:String=null, 
                                       isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            m_outParamsBuffer = new Vector.<Object>();
            m_ringPulseAnimation = new RingPulseAnimation(assetManager.getTexture("ring"), onRingPulseAnimationComplete);
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            if (m_ready && m_isActive)
            {
                // On a mouse down check that the player has hit within an area of label edge, this initiates a drag
                // The horizontal labels have priority over the verical labels
                m_outParamsBuffer.length = 0;
                m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                
                if (m_previewBarLabelView != null)
                {
                    // Do not let the label go past the first or last segment edges
                    var segmentViews:Vector.<BarSegmentView> = m_targetBarWholeView.segmentViews;
                    var leftEdgeXLimit:Number = segmentViews[0].rigidBody.boundingRectangle.left;
                    var rightEdgeXLimit:Number = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle.right;
                    var localX:Number = m_localMouseBuffer.x;
                    if (m_localMouseBuffer.x < leftEdgeXLimit)
                    {
                        localX = leftEdgeXLimit;
                    }
                    else if (m_localMouseBuffer.x > rightEdgeXLimit)
                    {
                        localX = rightEdgeXLimit;
                    }
                }
                
                if (m_mouseState.leftMousePressedThisFrame)
                {
                    var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
                    var i:int;
                    var barWholeView:BarWholeView;
                    var numBarWholeViews:int = barWholeViews.length;
                    for (i = 0; i < numBarWholeViews; i++)
                    {
                        barWholeView = barWholeViews[i];
                        var labelViews:Vector.<BarLabelView> = barWholeView.labelViews;
                        checkLabelEdgeHitPoint(m_localMouseBuffer, labelViews, m_outParamsBuffer);
                        if (m_outParamsBuffer.length > 0)
                        {
                            var originalTargetBarLabelView:BarLabelView = m_outParamsBuffer[0] as BarLabelView;
                            m_draggingLeftEdge = m_outParamsBuffer[1] as Boolean;
                            m_originalLabelViewDraggedEdgeX = (m_draggingLeftEdge) ? 
                                originalTargetBarLabelView.x : 
                                originalTargetBarLabelView.x + originalTargetBarLabelView.rigidBody.boundingRectangle.width;
                            m_targetBarWholeView = barWholeView;
                            segmentViews = m_targetBarWholeView.segmentViews;
                            m_localLabelPivotX = (m_draggingLeftEdge) ? 
                                segmentViews[originalTargetBarLabelView.data.endSegmentIndex].rigidBody.boundingRectangle.right : 
                                segmentViews[originalTargetBarLabelView.data.startSegmentIndex].rigidBody.boundingRectangle.left;
                            m_localMousePressAnchorX = m_localMouseBuffer.x;
                            
                            // Create and show the preview
                            // We modify parameters of the preview and leave the regular view intact
                            // We want to manipulate the label of the preview (HACK need to show the preview before it refreshes the draw)
                            var previewView:BarModelView = m_barModelArea.getPreviewView(true);
                            m_barModelArea.showPreview(true);
                            m_previewBarLabelView = getBarLabelViewFromId(originalTargetBarLabelView.data.id, previewView.getBarWholeViews());
                            
                            status = ScriptStatus.SUCCESS;
                            
                            // Show a small pulse on hit of the label
                            m_ringPulseAnimation.reset(m_localMouseBuffer.x, m_localMouseBuffer.y, m_barModelArea, 0x00FF00);
                            Starling.juggler.add(m_ringPulseAnimation);
                            
                            m_previewBarLabelView.addButtonImagesToEdges(m_assetManager.getTexture("card_background_circle"));
                            m_previewBarLabelView.colorEdgeButton(m_draggingLeftEdge, 0x00FF00, 1.0);
                            m_eventDispatcher.dispatchEventWith(GameEvent.START_RESIZE_HORIZONTAL_LABEL);
                            break;
                        }
                    }
                }
                else if (m_mouseState.leftMouseDraggedThisFrame && m_previewBarLabelView != null && m_mouseState.mouseDeltaThisFrame.x != 0)
                {
                    status = ScriptStatus.SUCCESS;
                    
                    // Whether or not the player is currently dragging the left edge is determined whether the mouse crosses
                    // the other edge of the label.
                    if (m_localMouseBuffer.x > m_localLabelPivotX && m_draggingLeftEdge && m_previewBarLabelView.data.endSegmentIndex + 1 < segmentViews.length)
                    {
                        // Dragging the right edge now
                        // Start increases by one
                        // Reflect the x mouse anchor relative to the pivot if a dragged label went to the
                        // other side. Do the same for the original x
                        m_previewBarLabelView.data.startSegmentIndex = m_previewBarLabelView.data.endSegmentIndex + 1;
                        m_draggingLeftEdge = false;
                        m_localMousePressAnchorX = m_localLabelPivotX + (m_localLabelPivotX - m_localMousePressAnchorX);
                        
                        // Manipulating values of different frame of reference, need to transform to reference of the bar whole
                        var transformedPivotX:Number = m_localLabelPivotX - m_targetBarWholeView.x;
                        m_originalLabelViewDraggedEdgeX = transformedPivotX + (transformedPivotX - m_originalLabelViewDraggedEdgeX);
                        
                        // Change the color of the dragged button
                        m_previewBarLabelView.colorEdgeButton(m_draggingLeftEdge, 0x00FF00, 1.0);
                        m_previewBarLabelView.colorEdgeButton(!m_draggingLeftEdge, 0xFFFFFF, 0.3);
                    }
                    else if (m_localMouseBuffer.x < m_localLabelPivotX && !m_draggingLeftEdge && m_previewBarLabelView.data.startSegmentIndex - 1 >= 0)
                    {
                        // Dragging the left edge now
                        // End decreases by one
                        m_previewBarLabelView.data.endSegmentIndex = m_previewBarLabelView.data.startSegmentIndex - 1;
                        m_previewBarLabelView.data.startSegmentIndex = m_previewBarLabelView.data.endSegmentIndex;
                        m_draggingLeftEdge = true;
                        
                        // Convert the press and drag point to appear
                        m_localMousePressAnchorX = m_localLabelPivotX - (m_localMousePressAnchorX - m_localLabelPivotX);
                        
                        transformedPivotX = (m_localLabelPivotX - m_targetBarWholeView.x);
                        m_originalLabelViewDraggedEdgeX = (transformedPivotX) - (m_originalLabelViewDraggedEdgeX - transformedPivotX);
                        
                        // Change the color of the dragged button
                        m_previewBarLabelView.colorEdgeButton(m_draggingLeftEdge, 0x00FF00, 1.0);
                        m_previewBarLabelView.colorEdgeButton(!m_draggingLeftEdge, 0xFFFFFF, 0.3);
                    }
                    
                    // We need to update the graphic while the drag is occuring
                    getClosestSegmentIndexToCurrentMouse(localX, m_localMouseBuffer.y, m_outParamsBuffer);
                    var closestSegmentIndex:int = m_outParamsBuffer[0] as int;
                    var distanceFromSegment:Number = m_outParamsBuffer[1] as Number;
                    
                    // If do not allow for a label to span nothing
                    var validSpan:Boolean = (m_draggingLeftEdge && closestSegmentIndex <= m_previewBarLabelView.data.endSegmentIndex) ||
                        (!m_draggingLeftEdge && closestSegmentIndex >= m_previewBarLabelView.data.startSegmentIndex);
                    
                    // If distance is within some threshold then the edge should snap to the segment
                    // Otherwise just redraw the label so the edge goes to the mouse
                    var snapThreshold:Number = 30 * m_barModelArea.scaleFactor;
                    if (Math.abs(distanceFromSegment) < snapThreshold && validSpan)
                    {
                        // Figure out the new length of the label
                        // Dragging left alters the starting edge of the label
                        // Dragging right alters the ending edge of the label
                        var endSegmentIndex:int = (m_draggingLeftEdge) ? m_previewBarLabelView.data.endSegmentIndex : closestSegmentIndex;
                        var startSegmentIndex:int = (m_draggingLeftEdge) ? closestSegmentIndex : m_previewBarLabelView.data.startSegmentIndex;
                        
                        // Resize the preview on snapping to an edge
                        resizeHorizontalBarLabel(m_previewBarLabelView.data, startSegmentIndex, endSegmentIndex);
                        
                        // Need to resize the line AND reposition it based on which edge was clicked
                        var startSegmentBounds:Rectangle = segmentViews[startSegmentIndex].rigidBody.boundingRectangle;
                        var endSegmentBounds:Rectangle = segmentViews[endSegmentIndex].rigidBody.boundingRectangle;
                        
                        var newLabelLength:Number = endSegmentBounds.right - startSegmentBounds.left;
                        m_previewBarLabelView.resizeToLength(newLabelLength / m_barModelArea.scaleFactor);
                        
                        // The segment view position is relative to the containing whole bar (which is the same
                        // parent as the label view) so we use that coordinate rather than the bounding rectangle
                        // which is relative to the entire bar model view area.
                        m_previewBarLabelView.x = segmentViews[startSegmentIndex].x; 
                    }
                    else
                    {
                        // If we don't snap to an edge we just redraw the label to a new length.
                        var deltaX:Number = m_localMousePressAnchorX - localX;
                        
                        // Apply the difference to the original length of the label
                        originalTargetBarLabelView = getBarLabelViewFromId(m_previewBarLabelView.data.id, m_barModelArea.getBarWholeViews());
                        endSegmentIndex = originalTargetBarLabelView.data.endSegmentIndex;
                        startSegmentIndex = originalTargetBarLabelView.data.startSegmentIndex;
                        startSegmentBounds = segmentViews[startSegmentIndex].rigidBody.boundingRectangle;
                        endSegmentBounds = segmentViews[endSegmentIndex].rigidBody.boundingRectangle;
                        
                        var originalSpanningWidth:Number = endSegmentBounds.right - startSegmentBounds.left;
                        newLabelLength = (m_draggingLeftEdge) ? originalSpanningWidth + deltaX : originalSpanningWidth - deltaX;
                        
                        // This should fail in the instance where the label is spanning just one segment that is at the very
                        // end of the bar and the drag tries to make the span even smaller.
                        // (i.e. the movement is in the direction of the last edge and there is not way to snap to that edge)
                        var allowResize:Boolean = true;
                        var lastSegmentIndex:int = m_targetBarWholeView.segmentViews.length - 1;
                        if (m_previewBarLabelView.data.startSegmentIndex == 0 && m_previewBarLabelView.data.endSegmentIndex == 0 && 
                            !m_draggingLeftEdge && newLabelLength < segmentViews[0].rigidBody.boundingRectangle.width)
                        {
                            allowResize = false;
                        }
                        else if (m_previewBarLabelView.data.startSegmentIndex == lastSegmentIndex && m_previewBarLabelView.data.endSegmentIndex == lastSegmentIndex &&
                            m_draggingLeftEdge && newLabelLength < segmentViews[lastSegmentIndex].rigidBody.boundingRectangle.width)
                        {
                            allowResize = false;
                        }
                        
                        if (allowResize)
                        {
                            m_previewBarLabelView.resizeToLength(newLabelLength / m_barModelArea.scaleFactor);
                            
                            // If dragging the left, we need to shift the x of the label
                            if (m_draggingLeftEdge)
                            {
                                // A bit strange, but the coordinates of the bar model are 'unscaled' from its reference point, however
                                // outside values like mouse movements need to take into account the bar model scale.
                                // essentially it needs to translate itself to the frame of the bar model area
                                m_previewBarLabelView.x = m_originalLabelViewDraggedEdgeX - (deltaX / m_barModelArea.scaleFactor);
                            }
                            // Otherwise it is just anchored at the start
                            else
                            {
                                m_previewBarLabelView.x = segmentViews[m_previewBarLabelView.data.startSegmentIndex].x;
                            }
                        }
                    }
                }
                else if (m_mouseState.leftMouseReleasedThisFrame && m_previewBarLabelView != null)
                {
                    status = ScriptStatus.SUCCESS;
                    
                    // Check if the changes applied to the preview differ from the original bar
                    // Do not dispatch event if the indices do not change
                    originalTargetBarLabelView = getBarLabelViewFromId(m_previewBarLabelView.data.id, m_barModelArea.getBarWholeViews());
                    if (originalTargetBarLabelView.data.startSegmentIndex != m_previewBarLabelView.data.startSegmentIndex ||
                        originalTargetBarLabelView.data.endSegmentIndex != m_previewBarLabelView.data.endSegmentIndex)
                    {
                        // On a release we need to check the final edge the drag stopped at and update the label index
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        resizeHorizontalBarLabel(originalTargetBarLabelView.data, m_previewBarLabelView.data.startSegmentIndex, m_previewBarLabelView.data.endSegmentIndex);
                        m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        m_barModelArea.redraw();
                        
                        // Log resizing of a label on the bar segments
                        m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.RESIZE_HORIZONTAL_LABEL, false, {barModel:m_barModelArea.getBarModelData().serialize()});
                    }
                    
                    // Remove the preview
                    m_barModelArea.showPreview(false);
                    m_previewBarLabelView = null;
                    m_targetBarWholeView = null;
                    
                    m_eventDispatcher.dispatchEventWith(GameEvent.END_RESIZE_HORIZONTAL_LABEL);
                }
            }
            
            return status;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            
            // Whether or not the buttons appear is actually dependent on whether the logic in here is active
            if (m_ready && m_barModelArea != null)
            {
                m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, onBarModelRedrawn);
                toggleButtonsOnEdges(m_barModelArea, false);
                
                if (m_isActive)
                {
                    // Listen for redraw of bar model area, at this point we re-add all the buttons
                    m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, onBarModelRedrawn);
                    toggleButtonsOnEdges(m_barModelArea, true);
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Due to timing issue, the first redraw event is not caught,
            // so if the bar model area initially has object we need to process the initial set
            setIsActive(m_isActive);
        }
        
        /**
         * Looking at the current mouse position, get the index of the segment that the mouse is closest to.
         * If dragging the left side segments are checked on their left edge, if dragging right then segments
         * are checked on their right edge.
         * 
         * @param outParams
         *      First index is the index of the segment, second index is distance to that segment
         *      from the mouse point
         */
        private function getClosestSegmentIndexToCurrentMouse(localX:Number, localY:Number, outParams:Vector.<Object>):void
        {
            // Horizontal means that we should be snapping to the edges of segment
            var segmentView:BarSegmentView;
            var segmentViews:Vector.<BarSegmentView> = m_targetBarWholeView.segmentViews;
            var closestSegmentIndex:int = -1;
            var closestDistance:Number = 0;
            
            // We need to check for every segment edge (to allow for one edge to roll over into another)
            // Dragging the left side of the label means we are searching for a new start
            var i:int;
            var numSegments:int = segmentViews.length;
            for (i = 0; i < numSegments; i++)
            {
                segmentView = segmentViews[i];
                var segmentBound:Rectangle = segmentView.rigidBody.boundingRectangle;
                var distance:Number = (m_draggingLeftEdge) ? 
                    Math.abs(segmentBound.left - localX) : Math.abs(segmentBound.right - localX);
                if (closestSegmentIndex == -1 || distance < closestDistance)
                {
                    closestSegmentIndex = i;
                    closestDistance = distance;
                }
            }
            
            outParams.push(closestSegmentIndex, closestDistance);
        }
        
        private function resizeHorizontalBarLabel(targetBarLabel:BarLabel, 
                                                  startSegmentIndex:int, 
                                                  endSegmentIndex:int):void
        {
            targetBarLabel.startSegmentIndex = startSegmentIndex;
            targetBarLabel.endSegmentIndex = endSegmentIndex;
        }
        
        /**
         * Function that checks if a point (the click point) hits a set of label views
         * The hit area incorporates a small amount of padding to the left and right of each edge and should
         * be two boxes on either edge.
         * 
         * @param point
         *      A point whole coordinates are relative to the bar model widget
         * @param labelViews
         * @param outParams
         *      First index is the label that was hit, the second index is true if the start edge was hit, false if the end edge was hit
         *      Empty if none of the views hit
         */
        private function checkLabelEdgeHitPoint(point:Point, labelViews:Vector.<BarLabelView>, outParams:Vector.<Object>):void
        {
            var i:int;
            var labelView:BarLabelView;
            var numLabelViews:int = labelViews.length;
            for (i = 0; i < numLabelViews; i++)
            {
                labelView = labelViews[i];
                
                // Ignore the labels that are placed directly on the segment
                if (labelView.data.bracketStyle != BarLabel.BRACKET_NONE && 
                    (m_restrictedElementIds.length == 0 || m_restrictedElementIds.indexOf(labelView.data.value) > -1))
                {
                    var labelViewBounds:Rectangle = labelView.rigidBody.boundingRectangle;
                    
                    // We have 'hit' circles at the edges of the labels
                    var radiusSquared:Number = 15*15;
                    
                    var leftCenterX:Number = labelViewBounds.left;
                    var leftCenterY:Number = labelViewBounds.top + labelViewBounds.height * 0.5;
                    var leftDeltaX:Number = leftCenterX - point.x;
                    var leftDeltaY:Number = leftCenterY - point.y;
                    
                    var rightCenterX:Number = labelViewBounds.right;
                    var rightCenterY:Number = leftCenterY;
                    var rightDeltaX:Number = rightCenterX - point.x;
                    var rightDeltaY:Number = rightCenterY - point.y;
                    
                    var hitEdge:Boolean = false;
                    var dragLeft:Boolean = false;
                    var leftDifferenceSquared:Number = leftDeltaX * leftDeltaX + leftDeltaY * leftDeltaY;
                    var rightDifferenceSquared:Number = rightDeltaX * rightDeltaX + rightDeltaY * rightDeltaY;
                    
                    if (leftDifferenceSquared <= radiusSquared && rightDifferenceSquared <= radiusSquared)
                    {
                        hitEdge = true;
                        dragLeft = leftDifferenceSquared < rightDifferenceSquared;
                    }
                    else if (leftDifferenceSquared <= radiusSquared)
                    {
                        hitEdge = true;
                        dragLeft = true;
                    }
                    else if (rightDifferenceSquared <= radiusSquared)
                    {
                        hitEdge = true;
                        dragLeft = false;
                    }
                    
                    if (hitEdge)
                    {
                        outParams.push(labelView);
                        outParams.push(dragLeft);
                        break;
                    }
                }
            }
        }
        
        private function getBarLabelViewFromId(barLabelId:String, barWholeViews:Vector.<BarWholeView>):BarLabelView
        {
            var matchingBarLabelView:BarLabelView = null;
            var i:int;
            var barWholeView:BarWholeView;
            var numBarWholeViews:int = barWholeViews.length;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = barWholeViews[i];
                var j:int;
                var barLabelViews:Vector.<BarLabelView> = barWholeView.labelViews;
                var numBarLabelViews:int = barLabelViews.length;
                for (j = 0; j < numBarLabelViews; j++)
                {
                    if (barLabelViews[j].data.id == barLabelId)
                    {
                        matchingBarLabelView = barLabelViews[j];
                        break;
                    }
                }
                
                if (matchingBarLabelView != null)
                {
                    break;
                }
            }
            
            return matchingBarLabelView;
        }
        
        private function onRingPulseAnimationComplete():void
        {
            // Make sure animation isn't showing
            Starling.juggler.remove(m_ringPulseAnimation);
        }
        
        private function onBarModelRedrawn(event:Event):void
        {
            var barModelView:BarModelView = event.target as BarModelView;
            toggleButtonsOnEdges(event.target as BarModelView, true);
        }
        
        private function toggleButtonsOnEdges(barModelView:BarModelView, 
                                              showButtons:Boolean):void
        {
            // Look through all horizontal labels and add buttons to the edges
            var buttonTexture:Texture = m_assetManager.getTexture("card_background_circle");
            var barWholeViews:Vector.<BarWholeView> = barModelView.getBarWholeViews();
            var numBarWholeViews:int = barWholeViews.length;
            var i:int;
            for (i = 0; i < numBarWholeViews; i++)
            {
                var barLabelViews:Vector.<BarLabelView> = barWholeViews[i].labelViews;
                var numBarLabelViews:int = barLabelViews.length;
                var j:int;
                var barLabelView:BarLabelView;
                var barLabelViewBounds:Rectangle;
                for (j = 0; j < numBarLabelViews; j++)
                {
                    barLabelView = barLabelViews[j];
                    if (barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE)
                    {
                        if (showButtons)
                        {
                            // Do not add button is a restriction is placed
                            if (m_restrictedElementIds.length == 0 || m_restrictedElementIds.indexOf(barLabelView.data.value) > -1)
                            {
                                barLabelView.addButtonImagesToEdges(buttonTexture);
                            }
                        }
                        else
                        {
                            barLabelView.removeButtonImagesFromEdges();
                        }
                    }
                }
            }
        }
    }
}