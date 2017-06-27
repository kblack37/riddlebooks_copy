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
    
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.hints.scripts.IShowableScript;
    import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBarComparison;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    /**
     * Sample script to control showing a movie clip like animation of how to apply this gesture
     */
    public class AddNewBarComparisonTip extends BarModelTip implements IShowableScript
    {
        private var m_widgetDragSystem:WidgetDragSystem;
        private var m_vectorSpace:IVectorSpace;
        
        private var m_orderedGestures:PrioritySelector;
        
        public function AddNewBarComparisonTip(expressionSymbolMap:ExpressionSymbolMap,
                                               canvas:DisplayObjectContainer,
                                               mouseState:MouseState,
                                               time:Time,
                                               assetManager:AssetManager,
                                               screenBounds:Rectangle,
                                               id:String=null, 
                                               isActive:Boolean=true)
        {
            super(expressionSymbolMap, canvas, mouseState, time, assetManager, 
                DEFAULT_BAR_MODEL_WIDTH, DEFAULT_BAR_MODEL_HEIGHT, screenBounds,
                id,
                "This shows the difference between two boxes",
                id, isActive);
            
            m_barModelArea.topBarPadding = 20;
            m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
            m_widgetDragSystem.setParams(mouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
            
            m_orderedGestures = new PrioritySelector();
            var addBarComparison:AddNewBarComparison = new AddNewBarComparison(null, null, assetManager);
            addBarComparison.setCommonParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, mouseState);
            m_orderedGestures.pushChild(addBarComparison);
            
            var addBarComparisonHitArea:ShowBarModelHitAreas = new ShowBarModelHitAreas(
                null, null, assetManager, null);
            addBarComparisonHitArea.setParams(m_barModelArea, m_widgetDragSystem, addBarComparison);
            m_orderedGestures.pushChild(addBarComparisonHitArea);
            
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
            var greaterSegmentView:BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[0];
            var greaterSegmentBounds:Rectangle = greaterSegmentView.getBounds(globalReferenceObject);
            var lesserSegmentView:BarSegmentView = m_barModelArea.getBarWholeViews()[1].segmentViews[0];
            var lesserSegmentBounds:Rectangle = lesserSegmentView.getBounds(globalReferenceObject);
            
            // The start drag location is above the bars
            var startDragLocation:Point = new Point(
                greaterSegmentBounds.left + greaterSegmentBounds.width * 0.5, 
                greaterSegmentBounds.top - 50
            );
            
            // The final drag location is in the middle of the gap between the bigger and smaller bar
            var finalDragLocation:Point = new Point(
                (greaterSegmentBounds.right - lesserSegmentBounds.right) * 0.5 + lesserSegmentBounds.right, 
                lesserSegmentBounds.top + lesserSegmentBounds.height * 0.5
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
            var color:uint = XColor.getDistributedHsvColor(Math.random());
            var exampleBarModel:BarModelData = new BarModelData();
            var greaterBarWhole:BarWhole = new BarWhole(false);
            greaterBarWhole.barSegments.push(new BarSegment(3, 1, color, null));
            greaterBarWhole.barLabels.push(new BarLabel("3", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            exampleBarModel.barWholes.push(greaterBarWhole);
            
            var lesserBarWhole:BarWhole = new BarWhole(false);
            lesserBarWhole.barSegments.push(new BarSegment(1, 1, color, null));
            lesserBarWhole.barLabels.push(new BarLabel("1", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            exampleBarModel.barWholes.push(lesserBarWhole);
            
            m_barModelArea.setBarModelData(exampleBarModel);
            m_barModelArea.redraw(false);
        }
    }
}