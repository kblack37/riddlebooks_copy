package wordproblem.engine.animation
{
    import flash.display3D.Context3DBlendFactor;
    import flash.geom.Rectangle;
    
    import dragonbox.common.particlesystem.action.Accelerate;
    import dragonbox.common.particlesystem.action.Action;
    import dragonbox.common.particlesystem.action.Age;
    import dragonbox.common.particlesystem.action.DragForce;
    import dragonbox.common.particlesystem.action.Fade;
    import dragonbox.common.particlesystem.action.Move;
    import dragonbox.common.particlesystem.action.RotateToDirection;
    import dragonbox.common.particlesystem.clock.BlastClock;
    import dragonbox.common.particlesystem.clock.Clock;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.particlesystem.initializer.ColorInitializer;
    import dragonbox.common.particlesystem.initializer.Initializer;
    import dragonbox.common.particlesystem.initializer.LifeTime;
    import dragonbox.common.particlesystem.initializer.Position;
    import dragonbox.common.particlesystem.initializer.ScaleInitializer;
    import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
    import dragonbox.common.particlesystem.initializer.VelocityInitializer;
    import dragonbox.common.particlesystem.renderer.ParticleRenderer;
    import dragonbox.common.particlesystem.zone.DiskZone;
    import dragonbox.common.particlesystem.zone.PointZone;
    import dragonbox.common.util.XColor;
    
    import starling.animation.IAnimatable;
    import starling.core.Starling;
    import starling.display.DisplayObjectContainer;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    
    import wordproblem.resource.AssetManager;
    import wordproblem.resource.Resources;
    
    public class FireworksAnimation implements IAnimatable
    {
        /** Expected time it takes for fireword animation to complete */
        private static const MAX_RUNTIME_FOR_FIREWORK:Number = 8.0;
        private static const TIME_COUNT_LIMIT:Number = 20;
        /** Number of fireworks */
        private static const NUM_EMITTERS:int = 10;
        
        /** Keep track of progress within an animation cycle. In the cycle each emitter should burst once before the cycle restarts */
        private var m_timeCount:Number = 0.0;
        private var m_burstEmitters:Vector.<Emitter>;
        private var m_startOffsets:Vector.<Number>;
        private var m_emitterActive:Vector.<Boolean>;
        private var m_fireworksRenderer:ParticleRenderer;
        
        public function FireworksAnimation(width:Number, height:Number, assetManager:AssetManager)
        {
            // Get all the particles from the asset management
            var particleAtlas:TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
            var sourceTexture:Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
            var sourceBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
            var diamondBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_DIAMOND);
            var starBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_STAR);
            
            // Setting up fireworks using Dragon Box animation system
            var textureInitializer:Initializer = new TextureUVInitializer(Vector.<Rectangle>([starBounds, diamondBounds]), sourceBounds);
            var colorInitializer:Initializer;   
            var scaleInitializer:Initializer; 
            var ageAction:Action = new Age(easeInExpo);
            var moveAction:Action = new Move();
            var dragAction:Action = new DragForce(0.5);
            var fadeAction:Action = new Fade(1, 0);
            var accelerateAction:Action = new Accelerate(0, 100);
            var rotateToDirectionAction:Action = new RotateToDirection();
            
            // Only need one renderer for each emitter using a particular batch of textures
            var sourceBlendMode:String = Context3DBlendFactor.SOURCE_ALPHA;
            var destinationBlendMode:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            m_fireworksRenderer = new ParticleRenderer(sourceTexture, sourceBlendMode, destinationBlendMode);
            
            // Setup variables for each firework (ie. emitter)
            m_burstEmitters = new Vector.<Emitter>();
            m_startOffsets = new Vector.<Number>();
            m_emitterActive = new Vector.<Boolean>();
            
            // offsetMultipliers makes sure that the fire works are split evenly on the right and left side
            // if there is an odd number one more firework will be on the right than on the left
            var offsetMultipliers:Vector.<int> = new Vector.<int>();
            for (var j:int = 0; j < NUM_EMITTERS; j++)
            { 
                offsetMultipliers.push(j % 2);
            }
            
            // Setup each emitter (that is... a firework)
            for (var i:int = 0; i < NUM_EMITTERS; i++)
            {
                // Set location - randomly, but evenly on the left and right
                var anOffsetMultiplier:int = offsetMultipliers.splice(Math.floor(Math.random() * offsetMultipliers.length), 1)[0];
                var burstX:int = (Math.random() * 400) + (anOffsetMultiplier * 400);
                var burstY:int = 50 + Math.random() * 450;
                
                // Set the color - randomly from hsv color space
                colorInitializer = new ColorInitializer(
                    XColor.getDistributedHsvColor(Math.random()), 
                    XColor.getDistributedHsvColor(Math.random()), 
                    false
                );
                
                // Set the size of the particles in this firework
                scaleInitializer = new ScaleInitializer(0.2 + Math.random() * 0.8, 0.2 + Math.random() * 0.8, false, 0.2 + Math.random() * 0.8, 0.2 + Math.random() * 0.8);
                
                // Emitter for central burst
                const burstEmitter:Emitter = new Emitter();
                burstEmitter.addInitializer(new Position(new PointZone(burstX, burstY)));
                
                // Set size and shape of the burst
                var size:Number = 100 + Math.random() * 100;
                burstEmitter.addInitializer(new VelocityInitializer(new DiskZone(0, 0, size + 150 + Math.random() * 150, size, 0.5 + Math.random())));
                burstEmitter.addInitializer(new LifeTime(3, 1));
                burstEmitter.addInitializer(colorInitializer);
                burstEmitter.addInitializer(textureInitializer);
                burstEmitter.addInitializer(scaleInitializer);
                
                // Set series of actions (animations) that make the firework effect
                burstEmitter.addAction(accelerateAction);
                burstEmitter.addAction(moveAction);
                burstEmitter.addAction(dragAction);
                burstEmitter.addAction(fadeAction);
                burstEmitter.addAction(ageAction);
                burstEmitter.addAction(rotateToDirectionAction);
                
                // Set the clock of the firework
                var burstClock:Clock = new BlastClock(150);
                burstEmitter.setClock(burstClock);
                
                // Add the firework to the display list
                m_fireworksRenderer.addEmitter(burstEmitter);
                
                // Track firework, its location, and whether or not it is active
                m_burstEmitters.push(burstEmitter);
                m_startOffsets.push(Math.random() + i);
                m_emitterActive.push(false);
            }
        }
        
        /**
         * Computes the alpha of a particle in a firework. Essentially defines when particles will individually fade out, and how fast,
         * defined by an exponential curve (as opposed to a linear one).
         * @param    t    Total lifetime
         * @param    d    Current time
         * @return
         */
        private function easeInExpo(t:Number,d:Number):Number
        {
            return 1 - Math.pow(2, 10 * (t / d - 1));
        }
        
        /**
         * Runs the firework animation.
         * @param    canvasToAddTo
         */
        public function play(canvasToAddTo:DisplayObjectContainer):void
        {
            Starling.juggler.add(this);
            
            canvasToAddTo.addChild(m_fireworksRenderer);
        }
        
        /**
         * Updates each emitter as time proceeds.
         * @param    time
         */
        public function advanceTime(time:Number):void
        {
            // Restart the animation cycle
            if (m_timeCount > TIME_COUNT_LIMIT)
            {
                //m_timeCount = 0;
            }
            else
            {
                m_timeCount += time;
            }
            
            var i:int;
            var emitter:Emitter;
            for (i = 0; i < m_burstEmitters.length; i++)
            {
                emitter = m_burstEmitters[i];
                
                // If we are in the time slice the start offset on the cycle and an emitter is not yet active,
                // we should turn it on
                if (m_timeCount > m_startOffsets[i] && m_timeCount < (m_startOffsets[i] + MAX_RUNTIME_FOR_FIREWORK) && !m_emitterActive[i])
                {
                    // Need to reset clock and start again
                    emitter.start();
                    m_emitterActive[i] = true;
                }
                // If an emitter has gone past the timeslice it should run at, should turn off for a cycle
                else if (m_timeCount > (m_startOffsets[i] + MAX_RUNTIME_FOR_FIREWORK))
                {
                    emitter.reset();
                    m_emitterActive[i] = false;
                }
                
                // Update active emitters, so they proceed in their animation
                if (m_emitterActive[i])
                {
                    emitter.update(time);
                }
            }
            
            // Always update the rendering
            m_fireworksRenderer.update();
        }
        
        public function dispose():void
        {
            m_fireworksRenderer.removeAndDisposeAllEmitters();
            m_fireworksRenderer.removeFromParent(true);
        }
    }
}