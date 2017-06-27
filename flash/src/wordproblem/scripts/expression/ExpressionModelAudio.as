package wordproblem.scripts.expression
{
    import cgs.Audio.Audio;
    
    import starling.events.EventDispatcher;
    
    import wordproblem.engine.events.GameEvent;
    import wordproblem.scripts.BaseBufferEventScript;
    
    public class ExpressionModelAudio extends BaseBufferEventScript
    {
        /**
         * Catch all the signals related to expression modeling and use those to figure
         * out the right audio to play.
         */
        private var m_eventDispatcher:EventDispatcher;
        
        public function ExpressionModelAudio(eventDispatcher:EventDispatcher,
                                             id:String=null, 
                                             isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_eventDispatcher = eventDispatcher;
            m_eventDispatcher.addEventListener(GameEvent.CHANGED_OPERATOR, onChangedOperator);
            m_eventDispatcher.addEventListener(GameEvent.ADD_TERM_ATTEMPTED, onAddTermAttempted);
            m_eventDispatcher.addEventListener(GameEvent.REMOVE_TERM, onRemoveTerm);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_eventDispatcher.removeEventListener(GameEvent.CHANGED_OPERATOR, onChangedOperator);
            m_eventDispatcher.removeEventListener(GameEvent.ADD_TERM_ATTEMPTED, onAddTermAttempted);
            m_eventDispatcher.removeEventListener(GameEvent.REMOVE_TERM, onRemoveTerm);
        }
        
        private function onChangedOperator():void
        {
            Audio.instance.playSfx("button_click");
        }
        
        private function onAddTermAttempted():void
        {
            Audio.instance.playSfx("carddrop");
        }
        
        private function onRemoveTerm():void
        {
            Audio.instance.playSfx("text2card");
        }
    }
}