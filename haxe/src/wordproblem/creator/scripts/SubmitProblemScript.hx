package wordproblem.creator.scripts;


import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.events.Event;

import wordproblem.creator.EditableTextArea;
import wordproblem.creator.ProblemCreateData;
import wordproblem.creator.ProblemCreateEvent;
import wordproblem.creator.ScrollOptionsPicker;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.creator.WordProblemCreateUtil;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.GameServerRequester;
import wordproblem.resource.AssetManager;

/**
 * TODO: Submit incorrectly is enabled even though not all highlights have been used and when
 * invalid values have been selected for those parts.
 */
class SubmitProblemScript extends BaseProblemCreateScript
{
    private var m_editableTextArea : EditableTextArea;
    
    private var m_submitButtonAnimation : Tween;
    private var m_submitButtonGlow : DisplayObject;
    private var m_submitButtonGlowStartScale : Float;
    private var m_submitButtonGlowAnimation : Tween;
    
    private var m_gameServerRequester : GameServerRequester;
    
    public function new(createState : WordProblemCreateState,
            assetManager : AssetManager,
            gameServerRequester : GameServerRequester,
            id : String = null,
            isActive : Bool = true)
    {
        super(createState, assetManager, id, isActive);
        
        m_gameServerRequester = gameServerRequester;
        
        var targetWidth : Float = 70;
        m_submitButtonGlow = new Image(m_assetManager.getTexture("assets/card/halo.png"));
        m_submitButtonGlow.scaleX = m_submitButtonGlow.scaleY = targetWidth / m_submitButtonGlow.width;
        m_submitButtonGlow.pivotX = m_submitButtonGlow.width * 0.5;
        m_submitButtonGlow.pivotY = m_submitButtonGlow.height * 0.5;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_editableTextArea != null) 
        {
            m_editableTextArea.removeEventListener(ProblemCreateEvent.HIGHLIGHT_REFRESHED, bufferEvent);
            if (value) 
            {
                m_editableTextArea.addEventListener(ProblemCreateEvent.HIGHLIGHT_REFRESHED, bufferEvent);
            }
        }
    }
    
    override public function visit() : Int
    {
        super.visit();
        return ScriptStatus.RUNNING;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        var submitButton : Button = try cast(m_createState.getWidgetFromId("submitButton"), Button) catch(e:Dynamic) null;
        submitButton.addEventListener(starling.events.Event.TRIGGERED, onSubmit);
        submitButton.enabled = false;
        
        // Need to figure out how many parts needed to be tagged in the text area
        // To do this we poll the list of toggle buttons representing each part
        // When does it know when to re-adjust itself, needs to listen to some event
        m_editableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        setIsActive(m_isActive);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == ProblemCreateEvent.HIGHLIGHT_REFRESHED) 
        {
            // HACK: To avoid timing issues, this event needs to be buffered
            // Problem is the script to adjust the toggle buttons relies on this same event
            // The state of the buttons need to have already been changed
            
            // Get all the toggle buttons and see if they are set
            var elementsInModelMap : Dynamic = m_createState.getCurrentLevel().elementIdToDataMap;
            var allPartsHighlighted : Bool = true;
            for (elementId in Reflect.fields(elementsInModelMap))
            {
                var elementData : Dynamic = Reflect.field(elementsInModelMap, elementId);
                if (elementData != null && !elementData.highlighted) 
                {
                    allPartsHighlighted = false;
                    break;
                }
            }
            
            var submitButton : Button = try cast(m_createState.getWidgetFromId("submitButton"), Button) catch(e:Dynamic) null;
            if (allPartsHighlighted && m_submitButtonAnimation == null) 
            {
                /*
                // The glow is slightly off center relative to the 
                var displayIndexOfButton:int = submitButton.parent.getChildIndex(submitButton);
                submitButton.parent.addChildAt(m_submitButtonGlow, Math.max(0, displayIndexOfButton -1));
                m_submitButtonGlow.x = submitButton.x;
                m_submitButtonGlow.y = submitButton.y;
                m_submitButtonGlowAnimation = new Tween(m_submitButtonGlow, 0.8);
                m_submitButtonGlowAnimation.scaleTo(1.1);
                m_submitButtonGlowAnimation.reverse = true;
                m_submitButtonGlowAnimation.repeatCount = 0;
                Starling.juggler.add(m_submitButtonGlowAnimation);
                */
                // Trigger animation of the button glowing and scaled up and down
                m_submitButtonAnimation = new Tween(submitButton, 0.8);
                m_submitButtonAnimation.scaleTo(1.2);
                m_submitButtonAnimation.repeatCount = 0;
                m_submitButtonAnimation.reverse = true;
                Starling.juggler.add(m_submitButtonAnimation);
            }
            else if (!allPartsHighlighted && m_submitButtonAnimation != null) 
            {
                // Disable the animation if it was playing
                stopAnimations();
            }
            submitButton.enabled = allPartsHighlighted;
        }
    }
    
    private function onSubmit() : Void
    {
        // The game needs the level xml to be in a very particular format.
        // We need to walk the xml produced by the textfield and then convert it
        var createLevelData : ProblemCreateData = m_createState.getCurrentLevel();
        var idToAlias : Dynamic = { };
        var saveableText : String = WordProblemCreateUtil.createSaveableXMLFromTextfieldText(m_editableTextArea.getHtmlText(), idToAlias);
        
        // Background id is whatever the currently selected part of the scroller is
        var backgroundPicker : ScrollOptionsPicker = try cast(m_createState.getWidgetFromId("backgroundPicker"), ScrollOptionsPicker) catch(e:Dynamic) null;
        var selectedBackgroundData : Dynamic = backgroundPicker.getCurrentlySelectedOptionData();
        m_gameServerRequester.saveLevel(saveableText, createLevelData.barModelType, selectedBackgroundData.text, onSubmitProblemComplete);
        
        // Kill the animation on the button
        if (m_submitButtonAnimation != null) 
        {
            stopAnimations();
        }
    }
    
    private function onSubmitProblemComplete() : Void
    {
        trace("Problem saved!");
    }
    
    private function stopAnimations() : Void
    {
        Starling.juggler.remove(m_submitButtonAnimation);
        m_submitButtonAnimation = null;
        
        Starling.juggler.remove(m_submitButtonGlowAnimation);
        m_submitButtonGlowAnimation = null;
        
        m_submitButtonGlow.scaleX = m_submitButtonGlow.scaleY = 1.0;
        m_submitButtonGlow.removeFromParent();
    }
}
