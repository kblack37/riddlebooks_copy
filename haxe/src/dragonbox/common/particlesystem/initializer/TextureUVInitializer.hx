package dragonbox.common.particlesystem.initializer;


import flash.geom.Rectangle;

import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Initializes the uv coordinates of a particle. Most useful to assign several different textures
 * to a single emitter.
 * 
 * Every emitter must have this initializer set
 */
class TextureUVInitializer extends Initializer
{
    private var m_textureWidthsPixels : Array<Float>;
    private var m_textureHeightsPixels : Array<Float>;
    private var m_textureTopsV : Array<Float>;
    private var m_textureLeftsU : Array<Float>;
    private var m_textureWidthsUV : Array<Float>;
    private var m_textureHeightsUV : Array<Float>;
    
    /**
     * The parameters for this constructor are very specific. The renderer keeps track of one
     * large texture that holds every subtexture that can be drawn for that renderer. Each particle
     * must be assigned areas of the large texture from it will sample from.
     * 
     * @param textureRegion
     *      A list of region which will indicate the potential texture sampling coordinates
     *      that a particle can use
     * @param textureRegionSource
     *      This is the main rectangular texture region from which the list of
     *      texture regions are sampled from. Its x,y should be at 0,0 and it should
     *      contain completely contain all texture regions in the list
     */
    public function new(textureRegions : Array<Rectangle>,
            textureSourceRegion : Rectangle)
    {
        super();
        
        m_textureWidthsPixels = new Array<Float>();
        m_textureHeightsPixels = new Array<Float>();
        m_textureTopsV = new Array<Float>();
        m_textureLeftsU = new Array<Float>();
        m_textureWidthsUV = new Array<Float>();
        m_textureHeightsUV = new Array<Float>();
        
        // Convert each texture region to a set of uv coordinates
        var i : Int = 0;
        var region : Rectangle = null;
        var sourceWidth : Float = textureSourceRegion.width;
        var sourceHeight : Float = textureSourceRegion.height;
        for (i in 0...textureRegions.length){
            region = textureRegions[i];
            m_textureWidthsPixels.push(region.width);
            m_textureHeightsPixels.push(region.height);
            m_textureTopsV.push(region.y / sourceHeight);
            m_textureLeftsU.push(region.x / sourceWidth);
            m_textureWidthsUV.push(region.width / sourceWidth);
            m_textureHeightsUV.push(region.height / sourceHeight);
        }
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        var chosenTextureIndex : Int = 0;
        var numTextures : Int = m_textureTopsV.length;
        if (numTextures > 1) 
        {
            chosenTextureIndex = Math.floor(Math.random() * numTextures);
        }
        
        particle.textureHeightPixels = m_textureHeightsPixels[chosenTextureIndex];
        particle.textureWidthPixels = m_textureWidthsPixels[chosenTextureIndex];
        particle.textureLeftU = m_textureLeftsU[chosenTextureIndex];
        particle.textureTopV = m_textureTopsV[chosenTextureIndex];
        particle.textureHeightUV = m_textureHeightsUV[chosenTextureIndex];
        particle.textureWidthUV = m_textureWidthsUV[chosenTextureIndex];
    }
}
