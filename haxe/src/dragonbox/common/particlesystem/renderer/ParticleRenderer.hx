package dragonbox.common.particlesystem.renderer;

//import dragonbox.common.particlesystem.renderer.SHADER;

import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.emitter.Emitter;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.errors.MissingContextError;
import starling.events.Event;
import starling.extensions.CleanAgalMiniAssembler;
import starling.textures.Texture;
import starling.utils.MatrixUtil;
import starling.utils.VertexData;

/**
 * The renderer accepts some number of emitters and draws them on the display.
 * 
 * It links into the starling renderer logic to draw the particles.
 * 
 * MUST FIX:
 * For some reason all particles are smaller than the original texture that was passed in
 * Something seems wrong with the mvp matrix in the render function
 */
class ParticleRenderer extends DisplayObject
{
    @:meta(Embed(source="/../assets/shaders/particle.agal",mimeType="application/octet-stream"))

    private static var SHADER : Class<Dynamic>;
    
    /**
     * List of particle emitters to be drawn
     */
    private var m_emitters : Array<Emitter>;
    
    /**
     * Storage used to mark all vertices for every particle in
     * the emitters set to this renderer. This will dynamically grow with the number of
     * particles to render.
     * 
     * Every particle is represented as a billboard quad that requires
     * four vertices
     * 
     * (x,y) (r,g,b,a) (u,v)
     */
    private var m_vertexData : VertexData;
    
    /**
     * Vertex buffer needed by stage3d
     * 
     * This is a fixed size buffer that needs to be recreated each time the number
     * of particles to draw changes
     */
    private var m_vertexBuffer : VertexBuffer3D;
    
    /**
     * Storage used to group together all vertices that form a particle.
     * This will dynamically grow with the number of particles to draw
     * 
     * Each particle is formed by six indices, each triplet forms half of
     * the quad
     */
    private var m_indexData : Vector<Int>;
    
    /**
     * Index buffer needed by stage3d
     * 
     * This is a fixed size buffer that needs to be recreated each time the number
     * of particles to draw changes
     */
    private var m_indexBuffer : IndexBuffer3D;
    
    /**
     * Our custom shader used to render the particles for the emitters
     * 
     */
    private var m_shaderProgram : Program3D;
    
    /**
     * The total number of particles that need to be rendered at any given point
     * in time. This will allow the stage3d buffer to sample only the active portions
     * of our persistent vertex and index buffers.
     */
    private var m_numParticlesToRender : Int;
    
    private var m_alpha : Vector<Float>;
    private var m_sourceBlendMode : String;
    private var m_destinationBlendMode : String;
    
    /**
     * The source texture is where all particles will sample their data from. This requires a
     * particle to store the appropriate u,v coordinates. This is to facilitate a single renderer
     * being able to sample from several different textures at once
     * 
     * The source can take several values depending on the type of particle to generate:
     * -If we want a single renderer to draw several different textures, this texture needs
     * to be the a texture atlas.
     * -If we are sure the renderer only needs a single texture, just use that texture. However, if
     * we are using starling texture atlases to pack together the particle images this method is pratically the
     * same as the method above and Stage3d will end up loading the entire atlas anyway during rendering
     * -If we want to use a shatter or fragmentation animation this a
     * drawn copy of a starling display object.
     */
    private var m_sourceTexture : Texture;
    
