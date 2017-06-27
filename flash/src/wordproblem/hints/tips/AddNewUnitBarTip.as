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
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewUnitBar;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    public class AddNewUnitBarTip extends BarModelTip
    {
        private var m_widgetDragSystem:WidgetDragSystem;
        private var m_vectorSpace:IVectorSpace;
        
        private var m_orderedGestures:PrioritySelector;
        
        public function AddNewUnitBarTip(expressionSymbolMap:ExpressionSymbolMap,
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
                "When you drag a number here, it will make that number of equal sized boxes.",
                id, isActive);
            
            m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
            m_widgetDragSystem.setParams(mouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
            
            m_orderedGestures = new PrioritySelector();
            var addNewUnitBar:AddNewUnitBar = new AddNewUnitBar(null, null, assetManager, 30);
            addNewUnitBar.setParams(m_barModelArea, m_widgetDragSystem, mouseState, expressionSymbolMap, m_barModelArea.unitLength, m_gameEnginePlaceholderEventDispatcher);
            m_orderedGestures.pushChild(addNewUnitBar);
            
            var addNewUnitBarHitArea:ShowBarModelHitAreas = new ShowBarModelHitAreas(
                null, null, assetManager, null);
            addNewUnitBarHitArea.setParams(m_barModelArea, m_widgetDragSystem, addNewUnitBar);
            m_orderedGestures.pushChild(addNewUnitBarHitArea);
            
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
            
            var barModelBounds:Rectangle = m_barModelArea.getBounds(globalReferenceObject);

            // Hit areas are relative to the bar model reference
            var addUnitBar:AddNewUnitBar = m_orderedGestures.getChildren()[0] as AddNewUnitBar;
            var hitAreas:Vector.<Rectangle> = addUnitBar.getActiveHitAreas();
            var unitHitAreaBounds:Rectangle = hitAreas[0].clone();
            
            // Need to translate to global
            var globalPoint:Point = m_barModelArea.localToGlobal(new Point(unitHitAreaBounds.x, unitHitAreaBounds.y));
            unitHitAreaBounds.x = globalPoint.x;
            unitHitAreaBounds.y = globalPoint.y;
            
            // The start drag location is above the bars
            var startDragLocation:Point = new Point(
                barModelBounds.width * 0.5 + barModelBounds.x, barModelBounds.top - 20
            );
            
            // The final drag location is in the hit area new the left edge
            var finalDragLocation:Point = new Point(
                unitHitAreaBounds.left + unitHitAreaBounds.width * 0.5, 
                unitHitAreaBounds.top + unitHitAreaBounds.height * 0.5
            );
            
            var mainAnimationEvents:Vector.<SequenceEvent> = new Vector.<SequenceEvent>();
            var mainAnimationSequence:Sequence = new Sequence(mainAnimationEvents);
            
            // Hold the card for some number of seconds
            mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDragOfExpression, [startDragLocation, "3", m_widgetDragSystem, m_vectorSpace], new ExecuteOnceEndTrigger()));
            mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
            // Drag it to the space for comparison
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(startDragLocation, finalDragLocation, 0.75, m_simulatedMouseState));
            mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(1500)));
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
            m_barModelArea.setBarModelData(exampleBarModel);
            m_barModelArea.redraw(false);
        }
    }
}