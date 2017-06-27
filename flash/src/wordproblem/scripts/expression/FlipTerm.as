package wordproblem.scripts.expression
{
    import flash.geom.Point;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.SymbolTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script checks clicks on existing cards in the term area and flips them to the
     * opposite value.
     * 
     * Note to prevent conflicts with other scripts that also rely on detecting gestures on the
     * term area cards we cannot immediately react to events. We need to buffer it and only perform
     * the appropriate logic if a higher priority script does not do something first.
     */
    public class FlipTerm extends BaseTermAreaScript
    {
        /**
         * Buffer for logging mouse position during the flip
         */
        private const mousePoint:Point = new Point();
        
        public function FlipTerm(gameEngine:IGameEngine, 
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
                m_gameEngine.removeEventListener(GameEvent.CLICK_TERM_AREA, bufferEvent);
                if (value)
                {
                    m_gameEngine.addEventListener(GameEvent.CLICK_TERM_AREA, bufferEvent);
                }
            }
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            
            if (m_eventTypeBuffer.length > 0)
            {
                if (m_eventTypeBuffer[0] == GameEvent.CLICK_TERM_AREA)
                {
                    var params:Object = m_eventParamBuffer[0];
                    var selectedWidget:BaseTermWidget = params.widget;
                    var targetTermArea:TermAreaWidget = params.termArea;
                    
                    if (flipTermWidget(selectedWidget, targetTermArea))
                    {
                        status = ScriptStatus.SUCCESS;
                    }
                }
                
                super.reset();
            }
            
            return status;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // HACK: Need to find more consistent way to activate scripts
            this.setIsActive(m_isActive);
        }
        
        /**
         * Attempt to flip the card represented by the given widget
         * 
         * @return
         *      true if a flip was successful
         */
        public function flipTermWidget(targetWidget:BaseTermWidget, targetTermArea:TermAreaWidget):Boolean
        {
            var success:Boolean = false;
            if (targetWidget is SymbolTermWidget)
            {
                // Log flip
                var mouseState:MouseState = m_gameEngine.getMouseState();
                mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
                var uiComponentName:String = m_gameEngine.getUiEntityUnder(mousePoint).entityId;
                var loggingDetails:Object = {text:targetWidget.getNode().toString(), regionFlipped: uiComponentName, locationX:mousePoint.x, locationY:mousePoint.y}
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.NEGATE_EXPRESSION_EVENT, false, loggingDetails);
                
                // Flip card
                if (targetWidget is SymbolTermWidget && targetTermArea.isReady)
                {
                    targetTermArea.isReady = false;
                    (targetWidget as SymbolTermWidget).reverseValue(onComplete);
                    function onComplete():void
                    {
                        targetTermArea.redrawAfterModification()
                    }
                }
                
                success = true;
            }
            
            return success;
        }
    }
}