    /**
     * View this page for more information on blend modes:
     * http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display3D/Context3DBlendFactor.html
     */
    public function new(sourceTexture : Texture,
            sourceBlendMode : String = null,
            destinationBlendMode : String = null)
    {
        super();
        
        m_emitters = new Array<Emitter>();
        m_sourceTexture = sourceTexture;
        
        m_vertexData = new VertexData(0);
        m_indexData = new Vector<Int>();
        m_numParticlesToRender = -1;
		
		m_alpha = new Vector<Float>(4);
		for (i in 0...4) m_alpha[i] = 1.0;
        
        this.touchable = false;
        
        // Compile the shader program
        this.registerShaderPrograms();
        
        // Need to perform a dummy update in order to initialize the stage3d buffers before any possible
        // call to render can be made
        this.update();
        
        // By default we will choose a blend mode that takes into account the alpha in
        // a texture
        m_destinationBlendMode = destinationBlendMode != null ? destinationBlendMode : Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
        m_sourceBlendMode = sourceBlendMode != null ? sourceBlendMode : 
                ((sourceTexture.premultipliedAlpha) ? Context3DBlendFactor.ONE : Context3DBlendFactor.SOURCE_ALPHA);
        
        // handle a lost device context
        Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
                onContextCreated, false, 0, true);
    }
    
    override public function dispose() : Void
    {
        Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        
        if (m_vertexBuffer != null) 
        {
            m_vertexBuffer.dispose();
        }
        
        if (m_indexBuffer != null) 
        {
            m_indexBuffer.dispose();
        }
        
        super.dispose();
    }
    
    private function onContextCreated(event : Dynamic) : Void
    {
        this.registerShaderPrograms();
        this.update();
    }
    
    /**
     * Add a particle emitter, this is the only was for particles to be drawn
     */
    public function addEmitter(emitter : Emitter) : Void
    {
        m_emitters.push(emitter);
    }
    
    public function removeAndDisposeAllEmitters() : Void
    {
        while (m_emitters.length > 0)
        {
            var emitter : Emitter = m_emitters.pop();
            emitter.dispose();
        }
    }
    
    /**
     * Refresh the vertex information for the system by looking at current particle
     * state of each emitter.
     * 
     */
    private var uvCoordinateBuffer : VertexData = new VertexData(4, false);
    public function update() : Void
    {
        // Look at the list of particles, based on their properties we will
        // need to update the vertex data. This will need to take into
        // account dead and new particles but comparing the length of the
        // particle list with the length of the vertext list
        // Note each particle requires 4 vertices
        // It also requires 6 indices for the two triangles forming the quad
        var numParticlesProcessed : Int = 0;
        var vertexId : Int = 0;
        var indexId : Int = 0;
        var x : Float;
        var y : Float;
        var xOffset : Float;
        var yOffset : Float;
        var rotation : Float;
        var scale : Float;
        var color : Int;
        var alpha : Float;
        var i : Int;
        var numEmitters : Int = m_emitters.length;
        var numSpacesForParticles : Int = Std.int(m_vertexData.numVertices / 4);
        for (i in 0...numEmitters){
            // To get the number of particles to render, add up the limits from each emitter
            
            var emitter : Emitter = m_emitters[i];
            var particles : Array<Particle> = emitter.getParticles();
            var limit : Int = emitter.getParticleLimit();
            for (j in 0...limit){
                numParticlesProcessed++;
                var particle : Particle = particles[j];
                x = particle.xPosition;
                y = particle.yPosition;
                color = particle.color;
                alpha = particle.alpha;
                scale = particle.scale;
                rotation = particle.rotation;
                
                // The vertex data does not dynamically grow so whenever we run out of
                // space we need to allocate new space by appending a new quad.
                if (numParticlesProcessed > numSpacesForParticles) 
                {
                    // This also sets the texture coordinates for each particle
                    m_vertexData.append(uvCoordinateBuffer);
                }  // to know what the texture to use is    // vertex relative to the center point. Need    // Need to calculate the x and y offset of each  
                
                
                
                
                
                
                
                xOffset = particle.textureWidthPixels * scale / 2;
                yOffset = particle.textureHeightPixels * scale / 2;
                
                // Set a uniform color and alpha for each particle
                for (k in 0...4){
                    m_vertexData.setColor(vertexId + k, color);
                    m_vertexData.setAlpha(vertexId + k, alpha);
                }  // However, it does need to be updated    // We assume that the texture to sample for a particle will not change over time    // Set the texture data for each particle  
                
                
                
                
                
                
                
                m_vertexData.setTexCoords(vertexId, particle.textureLeftU, particle.textureTopV);
                m_vertexData.setTexCoords(vertexId + 1, particle.textureLeftU + particle.textureWidthUV, particle.textureTopV);
                m_vertexData.setTexCoords(vertexId + 2, particle.textureLeftU, particle.textureTopV + particle.textureHeightUV);
                m_vertexData.setTexCoords(vertexId + 3, particle.textureLeftU + particle.textureWidthUV, particle.textureTopV + particle.textureHeightUV);
                
                // ??? For some reasons textures do not project correctly, need to call this to correct it
                // The primary issue is that all textures are smaller than the source even without adjusting the scale
                m_sourceTexture.adjustVertexData(m_vertexData, vertexId, 4);
                
                // Set the index data
                // (note that this vector autmatically grows)
                m_indexData.fixed = false;
                m_indexData[indexId] = vertexId;
                m_indexData[indexId + 1] = vertexId + 1;
                m_indexData[indexId + 2] = vertexId + 2;
                m_indexData[indexId + 3] = vertexId + 1;
                m_indexData[indexId + 4] = vertexId + 3;
                m_indexData[indexId + 5] = vertexId + 2;
                m_indexData.fixed = true;
                indexId += 6;
                
                if (rotation == 0) 
                {
                    // Set the position for each particle
                    var leftX : Float = x - xOffset;
                    var topY : Float = y - yOffset;
                    var rightX : Float = x + xOffset;
                    var bottomY : Float = y + yOffset;
                    m_vertexData.setPosition(vertexId, leftX, topY);
                    m_vertexData.setPosition(vertexId + 1, rightX, topY);
                    m_vertexData.setPosition(vertexId + 2, leftX, bottomY);
                    m_vertexData.setPosition(vertexId + 3, rightX, bottomY);
                }
                else 
                {
                    var cos : Float = Math.cos(rotation);
                    var sin : Float = Math.sin(rotation);
                    var cosX : Float = cos * xOffset;
                    var cosY : Float = cos * yOffset;
                    var sinX : Float = sin * xOffset;
                    var sinY : Float = sin * yOffset;
                    
                    m_vertexData.setPosition(vertexId, x - cosX + sinY, y - sinX - cosY);
                    m_vertexData.setPosition(vertexId + 1, x + cosX + sinY, y + sinX - cosY);
                    m_vertexData.setPosition(vertexId + 2, x - cosX - sinY, y - sinX + cosY);
                    m_vertexData.setPosition(vertexId + 3, x + cosX - sinY, y + sinX + cosY);
                }
                vertexId += 4;
            }
        }  // last update.    // We need to create new buffers if the number of particles to draw has changed since the  
        
        
        
        
        
        if (m_numParticlesToRender != numParticlesProcessed) 
        {
            m_numParticlesToRender = numParticlesProcessed;
            
            if (m_vertexBuffer != null) 
            {
                m_vertexBuffer.dispose();
            }
            
            if (m_indexBuffer != null) 
            {
                m_indexBuffer.dispose();
            }
            
            if (m_numParticlesToRender > 0) 
            {
                var context3d : Context3D = Starling.current.context;
                m_vertexBuffer = context3d.createVertexBuffer(numParticlesProcessed * 4, VertexData.ELEMENTS_PER_VERTEX);
                m_indexBuffer = context3d.createIndexBuffer(numParticlesProcessed * 6);
            }
        }
    }
    
    /**
     * We don't bother getting the actual bounds
     */
    override public function getBounds(targetSpace : DisplayObject,
            resultRect : Rectangle = null) : Rectangle
    {
        if (resultRect == null)             resultRect = new Rectangle();
        
        var helperMatrix : Matrix = new Matrix();
        var helperPoint : Point = new Point();
        getTransformationMatrix(targetSpace, helperMatrix);
        MatrixUtil.transformCoords(helperMatrix, 0, 0, helperPoint);
        
        resultRect.x = helperPoint.x;
        resultRect.y = helperPoint.y;
        resultRect.width = resultRect.height = 0;
        
        return resultRect;
    }
    
    private var hackTextureOffset : Array<Float> = [0.4, 0.4, 0.4, 0.0];
    override public function render(support : RenderSupport, parentAlpha : Float) : Void
    {
        if (m_numParticlesToRender <= 0) 
        {
            return;
        }
        
        support.finishQuadBatch();
        support.raiseDrawCount();
        
        var context3d : Context3D = Starling.current.context;
        if (context3d == null) 
        {
            throw new MissingContextError();
        }
        
        parentAlpha *= this.alpha;
        var usePremultipliedAlpha : Bool = m_sourceTexture.premultipliedAlpha;
        m_alpha[0] = m_alpha[1] = m_alpha[2] = (((usePremultipliedAlpha)) ? parentAlpha : 1.0);
        m_alpha[3] = parentAlpha;
        
        // Upload the vertices, 4 per total number of particles to render
        m_vertexBuffer.uploadFromVector(m_vertexData.rawData, 0, m_numParticlesToRender * 4);
        
        // Upload indices forming the quads per particle, 6 indices are required each
        m_indexBuffer.uploadFromVector(m_indexData, 0, m_numParticlesToRender * 6);
        
        // Set the shader program to use
        context3d.setProgram(m_shaderProgram);
        
        // Apply blending
        // Very important, choosing the correct blend function
        context3d.setBlendFactors(m_sourceBlendMode, m_destinationBlendMode);
        
        // Set the textures to use within the registers, all particles must sample
        // from the source
        context3d.setTextureAt(0, m_sourceTexture.base);
        
        // Set the vertex information, which includes
        // position
        // color
        // texture (u,v) coordinates
        context3d.setVertexBufferAt(0, m_vertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
        context3d.setVertexBufferAt(1, m_vertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
        context3d.setVertexBufferAt(2, m_vertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
        
        // TODO: For some reason this will shrink the particle
        // Set the proper transformation matrix for the vertex shader
        var matrix : Matrix3D = support.mvpMatrix3D;
        context3d.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
        
        // Set alpha multiplier
        context3d.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, m_alpha, 1);
        
        // HACK:
        // This is stupid, when blending a dark hue is always applied when using blend mode source_alpha+(1-source_alpha)
        //context3d.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, hackTextureOffset, 1);
        
        // Draw two triangles forming the quad per particle
        context3d.drawTriangles(m_indexBuffer, 0, m_numParticlesToRender * 2);
        
        // Clear the registers
        context3d.setTextureAt(0, null);
        context3d.setVertexBufferAt(0, null);
        context3d.setVertexBufferAt(1, null);
        context3d.setVertexBufferAt(2, null);
    }
    
    private function registerShaderPrograms() : Void
    {
        var programName : String = "dragonbox.particles";
        var starlingTarget : Starling = Starling.current;
        if (!starlingTarget.hasProgram(programName)) 
        {
            var assembler : CleanAgalMiniAssembler = new CleanAgalMiniAssembler();
            
            var shaderRaw : ByteArray = try cast(Type.createInstance(SHADER, []), ByteArray) catch(e:Dynamic) null;
            var programBytes : Array<Dynamic> = assembler.getProgramBytesFromString(Std.string(shaderRaw));
            
            starlingTarget.registerProgram(programName, programBytes[0], programBytes[1]);
        }
        
        m_shaderProgram = starlingTarget.getProgram(programName);
    }
}
