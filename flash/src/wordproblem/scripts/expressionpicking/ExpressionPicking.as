package wordproblem.scripts.expressionpicking
{
    import cgs.Audio.Audio;
    
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
    
    public class ExpressionPicking extends BaseGameScript
    {
        private var m_expressionPickers:Vector.<ExpressionPickerWidget>;
        
        private var m_lastPickerHit:ExpressionPickerWidget;
        private var m_lastPickedContainerInFrame:ExpressionContainer;
        
        public function ExpressionPicking(gameEngine:IGameEngine, 
                                          expressionCompiler:IExpressionTreeCompiler, 
                                          assetManager:AssetManager, 
                                          id:String=null, 
                                          isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override public function visit():int
        {
            if (m_isActive && m_ready)
            {
                // Picker should not do anything if its parent layer not active
                if (m_expressionPickers.length > 0 && Layer.getDisplayObjectIsInInactiveLayer(m_expressionPickers[0]))
                {
                    return ScriptStatus.FAIL;
                }
                
                var mouseState:MouseState = m_gameEngine.getMouseState();
                var i:int;
                var expressionPicker:ExpressionPickerWidget;
                const numPickers:int = m_expressionPickers.length;
                for (i = 0; i < numPickers; i++)
                {
                    expressionPicker = m_expressionPickers[i];
                    
                    if (expressionPicker.isActive)
                    {
                        var pickedExpressionContainer:ExpressionContainer = expressionPicker.pickExpressionContainerUnderPoint(
                            mouseState.mousePositionThisFrame.x, 
                            mouseState.mousePositionThisFrame.y
                        );
                        
                        if (pickedExpressionContainer != null)
                        {
                            if (m_lastPickedContainerInFrame != pickedExpressionContainer && 
                                m_lastPickedContainerInFrame != null)
                            {
                                expressionPicker.setExpressionContainerOver(m_lastPickedContainerInFrame, false);
                            }
                            
                            // If clicked on a container, then select it or deselect it
                            if (mouseState.leftMousePressedThisFrame)
                            {
                                expressionPicker.setExpressionContainerSelected(pickedExpressionContainer, !pickedExpressionContainer.getIsSelected());
                                
                                var expression:String = pickedExpressionContainer.getExpressionComponent().expressionString;
                                var pickedId:String = m_gameEngine.getUiEntityIdFromObject(expressionPicker);
                                var eventType:String = (pickedExpressionContainer.getIsSelected()) ?
                                    GameEvent.EXPRESSION_PICKER_SELECT_OPTION : GameEvent.EXPRESSION_PICKER_DESELECT_OPTION;
                                m_gameEngine.dispatchEventWith(eventType, false, [expression, pickedId]);
                                
                                //log event as well
                                var loggingDetails:Object = {
                                    buttonName:eventType,
                                    expressionName:expression,
                                    locationX:mouseState.mousePositionThisFrame.x,
                                    locationY:mouseState.mousePositionThisFrame.y
                                }            
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
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_expressionPickers = new Vector.<ExpressionPickerWidget>();
            var expressionPickerDisplays:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(ExpressionPickerWidget);
            for each (var expressionPickerDisplay:DisplayObject in expressionPickerDisplays)
            {
                m_expressionPickers.push(expressionPickerDisplay as ExpressionPickerWidget);   
            }
        }
    }
}