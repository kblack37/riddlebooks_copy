package starling.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;
    import flash.utils.ByteArray;
    
    import starling.extensions.CleanAgalMiniAssembler;
    import starling.textures.Texture;
    
    public class ScanLineFilter extends FragmentFilter
    {
        [Embed(source="/../assets/shaders/scan.agal",mimeType="application/octet-stream")]
        private static const SHADER:Class;
        
        private var m_vertexShader:String;
        private var m_fragmentShader:String;
        private var m_shaderProgram:Program3D;
        
        /**
         * The target color of the scan line
         */
        private var m_targetColor:Vector.<Number>;
        
        /**
         * The left most coordinates of the scanline
         */
        private var m_minBounds:Vector.<Number>;
        
        /**
         * The right most coordinates of the scanline
         */
        private var m_maxBounds:Vector.<Number>;
        
        /**
         * The constant to stuff into the shader register
         */
        private var m_one:Vector.<Number>;
        
        public function ScanLineFilter(targetColor:uint,
                                       startRatio:Number,
                                       endRatio:Number,
                                       numPasses:int=1, 
                                       resolution:Number=1.0)
        {
            m_targetColor = new Vector.<Number>();
            m_targetColor.push(
                (targetColor & 0xFF0000) >> 16, 
                (targetColor & 0x00FF00) >> 8,
                (targetColor & 0x0000FF), 
                1
            );
            m_minBounds = new Vector.<Number>();
            m_minBounds.push(startRatio, 0.0, 0.0, 0.0);
            m_maxBounds = new Vector.<Number>();
            m_maxBounds.push(endRatio, 0.0, 0.0, 0.0);
            
            m_one = new Vector.<Number>();
            m_one.push(1.0, 0.0, 0.0, 0.0);
            
            // Immediately parse out the shader program
            const shaderRaw:ByteArray = new SHADER() as ByteArray;
            const shaderStrings:Array = CleanAgalMiniAssembler.instance.getStringsFromFile(shaderRaw.toString());
            m_vertexShader = shaderStrings[0];
            m_fragmentShader = shaderStrings[1];
            
            super(numPasses, resolution);
        }
        
        override public function dispose():void
        {
            if (m_shaderProgram != null)
            {
                m_shaderProgram.dispose();
            }
            
            super.dispose();
        }
        
        override protected function createPrograms():void
        {
            m_shaderProgram = super.assembleAgal(m_fragmentShader, m_vertexShader);
        }
        
        override protected function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            //
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            
            // Set the min and max bounds of the scan line scaled between 0 to 1
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, m_minBounds, 1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, m_maxBounds, 1);
            
            // Set the target color
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, m_targetColor, 1);
            
            // Set the constant of one
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, m_one, 1);
            
            context.setProgram(m_shaderProgram);
        }
        
        public function getMaxBound():Number
        {
            return m_maxBounds[0];
        }
        
        public function setMaxBound(value:Number):void
        {
            m_maxBounds[0] = value;
        }
        
        public function getMinBound():Number
        {
            return m_minBounds[0];
        }
        
        public function setMinBound(value:Number):void
        {
            m_minBounds[0] = value;
        }
    }
}