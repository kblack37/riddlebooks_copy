package wordproblem.scripts.barmodel
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script handles the removal of a label that is pasted directly on top
     * of a bar segment.
     */
    public class RemoveLabelOnSegment extends BaseBarModelScript implements IRemoveBarElement
    {
        /**
         * When the user presses down this is the label that was selected.
         * Null if no valid label was selected on press
         */
        private var m_hitBarLabelView:BarLabelView;
        
        /**
         * To remove a label, we detect a press on the descrption area for that label
         */
        private var m_labelDescriptionBounds:Rectangle;
        
        public function RemoveLabelOnSegment(gameEngine:IGameEngine, 
                                             expressionCompiler:IExpressionTreeCompiler, 
                                             assetManager:AssetManager, 
                                             id:String=null, 
                                             isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_labelDescriptionBounds = new Rectangle();
        }
        
        public function removeElement(element:DisplayObject):Boolean
        {
            var canRemove:Boolean = false;
            if (element is BarLabelView)
            {
                var hitBarLabelView:BarLabelView = element as BarLabelView;
                if (hitBarLabelView.data.bracketStyle == BarLabel.BRACKET_NONE && hitBarLabelView.data.isHorizontal)
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
                            if (barLabel.id == hitBarLabelView.data.id)
                            {
                                var referencedSegmentView:BarSegmentView = m_barModelArea.getBarWholeViews()[i].segmentViews[barLabel.startSegmentIndex];
                                var segementViewBounds:Rectangle = referencedSegmentView.rigidBody.boundingRectangle;
                                
                                // Create copy of the label for the animation, original gets disposed on redraw
                                var removedLabelView:BarLabelView = m_barModelArea.createBarLabelView(hitBarLabelView.data);
                                removedLabelView.rescaleAndRedraw(segementViewBounds.width, segementViewBounds.height, 1, 1);
                                removedLabelView.resizeToLength(hitBarLabelView.pixelLength);
                                var globalCoordinates:Point = hitBarLabelView.localToGlobal(new Point(0, 0));
                                removedLabelView.pivotX = removedLabelView.width * 0.5;
                                removedLabelView.pivotY = removedLabelView.height * 0.5;
                                removedLabelView.x = globalCoordinates.x + removedLabelView.pivotX;
                                removedLabelView.y = globalCoordinates.y + removedLabelView.pivotY;
                                
                                var popOffTween:Tween = new Tween(removedLabelView, 0.5);
                                popOffTween.animate("rotation", -Math.PI * 0.5);
                                popOffTween.fadeTo(0.0);
                                popOffTween.scaleTo(0.2);
                                popOffTween.moveTo(removedLabelView.x - 200, removedLabelView.y);
                                popOffTween.onComplete = function():void
                                {
                                    removedLabelView.removeFromParent(true);
                                    Starling.juggler.remove(popOffTween);
                                };
                                
                                m_gameEngine.getSprite().stage.addChild(removedLabelView);
                                Starling.juggler.add(popOffTween);
                                
                                var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                                barWhole.barLabels.splice(j, 1);
                                m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                                
                                m_barModelArea.redraw();
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
                    m_hitBarLabelView = checkHitLabel();
                    if (m_hitBarLabelView != null)
                    {
                        m_hitBarLabelView.setBracketAndDescriptionAlpha(0.3);
                        //m_ringPulseAnimation.reset(m_localMouseBuffer.x, m_localMouseBuffer.y, m_barModelArea, 0xFF0000);
                        //Starling.juggler.add(m_ringPulseAnimation);
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
         *
         * @return
         *      null if no label hit,
         */
        private function checkHitLabel():BarLabelView
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
                    
                    if (barLabelView.data.bracketStyle == BarLabel.BRACKET_NONE && m_barModelArea.stage != null)
                    {
                        // For labels directly on a segment we only factor in the label graphic
                        // since that is all that is there
                        var labelDescriptionDisplay:DisplayObject = barLabelView.getDescriptionDisplay();
                        labelDescriptionDisplay.getBounds(m_barModelArea, m_labelDescriptionBounds);
                        if (m_labelDescriptionBounds.containsPoint(m_localMouseBuffer))
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
    }
}