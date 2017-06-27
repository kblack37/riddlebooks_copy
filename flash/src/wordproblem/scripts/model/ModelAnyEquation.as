package wordproblem.scripts.model
{
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import feathers.controls.Button;
    
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
    public class ModelAnyEquation extends BaseGameScript
    {
        private var m_modelButton:Button;
        
        private var m_clickCounter:int = 0;
        
        public function ModelAnyEquation(gameEngine:IGameEngine, compiler:IExpressionTreeCompiler, assetManager:AssetManager)
        {
            super(gameEngine, compiler, assetManager);
            m_id = "ModelAnyEquation";
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Listen for when the player tries to model an equation
            m_modelButton = super.m_gameEngine.getUiEntity("modelEquationButton") as Button;
            this.setIsActive(m_isActive);
        }
        
        override public function setIsActive(value:Boolean):void
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
        
        private function onClickModel():void
        {
            // Combine the contents of both term areas into a single expression
            m_clickCounter++;
            
            const leftTermArea:TermAreaWidget = super.m_gameEngine.getUiEntity("leftTermArea") as TermAreaWidget;
            const modeledLeft:ExpressionNode = (leftTermArea.getWidgetRoot() != null) ?
                leftTermArea.getWidgetRoot().getNode() : null;
            
            const rightTermArea:TermAreaWidget = super.m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
            const modeledRight:ExpressionNode = (rightTermArea.getWidgetRoot() != null) ?
                rightTermArea.getWidgetRoot().getNode() : null;
            
            if (modeledRight != null && modeledLeft != null)
            {
                const vectorSpace:IVectorSpace = super.m_expressionCompiler.getVectorSpace();
                const givenEquation:ExpressionNode = ExpressionUtil.createOperatorTree(
                    modeledLeft, 
                    modeledRight, 
                    vectorSpace, 
                    vectorSpace.getEqualityOperator());
                m_gameEngine.dispatchEventWith(GameEvent.EQUATION_MODEL_SUCCESS, false, {id:m_clickCounter + "", equation:super.m_expressionCompiler.decompileAtNode(givenEquation)});
            }
        }
    }
}