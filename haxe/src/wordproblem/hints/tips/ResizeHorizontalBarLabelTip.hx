package wordproblem.hints.tips;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.eventsequence.CustomSequenceEvent;
import dragonbox.common.eventsequence.EventSequencer;
import dragonbox.common.eventsequence.Sequence;
import dragonbox.common.eventsequence.SequenceEvent;
import dragonbox.common.eventsequence.endtriggers.ExecuteOnceEndTrigger;
import dragonbox.common.eventsequence.endtriggers.TimerEndTrigger;
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

class ResizeHorizontalBarLabelTip extends BarModelTip
{
    private var m_resizeLabelGesture : ResizeHorizontalBarLabel;
    
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
                "This changes the number of boxes a name is equal to.", id, isActive);
        
        m_resizeLabelGesture = new ResizeHorizontalBarLabel(null, null, assetManager);
        m_resizeLabelGesture.setCommonParams(m_barModelArea, null, m_gameEnginePlaceholderEventDispatcher, mouseState);
        m_resizeLabelGesture.setIsActive(true);
    }
    
    override public function visit() : Int
    {
        super.visit();
        
        m_resizeLabelGesture.visit();
        
        return ScriptStatus.FAIL;
    }
    
    override public function show() : Void
    {
        super.show();
        
        setBarModelToStartState();
        
        // Move the mouse to the edge point of the label
        // Then drag the mouse horizontally so it sets to a segment edge further to the left
        var globalReferenceObject : DisplayObject = m_canvas.stage;
        var labelToResize : BarLabelView = m_barModelArea.getBarWholeViews()[0].labelViews[0];
        
        // The hit areas are a small radius are the left and right edges of the label
        var labelBounds : Rectangle = labelToResize.rigidBody.boundingRectangle.clone();
        var globalPoint : Point = m_barModelArea.localToGlobal(new Point(labelBounds.x, labelBounds.y));
        labelBounds.x = globalPoint.x;
        labelBounds.y = globalPoint.y;
        
        // The mouse should start at the edge of the label
        var startDragLocation : Point = new Point(
			labelBounds.right, 
			labelBounds.top + labelBounds.height * 0.5
        );
        
        // The final drag should be at the edge of a new segment
        var segmentToDragTo : BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[2];
        var segmentBounds : Rectangle = segmentToDragTo.rigidBody.boundingRectangle.clone();
        var segmentGlobalPoint : Point = m_barModelArea.localToGlobal(new Point(segmentBounds.x, segmentBounds.y));
        segmentBounds.x = segmentGlobalPoint.x;
        segmentBounds.y = segmentGlobalPoint.y;
        
        var finalDragLocation : Point = new Point(
			segmentBounds.right, 
			labelBounds.y
        );
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
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
        
        var sequences : Array<Sequence> = new Array<Sequence>();
        sequences.push(mainAnimationSequence);
        m_playbackEvents = new EventSequencer(sequences);
        m_playbackEvents.start();
    }
    
    override public function hide() : Void
    {
        super.hide();
        m_playbackEvents.dispose();
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_resizeLabelGesture.dispose();
    }
    
    private function pressMouseDown() : Void
    {
        m_simulatedMouseState.leftMousePressedThisFrame = true;
        m_simulatedMouseState.leftMouseDown = true;
    }
    
    private function moveMouseTo(position : Point) : Void
    {
        m_simulatedMouseState.mousePositionThisFrame.x = position.x;
        m_simulatedMouseState.mousePositionThisFrame.y = position.y;
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
        var barWholeToDivide : BarWhole = new BarWhole(false);
        
        var numSegments : Int = 5;
        var color : Int = XColor.getDistributedHsvColor(Math.random());
        for (i in 0...numSegments){
            barWholeToDivide.barSegments.push(new BarSegment(1, 1, color, null));
        }
        
        barWholeToDivide.barLabels.push(new BarLabel("a", 0, numSegments - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
        exampleBarModel.barWholes.push(barWholeToDivide);
        
        m_barModelArea.setBarModelData(exampleBarModel);
        m_barModelArea.redraw(true);
    }
}
