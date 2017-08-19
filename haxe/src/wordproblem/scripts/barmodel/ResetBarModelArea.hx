package wordproblem.scripts.barmodel;

import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.events.MouseEvent;

import wordproblem.callouts.TooltipControl;
import wordproblem.display.LabelButton;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.events.DataEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.UndoBarModelArea;

/**
 * Script controlling the reset button and resetting the bar model area back to some initial state.
 * (Usually initial state is empty but it can also be set an actual drawing.)
 */
class ResetBarModelArea extends BaseBarModelScript
{
    private var m_resetButton : LabelButton;
    
    /**
     * The model that the reset should clear back to.
     * 
     * If null then go back to empty model
     */
    private var m_startingModel : BarModelData;
    
    private var m_tooltipControl : TooltipControl;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            if (m_resetButton != null) 
            {
                m_resetButton.removeEventListener(MouseEvent.CLICK, onReset);
                if (value) 
                {
                    m_resetButton.addEventListener(MouseEvent.CLICK, onReset);
                }
            }
        }
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            m_tooltipControl.onEnterFrame();
        }
        return ScriptStatus.SUCCESS;
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        m_resetButton = try cast(m_gameEngine.getUiEntity("resetButton"), LabelButton) catch(e:Dynamic) null;
        
        m_tooltipControl = new TooltipControl(m_gameEngine, "resetButton", "Reset");
        
        // Activate again to make sure the event listener is bound to the button we just found
        setIsActive(m_isActive);
    }
    
    /**
     * Sometimes we have a fixed starting point, reset should clear back to that point
     * instead of making everything empty. For example we have a tutorial level that starts
     * of with a partially completed drawing, a reset should go back to the partial drawing.
     * 
     * @param startingModel
     *      If null, reset will show empty model. Reset uses an internal copy
     */
    public function setStartingModel(startingModel : BarModelData) : Void
    {
        if (startingModel != null) 
        {
            startingModel = startingModel.clone();
        }
        m_startingModel = startingModel;
    }
    
    private function onReset(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        if (m_startingModel == null) 
        {
            m_barModelArea.getBarModelData().clear();
        }
        else 
        {
            m_barModelArea.setBarModelData(m_startingModel.clone());
        }
        m_barModelArea.redraw();
        
        var loggingDetails : Dynamic = {
            buttonName : "ResetButton"
        };
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, loggingDetails));
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.RESET_BAR_MODEL, loggingDetails));
        
        // Dependency on undo, clear out the history stack on reset
        var undoBarModelArea : UndoBarModelArea = try cast(this.getNodeById("UndoBarModelArea"), UndoBarModelArea) catch(e:Dynamic) null;
        if (undoBarModelArea != null) 
        {
            undoBarModelArea.resetHistory();
        }
    }
}
