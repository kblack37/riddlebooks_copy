package wordproblem.hints.tips;

import wordproblem.hints.tips.BarModelTip;

import flash.geom.Point;
import flash.geom.Rectangle;

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

import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;

import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewBar;
import wordproblem.scripts.drag.WidgetDragSystem;

class AddNewBarTip extends BarModelTip
{
    private var m_widgetDragSystem : WidgetDragSystem;
    private var m_vectorSpace : IVectorSpace;
    
    private var m_addNewBar : AddNewBar;
    
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
                DEFAULT_BAR_MODEL_WIDTH, 240, screenBounds,
                id,
                "This adds a box on a new line.", id, isActive);
        
        m_barModelArea.topBarPadding = 20;
        m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
        m_widgetDragSystem.setParams(mouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
        
        m_addNewBar = new AddNewBar(null, null, assetManager, 2);
        m_addNewBar.setParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, mouseState, expressionSymbolMap, null);
        
        m_vectorSpace = new RealsVectorSpace();
    }
    
    override public function visit() : Int
    {
        super.visit();
        
        m_widgetDragSystem.visit();
        m_addNewBar.visit();
        
        return ScriptStatus.FAIL;
    }
    
    override public function show() : Void
    {
        super.show();
        
        setBarModelToStartState();
        
        // Once the initial bar model has been drawn we can measure the correct
        // positions of where the dragged widget should go
        var globalReferenceObject : DisplayObject = m_canvas.stage;
        var barWholeView : BarWholeView = m_barModelArea.getBarWholeViews()[0];
        var barWholeBounds : Rectangle = barWholeView.getBounds(globalReferenceObject);
        
        // The start drag location is above the bars
        var startDragLocation : Point = new Point(
        barWholeBounds.left + barWholeBounds.width * 0.5, 
        barWholeBounds.top - 50, 
        );
        
        // The final drag location is below the bar, this is a bit arbitrary though
        var finalDragLocation : Point = new Point(
        startDragLocation.x - 100, 
        barWholeBounds.bottom + barWholeBounds.height, 
        );
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
        // Hold the card for some number of seconds
        mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDragOfExpression, [startDragLocation, "2", m_widgetDragSystem, m_vectorSpace], new ExecuteOnceEndTrigger()));
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
        m_addNewBar.dispose();
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
        var startingBarWhole : BarWhole = new BarWhole(false);
        startingBarWhole.barSegments.push(new BarSegment(4, 1, XColor.getDistributedHsvColor(Math.random()), null));
        exampleBarModel.barWholes.push(startingBarWhole);
        
        m_barModelArea.setBarModelData(exampleBarModel);
        m_barModelArea.redraw(false);
    }
}
