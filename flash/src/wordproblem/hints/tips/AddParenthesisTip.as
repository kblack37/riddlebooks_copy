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
    
    public class AddParenthesisTip extends TermAreaTip
    {
        private var m_expressionCompiler:LatexCompiler;
        private var m_widgetDragSystem:WidgetDragSystem;
        private var m_termAreaMouseScript:TermAreaMouseScript;
        private var m_addAndChangeParenthesis:AddAndChangeParenthesis;
        
        private var m_containerForParenthesisButton:Sprite;
        
        public function AddParenthesisTip(expressionSymbolMap:ExpressionSymbolMap, 
                                          canvas:DisplayObjectContainer, 
                                          mouseState:MouseState, 
                                          time:Time, 
                                          assetManager:AssetManager, 
                                          screenBounds:Rectangle, 
                                          titleText:String,
                                          id:String=null, isActive:Boolean=true)
        {
            super(expressionSymbolMap, canvas, mouseState, time, assetManager, 250, 150, screenBounds, titleText, 
                "Hold down on the button and drag the parenthesis to add them to the answer.", 
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
            var status:int = super.visit();
            m_widgetDragSystem.visit();
            m_termAreaMouseScript.visit();
            m_addAndChangeParenthesis.visit();
            
            return status; 
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
            
            var parenthesisButtonGlobalLocation:Point = m_containerForParenthesisButton.localToGlobal(origin);
            parenthesisButtonGlobalLocation.x += m_containerForParenthesisButton.width * 0.5;
            parenthesisButtonGlobalLocation.y += m_containerForParenthesisButton.height * 0.5;
            
            // The end point of the drag should be the addition operator
            var operatorWidget:BaseTermWidget = m_termArea.getWidgetRoot();
            var operatorBounds:Rectangle = operatorWidget.rigidBodyComponent.boundingRectangle;
            var operatorGlobalLocation:Point = m_termArea.localToGlobal(new Point(operatorBounds.x, operatorBounds.y));
            operatorGlobalLocation.x += operatorBounds.width * 0.5;
            operatorGlobalLocation.y += operatorBounds.height * 0.5;
            
            var leftTermWidget:BaseTermWidget = m_termArea.getWidgetRoot().leftChildWidget;
            var leftTermBounds:Rectangle = leftTermWidget.rigidBodyComponent.boundingRectangle;
            var leftTermGlobalLocation:Point = m_termArea.localToGlobal(new Point(leftTermBounds.x, leftTermBounds.y));
            leftTermGlobalLocation.x += leftTermBounds.width * 0.25;
            leftTermGlobalLocation.y += leftTermBounds.height * 0.25;
            
            var mainAnimationEvents:Vector.<SequenceEvent> = new Vector.<SequenceEvent>();
            var mainAnimationSequence:Sequence = new Sequence(mainAnimationEvents);
            
            // Move the mouse from the top of the screen to the parenthesis button
            mainAnimationEvents.push(new CustomSequenceEvent(setMouseLocation, [termAreaGlobalLocation], new ExecuteOnceEndTrigger()));
            
            // First move the mouse over the parenthesis button and press down on it to activate
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(termAreaGlobalLocation, parenthesisButtonGlobalLocation, 0.6, m_simulatedMouseState, false));
            mainAnimationEvents.push(new CustomSequenceEvent(pressMouseAtCurrentPoint, null, new ExecuteOnceEndTrigger()));
            
            // Move the dragged paren over the left term first and pause to show the preview
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(parenthesisButtonGlobalLocation, leftTermGlobalLocation, 0.6, m_simulatedMouseState, true));
            mainAnimationEvents.push(new SequenceEvent(new TimerEndTrigger(500)));
            
            // Then move the dragged paren over the operator and release to add the paren
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(leftTermGlobalLocation, operatorGlobalLocation, 0.6, m_simulatedMouseState, true));
            mainAnimationEvents.push(new SequenceEvent(new TimerEndTrigger(500)));
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
            m_termArea.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), m_expressionCompiler.compile("a+b").head));
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