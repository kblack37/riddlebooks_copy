package dragonbox.common.particlesystem.initializer;


import flash.geom.Rectangle;

import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

/**
 * Initializer takes an existing texture and segments it into several small
 * squares, each of which represents a particle.
 * 
 * The initializer needs to have each particle take in the appropriate uv coordinates
 * and cartesian coordinates. This replaces the TextureUVInitializer
 */
class TextureGridInitializer extends Initializer
{
    /**
     * Maximum number of columns to break the texture into
     */
    private var m_columns : Int;
    
    /**
     * Maximum number of rows to break the texture into
     */
    private var m_rows : Int;
    
    /**
     * Get the height and width of a single particle
     */
    private var m_particleBounds : Rectangle;
    
    /**
     * We need to remember the specific place where each particle is located.
     * Assuming particles are initialized sequentially, this will help figure out
     * the starting values of the next particle.
     * 
     * The max index is (rows*columns)-1
     */
    private var m_particleIndex : Int;
    
    /**
     *
     * @param columns
     * @param rows
     * @param textureBounds
     *      The bounding dimension of the texture to be segmented, it is in pixel dimensions
     */
    public function new(columns : Int, rows : Int, textureBounds : Rectangle)
    {
        super();
        
        m_columns = columns;
        m_rows = rows;
        m_particleIndex = 0;
        
        var particleWidth : Float = textureBounds.width / columns;
        var particleHeight : Float = textureBounds.height / rows;
        m_particleBounds = new Rectangle(0, 0, particleWidth, particleHeight);
    }
    
    override public function initialize(emitter : Emitter, particle : Particle) : Void
    {
        var columnIndex : Int = m_particleIndex % m_columns;
        particle.xPosition = m_particleBounds.width * columnIndex;
        particle.textureWidthPixels = m_particleBounds.width;
        particle.textureWidthUV = 1.0 / m_columns;
        particle.textureLeftU = columnIndex * particle.textureWidthUV;
        
        var rowIndex : Int = m_particleIndex / m_columns;
        particle.yPosition = m_particleBounds.height * rowIndex;
        particle.textureHeightPixels = m_particleBounds.height;
        particle.textureHeightUV = 1.0 / m_rows;
        particle.textureTopV = rowIndex * particle.textureHeightUV;
        m_particleIndex++;
    }
}
