package wordproblem.engine.animation;


import flash.display3d.Context3DBlendFactor;
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
import wordproblem.resource.AssetManager;

import wordproblem.resource.Resources;

/**
 * Adds a slight sparkle of particles to a given collection of display object
 */
class ShimmerAnimation implements IAnimatable
{
    private var m_assetManager : AssetManager;
    private var m_activeShimmerEmitters : Array<Emitter>;
    private var m_shimmerRenderer : ParticleRenderer;
    
    /** Pool of emitters that can be re-used */
    private var m_availableEmitters : Array<Emitter>;
    
    public function new(assetManager : AssetManager)
    {
        var particleAtlas : TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
        var sourceTexture : Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
        
        m_assetManager = assetManager;
        m_activeShimmerEmitters = new Array<Emitter>();
        m_availableEmitters = new Array<Emitter>();
        
        var sourceBlendMode : String = Context3DBlendFactor.SOURCE_ALPHA;
        var destinationBlendMode : String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
        var shimmerRenderer : ParticleRenderer = new ParticleRenderer(sourceTexture, sourceBlendMode, destinationBlendMode);
        m_shimmerRenderer = shimmerRenderer;
    }
    
    /**
     *
     * @param viewsToShimmer
     *      List of objects to apply the shimmer to
     */
    public function play(viewsToShimmer : Array<DisplayObject>,
            canvasToAdd : DisplayObjectContainer) : Void
    {
        var i : Int = 0;
        var viewToShimmer : DisplayObject = null;
        var viewToShimmerBounds : Rectangle = new Rectangle();
        var emitter : Emitter = null;
        var numViewsToShimmer : Int = viewsToShimmer.length;
        for (i in 0...numViewsToShimmer){
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
    
    public function stop() : Void
    {
        if (m_shimmerRenderer.parent) 
        {
            m_shimmerRenderer.parent.removeChild(m_shimmerRenderer);
        }
        
        while (m_activeShimmerEmitters.length > 0)
        {
            var emitterToReuse : Emitter = m_activeShimmerEmitters.pop();
            emitterToReuse.reset();
            m_availableEmitters.push(emitterToReuse);
        }
        
        m_shimmerRenderer.removeAndDisposeAllEmitters();
        Starling.juggler.remove(this);
    }
    
    public function advanceTime(time : Float) : Void
    {
        var i : Int = 0;
        var emitter : Emitter = null;
        var numEmitters : Int = m_activeShimmerEmitters.length;
        for (i in 0...numEmitters){
            emitter = m_activeShimmerEmitters[i];
            emitter.update(time);
        }
        
        m_shimmerRenderer.update();
    }
    
    private function createEmitter(bounds : Rectangle) : Emitter
    {
        var particleAtlas : TextureAtlas = m_assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
        var sourceBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
        var diamondBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_DIAMOND);
        var starBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_STAR);
        var circleBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_CIRCLE);
        var bubbleBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_BUBBLE);
        
        var shimmerEmitter : Emitter = null;
        var boundsCenterX : Float = bounds.left + bounds.width / 2;
        var boundsCenterY : Float = bounds.top + bounds.height / 2;
        var radius : Float = bounds.width * 0.6;
        var ratio : Float = bounds.height / bounds.width;
        if (m_availableEmitters.length == 0) 
        {
            shimmerEmitter = new Emitter();
            shimmerEmitter.addInitializer(new LifeTime(1, 1));
            
            var boxZone : RectangleZone = new RectangleZone(bounds.x, bounds.y, bounds.width, bounds.height);
            shimmerEmitter.addInitializer(new Position(boxZone));  //new DiskZone(boundsCenterX, boundsCenterY, radius, radius, ratio)));  
            shimmerEmitter.addInitializer(new VelocityInitializer(new PointZone(0, -10)));  //new DiskZone(0, 0, 50, 60, 1)));  
            shimmerEmitter.addInitializer(new ColorInitializer(0xFFFF00, 0x00FF00, false));
            shimmerEmitter.addInitializer(new Alpha(1.0, 1.0));
            shimmerEmitter.addInitializer(new ScaleInitializer(0.1, 0.2, true, 0.6, 0.7));
            shimmerEmitter.addInitializer(new TextureUVInitializer([diamondBounds], sourceBounds));
            shimmerEmitter.addInitializer(new RotationVelocity(-2.0, 2.0));
            
            var padding : Float = 10;
            var killZone : RectangleZone = new RectangleZone(
            bounds.x - padding, 
            bounds.y - padding, 
            bounds.width + 2 * padding, 
            bounds.height + 2 * padding, 
            );
            shimmerEmitter.addAction(new KillZone(boxZone, true));
            shimmerEmitter.addAction(new Age());
            shimmerEmitter.addAction(new Fade(1.0, 0.2));
            shimmerEmitter.addAction(new ScaleChangeDynamic());
            shimmerEmitter.addAction(new Move());
            shimmerEmitter.addAction(new Rotate());
            
            var rate : Float = bounds.width * 0.1;
            shimmerEmitter.setClock(new SteadyClock(rate));
        }
        else 
        {
            shimmerEmitter = m_availableEmitters.pop();
            var positionInitializer : Position = try cast(shimmerEmitter.getInitializer(Position), Position) catch(e:Dynamic) null;
            boxZone = try cast(positionInitializer.getZone(), RectangleZone) catch(e:Dynamic) null;
            boxZone.reset(bounds.x, bounds.y, bounds.width, bounds.height);
        }
        
        return shimmerEmitter;
    }
}
