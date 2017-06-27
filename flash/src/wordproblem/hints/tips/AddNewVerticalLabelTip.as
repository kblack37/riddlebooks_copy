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
    import dragonbox.common.math.vectorspace.IVectorSpace;
    import dragonbox.common.math.vectorspace.RealsVectorSpace;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.XColor;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewVerticalLabel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    public class AddNewVerticalLabelTip extends BarModelTip
    {
        private var m_widgetDragSystem:WidgetDragSystem;
        private var m_vectorSpace:IVectorSpace;
        
        private var m_orderedGestures:PrioritySelector;
        
        public function AddNewVerticalLabelTip(expressionSymbolMap:ExpressionSymbolMap, 
                                               canvas:DisplayObjectContainer, 
                                               mouseState:MouseState, 
                                               time:Time, 
                                               assetManager:AssetManager,
                                               screenBounds:Rectangle, 
                                               titleText:String, 
                                               id:String=null, 
                                               isActive:Boolean=true)
        {
            super(expressionSymbolMap, 
                canvas, 
                mouseState, 
                time, 
                assetManager, 
                DEFAULT_BAR_MODEL_WIDTH, 
                DEFAULT_BAR_MODEL_HEIGHT, 
                screenBounds, 
                titleText, 
                "Drag here to show boxes on different lines are equal to something.", 
                id, 
                isActive
            );
            
            m_barModelArea.topBarPadding = 20;
            m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
            m_widgetDragSystem.setParams(mouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
            
            m_orderedGestures = new PrioritySelector();
            var addNewLabel:AddNewVerticalLabel = new AddNewVerticalLabel(null, null, assetManager, 1);
            addNewLabel.setCommonParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, mouseState);
            m_orderedGestures.pushChild(addNewLabel);
            
            var addNewLabelHitArea:ShowBarModelHitAreas = new ShowBarModelHitAreas(
                null, null, assetManager, null);
            addNewLabelHitArea.setParams(m_barModelArea, m_widgetDragSystem, addNewLabel);
            m_orderedGestures.pushChild(addNewLabelHitArea);
            
            m_vectorSpace = new RealsVectorSpace();
        }
        
        override public function visit():int
        {
            super.visit();
            
            m_widgetDragSystem.visit();
            m_orderedGestures.visit();
            
            return ScriptStatus.FAIL;
        }
        
        override public function show():void
        {
            super.show();
            
            setBarModelToStartState();
            
            // Once the initial bar model has been drawn we can measure the correct
            // positions of where the dragged widget should go
            var globalReferenceObject:DisplayObject = m_canvas.stage;
            var barWholeToAddName:BarWholeView = m_barModelArea.getBarWholeViews()[0];
            var barWholeBounds:Rectangle = barWholeToAddName.getBounds(globalReferenceObject);
            
            var addLabelScript:AddNewVerticalLabel = m_orderedGestures.getChildren()[0] as AddNewVerticalLabel;
            var addLabelHitArea:Rectangle = addLabelScript.getActiveHitAreas()[0].clone();
            
            // Need to translate to global
            var globalPoint:Point = m_barModelArea.localToGlobal(new Point(addLabelHitArea.x, addLabelHitArea.y));
            addLabelHitArea.x = globalPoint.x;
            addLabelHitArea.y = globalPoint.y;
            
            // The start drag location is above the bars
            var startDragLocation:Point = new Point(
                barWholeBounds.left + barWholeBounds.width * 0.5, 
                barWholeBounds.top - 50
            );
            
            // The final drag location is in the middle of the hit area
            var finalDragLocation:Point = new Point(
                addLabelHitArea.left + addLabelHitArea.width * 0.5, 
                addLabelHitArea.top + addLabelHitArea.height * 0.5
            );
            
            var mainAnimationEvents:Vector.<SequenceEvent> = new Vector.<SequenceEvent>();
            var mainAnimationSequence:Sequence = new Sequence(mainAnimationEvents);
            
            // Hold the card for some number of seconds
            mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDragOfExpression, [startDragLocation, "a", m_widgetDragSystem, m_vectorSpace], new ExecuteOnceEndTrigger()));
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
            m_widgetDragSystem.manuallyEndDrag();
            m_playbackEvents.dispose();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_widgetDragSystem.dispose();
            m_orderedGestures.dispose();
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
            createBarWhole(3, 1);
            createBarWhole(2, 2);
            m_barModelArea.setBarModelData(exampleBarModel);
            m_barModelArea.redraw(false);
            
            function createBarWhole(numSegments:int, valuePerSegment:Number):void
            {
                var barWhole:BarWhole = new BarWhole(false);
                for (var i:int = 0; i < numSegments; i++)
                {
                    barWhole.barSegments.push(new BarSegment(valuePerSegment, 1, XColor.getDistributedHsvColor(Math.random()), null));
                }
                exampleBarModel.barWholes.push(barWhole);
            }
        }
    }
}