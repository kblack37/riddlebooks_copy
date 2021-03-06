package wordproblem.scripts.barmodel
{
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Button;
    
    import starling.events.Event;
    
    import wordproblem.callouts.TooltipControl;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    /**
     * Script controlling the reset button and resetting the bar model area back to some initial state.
     * (Usually initial state is empty but it can also be set an actual drawing.)
     */
    public class ResetBarModelArea extends BaseBarModelScript
    {
        private var m_resetButton:Button;
        
        /**
         * The model that the reset should clear back to.
         * 
         * If null then go back to empty model
         */
        private var m_startingModel:BarModelData;
        
        private var m_tooltipControl:TooltipControl;
        
        public function ResetBarModelArea(gameEngine:IGameEngine, 
                                          expressionCompiler:IExpressionTreeCompiler, 
                                          assetManager:AssetManager, 
                                          id:String=null, 
                                          isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                if (m_resetButton != null)
                {
                    m_resetButton.removeEventListener(Event.TRIGGERED, onReset);
                    if (value)
                    {
                        m_resetButton.addEventListener(Event.TRIGGERED, onReset);
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
            m_resetButton = m_gameEngine.getUiEntity("resetButton") as Button;
            
            m_tooltipControl = new TooltipControl(m_gameEngine, "resetButton", "Reset");
            
            // Activate again to make sure the event listener is bound to the button we just found
            setIsActive(m_isActive);       
        }
        
        /**
         * Sometimes we have a fixed starting point, reset should clear back to that point
         * instead of making everything empty. For example we have a tutorial level that starts
         * of with a partially completed drawing, a reset should go back to the partial drawing.
         * 
         * @param startingModel
         *      If null, reset will show empty model. Reset uses an internal copy
         */
        public function setStartingModel(startingModel:BarModelData):void
        {
            if (startingModel != null)
            {
                startingModel = startingModel.clone();
            }
            m_startingModel = startingModel;
        }
        
        private function onReset():void
        {
            Audio.instance.playSfx("button_click");
            if (m_startingModel == null)
            {
                m_barModelArea.getBarModelData().clear();
            }
            else
            {
                m_barModelArea.setBarModelData(m_startingModel.clone());
            }
            m_barModelArea.redraw();
            
            var loggingDetails:Object = {buttonName:"ResetButton"}            
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.RESET_BAR_MODEL, false, loggingDetails);    
            
            // Dependency on undo, clear out the history stack on reset
            var undoBarModelArea:UndoBarModelArea = this.getNodeById("UndoBarModelArea") as UndoBarModelArea;
            if (undoBarModelArea != null)
            {
                undoBarModelArea.resetHistory();
            }
        }
    }
}