package wordproblem.scripts.expression.solving
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.drag.WidgetDragSystem;
    import wordproblem.scripts.expression.BaseTermAreaScript;
    
    /**
     * This script controls when a card in the term area is dragged.
     * 
     * The scripts that use the dragged card cannot be responsible since they do not know
     * about other gestures ideally thus should not be in control of initiating the drag.
     * 
     * This script starts up the process of setting the drag.
     */
    public class TermAreaDragActivateScript extends BaseTermAreaScript
    {
        private var m_widgetDragSystem:WidgetDragSystem;
        
        public function TermAreaDragActivateScript(gameEngine:IGameEngine, 
                                                   expressionCompiler:IExpressionTreeCompiler, 
                                                   assetManager:AssetManager, 
                                                   id:String=null, 
                                                   isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.PRESS_TERM_AREA, bufferEvent);
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            if (m_eventTypeBuffer.length > 0)
            {
                var indexOfPressEvent:int = m_eventTypeBuffer.indexOf(GameEvent.PRESS_TERM_AREA);
                var mouseState:MouseState = m_gameEngine.getMouseState();
                if (indexOfPressEvent >= 0)
                {
                    var params:Object = m_eventParamBuffer[indexOfPressEvent] as Object;
                    var widget:BaseTermWidget = params.widget as BaseTermWidget;
                    var termArea:TermAreaWidget = params.termArea;
                    m_widgetDragSystem.selectAndStartDrag(
                        widget.getNode(), 
                        mouseState.mousePositionThisFrame.x, 
                        mouseState.mousePositionThisFrame.y,
                        termArea,
                        null
                    );
                }
                reset();
            }
            return status;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_widgetDragSystem = this.getNodeById("WidgetDragSystem") as WidgetDragSystem;
            m_gameEngine.addEventListener(GameEvent.PRESS_TERM_AREA, bufferEvent);
        }
    }
}