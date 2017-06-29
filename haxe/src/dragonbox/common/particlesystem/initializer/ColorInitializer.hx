package dragonbox.common.particlesystem.initializer;

import dragonbox.common.particlesystem.initializer.Initializer;

import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.util.XColor;

/**
 * Set the initial color from some range
 * 
 * Can also optionally assign start and end value for each particle to remember
 * to allow for different color over time variation per particle.
 */
class ColorInitializer extends Initializer
{
    private var m_startColorRange1 : Int;
    private var m_startColorRange2 : Int;
    private var m_endColorRange1 : Int;
    private var m_endColorRange2 : Int;
    private var m_assignStartEndToParticle : Bool;
    
    public function new(startColorRange1 : Int,
            startColorRange2 : Int,
            assignStartEndToParticle : Bool,
            endColorRange1 : Int = 0,
            endColorRange2 : Int = 0)
    {
        super();
        
        m_startColorRange1 = startColorRange1;
        m_startColorRange2 = startColorRange2;
        m_endColorRange1 = endColorRange1;
        m_endColorRange2 = endColorRange2;
        
        m_assignStartEndToParticle = assignStartEndToParticle;
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        var startingColorToPick : Int = XColor.interpolateColors(m_startColorRange1, m_startColorRange2, Math.random());
        particle.color = startingColorToPick;
        
        if (m_assignStartEndToParticle) 
        {
            particle.startColor = startingColorToPick;
            
            var endingColorToPick : Int = XColor.interpolateColors(m_endColorRange1, m_endColorRange2, Math.random());
            particle.endColor = endingColorToPick;
        }
    }
}
