package wordproblem.scripts.expression.solving
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * This script handles factoring a term out of parenthesis.
     */
    public class FactorTerm extends BaseGameScript
    {
        public function FactorTerm(gameEngine:IGameEngine, 
                                   expressionCompiler:IExpressionTreeCompiler, 
                                   assetManager:AssetManager, 
                                   id:String=null, 
                                   isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
    }
}