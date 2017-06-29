package wordproblem.scripts.expressionpicking;


import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import feathers.controls.Button;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.events.Event;
import starling.textures.Texture;
import wordproblem.resource.AssetManager;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.widget.ExpressionContainer;
import wordproblem.engine.widget.ExpressionPickerWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.scripts.BaseGameScript;

/**
 * This script handles checking whether the the items in an expression picker are correct.
 * This handles performing the animation to give feedback to the player's as well.
 */
class ExpressionPickerCheck extends BaseGameScript
{
    private var m_modelEquationButton : Button;
    private var m_pickerIds : Array<String>;
    private var m_expressions : Array<String>;
    
    private var m_successCallback : Function;
    private var m_failCallback : Function;
    
    /**
     * While animation for correctness is playing do not make picker interactable
     * nor accept any more submits
     */
    private var m_numAnimationsPlaying : Int;
    
    /**
     * For each click of the submit button, we hold onto whether all expressions were satisfied for that click.
     * This is to remember the result across multiple frames because of possible animations.
     */
    private var m_allExpressionsSatisfied : Bool;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            successCallback : Function,
            failCallback : Function,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_successCallback = successCallback;
        m_failCallback = failCallback;
        m_pickerIds = new Array<String>();
        m_expressions = new Array<String>();
        m_numAnimationsPlaying = 0;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_modelEquationButton.removeEventListener(Event.TRIGGERED, onModelSelected);
    }
    
    override private function onLevelReady() : Void
    {
        // Get the model button and check whenever it is selected
        m_modelEquationButton = try cast(m_gameEngine.getUiEntity("modelEquationButton"), Button) catch(e:Dynamic) null;
        m_modelEquationButton.addEventListener(Event.TRIGGERED, onModelSelected);
    }
    
    /**
     * Unlike other scripts, we need to define what values we should be checking each picker
     * against
     * 
     * @param pickerIds
     *      The ids of the picker widgets
     * @param expressions
     *      The expressions each of the picker widgets should take
     */
    public function setTargetExpressionsForPickers(pickerIds : Array<String>,
            expressions : Array<String>) : Void
    {
        as3hx.Compat.setArrayLength(m_pickerIds, 0);
        as3hx.Compat.setArrayLength(m_expressions, 0);
        
        var i : Int;
        var numPickers : Int = pickerIds.length;
        for (i in 0...numPickers){
            m_pickerIds.push(pickerIds[i]);
            m_expressions.push(expressions[i]);
        }
    }
    
    private function onModelSelected() : Void
    {
        if (m_numAnimationsPlaying == 0) 
        {
            m_allExpressionsSatisfied = true;
            var outSelectedExpressionContainers : Array<ExpressionContainer> = new Array<ExpressionContainer>();
            var i : Int;
            var numPickerIds : Int = m_pickerIds.length;
            for (i in 0...numPickerIds){
                var expressionPickerWidget : ExpressionPickerWidget = try cast(m_gameEngine.getUiEntity(m_pickerIds[i]), ExpressionPickerWidget) catch(e:Dynamic) null;
                as3hx.Compat.setArrayLength(outSelectedExpressionContainers, 0);
                expressionPickerWidget.getSelectedExpressionContainers(outSelectedExpressionContainers);
                if (outSelectedExpressionContainers.length > 0) 
                {
                    // Grey out all the options that weren't selected. Then draw either a check mark
                    // or an x on the option depending if it was correct or incorrect
                    expressionPickerWidget.setGrayScaleToUnselected();
                    
                    // At this point we assume only one correct option can be selected
                    var targetExpression : String = m_expressions[i];
                    var selectedContainer : ExpressionContainer = outSelectedExpressionContainers[0];
                    if (selectedContainer.getExpressionComponent().expressionString == targetExpression) 
                    {
                        // This answer in this picker is correct
                        animate(true, selectedContainer);
                        expressionPickerWidget.isActive = false;
                    }
                    else if (targetExpression == null) 
                    {
                        // (NOTE: Do not play correct/incorrect animation for situations
                        // where any answer is acceptable since that has no concept of correctness)
                        
                    }
                    else 
                    {
                        m_allExpressionsSatisfied = false;
                        animate(false, selectedContainer);
                        expressionPickerWidget.isActive = false;
                    }
                }
                else 
                {
                    // Case where nothing was selected
                    m_allExpressionsSatisfied = false;
                }
            }
            
            var audioName : String = ((m_allExpressionsSatisfied)) ? "expression_option_success" : "wrong";
            Audio.instance.playSfx(audioName);
            
            var eventType : String = ((m_allExpressionsSatisfied)) ? 
            GameEvent.EXPRESSION_PICKER_CORRECT : GameEvent.EXPRESSION_PICKER_INCORRECT;
            m_gameEngine.dispatchEventWith(eventType);
            
            // If no animations are playing we can immediately fire events
            checkAnimationCompleteAndFireCallback();
        }
    }
    
    private function checkAnimationCompleteAndFireCallback() : Void
    {
        if (m_numAnimationsPlaying == 0) 
        {
            // Dispatch event depending on whether the picked answers were correct or incorrrect
            var loggingDetails : Dynamic;
            if (m_allExpressionsSatisfied) 
            {
                m_successCallback();
                
                //log the event
                loggingDetails = {
                            buttonName : "Is",
                            success : true,

                        };
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EQUALS_CLICKED_EVENT, false, loggingDetails);
            }
            else 
            {
                m_failCallback();
                
                //log the event
                loggingDetails = {
                            buttonName : "Is",
                            success : false,

                        };
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EQUALS_CLICKED_EVENT, false, loggingDetails);
            }
            
            var i : Int;
            var numPickerIds : Int = m_pickerIds.length;
            for (i in 0...numPickerIds){
                var expressionPickerWidget : ExpressionPickerWidget = try cast(m_gameEngine.getUiEntity(m_pickerIds[i]), ExpressionPickerWidget) catch(e:Dynamic) null;
                expressionPickerWidget.resetColors();
                expressionPickerWidget.isActive = true;
            }
        }
    }
    
    private function animate(correct : Bool,
            container : DisplayObjectContainer) : Void
    {
        m_numAnimationsPlaying++;
        
        var iconTextureName : String = ((correct)) ? "correct" : "wrong";
        var iconTexture : Texture = m_assetManager.getTexture(iconTextureName);
        var icon : DisplayObject = new Image(iconTexture);
        icon.pivotX = iconTexture.width * 0.5;
        icon.pivotY = iconTexture.height * 0.5;
        icon.alpha = 0.0;
        
        var endScale : Float = 2 * (container.height / icon.height);
        var startScale : Float = endScale * 5.0;
        icon.scaleX = icon.scaleY = startScale;
        icon.y = container.height * 0.5;
        icon.x = icon.pivotX;
        container.addChild(icon);
        
        // Animation is a string of tweens.
        // First show the icon popping in next to the selected answer
        // Wait for a short time
        // Then fade out and remove the icon
        var iconShowTween : Tween = new Tween(icon, 0.6, Transitions.EASE_IN);
        iconShowTween.animate("scaleX", endScale);
        iconShowTween.animate("scaleY", endScale);
        iconShowTween.animate("alpha", 1.0);
        iconShowTween.onComplete = function onShowComplete(tween : Tween) : Void
                {
                    Starling.juggler.remove(tween);
                    
                    var iconHideTween : Tween = new Tween(icon, 0.6, Transitions.EASE_OUT);
                    iconHideTween.animate("alpha", 0);
                    iconHideTween.delay = 0.8;
                    iconHideTween.onComplete = tweenComplete;
                    iconHideTween.onCompleteArgs = [iconHideTween];
                    Starling.juggler.add(iconHideTween);
                };
        
        iconShowTween.onCompleteArgs = [iconShowTween];
        Starling.juggler.add(iconShowTween);
    }
    
    private function tweenComplete(tween : Tween) : Void
    {
        (try cast(tween.target, DisplayObject) catch(e:Dynamic) null).removeFromParent(true);
        
        Starling.juggler.remove(tween);
        m_numAnimationsPlaying--;
        checkAnimationCompleteAndFireCallback();
    }
}
