package wordproblem.hints.processes;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Button;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.filters.ColorMatrixFilter;

import wordproblem.display.Layer;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

/**
 * For the one of the research experiments we want to show a multiple choice question.
 * The regular character thought bubble should be able 
 */
class DismissQuestionProcess extends ScriptNode
{
    private var m_assetManager : AssetManager;
    private var m_parentStage : Sprite;
    private var m_answerButtons : Array<Button>;
    private var m_potentialAnswers : Array<String>;
    private var m_answerCorrect : Array<Bool>;
    
    // Prevent all mouse interactions on the screen while the question is active
    private var m_blockingLayer : Layer;
    
    private var m_initialized : Bool;
    private var m_correctAnswerSelected : Bool;
    
    // Want to prevent user from selecting a new answer until an animation plays for
    // the last answers they picked.
    private var m_enableAnswerClick : Bool;
    
    public function new(assetManager : AssetManager,
            parentStage : Sprite,
            questionData : Dynamic,
            answerButtons : Array<Button>,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        // Parse the question data
        m_assetManager = assetManager;
        m_parentStage = parentStage;
        m_answerButtons = answerButtons;
        m_potentialAnswers = new Array<String>();
        m_answerCorrect = new Array<Bool>();
        var answers : Array<Dynamic> = questionData.answers;
        for (answer in answers)
        {
            m_potentialAnswers.push(answer.name);
            var correct : Bool = ((answer.exists("correct"))) ? 
            answer.correct : false;
            m_answerCorrect.push(correct);
        }
        
        m_initialized = false;
        m_correctAnswerSelected = false;
        m_blockingLayer = new Layer();
        var blockingQuad : Quad = new Quad(800, 600, 0);
        blockingQuad.alpha = 0.3;
        m_blockingLayer.addChild(blockingQuad);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (value) 
        {
            m_enableAnswerClick = true;
        }
        else if (m_blockingLayer.parent != null) 
        {
            // Remove display objects
            m_blockingLayer.removeFromParent(true);
            for (button in m_answerButtons)
            {
                button.removeEventListener(Event.TRIGGERED, onAnswerClicked);
            }
        }
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.RUNNING;
        if (m_isActive) 
        {
            if (!m_initialized) 
            {
                initializeView();
                m_initialized = true;
            }  // Return success only if they anwer the question correctly  
            
            
            
            if (m_correctAnswerSelected) 
            {
                // Exit condition if they picked the right response
                status = ScriptStatus.SUCCESS;
            }
        }
        
        return status;
    }
    
    private function initializeView() : Void
    {
        // Add the blocking sprite right between the ui components and the layer holding the character.
        m_parentStage.addChildAt(m_blockingLayer, 1);
        
        for (button in m_answerButtons)
        {
            button.addEventListener(Event.TRIGGERED, onAnswerClicked);
        }
    }
    
    private function onAnswerClicked(event : Event) : Void
    {
        if (m_enableAnswerClick) 
        {
            m_enableAnswerClick = false;
        }
        else 
        {
            return;
        }  // On clicking an answer, disable it and show icon whether it was correct  
        
        
        
        var targetButton : Button = try cast(event.target, Button) catch(e:Dynamic) null;
        var answer : String = targetButton.text;
        var indexOfAnswer : Int = Lambda.indexOf(m_potentialAnswers, answer);
        if (indexOfAnswer > -1) 
        {
            var isCorrect : Bool = m_answerCorrect[indexOfAnswer];
            var icon : Image = null;
            if (isCorrect) 
            {
                // Make button look correct (change color to green and add a check)
                icon = new Image(m_assetManager.getTexture("correct"));
            }
            else 
            {
                // Make button look incorrect (change color to red and add an x)
                icon = new Image(m_assetManager.getTexture("wrong"));
            }
            
            icon.pivotX = icon.width * 0.5;
            icon.pivotY = icon.height * 0.5;
            
            targetButton.enabled = false;
            
            var finalIconScale : Float = Math.min(targetButton.width, targetButton.height) / icon.width;
            icon.scaleX = icon.scaleY = 2;
            icon.x = targetButton.x + targetButton.width * 0.5;
            icon.y = targetButton.y + targetButton.height * 0.5;
            icon.alpha = 0.0;
            targetButton.parent.addChild(icon);
            
            var tween : Tween = new Tween(icon, 1);
            tween.fadeTo(1.0);
            tween.scaleTo(finalIconScale);
            // If correct answer selected have a short delay before it is dismissed
            tween.onComplete = function() : Void
                    {
                        var greyScaleFilter : ColorMatrixFilter = new ColorMatrixFilter();
                        greyScaleFilter.adjustSaturation(-1);
                        targetButton.filter = greyScaleFilter;
                        m_correctAnswerSelected = isCorrect;
                        m_enableAnswerClick = true;
                    };
            Starling.current.juggler.add(tween);
        }
    }
}
