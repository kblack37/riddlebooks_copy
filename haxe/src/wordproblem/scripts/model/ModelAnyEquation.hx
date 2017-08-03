package wordproblem.scripts.model;


import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.vectorspace.IVectorSpace;

import starling.display.Button;
import starling.events.Event;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * This script will remove all restrictions on what can correctly be modeled, this is most useful for the cases
 * where the player can accumulate a collection of equations during a playthrough.
 * 
 * If the player clicks the equation button, dispatch event that they have successfully modeled something.
 */
class ModelAnyEquation extends BaseGameScript
{
    private var m_modelButton : Button;
    
    private var m_clickCounter : Int = 0;
    
    public function new(gameEngine : IGameEngine, compiler : IExpressionTreeCompiler, assetManager : AssetManager)
    {
        super(gameEngine, compiler, assetManager);
        m_id = "ModelAnyEquation";
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        // Listen for when the player tries to model an equation
        m_modelButton = try cast(super.m_gameEngine.getUiEntity("modelEquationButton"), Button) catch(e:Dynamic) null;
        this.setIsActive(m_isActive);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        
        if (super.m_ready) 
        {
            m_modelButton.removeEventListener(Event.TRIGGERED, onClickModel);
            if (value) 
            {
                m_modelButton.addEventListener(Event.TRIGGERED, onClickModel);
            }
        }
    }
    
    private function onClickModel() : Void
    {
        // Combine the contents of both term areas into a single expression
        m_clickCounter++;
        
        var leftTermArea : TermAreaWidget = try cast(super.m_gameEngine.getUiEntity("leftTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var modeledLeft : ExpressionNode = ((leftTermArea.getWidgetRoot() != null)) ? 
        leftTermArea.getWidgetRoot().getNode() : null;
        
        var rightTermArea : TermAreaWidget = try cast(super.m_gameEngine.getUiEntity("rightTermArea"), TermAreaWidget) catch(e:Dynamic) null;
        var modeledRight : ExpressionNode = ((rightTermArea.getWidgetRoot() != null)) ? 
        rightTermArea.getWidgetRoot().getNode() : null;
        
        if (modeledRight != null && modeledLeft != null) 
        {
            var vectorSpace : IVectorSpace = super.m_expressionCompiler.getVectorSpace();
            var givenEquation : ExpressionNode = ExpressionUtil.createOperatorTree(
                    modeledLeft,
                    modeledRight,
                    vectorSpace,
                    vectorSpace.getEqualityOperator());
            m_gameEngine.dispatchEventWith(GameEvent.EQUATION_MODEL_SUCCESS, false, {
                        id : m_clickCounter + "",
                        equation : super.m_expressionCompiler.decompileAtNode(givenEquation),

                    });
        }
    }
}
