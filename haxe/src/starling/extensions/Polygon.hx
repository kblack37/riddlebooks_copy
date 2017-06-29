package starling.extensions;

import flash.errors.ArgumentError;
import starling.extensions.SHADER;

import com.adobe.utils.AGALMiniAssembler;

import flash.display3d.Context3D;
import flash.display3d.Context3DBlendFactor;
import flash.display3d.Context3DProgramType;
import flash.display3d.Context3DVertexBufferFormat;
import flash.display3d.IndexBuffer3D;
import flash.display3d.VertexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.BlendMode;
import starling.display.DisplayObject;
import starling.errors.MissingContextError;
import starling.events.Event;
import starling.utils.VertexData;

/** This custom display objects renders a regular, n-sided polygon. */
class Polygon extends DisplayObject
{
    public var radius(get, set) : Float;
    public var numEdges(get, set) : Int;
    public var color(get, set) : Int;

    @:meta(Embed(source="/../assets/shaders/polygon.agal",mimeType="application/octet-stream"))

    private static var SHADER : Class<Dynamic>;
    
    private static var PROGRAM_NAME : String = "polygon";
    
    // custom members
    private var mRadius : Float;
    private var mNumEdges : Int;
    private var mColor : Int;
    
    // vertex data
    private var mVertexData : VertexData;
    private var mVertexBuffer : VertexBuffer3D;
    
    // index data
    private var mIndexData : Array<Int>;
    private var mIndexBuffer : IndexBuffer3D;
    
    // helper objects (to avoid temporary objects)
    private static var sHelperMatrix : Matrix = new Matrix();
    private static var sRenderAlpha : Array<Float> = [1.0, 1.0, 1.0, 1.0];
    
    /** Creates a regular polygon with the specified redius, number of edges, and color. */
    public function new(radius : Float, numEdges : Int = 6, color : Int = 0xffffff)
    {
        super();
        if (numEdges < 3)             throw new ArgumentError("Invalid number of edges");
        
        mRadius = radius;
        mNumEdges = numEdges;
        mColor = color;
        
        // setup vertex data and prepare shaders
        setupVertices();
        createBuffers();
        registerPrograms();
        
        // handle lost context
        Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
    }
    
    /** Disposes all resources of the display object. */
    override public function dispose() : Void
    {
        Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        
        if (mVertexBuffer != null)             mVertexBuffer.dispose();
        if (mIndexBuffer != null)             mIndexBuffer.dispose();
        
        super.dispose();
    }
    
    private function onContextCreated(event : Event) : Void
    {
        // the old context was lost, so we create new buffers and shaders.
        createBuffers();
        registerPrograms();
    }
    
    /** Returns a rectangle that completely encloses the object as it appears in another 
     * coordinate system. */
    override public function getBounds(targetSpace : DisplayObject, resultRect : Rectangle = null) : Rectangle
    {
        if (resultRect == null)             resultRect = new Rectangle();
        
        var transformationMatrix : Matrix = (targetSpace == this) ? 
        null : getTransformationMatrix(targetSpace, sHelperMatrix);
        
        return mVertexData.getBounds(transformationMatrix, 0, -1, resultRect);
    }
    
    /** Creates the required vertex- and index data and uploads it to the GPU. */
    private function setupVertices() : Void
    {
        var i : Int;
        
        // create vertices
        
        mVertexData = new VertexData(mNumEdges + 1);
        mVertexData.setUniformColor(mColor);
        
        for (i in 0...mNumEdges){
            var edge : Point = Point.polar(mRadius, i * 2 * Math.PI / mNumEdges);
            mVertexData.setPosition(i, edge.x, edge.y);
        }
        
        mVertexData.setPosition(mNumEdges, 0.0, 0.0);  // center vertex  
        
        // create indices that span up the triangles
        
        mIndexData = [];
        
        for (i in 0...mNumEdges){mIndexData.push(mNumEdges);
            mIndexData.push(i);
            mIndexData.push((i + 1) % mNumEdges);
            
        }
    }
    
    /** Creates new vertex- and index-buffers and uploads our vertex- and index-data to those
     *  buffers. */
    private function createBuffers() : Void
    {
        var context : Context3D = Starling.context;
        if (context == null)             throw new MissingContextError();
        
        if (mVertexBuffer != null)             mVertexBuffer.dispose();
        if (mIndexBuffer != null)             mIndexBuffer.dispose();
        
        mVertexBuffer = context.createVertexBuffer(mVertexData.numVertices, VertexData.ELEMENTS_PER_VERTEX);
        mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);
        
        mIndexBuffer = context.createIndexBuffer(mIndexData.length);
        mIndexBuffer.uploadFromVector(mIndexData, 0, mIndexData.length);
    }
    
    /** Renders the object with the help of a 'support' object and with the accumulated alpha
     * of its parent object. */
    override public function render(support : RenderSupport, alpha : Float) : Void
    {
        // always call this method when you write custom rendering code!
        // it causes all previously batched quads/images to render.
        support.finishQuadBatch();
        
        // make this call to keep the statistics display in sync.
        support.raiseDrawCount();
        
        sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = 1.0;
        sRenderAlpha[3] = alpha * this.alpha;
        
        var context : Context3D = Starling.context;
        if (context == null)             throw new MissingContextError()  // apply the current blendmode  ;
        
        
        
        support.applyBlendMode(false);
        
        // activate program (shader) and set the required buffers / constants
        context.setProgram(Starling.current.getProgram(PROGRAM_NAME));
        context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
        context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, sRenderAlpha, 1);
        
        // finally: draw the object!
        context.drawTriangles(mIndexBuffer, 0, mNumEdges);
        
        // reset buffers
        context.setVertexBufferAt(0, null);
        context.setVertexBufferAt(1, null);
    }
    
    /** Creates vertex and fragment programs from assembly. */
    private static function registerPrograms() : Void
    {
        var target : Starling = Starling.current;
        if (target.hasProgram(PROGRAM_NAME))             return  // vc4 -> alpha    // vc0 -> mvpMatrix (4 vectors, vc0 - vc3)    // va1 -> color    // va0 -> position    // already registered  ;
        
        
        
        
        
        
        
        
        
        var assembler : CleanAgalMiniAssembler = new CleanAgalMiniAssembler();
        
        var shaderRaw : ByteArray = try cast(Type.createInstance(SHADER, []), ByteArray) catch(e:Dynamic) null;
        var programBytes : Array<Dynamic> = assembler.getProgramBytesFromString(Std.string(shaderRaw));
        
        target.registerProgram(
                PROGRAM_NAME,
                programBytes[0],
                programBytes[1]
                );
    }
    
    /** The radius of the polygon in points. */
    private function get_radius() : Float{return mRadius;
    }
    private function set_radius(value : Float) : Float{mRadius = value;setupVertices();
        return value;
    }
    
    /** The number of edges of the regular polygon. */
    private function get_numEdges() : Int{return mNumEdges;
    }
    private function set_numEdges(value : Int) : Int{mNumEdges = value;setupVertices();
        return value;
    }
    
    /** The color of the regular polygon. */
    private function get_color() : Int{return mColor;
    }
    private function set_color(value : Int) : Int{mColor = value;setupVertices();
        return value;
    }
}
