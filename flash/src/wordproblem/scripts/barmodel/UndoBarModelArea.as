package wordproblem.scripts.barmodel
{
    import cgs.Audio.Audio;
    import cgs.internationalization.StringTable;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Button;
    
    import starling.events.Event;
    
    import wordproblem.callouts.TooltipControl;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script handles undoing actions that were performed on the bar modeling widget
     */
    public class UndoBarModelArea extends BaseBarModelScript
    {
        /**
         * A history list of the bar model information
         */
        private var m_barModelDataHistory:Vector.<BarModelData>;
        
        /**
         * The button when pressed that should trigger the undo
         */
        private var m_undoButton:Button;
        
        private var m_tooltipControl:TooltipControl;
        
        public function UndoBarModelArea(gameEngine:IGameEngine, 
                                         expressionCompiler:IExpressionTreeCompiler, 
                                         assetManager:AssetManager, 
                                         id:String=null, 
                                         isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            m_barModelDataHistory = new Vector.<BarModelData>();
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                if (m_undoButton != null)
                {
                    m_undoButton.removeEventListener(Event.TRIGGERED, onUndoButtonClick);
                    m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, onBarModelAreaChange);
                    if (value)
                    {
                        m_undoButton.addEventListener(Event.TRIGGERED, onUndoButtonClick);
                        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, onBarModelAreaChange);
                    }
                }
            }
        }
        
        override public function visit():int
        {
            if (m_ready && m_isActive)
            {
                m_tooltipControl.onEnterFrame();
            }
            return ScriptStatus.SUCCESS;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_undoButton = m_gameEngine.getUiEntity("undoButton") as Button;
            m_tooltipControl = new TooltipControl(m_gameEngine, "undoButton", StringTable.lookup("undo"));
            
            this.setIsActive(m_isActive);
        }
        
        /**
         * Clear out history (useful for multi-part problems)
         */
        public function resetHistory():void
        {
            m_barModelDataHistory.length = 0;
        }
        
        public function undo():void
        {
            if (m_barModelDataHistory.length > 0)
            {
                var snapshotToGoTo:BarModelData = m_barModelDataHistory.pop();
                m_barModelArea.setBarModelData(snapshotToGoTo);
                m_barModelArea.redraw();
            }
            
            this.toggleUndoButtonEnabled(m_barModelDataHistory.length > 0);
        }
        
        private function onUndoButtonClick():void
        {
            Audio.instance.playSfx("button_click");
            undo();
            
            // Log that an undo was performed on the bar model
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.UNDO_BAR_MODEL, false, {
                barModel:m_barModelArea.getBarModelData().serialize()
            });
        }
        
        /**
         * Need to detect all changes in the bar model data. On each change need to create a snapshot
         * of the model data and save it for later
         */
        private function onBarModelAreaChange(event:Event, params:Object):void
        {
            m_barModelDataHistory.push(params.previousSnapshot);
            
            this.toggleUndoButtonEnabled(m_barModelDataHistory.length > 0);
        }
        
        private function toggleUndoButtonEnabled(enabled:Boolean):void
        {
            m_undoButton.alpha = (enabled) ? 1.0 : 0.4;
            m_undoButton.isEnabled = enabled;
        }
    }
}