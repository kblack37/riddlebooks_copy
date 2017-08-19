package wordproblem.scripts.barmodel;


import cgs.audio.Audio;
import cgs.internationalization.StringTable;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import wordproblem.display.LabelButton;
import openfl.events.Event;
import openfl.events.MouseEvent;

import wordproblem.callouts.TooltipControl;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

/**
 * This script handles undoing actions that were performed on the bar modeling widget
 */
class UndoBarModelArea extends BaseBarModelScript
{
    /**
     * A history list of the bar model information
     */
    private var m_barModelDataHistory : Array<BarModelData>;
    
    /**
     * The button when pressed that should trigger the undo
     */
    private var m_undoButton : LabelButton;
    
    private var m_tooltipControl : TooltipControl;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_barModelDataHistory = new Array<BarModelData>();
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            if (m_undoButton != null) 
            {
                m_undoButton.removeEventListener(MouseEvent.CLICK, onUndoButtonClick);
                m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, onBarModelAreaChange);
                if (value) 
                {
                    m_undoButton.addEventListener(MouseEvent.CLICK, onUndoButtonClick);
                    m_gameEngine.addEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, onBarModelAreaChange);
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
        
        m_undoButton = try cast(m_gameEngine.getUiEntity("undoButton"), LabelButton) catch (e:Dynamic) null;
		// TODO: uncomment when cgs library is finished
        m_tooltipControl = new TooltipControl(m_gameEngine, "undoButton", "" /*StringTable.lookup("undo")*/);
        
        this.setIsActive(m_isActive);
    }
    
    /**
     * Clear out history (useful for multi-part problems)
     */
    public function resetHistory() : Void
    {
		m_barModelDataHistory = new Array<BarModelData>();
    }
    
    public function undo() : Void
    {
        if (m_barModelDataHistory.length > 0) 
        {
            var snapshotToGoTo : BarModelData = m_barModelDataHistory.pop();
            m_barModelArea.setBarModelData(snapshotToGoTo);
            m_barModelArea.redraw();
        }
        
        this.toggleUndoButtonEnabled(m_barModelDataHistory.length > 0);
    }
    
    private function onUndoButtonClick(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        undo();
        
        // Log that an undo was performed on the bar model
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.UNDO_BAR_MODEL, {
                    barModel : m_barModelArea.getBarModelData().serialize()
                }));
    }
    
    /**
     * Need to detect all changes in the bar model data. On each change need to create a snapshot
     * of the model data and save it for later
     */
    private function onBarModelAreaChange(event : Dynamic) : Void
    {
		var data = (try cast(event, DataEvent) catch (e : Dynamic) null).getData();
        m_barModelDataHistory.push(data.previousSnapshot);
        
        this.toggleUndoButtonEnabled(m_barModelDataHistory.length > 0);
    }
    
    private function toggleUndoButtonEnabled(enabled : Bool) : Void
    {
        m_undoButton.alpha = ((enabled)) ? 1.0 : 0.4;
        m_undoButton.enabled = enabled;
    }
}
