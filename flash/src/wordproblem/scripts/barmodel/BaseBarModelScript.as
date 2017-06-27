package wordproblem.scripts.barmodel
{
    import flash.geom.Point;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.XColor;
    
    import starling.events.EventDispatcher;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    public class BaseBarModelScript extends BaseGameScript
    {
        /**
         * The bar model area is the main portion of the screen that we want to detect the dropping
         * of cards onto.
         */
        protected var m_barModelArea:BarModelAreaWidget;
        
        /**
         * The drag system manages the dragging of cards representing terms, we use this to detect whether a mouse
         * release is also tied to the dropping of a card.
         */
        protected var m_widgetDragSystem:WidgetDragSystem;
        
        /**
         * Temp point object to store the global coordinates of the mouse
         */
        protected var m_globalMouseBuffer:Point;
        
        /**
         * Temp point object to store the coordinate of the mouse relative to a local frame
         */
        protected var m_localMouseBuffer:Point;
        
        /**
         * A script should only hide a preview if it activated it.
         * Otherwise we have a situation where previews might flicker on and off.
         */
        protected var m_didActivatePreview:Boolean;
        
        /**
         * Dispatcher to send game related signals, usually this is the passed in game engine.
         * Exception is for situation like the tip playback animation or replays .
         */
        protected var m_eventDispatcher:EventDispatcher;
        
        /**
         * Mouse data used to interpret interactions
         */
        protected var m_mouseState:MouseState;
        
        /**
         * List of element ids that an action should be restricted to. It is up to the subclasses
         * to use this list in the appropriate fashion. (some scripts might use actual ids and others
         * may use values)
         * If list is empty or null, no restrictions should be placed
         */
        protected var m_restrictedElementIds:Vector.<String>;
        
        public function BaseBarModelScript(gameEngine:IGameEngine, 
                                           expressionCompiler:IExpressionTreeCompiler, 
                                           assetManager:AssetManager, 
                                           id:String=null, 
                                           isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_globalMouseBuffer = new Point();
            m_localMouseBuffer = new Point();
            
            m_didActivatePreview = false;
            m_restrictedElementIds = new Vector.<String>();
        }
        
        /**
         * For some of the tutorials we will want to restrict the gestures the player can
         * perform on a bar model to very specific parts.
         * For example we only want them to be able to split a specific box.
         * Note that ids of an element change when it gets deleted.
         *
         * Calling this function replaces all previous restrictions set by ealier calls
         * 
         * @param ids
         *      List of element ids in the current model that this script should restrict it
         */
        public function setRestrictedElementIdsCanPerformAction(elementIds:Vector.<String>):void
        {
            m_restrictedElementIds.length = 0;
            
            if (elementIds != null)
            {
                for each (var elementsId:String in elementIds)
                {
                    m_restrictedElementIds.push(elementsId);
                }
            }
        }
        
        /**
         * HACK function so that the 'tips' section of the game help menu
         * can re-use these scripts to show a playback.
         * 
         * Manually set up parts of the script that
         * 
         * Each subclass MUST call this, not overridable because each subclass may have additional params
         * as part of setup. If it doesn't then this function can be called directly.
         */
        public function setCommonParams(barModelArea:BarModelAreaWidget, 
                                        widgetDragSystem:WidgetDragSystem, 
                                        gameEngineEventDispatcher:EventDispatcher, 
                                        mouseState:MouseState):void
        {
            m_barModelArea = barModelArea;
            m_widgetDragSystem = widgetDragSystem;
            m_eventDispatcher = gameEngineEventDispatcher;
            m_mouseState = mouseState;
            
            if (m_eventDispatcher != m_gameEngine)
            {
                m_eventDispatcher.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
            }
            
            m_ready = true;
        }
        
        override public function reset():void
        {
            // Clear out the buffers
            while (m_eventTypeBuffer.length > 0)
            {
                m_eventTypeBuffer.pop();
            }
            
            while (m_eventParamBuffer.length > 0)
            {
                m_eventParamBuffer.pop();
            }
            
            m_didActivatePreview = false;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            if (m_gameEngine != null)
            {
                m_gameEngine.removeEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
            }
            
            if (m_gameEngine != m_eventDispatcher)
            {
                m_eventDispatcher.removeEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_barModelArea = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_widgetDragSystem = this.getNodeById("WidgetDragSystem") as WidgetDragSystem;
            
            // Listen for drop of a dragged object
            m_gameEngine.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
            m_eventDispatcher = m_gameEngine as EventDispatcher;
            m_mouseState = m_gameEngine.getMouseState();
        }
        
        protected function getRandomColorForSegment():uint
        {
            return XColor.getDistributedHsvColor(Math.random());
        }
        
        protected function getBarColor(termValue:String, extraDragParams:Object):uint
        {
            var color:uint = 0xFFFFFF;
            if (extraDragParams != null && extraDragParams.hasOwnProperty("color")) 
            {
                color = extraDragParams.color;
            }
            else if (termValue != null)
            {
                var symbolData:SymbolData = (m_gameEngine != null) ? m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(termValue) : null;
                if (symbolData == null)
                {
                    color = getRandomColorForSegment();
                }
                else if (symbolData.useCustomBarColor)
                {
                    color = symbolData.customBarColor;
                }
                else
                {
                    color = getRandomColorForSegment();
                    symbolData.useCustomBarColor = true;
                    symbolData.customBarColor = color;
                }
            }
            else
            {
                color = getRandomColorForSegment();
            }
            return color;
        }
        
        /**
         * Helper that sets the dragged widget from transparent to opaque.
         * Setting to transparent.
         */
        protected function setDraggedWidgetVisible(visible:Boolean):void
        {
            if (m_widgetDragSystem.getWidgetSelected() != null)
            {
                var draggedWidget:BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
                if (visible)
                {
                    draggedWidget.alpha = 1.0;   
                }
                else
                {
                    draggedWidget.alpha = 0.2;
                }
            }
        }
    }
}