package wordproblem.scripts.expression;


import cgs.audio.Audio;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;

import wordproblem.callouts.TooltipControl;
import wordproblem.display.LabelButton;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;
import wordproblem.scripts.expression.UndoTermArea;

class ResetTermArea extends BaseGameScript
{
    private var m_resetButton : LabelButton;
    
    /**
     * If null, starting expressions are empty for each term area
     */
    private var m_startingExpressions : Array<String>;
    
    /**
     * Logic to get a tooltip to appear on reset
     */
    private var m_toolTipControl : TooltipControl;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    /**
     * Sometimes we want a reset to go back to a non-empty intial state.
     * For this to happen, the level must specify the starting expression that should
     * go into each term area.
     * 
     * (WARNING: Multistep equations should reset this after each modeled equation
     * otherwise the term areas will reset to wrong values next time
     * 
     * @param expressions
     *      If null, then a reset to set the term areas to empty. Other wise each
     *      slot in the array sets the expressions for a term area.
     */
    public function setStartingExpressions(expressions : Array<String>) : Void
    {
        m_startingExpressions = expressions;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            if (m_resetButton != null) 
            {
                m_resetButton.removeEventListener(MouseEvent.CLICK, resetTerm);
            }
            
            if (value) 
            {
                m_resetButton.addEventListener(MouseEvent.CLICK, resetTerm);
            }
        }
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            m_toolTipControl.onEnterFrame();
        }
        return ScriptStatus.SUCCESS;
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        m_resetButton = try cast(m_gameEngine.getUiEntity("resetButton"), LabelButton) catch(e:Dynamic) null;
        
        m_toolTipControl = new TooltipControl(m_gameEngine, "resetButton", "Reset");
        
        // Activate again to make sure the event listener is bound to the button we just found
        setIsActive(m_isActive);
    }
    
    private function resetTerm(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        
        var undoTermArea : UndoTermArea = try cast(getNodeById("UndoTermArea"), UndoTermArea) catch(e:Dynamic) null;
        var undoWasActive : Bool = false;
        if (undoTermArea != null) 
        {
            undoWasActive = undoTermArea.getIsActive();
            
            var leftRoot : ExpressionNode = null;
            var rightRoot : ExpressionNode = null;
            if (m_startingExpressions != null) 
            {
                if (m_startingExpressions.length > 0 && m_startingExpressions[0] != null) 
                {
                    leftRoot = m_expressionCompiler.compile(m_startingExpressions[0]);
                }
                
                if (m_startingExpressions.length > 1 && m_startingExpressions[1] != null) 
                {
                    rightRoot = m_expressionCompiler.compile(m_startingExpressions[1]);
                }
            }
            undoTermArea.resetHistory(false, leftRoot, rightRoot);
            
            // Prevents undo from adding something to the stack history when reset is called
            if (undoWasActive) 
            {
                undoTermArea.setIsActive(false);
            }
        }
        
        var termAreas : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
        var i : Int = 0;
        for (i in 0...termAreas.length){
            // Check if there an initial expression a term area should reset to.
            // If none it becomes empty.
            var expressionRoot : ExpressionNode = null;
            if (m_startingExpressions != null && i < m_startingExpressions.length && m_startingExpressions[i] != null) 
            {
                expressionRoot = m_expressionCompiler.compile(m_startingExpressions[i]);
            }
            
            var termArea : TermAreaWidget = try cast(termAreas[i], TermAreaWidget) catch(e:Dynamic) null;
            termArea.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), expressionRoot));
            termArea.redrawAfterModification();
        }
		
		// Signal that a reset was triggered  
        var loggingDetails : Dynamic = {
            buttonName : "ResetButton"
        };
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, loggingDetails));
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.RESET_EQUATION, loggingDetails));
        
        if (undoTermArea != null && undoWasActive) 
        {
            // Reactives after stack history is cleared
            undoTermArea.setIsActive(true);
        }
    }
}




