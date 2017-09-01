package wordproblem.scripts.expression;

import cgs.audio.Audio;

import openfl.events.EventDispatcher;

import wordproblem.engine.events.GameEvent;
import wordproblem.scripts.BaseBufferEventScript;

class ExpressionModelAudio extends BaseBufferEventScript
{
    /**
     * Catch all the signals related to expression modeling and use those to figure
     * out the right audio to play.
     */
    private var m_eventDispatcher : EventDispatcher;
    
    public function new(eventDispatcher : EventDispatcher,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_eventDispatcher = eventDispatcher;
        m_eventDispatcher.addEventListener(GameEvent.CHANGED_OPERATOR, onChangedOperator);
        m_eventDispatcher.addEventListener(GameEvent.ADD_TERM_ATTEMPTED, onAddTermAttempted);
        m_eventDispatcher.addEventListener(GameEvent.REMOVE_TERM, onRemoveTerm);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_eventDispatcher.removeEventListener(GameEvent.CHANGED_OPERATOR, onChangedOperator);
        m_eventDispatcher.removeEventListener(GameEvent.ADD_TERM_ATTEMPTED, onAddTermAttempted);
        m_eventDispatcher.removeEventListener(GameEvent.REMOVE_TERM, onRemoveTerm);
    }
    
    private function onChangedOperator(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
    }
    
    private function onAddTermAttempted(event : Dynamic) : Void
    {
        Audio.instance.playSfx("carddrop");
    }
    
    private function onRemoveTerm(event : Dynamic) : Void
    {
        Audio.instance.playSfx("text2card");
    }
}
