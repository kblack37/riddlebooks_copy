package wordproblem.scripts.text;


import flash.geom.Point;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.ui.MouseState;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.text.view.TextView;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * Script that handles detecting mouse presses on the text and dispatching selection events.
 */
class DragText extends BaseGameScript
{
    /**
     * Reference to the text area so we can detect mouse events on it
     */
    private var m_textAreaWidget : TextAreaWidget;
    
    /**
     * Global coordinates of the mouse
     */
    private var m_mousePoint : Point = new Point();
    
    /**
     * A temp variable that remember the last view that was pressed down on.
     * Is unset as soon as the mouse is released or a drag is started
     */
    private var m_viewPressedDownOn : DocumentView;
    
    /**
     * A temp variable to remember the last point that was pressed down on.
     */
    private var m_lastMouseDownPoint : Point;
    
    /**
     * The document view that was pressed or dragged
     */
    private var m_viewUnderMouse : DocumentView;
    
    public function new(gameEngine : IGameEngine,
            compiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String,
            isActive : Bool = true)
    {
        super(gameEngine, compiler, assetManager, id, isActive);
    }
    
    override public function visit() : Int
    {
        if (this.m_ready && this.m_isActive) 
        {
            // The dragging of existing items and their release does not care about the layering
            // deactivation.
            var params : Dynamic = null;
            var mouseState : MouseState = this.m_gameEngine.getMouseState();
            m_mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            if (mouseState.leftMouseDraggedThisFrame && m_viewPressedDownOn != null) 
            {
                // Check if we have exceeded some drag radius threshold
                var startDrag : Bool = !MathUtil.pointInCircle(m_lastMouseDownPoint, 5, m_mousePoint);
                if (startDrag) 
                {
                    this.m_gameEngine.dispatchEventWith(GameEvent.START_DRAG_TEXT_AREA, false, {
                                documentView : m_viewPressedDownOn,
                                location : m_mousePoint.clone(),
                            });
                    m_viewPressedDownOn = null;
                }
            }
            // Kill the mouse detection is text area is blocked
            else if (mouseState.leftMouseReleasedThisFrame) 
            {
                // TODO: This had a guard that there was a valid view underneath the mouse
                // this is was to prevent a mouse release over a text area from always firing an event
                if (m_viewUnderMouse != null) 
                {
                    var renderComponentUnderMouse : RenderableComponent = m_gameEngine.getUiEntityUnder(m_mousePoint);
                    var uiComponentName : String = null;
                    if (renderComponentUnderMouse != null) 
                    {
                        uiComponentName = renderComponentUnderMouse.entityId;
                    }
					
					// Log the phrase drop  
					// Note: We want to make sure to log the drop before we actually execute the drop in the code, so that any additional logs that occur
                    // (ie. expression found) come strictly after the drop in the logs.
                    var text : String = ((Std.is(m_viewUnderMouse, TextView))) ? (try cast(m_viewUnderMouse, TextView) catch(e:Dynamic) null).getTextField().text : "";
                    var expressionUnder : Array<Dynamic> = viewContainsExpressionThatHasBeenModeled(m_viewUnderMouse);
                    var dropIsAnExpression : Bool = expressionUnder != null;
                    
                    var loggingDetails_drop : Dynamic = {
                        rawText : text,
                        isExpression : dropIsAnExpression,
                        regionDropped : uiComponentName,
                        locationX : m_mousePoint.x,
                        locationY : m_mousePoint.y,
                    };
                    if (dropIsAnExpression) 
                    {
                        Reflect.setField(loggingDetails_drop, "expressionName", expressionUnder[0]);
                        Reflect.setField(loggingDetails_drop, "hasBeenModeled", expressionUnder[1]);
                    }
                    m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.PHRASE_DROP_EVENT, false, loggingDetails_drop);
                    
                    // Release the phrase
                    params = {
                                view : m_viewUnderMouse,
                                isExpression : dropIsAnExpression,
                                regionDropped : uiComponentName,
                                location : m_mousePoint,
                            };
                    m_gameEngine.dispatchEventWith(GameEvent.RELEASE_TEXT_AREA, false, params);
                }
                
                m_viewPressedDownOn = null;
                m_viewUnderMouse = null;
            }
            
            
            
            if (Layer.getDisplayObjectIsInInactiveLayer(m_textAreaWidget)) 
            {
                return ScriptStatus.FAIL;
            }  
			
			// Need to check that we are within the bounding of this mask  
            if (mouseState.leftMousePressedThisFrame) 
            {
                // The hit test should return the document view furthest down in the tree structure.
                var hitView : DocumentView = m_textAreaWidget.hitTestDocumentView(m_mousePoint);
                if (hitView != null) 
                {
                    m_lastMouseDownPoint = m_mousePoint.clone();
                    m_viewPressedDownOn = hitView;
                    m_viewUnderMouse = hitView;
                }
                
                if (m_viewPressedDownOn != null) 
                {
                    // Press the phrase
                    var expressionPressed : Array<Dynamic> = viewContainsExpressionThatHasBeenModeled(m_viewPressedDownOn);
                    var pickupIsAnExpression : Bool = expressionPressed != null;
                    params = {
                                view : m_viewPressedDownOn,
                                isExpression : ((expressionPressed != null)) ? true : false,
                            };
                    this.m_gameEngine.dispatchEventWith(GameEvent.PRESS_TEXT_AREA, false, params);
                    
                    if (Std.is(m_viewPressedDownOn, TextView)) 
                    {
                        // Log the phrase pickup
                        var loggingDetails_pickup : Dynamic = {
                            rawText : (try cast(m_viewPressedDownOn, TextView) catch(e:Dynamic) null).getTextField().text,
                            isExpression : pickupIsAnExpression,
                            locationX : m_mousePoint.x,
                            locationY : m_mousePoint.y,
                        };
                        if (pickupIsAnExpression) 
                        {
                            Reflect.setField(loggingDetails_pickup, "expressionName", expressionPressed);
                        }
                        
                        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.PHRASE_PICKUP_EVENT, false, loggingDetails_pickup);
                    }
                }
            }
        }
        
        return ScriptStatus.FAIL;
    }
    
    /** 
     * Rather than return a Boolean as the name might imply, return an Array including the expressionString of the term widget found and whether it has been found yet.
     * or null view is not an expression
     */
    private function viewContainsExpressionThatHasBeenModeled(aView : DocumentView) : Array<Dynamic>
    {
        var result : Array<Dynamic> = null;
        var textComponentManager : ComponentManager = m_textAreaWidget.componentManager;
        var components : Array<Component> = textComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var numComponents : Int = components.length;
        for (i in 0...numComponents){
            var expressionComponent : ExpressionComponent = try cast(components[i], ExpressionComponent) catch(e:Dynamic) null;
            var documentIdBoundToExpression : String = expressionComponent.entityId;
            if (m_textAreaWidget.getViewIsInContainer(aView, documentIdBoundToExpression)) {
                var deckComponentManager : ComponentManager = (try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null).componentManager;
                var deckcomponents : Array<Component> = deckComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                var numDeckComponents : Int = deckcomponents.length;
                var hasBeenModeled : Bool = false;
                for (j in 0...numDeckComponents){
                    var deckComponent : ExpressionComponent = try cast(deckcomponents[j], ExpressionComponent) catch(e:Dynamic) null;
                    var deckIdBoundToExpression : String = deckComponent.entityId;
                    if (expressionComponent.expressionString == deckComponent.expressionString) {
                        hasBeenModeled = deckComponent.hasBeenModeled;
                    }
                }
                result = [expressionComponent.expressionString, hasBeenModeled];
                break;
            }
        }
        return result;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        m_textAreaWidget = try cast(this.m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
    }
}
