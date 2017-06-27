package wordproblem.engine.animation
{
    import flash.display3D.Context3DBlendFactor;
    import flash.geom.Rectangle;
    
    import dragonbox.common.particlesystem.action.Age;
    import dragonbox.common.particlesystem.action.Fade;
    import dragonbox.common.particlesystem.action.KillZone;
    import dragonbox.common.particlesystem.action.Move;
    import dragonbox.common.particlesystem.action.Rotate;
    import dragonbox.common.particlesystem.action.ScaleChangeDynamic;
    import dragonbox.common.particlesystem.clock.SteadyClock;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.particlesystem.initializer.Alpha;
    import dragonbox.common.particlesystem.initializer.ColorInitializer;
    import dragonbox.common.particlesystem.initializer.LifeTime;
    import dragonbox.common.particlesystem.initializer.Position;
    import dragonbox.common.particlesystem.initializer.RotationVelocity;
    import dragonbox.common.particlesystem.initializer.ScaleInitializer;
    import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
    import dragonbox.common.particlesystem.initializer.VelocityInitializer;
    import dragonbox.common.particlesystem.renderer.ParticleRenderer;
    import dragonbox.common.particlesystem.zone.PointZone;
    import dragonbox.common.particlesystem.zone.RectangleZone;
    
    import starling.animation.IAnimatable;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import wordproblem.resource.AssetManager
    
    import wordproblem.resource.Resources;
    
    /**
     * Adds a slight sparkle of particles to a given collection of display object
     */
    public class ShimmerAnimation implements IAnimatable
    {
        private var m_assetManager:AssetManager;
        private var m_activeShimmerEmitters:Vector.<Emitter>;
        private var m_shimmerRenderer:ParticleRenderer;
        
        /** Pool of emitters that can be re-used */
        private var m_availableEmitters:Vector.<Emitter>;
        
        public function ShimmerAnimation(assetManager:AssetManager)
        {
            const particleAtlas:TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
            const sourceTexture:Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
            
            m_assetManager = assetManager;
            m_activeShimmerEmitters = new Vector.<Emitter>();
            m_availableEmitters = new Vector.<Emitter>();
            
            const sourceBlendMode:String = Context3DBlendFactor.SOURCE_ALPHA;
            const destinationBlendMode:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            const shimmerRenderer:ParticleRenderer = new ParticleRenderer(sourceTexture, sourceBlendMode, destinationBlendMode);
            m_shimmerRenderer = shimmerRenderer;
        }
        
        /**
         *
         * @param viewsToShimmer
         *      List of objects to apply the shimmer to
         */
        public function play(viewsToShimmer:Vector.<DisplayObject>, 
                             canvasToAdd:DisplayObjectContainer):void
        {
            var i:int;
            var viewToShimmer:DisplayObject;
            var viewToShimmerBounds:Rectangle = new Rectangle();
            var emitter:Emitter;
            const numViewsToShimmer:int = viewsToShimmer.length;
            for (i = 0; i < numViewsToShimmer; i++)
            {
                viewToShimmer = viewsToShimmer[i];
                viewToShimmer.getBounds(canvasToAdd, viewToShimmerBounds);
                
                emitter = this.createEmitter(viewToShimmerBounds);
                emitter.start();
                
                m_activeShimmerEmitters.push(emitter);
                m_shimmerRenderer.addEmitter(emitter);
            }
            
            canvasToAdd.addChild(m_shimmerRenderer);
            
            Starling.juggler.add(this);
        }
        
        public function stop():void
        {
            if (m_shimmerRenderer.parent)
            {
                m_shimmerRenderer.parent.removeChild(m_shimmerRenderer);
            }
            
            while (m_activeShimmerEmitters.length > 0)
            {
                const emitterToReuse:Emitter = m_activeShimmerEmitters.pop();
                emitterToReuse.reset();
                m_availableEmitters.push(emitterToReuse);
            }
            
            m_shimmerRenderer.removeAndDisposeAllEmitters();
            Starling.juggler.remove(this);
        }
        
        public function advanceTime(time:Number):void
        {
            var i:int;
            var emitter:Emitter;
            const numEmitters:int = m_activeShimmerEmitters.length;
            for (i = 0; i < numEmitters; i++)
            {
                emitter = m_activeShimmerEmitters[i];
                emitter.update(time);
            }
            
            m_shimmerRenderer.update();
        }
        
        private function createEmitter(bounds:Rectangle):Emitter
        {
            const particleAtlas:TextureAtlas = m_assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
            const sourceBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
            const diamondBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_DIAMOND);
            const starBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_STAR);
            const circleBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_CIRCLE);
            const bubbleBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_BUBBLE);
            
            var shimmerEmitter:Emitter;
            var boundsCenterX:Number = bounds.left + bounds.width / 2;
            var boundsCenterY:Number = bounds.top + bounds.height / 2;
            var radius:Number = bounds.width * 0.6;
            var ratio:Number = bounds.height / bounds.width;
            if (m_availableEmitters.length == 0)
            {
                shimmerEmitter = new Emitter();
                shimmerEmitter.addInitializer(new LifeTime(1, 1));
                
                var boxZone:RectangleZone = new RectangleZone(bounds.x, bounds.y, bounds.width, bounds.height);
                shimmerEmitter.addInitializer(new Position(boxZone));//new DiskZone(boundsCenterX, boundsCenterY, radius, radius, ratio)));
                shimmerEmitter.addInitializer(new VelocityInitializer(new PointZone(0, -10)));//new DiskZone(0, 0, 50, 60, 1)));
                shimmerEmitter.addInitializer(new ColorInitializer(0xFFFF00, 0x00FF00, false));
                shimmerEmitter.addInitializer(new Alpha(1.0, 1.0));
                shimmerEmitter.addInitializer(new ScaleInitializer(0.1, 0.2, true, 0.6, 0.7));
                shimmerEmitter.addInitializer(new TextureUVInitializer(Vector.<Rectangle>([diamondBounds]), sourceBounds));
                shimmerEmitter.addInitializer(new RotationVelocity(-2.0, 2.0));
                
                const padding:Number = 10;
                var killZone:RectangleZone = new RectangleZone(
                    bounds.x - padding, 
                    bounds.y - padding, 
                    bounds.width + 2 * padding, 
                    bounds.height + 2 * padding
                );
                shimmerEmitter.addAction(new KillZone(boxZone, true));
                shimmerEmitter.addAction(new Age());
                shimmerEmitter.addAction(new Fade(1.0, 0.2));
                shimmerEmitter.addAction(new ScaleChangeDynamic());
                shimmerEmitter.addAction(new Move());
                shimmerEmitter.addAction(new Rotate());
                
                const rate:Number = bounds.width * 0.1;
                shimmerEmitter.setClock(new SteadyClock(rate));
            }
            else
            {
                shimmerEmitter = m_availableEmitters.pop();
                const positionInitializer:Position = shimmerEmitter.getInitializer(Position) as Position;
                boxZone = positionInitializer.getZone() as RectangleZone;
                boxZone.reset(bounds.x, bounds.y, bounds.width, bounds.height);//boundsCenterX, boundsCenterY, radius, radius, ratio);
            }
            
            return shimmerEmitter;
        }
    }
}