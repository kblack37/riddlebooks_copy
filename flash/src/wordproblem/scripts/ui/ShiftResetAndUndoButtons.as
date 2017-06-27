package wordproblem.scripts.ui
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.display.DisplayObject;
    
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
    public class ShiftResetAndUndoButtons extends BaseGameScript
    {
        public function ShiftResetAndUndoButtons(gameEngine:IGameEngine, 
                                                 expressionCompiler:IExpressionTreeCompiler, 
                                                 assetManager:AssetManager, 
                                                 id:String=null, 
                                                 isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        public function shift():void
        {
            // New y position is in the middle of the space between the bar model area
            // and the term area
            var termArea:DisplayObject = m_gameEngine.getUiEntity("rightTermArea");
            var barModelArea:DisplayObject = m_gameEngine.getUiEntity("barModelArea");
            var bottom:Number = barModelArea.y + barModelArea.height;
            var amountOfOpenSpace:Number = termArea.y - bottom;
            
            var undoButton:DisplayObject = m_gameEngine.getUiEntity("undoButton");
            if (undoButton != null)
            {
                undoButton.y = (amountOfOpenSpace - undoButton.height) * 0.5 + bottom;
            }
            
            var resetButton:DisplayObject = m_gameEngine.getUiEntity("resetButton");
            if (resetButton != null)
            {
                resetButton.y = (amountOfOpenSpace - resetButton.height) * 0.5 + bottom;
            }
        }
    }
}