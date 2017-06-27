package wordproblem.scripts.expression
{
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import feathers.controls.Button;
    
    import starling.display.DisplayObject;
    import starling.events.Event;
    
    import wordproblem.callouts.TooltipControl;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.expression.tree.HistoryManager;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * TODO: Bug where this thing potentially adds a null expression at the start which causes an undo to clobber
     * initially set expression. ex.) we want the user to start with expressions already filled in, undo should return to this state
     * Work around in for levels using this to manually call the overrideOnLevelReady BEFORE they set an inital expression
     */
    public class UndoTermArea extends BaseGameScript
    {
        /**
         * The history for the current equation
         */
        private var m_historyManager:HistoryManager;
        
        /**
         * Reference to the button that when clicked should trigger an undo. If there is nothing to
         * undo then it should be disabled.
         */
        private var m_undoButton:Button;
        
        /**
         * Logic to get tooltip to appear on the undo button
         */
        private var m_tooltipControl:TooltipControl;
        
        public function UndoTermArea(gameEngine:IGameEngine, 
                                     expressionCompiler:IExpressionTreeCompiler, 
                                     assetManager:AssetManager, 
                                     id:String=null, 
                                     isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override public function visit():int
        {
            // Add tooltip on hover over
            if (m_ready && m_isActive && m_undoButton != null && m_undoButton.parent != null)
            {
                m_tooltipControl.onEnterFrame();
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                var i:int;
                var termArea:TermAreaWidget;
				var termAreaWidgets:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
                
				for (i = 0; i < termAreaWidgets.length; i++)
				{
					termArea = termAreaWidgets[i] as TermAreaWidget;
					termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
				}
				
				m_undoButton.removeEventListener(Event.TRIGGERED, clickUndo);
				
                if (value)
                {
                    // Need to listen for event when a new equation was selected, as this affects the current history
                    // stack we use for undo
                    for (i = 0; i < termAreaWidgets.length; i++)
                    {
                        termArea = termAreaWidgets[i] as TermAreaWidget;
                        termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                    }
                    m_undoButton.addEventListener(Event.TRIGGERED, clickUndo);
                    
                    toggleUndoButtonEnabled(m_historyManager.canUndo());
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_undoButton = m_gameEngine.getUiEntity("undoButton") as Button;
            
            // Once a player has modeled an equation we need to add it the history manager
            if (m_undoButton != null)
            {
                resetHistory(false);
                m_tooltipControl = new TooltipControl(m_gameEngine, "undoButton", "Undo");
            }
            this.setIsActive(m_isActive);
        }
        
        /**
         * Clear previous history contents and reset it to the current contents of the
         * term area.
         * 
         * @param setFirstEntryToExistingTermArea
         *      If true then the first entry of the history stack should look at what is in the
         *      current term areas and record that as a history entry. If false then it
         *      uses the given leftRoot, rightRoot params to make the first entry.
         */
        public function resetHistory(setFirstEntryToExistingTermArea:Boolean, 
                                     leftRoot:ExpressionNode=null, 
                                     rightRoot:ExpressionNode=null):void
        {
            // Clear old history stack
            if (m_historyManager != null)
            {
                m_historyManager.dispose();
            }
            
            m_historyManager = new HistoryManager();
            
            if (setFirstEntryToExistingTermArea)
            {
                createEntryFromCurrentTermArea();
            }
            else
            {
                m_historyManager.createHistorySnapshotEquation(
                    leftRoot,
                    rightRoot,
                    m_expressionCompiler.getVectorSpace()
                );
            }
            
            toggleUndoButtonEnabled(m_historyManager.canUndo());
        }
        
        public function undo():void
        {
            // Look at the current equation in focus and pull from its stack
            var vectorSpace:IVectorSpace = m_expressionCompiler.getVectorSpace();
            var historyManager:HistoryManager = m_historyManager;
            
            // Signal that an undo was triggered
            var loggingDetails:Object = {buttonName:"UndoButton"}            
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.UNDO_EQUATION, false, loggingDetails);
            
            if (historyManager.canUndo())
            {
                var root:ExpressionNode = historyManager.undo(vectorSpace);
                var leftRoot:ExpressionNode = null;
                var rightRoot:ExpressionNode = null;
                if (root != null)
                {
                    leftRoot = ExpressionUtil.copy(root.left, vectorSpace);
                    rightRoot = ExpressionUtil.copy(root.right, vectorSpace);
                }
                
                var termAreaWidgets:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
                var leftTermArea:TermAreaWidget = termAreaWidgets[0] as TermAreaWidget;
                leftTermArea.setTree(new ExpressionTree(vectorSpace, leftRoot));
                leftTermArea.redrawAfterModification(true);
                var rightTermArea:TermAreaWidget = termAreaWidgets[1] as TermAreaWidget;
                rightTermArea.setTree(new ExpressionTree(vectorSpace, rightRoot));
                rightTermArea.redrawAfterModification(true);
            }
        }
        
        private function onTermAreaChanged(event:Event, param:Object):void
        {
            // Ignore changes triggered by this undo itself
            if (param == null || !param.undo)
            {
                // Whenever the term area under goes an incremental change we flush the contents to
                // the appropriate history slot.
                createEntryFromCurrentTermArea();
            }
            
            this.toggleUndoButtonEnabled(m_historyManager.canUndo());
        }
        
        private function createEntryFromCurrentTermArea():void
        {
            var termAreaWidgets:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
            var leftWidget:BaseTermWidget = (termAreaWidgets[0] as TermAreaWidget).getWidgetRoot();
            var leftRoot:ExpressionNode = (leftWidget != null) ? leftWidget.getNode() : null;
            var rightWidget:BaseTermWidget = (termAreaWidgets[1] as TermAreaWidget).getWidgetRoot();
            var rightRoot:ExpressionNode = (rightWidget != null) ? rightWidget.getNode() : null;
            
            m_historyManager.createHistorySnapshotEquation(
                leftRoot,
                rightRoot,
                m_expressionCompiler.getVectorSpace()
            );
        }
        
        private function toggleUndoButtonEnabled(enabled:Boolean):void
        {
            m_undoButton.alpha = (enabled) ? 1.0 : 0.4;
            m_undoButton.isEnabled = enabled;
        }
        
        private function clickUndo():void
        {
            Audio.instance.playSfx("button_click");
            undo();
        }
    }
}