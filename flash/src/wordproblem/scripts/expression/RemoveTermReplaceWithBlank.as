package wordproblem.scripts.expression
{
    import dragonbox.common.expressiontree.WildCardNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * Slightly modified behavior of term removal where each card gets immediately replaced
     * by a blank card. This is useful for levels where we want to preserve the expression tree structure
     */
    public class RemoveTermReplaceWithBlank extends RemoveTerm
    {
        public function RemoveTermReplaceWithBlank(gameEngine:IGameEngine, 
                                                   expressionCompiler:IExpressionTreeCompiler, 
                                                   assetManager:AssetManager)
        {
            super(gameEngine, expressionCompiler, assetManager);
        }
        
        override protected function onRemoveCallback(termArea:TermAreaWidget, termWidget:BaseTermWidget):void
        {
            termArea.isReady = false;
            termArea.getTree().replaceNode(termWidget, new WildCardNode(m_expressionCompiler.getVectorSpace(), "?", null));
            termArea.redrawAfterModification();
        }
    }
}