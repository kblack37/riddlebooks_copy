package wordproblem.scripts.expression
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.utils.AssetManager;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * Script contains the logic to distribute an existing term into an existing sum or difference.
     * The rule is a*(b+c)=a*b+a*c.
     */
    public class DistributiveProperty extends BaseGameScript
    {
        public function DistributiveProperty(gameEngine:IGameEngine,
                                       expressionCompiler:IExpressionTreeCompiler, 
                                       assetManager:AssetManager)
        {
            super(gameEngine, expressionCompiler, assetManager);
        }
        
        override public function visit():int
        {
            // We first detect if the player is dragging something that already exists in the term area.
            
            // We then want to check that the dragged piece is either multiplying or dividing any term that is wrapped in a parentheses
        }
    }
}