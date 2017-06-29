package dragonbox.common.particlesystem.action;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.util.XColor;

/**
 * Apply a change in color using a particles own start and end colors.
 * 
 * Color initialization is required before using this action
 */
class ColorChangeDynamic extends Action
{
    public function new()
    {
        super();
    }
    
    override public function update(emitter : Emitter, particle : Particle, time : Float) : Void
    {
        var startColor : Int = particle.startColor;
        var endColor : Int = particle.endColor;
        particle.color = XColor.interpolateColors(startColor, endColor, particle.energy);
    }
}
