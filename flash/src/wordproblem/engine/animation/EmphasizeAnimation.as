package wordproblem.engine.animation
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.particlesystem.action.Age;
    import dragonbox.common.particlesystem.action.CentripetalForce;
    import dragonbox.common.particlesystem.action.ColorChangeDynamic;
    import dragonbox.common.particlesystem.action.DragForce;
    import dragonbox.common.particlesystem.action.Fade;
    import dragonbox.common.particlesystem.action.Move;
    import dragonbox.common.particlesystem.clock.SteadyClock;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.particlesystem.initializer.ColorInitializer;
    import dragonbox.common.particlesystem.initializer.LifeTime;
    import dragonbox.common.particlesystem.initializer.Position;
    import dragonbox.common.particlesystem.initializer.ScaleInitializer;
    import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
    import dragonbox.common.particlesystem.initializer.VelocityInitializer;
    import dragonbox.common.particlesystem.renderer.ParticleRenderer;
    import dragonbox.common.particlesystem.zone.DiskZone;
    
    import starling.animation.IAnimatable;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import wordproblem.resource.AssetManager
    
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.resource.Resources;

    /**
     * Animation is used to place some kind of emphasis or highlighting to a list
     * of given display objects.
     */
    public class EmphasizeAnimation implements IAnimatable
    {
        private var m_maxRadius:Number;
        private var m_radius:Number;
        
        private var m_widgetsToEmphasize:Vector.<BaseTermWidget>;
        
        private var m_assetManager:AssetManager;
        private var m_emphasizeRenderer:ParticleRenderer;
        private var m_activeEmphasizeEmitters:Vector.<Emitter>;
        
        public function EmphasizeAnimation(assetManager:AssetManager)
        {
            super();
            
            const particleAtlas:TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
            const sourceTexture:Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
            
            m_activeEmphasizeEmitters = new Vector.<Emitter>();
            m_assetManager = assetManager;
            
            m_emphasizeRenderer = new ParticleRenderer(sourceTexture);
            m_radius = Math.random() * m_maxRadius;
        }
        
        public function play(widgetsToEmphasize:Vector.<BaseTermWidget>):void
        {
            m_widgetsToEmphasize = new Vector.<BaseTermWidget>();
            for (var i:int = 0; i < widgetsToEmphasize.length; i++)
            {
                const widgetToEmphasize:BaseTermWidget = widgetsToEmphasize[i];
                m_widgetsToEmphasize.push(widgetToEmphasize);
                widgetToEmphasize.addChildAt(m_emphasizeRenderer, 0);
                
                const emitter:Emitter = createEmitter();
                emitter.start();
                m_activeEmphasizeEmitters.push(emitter);
                m_emphasizeRenderer.addEmitter(emitter);
            }
        }
        
        public function stop():void
        {
            m_emphasizeRenderer.removeAndDisposeAllEmitters();
            m_emphasizeRenderer.removeFromParent();
        }
        
        public function advanceTime(time:Number):void
        {
            var i:int;
            const numEmitters:int = m_activeEmphasizeEmitters.length;
            for (i = 0; i < numEmitters; i++)
            {
                m_activeEmphasizeEmitters[i].update(time);
            }
            
            m_emphasizeRenderer.update();
        }

        private function createEmitter():Emitter
        {
            var particleAtlas:TextureAtlas = m_assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
            var sourceBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
            var circleBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_CIRCLE);
            var diamondBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_DIAMOND);
            
            var emphasizeEmitter:Emitter = new Emitter();
            emphasizeEmitter.addInitializer(new LifeTime(7, 3));
            emphasizeEmitter.addInitializer(new ScaleInitializer(0.3, 0.5, false, 0 , 0));
            emphasizeEmitter.addInitializer(new VelocityInitializer(new DiskZone(0, 0, 5, 0, 1)));
            emphasizeEmitter.addInitializer(new Position(new DiskZone(0, 0, 10, 5, 1)));
            emphasizeEmitter.addInitializer(new ColorInitializer(0x0000CC, 0x00CC00, true, 0xCC0000, 0xFF0000));
            emphasizeEmitter.addInitializer(new TextureUVInitializer(Vector.<Rectangle>([circleBounds]), sourceBounds));
            
            emphasizeEmitter.addAction(new Age());
            emphasizeEmitter.addAction(new Move());
            emphasizeEmitter.addAction(new Fade(0.8, 0.2));
            emphasizeEmitter.addAction(new DragForce(3));
            emphasizeEmitter.addAction(new ColorChangeDynamic());
            emphasizeEmitter.addAction(new CentripetalForce(0, 0, 0, 100));
            
            emphasizeEmitter.setClock(new SteadyClock(10));
            return emphasizeEmitter;
        }
    }
}