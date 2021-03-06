// =================================================================================================
//
//	Starling Framework - Particle System Extension
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.extensions;

import flash.errors.ArgumentError;
import starling.extensions.Particle;

import com.adobe.utils.AGALMiniAssembler;

import flash.display3d.Context3D;
import flash.display3d.Context3DBlendFactor;
import flash.display3d.Context3DProgramType;
import flash.display3d.Context3DVertexBufferFormat;
import flash.display3d.IndexBuffer3D;
import flash.display3d.Program3D;
import flash.display3d.VertexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import starling.animation.IAnimatable;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.errors.MissingContextError;
import starling.events.Event;
import starling.textures.Texture;
import starling.textures.TextureSmoothing;
import starling.utils.MatrixUtil;
import starling.utils.VertexData;

/** Dispatched when emission of particles is finished. */
@:meta(Event(name="complete",type="starling.events.Event"))


class ParticleSystem extends DisplayObject implements IAnimatable
{
    public var isEmitting(get, never) : Bool;
    public var capacity(get, never) : Int;
    public var numParticles(get, never) : Int;
    public var maxCapacity(get, set) : Int;
    public var emissionRate(get, set) : Float;
    public var emitterX(get, set) : Float;
    public var emitterY(get, set) : Float;
    public var blendFactorSource(get, set) : String;
    public var blendFactorDestination(get, set) : String;
    public var texture(get, set) : Texture;
    public var smoothing(get, set) : String;

    public static inline var MAX_NUM_PARTICLES : Int = 16383;
    
    private var mTexture : Texture;
    private var mParticles : Array<Particle>;
    private var mFrameTime : Float;
    
    private var mProgram : Program3D;
    private var mVertexData : VertexData;
    private var mVertexBuffer : VertexBuffer3D;
    private var mIndices : Array<Int>;
    private var mIndexBuffer : IndexBuffer3D;
    
    private var mNumParticles : Int;
    private var mMaxCapacity : Int;
    private var mEmissionRate : Float;  // emitted particles per second  
    private var mEmissionTime : Float;
    
    /** Helper objects. */
    private static var sHelperMatrix : Matrix = new Matrix();
    private static var sHelperPoint : Point = new Point();
    private static var sRenderAlpha : Array<Float> = [1.0, 1.0, 1.0, 1.0];
    
    private var mEmitterX : Float;
    private var mEmitterY : Float;
    private var mPremultipliedAlpha : Bool;
    private var mBlendFactorSource : String;
    private var mBlendFactorDestination : String;
    private var mSmoothing : String;
    
