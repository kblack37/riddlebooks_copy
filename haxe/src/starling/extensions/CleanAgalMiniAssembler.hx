package starling.extensions;

import flash.errors.Error;

//import com.adobe.utils.AGALMiniAssembler;

import openfl.display3D.Context3DProgramType;
import flash.utils.ByteArray;

// TODO: uncomment this once dependencies are figured out

/**
 * This assembler allows for comments embedded in the agal source.
 * Useful mainly when the shader code is in a separate file
 */
class CleanAgalMiniAssembler //extends AGALMiniAssembler
{
    private static inline var SHADER_FILE_DELIMITER : String = "#";
    private static var REGEXP_LINE_BREAKER : EReg = new EReg('[\\f\\n\\r\\v;]+', "g");
    private static var COMMENT : EReg = new EReg('\\/\\/[^\\n]*\\n', "g");
    //
    public static var instance : CleanAgalMiniAssembler = new CleanAgalMiniAssembler();
    //
    public function new(debugging : Bool = false)
    {
        //super(debugging);
    }
    //
    ///**
     //* Assemble contents of a shader file into its shader programs.
     //* Expects the file to contain the vertex shader instructions first
     //* followed by the fragment shader instructions.
     //* 
     //* @param contents
     //*      The raw string of the instructions for the shader
     //* @return
     //*      An array of byte arrays that were part of the shader
     //*/
    public function getProgramBytesFromString(contents : String) : Array<Dynamic>
    {
        // Split the contents at the vertex/fragment delimit
        var shaderBytes : Array<Dynamic> = [];
        var pieces : Array<Dynamic> = contents.split(SHADER_FILE_DELIMITER);
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
    //
    ///**
     //* Get the raw strings representing a shader
     //* 
     //* @param contents
     //*      The shader file string contents     
     //* @return
     //*      An array of strings containing just raw instructions
     //*/
    public function getStringsFromFile(contents : String) : Array<Dynamic>
    {
        var shaderStrings : Array<Dynamic> = [];
        var pieces : Array<Dynamic> = contents.split(SHADER_FILE_DELIMITER);
        
        var i : Int = 0;
        for (i in 0...pieces.length){
            shaderStrings.push(removeComments(pieces[i]));
        }
        
        return shaderStrings;
    }
	
    /*override*/ public function assemble(mode : String, source : String, version : Int = 1, ignorelimits : Bool = false) : ByteArray
    {
        //return super.assemble(mode, removeComments(source), version, ignorelimits);
		return new ByteArray();
    }
    
    public function removeComments(source : String) : String
    {
        // Pull out the c-style comments first.
        var start : Int = source.indexOf("/*");
        while (start >= 0){
            var end : Int = source.indexOf("*/", start + 1);
            if (end < 0)                 throw new Error("Comment end not found.");
            
            source = source.substr(0, start) + source.substr(end + 2);
            start = source.indexOf("/*");
        }
        
		source = REGEXP_LINE_BREAKER.replace(source, "\n");
		source = COMMENT.replace(source, "");
        return source;
    }
}
