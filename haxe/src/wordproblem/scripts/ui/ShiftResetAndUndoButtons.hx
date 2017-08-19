package wordproblem.scripts.ui;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * Have common logic that shifts down the hint and reset buttons to a new ending location.
 * For bar model levels, they generally start just above the bar model area. When the player is finished
 * making a bar model, those buttons should move down just above the equation model areas.
 * 
 * The movement is to indicate the reset and undo now only affect the equation areas.
 */
class ShiftResetAndUndoButtons extends BaseGameScript
{
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    public function shift() : Void
    {
        // New y position is in the middle of the space between the bar model area
        // and the term area
        var termArea : DisplayObject = m_gameEngine.getUiEntity("rightTermArea");
        var barModelArea : DisplayObject = m_gameEngine.getUiEntity("barModelArea");
        var bottom : Float = barModelArea.y + barModelArea.height;
        var amountOfOpenSpace : Float = termArea.y - bottom;
        
        var undoButton : DisplayObject = m_gameEngine.getUiEntity("undoButton");
        if (undoButton != null) 
        {
            undoButton.y = (amountOfOpenSpace - undoButton.height) * 0.5 + bottom;
        }
        
        var resetButton : DisplayObject = m_gameEngine.getUiEntity("resetButton");
        if (resetButton != null) 
        {
            resetButton.y = (amountOfOpenSpace - resetButton.height) * 0.5 + bottom;
        }
    }
}