    public function new(texture : Texture, emissionRate : Float,
            initialCapacity : Int = 128, maxCapacity : Int = 16383,
            blendFactorSource : String = null, blendFactorDest : String = null)
    {
        super();
        if (texture == null)             throw new ArgumentError("texture must not be null");
        
        mTexture = texture;
        mPremultipliedAlpha = texture.premultipliedAlpha;
        mParticles = new Array<Particle>();
        mVertexData = new VertexData(0);
        mIndices = [];
        mEmissionRate = emissionRate;
        mEmissionTime = 0.0;
        mFrameTime = 0.0;
        mEmitterX = mEmitterY = 0;
        mMaxCapacity = Math.min(MAX_NUM_PARTICLES, maxCapacity);
        mSmoothing = TextureSmoothing.BILINEAR;
        
        mBlendFactorDestination = blendFactorDest || Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
        mBlendFactorSource = blendFactorSource ||
                ((mPremultipliedAlpha) ? Context3DBlendFactor.ONE : Context3DBlendFactor.SOURCE_ALPHA);
        
        createProgram();
        raiseCapacity(initialCapacity);
        
        // handle a lost device context
        Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
                onContextCreated, false, 0, true);
    }
    
    override public function dispose() : Void
    {
        Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        
        if (mVertexBuffer != null)             mVertexBuffer.dispose();
        if (mIndexBuffer != null)             mIndexBuffer.dispose();
        
        super.dispose();
    }
    
    private function onContextCreated(event : Dynamic) : Void
    {
        createProgram();
        raiseCapacity(0);
    }
    
    private function createParticle() : Particle
    {
        return new Particle();
    }
    
    private function initParticle(particle : Particle) : Void
    {
        particle.x = mEmitterX;
        particle.y = mEmitterY;
        particle.currentTime = 0;
        particle.totalTime = 1;
        particle.color = Math.random() * 0xffffff;
    }
    
    private function advanceParticle(particle : Particle, passedTime : Float) : Void
    {
        particle.y += passedTime * 250;
        particle.alpha = 1.0 - particle.currentTime / particle.totalTime;
        particle.scale = 1.0 - particle.alpha;
        particle.currentTime += passedTime;
    }
    
    private function raiseCapacity(byAmount : Int) : Void
    {
        var oldCapacity : Int = capacity;
        var newCapacity : Int = Math.min(mMaxCapacity, capacity + byAmount);
        var context : Context3D = Starling.context;
        
        if (context == null)             throw new MissingContextError();
        
        var baseVertexData : VertexData = new VertexData(4);
        baseVertexData.setTexCoords(0, 0.0, 0.0);
        baseVertexData.setTexCoords(1, 1.0, 0.0);
        baseVertexData.setTexCoords(2, 0.0, 1.0);
        baseVertexData.setTexCoords(3, 1.0, 1.0);
        mTexture.adjustVertexData(baseVertexData, 0, 4);
        
        mParticles.fixed = false;
        mIndices.fixed = false;
        
        for (i in oldCapacity...newCapacity){
            var numVertices : Int = i * 4;
            var numIndices : Int = i * 6;
            
            mParticles[i] = createParticle();
            mVertexData.append(baseVertexData);
            
            mIndices[numIndices] = numVertices;
            mIndices[as3hx.Compat.parseInt(numIndices + 1)] = numVertices + 1;
            mIndices[as3hx.Compat.parseInt(numIndices + 2)] = numVertices + 2;
            mIndices[as3hx.Compat.parseInt(numIndices + 3)] = numVertices + 1;
            mIndices[as3hx.Compat.parseInt(numIndices + 4)] = numVertices + 3;
            mIndices[as3hx.Compat.parseInt(numIndices + 5)] = numVertices + 2;
        }
        
        mParticles.fixed = true;
        mIndices.fixed = true;
        
        // upload data to vertex and index buffers
        
        if (mVertexBuffer != null)             mVertexBuffer.dispose();
        if (mIndexBuffer != null)             mIndexBuffer.dispose();
        
        mVertexBuffer = context.createVertexBuffer(newCapacity * 4, VertexData.ELEMENTS_PER_VERTEX);
        mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, newCapacity * 4);
        
        mIndexBuffer = context.createIndexBuffer(newCapacity * 6);
        mIndexBuffer.uploadFromVector(mIndices, 0, newCapacity * 6);
    }
    
    /** Starts the emitter for a certain time. @default infinite time */
    public function start(duration : Float = Float.MAX_VALUE) : Void
    {
        if (mEmissionRate != 0) 
            mEmissionTime = duration;
    }
    
    /** Stops emitting new particles. Depending on 'clearParticles', the existing particles
     *  will either keep animating until they die or will be removed right away. */
    public function stop(clearParticles : Bool = false) : Void
    {
        mEmissionTime = 0.0;
        if (clearParticles)             clear();
    }
    
    /** Removes all currently active particles. */
    public function clear() : Void
    {
        mNumParticles = 0;
    }
    
    /** Returns an empty rectangle at the particle system's position. Calculating the
     *  actual bounds would be too expensive. */
    override public function getBounds(targetSpace : DisplayObject,
            resultRect : Rectangle = null) : Rectangle
    {
        if (resultRect == null)             resultRect = new Rectangle();
        
        getTransformationMatrix(targetSpace, sHelperMatrix);
        MatrixUtil.transformCoords(sHelperMatrix, 0, 0, sHelperPoint);
        
        resultRect.x = sHelperPoint.x;
        resultRect.y = sHelperPoint.y;
        resultRect.width = resultRect.height = 0;
        
        return resultRect;
    }
    
    public function advanceTime(passedTime : Float) : Void
    {
        var particleIndex : Int = 0;
        var particle : Particle = null;
        
        // advance existing particles
        
        while (particleIndex < mNumParticles)
        {
            particle = try cast(mParticles[particleIndex], Particle) catch(e:Dynamic) null;
            
            if (particle.currentTime < particle.totalTime) 
            {
                advanceParticle(particle, passedTime);
                ++particleIndex;
            }
            else 
            {
                if (particleIndex != mNumParticles - 1) 
                {
                    var nextParticle : Particle = try cast(mParticles[as3hx.Compat.parseInt(mNumParticles - 1)], Particle) catch(e:Dynamic) null;
                    mParticles[as3hx.Compat.parseInt(mNumParticles - 1)] = particle;
                    mParticles[particleIndex] = nextParticle;
                }--;mNumParticles;
                
                if (mNumParticles == 0 && mEmissionTime == 0) 
                    dispatchEvent(new Event(Event.COMPLETE));
            }
        }  // create and advance new particles  
        
        
        
        
        if (mEmissionTime > 0) 
        {
            var timeBetweenParticles : Float = 1.0 / mEmissionRate;
            mFrameTime += passedTime;
            
            while (mFrameTime > 0)
            {
                if (mNumParticles < mMaxCapacity) 
                {
                    if (mNumParticles == capacity) 
                        raiseCapacity(capacity);
                    
                    particle = try cast(mParticles[mNumParticles], Particle) catch(e:Dynamic) null;
                    initParticle(particle);
                    
                    // particle might be dead at birth
                    if (particle.totalTime > 0.0) 
                    {
                        advanceParticle(particle, mFrameTime);
                        ++mNumParticles;
                    }
                }
                
                mFrameTime -= timeBetweenParticles;
            }
            
            if (mEmissionTime != Float.MAX_VALUE) 
                mEmissionTime = Math.max(0.0, mEmissionTime - passedTime);
        }  // update vertex data  
        
        
        
        
        var vertexID : Int = 0;
        var color : Int = 0;
        var alpha : Float = 0.0;
        var rotation : Float = 0.0;
        var x : Float = 0.0;
        var y : Float = 0.0;
        var xOffset : Float = 0.0;
        var yOffset : Float = 0.0;
        var textureWidth : Float = mTexture.width;
        var textureHeight : Float = mTexture.height;
        
        for (i in 0...mNumParticles){
            vertexID = i << 2;
            particle = try cast(mParticles[i], Particle) catch(e:Dynamic) null;
            color = particle.color;
            alpha = particle.alpha;
            rotation = particle.rotation;
            x = particle.x;
            y = particle.y;
            xOffset = textureWidth * particle.scale >> 1;
            yOffset = textureHeight * particle.scale >> 1;
            
            for (j in 0...4){mVertexData.setColorAndAlpha(vertexID + j, color, alpha);
            }
            
            if (rotation != 0) 
            {
                var cos : Float = Math.cos(rotation);
                var sin : Float = Math.sin(rotation);
                var cosX : Float = cos * xOffset;
                var cosY : Float = cos * yOffset;
                var sinX : Float = sin * xOffset;
                var sinY : Float = sin * yOffset;
                
                mVertexData.setPosition(vertexID, x - cosX + sinY, y - sinX - cosY);
                mVertexData.setPosition(vertexID + 1, x + cosX + sinY, y + sinX - cosY);
                mVertexData.setPosition(vertexID + 2, x - cosX - sinY, y - sinX + cosY);
                mVertexData.setPosition(vertexID + 3, x + cosX - sinY, y + sinX + cosY);
            }
            else 
            {
                // optimization for rotation == 0
                mVertexData.setPosition(vertexID, x - xOffset, y - yOffset);
                mVertexData.setPosition(vertexID + 1, x + xOffset, y - yOffset);
                mVertexData.setPosition(vertexID + 2, x - xOffset, y + yOffset);
                mVertexData.setPosition(vertexID + 3, x + xOffset, y + yOffset);
            }
        }
    }
    
    override public function render(support : RenderSupport, alpha : Float) : Void
    {
        if (mNumParticles == 0)             return  // it causes all previously batched quads/images to render.    // always call this method when you write custom rendering code!  ;
        
        
        
        
        
        support.finishQuadBatch();
        
        // make this call to keep the statistics display in sync.
        // to play it safe, it's done in a backwards-compatible way here.
        if (support.exists("raiseDrawCount")) 
            support.raiseDrawCount();
        
        alpha *= this.alpha;
        
        var context : Context3D = Starling.context;
        var pma : Bool = texture.premultipliedAlpha;
        
        sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = (pma) ? alpha : 1.0;
        sRenderAlpha[3] = alpha;
        
        if (context == null)             throw new MissingContextError();
        
        mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mNumParticles * 4);
        mIndexBuffer.uploadFromVector(mIndices, 0, mNumParticles * 6);
        
        context.setBlendFactors(mBlendFactorSource, mBlendFactorDestination);
        context.setTextureAt(0, mTexture.base);
        
        context.setProgram(mProgram);
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, sRenderAlpha, 1);
        context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
        context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
        context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
        
        context.drawTriangles(mIndexBuffer, 0, mNumParticles * 2);
        
        context.setTextureAt(0, null);
        context.setVertexBufferAt(0, null);
        context.setVertexBufferAt(1, null);
        context.setVertexBufferAt(2, null);
    }
    
    /** Initialize the <tt>ParticleSystem</tt> with particles distributed randomly throughout
     *  their lifespans. */
    public function populate(count : Int) : Void
    {
        count = Math.min(count, mMaxCapacity - mNumParticles);
        
        if (mNumParticles + count > capacity) 
            raiseCapacity(mNumParticles + count - capacity);
        
        var p : Particle = null;
        for (i in 0...count){
            p = mParticles[mNumParticles + i];
            initParticle(p);
            advanceParticle(p, Math.random() * p.totalTime);
        }
        
        mNumParticles += count;
    }
    
    // program management
    
    private function createProgram() : Void
    {
        var mipmap : Bool = mTexture.mipMapping;
        var textureFormat : String = mTexture.format;
        var programName : String = "ext.ParticleSystem." + textureFormat + "/" +
        mSmoothing.charAt(0) + ((mipmap) ? "+mm" : "");
        
        mProgram = Starling.current.getProgram(programName);
        
        if (mProgram == null) 
        {
            var textureOptions : String = 
            RenderSupport.getTextureLookupFlags(textureFormat, mipmap, false, mSmoothing);
            
            var vertexProgramCode : String = 
            "m44 op, va0, vc0 \n" +  // 4x4 matrix transform to output clipspace  
            "mul v0, va1, vc4 \n" +  // multiply color with alpha and pass to fragment program  
            "mov v1, va2      \n";  // pass texture coordinates to fragment program  
            
            var fragmentProgramCode : String = 
            "tex ft1, v1, fs0 " + textureOptions + "\n" +  // sample texture 0  
            "mul oc, ft1, v0";  // multiply color with texel color  
            
            var assembler : AGALMiniAssembler = new AGALMiniAssembler();
            
            Starling.current.registerProgram(programName,
                    assembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode),
                    assembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode));
            
            mProgram = Starling.current.getProgram(programName);
        }
    }
    
    private function get_isEmitting() : Bool{return mEmissionTime > 0 && mEmissionRate > 0;
    }
    private function get_capacity() : Int{return mVertexData.numVertices / 4;
    }
    private function get_numParticles() : Int{return mNumParticles;
    }
    
    private function get_maxCapacity() : Int{return mMaxCapacity;
    }
    private function set_maxCapacity(value : Int) : Int
    {
        mMaxCapacity = Math.min(MAX_NUM_PARTICLES, value);
        return value;
    }
    
    private function get_emissionRate() : Float{return mEmissionRate;
    }
    private function set_emissionRate(value : Float) : Float{mEmissionRate = value;
        return value;
    }
    
    private function get_emitterX() : Float{return mEmitterX;
    }
    private function set_emitterX(value : Float) : Float{mEmitterX = value;
        return value;
    }
    
    private function get_emitterY() : Float{return mEmitterY;
    }
    private function set_emitterY(value : Float) : Float{mEmitterY = value;
        return value;
    }
    
    private function get_blendFactorSource() : String{return mBlendFactorSource;
    }
    private function set_blendFactorSource(value : String) : String{mBlendFactorSource = value;
        return value;
    }
    
    private function get_blendFactorDestination() : String{return mBlendFactorDestination;
    }
    private function set_blendFactorDestination(value : String) : String{mBlendFactorDestination = value;
        return value;
    }
    
    private function get_texture() : Texture{return mTexture;
    }
    private function set_texture(value : Texture) : Texture{mTexture = value;createProgram();
        return value;
    }
    
    private function get_smoothing() : String{return mSmoothing;
    }
    private function set_smoothing(value : String) : String{mSmoothing = value;
        return value;
    }
}
