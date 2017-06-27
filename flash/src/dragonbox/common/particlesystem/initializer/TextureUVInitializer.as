package dragonbox.common.particlesystem.initializer
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.particlesystem.Particle;
    import dragonbox.common.particlesystem.emitter.Emitter;

    /**
     * Initializes the uv coordinates of a particle. Most useful to assign several different textures
     * to a single emitter.
     * 
     * Every emitter must have this initializer set
     */
    public class TextureUVInitializer extends Initializer
    {
        private var m_textureWidthsPixels:Vector.<Number>;
        private var m_textureHeightsPixels:Vector.<Number>;
        private var m_textureTopsV:Vector.<Number>;
        private var m_textureLeftsU:Vector.<Number>;
        private var m_textureWidthsUV:Vector.<Number>;
        private var m_textureHeightsUV:Vector.<Number>;
        
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
        public function TextureUVInitializer(textureRegions:Vector.<Rectangle>, 
                                             textureSourceRegion:Rectangle)
        {
            super();
            
            m_textureWidthsPixels = new Vector.<Number>();
            m_textureHeightsPixels = new Vector.<Number>();
            m_textureTopsV = new Vector.<Number>();
            m_textureLeftsU = new Vector.<Number>();
            m_textureWidthsUV = new Vector.<Number>();
            m_textureHeightsUV = new Vector.<Number>();
            
            // Convert each texture region to a set of uv coordinates
            var i:int;
            var region:Rectangle;
            const sourceWidth:Number = textureSourceRegion.width;
            const sourceHeight:Number = textureSourceRegion.height;
            for (i = 0; i < textureRegions.length; i++)
            {
                region = textureRegions[i];
                m_textureWidthsPixels.push(region.width);
                m_textureHeightsPixels.push(region.height);
                m_textureTopsV.push(region.y / sourceHeight);
                m_textureLeftsU.push(region.x / sourceWidth);
                m_textureWidthsUV.push(region.width / sourceWidth);
                m_textureHeightsUV.push(region.height / sourceHeight);
            }
        }
        
        override public function initialize(emitter:Emitter, particle:Particle):void
        {
            var chosenTextureIndex:int = 0;
            const numTextures:int = m_textureTopsV.length;
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
}