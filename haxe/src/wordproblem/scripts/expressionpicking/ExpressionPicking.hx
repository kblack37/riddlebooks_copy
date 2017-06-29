package wordproblem.scripts.expressionpicking;


import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import starling.display.DisplayObject;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.ExpressionContainer;
import wordproblem.engine.widget.ExpressionPickerWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

class ExpressionPicking extends BaseGameScript
{
    private var m_expressionPickers : Array<ExpressionPickerWidget>;
    
    private var m_lastPickerHit : ExpressionPickerWidget;
    private var m_lastPickedContainerInFrame : ExpressionContainer;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    override public function visit() : Int
    {
        if (m_isActive && m_ready) 
        {
            // Picker should not do anything if its parent layer not active
            if (m_expressionPickers.length > 0 && Layer.getDisplayObjectIsInInactiveLayer(m_expressionPickers[0])) 
            {
                return ScriptStatus.FAIL;
            }
            
            var mouseState : MouseState = m_gameEngine.getMouseState();
            var i : Int;
            var expressionPicker : ExpressionPickerWidget;
            var numPickers : Int = m_expressionPickers.length;
            for (i in 0...numPickers){
                expressionPicker = m_expressionPickers[i];
                
                if (expressionPicker.isActive) 
                {
                    var pickedExpressionContainer : ExpressionContainer = expressionPicker.pickExpressionContainerUnderPoint(
                            mouseState.mousePositionThisFrame.x,
                            mouseState.mousePositionThisFrame.y
                            );
                    
                    if (pickedExpressionContainer != null) 
                    {
                        if (m_lastPickedContainerInFrame != pickedExpressionContainer &&
                            m_lastPickedContainerInFrame != null) 
                        {
                            expressionPicker.setExpressionContainerOver(m_lastPickedContainerInFrame, false);
                        }  // If clicked on a container, then select it or deselect it  
                        
                        
                        
                        if (mouseState.leftMousePressedThisFrame) 
                        {
                            expressionPicker.setExpressionContainerSelected(pickedExpressionContainer, !pickedExpressionContainer.getIsSelected());
                            
                            var expression : String = pickedExpressionContainer.getExpressionComponent().expressionString;
                            var pickedId : String = m_gameEngine.getUiEntityIdFromObject(expressionPicker);
                            var eventType : String = ((pickedExpressionContainer.getIsSelected())) ? 
                            GameEvent.EXPRESSION_PICKER_SELECT_OPTION : GameEvent.EXPRESSION_PICKER_DESELECT_OPTION;
                            m_gameEngine.dispatchEventWith(eventType, false, [expression, pickedId]);
                            
                            //log event as well
                            var loggingDetails : Dynamic = {
                                buttonName : eventType,
                                expressionName : expression,
                                locationX : mouseState.mousePositionThisFrame.x,
                                locationY : mouseState.mousePositionThisFrame.y,

                            };
                            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.TUTORIAL_PROGRESS_EVENT, false, loggingDetails);
                            
                            Audio.instance.playSfx("expression_option_pick");
                        }
                        else 
                        {
                            // Show hover over
                            expressionPicker.setExpressionContainerOver(pickedExpressionContainer, true);
                        }
                        
                        m_lastPickerHit = expressionPicker;
                        m_lastPickedContainerInFrame = pickedExpressionContainer;
                    }
                    else if (m_lastPickedContainerInFrame != null && m_lastPickerHit == expressionPicker) 
                    {
                        // If mouse not hitting anything, turn off mouse hover on last picked container
                        // for that frame
                        expressionPicker.setExpressionContainerOver(m_lastPickedContainerInFrame, false);
                        m_lastPickedContainerInFrame = null;
                        m_lastPickerHit = null;
                    }
                }
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_expressionPickers = new Array<ExpressionPickerWidget>();
        var expressionPickerDisplays : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(ExpressionPickerWidget);
        for (expressionPickerDisplay in expressionPickerDisplays)
        {
            m_expressionPickers.push(try cast(expressionPickerDisplay, ExpressionPickerWidget) catch(e:Dynamic) null);
        }
    }
}
