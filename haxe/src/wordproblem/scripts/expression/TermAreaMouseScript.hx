package wordproblem.scripts.expression;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.util.MathUtil;

import starling.display.DisplayObject;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * This script handles taps, presses, and drags of the objects directly on the term areas.
 * It does not have any specific game logic, it is more like a centralized controller that the
 * logic scripts should listen to when an interesting gesture involving the term areas is
 * initiated.
 */
class TermAreaMouseScript extends BaseTermAreaScript
{
    /**
     * Temp buffer to store mouse coordinates on every update
     */
    private var m_globalMousePoint : Point = new Point();
    
    /**
     * The widget that the user has pressed down on.
     */
    private var m_currentWidgetPressed : BaseTermWidget;
    private var m_termAreaForCurrentWidgetPressed : TermAreaWidget;
    
    /**
     * A buffer storing last click point, on another frame we use this to check whether the
     * cursor has exceeded the neccessary radius such that we can treat it as a drag gesture
     */
    private var m_lastMousePressPoint : Point = new Point();
    
    /**
     * Create a single entry place where we have cards being dragged into term areas.
     * Hand over control of the dragged card that was removed
     */
    private var m_widgetDragSystem : WidgetDragSystem;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    public function setParams(widgetDragSystem : WidgetDragSystem) : Void
    {
        m_widgetDragSystem = widgetDragSystem;
    }
    
    override public function visit() : Int
    {
        // For each term area check if the mouse hits it
        // We assume that the term areas do not overlap, if the mouse or touch is in
        // one term area it cannot be in another.
        if (m_ready && m_isActive) 
        {
            // Update mouse position in local buffer
            m_globalMousePoint.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            
            // Scale a dragged card if it is over one of the term areas
            if (m_widgetDragSystem.getWidgetSelected() != null && m_mouseState.leftMouseDraggedThisFrame) 
            {
                onDragCardOverTermArea(m_widgetDragSystem.getWidgetSelected(), m_globalMousePoint);
            }  // dispatching events.    // If one of the term areas is underneath another layer it should not be  
            
            
            
            
            
            if (m_termAreas.length > 0 && Layer.getDisplayObjectIsInInactiveLayer(m_termAreas[0])) 
            {
                return ScriptStatus.FAIL;
            }
            
            var termArea : TermAreaWidget = null;
            var i : Int = 0;
            for (i in 0...m_termAreas.length){
                termArea = m_termAreas[i];
                
                var mouseInConstraints : Bool = termArea.containsPoint(m_globalMousePoint);
                if (mouseInConstraints && termArea.isInteractable) 
                {
                    // A click within the term area might mean the player is attempting to drag a card
                    if (m_mouseState.leftMousePressedThisFrame) 
                    {
                        // We are adding the behavior where clicking on a paren will trigger some other action
                        // As a result we may need to separate them into two different events
                        var outParams : Array<Dynamic> = new Array<Dynamic>();
                        termArea.pickParenthesisUnderPoint(m_globalMousePoint.x, m_globalMousePoint.y, outParams);
                        if (outParams.length > 0) 
                        {
                            m_eventDispatcher.dispatchEventWith(GameEvent.PRESS_PARENTHESIS_TERM_AREA, false, {
                                        widget : outParams[0],
                                        termArea : termArea,
                                        left : outParams[1],

                                    });
                        }
                        
                        var pickedWidget : BaseTermWidget = termArea.pickWidgetUnderPoint(
                                m_globalMousePoint.x, m_globalMousePoint.y, true);
                        if (pickedWidget != null) 
                        {
                            m_currentWidgetPressed = pickedWidget;
                            m_termAreaForCurrentWidgetPressed = termArea;
                            m_lastMousePressPoint.setTo(m_globalMousePoint.x, m_globalMousePoint.y);
                            
                            m_eventDispatcher.dispatchEventWith(GameEvent.PRESS_TERM_AREA, false, {
                                        widget : pickedWidget,
                                        termArea : termArea,

                                    });
                        }
                    }
                    else if (m_mouseState.leftMouseDraggedThisFrame && m_currentWidgetPressed != null) 
                    {
                        var dragPixelRadius : Float = 10;
                        if (!MathUtil.pointInCircle(m_lastMousePressPoint, dragPixelRadius, m_globalMousePoint)) 
                        {
                            // Dispatch event that we started a drag on an existing widget
                            m_eventDispatcher.dispatchEventWith(GameEvent.START_DRAG_TERM_AREA, false, {
                                        widget : m_currentWidgetPressed,
                                        termArea : m_termAreaForCurrentWidgetPressed,

                                    });
                            m_termAreaForCurrentWidgetPressed = null;
                            m_currentWidgetPressed = null;
                        }
                    }
                    // Assume term areas don't overlap, if mouse is in one do not process events in the others
                    else if (m_mouseState.leftMouseReleasedThisFrame && m_currentWidgetPressed != null) 
                    {
                        m_eventDispatcher.dispatchEventWith(GameEvent.CLICK_TERM_AREA, false, {
                                    widget : m_currentWidgetPressed,
                                    termArea : termArea,

                                });
                        m_termAreaForCurrentWidgetPressed = null;
                        m_currentWidgetPressed = null;
                    }
                    
                    
                    
                    break;
                }
            }
        }  // come after it.    // Always return fail so a priority selector will always process the nodes that  
        
        
        
        
        
        return ScriptStatus.FAIL;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_widgetDragSystem = try cast(this.getNodeById("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null;
    }
    
    // ??? Maybe this should be moved to it's own script
    private function onDragCardOverTermArea(widget : BaseTermWidget, globalPoint : Point) : Void
    {
        // On dragging a card from the deck we need to make sure it scales properly
        // If the dragged term is inside a term area it needs to scale to the same size
        var amountToScaleTo : Float = 1.0;
        var stage : DisplayObject = widget.stage;
        
        // Use the unscaled bounds of the widget and use that to detect intersection
        // This is to prevent the situation where the scaling oscillates since the unscaled
        // widgets intersect at a certain point but the scaled version does not.
        widget.scaleX = widget.scaleY = 1.0;
        var widgetBounds : Rectangle = widget.getBounds(stage);
        
        var i : Int = 0;
        for (i in 0...m_termAreas.length){
            if (m_termAreas[i].stage != null) 
            {
                var termAreaBounds : Rectangle = m_termAreas[i].getBounds(stage);
                if (termAreaBounds.intersects(widgetBounds)) 
                {
                    amountToScaleTo = m_termAreas[i].getScaleFactor();
                    widget.scaleX = widget.scaleY = amountToScaleTo;
                    break;
                }
            }
        }
    }
}
