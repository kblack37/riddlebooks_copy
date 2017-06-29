package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.util.XColor;

/**
 * Applies a change in color from fixed start and end colors
 * 
 * A color initialization is not needed if using this action.
 */
class ColorChangeFixed extends Action
{
    private var m_startColor : Int;
    private var m_endColor : Int;
    
    public function new(startColor : Int, endColor : Int)
    {
        super();
        
        m_startColor = startColor;
        m_endColor = endColor;
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        particle.color = XColor.interpolateColors(m_startColor, m_endColor, particle.energy);
    }
}
