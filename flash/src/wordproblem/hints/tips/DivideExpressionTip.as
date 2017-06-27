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
    
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.hints.tips.eventsequence.MouseMoveToSequenceEvent;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.drag.WidgetDragSystem;
    import wordproblem.scripts.expression.AddTerm;
    
    public class DivideExpressionTip extends TermAreaTip
    {
        private var m_expressionCompiler:LatexCompiler;
        private var m_widgetDragSystem:WidgetDragSystem;
        private var m_addTerm:AddTerm;
        
        public function DivideExpressionTip(expressionSymbolMap:ExpressionSymbolMap, 
                                            canvas:DisplayObjectContainer, 
                                            mouseState:MouseState, 
                                            time:Time, 
                                            assetManager:AssetManager,
                                            screenBounds:Rectangle, 
                                            titleText:String,
                                            id:String=null, 
                                            isActive:Boolean=true)
        {
            super(expressionSymbolMap, canvas, mouseState, time, assetManager, 
                250, 150, 
                screenBounds, titleText, 
                "Add a division operation by putting a value underneath another.", id, isActive);
            
            m_widgetDragSystem = new WidgetDragSystem(null, m_expressionCompiler, assetManager);
            m_widgetDragSystem.setParams(m_simulatedMouseState, expressionSymbolMap, canvas, m_gameEnginePlaceholderEventDispatcher);
            
            m_expressionCompiler = new LatexCompiler(new RealsVectorSpace());
            m_addTerm = new AddTerm(null, m_expressionCompiler, assetManager);
            m_addTerm.setParams(Vector.<TermAreaWidget>([m_termArea]), new LevelRules(false, false, true, false, false, true, true),
                m_gameEnginePlaceholderEventDispatcher, m_simulatedMouseState, m_widgetDragSystem, m_mainDisplay, expressionSymbolMap);
        }
        
        override public function visit():int
        {
            var status:int = super.visit();
            m_widgetDragSystem.visit();
            m_addTerm.visit();
            
            return status;
        }
        
        override public function show():void
        {
            super.show();
            
            setupExpression();
            
            // Start mouse just above the term area
            var globalReferenceObject:DisplayObject = m_canvas.stage;
            var termAreaGlobalLocation:Point = m_termArea.localToGlobal(new Point(0, 0));
            var startDragLocation:Point = new Point(
                termAreaGlobalLocation.x + 0.5 * m_termArea.getConstraintsWidth(), 
                termAreaGlobalLocation.y - 25
            );
            
            // End mouse at the bottom half of the expression on the board
            var existingExpressionWidget:BaseTermWidget = m_termArea.getWidgetRoot();
            var existingExpressionBounds:Rectangle = existingExpressionWidget.rigidBodyComponent.boundingRectangle;
            var operatorGlobalLocation:Point = m_termArea.localToGlobal(new Point(existingExpressionBounds.x, existingExpressionBounds.y));
            var finalDragLocation:Point = new Point(
                operatorGlobalLocation.x + existingExpressionBounds.width * 0.5,
                operatorGlobalLocation.y + existingExpressionBounds.height * 0.85
            );
            
            var mainAnimationEvents:Vector.<SequenceEvent> = new Vector.<SequenceEvent>();
            var mainAnimationSequence:Sequence = new Sequence(mainAnimationEvents);
            
            // Hold the card for some number of seconds
            mainAnimationEvents.push(new CustomSequenceEvent(pressAndStartDragOfExpression, [startDragLocation, "2", m_widgetDragSystem, m_expressionCompiler.getVectorSpace()], new ExecuteOnceEndTrigger()));
            mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
            // Drag it to the space for comparison
            mainAnimationEvents.push(new MouseMoveToSequenceEvent(startDragLocation, finalDragLocation, 1.0, m_simulatedMouseState));
            mainAnimationEvents.push(new CustomSequenceEvent(holdDownMouse, null, new TimerEndTrigger(500)));
            mainAnimationEvents.push(new CustomSequenceEvent(releaseMouse, null, new ExecuteOnceEndTrigger()));
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
            
            // Make sure any actively dragged card is cleared
            m_widgetDragSystem.manuallyEndDrag();
            m_playbackEvents.dispose();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_widgetDragSystem.dispose();
            m_addTerm.dispose();
        }
        
        private function setupExpression():void
        {
            m_termArea.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), m_expressionCompiler.compile("a").head));
            m_termArea.redrawAfterModification(false);
        }
        
        private function loopBack(sequenceToLoop:Sequence):void
        {
            sequenceToLoop.reset();
            
            // Reset the expression
            setupExpression();
            
            // Restart the given sequence after reset
            sequenceToLoop.start();
        }
    }
}