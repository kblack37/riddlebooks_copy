package wordproblem.scripts.barmodel
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarModelData;
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
     * This script handles adding the new comparison segment to show the different
     * in value between a shorter and longer bar.
     */
    public class AddNewBarComparison extends BaseBarModelScript implements IHitAreaScript, ICardOnSegmentEdgeScript
    {
        /**
         * A buffer that stores the bar view that the comparison should add to
         */
        private var m_outParamsBuffer:Vector.<Object>;
        
        // Used to keep track of changes in which bars should be involved in the comparison
        private var m_currentTargetBarId:String;
        private var m_currentCompareToBarId:String;
        
        /**
         * Active hit areas on a given frame
         */
        private var m_hitAreas:Vector.<Rectangle>;
        private var m_hitAreaPool:Vector.<Rectangle>;
        
        /**
         * Extra list to map a hit area to a particular bar view
         */
        private var m_hitAreaBarIds:Vector.<String>;
        
        /**
         * Should hit areas for this action be shown in at the start of a frame
         */
        private var m_showHitAreas:Boolean;
        
        public function AddNewBarComparison(gameEngine:IGameEngine, 
                                            expressionCompiler:IExpressionTreeCompiler, 
                                            assetManager:AssetManager, 
                                            id:String=null, 
                                            isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_outParamsBuffer = new Vector.<Object>();
            m_hitAreas = new Vector.<Rectangle>();
            m_hitAreaPool = new Vector.<Rectangle>();
            m_hitAreaBarIds = new Vector.<String>();
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            m_showHitAreas = false;
            if (m_ready && m_isActive)
            {
                m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                m_outParamsBuffer.length = 0;
                
                if (m_eventTypeBuffer.length > 0)
                {
                    var data:Object = m_eventParamBuffer[0];
                    var releasedWidget:BaseTermWidget = data.widget;
                    
                    if (releasedWidget is SymbolTermWidget && checkOverHitArea(m_outParamsBuffer))
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        
                        var targetBarWholeView:BarWholeView = m_outParamsBuffer[0] as BarWholeView;
                        var barToCompareAgainst:BarWholeView = m_outParamsBuffer[1] as BarWholeView;
                        
                        var widthDifference:Number = barToCompareAgainst.segmentViews[barToCompareAgainst.segmentViews.length - 1].rigidBody.boundingRectangle.right - 
                            targetBarWholeView.segmentViews[targetBarWholeView.segmentViews.length - 1].rigidBody.boundingRectangle.right;
                        var releasedExpressionNode:ExpressionNode = releasedWidget.getNode();
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        addNewBarComparison(targetBarWholeView.data, releasedExpressionNode.data, barToCompareAgainst.data, barToCompareAgainst.segmentViews.length - 1);
                        
                        m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        m_barModelArea.redraw();
                        
                        m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, false, 
                            {barModel:m_barModelArea.getBarModelData().serialize(),
                                value:releasedExpressionNode.data});
                        
                        m_currentTargetBarId = null;
                        m_currentCompareToBarId = null;
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null && m_widgetDragSystem.getWidgetSelected() is SymbolTermWidget)
                {
                    m_showHitAreas = true;
                    if (checkOverHitArea(m_outParamsBuffer))
                    {
                        targetBarWholeView = m_outParamsBuffer[0] as BarWholeView;
                        barToCompareAgainst = m_outParamsBuffer[1] as BarWholeView;
                        var barsInComparisonDifferFromLastVisit:Boolean = m_currentCompareToBarId != barToCompareAgainst.data.id || 
                            m_currentTargetBarId != targetBarWholeView.data.id;
                        
                        // This check shows the preview if either it was not showing already OR a lower priority
                        // script had activated it but we want to overwrite it.
                        // Also redraw if the values changed from last time
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview || barsInComparisonDifferFromLastVisit)
                        {
                            m_currentTargetBarId = targetBarWholeView.data.id;
                            m_currentCompareToBarId = barToCompareAgainst.data.id;
                            
                            widthDifference = barToCompareAgainst.segmentViews[barToCompareAgainst.segmentViews.length - 1].rigidBody.boundingRectangle.right - 
                                targetBarWholeView.segmentViews[targetBarWholeView.segmentViews.length - 1].rigidBody.boundingRectangle.right;
                            releasedExpressionNode = m_widgetDragSystem.getWidgetSelected().getNode();
                            
                            var previewView:BarModelView = m_barModelArea.getPreviewView(true);
                            var previewBarWhole:BarWhole = previewView.getBarModelData().getBarWholeById(targetBarWholeView.data.id);
                            addNewBarComparison(previewBarWhole, releasedExpressionNode.data, barToCompareAgainst.data, barToCompareAgainst.segmentViews.length - 1);
                            m_barModelArea.showPreview(true);
                            m_didActivatePreview = true;
                            
                            // Blink the new comparison
                            var previewBarWholeWithComparison:BarWholeView = previewView.getBarWholeViewById(m_currentTargetBarId);
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(m_currentTargetBarId));
                            var renderComponent:RenderableComponent = new RenderableComponent(m_currentTargetBarId);
                            renderComponent.view = previewBarWholeWithComparison.comparisonView;
                            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                            
                            super.setDraggedWidgetVisible(false);
                        }
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    else if (m_didActivatePreview)
                    {
                        // Remove the preview
                        m_barModelArea.componentManager.removeAllComponentsFromEntity(m_currentTargetBarId);
                        m_currentTargetBarId = null;
                        m_currentCompareToBarId = null;
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        super.setDraggedWidgetVisible(true);
                    }
                }
            }
            return status;
        }
        
        override public function reset():void
        {
            super.reset();
            
            m_showHitAreas = false;
            m_barModelArea.componentManager.removeAllComponentsFromEntity(m_currentTargetBarId);
        }
        
        public function getActiveHitAreas():Vector.<Rectangle>
        {
            calculateHitAreas();
            return m_hitAreas;
        }
        
        public function getShowHitAreasForFrame():Boolean
        {
            return m_showHitAreas;
        }
        
        public function postProcessHitAreas(hitAreas:Vector.<Rectangle>, hitAreaGraphics:Vector.<DisplayObjectContainer>):void
        {
            for (var i:int = 0; i < hitAreas.length; i++)
            {
                var icon:Image = new Image(m_assetManager.getTexture("subtract"));
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
            while (m_hitAreas.length > 0)
            {
                m_hitAreaPool.push(m_hitAreas.pop());
            }
            
            m_hitAreaBarIds.length = 0;
            
            // For each individual bar, the hit area starts at the edge of the end and
            // extends to the edge of the longest bar
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var i:int;
            var numBarWholeViews:int = barWholeViews.length;
            var barWholeView:BarWholeView;
            
            // First find the end of the longest bar, the is the rightmost limit for all bars
            var longestBarViewIndex:int = -1;
            var furthestRightEdgeX:Number = 0;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = barWholeViews[i];
                var segmentViews:Vector.<BarSegmentView> = barWholeView.segmentViews;
                var rightEdgeX:Number = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle.right;
                if (longestBarViewIndex == -1 || rightEdgeX > furthestRightEdgeX)
                {
                    longestBarViewIndex = i;
                    furthestRightEdgeX = rightEdgeX;
                }
            }
            
            // With the proper end, go through each bar and treat each having a hit area
            // extending horizontally from its last segment edge to the furthest edge of the longest bar
            // and vertically from the top and bottom of its segments
            for (i = 0; i < numBarWholeViews; i++)
            {
                // No hit area for the longest bar since we define the comparison to always span from
                // a smaller value to a larger one.
                if (i != longestBarViewIndex)
                {
                    barWholeView = barWholeViews[i];
                    segmentViews = barWholeView.segmentViews;
                    var lastSegmentBounds:Rectangle = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle;
                    var leftEdgeX:Number = lastSegmentBounds.right;
                    var topEdgeY:Number = lastSegmentBounds.top;
                    var hitAreaHeight:Number = lastSegmentBounds.height;
                    var hitAreaWidth:Number = furthestRightEdgeX - leftEdgeX;
                    
                    // Grab a rectangle from the pool
                    var hitArea:Rectangle = (m_hitAreaPool.length > 0) ? m_hitAreaPool.pop() : new Rectangle();
                    hitArea.setTo(leftEdgeX, topEdgeY, hitAreaWidth, hitAreaHeight);
                    m_hitAreas.push(hitArea);
                    
                    m_hitAreaBarIds.push(barWholeView.data.id);
                }
            }
        }
        
        /**
         *
         * @param outParams
         *      First index is the target bar whole view that was hit
         *      Second index is the bar to compare against (should always be longer than the first)
         */
        private function checkOverHitArea(outParams:Vector.<Object>):Boolean
        {
            var doAddComparison:Boolean = false;
            calculateHitAreas();
            
            var i:int;
            var numHitAreas:int = m_hitAreas.length;
            var hitArea:Rectangle;
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var numBarWholeViews:int = barWholeViews.length;
            for (i = 0; i < numHitAreas; i++)
            {
                hitArea = m_hitAreas[i];
                
                if (hitArea.width > 0.01 && hitArea.containsPoint(m_localMouseBuffer))
                {
                    // If we are in the hit area we now need to determine which bar this one should
                    // compare against.
                    // We can do this by finding the rightmost edge of every OTHER bar and figuring out
                    // which one is closest to the current mouse x.
                    // The mouse x must also be to the left of that edge and right of the current bar's
                    // right edge (i.e. can only compare with bars longer than it)
                    var j:int;
                    var closestBarIndex:int = -1;
                    var closestDistance:Number = 0;
                    for (j = 0; j < numBarWholeViews; j++)
                    {
                        var otherBarWholeView:BarWholeView = barWholeViews[j];
                        if (otherBarWholeView.data.id != m_hitAreaBarIds[i])
                        {
                            var otherBarSegmentViews:Vector.<BarSegmentView> = otherBarWholeView.segmentViews;
                            var rightEdgeXOtherBar:Number = otherBarSegmentViews[otherBarSegmentViews.length - 1].rigidBody.boundingRectangle.right;
                            if (m_localMouseBuffer.x < rightEdgeXOtherBar && rightEdgeXOtherBar > hitArea.left)
                            {
                                var mouseDeltaFromEdge:Number = rightEdgeXOtherBar - m_localMouseBuffer.x;
                                if (closestBarIndex == -1 || mouseDeltaFromEdge < closestDistance)
                                {
                                    closestBarIndex = j;
                                    closestDistance = mouseDeltaFromEdge;
                                }
                            }
                        }
                    }
                    
                    if (closestBarIndex != -1)
                    {
                        doAddComparison = true;
                        var targetBarWholeView:BarWholeView = m_barModelArea.getBarWholeViewById(m_hitAreaBarIds[i]);
                        outParams.push(targetBarWholeView, barWholeViews[closestBarIndex]);
                    }
                    
                    break;
                }
            }
            
            return doAddComparison;
        }

        public function addNewBarComparison(barWhole:BarWhole, 
                                            value:String, 
                                            barWholeToCompareTo:BarWhole, 
                                            segmentIndexToCompareTo:int):void
        {
            var newBarComparison:BarComparison = new BarComparison(value, barWholeToCompareTo.id, segmentIndexToCompareTo);
            barWhole.barComparison = newBarComparison;
        }
        
        public function canPerformAction(draggedWidget:DisplayObject, barWholeId:String):Boolean
        {
            // Find the given bar whole
            var canPerformAction:Boolean = false;
            
            // Only allow comparison is currently dragged widget is card and the target bar is not the longest
            // (User can also drag boxes, which do not make sense in terms of creating a comparison)
            if (draggedWidget is SymbolTermWidget)
            {
                var matchingBarWholeView:BarWholeView = m_barModelArea.getBarWholeViewById(barWholeId);
                var otherBarWhole:BarWhole = getLongestOtherBarWholeIdToCompare(barWholeId);
                canPerformAction = matchingBarWholeView != null && matchingBarWholeView.data != otherBarWhole && otherBarWhole != null;
            }
            
            return canPerformAction;
        }
        
        public function performAction(draggedWidget:DisplayObject, extraParams:Object, barWholeId:String):void
        {
            // Dispose the preview if it was shown
            if (draggedWidget is SymbolTermWidget)
            {
                hidePreview();
                
                var cardValue:String = (draggedWidget as SymbolTermWidget).getNode().data;
                var matchingBarWholeView:BarWholeView = m_barModelArea.getBarWholeViewById(barWholeId);
                var otherBarWhole:BarWhole = getLongestOtherBarWholeIdToCompare(barWholeId);
                if (otherBarWhole != null && matchingBarWholeView != null)
                {
                    var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                    this.addNewBarComparison(matchingBarWholeView.data, cardValue, otherBarWhole, otherBarWhole.barSegments.length - 1);
                    
                    m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                    
                    // Redraw at the end to refresh
                    m_barModelArea.redraw();
                    
                    // Log splitting on an existing segment
                    m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, false, {
                        barModel:m_barModelArea.getBarModelData().serialize(),
                        value:cardValue
                    });
                }
            }
        }
        
        private function getLongestOtherBarWholeIdToCompare(barWholeId:String):BarWhole
        {
            var otherBarWhole:BarWhole = null;
            var matchingBarWholeView:BarWholeView = m_barModelArea.getBarWholeViewById(barWholeId);
            if (matchingBarWholeView != null)
            {
                // A comparison can be added only if there is another bar that is longer. If there are multiple ones,
                // we pick the longest one
                var valueOfCurrentBarWhole:Number = matchingBarWholeView.data.getValue();
                var otherBarWholeViewToCompare:BarWholeView = null;
                for each (var otherBarWholeView:BarWholeView in m_barModelArea.getBarWholeViews())
                {
                    if (otherBarWholeView != matchingBarWholeView)
                    {
                        var valueOfOtherBarWhole:Number = otherBarWholeView.data.getValue();
                        if (valueOfOtherBarWhole > valueOfCurrentBarWhole)
                        {
                            otherBarWhole = otherBarWholeView.data;
                            break;
                        }
                    }
                }
            }
            
            return otherBarWhole;
        }
        
        public function showPreview(draggedWidget:DisplayObject, extraParams:Object, barWholeId:String):void
        {
            if (draggedWidget is SymbolTermWidget)
            {
                var cardValue:String = (draggedWidget as SymbolTermWidget).getNode().data;
                var targetBarWholeView:BarWhole = m_barModelArea.getBarModelData().getBarWholeById(barWholeId);
                var otherBarWholeToCompare:BarWhole = getLongestOtherBarWholeIdToCompare(barWholeId);
                
                var previewView:BarModelView = m_barModelArea.getPreviewView(true);
                var previewTargetBarWhole:BarWhole = previewView.getBarModelData().getBarWholeById(barWholeId);
                var previewOtherBarWhole:BarWhole = previewView.getBarModelData().getBarWholeById(otherBarWholeToCompare.id);
                this.addNewBarComparison(previewTargetBarWhole, cardValue, previewOtherBarWhole, previewOtherBarWhole.barSegments.length - 1);
                
                m_barModelArea.showPreview(true);
                
                // Blink the new comparison
                var previewBarWholeWithComparison:BarWholeView = previewView.getBarWholeViewById(barWholeId);
                m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(barWholeId));
                var renderComponent:RenderableComponent = new RenderableComponent(barWholeId);
                renderComponent.view = previewBarWholeWithComparison.comparisonView;
                m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                m_currentTargetBarId = barWholeId;
            }
        }
        
        public function hidePreview():void
        {
            m_barModelArea.showPreview(false);
            
            // Remove the blink from the preview comparison
            m_barModelArea.componentManager.removeAllComponentsFromEntity(m_currentTargetBarId);
        }
    }
}