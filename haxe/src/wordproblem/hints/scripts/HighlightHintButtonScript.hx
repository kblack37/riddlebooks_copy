package wordproblem.hints.scripts;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.time.Time;

import feathers.controls.Callout;

import starling.display.DisplayObject;

import wordproblem.callouts.CalloutCreator;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * This script handles highlighting the hint button if we notice the player is
 * struggling with this problem.
 * 
 * We interpret struggling as:
 * Not performing any action for x number of seconds
 * Not submitting an answer for x number of seconds
 * Submitting a wrong answer x number of times
 * 
 * The thresholds for these may depend on the level.
 * We only need to show this once per level as hopefully once they see it once
 * they can now remember where to get hints from.
 */
class HighlightHintButtonScript extends BaseGameScript
{
    /**
     * This object is updated outside this script, we just keep a 
     */
    private var m_time : Time;
    
    /**
     * Use this for consistent logic for creating new callout components
     */
    private var m_calloutCreator : CalloutCreator;
    
    /**
     * Need this so we can easily tell if a hint is active, if it is then we need to make sure we do
     * not attempt to show the highlight again.
     */
    private var m_helpController : HelpController;
    
    /**
     * The flag disables the script from continuing the check to show the highlight.
     * The reason for this is that if it is shown once in a level it might be unnecessary and
     * annoying to show it multiple times afterwards.
     * 
     * (If we don't want this behavior then we would need to restart the counter
     * once the hint screen closes)
     */
    private var m_continueCheckingTriggers : Bool;
    
    /**
     * If the player passes this threshold of seconds between the submission of an answer
     * we assume they are confused.
     */
    private var m_secondsBetweenAnswerSubmit : Float = 180;
    private var m_secondsBetweenAnswerSubmitCounter : Float;
    
    /**
     * If the player passes this threshold of seconds between performing a modification
     * to either the bar model or the expression we assume they are confused.
     */
    private var m_secondsBetweenModification : Float = 90;
    private var m_secondsBetweenModificationCounter : Float;
    
    /**
     * If the player passes this threshold of incorrect submission we assume they are confused.
     * The submission can occur in the bar model or the equation.
     */
    private var m_numberIncorrectSubmission : Int = 3;
    private var m_numberIncorrectSubmissionCounter : Int;
    
