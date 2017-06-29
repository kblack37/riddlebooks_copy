package wordproblem.scripts.expression.solving;


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
class MoveAdditiveTerm extends BaseTermAreaScript
{
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
        var status : Int = ScriptStatus.FAIL;
        return status;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
    }
}
