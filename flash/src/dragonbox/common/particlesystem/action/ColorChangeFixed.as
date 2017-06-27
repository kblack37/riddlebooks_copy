package dragonbox.common.particlesystem.action
{
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.util.XColor;

    /**
     * Applies a change in color from fixed start and end colors
     * 
     * A color initialization is not needed if using this action.
     */
    public class ColorChangeFixed extends Action
    {
        private var m_startColor:uint;
        private var m_endColor:uint;
        
        public function ColorChangeFixed(startColor:uint, endColor:uint)
        {
            super();
            
            m_startColor = startColor;
            m_endColor = endColor;
        }
        
        override public function update(emitter:Emitter, particle:Particle, time:Number):void
        {
            particle.color = XColor.interpolateColors(m_startColor, m_endColor, particle.energy);
        }
    }
}