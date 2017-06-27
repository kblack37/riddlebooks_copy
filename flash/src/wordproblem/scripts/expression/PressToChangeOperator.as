package wordproblem.scripts.expression
{
    import flash.geom.Point;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.GroupTermWidget;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script checks for clicks on the operator image within a term area.
     * 
     * When it detects it, it changes the value of that operator.
     * 
     * Note to prevent conflicts with other scripts that also rely on detecting gestures on the
     * term area cards we cannot immediately react to events. We need to buffer it and only perform
     * the appropriate logic if a higher priority script does not do something first.
     */
    public class PressToChangeOperator extends BaseTermAreaScript
    {
        /**
         * List of operators to cycle through given a current operator
         */
        private var m_operatorsToCycleThrough:Vector.<String>;
        
        private var m_globalBuffer:Point;
        
        private var m_operatorWidgetPressedLast:GroupTermWidget;
        private var m_operatorUnderPointLastFrame:GroupTermWidget;
        
        public function PressToChangeOperator(gameEngine:IGameEngine, 
                                              expressionCompiler:IExpressionTreeCompiler, 
                                              assetManager:AssetManager, 
                                              id:String=null, 
                                              isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_operatorsToCycleThrough = new Vector.<String>();
            m_globalBuffer = new Point();
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            
            if (m_isActive && m_ready)
            {
                populateOperatorsToCycleThrough();
                m_globalBuffer.x = m_mouseState.mousePositionThisFrame.x;
                m_globalBuffer.y = m_mouseState.mousePositionThisFrame.y;
                
                var i:int;
                var numTermAreas:int = m_termAreas.length;
                var operatorUnderPoint:GroupTermWidget = null;
                for (i = 0; i < numTermAreas; i++)
                {
                    var termArea:TermAreaWidget = m_termAreas[i];
                    if (termArea.isInteractable)
                    {
                        var widgetUnderPoint:BaseTermWidget = termArea.pickWidgetUnderPoint(m_globalBuffer.x, m_globalBuffer.y, true);
                        
                        // Only care about presses on operators
                        if (widgetUnderPoint != null && m_operatorsToCycleThrough.indexOf(widgetUnderPoint.getNode().data) >= 0)
                        {
                            operatorUnderPoint = widgetUnderPoint as GroupTermWidget;
                            break;
                        }
                    }
                }

                if (operatorUnderPoint != null)
                {
                    if (m_mouseState.leftMousePressedThisFrame)
                    {
                        // On press the operator should scale down a bit
                        m_operatorWidgetPressedLast = operatorUnderPoint;
                    }
                    else if (m_mouseState.leftMouseReleasedThisFrame)
                    {
                        if (m_operatorWidgetPressedLast == operatorUnderPoint && cycleOperator(operatorUnderPoint, termArea))
                        {
                            m_eventDispatcher.dispatchEventWith(GameEvent.CHANGED_OPERATOR);
                            m_eventDispatcher.dispatchEventWith(GameEvent.EQUATION_CHANGED);
                            status = ScriptStatus.SUCCESS;
                        }
                        
                        m_operatorWidgetPressedLast = null;
                    }
                    
                    if (m_operatorWidgetPressedLast != null)
                    {
                        var operatorPressedScale:Number = 1.0;
                        if (m_mouseState.leftMouseDown)
                        {
                            // Scale down operator on press
                            operatorPressedScale = 0.8;
                        }
                        m_operatorWidgetPressedLast.groupImage.scaleX = m_operatorWidgetPressedLast.groupImage.scaleY = operatorPressedScale;
                    }
                    else if (m_operatorUnderPointLastFrame != null)
                    {
                        m_operatorUnderPointLastFrame.groupImage.scaleX = m_operatorUnderPointLastFrame.groupImage.scaleY = 1.2;
                    }
                }
                else
                {
                    // Clear any hover over modifications on the pressed widget                    
                    if (m_operatorUnderPointLastFrame != null)
                    {
                        m_operatorUnderPointLastFrame.groupImage.scaleX = m_operatorUnderPointLastFrame.groupImage.scaleY = 1.0;
                    }
                }
                m_operatorUnderPointLastFrame = operatorUnderPoint;
            }
            
            return status;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            this.setIsActive(m_isActive);
        }
        
        private function populateOperatorsToCycleThrough():void
        {
            // Go through level rules and check that the operator is allowed
            var vectorSpace:IVectorSpace = m_expressionCompiler.getVectorSpace();
            m_operatorsToCycleThrough.length = 0;
            m_operatorsToCycleThrough.push(
                vectorSpace.getAdditionOperator()
            );
            
            var levelRules:LevelRules = m_levelRules;
            if (levelRules.allowSubtract)
            {
                m_operatorsToCycleThrough.push(vectorSpace.getSubtractionOperator());
            }
            
            if (levelRules.allowMultiply)
            {
                m_operatorsToCycleThrough.push(vectorSpace.getMultiplicationOperator());
            }
            
            // TODO: The current orientation of division is odd since we never really want to stack things ontop
            /*
            if (levelRules.allowDivide)
            {
            m_operatorsToCycleThrough.push(vectorSpace.getDivisionOperator());
            }
            */
        }
        
        /**
         * Attempt to cycle the operator on the given term widget
         * 
         * @return
         *      true if a cycle could be performed
         */
        public function cycleOperator(targetWidget:BaseTermWidget, termAreaWidget:TermAreaWidget):Boolean
        {
            var success:Boolean = false;
            if (targetWidget is GroupTermWidget)
            {
                // From the starting operator, find the next one to cycle to
                var currentOperator:String = targetWidget.getNode().data;
                var indexOfNextOperator:int = -1;
                var indexOfCurrentOperator:int = m_operatorsToCycleThrough.indexOf(currentOperator);
                
                if (indexOfCurrentOperator >= 0)
                {
                    indexOfNextOperator = indexOfCurrentOperator + 1;
                    if (indexOfNextOperator >= m_operatorsToCycleThrough.length)
                    {
                        indexOfNextOperator = 0;
                    }
                    
                    var nextOperator:String = m_operatorsToCycleThrough[indexOfNextOperator];
                    if (nextOperator != currentOperator)
                    {
                        termAreaWidget.isReady = false;
                        termAreaWidget.getTree().changeOperatorOnNode(targetWidget.getNode(), nextOperator);
                        termAreaWidget.redrawAfterModification();
                        
                        success = true;
                    }
                }
            }
            
            return success;
        }
    }
}