package dragonbox.common.particlesystem.activities;


import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Tell the emitter to follow an elliptical path with some
 * fixed velocity
 */
class FollowEllipsePath extends Activity
{
    /**
     * Amount the path should stretch horizontally on either side
     */
    private var m_horizontalRadius : Float;
    
    /**
     * Amount the path should stretch vertically on either side
     */
    private var m_verticalRadius : Float;
    
    /**
     * The number of seconds it should take to make a full circle
     * 
     * The normal period to follow the full path is 2*PI
     * or roughly 6.3 seconds to make a complete circle
     */
    private var m_period : Float;
    
    /**
     * A count of the absolute time in seconds
     */
    private var m_t : Float;
    
    public function new(horizontalRadius : Float, verticalRadius : Float, period : Float)
    {
        super();
        
        m_horizontalRadius = horizontalRadius;
        m_verticalRadius = verticalRadius;
        m_period = period;
        
        m_t = 0.0;
    }
    
    override public function initialize(emitter : Emitter) : Void
    {
    }
    
    override public function update(emitter : Emitter, time : Float) : Void
    {
        m_t += time;
        
        // To prevent integer overflow we can wrap the time back to some small value
        
        // Based on the time elapsed, calculate where the emitter should now be
        var adjustedTime : Float = (2 * Math.PI) / m_period * m_t;
        var x : Float = m_horizontalRadius * Math.cos(adjustedTime);
        var y : Float = m_verticalRadius * Math.sin(adjustedTime);
        
        emitter.x = x;
        emitter.y = y;
    }
}
