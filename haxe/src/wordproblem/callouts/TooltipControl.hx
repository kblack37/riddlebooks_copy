package wordproblem.callouts;


import flash.geom.Rectangle;
import flash.text.TextFormat;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.ui.MouseState;

import starling.display.DisplayObject;
import starling.text.TextField;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.text.GameFonts;

/**
 * Class contains basic logic to get a tooltip to appear over a ui part on mouse hover
 * over and remove on hover out
 */
class TooltipControl implements IDisposable
{
    public var textWidth : Float = 80;
    public var textHeight : Float = 40;
    
    private var m_gameEngine : IGameEngine;
    
    /**
     * The entity id of the ui component (requires the display object to have been created
     * in the xml like widget layout)
     */
    private var m_uiEntityId : String;
    
    /**
     * The text content of the tooltip
     */
    private var m_toolTipText : String;
    
    /**
     * A buffer storing the bounds of the object
     */
    private var m_displayHitArea : Rectangle;
    
    /**
     * The display object to have the tool tip attached to it.
     */
    private var m_objectToGetTooltip : DisplayObject;
    
    /**
     * Properties of how the text in the tooltip is styled.
     */
    private var m_textStyle : TextFormat;
    
    /**
     * A limitation of the Starling callout system we are using is only one callout can be bound
     * to a display object at any single time. This is a problem if another script, like a tutorial,
     * binds a callout to the object the control is also bound to. The other script takes
     * priority and we do not try to overwrite that callout.
     * 
     * This flag helps this control know when it has instantiated a callout, it will only remove callouts
     * it knows it has created.
     */
    private var m_thisControlCreatedCallout : Bool;
    
    public function new(gameEngine : IGameEngine,
            uiEntityId : String,
            text : String,
            fontName : String = "Verdana",
            fontSize : Int = 18,
            fontColor : Int = 0xFFFFFF)
    {
        
        m_gameEngine = gameEngine;
        m_uiEntityId = uiEntityId;
        m_toolTipText = text;
        m_textStyle = new TextFormat(fontName, fontSize, fontColor);
        
        m_objectToGetTooltip = m_gameEngine.getUiEntity(m_uiEntityId);
        m_displayHitArea = new Rectangle();
        m_thisControlCreatedCallout = false;
    }
    
    /**
     * Reset the text for the tooltip
     */
    public function setText(value : String) : Void
    {
        m_toolTipText = value;
    }
    
    public function onEnterFrame() : Void
    {
        // If the entity to attach a tool tip to doesn't exist or is not part
        // of the display tree, this function should have no effect.
        if (m_objectToGetTooltip == null || m_objectToGetTooltip.stage == null) 
        {
            return;
        }
        
        var mouseState : MouseState = m_gameEngine.getMouseState();
        m_objectToGetTooltip.getBounds(m_objectToGetTooltip.stage, m_displayHitArea);
        
        // If tooltip is visible and mouse is not in bounds then remove it
        // If the tooltip is not visible and mouse is in the bounds then add it
        // Other cases do not do anything
        var uiComponentManager : ComponentManager = m_gameEngine.getUiComponentManager();
        var calloutComponent : Component = uiComponentManager.getComponentFromEntityIdAndType(m_uiEntityId, CalloutComponent.TYPE_ID);
        if (m_displayHitArea.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y)) 
        {
            // Only add callout if not already there and a layer is not ontop of it
            if (calloutComponent == null && !Layer.getDisplayObjectIsInInactiveLayer(m_objectToGetTooltip) && m_objectToGetTooltip.visible) 
            {
                var newCalloutComponent : CalloutComponent = new CalloutComponent(m_uiEntityId);
                newCalloutComponent.display = new TextField(Std.int(textWidth), Std.int(textHeight), m_toolTipText, 
                        m_textStyle.font, m_textStyle.size, try cast(m_textStyle.color, Int) catch(e:Dynamic) null);
                newCalloutComponent.backgroundTexture = "button_white";
                newCalloutComponent.arrowTexture = "";
                newCalloutComponent.backgroundColor = 0x000000;
                
                // Have callout point down if the ui is too far up
				// TODO: replaced Callout.DIRECTION_DOWN and Callout.DIRECTION_UP with dummy values
				// since the feathers callout library is not used anymore
                newCalloutComponent.directionFromOrigin = ((m_displayHitArea.y < 100)) ? "down" : "up";
                uiComponentManager.addComponentToEntity(newCalloutComponent);
                
                m_thisControlCreatedCallout = true;
            }
			
			// Update callout display if text changed  
            if (calloutComponent != null && m_thisControlCreatedCallout) 
            {
                var currentText : TextField = try cast((try cast(calloutComponent, CalloutComponent) catch(e:Dynamic) null).display, TextField) catch(e:Dynamic) null;
                if (currentText.text != m_toolTipText) 
                {
                    currentText.text = m_toolTipText;
                }
            }
        }
        else 
        {
            if (calloutComponent != null && m_thisControlCreatedCallout) 
            {
                uiComponentManager.removeComponentFromEntity(m_uiEntityId, CalloutComponent.TYPE_ID);
                m_thisControlCreatedCallout = false;
            }
        }
    }
    
    public function dispose() : Void
    {
        // Kill the active callout if it exists
        if (m_thisControlCreatedCallout) 
        {
            var uiComponentManager : ComponentManager = m_gameEngine.getUiComponentManager();
            uiComponentManager.removeComponentFromEntity(m_uiEntityId, CalloutComponent.TYPE_ID);
            m_thisControlCreatedCallout = false;
        }
    }
}
