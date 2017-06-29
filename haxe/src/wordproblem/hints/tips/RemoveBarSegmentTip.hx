package wordproblem.hints.tips;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.eventsequence.CustomSequenceEvent;
import dragonbox.common.eventsequence.EventSequencer;
import dragonbox.common.eventsequence.Sequence;
import dragonbox.common.eventsequence.SequenceEvent;
import dragonbox.common.eventsequence.endtriggers.ExecuteOnceEndTrigger;
import dragonbox.common.eventsequence.endtriggers.TimerEndTrigger;
import dragonbox.common.math.vectorspace.IVectorSpace;
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
import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.RemoveBarSegment;
import wordproblem.scripts.drag.WidgetDragSystem;

class RemoveBarSegmentTip extends BarModelTip
{
    private var m_widgetDragSystem : WidgetDragSystem;
    private var m_vectorSpace : IVectorSpace;
    
    private var m_orderedGestures : PrioritySelector;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            canvas : DisplayObjectContainer,
            mouseState : MouseState,
            time : Time,
            assetManager : AssetManager,
            screenBounds : Rectangle,
            id : String = null,
            isActive : Bool = true)
    {
        super(expressionSymbolMap, canvas, mouseState, time, assetManager,
                270, 190, screenBounds,
                id,
                "This removes a part that you do not want in the answer. Press on and drag away to remove a part.",
                id, isActive);
        
        m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
        m_widgetDragSystem.setParams(m_simulatedMouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
        
        m_orderedGestures = new PrioritySelector();
        
        var removeBarSegment : RemoveBarSegment = new RemoveBarSegment(null, null, assetManager);
        removeBarSegment.setCommonParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, m_simulatedMouseState);
        m_orderedGestures.pushChild(removeBarSegment);
    }
    
    override public function visit() : Int
    {
        super.visit();
        
        m_widgetDragSystem.visit();
        m_orderedGestures.visit();
        
        return ScriptStatus.FAIL;
    }
    
    override public function show() : Void
    {
        super.show();
        
        setBarModelToStartState();
        
        // Once the initial bar model has been drawn we can measure the correct
        // positions of where the dragged widget should go
        var globalReferenceObject : DisplayObject = m_canvas.stage;
        
        var barModelBounds : Rectangle = m_barModelArea.getBounds(globalReferenceObject);
        
        // Hit areas are relative to the bar model reference
        var firstSegment : BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[0];
        var localBounds : Rectangle = firstSegment.rigidBody.boundingRectangle;
        
        // Need to translate the bounds of the first bar to global
        var globalPoint : Point = m_barModelArea.localToGlobal(new Point(localBounds.x, localBounds.y));
        
        // The start location is above the bars
        var startDragLocation : Point = new Point(
        barModelBounds.width * 0.5 + barModelBounds.x, barModelBounds.top - 20, 
        );
        
        // The location where the first press occurs is in the middle of the first bar
        var finalDragLocation : Point = new Point(
        globalPoint.x + localBounds.width * 0.5, 
        globalPoint.y + localBounds.height * 0.5, 
        );
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
        // Have mouse float just above the bar model
        mainAnimationEvents.push(new CustomSequenceEvent(moveMouseToPoint, [startDragLocation], new ExecuteOnceEndTrigger()));
        
        // Move down to the first bar
        mainAnimationEvents.push(new MouseMoveToSequenceEvent(startDragLocation, finalDragLocation, 1.0, m_simulatedMouseState, false));
        
        // Then press and drag up
        mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDrag, null, new ExecuteOnceEndTrigger()));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
        mainAnimationEvents.push(new MouseMoveToSequenceEvent(finalDragLocation, startDragLocation, 0.55, m_simulatedMouseState));
        
        // Release to complete the action
        mainAnimationEvents.push(new CustomSequenceEvent(releaseMouse, null, new ExecuteOnceEndTrigger()));
        mainAnimationEvents.push(new CustomSequenceEvent(loopBack, [mainAnimationSequence], new ExecuteOnceEndTrigger()));
        
        var sequences : Array<Sequence> = new Array<Sequence>();
        sequences.push(mainAnimationSequence);
        m_playbackEvents = new EventSequencer(sequences);
        m_playbackEvents.start();
    }
    
    override public function hide() : Void
    {
        super.hide();
        m_widgetDragSystem.manuallyEndDrag();
        m_playbackEvents.dispose();
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_widgetDragSystem.dispose();
        m_orderedGestures.dispose();
    }
    
    private function moveMouseToPoint(location : Point) : Void
    {
        m_simulatedMouseState.mousePositionThisFrame.x = location.x;
        m_simulatedMouseState.mousePositionThisFrame.y = location.y;
    }
    
    private function pressAndStartDrag() : Void
    {
        m_simulatedMouseState.leftMousePressedThisFrame = true;
        m_simulatedMouseState.leftMouseDown = true;
    }
    
    private function loopBack(sequenceToLoop : Sequence) : Void
    {
        sequenceToLoop.reset();
        
        // Reset the bar model
        setBarModelToStartState();
        
        // Restart the given sequence after reset
        sequenceToLoop.start();
    }
    
    private function setBarModelToStartState() : Void
    {
        var exampleBarModel : BarModelData = new BarModelData();
        
        var color : Int = XColor.getDistributedHsvColor(Math.random());
        var firstBarWhole : BarWhole = new BarWhole(false);
        firstBarWhole.barSegments.push(new BarSegment(4, 1, color, null));
        firstBarWhole.barLabels.push(new BarLabel("a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        exampleBarModel.barWholes.push(firstBarWhole);
        
        var secondBarWhole : BarWhole = new BarWhole(false);
        secondBarWhole.barSegments.push(new BarSegment(3, 1, color, null));
        secondBarWhole.barLabels.push(new BarLabel("b", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        secondBarWhole.barSegments.push(new BarSegment(2, 1, color, null));
        secondBarWhole.barLabels.push(new BarLabel("c", 1, 1, true, false, BarLabel.BRACKET_NONE, null));
        exampleBarModel.barWholes.push(secondBarWhole);
        
        m_barModelArea.setBarModelData(exampleBarModel);
        m_barModelArea.redraw(false);
    }
}
