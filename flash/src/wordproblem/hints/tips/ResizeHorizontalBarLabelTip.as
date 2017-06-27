package wordproblem.hints.tips
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.eventSequence.CustomSequenceEvent;
    import dragonbox.common.eventSequence.EventSequencer;
    import dragonbox.common.eventSequence.Sequence;
    import dragonbox.common.eventSequence.SequenceEvent;
    import dragonbox.common.eventSequence.endtriggers.ExecuteOnceEndTrigger;
    import dragonbox.common.eventSequence.endtriggers.TimerEndTrigger;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.XColor;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.ResizeHorizontalBarLabel;
    
    public class ResizeHorizontalBarLabelTip extends BarModelTip
    {
        private var m_resizeLabelGesture:ResizeHorizontalBarLabel;
        
        public function ResizeHorizontalBarLabelTip(expressionSymbolMap:ExpressionSymbolMap, 
                                                    canvas:DisplayObjectContainer, 
                                                    mouseState:MouseState, 
                                                    time:Time, 
                                                    assetManager:AssetManager,
                                                    screenBounds:Rectangle,
                                                    id:String=null, 
                                                    isActive:Boolean=true)
        {
            super(expressionSymbolMap, canvas, mouseState, time, assetManager, 400, 170, screenBounds,
                id,
                "This changes the number of boxes a name is equal to.", id, isActive);
            
            m_resizeLabelGesture = new ResizeHorizontalBarLabel(null, null, assetManager);
            m_resizeLabelGesture.setCommonParams(m_barModelArea, null, m_gameEnginePlaceholderEventDispatcher, mouseState);
            m_resizeLabelGesture.setIsActive(true);
        }
        
        override public function visit():int
        {
            super.visit();

            m_resizeLabelGesture.visit();
            
            return ScriptStatus.FAIL;
        }
        
        override public function show():void
        {
            super.show();
            
            setBarModelToStartState();
            
            // Move the mouse to the edge point of the label
            // Then drag the mouse horizontally so it sets to a segment edge further to the left
            var globalReferenceObject:DisplayObject = m_canvas.stage;
            var labelToResize:BarLabelView = m_barModelArea.getBarWholeViews()[0].labelViews[0];
            
            // The hit areas are a small radius are the left and right edges of the label
            var labelBounds:Rectangle = labelToResize.rigidBody.boundingRectangle.clone();
            var globalPoint:Point = m_barModelArea.localToGlobal(new Point(labelBounds.x, labelBounds.y));
            labelBounds.x = globalPoint.x;
            labelBounds.y = globalPoint.y;
            
            // The mouse should start at the edge of the label
            var startDragLocation:Point = new Point(
                labelBounds.right, 
                labelBounds.top + labelBounds.height * 0.5
            );
            
            // The final drag should be at the edge of a new segment
            var segmentToDragTo:BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[2];
            var segmentBounds:Rectangle = segmentToDragTo.rigidBody.boundingRectangle.clone();
            var segmentGlobalPoint:Point = m_barModelArea.localToGlobal(new Point(segmentBounds.x, segmentBounds.y));
            segmentBounds.x = segmentGlobalPoint.x;
            segmentBounds.y = segmentGlobalPoint.y;
            
            var finalDragLocation:Point = new Point(
                segmentBounds.right, 
                labelBounds.y
            );
            
            var mainAnimationEvents:Vector.<SequenceEvent> = new Vector.<SequenceEvent>();
            var mainAnimationSequence:Sequence = new Sequence(mainAnimationEvents);
            
            // Hold the card for some number of seconds
            mainAnimationEvents.push(new CustomSequenceEvent(moveMouseTo, [startDragLocation], new ExecuteOnceEndTrigger()));
            mainAnimationEvents.push(new CustomSequenceEvent(pressMouseDown, null, new ExecuteOnceEndTrigger()));
            mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
            // Drag it to the space for comparison
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(startDragLocation, finalDragLocation, 1.0, m_simulatedMouseState));
            mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
            mainAnimationEvents.push(new CustomSequenceEvent(releaseMouse, null, new ExecuteOnceEndTrigger()));
            mainAnimationEvents.push(new SequenceEvent(new TimerEndTrigger(500)));
            mainAnimationEvents.push(new CustomSequenceEvent(loopBack, [mainAnimationSequence], new ExecuteOnceEndTrigger()));
            
            var sequences:Vector.<Sequence> = new Vector.<Sequence>();
            sequences.push(mainAnimationSequence);
            m_playbackEvents = new EventSequencer(sequences);
            m_playbackEvents.start();
        }
        
        override public function hide():void
        {
            super.hide();
            m_playbackEvents.dispose();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_resizeLabelGesture.dispose();
        }
        
        private function pressMouseDown():void
        {
            m_simulatedMouseState.leftMousePressedThisFrame = true;
            m_simulatedMouseState.leftMouseDown = true;
        }
        
        private function moveMouseTo(position:Point):void
        {
            m_simulatedMouseState.mousePositionThisFrame.x = position.x;
            m_simulatedMouseState.mousePositionThisFrame.y = position.y;
        }
        
        private function loopBack(sequenceToLoop:Sequence):void
        {
            sequenceToLoop.reset();
            
            // Reset the bar model
            setBarModelToStartState();
            
            // Restart the given sequence after reset
            sequenceToLoop.start();
        }
        
        private function setBarModelToStartState():void
        {
            var exampleBarModel:BarModelData = new BarModelData();
            var barWholeToDivide:BarWhole = new BarWhole(false);
            
            var numSegments:int = 5;
            var color:uint = XColor.getDistributedHsvColor(Math.random());
            for (var i:int = 0; i < numSegments; i++)
            {
                barWholeToDivide.barSegments.push(new BarSegment(1, 1, color, null));
            }
            
            barWholeToDivide.barLabels.push(new BarLabel("a", 0, numSegments - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            exampleBarModel.barWholes.push(barWholeToDivide);
            
            m_barModelArea.setBarModelData(exampleBarModel);
            m_barModelArea.redraw(true);
        }
    }
}