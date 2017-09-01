package wordproblem.scripts.barmodel;

import cgs.audio.Audio;

import openfl.events.EventDispatcher;

import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.scripts.BaseBufferEventScript;

/**
 * Listen for all events tied to the construction of the bar model and play some
 */
class BarModelAudio extends BaseBufferEventScript
{
    private var m_eventDispatcher : EventDispatcher;
    
    public function new(eventDispatcher : EventDispatcher,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_eventDispatcher = eventDispatcher;
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR, onAddNewBar);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, onAddNewBarComparison);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_SEGMENT, onAddNewBarSegment);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL, onAddNewHorizontalLabel);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR, onAddNewUnitBar);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL, onAddNewVerticalLabel);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_BAR_COMPARISON, onRemoveBarComparison);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_BAR_SEGMENT, onRemoveBarSegment);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_HORIZONTAL_LABEL, onRemoveHorizontalLabel);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.REMOVE_VERTICAL_LABEL, onRemoveVerticalLabel);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.RESIZE_BAR_COMPARISON, onResizeBarComparison);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.RESIZE_HORIZONTAL_LABEL, onResizeHorizontalLabel);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.RESIZE_VERTICAL_LABEL, onResizeVerticalLabel);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.SPLIT_BAR_SEGMENT, onSplitBarSegment);
        m_eventDispatcher.addEventListener(AlgebraAdventureLoggingConstants.MULTIPLY_BAR, onSplitBarSegment);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR, onAddNewBar);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, onAddNewBarComparison);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_BAR_SEGMENT, onAddNewBarSegment);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL, onAddNewHorizontalLabel);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR, onAddNewUnitBar);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL, onAddNewVerticalLabel);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.REMOVE_BAR_COMPARISON, onRemoveBarComparison);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.REMOVE_BAR_SEGMENT, onRemoveBarSegment);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.REMOVE_HORIZONTAL_LABEL, onRemoveHorizontalLabel);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.REMOVE_VERTICAL_LABEL, onRemoveVerticalLabel);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.RESIZE_BAR_COMPARISON, onResizeBarComparison);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.RESIZE_HORIZONTAL_LABEL, onResizeHorizontalLabel);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.RESIZE_VERTICAL_LABEL, onResizeVerticalLabel);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.SPLIT_BAR_SEGMENT, onSplitBarSegment);
        m_eventDispatcher.removeEventListener(AlgebraAdventureLoggingConstants.MULTIPLY_BAR, onSplitBarSegment);
    }
    
    private function onAddNewBar(event : Dynamic) : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewBarComparison(event : Dynamic) : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewBarSegment(event : Dynamic) : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewHorizontalLabel(event : Dynamic) : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewUnitBar(event : Dynamic) : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewVerticalLabel(event : Dynamic) : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onRemoveBarComparison(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
    }
    
    private function onRemoveBarSegment(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
    }
    
    private function onRemoveHorizontalLabel(event : Dynamic) : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onRemoveVerticalLabel(event : Dynamic) : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onResizeBarComparison(event : Dynamic) : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onResizeHorizontalLabel(event : Dynamic) : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onResizeVerticalLabel(event : Dynamic) : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onSplitBarSegment(event : Dynamic) : Void
    {
        Audio.instance.playSfx("card2deck");
    }
}
