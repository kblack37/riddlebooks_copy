package wordproblem.engine.animation
{
    import dragonbox.common.util.XColor;
    
    import feathers.display.Scale9Image;
    
    import starling.animation.IAnimatable;
    import starling.display.DisplayObject;
    import starling.events.Event;
    import starling.events.EventDispatcher;
    
    /**
     * Animation smoothly interpolates the color of a given image from a start to an end value.
     */
    public class ColorChangeAnimation extends EventDispatcher implements IAnimatable
    {
        private var m_image:DisplayObject;
        private var m_startColor:uint;
        private var m_endColor:uint;
        private var m_elapsedTime:Number;
        private var m_duration:Number;
        
        public function ColorChangeAnimation()
        {
        }
        
        public function play(startColor:uint, 
                             endColor:uint, 
                             durationSeconds:Number, 
                             image:DisplayObject):void
        {
            m_startColor = startColor;
            m_endColor = endColor;
            m_elapsedTime = 0;
            m_duration = durationSeconds;
            m_image = image;
            
            // Make the object the starting color
            if (m_image is Scale9Image)
            {
                (m_image as Scale9Image).color = startColor;
            }
        }
        
        public function advanceTime(time:Number):void
        {
            m_elapsedTime += time;
            const resultColor:uint = XColor.interpolateColors(m_endColor, m_startColor, m_elapsedTime / m_duration);
            if (m_image is Scale9Image)
            {
                (m_image as Scale9Image).color = resultColor;
            }
            
            if (m_elapsedTime > m_duration)
            {
                (m_image as Scale9Image).color = m_endColor;
                dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
            }
        }
    }
}