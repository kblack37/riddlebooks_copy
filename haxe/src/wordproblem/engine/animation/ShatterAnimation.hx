package wordproblem.engine.animation;


import flash.display3d.Context3DBlendFactor;
import flash.geom.Rectangle;

import dragonbox.common.particlesystem.action.Accelerate;
import dragonbox.common.particlesystem.action.Age;
import dragonbox.common.particlesystem.action.DragForce;
import dragonbox.common.particlesystem.action.Fade;
import dragonbox.common.particlesystem.action.Move;
import dragonbox.common.particlesystem.action.Rotate;
import dragonbox.common.particlesystem.clock.BlastClock;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.particlesystem.initializer.LifeTime;
import dragonbox.common.particlesystem.initializer.RotationVelocity;
import dragonbox.common.particlesystem.initializer.TextureGridInitializer;
import dragonbox.common.particlesystem.initializer.VelocityInitializer;
import dragonbox.common.particlesystem.renderer.ParticleRenderer;
import dragonbox.common.particlesystem.zone.DiskZone;

import starling.animation.IAnimatable;
import starling.animation.Juggler;
import starling.core.Starling;
import starling.display.DisplayObjectContainer;
import starling.textures.Texture;

/**
 * Take an display object and break it down into several square pieces
 */
class ShatterAnimation implements IAnimatable
{
    public var activeTexture : Texture;
    private var m_emitter : Emitter;
    private var m_particleRenderer : ParticleRenderer;
    
    /**
     * Total seconds the animation should last
     */
    private var m_shatterDuration : Float;
    private var m_totalTimeElapsedSincePlay : Float = 0;
    
    /**
     * Accepts single parameters that is this entire ShatterAnimation object
     */
    private var m_completeCallback : Function;
    
    private var m_juggler : Juggler;
    
    public function new(renderTexture : Texture,
            completeCallback : Function,
            maxDurationSeconds : Float)
    {
        this.activeTexture = renderTexture;
        
        // Determine size of each broken piece, equal sized pieces are preferred for simplicity
        var drawnObjectWidth : Float = renderTexture.width;
        var drawnObjectHeight : Float = renderTexture.height;
        m_shatterDuration = maxDurationSeconds;
        
        var numColumns : Int = Math.ceil(drawnObjectWidth / 4.0);
        var numRows : Int = Math.ceil(drawnObjectHeight / 4.0);
        m_emitter = new Emitter();
        m_emitter.addInitializer(new TextureGridInitializer(numColumns, numRows, new Rectangle(0, 0, drawnObjectWidth, drawnObjectHeight)));
        m_emitter.addInitializer(new VelocityInitializer(new DiskZone(0, 0, 90, 70, 1)));
        m_emitter.addInitializer(new RotationVelocity(0.5, Math.PI * 0.5));
        m_emitter.addInitializer(new LifeTime(maxDurationSeconds, maxDurationSeconds * 0.5));
        m_emitter.addAction(new Age(easeInExpo));
        m_emitter.addAction(new Accelerate(0, 50));
        m_emitter.addAction(new DragForce(0.3));
        m_emitter.addAction(new Move());
        m_emitter.addAction(new Rotate());
        m_emitter.addAction(new Fade(0.8, 0));
        
        m_emitter.setClock(new BlastClock(numColumns * numRows));
        
        m_particleRenderer = new ParticleRenderer(renderTexture, Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
        m_particleRenderer.addEmitter(m_emitter);
        
        m_completeCallback = completeCallback;
    }
    
    public function advanceTime(time : Float) : Void
    {
        m_emitter.update(time);
        m_particleRenderer.update();
        
        // After some duration make sure to signal the completion
        m_totalTimeElapsedSincePlay += time;
        if (m_totalTimeElapsedSincePlay > m_shatterDuration) 
        {
            m_particleRenderer.removeFromParent();
            m_juggler.remove(this);
            if (m_completeCallback != null) 
            {
                m_completeCallback(this);
            }
        }
    }
    
    public function play(canvasToAddTo : DisplayObjectContainer, x : Float, y : Float, juggler : Juggler = null) : Void
    {
        if (juggler == null) 
        {
            juggler = Starling.juggler;
        }
        
        m_juggler = juggler;
        m_particleRenderer.x = x;
        m_particleRenderer.y = y;
        canvasToAddTo.addChild(m_particleRenderer);
        m_juggler.add(this);
        m_emitter.start();
    }
    
    public function dispose() : Void
    {
        m_emitter.dispose();
        m_particleRenderer.removeFromParent(true);
    }
    
    /**
     * Computes the alpha of a particle in the animation. Essentially defines when particles will individually fade out, and how fast,
     * defined by an exponential curve (as opposed to a linear one).
     * @param    t    Total lifetime
     * @param    d    Current time
     * @return
     */
    private function easeInExpo(t : Float, d : Float) : Float
    {
        return 1 - Math.pow(2, 10 * (t / d - 1));
    }
}
