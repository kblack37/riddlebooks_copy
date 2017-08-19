package wordproblem.engine.animation;


import flash.display3d.Context3DBlendFactor;
import flash.geom.Rectangle;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.particlesystem.action.Age;
import dragonbox.common.particlesystem.action.Fade;
import dragonbox.common.particlesystem.clock.SteadyClock;
import dragonbox.common.particlesystem.emitter.Emitter;
import dragonbox.common.particlesystem.initializer.ColorInitializer;
import dragonbox.common.particlesystem.initializer.Initializer;
import dragonbox.common.particlesystem.initializer.LifeTime;
import dragonbox.common.particlesystem.initializer.Position;
import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
import dragonbox.common.particlesystem.renderer.ParticleRenderer;
import dragonbox.common.particlesystem.zone.LineZone;

import starling.animation.IAnimatable;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Sprite;
import starling.textures.Texture;
import starling.textures.TextureAtlas;
import wordproblem.resource.AssetManager;

import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.resource.Resources;

/**
 * Animation to gradually reveal an obect behind a mask.
 * 
 */
class RevealTextAnimation implements IAnimatable implements IDisposable
{
    /**
     * The rect that determines how much of the text content is visible, the changes in its properties
     * determine what part of the content is visible.
     */
    private var m_clippingRectangle : Rectangle;
    
    /**
     * These are the limits of the view port to reveal. The clipping rect should not exceed
     * the width of this rect while the animation is playing.
     */
    private var m_maxRevealBounds : Rectangle;
    
    private var m_textAreaWidget : TextAreaWidget;
    
    private var m_emitter : Emitter;
    private var m_particleRenderer : ParticleRenderer;
    
    /**
     * A nested animation that controls the width of the mask over the text content
     */
    private var m_revealTween : Tween;
    
    /**
     * Number of pixels per second the reveal should move at
     */
    private var m_revealVelocity : Float = 500;
    
    public function new(textAreaWidget : TextAreaWidget, assetManager : AssetManager)
    {
        m_textAreaWidget = textAreaWidget;
        
        var particleAtlas : TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
        var sourceTexture : Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
        var sourceBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
        var diamondBounds : Rectangle = particleAtlas.getRegion(Resources.PARTICLE_CIRCLE);
        var textureInitializer : Initializer = new TextureUVInitializer([diamondBounds], sourceBounds);
        
        m_emitter = new Emitter();
        m_emitter.addInitializer(new ColorInitializer(0x0, 0x0, false));
        m_emitter.addInitializer(new LifeTime(1.0, 1.0));
        m_emitter.addInitializer(textureInitializer);
        m_emitter.addInitializer(new Position(new LineZone(0, 0, 0, 0)));
        m_emitter.addAction(new Fade(1.0, 0.0));
        m_emitter.addAction(new Age());
        m_emitter.setClock(new SteadyClock(50));
        
        var sourceBlendMode : String = Context3DBlendFactor.SOURCE_ALPHA;
        var destinationBlendMode : String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
        m_particleRenderer = new ParticleRenderer(sourceTexture, sourceBlendMode, destinationBlendMode);
        m_particleRenderer.addEmitter(m_emitter);
    }
    
    public function play(idOfViewToReveal : String) : Void
    {
        var viewsToReveal : Array<DocumentView> = m_textAreaWidget.getDocumentViewsAtPageIndexById(idOfViewToReveal);
        if (viewsToReveal.length > 0) 
        {
            // TODO: Only revealing the first one
            var viewToReveal : DocumentView = viewsToReveal[0];
            
            // Make sure the view is visible and added to the display list
            viewToReveal.node.setIsVisible(true);
            if (viewToReveal.parent == null) 
            {
                viewToReveal.parentView.addChild(viewToReveal);
                m_textAreaWidget.setBottomScrollLimit();
            }  // the parameters of the animation    // Get the covering bounds of the view in local coordinate, this determines  
            
            
            
            
            
            var viewLocalBounds : Rectangle = viewToReveal.getBounds(viewToReveal);
            m_maxRevealBounds = viewLocalBounds;
            
            // The mask starts at the left most edge with no width and gradually expands to the right edge
            var clippingRectangle : Rectangle = new Rectangle(viewLocalBounds.x, viewLocalBounds.y, 0, viewLocalBounds.height);
            var revealTween : Tween = new Tween(clippingRectangle, viewLocalBounds.width / m_revealVelocity);
            revealTween.animate("width", viewLocalBounds.width);
            revealTween.onUpdate = function() : Void
                    {
                        viewToReveal.clipRect = m_clippingRectangle;
                        
                        m_particleRenderer.x = m_clippingRectangle.right + viewToReveal.x;
                    };
            
            revealTween.onComplete = function() : Void
                    {
                        // Remove the mask at the end
                        viewToReveal.clipRect = null;
                    };
            m_revealTween = revealTween;
            m_clippingRectangle = clippingRectangle;
            
            // Start up the particle scrubber
            var position : Position = try cast(m_emitter.getInitializer(Position), Position) catch(e:Dynamic) null;
            var lineZone : LineZone = try cast(position.getZone(), LineZone) catch(e:Dynamic) null;
            lineZone.reset(0, 0, 0, viewLocalBounds.height);
            m_emitter.start();
            
            // Renderer should get added to the parent view so it does not get masked
            m_particleRenderer.x = viewLocalBounds.x + viewToReveal.x;
            m_particleRenderer.y = viewLocalBounds.y + viewToReveal.y;
            viewToReveal.parentView.addChild(m_particleRenderer);
            
            Starling.juggler.add(this);
        }
    }
    
    public function stop() : Void
    {
    }
    
    public function advanceTime(time : Float) : Void
    {
        // On every call to advance time we progress both the particle scrubber and the mask tween.
        m_revealTween.advanceTime(time);
        
        m_emitter.update(time);
        m_particleRenderer.update();
        
        // Stop the animation once the scrubber has reached the end of the bounds
        if (m_clippingRectangle.right + 0.01 >= m_maxRevealBounds.right) 
        {
            Starling.juggler.remove(this);
            m_emitter.reset();
            if (m_particleRenderer.parent != null) m_particleRenderer.parent.removeChild(m_particleRenderer);
        }
    }
    
    public function dispose() : Void
    {
    }
}
