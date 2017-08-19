package wordproblem.engine.animation;


import flash.geom.Rectangle;

import dragonbox.common.particlesystem.action.Age;
import dragonbox.common.particlesystem.action.Move;
import dragonbox.common.particlesystem.action.RotateToDirection;
import dragonbox.common.particlesystem.action.ScaleChangeFixed;
import dragonbox.common.particlesystem.clock.SteadyClock;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.particlesystem.initializer.ColorInitializer;
import dragonbox.common.particlesystem.initializer.Initializer;
import dragonbox.common.particlesystem.initializer.LifeTime;
import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
import dragonbox.common.particlesystem.initializer.VelocityInitializer;
import dragonbox.common.particlesystem.renderer.ParticleRenderer;
import dragonbox.common.particlesystem.zone.DiskZone;

import starling.animation.IAnimatable;
import starling.core.Starling;
import starling.display.DisplayObjectContainer;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

import wordproblem.resource.AssetManager;
import wordproblem.resource.Resources;

class SparklerAnimation implements IAnimatable
{
    public var x(never, set) : Float;
    public var y(never, set) : Float;

    private var m_emitter : Emitter;
    private var m_particleRenderer : ParticleRenderer;
    
    public function new(assetManager : AssetManager)
    {
        //var particleAtlas : TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
        //var sourceTexture : Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
        //var sourceBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
        //var particleBounds : Rectangle = particleAtlas.getRegion("circle");
        //
        //var textureInitializer : Initializer = new TextureUVInitializer([particleBounds], sourceBounds);
        //var colorInitializer : Initializer = new ColorInitializer(0xFF00C0, 0x198CFF, false);
        //var velocityInitializer : Initializer = new VelocityInitializer(new DiskZone(0, 0, 100, 50, 1));
        //var lifeTimeInitializer : Initializer = new LifeTime(1.0, 0.7);
        //
        //var emitter : Emitter = new Emitter();
        //emitter.setClock(new SteadyClock(15));
        //emitter.addInitializer(textureInitializer);
        //emitter.addInitializer(colorInitializer);
        //emitter.addInitializer(velocityInitializer);
        //emitter.addInitializer(lifeTimeInitializer);
        //emitter.addAction(new Age());
        //emitter.addAction(new Move());
        //emitter.addAction(new ScaleChangeFixed(0.8, 0.1));
        //emitter.addAction(new RotateToDirection());
        //m_emitter = emitter;
        //
        //var renderer : ParticleRenderer = new ParticleRenderer(sourceTexture);  //, Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);  
        //renderer.addEmitter(emitter);
        //m_particleRenderer = renderer;
    }
    
    private function set_x(value : Float) : Float
    {
        m_particleRenderer.x = value;
        return value;
    }
    
    private function set_y(value : Float) : Float
    {
        m_particleRenderer.y = value;
        return value;
    }
    
    public function play(canvasToAddTo : DisplayObjectContainer) : Void
    {
        m_emitter.reset();
        m_emitter.start();
        Starling.current.juggler.add(this);
        
        canvasToAddTo.addChild(m_particleRenderer);
    }
    
    public function stop() : Void
    {
        m_emitter.reset();
        if (m_particleRenderer.parent != null) m_particleRenderer.parent.removeChild(m_particleRenderer);
        
        Starling.current.juggler.remove(this);
    }
    
    public function advanceTime(time : Float) : Void
    {
        m_emitter.update(time);
        m_particleRenderer.update();
    }
}
