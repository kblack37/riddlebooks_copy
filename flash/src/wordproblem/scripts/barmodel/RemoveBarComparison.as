package wordproblem.scripts.barmodel
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.util.MathUtil;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObject;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.animation.RemoveResizeableBarPieceAnimation;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarComparisonView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    public class RemoveBarComparison extends BaseBarModelScript implements IRemoveBarElement
    {
        /**
         * A buffer that stores the hit comparison view and id of the bar containing it
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        /**
         * Reference to the comparison that was selected
         */
        private var m_hitBarComparisonView:BarComparisonView;
        
        /**
         * Need to measure the total bounds of the comparison, which includes both the arrow
         * and the label on top.
         */
        private var m_boundsBuffer:Rectangle;
        
        private var m_pressMouseBuffer:Point;
        
        public function RemoveBarComparison(gameEngine:IGameEngine, 
                                            expressionCompiler:IExpressionTreeCompiler, 
                                            assetManager:AssetManager, 
                                            id:String=null, 
                                            isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_outParamsBuffer = new Vector.<Object>();
            m_boundsBuffer = new Rectangle();
            m_pressMouseBuffer = new Point();
        }
        
        public function removeElement(element:DisplayObject):Boolean
        {
            var canRemove:Boolean = false;
            if (element is BarComparisonView)
            {
                var hitBarComparisonView:BarComparisonView = element as BarComparisonView;
                
                // Search for the bar whole with the matching id and then remove the comparison
                var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                var numBarWholes:int = barWholes.length;
                var i:int;
                var barWhole:BarWhole;
                for (i = 0; i < numBarWholes; i++)
                {
                    barWhole = barWholes[i];
                    if (barWhole.barComparison != null && barWhole.barComparison.id == hitBarComparisonView.data.id)
                    {
                        // Create animation where the comparison quickly shrinks in size like it is being rolled up before
                        // falling off the edge (Need to create a clone of the label as the original is disposed on a redraw)
                        var removedComparisonView:BarComparisonView = m_barModelArea.createBarComparisonView(hitBarComparisonView.data);
                        removedComparisonView.resizeToLength(hitBarComparisonView.pixelLength);
                        var globalCoordinates:Point = hitBarComparisonView.localToGlobal(new Point(0, 0));
                        removedComparisonView.x = globalCoordinates.x;
                        removedComparisonView.y = globalCoordinates.y;
                        var removeBarComparisonAnimation:RemoveResizeableBarPieceAnimation = new RemoveResizeableBarPieceAnimation(function():void
                        {
                            removedComparisonView.removeFromParent(true);
                        });
                        removedComparisonView.scaleX = removedComparisonView.scaleY = m_barModelArea.scaleFactor;
                        m_gameEngine.getSprite().addChild(removedComparisonView);
                        removeBarComparisonAnimation.play(removedComparisonView);
                        
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        barWhole.barComparison = null;  // Remove the comparison from the model
                        m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        m_barModelArea.redraw();
                        
                        // Log removal of a bar comparison
                        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.REMOVE_BAR_COMPARISON, false, {barModel:m_barModelArea.getBarModelData().serialize()});
                        
                        break;
                    }
                }
                canRemove = true;
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
                
                m_outParamsBuffer.length = 0;
                if (mouseState.leftMousePressedThisFrame)
                {
                    if (checkHitBarComparison(m_outParamsBuffer))
                    {
                        m_pressMouseBuffer.setTo(m_globalMouseBuffer.x, m_globalMouseBuffer.y);
                        m_hitBarComparisonView = m_outParamsBuffer[0] as BarComparisonView;
                        m_hitBarComparisonView.alpha = 0.5;
                        status = ScriptStatus.SUCCESS;
                    }
                }
                // To remove player need to drag away the piece
                else if (mouseState.leftMouseDraggedThisFrame && m_hitBarComparisonView != null)
                {
                    // See if they dragged far away enough from the drag point
                    var radius:Number = 8;
                    if (!MathUtil.pointInCircle(m_pressMouseBuffer, radius, m_globalMouseBuffer))
                    {
                        removeElement(m_hitBarComparisonView);
                        m_hitBarComparisonView.alpha = 1.0;
                        m_hitBarComparisonView = null;
                        
                        status = ScriptStatus.SUCCESS;
                    }
                }
                else if (mouseState.leftMouseReleasedThisFrame && m_hitBarComparisonView != null)
                {
                    m_hitBarComparisonView.alpha = 1.0;
                    m_hitBarComparisonView = null;
                }
            }
            
            return status;
        }
        
        private function checkHitBarComparison(outParams:Vector.<Object>):Boolean
        {
            var hitComparison:Boolean = false;
            var outBounds:Rectangle = new Rectangle();
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var numBarWholeViews:int = barWholeViews.length;
            var i:int;
            var barWholeView:BarWholeView;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = barWholeViews[i];
                
                // For remove we check if the player has hit any portion of the comparison,
                // this includes the textfield which is not part of the rigid body bounds
                var barComparisonView:BarComparisonView = barWholeView.comparisonView;
                if (barComparisonView != null)
                {
                    barComparisonView.getBounds(m_barModelArea, m_boundsBuffer);
                    if (m_boundsBuffer.containsPoint(m_localMouseBuffer))
                    {
                        hitComparison = true;
                        outParams.push(barComparisonView, barWholeView.data.id);
                        break;
                    }
                }
            }
            return hitComparison;
        }
    }
}