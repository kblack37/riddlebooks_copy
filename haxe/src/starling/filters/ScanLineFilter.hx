package starling.filters;

import starling.filters.FragmentFilter;
//import starling.filters.SHADER;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Program3D;
import openfl.Vector;
import flash.utils.ByteArray;

import starling.extensions.CleanAgalMiniAssembler;
import starling.textures.Texture;

class ScanLineFilter extends FragmentFilter
{
    @:meta(Embed(source="/../assets/shaders/scan.agal",mimeType="application/octet-stream"))

    private static var SHADER : Class<Dynamic>;
    
    private var m_vertexShader : String;
    private var m_fragmentShader : String;
    private var m_shaderProgram : Program3D;
    
    /**
     * The target color of the scan line
     */
    private var m_targetColor : Vector<Float>;
    
    /**
     * The left most coordinates of the scanline
     */
    private var m_minBounds : Vector<Float>;
    
    /**
     * The right most coordinates of the scanline
     */
    private var m_maxBounds : Vector<Float>;
    
    /**
     * The constant to stuff into the shader register
     */
    private var m_one : Vector<Float>;
    
    public function new(targetColor : Int,
            startRatio : Float,
            endRatio : Float,
            numPasses : Int = 1,
            resolution : Float = 1.0)
    {
        m_targetColor = new Vector<Float>();
        m_targetColor.push((targetColor & 0xFF0000) >> 16);
        m_targetColor.push((targetColor & 0x00FF00) >> 8);
        m_targetColor.push((targetColor & 0x0000FF));
        m_targetColor.push(1);
        
        m_minBounds = new Vector<Float>();
        m_minBounds.push(startRatio);
        m_minBounds.push(0.0);
        m_minBounds.push(0.0);
        m_minBounds.push(0.0);
        
        m_maxBounds = new Vector<Float>();
        m_maxBounds.push(endRatio);
        m_maxBounds.push(0.0);
        m_maxBounds.push(0.0);
        m_maxBounds.push(0.0);
        
        
        m_one = new Vector<Float>();
        m_one.push(1.0);
        m_one.push(0.0);
        m_one.push(0.0);
        m_one.push(0.0);
        
        
        // Immediately parse out the shader program
        var shaderRaw : ByteArray = try cast(Type.createInstance(SHADER, []), ByteArray) catch(e:Dynamic) null;
        var shaderStrings : Array<Dynamic> = CleanAgalMiniAssembler.instance.getStringsFromFile(Std.string(shaderRaw));
        m_vertexShader = shaderStrings[0];
        m_fragmentShader = shaderStrings[1];
        
        super(numPasses, resolution);
    }
    
    override public function dispose() : Void
    {
        if (m_shaderProgram != null) 
        {
            m_shaderProgram.dispose();
        }
        
        super.dispose();
    }
    
    override private function createPrograms() : Void
    {
        m_shaderProgram = super.assembleAgal(m_fragmentShader, m_vertexShader);
    }
    
    override private function activate(pass : Int, context : Context3D, texture : Texture) : Void
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
    
    public function getMaxBound() : Float
    {
        return m_maxBounds[0];
    }
    
    public function setMaxBound(value : Float) : Void
    {
        m_maxBounds[0] = value;
    }
    
    public function getMinBound() : Float
    {
        return m_minBounds[0];
    }
    
    public function setMinBound(value : Float) : Void
    {
        m_minBounds[0] = value;
    }
}
