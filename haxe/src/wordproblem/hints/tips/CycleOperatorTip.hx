package wordproblem.hints.tips;

import wordproblem.hints.tips.TermAreaTip;

import openfl.geom.Point;
import openfl.geom.Rectangle;

import dragonbox.common.eventsequence.CustomSequenceEvent;
import dragonbox.common.eventsequence.EventSequencer;
import dragonbox.common.eventsequence.Sequence;
import dragonbox.common.eventsequence.SequenceEvent;
import dragonbox.common.eventsequence.endtriggers.ExecuteOnceEndTrigger;
import dragonbox.common.eventsequence.endtriggers.TimerEndTrigger;
import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.level.LevelRules;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.expression.PressToChangeOperator;

class CycleOperatorTip extends TermAreaTip
{
    private var m_pressToChangeOperator : PressToChangeOperator;
    private var m_expressionCompiler : LatexCompiler;
    
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
        super(expressionSymbolMap, canvas, mouseState, time, assetManager,
                270, 150, screenBounds,
                titleText,
                "Press on the operator to change it",
                id, isActive);
        
        m_expressionCompiler = new LatexCompiler(new RealsVectorSpace());
        m_pressToChangeOperator = new PressToChangeOperator(null, m_expressionCompiler, null);
        m_pressToChangeOperator.setCommonParams([m_termArea], new LevelRules(true, true, false, false, false, false, false),
                m_gameEnginePlaceholderEventDispatcher, m_simulatedMouseState);
    }
    
    override public function visit() : Int
    {
        // The gesture script needs to run visit after the super class visit because
        // the super class manipulates the mouse state (sets data) that the gesture script
        // needs to read for that frame.
        var status : Int = super.visit();
        m_pressToChangeOperator.visit();
        
        return status;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_pressToChangeOperator.dispose();
    }
    
    override public function show() : Void
    {
        super.show();
        
        setupExpression();
        
        var globalReferenceObject : DisplayObject = m_canvas.stage;
        var termAreaGlobalLocation : Point = m_termArea.localToGlobal(new Point(0, 0));
        var startMousePoint : Point = new Point(
			termAreaGlobalLocation.x + 0.5 * m_termArea.getConstraintsWidth(), 
			termAreaGlobalLocation.y - 25
        );
        
        // Need to identify the location of the plus sign (assume it is the root
        var operatorWidget : BaseTermWidget = m_termArea.getWidgetRoot();
        var operatorBounds : Rectangle = operatorWidget.rigidBodyComponent.boundingRectangle;
        var operatorGlobalLocation : Point = m_termArea.localToGlobal(new Point(operatorBounds.x, operatorBounds.y));
        var operatorMousePoint : Point = new Point(
			operatorGlobalLocation.x + operatorBounds.width * 0.5, 
			operatorGlobalLocation.y + operatorBounds.height * 0.5
        );
        
        var finalMousePoint : Point = new Point(
			operatorMousePoint.x + 20, 
			operatorMousePoint.y - 20
        );
        
        var mainAnimationEvents : Array<SequenceEvent> = new Array<SequenceEvent>();
        var mainAnimationSequence : Sequence = new Sequence(mainAnimationEvents);
        
        // Move the mouse from the top of the screen to a point just over the plus sign
        mainAnimationEvents.push(new CustomSequenceEvent(setMouseLocation, [startMousePoint], new ExecuteOnceEndTrigger()));
        
        // Stop over the operator and then trigger a click to alter it
        mainAnimationEvents.push(new MouseMoveToSequenceEvent(startMousePoint, operatorMousePoint, 0.6, m_simulatedMouseState, false));
        mainAnimationEvents.push(new CustomSequenceEvent(pressMouseAtCurrentPoint, null, new ExecuteOnceEndTrigger()));
        mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
        mainAnimationEvents.push(new CustomSequenceEvent(releaseMouse, null, new ExecuteOnceEndTrigger()));
        
        // Repeat should reset the expression
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
    
    private function setupExpression() : Void
    {
        m_termArea.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), m_expressionCompiler.compile("a+b")));
        m_termArea.redrawAfterModification(false);
    }
    
    private function loopBack(sequenceToLoop : Sequence) : Void
    {
        sequenceToLoop.reset();
        
        // Reset the expression
        setupExpression();
        
        // Restart the given sequence after reset
        sequenceToLoop.start();
    }
}
