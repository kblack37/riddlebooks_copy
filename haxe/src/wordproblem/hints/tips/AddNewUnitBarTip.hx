package wordproblem.hints.tips;

import wordproblem.hints.tips.BarModelTip;

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

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.selector.PrioritySelector;
import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.AddNewUnitBar;
import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
import wordproblem.scripts.drag.WidgetDragSystem;

class AddNewUnitBarTip extends BarModelTip
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
            id : String = null,
            isActive : Bool = true)
    {
        super(expressionSymbolMap, canvas, mouseState, time, assetManager,
                BarModelTip.DEFAULT_BAR_MODEL_WIDTH, BarModelTip.DEFAULT_BAR_MODEL_HEIGHT, screenBounds,
                id,
                "When you drag a number here, it will make that number of equal sized boxes.",
                id, isActive);
        
        m_widgetDragSystem = new WidgetDragSystem(null, null, assetManager);
        m_widgetDragSystem.setParams(mouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
        
        m_orderedGestures = new PrioritySelector();
        var addNewUnitBar : AddNewUnitBar = new AddNewUnitBar(null, null, assetManager, 30);
        addNewUnitBar.setParams(m_barModelArea, m_widgetDragSystem, mouseState, expressionSymbolMap, Std.int(m_barModelArea.unitLength), m_gameEnginePlaceholderEventDispatcher);
        m_orderedGestures.pushChild(addNewUnitBar);
        
        var addNewUnitBarHitArea : ShowBarModelHitAreas = new ShowBarModelHitAreas(
        null, null, assetManager, null);
        addNewUnitBarHitArea.setParams(m_barModelArea, m_widgetDragSystem, addNewUnitBar);
        m_orderedGestures.pushChild(addNewUnitBarHitArea);
        
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
        
        var barModelBounds : Rectangle = m_barModelArea.getBounds(globalReferenceObject);
        
        // Hit areas are relative to the bar model reference
        var addUnitBar : AddNewUnitBar = try cast(m_orderedGestures.getChildren()[0], AddNewUnitBar) catch(e:Dynamic) null;
        var hitAreas : Array<Rectangle> = addUnitBar.getActiveHitAreas();
        var unitHitAreaBounds : Rectangle = hitAreas[0].clone();
        
        // Need to translate to global
        var globalPoint : Point = m_barModelArea.localToGlobal(new Point(unitHitAreaBounds.x, unitHitAreaBounds.y));
        unitHitAreaBounds.x = globalPoint.x;
        unitHitAreaBounds.y = globalPoint.y;
        
        // The start drag location is above the bars
        var startDragLocation : Point = new Point(
			barModelBounds.width * 0.5 + barModelBounds.x,
			barModelBounds.top - 20
        );
        
        // The final drag location is in the hit area new the left edge
        var finalDragLocation : Point = new Point(
			unitHitAreaBounds.left + unitHitAreaBounds.width * 0.5, 
			unitHitAreaBounds.top + unitHitAreaBounds.height * 0.5
        );
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
        // Hold the card for some number of seconds
        mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDragOfExpression, [startDragLocation, "3", m_widgetDragSystem, m_vectorSpace], new ExecuteOnceEndTrigger()));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
        // Drag it to the space for comparison
        mainAnimationEvents.push(new MouseMoveToSequenceEvent(startDragLocation, finalDragLocation, 0.75, m_simulatedMouseState));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(1500)));
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
        m_barModelArea.setBarModelData(exampleBarModel);
        m_barModelArea.redraw(false);
    }
}
