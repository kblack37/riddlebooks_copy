package dragonbox.common.particlesystem;

import dragonbox.common.particlesystem.ParticleAtlas;
import dragonbox.common.particlesystem.ParticleAtlasXml;

import flash.display3d.Context3DBlendFactor;
import flash.geom.Rectangle;

import dragonbox.common.particlesystem.action.Accelerate;
import dragonbox.common.particlesystem.action.Age;
import dragonbox.common.particlesystem.action.CentripetalForce;
import dragonbox.common.particlesystem.action.ColorChangeDynamic;
import dragonbox.common.particlesystem.action.ColorChangeFixed;
import dragonbox.common.particlesystem.action.DragForce;
import dragonbox.common.particlesystem.action.Fade;
import dragonbox.common.particlesystem.action.GravityWell;
import dragonbox.common.particlesystem.action.Move;
import dragonbox.common.particlesystem.action.ScaleChangeDynamic;
import dragonbox.common.particlesystem.action.ScaleChangeFixed;
import dragonbox.common.particlesystem.clock.SteadyClock;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.particlesystem.initializer.ColorInitializer;
import dragonbox.common.particlesystem.initializer.LifeTime;
import dragonbox.common.particlesystem.initializer.Position;
import dragonbox.common.particlesystem.initializer.ScaleInitializer;
import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
import dragonbox.common.particlesystem.initializer.VelocityInitializer;
import dragonbox.common.particlesystem.renderer.ParticleRenderer;
import dragonbox.common.particlesystem.zone.DiskSectionZone;
import dragonbox.common.particlesystem.zone.DiskZone;
import dragonbox.common.particlesystem.zone.PointZone;
import dragonbox.common.particlesystem.zone.RectangleZone;
import dragonbox.common.time.Time;

import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

/**
 * Testing application for how particles appear.
 */
class ParticleTest extends Sprite
{
    @:meta(Embed(source="/../assets/particles/particle_atlas.png"))

    public static var particle_atlas : Class<Dynamic>;
    @:meta(Embed(source="/../assets/particles/particle_atlas.xml",mimeType="application/octet-stream"))

    public static var particle_atlas_xml : Class<Dynamic>;
    
    private var m_time : Time;
    
    
    public function new()
    {
        super();
        
        if (this.stage == null) 
        {
            addEventListener(Event.ADDED_TO_STAGE, onStageInitialized);
        }
        else 
        {
            onStageInitialized(null);
        }
    }
    
    private var m_swirlEmitter : Emitter;
    private var m_swirlRenderer : ParticleRenderer;
    
    private var m_shimmerEmitter : Emitter;
    private var m_shimmerRenderer : ParticleRenderer;
    
