package wordproblem.scripts.barmodel
{
    import cgs.Audio.Audio;
    
    import starling.events.EventDispatcher;
    
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.scripts.BaseBufferEventScript;
    
    /**
     * Listen for all events tied to the construction of the bar model and play some
     */
    public class BarModelAudio extends BaseBufferEventScript
    {
        private var m_eventDispatcher:EventDispatcher;
        
        public function BarModelAudio(eventDispatcher:EventDispatcher,
                                      id:String=null, 
                                      isActive:Boolean=true)
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
        
        override public function dispose():void
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
        
        private function onAddNewBar():void
        {
            Audio.instance.playSfx("carddrop");
        }
        
        private function onAddNewBarComparison():void
        {
            Audio.instance.playSfx("carddrop");
        }
        
        private function onAddNewBarSegment():void
        {
            Audio.instance.playSfx("carddrop");
        }
        
        private function onAddNewHorizontalLabel():void
        {
            Audio.instance.playSfx("carddrop");
        }
        
        private function onAddNewUnitBar():void
        {
            Audio.instance.playSfx("carddrop");
        }
        
        private function onAddNewVerticalLabel():void
        {
            Audio.instance.playSfx("carddrop");
        }
        
        private function onRemoveBarComparison():void
        {
            Audio.instance.playSfx("button_click");
        }
        
        private function onRemoveBarSegment():void
        {
            Audio.instance.playSfx("button_click");
        }
        
        private function onRemoveHorizontalLabel():void
        {
            Audio.instance.playSfx("card2deck");
        }
        
        private function onRemoveVerticalLabel():void
        {
            Audio.instance.playSfx("card2deck");
        }
        
        private function onResizeBarComparison():void
        {
            Audio.instance.playSfx("card2deck");
        }
        
        private function onResizeHorizontalLabel():void
        {
            Audio.instance.playSfx("card2deck");
        }
        
        private function onResizeVerticalLabel():void
        {
            Audio.instance.playSfx("card2deck");
        }
        
        private function onSplitBarSegment():void
        {
            Audio.instance.playSfx("card2deck");
        }
    }
}