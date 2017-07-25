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
import wordproblem.engine.scripting.graph.selector.PrioritySelector;
import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewVerticalLabel;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.drag.WidgetDragSystem;

class AddNewVerticalLabelTip extends BarModelTip
{
    private var m_widgetDragSystem : WidgetDragSystem;
    private var m_vectorSpace : RealsVectorSpace;
    
    private var m_orderedGestures : PrioritySelector;
    
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
        super(expressionSymbolMap,
                canvas,
                mouseState,
                time,
                assetManager,
                BarModelTip.DEFAULT_BAR_MODEL_WIDTH,
                BarModelTip.DEFAULT_BAR_MODEL_HEIGHT,
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
        var addNewLabel : AddNewVerticalLabel = new AddNewVerticalLabel(null, null, assetManager, 1);
        addNewLabel.setCommonParams(m_barModelArea, m_widgetDragSystem, m_gameEnginePlaceholderEventDispatcher, mouseState);
        m_orderedGestures.pushChild(addNewLabel);
        
        var addNewLabelHitArea : ShowBarModelHitAreas = new ShowBarModelHitAreas(
        null, null, assetManager, null);
        addNewLabelHitArea.setParams(m_barModelArea, m_widgetDragSystem, addNewLabel);
        m_orderedGestures.pushChild(addNewLabelHitArea);
        
        m_vectorSpace = new RealsVectorSpace();
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
        var barWholeToAddName : BarWholeView = m_barModelArea.getBarWholeViews()[0];
        var barWholeBounds : Rectangle = barWholeToAddName.getBounds(globalReferenceObject);
        
        var addLabelScript : AddNewVerticalLabel = try cast(m_orderedGestures.getChildren()[0], AddNewVerticalLabel) catch(e:Dynamic) null;
        var addLabelHitArea : Rectangle = addLabelScript.getActiveHitAreas()[0].clone();
        
        // Need to translate to global
        var globalPoint : Point = m_barModelArea.localToGlobal(new Point(addLabelHitArea.x, addLabelHitArea.y));
        addLabelHitArea.x = globalPoint.x;
        addLabelHitArea.y = globalPoint.y;
        
        // The start drag location is above the bars
        var startDragLocation : Point = new Point(
			barWholeBounds.left + barWholeBounds.width * 0.5, 
			barWholeBounds.top - 50
        );
        
        // The final drag location is in the middle of the hit area
        var finalDragLocation : Point = new Point(
			addLabelHitArea.left + addLabelHitArea.width * 0.5, 
			addLabelHitArea.top + addLabelHitArea.height * 0.5
        );
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
        // Hold the card for some number of seconds
        mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDragOfExpression, [startDragLocation, "a", m_widgetDragSystem, m_vectorSpace], new ExecuteOnceEndTrigger()));
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
        m_orderedGestures.dispose();
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
		function createBarWhole(numSegments : Int, valuePerSegment : Float) : Void
        {
            var barWhole : BarWhole = new BarWhole(false);
            for (i in 0...numSegments){
                barWhole.barSegments.push(new BarSegment(valuePerSegment, 1, XColor.getDistributedHsvColor(Math.random()), null));
            }
            exampleBarModel.barWholes.push(barWhole);
        };
        createBarWhole(3, 1);
        createBarWhole(2, 2);
        m_barModelArea.setBarModelData(exampleBarModel);
        m_barModelArea.redraw(false);
    }
}
