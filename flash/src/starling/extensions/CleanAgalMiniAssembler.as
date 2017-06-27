package starling.extensions
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3DProgramType;
    import flash.utils.ByteArray;
    
    /**
     * This assembler allows for comments embedded in the agal source.
     * Useful mainly when the shader code is in a separate file
     */
    public class CleanAgalMiniAssembler extends AGALMiniAssembler
    {
        private static const SHADER_FILE_DELIMITER:String = "#";
        private static const REGEXP_LINE_BREAKER:RegExp		= /[\f\n\r\v;]+/g;
        private static const COMMENT:RegExp					= /\/\/[^\n]*\n/g;
        
        public static const instance:CleanAgalMiniAssembler = new CleanAgalMiniAssembler();
        
        public function CleanAgalMiniAssembler(debugging:Boolean=false)
        {
            super(debugging);
        }
        
        /**
         * Assemble contents of a shader file into its shader programs.
         * Expects the file to contain the vertex shader instructions first
         * followed by the fragment shader instructions.
         * 
         * @param contents
         *      The raw string of the instructions for the shader
         * @return
         *      An array of byte arrays that were part of the shader
         */
        public function getProgramBytesFromString(contents:String):Array
        {
            // Split the contents at the vertex/fragment delimit
            var shaderBytes:Array = [];
            var pieces:Array = contents.split(SHADER_FILE_DELIMITER);
            if (pieces.length >= 1)
            {
                shaderBytes.push(this.assemble(Context3DProgramType.VERTEX, pieces[0]));
            }
            
            if (pieces.length == 2)
            {
                shaderBytes.push(this.assemble(Context3DProgramType.FRAGMENT, pieces[1]));
            }
            
            return shaderBytes;
        }
        
        /**
         * Get the raw strings representing a shader
         * 
         * @param contents
         *      The shader file string contents     
         * @return
         *      An array of strings containing just raw instructions
         */
        public function getStringsFromFile(contents:String):Array
        {
            var shaderStrings:Array = [];
            var pieces:Array = contents.split(SHADER_FILE_DELIMITER);
            
            var i:int;
            for (i = 0; i < pieces.length; i++)
            {
                shaderStrings.push(removeComments(pieces[i]));
            }
            
            return shaderStrings;
        }
        
        override public function assemble(mode:String, source:String, version:uint=1, ignorelimits:Boolean=false):ByteArray
        {
            return super.assemble(mode, removeComments(source), version, ignorelimits);
        }
        
        public function removeComments(source:String):String
        {
            // Pull out the c-style comments first.
            var start:int = source.indexOf( "/*" );
            while( start >= 0 ) {
                var end:int = source.indexOf( "*/", start+1 );
                if ( end < 0 ) throw new Error( "Comment end not found." );
                
                source = source.substr( 0, start ) + source.substr( end+2 );
                start = source.indexOf( "/*" );
            }
            
            source = source.replace( REGEXP_LINE_BREAKER, "\n" );
            source = source.replace( COMMENT, "" );
            return source;
        }
    }
}