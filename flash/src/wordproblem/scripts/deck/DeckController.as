package wordproblem.scripts.deck
{
    import flash.geom.Point;
    
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.util.MathUtil;
    import dragonbox.common.ui.MouseState;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.animation.SnapBackAnimation;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.SymbolTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    /**
     * Manages all the interactions the player has exclusively with the deck.
     * Note that this does not incorporate logic of adding items from the deck to other areas.
     * 
     * (Most of these should be self contained)
     */
    public class DeckController extends BaseGameScript
    {
        private const m_globalMouseBuffer:Point = new Point();
        
        /**
         * Record the last coordinates of a mouse press to check whether the mouse has
         * moved far enough to trigger a drag.
         */
        private var m_lastMousePressPoint:Point = new Point();
        
        /**
         * Primary layer where individual symbols are added on top of
         */
        private var m_deckArea:DeckWidget;
        
        /**
         * The reference to the original object contained in the deck that was
         * selected. This is only set if the player has dragged a card from the deck.
         */
        private var m_originalOfDraggedWidget:BaseTermWidget;
        
        /**
         * Keep track of the current object the user has pressed down on.
         * Null if they are not pressed down on anything.
         */
        private var m_currentEntryPressed:BaseTermWidget;
        
        /**
         * The system hands over control of the dragged item to the widget dragging system
         */
        private var m_widgetDragSystem:WidgetDragSystem;
        
        private var m_snapBackAnimation:SnapBackAnimation;
        
        public function DeckController(gameEngine:IGameEngine, 
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
                m_gameEngine.removeEventListener(GameEvent.ADD_TERM_ATTEMPTED, bufferEvent);
                m_gameEngine.removeEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
                if (value)
                {
                    m_gameEngine.addEventListener(GameEvent.ADD_TERM_ATTEMPTED, bufferEvent);
                    
                    // Listen for drop of a dragged object
                    m_gameEngine.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
                }
            }
        }
        
        override public function visit():int
        {
            // This system depends on the deck being part of the display list
            if (!m_ready || m_deckArea == null || Layer.getDisplayObjectIsInInactiveLayer(m_deckArea))
            {
                return ScriptStatus.FAIL;
            }
            
            this.iterateThroughBufferedEvents();
            
            var mouseState:MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            
            if (mouseState.leftMousePressedThisFrame)
            {
                // Perform a hit test with all objects
                var hitObject:BaseTermWidget = m_deckArea.getObjectUnderPoint(m_globalMouseBuffer.x, m_globalMouseBuffer.y) as BaseTermWidget;
                if (hitObject != null && !hitObject.getIsHidden() && hitObject.getIsEnabled())
                {
                    m_gameEngine.dispatchEventWith(GameEvent.SELECT_DECK_AREA, false, hitObject);
                    
                    m_currentEntryPressed = hitObject;
                    m_lastMousePressPoint.setTo(m_globalMouseBuffer.x, m_globalMouseBuffer.y);
                    
                    var params:Object = {termWidget:m_currentEntryPressed, location:m_globalMouseBuffer}
                    m_gameEngine.dispatchEventWith(GameEvent.START_DRAG_DECK_AREA, false, params);
                    Audio.instance.playSfx("pickup_card_deck");
                }
            }
            else if (mouseState.leftMouseDraggedThisFrame && m_currentEntryPressed != null)
            {
                if (!MathUtil.pointInCircle(m_lastMousePressPoint, 10, m_globalMouseBuffer) && m_currentEntryPressed.getIsEnabled())
                {
                    this.onEntryDrag(m_currentEntryPressed);
                    m_currentEntryPressed = null;
                }
            }
            else if (mouseState.leftMouseReleasedThisFrame)
            {
                // This detects a click on an undragged card
                if (m_currentEntryPressed != null)
                {
                    this.onEntryClick(m_currentEntryPressed);
                    m_currentEntryPressed = null;
                }
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            if (m_snapBackAnimation != null)
            {
                Starling.juggler.remove(m_snapBackAnimation);
                m_snapBackAnimation.dispose();
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_deckArea = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            m_widgetDragSystem = this.getNodeById("WidgetDragSystem") as WidgetDragSystem;
            
            m_snapBackAnimation = new SnapBackAnimation();
            
            this.setIsActive(m_isActive);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.END_DRAG_TERM_WIDGET)
            {
                var origin:DisplayObject = param.origin;
                if (origin is DeckWidget && param.widget is SymbolTermWidget)
                {
                    this.snapWidgetBackToDeck({widget:param.widget, origin:param.origin});
                }
            }
            else if (eventType == GameEvent.ADD_TERM_ATTEMPTED)
            {
                this.snapWidgetBackToDeck(param);
            }
        }
        
        private function snapWidgetBackToDeck(params:Object):void
        {
            var widget:BaseTermWidget = params.widget;
            var animate:Boolean = !params.success;
            
            var data:String = widget.getNode().data;
            
            if (animate)
            {
                const widgetToSnap:BaseTermWidget = m_deckArea.getWidgetFromSymbol(data);
                if (widgetToSnap != null && !widgetToSnap.getIsHidden())
                {
                    if (m_deckArea.stage != null)
                    {
                        widgetToSnap.stage.addChild(widget);
                        m_snapBackAnimation.setParameters(widget, widgetToSnap, 800, onAnimationDone);
                        Starling.juggler.add(m_snapBackAnimation);
                    }
                }
                else
                {
                    Starling.juggler.tween(widget, 0.5, {alpha:0.0});
                }
                
                function onAnimationDone():void
                {
                    widget.removeFromParent();
                    Starling.juggler.remove(m_snapBackAnimation);
                    
                    if (m_originalOfDraggedWidget != null)
                    {
                        m_originalOfDraggedWidget.alpha = (m_originalOfDraggedWidget.getIsEnabled()) ? 1.0 : m_originalOfDraggedWidget.alpha;
                        m_originalOfDraggedWidget = null;
                    }
                }
            }
            else
            {
                widget.removeFromParent();
                if (m_originalOfDraggedWidget != null)
                {
                    m_originalOfDraggedWidget.alpha = (m_originalOfDraggedWidget.getIsEnabled()) ? 1.0 : m_originalOfDraggedWidget.alpha;
                    m_originalOfDraggedWidget = null;
                }
            }
        }
        
        private function onEntryClick(pickedWidget:BaseTermWidget):void
        {
            // If an entry has been clicked we first assume that it is an attempt to turn
            // the given card.
            if (m_gameEngine.getCurrentLevel().getLevelRules().allowCardFlip)
            {
                // Log flip
                var uiComponentName:String = m_gameEngine.getUiEntityUnder(m_globalMouseBuffer).entityId;
                var loggingDetails:Object = {expressionName:pickedWidget.getNode().toString(), regionFlipped: uiComponentName, locationX:m_globalMouseBuffer.x, locationY:m_globalMouseBuffer.y}
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.NEGATE_EXPRESSION_EVENT, false, loggingDetails);
                
                // Flip card
                m_deckArea.reverseValue(pickedWidget);
            }
        }
        
        private function onEntryDrag(pickedWidget:BaseTermWidget):void
        {
            m_originalOfDraggedWidget = pickedWidget;
            m_originalOfDraggedWidget.alpha = 0.4;
            
            // Log the expression pickup - bring picked up from the deck
            var currLoc:Point = pickedWidget.localToGlobal(new Point());
            var uiComponentName:String = "deckArea";    // At this point, we are always picking up in the deck area
            var loggingDetails_pickup:Object = {expressionName:pickedWidget.getNode().toString(), regionPickup: uiComponentName, locationX:currLoc.x, locationY:currLoc.y};
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EXPRESSION_PICKUP_EVENT, false, loggingDetails_pickup);
            
            // We first check that the given card is valid for dragging
            // If it is then we set is as the active object being dragged.
            m_widgetDragSystem.selectAndStartDrag(pickedWidget.getNode(), m_globalMouseBuffer.x, m_globalMouseBuffer.y, m_deckArea, null);
        }
    }
}