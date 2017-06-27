package dragonbox.common.display
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.errors.MissingContextError;
    import starling.extensions.CleanAgalMiniAssembler;
    import starling.textures.Texture;
    import starling.utils.VertexData;
    
    /**
     * This class defines a trapezoidal shape (at least one pair of parellel side) and
     * attempts to map a texture to this shape with minimized distortion.
     * 
     * We will also just have two triangles defined by 6 vertices
     * Look at the Starling Quad class to see the numbering of the corners, the first
     * triangle is the top one, the second is the bottom.
     * 
     * 
     * Used this link to help with the uv mapping
     * http://northwaygames.com/drawing-a-trapezoid-with-stage3d/
     */
    public class TrapezoidalImage extends DisplayObject
    {
        [Embed(source="/../assets/shaders/trapezoid.agal",mimeType="application/octet-stream")]
        private static const SHADER:Class;
        
        private const NUM_VERTICES:int = 4;
        
        private const VALUES_PER_VERTEX:int = 5;
        
        /**
         * The starling texture to be mapped on top of this shape.
         */
        private var m_originalTexture:Texture;
        
        /**
         * Raw vertex information
         * 
         * Each vertex will have values for
         * x, y (position)
         * u, v (texture coordinates)
         * p (perspective ratio, the difference in height between left and right)
         */
        private var m_vertices:Vector.<Number>;
        
        /**
         * The trapezoid has 4 vertices, which form two triangles.
         * We store the list of vertex indices that defines these triangles.
         */
        private var m_indices:Vector.<uint>;
        
        /**
         * The buffer used by Stage3D to properly render the scene
         */
        private var m_vertexBuffer:VertexBuffer3D;
        
        /**
         * The buffer used by Stage3D
         */
        private var m_indexBuffer:IndexBuffer3D;
        
        /**
         * The shader to render the image.
         */
        private var m_shaderProgram:Program3D;
        
        public function TrapezoidalImage(texture:Texture)
        {
            super();
            
            // Set initial values for the for vertices in each triangle
            // Note that the vertices will always map to the corners of uv map
            m_vertices = new Vector.<Number>();
            // Top triangle
            m_vertices.push(
                0, 0, 0, 0, 0,
                0, 0, 1, 0, 0,
                0, 0, 0, 1, 0
            );
            // Bottom triangle
            m_vertices.push(
                0, 0, 1, 1, 0//,
                //0, 0, 0, 1.0, 0,
                //0, 0, 1.0, 1.0, 0
            );
            
            // Defines the two triangles of the trapezoid
            m_indices = new Vector.<uint>();
            m_indices.push(0, 1, 2);
            m_indices.push(3, 1, 2);
            
            // Need to create Stage3D buffers
            // Since this trapezoid will always have a fixed number of vertices we can
            // create the buffer space at the very start
            const context3d:Context3D = Starling.context;
            m_vertexBuffer = context3d.createVertexBuffer(NUM_VERTICES, VALUES_PER_VERTEX);
            m_indexBuffer = context3d.createIndexBuffer(6);
            
            m_originalTexture = texture;
            
            this.registerShaderPrograms();
           
            const dim:Number = 200;
            this.setVertexPosition(0, 0, 0);
            this.setVertexPosition(1, dim, 0);
            this.setVertexPosition(2, 0, dim);
            
            this.setVertexPosition(3, dim, dim*2);
            //this.setVertexPosition(4, dim, 0);
            //this.setVertexPosition(5, dim, dim);
            
        }
        
        override public function render(support:RenderSupport, 
                                        parentAlpha:Number):void
        {
            support.finishQuadBatch();
            support.raiseDrawCount();
            
            const context3d:Context3D = Starling.context;
            if (context3d == null)
            {
                throw new MissingContextError();
            }
            
            m_vertexBuffer.uploadFromVector(m_vertices, 0, NUM_VERTICES);
            m_indexBuffer.uploadFromVector(m_indices, 0, 6);
            
            context3d.setProgram(m_shaderProgram);
            
            // Apply blending
            // Very important, choosing the correct blend function
            //context3d.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
            support.applyBlendMode(false);
            
            // The positions of the vertex are at the first numbers, put them in the first vertex attribute register
            context3d.setVertexBufferAt(0, m_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
            
            // The uv coordinates are the next two numbers after the position, put them in the second vertex attribute register
            context3d.setVertexBufferAt(1, m_vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_3);
            
            // The perspective value is the next number after the uv, put them in the third vertex attribute register
            //context3d.setVertexBufferAt(2, m_vertexBuffer, 5, Context3DVertexBufferFormat.FLOAT_1);
            
            // Put texture in the first tex register
            context3d.setTextureAt(0, m_originalTexture.base);
            
            // Set the proper transformation matrix for the vertex shader
            const matrix:Matrix3D = support.mvpMatrix3D;
            context3d.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
            
            // Draw two triangles forming the trapezoid
            context3d.drawTriangles(m_indexBuffer, 0, 2);//NUM_VERTICES / 3);
            
            // Clear the registers
            context3d.setTextureAt(0, null);
            context3d.setVertexBufferAt(0, null);
            context3d.setVertexBufferAt(1, null);
            //context3d.setVertexBufferAt(2, null);
        }
        
        override public function getBounds(targetSpace:DisplayObject, 
                                           resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null)
            {
                resultRect = new Rectangle();      
            }
            
            return resultRect;
        }
        
        override public function dispose():void
        {
            if (m_vertexBuffer != null)
            {   
                m_vertexBuffer.dispose();
            }
            
            if (m_indexBuffer)
            {
                m_indexBuffer.dispose();
            }
            
            super.dispose();
        }
        
        /**
         * Trapezoid is composed of a top triangle with indices 0-2 starting at the
         * top left corner and a bottom triangle with indices 3-5 starting at the top
         * right corner. (IMPORTANT: the vertices (1, 3) and (2, 4) are shared
         */
        public function setVertexPosition(vertexId:int, x:Number, y:Number):void
        {
            const vertexOffset:int = vertexId * VALUES_PER_VERTEX;
            m_vertices[vertexOffset] = x;
            m_vertices[vertexOffset + 1] = y;
        }
        
        private function registerShaderPrograms():void
        {
            const programName:String = "dragonbox.trapezoid";
            const starlingTarget:Starling = Starling.current;
            if (!starlingTarget.hasProgram(programName))
            {
                const assembler:CleanAgalMiniAssembler = new CleanAgalMiniAssembler();
                
                const shaderRaw:ByteArray = new SHADER() as ByteArray;
                const programBytes:Array = assembler.getProgramBytesFromString(shaderRaw.toString());
                
                starlingTarget.registerProgram(programName, programBytes[0], programBytes[1]);
            }
            
            m_shaderProgram = starlingTarget.getProgram(programName);
        }
    }
}