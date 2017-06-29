package wordproblem.hints.processes;


import flash.geom.Point;

import dragonbox.common.ui.MouseState;

import starling.display.DisplayObject;
import starling.events.Event;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;

class DismissCharacterOnClickProcess extends ScriptNode
{
    private var m_characterController : HelperCharacterController;
    private var m_characterId : String;
    private var m_mouseState : MouseState;
    private var m_globalMouseBuffer : Point;
    private var m_localMouseBuffer : Point;
    
    /**
     * Keep track if the last user press was in the bounds of the character
     */
    private var m_userPressedOnCharacter : Bool;
    
    /**
     * If true, then at the starting stages this script is running we will temporarily ignore the behave that
     * mouse out of the character or callout area makes it transparent.
     * 
     * The reason is that we want the callout (the hint content) to always be visible at the onset so the user
     * can more readily see an important help message has popped up.
     */
    private var m_persistentCalloutOpacity : Bool;
    private var m_mouseInCalloutBoundsLastFrame : Bool;
    
    private var m_extraButtonOnCallout : DisplayObject;
    private var m_extraButtonClickCallback : Function;
    
    // For some reason the character callout appears at the top left of the screen at the start.
    // This causes this hit to be immediately triggered.
    // The 'ghost' of the callout appearing at 0, 0 at the start seems to baked in behavior.
    // A simple hacky solution would be to have this script wait for a few frames before detecting hits.
    // This allows some time for the callout to be positioned to the right place
    private var m_frameDelayCounter : Int;
    
    public function new(characterAndCalloutControl : HelperCharacterController,
            characterId : String,
            mouseState : MouseState,
            extraButtonOnCallout : DisplayObject,
            extraButtonClickCallback : Function,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_characterController = characterAndCalloutControl;
        m_characterId = characterId;
        m_mouseState = mouseState;
        m_globalMouseBuffer = new Point();
        m_localMouseBuffer = new Point();
        m_persistentCalloutOpacity = true;
        m_mouseInCalloutBoundsLastFrame = false;
        m_frameDelayCounter = 0;
        
        if (extraButtonOnCallout != null) 
        {
            m_extraButtonOnCallout = extraButtonOnCallout;
            m_extraButtonClickCallback = extraButtonClickCallback;
            
            m_extraButtonOnCallout.addEventListener(Event.TRIGGERED, m_extraButtonClickCallback);
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        if (m_extraButtonOnCallout != null) 
        {
            m_extraButtonOnCallout.removeEventListener(Event.TRIGGERED, m_extraButtonClickCallback);
        }
    }
    
    override public function visit() : Int
    {
        // Return fail after the player clicked on either the character or the callout on this frame
        // This will trigger the next script in the sequence
        var status : Int = ScriptStatus.RUNNING;
        
        if (m_frameDelayCounter < 3) 
        {
            m_frameDelayCounter++;
        }
        else 
        {
            // HACK: Adding default behavior of the mouse over and out affecting the transparency of the callout
            var mouseHitCharacterOnFrame : Bool = this.getGlobalPointHitCharacterOrCallout(
                    m_characterId,
                    m_mouseState.mousePositionThisFrame.x,
                    m_mouseState.mousePositionThisFrame.y
                    );
            
            // This is a mouse out of the callout bounds
            if (!mouseHitCharacterOnFrame && m_mouseInCalloutBoundsLastFrame) 
            {
                // The first mouse out turns off the persistent opacity
                m_persistentCalloutOpacity = false;
            }
            m_mouseInCalloutBoundsLastFrame = mouseHitCharacterOnFrame;
            
            if (!m_persistentCalloutOpacity) 
            {
                var characterComponentManager : ComponentManager = m_characterController.getComponentManager();
                var calloutComponents : Array<Component> = characterComponentManager.getComponentListForType(CalloutComponent.TYPE_ID);
                var i : Int;
                var hitCallout : Bool = false;
                var numCallouts : Int = calloutComponents.length;
                for (i in 0...numCallouts){
                    var calloutComponent : CalloutComponent = try cast(calloutComponents[i], CalloutComponent) catch(e:Dynamic) null;
                    if (calloutComponent.callout != null) 
                    {
                        calloutComponent.callout.alpha = ((mouseHitCharacterOnFrame)) ? 1.0 : 0.2;
                    }
                }
            }  // On click of character schedule the action that dismisses the it  
            
            
            
            var shouldDismissOnFrame : Bool = false;
            if (m_mouseState.leftMousePressedThisFrame) 
            {
                m_userPressedOnCharacter = mouseHitCharacterOnFrame;
            }
            else if (m_mouseState.leftMouseReleasedThisFrame) 
            {
                shouldDismissOnFrame = m_userPressedOnCharacter && mouseHitCharacterOnFrame;
                m_userPressedOnCharacter = false;
            }
            
            if (shouldDismissOnFrame) 
            {
                status = ScriptStatus.SUCCESS;
            }
        }
        
        return status;
    }
    
    private function getGlobalPointHitCharacterOrCallout(characterId : String,
            globalX : Float,
            globalY : Float) : Bool
    {
        var characterComponentManager : ComponentManager = m_characterController.getComponentManager();
        var calloutComponents : Array<Component> = characterComponentManager.getComponentListForType(CalloutComponent.TYPE_ID);
        var i : Int;
        var hitCallout : Bool = false;
        var numCallouts : Int = calloutComponents.length;
        for (i in 0...numCallouts){
            var calloutComponent : CalloutComponent = try cast(calloutComponents[i], CalloutComponent) catch(e:Dynamic) null;
            m_globalMouseBuffer.x = globalX;
            m_globalMouseBuffer.y = globalY;
            
            // Extra guard where character is visible but the callout has not been created yet
            if (calloutComponent.callout != null && calloutComponent.entityId == characterId) 
            {
                calloutComponent.callout.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                if (!calloutComponent.callout.hitTest(m_localMouseBuffer)) 
                {
                    var characterView : DisplayObject = (try cast(characterComponentManager.getComponentFromEntityIdAndType(characterId, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null).view;
                    characterView.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                    if (characterView.hitTest(m_localMouseBuffer) != null) 
                    {
                        hitCallout = true;
                        break;
                    }
                }
                else 
                {
                    hitCallout = true;
                    break;
                }
            }
        }
        
        return hitCallout;
    }
}
