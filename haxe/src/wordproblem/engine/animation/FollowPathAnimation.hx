package wordproblem.engine.animation;


import flash.display3d.Context3DBlendFactor;
import flash.geom.Rectangle;

import dragonbox.common.particlesystem.action.Accelerate;
import dragonbox.common.particlesystem.action.Age;
import dragonbox.common.particlesystem.action.Fade;
import dragonbox.common.particlesystem.action.Move;
import dragonbox.common.particlesystem.action.ScaleChangeFixed;
import dragonbox.common.particlesystem.clock.Clock;
import dragonbox.common.particlesystem.clock.SteadyClock;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.particlesystem.initializer.ColorInitializer;
import dragonbox.common.particlesystem.initializer.Initializer;
import dragonbox.common.particlesystem.initializer.LifeTime;
import dragonbox.common.particlesystem.initializer.Position;
import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
import dragonbox.common.particlesystem.initializer.VelocityInitializer;
import dragonbox.common.particlesystem.renderer.ParticleRenderer;
import dragonbox.common.particlesystem.zone.DiskZone;
import dragonbox.common.particlesystem.zone.PointZone;

import starling.animation.IAnimatable;
import starling.display.DisplayObjectContainer;
import starling.events.Event;
import starling.events.EventDispatcher;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

import wordproblem.resource.AssetManager;
import wordproblem.resource.Resources;

/**
 * Animation causes a particle emitter to follow an elliptical path around some bounding box
 */
class FollowPathAnimation extends EventDispatcher implements IAnimatable
{
    private var m_emitter : Emitter;
    private var m_renderer : ParticleRenderer;
    
    private var m_canvasToAddTo : DisplayObjectContainer;
    
    private var m_maxTimeSeconds : Float;
    private var m_timeElapsedSeconds : Float;
    private var m_onComplete : Function;
    
    /**
     * @param boundingBox
     *      The box with the reference frame of the canvas enclosing the elliptical path
     * @param maxTimeSeconds
     *      Number of seconds the animation should run before stopping itself, if zero or less it will never
     *      stop on its own
     */
    public function new(assetManager : AssetManager,
            canvasToAddTo : DisplayObjectContainer,
            boundingBox : Rectangle,
            maxTimeSeconds : Float,
            onComplete : Function = null)
    {
        super();
        var particleAtlas : TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
        var sourceTexture : Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
        var sourceBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
        var starBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_CIRCLE);
        
        var steadyClock : Clock = new SteadyClock(20);
        var textureInitializer : Initializer = new TextureUVInitializer([starBounds], sourceBounds);
        
        var emitter : Emitter = new Emitter();
        emitter.addInitializer(new Position(new DiskZone(boundingBox.width * 0.5, boundingBox.width * 0.5, boundingBox.width * 0.5, boundingBox.width * 0.5, 1)));
        emitter.addInitializer(new LifeTime(4, 2));
        emitter.addInitializer(new ColorInitializer(0x7FFFD4, 0x00FF00, false));
        emitter.addInitializer(textureInitializer);
        emitter.addInitializer(new VelocityInitializer(new PointZone(0, -5)));
        emitter.addAction(new Accelerate(0, -4));
        emitter.addAction(new Age());
        emitter.addAction(new Move());
        emitter.addAction(new ScaleChangeFixed(0.6, 0.3));
        emitter.addAction(new Fade(1.0, 0.0));
        emitter.setClock(steadyClock);
        m_emitter = emitter;
        
        var sourceBlendMode : String = Context3DBlendFactor.SOURCE_ALPHA;
        var destinationBlendMode : String = Context3DBlendFactor.ONE;
        var renderer : ParticleRenderer = new ParticleRenderer(sourceTexture, sourceBlendMode, destinationBlendMode);
        renderer.addEmitter(emitter);
        m_renderer = renderer;
        m_canvasToAddTo = canvasToAddTo;
        
        m_maxTimeSeconds = maxTimeSeconds;
        m_timeElapsedSeconds = 0.0;
        m_onComplete = onComplete;
    }
    
    public function advanceTime(time : Float) : Void
    {
        m_timeElapsedSeconds += time;
        
        if (m_maxTimeSeconds <= 0 || m_timeElapsedSeconds < m_maxTimeSeconds) 
        {
            m_emitter.update(time);
            m_renderer.update();
        }
        else 
        {
            // After some amount of time has passed, kill the resource
            dispose();
            
            this.dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
            
            if (m_onComplete != null) 
            {
                m_onComplete();
            }
        }
    }
    
    public function play() : Void
    {
        m_emitter.start();
        m_canvasToAddTo.addChild(m_renderer);
    }
    
    public function pause() : Void
    {
        m_emitter.reset();
        m_renderer.removeFromParent();
    }
    
    public function dispose() : Void
    {
        m_emitter.dispose();
        m_renderer.removeFromParent(true);
    }
}
