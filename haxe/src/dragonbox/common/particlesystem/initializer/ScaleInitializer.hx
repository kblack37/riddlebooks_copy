package dragonbox.common.particlesystem.initializer;


import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

class ScaleInitializer extends Initializer
{
    private var m_startMinScale : Float;
    private var m_startMaxScale : Float;
    private var m_endMinScale : Float;
    private var m_endMaxScale : Float;
    private var m_assignStartEndToParticle : Bool;
    
    public function new(startMinScale : Float,
            startMaxScale : Float,
            assignStartEndToParticle : Bool,
            endMinScale : Float,
            endMaxScale : Float)
    {
        super();
        
        m_startMinScale = startMinScale;
        m_startMaxScale = startMaxScale;
        m_endMinScale = endMinScale;
        m_endMaxScale = endMaxScale;
        m_assignStartEndToParticle = assignStartEndToParticle;
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        var startScale : Float = ((m_startMinScale == m_startMaxScale)) ? 
        m_startMinScale : m_startMinScale + Math.random() * (m_startMaxScale - m_startMinScale);
        particle.scale = startScale;
        if (m_assignStartEndToParticle) 
        {
            particle.startScale = startScale;
            particle.endScale = m_endMinScale + Math.random() * (m_endMaxScale - m_endMinScale);
        }
    }
}
