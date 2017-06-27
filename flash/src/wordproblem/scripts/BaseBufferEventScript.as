package wordproblem.scripts
{
    import starling.events.Event;
    
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    
    /**
     * Base class that buffers events
     */
    public class BaseBufferEventScript extends ScriptNode
    {
        /**
         * Starling event listeners are not synched to the visit call of the script nodes. This means it is possible
         * that the callback for an event triggers after a script has been visited. In order to synch with the
         * visit, we need to buffer the event and call the callbacks on the NEXT visit cycle.
         * 
         * The main purpose for this is to correctly implement an ordered priority of the scripts, meaning a
         * scipt can interrupt another from executing an action to prevent gesture conflicts.
         */
        protected var m_eventTypeBuffer:Vector.<String>;
        
        /**
         * Remember the parameters associated with each buffered event.
         */
        protected var m_eventParamBuffer:Vector.<Object>;
        
        public function BaseBufferEventScript(id:String=null, isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_eventTypeBuffer = new Vector.<String>();
            m_eventParamBuffer = new Vector.<Object>();
        }
        
        override public function visit():int
        {
            iterateThroughBufferedEvents();
            return ScriptStatus.SUCCESS;
        }
        
        override public function reset():void
        {
            // Make sure buffers are cleared on each visit frame
            m_eventTypeBuffer.length = 0;
            m_eventParamBuffer.length = 0;
        }
        
        protected function iterateThroughBufferedEvents():void
        {
            if (m_eventTypeBuffer.length > 0)
            {
                var i:int;
                var numEvents:int = m_eventTypeBuffer.length;
                for (i = 0; i < numEvents; i++)
                {
                    var eventType:String = m_eventTypeBuffer[i];
                    var eventParam:Object = m_eventParamBuffer[i];
                    processBufferedEvent(eventType, eventParam);
                }
                
                m_eventTypeBuffer.length = 0;
                m_eventParamBuffer.length = 0;
            }
        }
        
        /**
         * Event listeners should bind to this function if we want to process all captured events
         * together on the next frame.
         */
        protected function bufferEvent(event:Event, param:Object):void
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
        protected function processBufferedEvent(eventType:String, param:Object):void
        {
        }
    }
}