    private var m_localPointBuffer : Point;
    private var m_globalPointBuffer : Point;
    private var m_calloutBoundsBuffer : Rectangle;
    private var m_screenBounds : Rectangle;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            helpController : HelpController,
            time : Time,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_helpController = helpController;
        m_time = time;
        m_localPointBuffer = new Point(0, 0);
        m_globalPointBuffer = new Point();
        m_calloutBoundsBuffer = new Rectangle();
        m_screenBounds = new Rectangle(0, 0, 800, 600);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            m_gameEngine.removeEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_FAIL, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_CHANGED, bufferEvent);
            if (value) 
            {
                m_gameEngine.addEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
                m_gameEngine.addEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, bufferEvent);
                m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
                m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
                m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_FAIL, bufferEvent);
                m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
                m_gameEngine.addEventListener(GameEvent.EQUATION_CHANGED, bufferEvent);
            }
            else 
            {
                // Clear out the components on the button if they exist
                removeHighlightFromButton();
            }
        }
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            // Iterate through the buffered events
            super.visit();
            
            // On update will need to check if enough time has elapsed to fire one of
            // the time based triggers
            if (m_continueCheckingTriggers) 
            {
                var secondsElapsed : Float = m_time.frameDeltaSecs();
                
                // Ignore time lapse and reset timers if any hint is actively being shown
                if (m_helpController.getCurrentlyShownHint() != null) 
                {
                    m_secondsBetweenAnswerSubmitCounter = 0;
                    m_secondsBetweenModificationCounter = 0;
                }
                else 
                {
                    // Ignore time elapse in the edge case where the hint button is not visible (i.e. is it outside the view bounds
                    var hintButton : DisplayObject = m_gameEngine.getUiEntity("hintButton");
                    hintButton.localToGlobal(m_localPointBuffer, m_globalPointBuffer);
                    if (m_globalPointBuffer.y <= m_screenBounds.bottom && m_globalPointBuffer.y >= m_screenBounds.top &&
                        m_globalPointBuffer.x >= m_screenBounds.left && m_globalPointBuffer.x <= m_screenBounds.right) 
                    {
                        m_secondsBetweenAnswerSubmitCounter += secondsElapsed;
                        m_secondsBetweenModificationCounter += secondsElapsed;
                    }
                }  // Once any trigger has been fired at least once do not fire it again  
                
                
                
                if (m_secondsBetweenAnswerSubmitCounter >= m_secondsBetweenAnswerSubmit) 
                {
                    addHighlightToButton();
                    m_continueCheckingTriggers = false;
                }
                else if (m_secondsBetweenModificationCounter >= m_secondsBetweenModification) 
                {
                    addHighlightToButton();
                    m_continueCheckingTriggers = false;
                }
                // TODO: The continuous submission of an incorrect answer would strongly indicate that a user still
                // needs help. Perhaps the highlight would still be useful in just this case
                else if (m_numberIncorrectSubmissionCounter >= m_numberIncorrectSubmission) 
                {
                    addHighlightToButton();
                    m_continueCheckingTriggers = false;
                }
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_secondsBetweenAnswerSubmitCounter = 0;
        m_secondsBetweenModificationCounter = 0;
        m_numberIncorrectSubmissionCounter = 0;
        m_continueCheckingTriggers = true;
        
        m_calloutCreator = new CalloutCreator(new TextParser(), new TextViewFactory(m_assetManager, m_gameEngine.getExpressionSymbolResources()));
        
        setIsActive(m_isActive);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.HINT_BUTTON_SELECTED) 
        {
            // Once the hint button is selected once we just terminate all further checks
            // for this level, also remove the highlighting
            removeHighlightFromButton();
            m_continueCheckingTriggers = false;
        }
        // On any change reset the counter on performing an action
        else if (eventType == GameEvent.BAR_MODEL_AREA_CHANGE || eventType == GameEvent.EQUATION_CHANGED) 
        {
            m_secondsBetweenModificationCounter = 0;
        }
        else if (eventType == GameEvent.BAR_MODEL_CORRECT || eventType == GameEvent.EQUATION_MODEL_SUCCESS) 
        {
            m_secondsBetweenAnswerSubmitCounter = 0;
            m_secondsBetweenModificationCounter = 0;
            m_numberIncorrectSubmissionCounter = 0;
        }
        else if (eventType == GameEvent.BAR_MODEL_INCORRECT || eventType == GameEvent.EQUATION_MODEL_FAIL) 
        {
            m_secondsBetweenAnswerSubmitCounter = 0;
            m_numberIncorrectSubmissionCounter++;
        }
    }
    
    private function addHighlightToButton() : Void
    {
        // The highlighting of the hint button can just be a basic callout box
        var calloutHeight : Int = 50;
        var globalHintBounds : Rectangle = m_gameEngine.getUiEntity("hintButton").getBounds(m_gameEngine.getSprite());
        var calloutOrientation : String = ((globalHintBounds.y > calloutHeight * 2)) ? 
        Callout.DIRECTION_UP : Callout.DIRECTION_DOWN;
        
        // Player can dismiss the callout by clicking on the text bubble
        // (necessary since the tool tip will annoyingly obscure the text sometimes)
        var uiComponentManager : ComponentManager = m_gameEngine.getUiComponentManager();
        uiComponentManager.addComponentToEntity(m_calloutCreator.createCalloutComponentFromText({
                            id : "hintButton",
                            text : "Get Help",
                            color : 0xFFFFFF,
                            direction : calloutOrientation,
                            width : 100,
                            height : calloutHeight,
                            animationPeriod : 1,
                            closeOnTouchInside : true,
                            closeCallback : removeHighlightFromButton,

                        }));
        uiComponentManager.addComponentToEntity(new HighlightComponent("hintButton", 0x00FF00, 1));
        
        // Log that the highlight prompt is showing
        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.HINT_BUTTON_HIGHLIGHTED);
    }
    
    private function removeHighlightFromButton() : Void
    {
        var uiComponentManager : ComponentManager = m_gameEngine.getUiComponentManager();
        uiComponentManager.removeComponentFromEntity("hintButton", CalloutComponent.TYPE_ID);
        uiComponentManager.removeComponentFromEntity("hintButton", HighlightComponent.TYPE_ID);
    }
}
