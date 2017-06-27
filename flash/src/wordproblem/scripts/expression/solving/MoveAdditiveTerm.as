package wordproblem.scripts.expression.solving
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.expression.BaseTermAreaScript;
    
    /**
     * This script handles allowing a player to pick up an entire term group and move it to
     * the otherside, assuming that term was added or subtracted. This is mostly just a shortcut
     * to allow a user to quickly reorganize an equation.
     * 
     * i.e. x+a*b/d=6 should allow the pickup of a*b/d and move it in one action to get x=6-a*b/d
     */
    public class MoveAdditiveTerm extends BaseTermAreaScript
    {
        public function MoveAdditiveTerm(gameEngine:IGameEngine, 
                                         expressionCompiler:IExpressionTreeCompiler, 
                                         assetManager:AssetManager, 
                                         id:String=null, 
                                         isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            return status;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
        }
        
        /*
        Listen for click and drag on a term??? Some other script listens for the grab.
        Multiple scripts might be contending for the grabbed widget and it is unclear which is the right one 
        
        After some starting distance we will need to grab the entire group and not just the individual card
        
        We copy the entire group entire of widgets, the dragged widget is actually the a grouped term
        The problem is the layout and redraw of a group occurs at the term area widget level.
        */
    }
}