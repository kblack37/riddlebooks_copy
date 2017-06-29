package starling.extensions.pixelmask;

import flash.errors.Error;

import flash.display3d.Context3DBlendFactor;
import flash.geom.Matrix;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.BlendMode;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.events.Event;
import starling.textures.RenderTexture;

class PixelMaskDisplayObject extends DisplayObjectContainer
{
    public var isAnimated(get, set) : Bool;
    public var inverted(get, set) : Bool;
    public var mask(never, set) : DisplayObject;

    private static inline var MASK_MODE_NORMAL : String = "mask";
    private static inline var MASK_MODE_INVERTED : String = "maskinverted";
    
    private var _mask : DisplayObject;
    private var _renderTexture : RenderTexture;
    private var _maskRenderTexture : RenderTexture;
    
    private var _image : Image;
    private var _maskImage : Image;
    
    private var _superRenderFlag : Bool = false;
    private var _inverted : Bool = false;
    private var _scaleFactor : Float;
    private var _isAnimated : Bool = true;
    private var _maskRendered : Bool = false;
    
    public function new(scaleFactor : Float = -1, isAnimated : Bool = true)
    {
        super();
        
        _isAnimated = isAnimated;
        _scaleFactor = scaleFactor;
        
        BlendMode.register(MASK_MODE_NORMAL, Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_ALPHA);
        BlendMode.register(MASK_MODE_INVERTED, Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
        
        // Handle lost context. By using the conventional event, we can make a weak listener.
        // This avoids memory leaks when people forget to call "dispose" on the object.
        Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
                onContextCreated, false, 0, true);
    }
    
    private function get_isAnimated() : Bool
    {
        return _isAnimated;
    }
    
    private function set_isAnimated(value : Bool) : Bool
    {
        _isAnimated = value;
        return value;
    }
    
    override public function dispose() : Void
    {
        clearRenderTextures();
        Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        super.dispose();
    }
    
    private function onContextCreated(event : Dynamic) : Void
    {
        refreshRenderTextures();
    }
    
    private function get_inverted() : Bool
    {
        return _inverted;
    }
    
    private function set_inverted(value : Bool) : Bool
    {
        _inverted = value;
        refreshRenderTextures(null);
        return value;
    }
    
    private function set_mask(mask : DisplayObject) : DisplayObject
    {
        
        // clean up existing mask if there is one
        if (_mask != null) {
            _mask = null;
        }
        
        if (mask != null) {
            _mask = mask;
            
            if (_mask.width == 0 || _mask.height == 0) {
                throw new Error("Mask must have dimensions. Current dimensions are " + _mask.width + "x" + _mask.height + ".");
            }
            
            refreshRenderTextures(null);
        }
        else {
            clearRenderTextures();
        }
        return mask;
    }
    
    private function clearRenderTextures() : Void
    {
        // clean up old render textures and images
        if (_maskRenderTexture != null) {
            _maskRenderTexture.dispose();
        }
        
        if (_renderTexture != null) {
            _renderTexture.dispose();
        }
        
        if (_image != null) {
            _image.dispose();
        }
        
        if (_maskImage != null) {
            _maskImage.dispose();
        }
    }
    
    private function refreshRenderTextures(e : Event = null) : Void
    {
        if (_mask != null) {
            
            clearRenderTextures();
            
            _maskRenderTexture = new RenderTexture(_mask.width, _mask.height, false, _scaleFactor);
            _renderTexture = new RenderTexture(_mask.width, _mask.height, false, _scaleFactor);
            
            // create image with the new render texture
            _image = new Image(_renderTexture);
            
            // create image to blit the mask onto
            _maskImage = new Image(_maskRenderTexture);
            
            // set the blending mode to MASK (ZERO, SRC_ALPHA)
            if (_inverted) {
                _maskImage.blendMode = MASK_MODE_INVERTED;
            }
            else {
                _maskImage.blendMode = MASK_MODE_NORMAL;
            }
        }
        _maskRendered = false;
    }
    
    override public function render(support : RenderSupport, parentAlpha : Float) : Void
    {
        if (_isAnimated || (!_isAnimated && !_maskRendered)) {
            if (_superRenderFlag || _mask == null) {
                super.render(support, parentAlpha);
            }
            else {
                if (_mask != null) {
                    _maskRenderTexture.draw(_mask);
                    _renderTexture.drawBundled(drawRenderTextures);
                    _image.render(support, parentAlpha);
                    _maskRendered = true;
                }
            }
        }
        else {
            _image.render(support, parentAlpha);
        }
    }
    
    private function drawRenderTextures() : Void
    {
        // undo scaling and positioning temporarily because its already applied in this execution stack
        
        var matrix : Matrix = this.transformationMatrix.clone();
        
        this.transformationMatrix = new Matrix();
        _superRenderFlag = true;
        _renderTexture.draw(this);
        _superRenderFlag = false;
        
        this.transformationMatrix = matrix;
        _renderTexture.draw(_maskImage);
    }
}
