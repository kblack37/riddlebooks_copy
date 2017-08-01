package wordproblem.scripts;


import starling.events.Event;

import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;

/**
 * Base class that buffers events
 */
class BaseBufferEventScript extends ScriptNode
{
    /**
     * Starling event listeners are not synched to the visit call of the script nodes. This means it is possible
     * that the callback for an event triggers after a script has been visited. In order to synch with the
     * visit, we need to buffer the event and call the callbacks on the NEXT visit cycle.
     * 
     * The main purpose for this is to correctly implement an ordered priority of the scripts, meaning a
     * scipt can interrupt another from executing an action to prevent gesture conflicts.
     */
    private var m_eventTypeBuffer : Array<String>;
    
    /**
     * Remember the parameters associated with each buffered event.
     */
    private var m_eventParamBuffer : Array<Dynamic>;
    
    public function new(id : String = null, isActive : Bool = true)
    {
        super(id, isActive);
        
        m_eventTypeBuffer = new Array<String>();
        m_eventParamBuffer = new Array<Dynamic>();
    }
    
    override public function visit() : Int
    {
        iterateThroughBufferedEvents();
        return ScriptStatus.SUCCESS;
    }
    
    override public function reset() : Void
    {
        // Make sure buffers are cleared on each visit frame
		m_eventTypeBuffer = new Array<String>();
		m_eventParamBuffer = new Array<Dynamic>();
    }
    
    private function iterateThroughBufferedEvents() : Void
    {
        if (m_eventTypeBuffer.length > 0) 
        {
            var i : Int = 0;
            var numEvents : Int = m_eventTypeBuffer.length;
            for (i in 0...numEvents){
                var eventType : String = m_eventTypeBuffer[i];
                var eventParam : Dynamic = m_eventParamBuffer[i];
                processBufferedEvent(eventType, eventParam);
            }
            
			m_eventTypeBuffer = new Array<String>();
			m_eventParamBuffer = new Array<Dynamic>();
        }
    }
    
    /**
     * Event listeners should bind to this function if we want to process all captured events
     * together on the next frame.
     */
    private function bufferEvent(event : Event, param : Dynamic) : Void
    {
        m_eventTypeBuffer.push(event.type);
        m_eventParamBuffer.push(param);
    }
    
    /**
     * A script will iterate through all buffered event found during a frame and uses this function for custom
     * logic to be applied to a particular event.
     * 
     * Subclasses should override
     */
    private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
    }
}
