package wordproblem.scripts.barmodel
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.animation.RingPulseAnimation;
    import wordproblem.engine.barmodel.animation.RemoveResizeableBarPieceAnimation;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    public class RemoveHorizontalLabel extends BaseBarModelScript implements IRemoveBarElement
    {
        /**
         * When the user presses down this is the label that was selected.
         * Null if no valid label was selected on press
         */
        private var m_hitBarLabelView:BarLabelView;
        
        /**
         * Pulse that plays when user presses on an edge that resizes
         */
        private var m_ringPulseAnimation:RingPulseAnimation;
        
        /**
         * To remove a label, we detect a press on the descrption area for that label
         */
        private var m_labelDescriptionBounds:Rectangle;
        
        public function RemoveHorizontalLabel(gameEngine:IGameEngine, 
                                                expressionCompiler:IExpressionTreeCompiler, 
                                                assetManager:AssetManager, 
                                                id:String=null, 
                                                isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_ringPulseAnimation = new RingPulseAnimation(assetManager.getTexture("ring"), onRingPulseAnimationComplete);
            m_labelDescriptionBounds = new Rectangle();
        }
        
        public function removeElement(element:DisplayObject):Boolean
        {
            var canRemove:Boolean = false;
            if (element is BarLabelView)
            {
                var hitBarLabelView:BarLabelView = element as BarLabelView;
                if (hitBarLabelView.data.bracketStyle == BarLabel.BRACKET_STRAIGHT && hitBarLabelView.data.isHorizontal)
                {
                    canRemove = true;
                    
                    // Delete the label
                    var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                    var numBarWholes:int = barWholes.length;
                    var i:int;
                    var barWhole:BarWhole;
                    var foundMatchingLabel:Boolean = false;
                    for (i = 0; i < numBarWholes; i++)
                    {
                        barWhole = barWholes[i];
                        
                        var barLabels:Vector.<BarLabel> = barWhole.barLabels;
                        var numBarLabels:int = barLabels.length;
                        var j:int;
                        var barLabel:BarLabel;
                        for (j = 0; j < numBarLabels; j++)
                        {
                            barLabel = barLabels[j];
                            
                            // HACK: Do not allow removal of labels with a hidden value, some tutorials may need that to stay on the screen
                            if (barLabel.id == hitBarLabelView.data.id && hitBarLabelView.data.hiddenValue == null)
                            {
                                // Create animation where the label quickly shrinks in size like it is being rolled up before
                                // falling off the edge (Need to create a clone of the label as the original is disposed on a redraw)
                                var removedLabelView:BarLabelView = m_barModelArea.createBarLabelView(hitBarLabelView.data);
                                removedLabelView.resizeToLength(hitBarLabelView.pixelLength);
                                var globalCoordinates:Point = hitBarLabelView.localToGlobal(new Point(0, 0));
                                removedLabelView.x = globalCoordinates.x;
                                removedLabelView.y = globalCoordinates.y;
                                var removeBarLabelAnimation:RemoveResizeableBarPieceAnimation = new RemoveResizeableBarPieceAnimation(function():void
                                {
                                    removedLabelView.removeFromParent(true);
                                });
                                removedLabelView.scaleX = removedLabelView.scaleY = m_barModelArea.scaleFactor;
                                m_gameEngine.getSprite().addChild(removedLabelView);
                                removeBarLabelAnimation.play(removedLabelView);
                                
                                // Splice out the target label
                                var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                                barLabels.splice(j, 1);
                                m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                                m_barModelArea.redraw();
                                
                                // Log removal of a label on the segments
                                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.REMOVE_HORIZONTAL_LABEL, false, {barModel:m_barModelArea.getBarModelData().serialize()});
                                
                                foundMatchingLabel = true;
                                break;
                            }
                        }
                        
                        if (foundMatchingLabel)
                        {
                            break;
                        }
                    }
                }
            }
            
            return canRemove;
        }
        
        override public function reset():void
        {
            super.reset();
            
            if (m_hitBarLabelView != null)
            {
                m_hitBarLabelView.setBracketAndDescriptionAlpha(1.0);
                m_hitBarLabelView = null;
            }
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            if (m_ready && m_isActive && !Layer.getDisplayObjectIsInInactiveLayer(m_barModelArea))
            {
                var mouseState:MouseState = m_gameEngine.getMouseState();
                m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                
                if (mouseState.leftMousePressedThisFrame)
                {
                    m_hitBarLabelView = checkHitHorizontalLabel();
                    if (m_hitBarLabelView != null)
                    {
                        m_hitBarLabelView.setBracketAndDescriptionAlpha(0.3);
                        m_ringPulseAnimation.reset(m_localMouseBuffer.x, m_localMouseBuffer.y, m_barModelArea, 0xFF0000);
                        Starling.juggler.add(m_ringPulseAnimation);
                        
                        status = ScriptStatus.SUCCESS;
                    }
                }
                else if ((mouseState.leftMouseDraggedThisFrame || mouseState.leftMouseReleasedThisFrame) && m_hitBarLabelView != null)
                {
                    if (removeElement(m_hitBarLabelView))
                    {
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    m_hitBarLabelView = null;
                }
            }
            
            return status;
        }
        
        /**
         * Function checks if the current mouse point (with frame of reference to the bar model area) has
         * hit the appropriate area of a horizontal label.
         * 
         * @return
         *      null if no horizontal label was hit
         */
        private function checkHitHorizontalLabel():BarLabelView
        {
            var hitLabel:BarLabelView = null;
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var numBarWholeViews:int = barWholeViews.length;
            var i:int;
            for (i = 0; i < numBarWholeViews; i++)
            {
                var barLabelViews:Vector.<BarLabelView> = barWholeViews[i].labelViews;
                var numBarLabelViews:int = barLabelViews.length;
                var j:int;
                var barLabelView:BarLabelView;
                for (j = 0; j < numBarLabelViews; j++)
                {
                    barLabelView = barLabelViews[j];
                    
                    if (barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE && m_barModelArea.stage != null)
                    {
                        // The rigid body property accounts for the brackets
                        var didHitLabel:Boolean = barLabelView.rigidBody.boundingRectangle.containsPoint(m_localMouseBuffer);
                        if (!didHitLabel)
                        {
                            // We also factor in the label graphic
                            var labelDescriptionDisplay:DisplayObject = barLabelView.getDescriptionDisplay();
                            labelDescriptionDisplay.getBounds(m_barModelArea, m_labelDescriptionBounds);
                            didHitLabel = m_labelDescriptionBounds.containsPoint(m_localMouseBuffer);
                        }
                        
                        if (didHitLabel)
                        {
                            hitLabel = barLabelView;
                            break;
                        }
                    }
                }
                
                if (hitLabel != null)
                {
                    break;
                }
            }
            
            return hitLabel;
        }
        
        private function onRingPulseAnimationComplete():void
        {
            // Make sure animation isn't showing
            Starling.juggler.remove(m_ringPulseAnimation);
        }
    }
}