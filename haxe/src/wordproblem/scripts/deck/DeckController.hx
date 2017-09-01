package wordproblem.scripts.deck;


import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XString;

import motion.Actuate;

import openfl.display.DisplayObject;
import openfl.geom.Point;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.DataEvent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;
import wordproblem.scripts.drag.WidgetDragSystem;

import wordproblem.engine.animation.SnapBackAnimation;

/**
 * Manages all the interactions the player has exclusively with the deck.
 * Note that this does not incorporate logic of adding items from the deck to other areas.
 * 
 * (Most of these should be self contained)
 */
class DeckController extends BaseGameScript
{
    private var m_globalMouseBuffer : Point = new Point();
    
    /**
     * Record the last coordinates of a mouse press to check whether the mouse has
     * moved far enough to trigger a drag.
     */
    private var m_lastMousePressPoint : Point = new Point();
    
    /**
     * Primary layer where individual symbols are added on top of
     */
    private var m_deckArea : DeckWidget;
    
    /**
     * The reference to the original object contained in the deck that was
     * selected. This is only set if the player has dragged a card from the deck.
     */
    private var m_originalOfDraggedWidget : BaseTermWidget;
    
    /**
     * Keep track of the current object the user has pressed down on.
     * Null if they are not pressed down on anything.
     */
    private var m_currentEntryPressed : BaseTermWidget;
    
    /**
     * The system hands over control of the dragged item to the widget dragging system
     */
    private var m_widgetDragSystem : WidgetDragSystem;
    
    private var m_snapBackAnimation : SnapBackAnimation;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    override public function setIsActive(value : Bool) : Void
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
    
    override public function visit() : Int
    {
        // This system depends on the deck being part of the display list
        if (!m_ready || m_deckArea == null || Layer.getDisplayObjectIsInInactiveLayer(m_deckArea)) 
        {
            return ScriptStatus.FAIL;
        }
        
        this.iterateThroughBufferedEvents();
        
        var mouseState : MouseState = m_gameEngine.getMouseState();
        m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
        
        if (mouseState.leftMousePressedThisFrame) 
        {
            // Perform a hit test with all objects
            var hitObject : BaseTermWidget = try cast(m_deckArea.getObjectUnderPoint(m_globalMouseBuffer.x, m_globalMouseBuffer.y), BaseTermWidget) catch(e:Dynamic) null;
            if (hitObject != null && !hitObject.getIsHidden() && hitObject.getIsEnabled()) 
            {
                m_gameEngine.dispatchEvent(new DataEvent(GameEvent.SELECT_DECK_AREA, hitObject));
                
                m_currentEntryPressed = hitObject;
                m_lastMousePressPoint.setTo(m_globalMouseBuffer.x, m_globalMouseBuffer.y);
                
                var params : Dynamic = {
                    termWidget : m_currentEntryPressed,
                    location : m_globalMouseBuffer,
                };
                m_gameEngine.dispatchEvent(new DataEvent(GameEvent.START_DRAG_DECK_AREA, params));
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
    
    override public function dispose() : Void
    {
        super.dispose();
        
        if (m_snapBackAnimation != null) 
        {
            m_snapBackAnimation.dispose();
        }
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        m_deckArea = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        m_widgetDragSystem = try cast(this.getNodeById("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null;
        
        m_snapBackAnimation = new SnapBackAnimation();
        
        this.setIsActive(m_isActive);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.END_DRAG_TERM_WIDGET) 
        {
            var origin : DisplayObject = param.origin;
            if (Std.is(origin, DeckWidget) && Std.is(param.widget, SymbolTermWidget)) 
            {
                this.snapWidgetBackToDeck({
                            widget : param.widget,
                            origin : param.origin,
                        });
            }
        }
        else if (eventType == GameEvent.ADD_TERM_ATTEMPTED) 
        {
            this.snapWidgetBackToDeck(param);
        }
    }
    
    private function snapWidgetBackToDeck(params : Dynamic) : Void
    {
        var widget : BaseTermWidget = params.widget;
        var animate : Bool = !params.success;
        
        var data : String = widget.getNode().data;
        
        if (animate) 
        {
            var widgetToSnap : BaseTermWidget = m_deckArea.getWidgetFromSymbol(data);
			function onAnimationDone() : Void
            {
                if (widget.parent != null) widget.parent.removeChild(widget);
				m_snapBackAnimation.stop();
                
                if (m_originalOfDraggedWidget != null) 
                {
                    m_originalOfDraggedWidget.alpha = ((m_originalOfDraggedWidget.getIsEnabled())) ? 1.0 : m_originalOfDraggedWidget.alpha;
                    m_originalOfDraggedWidget = null;
                }
            };
            if (widgetToSnap != null && !widgetToSnap.getIsHidden()) 
            {
                if (m_deckArea.stage != null) 
                {
                    widgetToSnap.stage.addChild(widget);
                    m_snapBackAnimation.setParameters(widget, widgetToSnap, 800, onAnimationDone);
					m_snapBackAnimation.start();
                }
            }
            else 
            {
				Actuate.tween(widget, 0.5, { alpha: 0 });
            }
        }
        else 
        {
            if (widget.parent != null) widget.parent.removeChild(widget);
            if (m_originalOfDraggedWidget != null) 
            {
                m_originalOfDraggedWidget.alpha = ((m_originalOfDraggedWidget.getIsEnabled())) ? 1.0 : m_originalOfDraggedWidget.alpha;
                m_originalOfDraggedWidget = null;
            }
        }
    }
    
    private function onEntryClick(pickedWidget : BaseTermWidget) : Void
    {
        // If an entry has been clicked we first assume that it is an attempt to turn
        // the given card.
        if (m_gameEngine.getCurrentLevel().getLevelRules().allowCardFlip && XString.isNumber(pickedWidget.getNode().data)) 
        {
            // Log flip
            var uiComponentName : String = m_gameEngine.getUiEntityUnder(m_globalMouseBuffer).entityId;
            var loggingDetails : Dynamic = {
                expressionName : Std.string(pickedWidget.getNode()),
                regionFlipped : uiComponentName,
                locationX : m_globalMouseBuffer.x,
                locationY : m_globalMouseBuffer.y,
            };
            m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.NEGATE_EXPRESSION_EVENT, loggingDetails));
            
            // Flip card
            m_deckArea.reverseValue(pickedWidget);
        }
    }
    
    private function onEntryDrag(pickedWidget : BaseTermWidget) : Void
    {
        m_originalOfDraggedWidget = pickedWidget;
        m_originalOfDraggedWidget.alpha = 0.4;
        
        // Log the expression pickup - bring picked up from the deck
        var currLoc : Point = pickedWidget.localToGlobal(new Point());
        var uiComponentName : String = "deckArea";  // At this point, we are always picking up in the deck area  
        var loggingDetails_pickup : Dynamic = {
            expressionName : Std.string(pickedWidget.getNode()),
            regionPickup : uiComponentName,
            locationX : currLoc.x,
            locationY : currLoc.y,
        };
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.EXPRESSION_PICKUP_EVENT, loggingDetails_pickup));
        
        // We first check that the given card is valid for dragging
        // If it is then we set is as the active object being dragged.
        m_widgetDragSystem.selectAndStartDrag(pickedWidget.getNode(), m_globalMouseBuffer.x, m_globalMouseBuffer.y, m_deckArea, null);
    }
}
