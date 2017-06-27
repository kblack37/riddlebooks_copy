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
    import dragonbox.common.expressiontree.compile.LatexCompiler;
    import dragonbox.common.math.vectorspace.RealsVectorSpace;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Sprite;
    
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.drag.WidgetDragSystem;
    import wordproblem.scripts.expression.AddAndChangeParenthesis;
    import wordproblem.scripts.expression.TermAreaMouseScript;
    
    public class ChangeAndRemoveParenthesisTip extends TermAreaTip
    {
        private var m_expressionCompiler:LatexCompiler;
        private var m_widgetDragSystem:WidgetDragSystem;
        private var m_termAreaMouseScript:TermAreaMouseScript;
        private var m_addAndChangeParenthesis:AddAndChangeParenthesis;
        
        private var m_containerForParenthesisButton:Sprite;
        
        public function ChangeAndRemoveParenthesisTip(expressionSymbolMap:ExpressionSymbolMap, 
                                                      canvas:DisplayObjectContainer, 
                                                      mouseState:MouseState, 
                                                      time:Time, assetManager:AssetManager, 
                                                      screenBounds:Rectangle, 
                                                      titleText:String, 
                                                      id:String=null, 
                                                      isActive:Boolean=true)
        {
            super(expressionSymbolMap, canvas, mouseState, time, assetManager,
                200, 140, screenBounds, titleText, 
                "Drag the left or right part to change how much the parenthesis covers or drag it out of the area to remove it.", 
                id, isActive);
            m_expressionCompiler = new LatexCompiler(new RealsVectorSpace());
            m_widgetDragSystem = new WidgetDragSystem(null, m_expressionCompiler, assetManager);
            m_widgetDragSystem.setParams(mouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
            
            var termAreas:Vector.<TermAreaWidget> = Vector.<TermAreaWidget>([m_termArea]);
            var levelRules:LevelRules = new LevelRules(false, false, false, false, false, false, true);
            m_termAreaMouseScript = new TermAreaMouseScript(null, m_expressionCompiler, assetManager);
            m_termAreaMouseScript.setCommonParams(termAreas, levelRules, m_gameEnginePlaceholderEventDispatcher, mouseState);
            m_termAreaMouseScript.setParams(m_widgetDragSystem);
            
            m_addAndChangeParenthesis = new AddAndChangeParenthesis(null, m_expressionCompiler, assetManager);
            m_addAndChangeParenthesis.setCommonParams(termAreas, levelRules, m_gameEnginePlaceholderEventDispatcher, mouseState);
            
            m_containerForParenthesisButton = new Sprite();
            m_addAndChangeParenthesis.setParams(canvas, m_containerForParenthesisButton);
        }
        
        override public function visit():int
        {
            m_widgetDragSystem.visit();
            m_termAreaMouseScript.visit();
            m_addAndChangeParenthesis.visit();
            
            return super.visit();
        }
        
        override public function show():void
        {
            super.show();
            m_addAndChangeParenthesis.setIsActive(true);
            
            // The parenthesis button appears just above and to the left of the term area
            m_containerForParenthesisButton.x = m_termArea.x - m_containerForParenthesisButton.width;
            m_containerForParenthesisButton.y = m_termArea.y - m_containerForParenthesisButton.height;
            m_mainDisplay.addChild(m_containerForParenthesisButton);
            
            setUpExpression();
            var origin:Point = new Point(0, 0);
            var termAreaGlobalLocation:Point = m_termArea.localToGlobal(origin);
            termAreaGlobalLocation.x += 0.5 * m_termArea.getConstraintsWidth(); 
            termAreaGlobalLocation.y -= 25;
            
            // Find the location of the parenthesis graphic
            // (HACK: Requires knowledge of how the parenthesis is displayed)
            var leftTermWidget:BaseTermWidget = m_termArea.getWidgetRoot().leftChildWidget;
            var rightParenImage:DisplayObject = leftTermWidget.m_parenthesesCanvas.getChildAt(1);
            var rightParenGlobalPosition:Point = leftTermWidget.m_parenthesesCanvas.localToGlobal(new Point(
                rightParenImage.x,
                rightParenImage.y
            ));
            // Note that the parenthesis coordinate is already placed on the center
            
            // The end point of the drag should be the addition operator
            var rightTermWidget:BaseTermWidget = m_termArea.getWidgetRoot().rightChildWidget;
            var rightTermBounds:Rectangle = rightTermWidget.rigidBodyComponent.boundingRectangle;
            var rightTermGlobalPosition:Point = m_termArea.localToGlobal(new Point(rightTermBounds.x, rightTermBounds.y));
            rightTermGlobalPosition.x += rightTermBounds.width;
            rightTermGlobalPosition.y += rightTermBounds.height * 0.5;
            
            var mainAnimationEvents:Vector.<SequenceEvent> = new Vector.<SequenceEvent>();
            var mainAnimationSequence:Sequence = new Sequence(mainAnimationEvents);
            
            // Set mouse at top for the start
            mainAnimationEvents.push(new CustomSequenceEvent(setMouseLocation, [termAreaGlobalLocation], new ExecuteOnceEndTrigger()));
            
            // First move the mouse over the right parenthesis and press down to start drag
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(termAreaGlobalLocation, rightParenGlobalPosition, 0.6, m_simulatedMouseState, false));
            mainAnimationEvents.push(new CustomSequenceEvent(pressMouseAtCurrentPoint, null, new ExecuteOnceEndTrigger()));
            
            // Move the dragged paren to the right side of the right term to resize
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(rightParenGlobalPosition, rightTermGlobalPosition, 0.6, m_simulatedMouseState, true));
            mainAnimationEvents.push(new SequenceEvent(new TimerEndTrigger(500)));
            mainAnimationEvents.push(new CustomSequenceEvent(releaseMouse, null, new ExecuteOnceEndTrigger()));
            
            // Finally to show how remove works, drag the right edge out of the term area
            // (HACK: For simplicity we will make a guess of where the right parenthesis ends up click that point)
            var newParenPositionEstimate:Point = new Point(rightTermGlobalPosition.x - rightParenImage.width * 0.5, rightTermGlobalPosition.y);
            mainAnimationEvents.push(new SequenceEvent(new TimerEndTrigger(500)));
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(rightTermGlobalPosition, newParenPositionEstimate, 0.1, m_simulatedMouseState, false));
            mainAnimationEvents.push(new CustomSequenceEvent(pressMouseAtCurrentPoint, null, new ExecuteOnceEndTrigger()));
            
            // Just drag back to starting position
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(newParenPositionEstimate, new Point(newParenPositionEstimate.x + 50, termAreaGlobalLocation.y), 0.6, m_simulatedMouseState, true));
            mainAnimationEvents.push(new CustomSequenceEvent(releaseMouse, null, new ExecuteOnceEndTrigger()));
            
            // Repeat should reset the expression
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
            
            m_addAndChangeParenthesis.setIsActive(false);
            m_containerForParenthesisButton.removeFromParent();
            m_widgetDragSystem.manuallyEndDrag();
            m_playbackEvents.dispose();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_widgetDragSystem.dispose();
            m_termAreaMouseScript.dispose();
            m_addAndChangeParenthesis.dispose();
            m_containerForParenthesisButton.removeFromParent();
        }
        
        private function setUpExpression():void
        {
            m_termArea.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), m_expressionCompiler.compile("(a)+b").head));
            m_termArea.redrawAfterModification();
        }
        
        private function loopBack(sequenceToLoop:Sequence):void
        {
            sequenceToLoop.reset();
            
            // Reset the expression
            setUpExpression();
            
            // Restart the given sequence after reset
            sequenceToLoop.start();
        }
    }
}