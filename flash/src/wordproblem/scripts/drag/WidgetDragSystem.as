package wordproblem.scripts.drag
{
    import flash.geom.Point;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.events.EventDispatcher;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.SymbolTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;

    /**
     * This system is responsible for the visual dragging of the widgets representing cards.
     * Several external systems will be dependent on this one to manage the dragging of
     * a card, those external system need to first register the dragged card here and it will take
     * card of redrawing it during the drag and sending a event when the card is released.
     * 
     * It is important to note that the intention of this system is not to interpret the movement,
     * it only knows about term areas at a high level and does not know where the dragged term comes from.
     * 
     * The drag system also handles presses and releases on terms.
     * 
     * NOTE:
     * The pattern to follow is that any script that initiates the drag of an object is also
     * responsible for cleaning it up. Several scripts will be interested in using the dragged object,
     * and on release can choose to 'consume' it, which may alter the behavior on clean up. For example
     * the deck starts dragging when the player moves a card around, if it is not used then the card should
     * snap back otherwise it just fades away.
     * To clean up, the script needs to listen for dispatched events.
     */
    public class WidgetDragSystem extends BaseGameScript
    {
        /**
         * The reference to the widget being dragged, note that it is different from
         * the one embedded in the deck
         */
        private var m_draggedWidget:BaseTermWidget;
        
        /**
         * The origin of the widget being dragged:
         * deck, termArea, textArea
         * 
         * Does the dragged widget represent a term that already exists in the term area? External systems
         * need to know the difference because it will change the context of actions. For example, dropping an
         * existing term could mean we just want to move the term while dropping a new term represents adding
         * it to the expression.
         */
        private var m_draggedWidgetOrigin:DisplayObject;
        
        /**
         * In rare cases (for example wanting to drag bar segments without making them look like cards) we want
         * a custom visual to be dragged and not something that looks like a card.
         * This thing will be pasted on top of the dragged widget.
         */
        private var m_customDisplay:DisplayObject;
        
        /**
         * If a part of the system requests using a custom texture to be dragged we need to keep
         * track of whether the texture should be disposed when the dragged object is not longer
         * shown.
         * 
         * Signature- callback(display:DisplayObject)
         */
        private var m_disposeCustomCallback:Function;
        
        /**
         * A mapping of extra data attributes for the currently dragged item.
         * Should be sent out along with any drag events.
         */
        private var m_extraParams:Object;
        
        private const m_globalMouseBuffer:Point = new Point();
        private const m_localMouseBuffer:Point = new Point();
        
        private var m_mouseState:MouseState;
        private var m_expressionSymbolMap:ExpressionSymbolMap;
        private var m_draggedWidgetCanvas:DisplayObjectContainer;
        private var m_eventDispatcher:EventDispatcher;
        
        public function WidgetDragSystem(gameEngine:IGameEngine, 
                                         expressionCompiler:IExpressionTreeCompiler,
                                         assetManager:AssetManager)
        {
            super(gameEngine, expressionCompiler, assetManager, "WidgetDragSystem");
        }
        
        public function setParams(mouseState:MouseState, 
                                  expressionSymbolMap:ExpressionSymbolMap, 
                                  draggedWidgetCanvas:DisplayObjectContainer, 
                                  eventDispatcher:EventDispatcher):void
        {
            m_mouseState = mouseState;
            m_expressionSymbolMap = expressionSymbolMap;
            m_draggedWidgetCanvas = draggedWidgetCanvas;
            m_eventDispatcher = eventDispatcher;
            m_ready = true;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            if (m_draggedWidget != null)
            {
                m_draggedWidget.removeFromParent(true);
                disposeCustomDisplay();
            }
        }
        
        override public function visit():int
        {
            var scriptStatus:int = ScriptStatus.SUCCESS;
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            
            if (m_draggedWidget != null)
            {
                if (m_mouseState.leftMouseDraggedThisFrame)
                {
                    // Update drag position
                    m_draggedWidget.parent.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                    m_draggedWidget.x = m_localMouseBuffer.x;
                    m_draggedWidget.y = m_localMouseBuffer.y;
                }
                else if (m_mouseState.leftMouseReleasedThisFrame)
                {
                    var releasedWidget:BaseTermWidget = m_draggedWidget;
                    var releaseWidgetOrigin:DisplayObject = m_draggedWidgetOrigin;
                    
                    // Tentatively remove the dragged object from the screen
                    releasedWidget.removeFromParent();
                    m_draggedWidget = null;
                    m_draggedWidgetOrigin = null;
                    
                    var eventType:String = (releaseWidgetOrigin is TermAreaWidget) ?
                        GameEvent.END_DRAG_EXISTING_TERM_WIDGET : GameEvent.END_DRAG_TERM_WIDGET;
                    var eventParams:Object = {widget:releasedWidget, origin:releaseWidgetOrigin};
                    if (m_extraParams != null)
                    {
                        for (var extraParamAttribute:String in m_extraParams)
                        {
                            if (!eventParams.hasOwnProperty(extraParamAttribute))
                            {
                                eventParams[extraParamAttribute] = m_extraParams[extraParamAttribute];
                            }
                        }
                    }
                    
                    m_eventDispatcher.dispatchEventWith(eventType, false, eventParams);
                    
                    m_extraParams = null;
                    disposeCustomDisplay();
                }
            }
            
            return scriptStatus;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_mouseState = m_gameEngine.getMouseState();
            m_expressionSymbolMap = m_gameEngine.getExpressionSymbolResources();
            m_draggedWidgetCanvas = m_gameEngine.getSprite().stage;
            m_eventDispatcher = m_gameEngine as EventDispatcher;
        }

        /**
         * Get extra data associated with the dragged object
         * Here are the properties that can be set
         * 'color': get back hex color that should be applied to created boxes from the dragged piece
         */
        public function getExtraParams():Object
        {
            return m_extraParams;
        }
        
        /**
         * By exposing this function we allow for external systems to be able to associate
         * some expression to be loosely associated with the deck while it is being dragged.
         * 
         * @param node
         *      The node data to create a draggable widget from
         * @param x
         * 		Global x coordinate of where the dragged object should start
         * @param y
         * 		Global y coordinate of where the dragged object should start
         * @param nodeOrigin
         *      Where the node to drag originally came from, ex.) is it an existing term in one of the term areas.
         *      Possible values are deck, termArea, textArea. It is the ui component
         * @param extraParams
         *      Any extra data attributes that should be associated with the dragged object.
         *      For example 'color' would indicate the bar segment color applied created from the
         *      dragged card. Null if no extra params desired
         */
        public function selectAndStartDrag(node:ExpressionNode, 
                                           x:Number, 
                                           y:Number, 
                                           nodeOrigin:DisplayObject,
                                           extraParams:Object,
                                           customDisplay:DisplayObject=null, 
                                           disposeCustomCallback:Function=null):void
        {
            // Can only have one dragged copy at any instance
            if (m_draggedWidget != null)
            {
                m_draggedWidget.removeFromParent(true);
                disposeCustomDisplay();
            }
            
            m_extraParams = extraParams;
            
            // For dragging bars, be able to accept a custom texture since we don't
            // want to show the number
            m_disposeCustomCallback = disposeCustomCallback;
            if (customDisplay == null)
            {
                // create a copy of the widget that can be dragged around the board
                var widgetCopy:BaseTermWidget = new SymbolTermWidget(
                    node,
                    m_expressionSymbolMap,
                    m_assetManager
                );
            }
            else
            {
                m_customDisplay = customDisplay;
                widgetCopy = new BaseTermWidget(node, m_assetManager);
                widgetCopy.addChild(m_customDisplay);
            }
            
            m_globalMouseBuffer.x = x;
            m_globalMouseBuffer.y = y;
            m_draggedWidgetCanvas.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            widgetCopy.x = m_localMouseBuffer.x;
            widgetCopy.y = m_localMouseBuffer.y;
            
            // we add the card onto the stage so it automatically appears on top of everything
            m_draggedWidgetCanvas.addChild(widgetCopy);
            
            m_draggedWidget = widgetCopy;
            m_draggedWidgetOrigin = nodeOrigin;
            
            var eventType:String = (m_draggedWidgetOrigin is TermAreaWidget) ?
                GameEvent.START_DRAG_EXISTING_TERM_WIDGET : GameEvent.START_DRAG_TERM_WIDGET;
            var params:Object = {termWidget:m_draggedWidget, location:new Point(x, y)};
            m_eventDispatcher.dispatchEventWith(eventType, false, params);
        }
        
        /**
         * Get the widget currently being dragged around
         * 
         * @return
         *      Reference to the dragged term widget or null if nothing is
         *      being dragged.
         */
        public function getWidgetSelected():BaseTermWidget
        {
            return m_draggedWidget;
        }
        
        public function manuallyEndDrag():void
        {
            // Tentatively remove the dragged object from the screen
            if (m_draggedWidget != null)
            {
                m_draggedWidget.removeFromParent();
                m_draggedWidget = null;
            }
            m_draggedWidgetOrigin = null;
            
            m_extraParams = null;
            disposeCustomDisplay();
        }
        
        private function disposeCustomDisplay():void
        {
            if (m_disposeCustomCallback != null && m_customDisplay != null)
            {
                m_disposeCustomCallback(m_customDisplay);
                m_customDisplay = null;
            }
        }
    }
}