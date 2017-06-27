package wordproblem.hints.tips.eventsequence
{
    import flash.geom.Point;
    
    import dragonbox.common.eventSequence.SequenceEvent;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    /**
     * Event that moves the position of a mouse state from a start position to an end position
     * in a linear path within a given time frame
     */
    public class MouseMoveToSequenceEvent extends SequenceEvent
    {
        private var m_startPosition:Point;
        private var m_endPosition:Point;
        
        private var m_moveDurationSeconds:Number;
        private var m_secondsElapsedSinceStart:Number;
        private var m_simulatedMouseState:MouseState;
        private var m_mouseDownOnDrag:Boolean;
        
        public function MouseMoveToSequenceEvent(startPosition:Point, 
                                                 endPosition:Point,
                                                 durationSeconds:Number, 
                                                 simulatedMouseState:MouseState, 
                                                 mouseDownOnDrag:Boolean=true)
        {
            super(null);
            
            m_startPosition = startPosition;
            m_endPosition = endPosition;
            m_moveDurationSeconds = durationSeconds;
            m_simulatedMouseState = simulatedMouseState;
            m_mouseDownOnDrag = mouseDownOnDrag;
            
            m_secondsElapsedSinceStart = 0.0;
        }
        
        override public function update(time:Time):void
        {
            if(currentState == ACTIVE)
            {
                m_secondsElapsedSinceStart += time.currentDeltaSeconds;
                
                if(m_secondsElapsedSinceStart >= m_moveDurationSeconds)
                {
                    this.currentState = COMPLETE;
                    
                    m_secondsElapsedSinceStart = m_moveDurationSeconds;
                }
                
                m_simulatedMouseState.leftMouseDown = m_mouseDownOnDrag;
                m_simulatedMouseState.leftMouseDraggedThisFrame = m_mouseDownOnDrag;
                
                var prevX:Number = m_simulatedMouseState.mousePositionThisFrame.x;
                var prevY:Number = m_simulatedMouseState.mousePositionThisFrame.y;
                m_simulatedMouseState.mousePositionLastFrame.x = prevX;
                m_simulatedMouseState.mousePositionLastFrame.y = prevY;
                
                var deltaX:Number = m_endPosition.x - m_startPosition.x;
                var deltaY:Number = m_endPosition.y - m_startPosition.y;
                m_simulatedMouseState.mousePositionThisFrame.x = (deltaX / m_moveDurationSeconds) * m_secondsElapsedSinceStart + m_startPosition.x;
                m_simulatedMouseState.mousePositionThisFrame.y = (deltaY / m_moveDurationSeconds) * m_secondsElapsedSinceStart + m_startPosition.y;
                
                m_simulatedMouseState.mouseDeltaThisFrame.x = m_simulatedMouseState.mousePositionThisFrame.x - prevX;
                m_simulatedMouseState.mouseDeltaThisFrame.y = m_simulatedMouseState.mousePositionThisFrame.y - prevY;
            }
        }
        
        override public function reset():void
        {
            super.reset();
            
            m_secondsElapsedSinceStart = 0.0;
        }
    }
}