    private var m_fireEmitter : Emitter;
    private var m_fireRenderer : ParticleRenderer;
    private function onStageInitialized(event : Event) : Void
    {
        //addChild(new Quad(800, 600, 0x000000));
        addChild(new Quad(800, 600, 0xFFFFFF));
        //addChild(new Quad(800, 600, 0xFFFFFF));
        
        m_time = new Time();
        
        var particleAtlasTexture : Texture = Texture.fromBitmap(Type.createInstance(particle_atlas, []));
        var particleAtlasXml : FastXML = new FastXML(Std.string(Type.createInstance(particle_atlas_xml, [])));
        
        var textureAtlas : TextureAtlas = new TextureAtlas(particleAtlasTexture, particleAtlasXml);
        textureAtlas.addRegion("all", new Rectangle(0, 0, particleAtlasTexture.width, particleAtlasTexture.height));
        
        var sourceTexture : Texture = textureAtlas.getTexture("all");
        var sourceBounds : Rectangle = textureAtlas.getRegion("all");
        var circleBounds : Rectangle = textureAtlas.getRegion("circle");
        var diamondBounds : Rectangle = textureAtlas.getRegion("diamond");
        var starBounds : Rectangle = textureAtlas.getRegion("star");
        
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
        
        var sourceBlendMode : String = Context3DBlendFactor.SOURCE_ALPHA;
        var destinationBlendMode : String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
        
        // Emitter for the dragonbox swirl animation
        var swirlEmitter : Emitter = new Emitter();
        swirlEmitter.addInitializer(new LifeTime(7, 3));
        swirlEmitter.addInitializer(new VelocityInitializer(new DiskZone(0, 0, 5, 0, 1)));
        swirlEmitter.addInitializer(new Position(new DiskZone(0, 0, 10, 5, 1)));
        swirlEmitter.addInitializer(new ColorInitializer(0x0000CC, 0x00CC00, true, 0xCC0000, 0xFF0000));
        swirlEmitter.addInitializer(new TextureUVInitializer([circleBounds], sourceBounds));
        
        swirlEmitter.addAction(new Age());
        swirlEmitter.addAction(new Move());
        swirlEmitter.addAction(new Fade(0.8, 0.2));
        swirlEmitter.addAction(new DragForce(3));
        swirlEmitter.addAction(new ColorChangeDynamic());
        swirlEmitter.addAction(new CentripetalForce(0, 0, 0, 100));
        
        swirlEmitter.setClock(new SteadyClock(5));
        swirlEmitter.start();
        m_swirlEmitter = swirlEmitter;
        
        var swirlRenderer : ParticleRenderer = new ParticleRenderer(sourceTexture);
        swirlRenderer.x = 300;
        swirlRenderer.y = 300;
        swirlRenderer.addEmitter(swirlEmitter);
        addChild(swirlRenderer);
        m_swirlRenderer = swirlRenderer;
        
        // Emitter for an area sparkle effect, use this to emphasize a block of text or
        // an image
        var shimmerEmitter : Emitter = new Emitter();
        shimmerEmitter.addInitializer(new LifeTime(3, 1));
        shimmerEmitter.addInitializer(new Position(new RectangleZone(0, 0, 800, 600)));
        shimmerEmitter.addInitializer(new ColorInitializer(0xdca9a8, 0xfeffae, false));
        shimmerEmitter.addInitializer(new ScaleInitializer(0.1, 0.3, true, 1.0, 2.0));
        shimmerEmitter.addInitializer(new TextureUVInitializer([diamondBounds, starBounds], sourceBounds));
        
        shimmerEmitter.addAction(new Age());
        //shimmerEmitter.addAction(new Fade(1.0, 0));
        shimmerEmitter.addAction(new ScaleChangeDynamic());
        
        shimmerEmitter.setClock(new SteadyClock(50));
        shimmerEmitter.start();
        m_shimmerEmitter = shimmerEmitter;
        
        var shimmerRenderer : ParticleRenderer = new ParticleRenderer(sourceTexture, sourceBlendMode, destinationBlendMode);
        shimmerRenderer.x = 0;
        shimmerRenderer.y = 0;
        shimmerRenderer.addEmitter(shimmerEmitter);
        addChild(shimmerRenderer);
        m_shimmerRenderer = shimmerRenderer;
        
        
        // Gravity emitter
        var gravityEmitter : Emitter = new Emitter();
        gravityEmitter.addInitializer(new ColorInitializer(0x0000FF, 0xFFFF00, false));
        gravityEmitter.addInitializer(new Position(new DiskZone(0, 0, 40, 10, 1)));
        gravityEmitter.addInitializer(new VelocityInitializer(new PointZone(50, 50)));
        gravityEmitter.addInitializer(new LifeTime(2, 20));
        gravityEmitter.addInitializer(new TextureUVInitializer([circleBounds], sourceBounds));
        
        gravityEmitter.addAction(new GravityWell(0, 0, 20, 100));
        
        // Fire emitter
        var fireEmitter : Emitter = new Emitter();
        fireEmitter.addInitializer(new LifeTime(3, 2));
        fireEmitter.addInitializer(new VelocityInitializer(new DiskSectionZone(0, 0, 20, 0, -Math.PI, 0)));
        fireEmitter.addInitializer(new Position(new DiskZone(0, 0, 3, 0, 1)));
        fireEmitter.addInitializer(new TextureUVInitializer([circleBounds], sourceBounds));
        
        fireEmitter.addAction(new Age());
        fireEmitter.addAction(new Move());
        fireEmitter.addAction(new DragForce(1.0));
        fireEmitter.addAction(new Accelerate(0, -40));
        fireEmitter.addAction(new ColorChangeFixed(0xFFCC00, 0xCC0000));
        fireEmitter.addAction(new Fade(1.0, 0));
        fireEmitter.addAction(new ScaleChangeFixed(1.5, 1.0));
        
        fireEmitter.setClock(new SteadyClock(10));
        fireEmitter.start();
        m_fireEmitter = fireEmitter;
        
        var fireRenderer : ParticleRenderer = new ParticleRenderer(sourceTexture, sourceBlendMode, destinationBlendMode);
        fireRenderer.x = 100;
        fireRenderer.y = 100;
        fireRenderer.addEmitter(fireEmitter);
        addChild(fireRenderer);
        m_fireRenderer = fireRenderer;
    }
    
    private function onEnterFrame(event : Event) : Void
    {
        m_time.update();
        var secondsElapsed : Float = m_time.currentDeltaSeconds;
        m_swirlEmitter.update(secondsElapsed);
        m_swirlRenderer.update();
        m_fireEmitter.update(secondsElapsed);
        m_fireRenderer.update();
        m_shimmerEmitter.update(secondsElapsed);
        m_shimmerRenderer.update();
    }
}
