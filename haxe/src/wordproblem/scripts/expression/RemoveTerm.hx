package wordproblem.scripts.expression;


import flash.geom.Point;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * Base script to handle remove an existing term
 */
class RemoveTerm extends BaseTermAreaScript
{
    /**
     * Create a single entry place where we have cards being dragged into term areas.
     * Hand over control of the dragged card that was removed
     */
    private var m_widgetDragSystem : WidgetDragSystem;
    
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * Reference to the original term area the dragged object came from
     */
    private var m_selectedTermArea : TermAreaWidget;
    
    /**
     * Reference to the original widget in one of the term areas that was dragged.
     */
    private var m_selectedWidget : BaseTermWidget;
    
    /**
     * Widget being dragged around, it is a copy of an object in the term area.
     * Later on the control of the dragged object gets passed to the widget drag
     * system.
     */
    private var m_draggedWidget : BaseTermWidget;
    
    /**
     * The radius that the dragged widget must exceed from the original selected radius before
     * it gets removed. A drop within this radius snaps the dragged object back to its original position.
     */
    private var m_dragRadius : Float = 30;
    
    // Buffer objects
    private var m_mousePoint : Point;
    private var m_selectedWidgetAnchorPoint : Point;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_mousePoint = new Point();
        m_selectedWidgetAnchorPoint = new Point();
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            
            super.iterateThroughBufferedEvents();
            
            if (m_draggedWidget != null) 
            {
                if (mouseState.leftMouseDraggedThisFrame) 
                {
                    // Check if the current drag position exceeds the max allowed radius
                    // If it does we remove the widget from the term area and hand over
                    // control to the deck area
                    if (!MathUtil.pointInCircle(m_selectedWidgetAnchorPoint, m_dragRadius, m_mousePoint)) 
                    {
                        // Check whether we are allowed to remove the given term
                        var draggedTermValue : String = m_selectedWidget.getNode().data;
                        var canRemoveTerm : Bool = true;
                        var nonRemoveableTerms : Array<String> = m_levelRules.termsNotRemovable;
						if (nonRemoveableTerms.indexOf(draggedTermValue) >= 0) {
							canRemoveTerm = false;
						}
						
                        if (canRemoveTerm) 
                        {
                            // This small segment of code is overrideable because we want a slightly modified
                            // behavior where removing a node will replace it with a blank at that same spot
                            onRemoveCallback(m_selectedTermArea, m_selectedWidget);
                            
                            // Use an external system to drag around the new object
                            m_widgetDragSystem.selectAndStartDrag(m_selectedWidget.getNode(), m_mousePoint.x, m_mousePoint.y, m_selectedTermArea, null);
                            m_draggedWidget = null;
                            m_gameEngine.dispatchEventWith(GameEvent.REMOVE_TERM, false, {
                                        widget : m_selectedWidget
                                    });
                            
                            m_gameEngine.dispatchEventWith(GameEvent.EQUATION_CHANGED);
                        }
                    }
                }
                else if (mouseState.leftMouseReleasedThisFrame) 
                {
                    // Snap the dragged widget back into place
                    m_selectedWidget.alpha = 1.0;
                    m_draggedWidget = null;
                }
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.START_DRAG_TERM_AREA) 
        {
            var selectedWidget : BaseTermWidget = param.widget;
            var targetTermArea : TermAreaWidget = try cast(param.termArea, TermAreaWidget) catch(e:Dynamic) null;
            
            if (Std.is(selectedWidget, SymbolTermWidget)) 
            {
                // Remember the term area that was selected
                m_selectedTermArea = targetTermArea;
                
                // Create a copy of the dragged widget
                m_draggedWidget = new SymbolTermWidget(selectedWidget.getNode(), m_expressionSymbolMap, m_assetManager);
                
                // Keep a reference to the selected widget as well as its position relative to the
                // dragged copy's parent
                m_selectedWidget = selectedWidget;
                m_selectedWidget.alpha = 0.3;
                selectedWidget.parent.localToGlobal(new Point(selectedWidget.x, selectedWidget.y), m_selectedWidgetAnchorPoint);
            }
        }
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            m_gameEngine.removeEventListener(GameEvent.START_DRAG_TERM_AREA, bufferEvent);
            if (value) 
            {
                m_gameEngine.addEventListener(GameEvent.START_DRAG_TERM_AREA, bufferEvent);
            }
        }
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_widgetDragSystem = try cast(this.getNodeById("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null;
        m_expressionSymbolMap = this.m_gameEngine.getExpressionSymbolResources();
        setIsActive(m_isActive);
    }
    
    /**
     * Callback that gets triggered the moment the player has moved an existing term far enough such that
     * it should be removed
     * 
     * Function accepts two parameters, the first is the term area widget, the second is the term widget moved
     */
    private function onRemoveCallback(termArea : TermAreaWidget, termWidget : BaseTermWidget) : Void
    {
        // Remove the node of the dragged item from the term area
        termArea.isReady = false;
        termArea.getTree().removeNode(termWidget.getNode());
        termArea.redrawAfterModification();
		
        // Log the expression pickup - being picked up from a term area
        var uiComponentName : String = (termArea == m_gameEngine.getUiEntity("leftTermArea")) ? "leftTermRegion" : "rightTermRegion";
        var loggingDetails_pickup : Dynamic = {
            expressionName : Std.string(termWidget.getNode()),
            regionPickup : uiComponentName,
            locationX : m_mousePoint.x,
            locationY : m_mousePoint.y,
        };
        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EXPRESSION_PICKUP_EVENT, false, loggingDetails_pickup);
    }
}
