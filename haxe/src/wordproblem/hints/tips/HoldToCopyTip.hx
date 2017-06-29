package wordproblem.hints.tips;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.eventsequence.CustomSequenceEvent;
import dragonbox.common.eventsequence.EventSequencer;
import dragonbox.common.eventsequence.Sequence;
import dragonbox.common.eventsequence.SequenceEvent;
import dragonbox.common.eventsequence.endtriggers.ExecuteOnceEndTrigger;
import dragonbox.common.eventsequence.endtriggers.TimerEndTrigger;
import dragonbox.common.expressiontree.compile.LatexCompiler;
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
import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.barmodel.BarToCard;
import wordproblem.scripts.barmodel.HoldToCopy;
import wordproblem.scripts.drag.WidgetDragSystem;

class HoldToCopyTip extends BarModelTip
{
    private var m_widgetDragSystem : WidgetDragSystem;
    private var m_vectorSpace : IVectorSpace;
    private var m_addNewBar : AddNewBar;
    private var m_barToCard : BarToCard;
    private var m_holdToCopy : HoldToCopy;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            canvas : DisplayObjectContainer,
            mouseState : MouseState,
            time : Time,
            assetManager : AssetManager,
            screenBounds : Rectangle,
            titleText : String,
            id : String = null,
            isActive : Bool = true)
    {
        super(expressionSymbolMap, canvas, mouseState, time, assetManager, 270, 190,
                screenBounds, titleText,
                "Press and hold to create a copy of a name or a box. You can then add the part somewhere else.",
                id, isActive);
        
        var expressionCompiler : LatexCompiler = new LatexCompiler(new RealsVectorSpace());
        m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
        m_widgetDragSystem.setParams(m_simulatedMouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
        
        m_holdToCopy = new HoldToCopy(null, expressionCompiler, m_assetManager, m_simulatedTimer, assetManager.getBitmapData("glow_yellow"));
        m_holdToCopy.setCommonParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, m_simulatedMouseState);
        
        m_addNewBar = new AddNewBar(null, null, assetManager, 2);
        m_addNewBar.setParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, mouseState, expressionSymbolMap, null);
        
        m_barToCard = new BarToCard(null, expressionCompiler, assetManager, true);
        m_barToCard.setCommonParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, m_simulatedMouseState);
        m_holdToCopy.init(m_barToCard);
    }
    
    override public function visit() : Int
    {
        super.visit();
        
        m_widgetDragSystem.visit();
        m_holdToCopy.visit();
        m_addNewBar.visit();
        
        return ScriptStatus.FAIL;
    }
    
    override public function show() : Void
    {
        super.show();
        
        m_holdToCopy.setIsActive(true);
        setBarModelToStartState();
        
        // Once the initial bar model has been drawn we can measure the correct
        // positions of where the dragged widget should go
        var globalReferenceObject : DisplayObject = m_canvas.stage;
        
        var barModelBounds : Rectangle = m_barModelArea.getBounds(globalReferenceObject);
        
        // Hit areas are relative to the bar model reference
        var secondSegment : BarSegmentView = m_barModelArea.getBarWholeViews()[0].segmentViews[1];
        var localBounds : Rectangle = secondSegment.rigidBody.boundingRectangle;
        
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
        
        // Drop location should be right near the bottom
        var newBarAddLocation : Point = new Point(startDragLocation.x, barModelBounds.y + barModelBounds.height - localBounds.height * 0.5);
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
        // Have mouse float just above the bar model
        mainAnimationEvents.push(new CustomSequenceEvent(moveMouseToPoint, [startDragLocation], new ExecuteOnceEndTrigger()));
        
        // Move down to the first bar
        mainAnimationEvents.push(new MouseMoveToSequenceEvent(startDragLocation, finalDragLocation, 1.0, m_simulatedMouseState, false));
        
        // Then press and drag up
        mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDrag, null, new ExecuteOnceEndTrigger()));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(1500)));
        
        // Drag it to the bottom to add the copy
        mainAnimationEvents.push(new MouseMoveToSequenceEvent(finalDragLocation, newBarAddLocation, 0.55, m_simulatedMouseState));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(700)));
        
        // Release to complete the action
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
        m_holdToCopy.setIsActive(false);
        m_barToCard.cancelTransform();
        
        // For some reason the preview sticks around if we back out before the change is applied
        m_barModelArea.showPreview(false);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_widgetDragSystem.dispose();
        m_holdToCopy.dispose();
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
        
        for (i in 0...4){
            firstBarWhole.barSegments.push(new BarSegment(2, 1, color, null));
        }
        firstBarWhole.barLabels.push(new BarLabel("a", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        exampleBarModel.barWholes.push(firstBarWhole);
        
        m_barModelArea.setBarModelData(exampleBarModel);
        m_barModelArea.redraw(false);
    }
}
