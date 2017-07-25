package wordproblem.scripts.barmodel;

// TODO: uncomment once cgs library is ported
//import cgs.audio.Audio;

import starling.events.EventDispatcher;

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
    
    private function onAddNewBar() : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewBarComparison() : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewBarSegment() : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewHorizontalLabel() : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewUnitBar() : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onAddNewVerticalLabel() : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onRemoveBarComparison() : Void
    {
        Audio.instance.playSfx("button_click");
    }
    
    private function onRemoveBarSegment() : Void
    {
        Audio.instance.playSfx("button_click");
    }
    
    private function onRemoveHorizontalLabel() : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onRemoveVerticalLabel() : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onResizeBarComparison() : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onResizeHorizontalLabel() : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onResizeVerticalLabel() : Void
    {
        Audio.instance.playSfx("card2deck");
    }
    
    private function onSplitBarSegment() : Void
    {
        Audio.instance.playSfx("card2deck");
    }
}
