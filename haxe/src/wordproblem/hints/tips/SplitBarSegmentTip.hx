package wordproblem.hints.tips;


import openfl.geom.Point;
import openfl.geom.Rectangle;

import dragonbox.common.eventsequence.CustomSequenceEvent;
import dragonbox.common.eventsequence.EventSequencer;
import dragonbox.common.eventsequence.Sequence;
import dragonbox.common.eventsequence.SequenceEvent;
import dragonbox.common.eventsequence.endtriggers.ExecuteOnceEndTrigger;
import dragonbox.common.eventsequence.endtriggers.TimerEndTrigger;
import dragonbox.common.math.vectorspace.IVectorSpace;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.SplitBarSegment;
import wordproblem.scripts.drag.WidgetDragSystem;

class SplitBarSegmentTip extends BarModelTip
{
    private var m_widgetDragSystem : WidgetDragSystem;
    private var m_vectorSpace : RealsVectorSpace;
    
    private var m_splitGesture : SplitBarSegment;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            canvas : DisplayObjectContainer,
            mouseState : MouseState,
            time : Time,
            assetManager : AssetManager,
            screenBounds : Rectangle,
            id : String = null,
            isActive : Bool = true)
    {
        super(expressionSymbolMap, canvas, mouseState, time, assetManager, 400, 170, screenBounds,
                id,
                "This will divide a box into equally sized groups. The number of boxes equals the number you dragged",
                id, isActive);
        
        m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
        m_widgetDragSystem.setParams(mouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
        
        m_splitGesture = new SplitBarSegment(null, null, assetManager);
        m_splitGesture.setCommonParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, mouseState);
        
        m_vectorSpace = new RealsVectorSpace();
    }
    
    override public function visit() : Int
    {
        super.visit();
        
        m_widgetDragSystem.visit();
        m_splitGesture.visit();
        
        return ScriptStatus.FAIL;
    }
    
    override public function show() : Void
    {
        super.show();
        
        setBarModelToStartState();
        
        // Once the initial bar model has been drawn we can measure the correct
        // positions of where the dragged widget should go
        var globalReferenceObject : DisplayObject = m_canvas.stage;
        var segmentViewToDivide : BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[0];
        var segmentToDivideBounds : Rectangle = segmentViewToDivide.getBounds(globalReferenceObject);
        
        // The start drag location is above the bars
        var startDragLocation : Point = new Point(
			segmentToDivideBounds.left + segmentToDivideBounds.width * 0.5, 
			segmentToDivideBounds.top - 50
        );
        
        // The final drag location is in the middle of the segment
        var finalDragLocation : Point = new Point(
			segmentToDivideBounds.left + segmentToDivideBounds.width * 0.5, 
			segmentToDivideBounds.top + segmentToDivideBounds.height * 0.5
        );
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
        // Hold the card for some number of seconds
        mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDragOfExpression, [startDragLocation, "5", m_widgetDragSystem, m_vectorSpace], new ExecuteOnceEndTrigger()));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
        // Drag it to the space for comparison
        mainAnimationEvents.push(new MouseMoveToSequenceEvent(startDragLocation, finalDragLocation, 1.0, m_simulatedMouseState));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
        mainAnimationEvents.push(new CustomSequenceEvent(releaseMouse, null, new ExecuteOnceEndTrigger()));
        mainAnimationEvents.push(new SequenceEvent(new TimerEndTrigger(500)));
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
        m_splitGesture.dispose();
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
        var color : Int = XColor.getDistributedHsvColor(Math.random());
        var exampleBarModel : BarModelData = new BarModelData();
        var barWholeToDivide : BarWhole = new BarWhole(false);
        barWholeToDivide.barSegments.push(new BarSegment(5, 1, color, null));
        barWholeToDivide.barLabels.push(new BarLabel("a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        exampleBarModel.barWholes.push(barWholeToDivide);
        
        m_barModelArea.setBarModelData(exampleBarModel);
        m_barModelArea.redraw(false);
    }
}
