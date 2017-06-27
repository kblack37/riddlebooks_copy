package wordproblem.scripts.barmodel
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.animation.BarModelToExpressionAnimation;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.view.BarComparisonView;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    /**
     * Script that handles converting elements of the bar model area into single terms that the player moves around.
     * Used for both bar modeling and equation modeling.
     */
    public class BarToCard extends BaseBarModelScript
    {  
        /**
         * Storage for bounds for hit tests
         */
        private var m_boundsBuffer:Rectangle;
        
        /**
         * If true, then bar segment without a label attached are allowed to change into draggable blocks
         * that don't display a value. If false,
         */
        private var m_allowCustomDisplayCards:Boolean;
        
        /**
         * If true then the target bar elements should transform into a regular card
         * Other wise it should maintain it's normal appearance
         * (Used internally and only when dragging bar segments to make duplicates of them)
         */
        private var m_doCreateCardForBarElements:Boolean;
        
        /**
         * Keep track of the pieces of the bar model that were selected across multiple frames
         */
        private var m_barElementsToTransform:Vector.<DisplayObject>;
        
        /**
         * Tween that plays when the element copy shrinks down.
         * We keep a reference in case we need to interrupts it
         */
        private var m_barElementTransformTween:Tween;
        
        /**
         * This is a copy of the bar views to transform. For a small amount of time this view
         * is visible and follows the mouse until a card appears
         */
        private var m_barElementCopy:Image;
        
        /**
         * Out parameters used for the hit test checks
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        /**
         * The current expression value of the bar element that was pressed on.
         * If null, either nothing was last hit or the bar element cannot be represented by a single expression
         */
        private var m_termValueSelected:String;
        
        private var m_setBarColor:Boolean;
        private var m_barColor:uint;
        
        /**
         * If not null, then a dragged bar segment has a label name that should be pasted on top of it
         */
        private var m_barLabelValueOnSegment:String;
        
        /**
         * In some tutorials we want to restrict the selection of pieces.
         * This is a list of bar model element ids that should not be selectable
         */
        private var m_idsToIgnore:Vector.<String>;
        
        public function BarToCard(gameEngine:IGameEngine, 
                                  expressionCompiler:IExpressionTreeCompiler, 
                                  assetManager:AssetManager,
                                  allowCustomDisplayCards:Boolean,
                                  id:String=null, 
                                  isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_allowCustomDisplayCards = allowCustomDisplayCards;
            m_barElementsToTransform = new Vector.<DisplayObject>();
            m_boundsBuffer = new Rectangle();
            m_outParamsBuffer = new Vector.<Object>();
            m_doCreateCardForBarElements = true;
            m_idsToIgnore = new Vector.<String>();            
        }
        
        public function getIdsToIgnore():Vector.<String>
        {
            return m_idsToIgnore;
        }
        
        /**
         * Exposing this function so that the hold to copy can force a bar element to turn into a card
         * without going through the mouse gestures defined in the visit function.
         * 
         * REQUIRES bufferHitElementsAtPoint to be called beforehand
         * 
         * @param dragX
         *      Global x location to start
         * @param dragY
         *      Global y location to start
         * @param onTransformComplete
         */
        public function forceTransform(dragX:Number, 
                                       dragY:Number, 
                                       dragValue:String, 
                                       widgetDragSystem:WidgetDragSystem,
                                       barModelArea:BarModelAreaWidget, 
                                       onTransformComplete:Function=null):void
        {
            // Need to pivot on point on the bar model that the mouse is at
            // HACK: Other the removal scripts changes the transparency of the view, restore to original values
            for each (var barElementView:DisplayObject in m_barElementsToTransform)
            {
                barElementView.alpha = 1.0;
            }
            
            var selectedBarModelElementCopy:Image = BarModelToExpressionAnimation.convertBarModelViewsToSingleImage(
                m_barElementsToTransform, barModelArea.stage, barModelArea.scaleFactor, m_boundsBuffer
            );
            
            // If the element should be converted into a card we play a tween where the element shrinks to nothing
            // otherwise we can start dragging the element without any extra tween
            if (m_doCreateCardForBarElements)
            {
                var pivotX:Number = dragX - m_boundsBuffer.x;
                var pivotY:Number = dragY - m_boundsBuffer.y;
                selectedBarModelElementCopy.pivotX = pivotX;
                selectedBarModelElementCopy.pivotY = pivotY;
                selectedBarModelElementCopy.x = m_boundsBuffer.x + pivotX;
                selectedBarModelElementCopy.y = m_boundsBuffer.y + pivotY;
                
                m_barElementCopy = selectedBarModelElementCopy;
                barModelArea.stage.addChild(selectedBarModelElementCopy);
                
                // Start drag immediate BUT keep it hidden until the transform finishes
                // The dragged card need to start at the current position of the mouse
                // (make sure coordinates are relative to the canvas)
                widgetDragSystem.selectAndStartDrag(new ExpressionNode(m_expressionCompiler.getVectorSpace(), dragValue),
                    m_mouseState.mousePositionThisFrame.x, 
                    m_mouseState.mousePositionThisFrame.y, 
                    barModelArea, null);
                if (widgetDragSystem.getWidgetSelected())
                {
                    widgetDragSystem.getWidgetSelected().alpha = 0.0;
                }
                
                // Tween to shrink copy to nothing
                var shrinkCopyTween:Tween = new Tween(selectedBarModelElementCopy, 0.3);
                shrinkCopyTween.scaleTo(0);
                shrinkCopyTween.onComplete = function():void
                {
                    // Make the dragged part visible after the transform is finished
                    if (widgetDragSystem.getWidgetSelected())
                    {
                        widgetDragSystem.getWidgetSelected().alpha = 1.0;
                    }
                    
                    clearBarElementCopy();
                    if (onTransformComplete != null)
                    {
                        onTransformComplete();
                    }
                };
                Starling.juggler.add(shrinkCopyTween);
                m_barElementTransformTween = shrinkCopyTween;
            }
            // Other wise the new dragged segment just appears as it did in the bar model
            else
            {
                selectedBarModelElementCopy.pivotX = m_boundsBuffer.width * 0.5;
                selectedBarModelElementCopy.pivotY = m_boundsBuffer.height * 0.5;
                
                var extraDragParams:Object = null;
                if (m_setBarColor)
                {
                    extraDragParams = {color:m_barColor};
                }
                
                if (m_barLabelValueOnSegment != null)
                {
                    extraDragParams = {label:m_barLabelValueOnSegment};
                }
                
                widgetDragSystem.selectAndStartDrag(new ExpressionNode(m_expressionCompiler.getVectorSpace(), dragValue),
                    m_mouseState.mousePositionThisFrame.x, 
                    m_mouseState.mousePositionThisFrame.y, 
                    barModelArea, extraDragParams, selectedBarModelElementCopy, onCustomDispose);
            }
        }
        
        /**
         * There is a small slice of time after forceTransform has been called where an animation to start the drag of
         * a bar element is playing. During this time the user can actually release the mouse to cancel the transform.
         * This function handles that edge case where the animation can be stopped
         */
        public function cancelTransform():void
        {
            if (m_barElementTransformTween != null)
            {
                Starling.juggler.remove(m_barElementTransformTween);
                m_barElementCopy.removeFromParent(true);
            }
        }
        
        /**
         * Another hack function needed for the hold to copy to work
         * 
         * @param prioritizeLabels
         *      If true, then labels appearing on top of the segment will be the expression value the card
         *      should have when dragged
         * @return
         *      The expression value to make a card from
         */
        public function bufferHitElementsAtPoint(barModelPoint:Point, 
                                                 barModelArea:BarModelAreaWidget, 
                                                 prioritizeLabels:Boolean=true):String
        {
            m_barLabelValueOnSegment = null;
            m_setBarColor = false;
            m_barElementsToTransform.length = 0;
            m_outParamsBuffer.length = 0;
            
            var hitExpressionValue:String = null;
            if (BarModelHitAreaUtil.getBarElementUnderPoint(m_outParamsBuffer, barModelArea, barModelPoint, m_boundsBuffer, prioritizeLabels))
            {
                var hitElement:Object = m_outParamsBuffer[0];
                var hitElementIndex:int = m_outParamsBuffer[1] as int;
                var hitBarView:BarWholeView = m_outParamsBuffer[2] as BarWholeView;
                
                // Save the view that was hit
                m_barElementsToTransform.push(hitElement);
                
                m_doCreateCardForBarElements = true;
                
                // Need to figure out what term value each particular type of hit
                // object should convert to
                if (hitBarView != null)
                {
                    if (hitElement is BarSegmentView)
                    {
                        // The easy way is to just get the segment value directly and transform it back into a term value
                        var barSegmentView:BarSegmentView = hitElement as BarSegmentView;
                        
                        // Segments are the trickiest case potentially as the card value is really governed by values assigned to it
                        // If a segment has a no-bracket label it takes the value of that label
                        // Look through all labels and fetch ones that lie exactly on top
                        var barLabelViews:Vector.<BarLabelView> = hitBarView.labelViews;
                        var i:int;
                        var barLabelView:BarLabelView;
                        var numBarLabelViews:int = barLabelViews.length;
                        var segmentMatchedSingleLabel:Boolean = false;
                        for (i = 0; i < numBarLabelViews; i++)
                        {
                            barLabelView = barLabelViews[i];
                            if (barLabelView.data.endSegmentIndex == hitElementIndex && 
                                barLabelView.data.startSegmentIndex == hitElementIndex &&
                                barLabelView.data.bracketStyle == BarLabel.BRACKET_NONE
                            )
                            {
                                m_barLabelValueOnSegment = barLabelView.data.value;
                                segmentMatchedSingleLabel = true;
                                hitExpressionValue = barLabelView.data.value;
                                
                                // If label lies on top, save that it was hit as well
                                m_barElementsToTransform.push(barLabelView);
                            }
                        }
                        
                        if (m_allowCustomDisplayCards && !segmentMatchedSingleLabel)
                        {
                            var segmentTermValue:Number = barSegmentView.data.numeratorValue * barModelArea.normalizingFactor / barSegmentView.data.denominatorValue;
                            hitExpressionValue = segmentTermValue + "";
                            m_doCreateCardForBarElements = false;
                            
                            m_setBarColor = true;
                            m_barColor = barSegmentView.data.color;
                        }
                        else if (segmentMatchedSingleLabel)
                        {
                            m_doCreateCardForBarElements = true;   
                        }
                        else
                        {
                            // A segment without a label on top was dragged, in equation building mode we want this
                            // to convert to a number. That number should be equal to the number of segment in the
                            // row with the same segment value as the one that was dragged.
                            var numSegmentsWithTheSameValue:int = 0;
                            var segmentValueOfHitPart:Number = barSegmentView.data.getValue();
                            for each (var segmentViewInBar:BarSegmentView in hitBarView.segmentViews)
                            {
                                if (segmentViewInBar.data.getValue() == segmentValueOfHitPart)
                                {
                                    numSegmentsWithTheSameValue++;
                                    m_barElementsToTransform.push(segmentViewInBar);
                                }
                            }
                            
                            if (numSegmentsWithTheSameValue > 1)
                            {
                                hitExpressionValue = numSegmentsWithTheSameValue.toString();
                            }
                            else
                            {
                                // Act like a display was never hit if not allowed to create custom cards and hit a segment
                                hitExpressionValue = null;
                                m_barElementsToTransform.length = 0;
                            }
                        }
                    }
                    else if (hitElement is BarLabelView)
                    {
                        barLabelView = hitElement as BarLabelView;
                        hitExpressionValue = barLabelView.data.value;
                    }
                    else if (hitElement is BarComparisonView)
                    {
                        var barComparisonView:BarComparisonView = hitElement as BarComparisonView;
                        hitExpressionValue = barComparisonView.data.value;
                    }
                }
                else
                {
                    if (hitElement is BarLabelView)
                    {
                        barLabelView = hitElement as BarLabelView;
                        hitExpressionValue = barLabelView.data.value;
                    }
                }
            }
            
            if (m_idsToIgnore.length > 0)
            {
                var idOfHitElement:String = null;
                if (hitElement is BarSegmentView)
                {
                    idOfHitElement = (hitElement as BarSegmentView).data.id;
                }
                else if (hitElement is BarLabelView)
                {
                    idOfHitElement = (hitElement as BarLabelView).data.id;
                }
                else if (hitElement is BarComparisonView)
                {
                    idOfHitElement = (hitElement as BarComparisonView).data.id;
                }
                
                // Ignore this hit if the target element was specified in the ignore list
                if (idOfHitElement != null && m_idsToIgnore.indexOf(idOfHitElement) > -1)
                {
                    hitExpressionValue = null;
                }
            }
            
            return hitExpressionValue;
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            
            if (m_ready && m_isActive && !Layer.getDisplayObjectIsInInactiveLayer(m_barModelArea))
            {
                m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                if (m_mouseState.leftMousePressedThisFrame)
                {
                    m_termValueSelected = bufferHitElementsAtPoint(m_localMouseBuffer, m_barModelArea, false);
                }
                else if (m_mouseState.leftMouseDraggedThisFrame && m_termValueSelected != null)
                {
                    if (m_barElementCopy != null)
                    {
                        m_barElementCopy.x = m_globalMouseBuffer.x;
                        m_barElementCopy.y = m_globalMouseBuffer.y;
                    }
                    
                    // We only want to create the dragged copy once while dragging.
                    // In the case of a bar segment there is no tween so the drag system will immediately detect the drag.
                    if (m_barElementCopy == null && m_widgetDragSystem.getWidgetSelected() == null)
                    {
                        Audio.instance.playSfx("bar2card");
                        forceTransform(m_globalMouseBuffer.x, m_globalMouseBuffer.y, m_termValueSelected, m_widgetDragSystem, m_barModelArea);
                    }
                }
                
                // On release clear the buffers.
                // If a tween is not finished then stop it immediately and dispose the bar element copy textures
                if (m_mouseState.leftMouseReleasedThisFrame)
                {
                    if (m_barElementTransformTween != null)
                    {
                        clearBarElementCopy();
                    }
                    m_barElementsToTransform.length = 0;
                    m_termValueSelected = null;
                }
            }
            
            return status;
        }
        
        private function clearBarElementCopy():void
        {
            m_barElementCopy.removeFromParent(true);
            // The dragged copy can be destroyed along with the custom texture
            m_barElementCopy.texture.dispose();
            m_barElementCopy = null;
            m_termValueSelected = null;
            
            Starling.juggler.remove(m_barElementTransformTween);
            m_barElementTransformTween = null;
        }
        
        private function onCustomDispose(customDisplay:DisplayObject):void
        {
            if (customDisplay is Image)
            {
                (customDisplay as Image).texture.dispose();
            }
        }
    }
}