package wordproblem.currency
{
    import flash.display3D.Context3DBlendFactor;
    import flash.geom.Rectangle;
    
    import dragonbox.common.particlesystem.action.Accelerate;
    import dragonbox.common.particlesystem.action.Age;
    import dragonbox.common.particlesystem.action.DragForce;
    import dragonbox.common.particlesystem.action.Fade;
    import dragonbox.common.particlesystem.action.Move;
    import dragonbox.common.particlesystem.clock.BlastClock;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.particlesystem.initializer.LifeTime;
    import dragonbox.common.particlesystem.initializer.ScaleInitializer;
    import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
    import dragonbox.common.particlesystem.initializer.VelocityInitializer;
    import dragonbox.common.particlesystem.renderer.ParticleRenderer;
    import dragonbox.common.particlesystem.zone.DiskSectionZone;
    
    import starling.animation.IAnimatable;
    import starling.display.DisplayObjectContainer;
    import starling.textures.Texture;
    
    /**
     * Show a small burst of coins spouting from a central point, like a geyser.
     */
    public class CurrencyParticlesAnimation implements IAnimatable
    {
        private var m_emitter:Emitter;
        private var m_renderer:ParticleRenderer;
        
        private var m_canvas:DisplayObjectContainer;
        
        /**
         * The animation has an end time, use this counter to determine when we can stop
         * updating the particles.
         */
        private var m_timeSpentRunning:Number;
        
        
        public function CurrencyParticlesAnimation(coinTexture:Texture, canvas:DisplayObjectContainer)
        {
            m_canvas = canvas;
            
            m_emitter = new Emitter();
            
            var coinTextureBounds:Rectangle = new Rectangle(0, 0, coinTexture.width, coinTexture.height);
            m_emitter.addInitializer(new TextureUVInitializer(Vector.<Rectangle>([coinTextureBounds]), coinTextureBounds));
            m_emitter.addInitializer(new VelocityInitializer(new DiskSectionZone(0, 0, 150, 110, Math.PI * 1.4, Math.PI * 1.6)));
            m_emitter.addInitializer(new ScaleInitializer(0.15, 0.2, false, 0, 0));
            m_emitter.addInitializer(new LifeTime(2, 2));
            
            m_emitter.addAction(new Move());
            m_emitter.addAction(new Age(easeInExpo));
            m_emitter.addAction(new Accelerate(0, 100));
            m_emitter.addAction(new DragForce(1));
            m_emitter.addAction(new Fade(1.0, 0.0));
            
            m_emitter.setClock(new BlastClock(20));
            
            var sourceBlendMode:String = Context3DBlendFactor.SOURCE_ALPHA;
            var destinationBlendMode:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            m_renderer = new ParticleRenderer(coinTexture, sourceBlendMode, destinationBlendMode);
        }
        
        public function start():void
        {
            m_timeSpentRunning = 0;
            m_emitter.start();
            m_renderer.addEmitter(m_emitter);
            m_canvas.addChildAt(m_renderer, 0);
        }
        
        public function dispose():void
        {
            m_emitter.dispose();
            m_renderer.removeFromParent(true);
        }
        
        public function advanceTime(time:Number):void
        {
            if (m_timeSpentRunning < 3)
            {
                m_timeSpentRunning += time;
                m_emitter.update(time);
                m_renderer.update();
            }
        }
        
        private function easeInExpo(t:Number,d:Number):Number
        {
            return 1 - Math.pow(2, 10 * (t / d - 1));
        }
    }
}