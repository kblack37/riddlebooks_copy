package wordproblem.resource;

import flash.errors.ArgumentError;
import flash.errors.Error;
import haxe.xml.Fast;
import openfl.Assets;
import openfl.Vector;
//import wordproblem.resource.ImageDataClass;
//import wordproblem.resource.RawAsset;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.FileReference;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
//import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;
import flash.system.System;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

//import flash.utils.DescribeType;

import haxe.Constraints.Function;

// TODO: uncomment these once cgs porting is done
//import cgs.audio.IAudioResource;
//import cgs.levelprogression.util.ICgsLevelResourceManager;

import starling.core.Starling;
import starling.events.Event;
import starling.events.EventDispatcher;
import starling.extensions.textureutil.AtlasBuilder;
import starling.text.BitmapFont;
import starling.text.TextField;
import starling.textures.AtfData;
import starling.textures.RenderTexture;
import starling.textures.SubTexture;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

import wordproblem.resource.bundles.ResourceBundle;

/** Dispatched when all textures have been restored after a context loss. */
@:meta(Event(name="texturesRestored",type="starling.events.Event"))


/** The AssetManager handles loading and accessing a variety of asset types. You can 
 *  add assets directly (via the 'add...' methods) or asynchronously via a queue. This allows
 *  you to deal with assets in a unified way, no matter if they are loaded from a file, 
 *  directory, URL, or from an embedded object.
 *  
 *  <p>The class can deal with the following media types:
 *  <ul>
 *    <li>Textures, either from Bitmaps or ATF data</li>
 *    <li>Texture atlases</li>
 *    <li>Bitmap Fonts</li>
 *    <li>Sounds</li>
 *    <li>XML data</li>
 *    <li>JSON data</li>
 *    <li>ByteArrays</li>
 *  </ul>
 *  </p>
 *  
 *  <p>For more information on how to add assets from different sources, read the documentation
 *  of the "enqueue()" method.</p>
 * 
 *  <strong>Context Loss</strong>
 *  
 *  <p>When the stage3D context is lost (and you have enabled 'Starling.handleLostContext'),
 *  the AssetManager will automatically restore all loaded textures. To save memory, it will
 *  get them from their original sources. Since this is done asynchronously, your images might
 *  not reappear all at once, but during a timeframe of several seconds. If you want, you can
 *  pause your game during that time; the AssetManager dispatches an "Event.TEXTURES_RESTORED"
 *  event when all textures have been restored.</p>
 */
class AssetManager extends EventDispatcher //implements ICgsLevelResourceManager implements IAudioResource
{
    private var queue(get, never) : Array<Dynamic>;
    public var numQueuedAssets(get, never) : Int;
    public var verbose(get, set) : Bool;
    public var useMipMaps(get, set) : Bool;
    public var scaleFactor(get, set) : Float;
    public var checkPolicyFile(get, set) : Bool;

    /**
     * Different versions may have restrictions on where dynamically loaded resources can
     * be loaded from. By default all relative paths try to fetch from the same domain as the
     * main application file (or is it the web page?)
     * 
     * By specifying this path, the location can be overriden so that resources are fetched from
     * a separate location.
     */
    public var resourcePathBase : String;
    
    private var mScaleFactor : Float;
    private var mUseMipMaps : Bool;
    private var mCheckPolicyFile : Bool;
    private var mVerbose : Bool;
    private var mNumLostTextures : Int;
    private var mNumRestoredTextures : Int;
    
    private var mQueue : Array<Dynamic>;
    private var mIsLoading : Bool;
    private var mTimeoutID : Int;
    
    private var mTextures : Dictionary<String, Texture>;
    private var mAtlases : Dictionary<String, TextureAtlas>;
    private var mSounds : Dictionary<String, Sound>;
    private var mXmls : Dictionary < String, Fast>;
    private var mObjects : Dictionary<String, Dynamic>;
    private var mByteArrays : Dictionary<String, ByteArray>;
    
    /**
     * We have a situation where there is a limit to the total size of textures that can be loaded
     * by a running application. This is a problem for embedded assets as it means we cannot simply
     * add all of them as textures from the start.
     * 
     * We cannot 'reload' embedded class so texture can only be recreated if we can reference the
     * class or have the bitmap information saved somewhere
     * 
     * Warning: keeping a copy of each bitmap data for every asset will probably leave a pretty
     * big memory foot print
     */
    private var m_savedBitmapData : Dictionary<String, BitmapData>;
    
    /**
     * For embedded texture atlas, we have the image and an xml that defines how to segment the image
     * into regions.
     * 
     * We don't want that huge atlas image texture sitting in the limited space of the graphics memory,
     * so we need to potentially load it into there multiple times. This require recreating the
     * TextureAtlas object multiple times, in this case it needs the xml multiple times to segment
     * the image into regions.
     */
    private var m_savedEmbeddedAtlasXml : Dictionary<String, Fast>;
    
    /**
     * Mapping from the id/name used to fetch a resource from this manager to a count of how
     * many times we think it is actively being used at the moment.
     * 
     * The purpose of this is that whenever the count for a particular texture is zero, we can safely dispose
     * the texture (thus freeing it from graphics memory)
     */
    private var m_textureIdToUsageCount : Dynamic;
    
    /** helper objects */
    private static var sNames : Array<String> = [];
    
    /** Create a new AssetManager. The 'scaleFactor' and 'useMipmaps' parameters define
     *  how enqueued bitmaps will be converted to textures. */
    public function new(scaleFactor : Float = 1, useMipmaps : Bool = false, pathBase : String = null)
    {
        super();
        mVerbose = false;
        mCheckPolicyFile = false;
        mIsLoading = false;
        mScaleFactor = (scaleFactor > 0) ? scaleFactor : Starling.current.contentScaleFactor;
        mUseMipMaps = useMipmaps;
        mQueue = [];
        mTextures = new Dictionary();
        mAtlases = new Dictionary();
        mSounds = new Dictionary();
        mXmls = new Dictionary();
        mObjects = new Dictionary();
        mByteArrays = new Dictionary();
        
        m_savedBitmapData = new Dictionary();
        m_savedEmbeddedAtlasXml = new Dictionary();
        m_textureIdToUsageCount = { };
        
        resourcePathBase = pathBase;
    }
    
    /*
    We have some collection of resources that need to be loaded.
    Combination of url strings and embedded resources.
    
    They are all instances of objects, more than anything we just need to document
    how these objects work
    */
    public function loadResourceBundles(resourceBundles : Array<ResourceBundle>,
            onProgress : Function,
            onComplete : Function) : Void
    {
        var bundlesToLoad : Int = resourceBundles.length;
        var bundlesRemainingToBeLoaded : Int = bundlesToLoad;
        var numStarlingLoadableBundles : Int = 0;
        for (i in 0...bundlesToLoad){
            var resourceBundle : ResourceBundle = resourceBundles[i];
            
            // First load in any additional resources included by this bundle
            var additionalResourceMap : Dynamic = resourceBundle.getNameToResourceMap();
            for (resourceName in Reflect.fields(additionalResourceMap))
            {
                enqueueWithName(Reflect.field(additionalResourceMap, resourceName), resourceName);
            }  // with static embedded resources already)    // just enqueue then loadQueue on it. (Starling knows how to load a class    // This bundle can be loaded by the default Starling AssetManager, we can  
            
            
            
            
            
            
            
            var className : String = Type.getClassName(Type.getClass(resourceBundle));
            var classObject : Class<Dynamic> = Type.getClass(Type.resolveClass(className));
			// TODO: is this necessary?
            //enqueue(classObject);
            
            numStarlingLoadableBundles++;
        }  // Thus the total number of bundled resources need to treat the starling assets as only one large bundle    // All assets that are loadable from starling's default manager are loaded as a single blob,  
        
        
        
        
        
        bundlesRemainingToBeLoaded -= Std.int(Math.max(0, numStarlingLoadableBundles - 1));
        
		function onBundleLoaded() : Void
        {
            bundlesRemainingToBeLoaded--;
            if (bundlesRemainingToBeLoaded == 0 && onComplete != null) 
            {
                onComplete();
            }
        };
		
        function onStarlingLoadProgress(ratio : Float) : Void
        {
            // HACK: This thing is getting triggered multiple times
            if (ratio >= 1.0) 
            {
                onBundleLoaded();
            }
        };
		
        loadQueue(onStarlingLoadProgress);
    }
    
    /**
     * Function is a required extension from the cgs common audio package.
     * We can use starling's built-in management capabilities to store and link to the
     * sound resources.
     * 
     * @param soundName
     *      A string key that will properly link to the sound resource
     * @return
     *      A usable sound object
     */
    public function getSoundResource(soundName : String) : Sound
    {
        return this.getSound(soundName);
    }
    
    /**
     * Get back raw bitmap data for an image
     * 
     * @return
     *      null if no image has matching name
     */
    public function getBitmapData(name : String) : BitmapData
    {
        return Reflect.field(m_savedBitmapData, name);
    }
    
    /**
     * @param atlasName
     *      Name that will act as the key to fetch the atlas from starling
     * @param onImagesLoaded
     *      Callback when all images have been loaded, accepts a list
     *      of bitmapdata objects containing the images. They are indexed
     *      in the same order as the list of nodes.
     */
    public function loadDynamicAtlas(imagesToLoad : Array<Dynamic>,
            imageIds : Array<String>,
            atlasName : String,
            onComplete : Function) : Void
    {
        // Keep track of all images to load in the array.
        // For initial simplicity we load them all in sequential order
        var bitmapIdsToLoad : Array<String> = new Array<String>();
        var idToBitmapMap : Dictionary<String, Bitmap> = new Dictionary();
        var numImages : Int = imagesToLoad.length;
        var bitmap : Bitmap;
        var bitmapId : String;
        for (i in 0...numImages){
            var imageData : Dynamic = imagesToLoad[i];
            bitmapId = imageIds[i];
            if (Std.is(imageData, Class)) 
            {
                // Immediately instantiate the object as a bitmap
                var imageDataClass : Class<Dynamic> = Type.getClass(imageData);
                bitmap = try cast(Type.createInstance(imageDataClass, []), Bitmap) catch(e:Dynamic) null;
                Reflect.setField(idToBitmapMap, bitmapId, bitmap);
            }
            else if (Std.is(imageData, String)) 
            {
                // Attempt to load the image from the specified url
                bitmapIdsToLoad.push(bitmapId);
                enqueueWithName(imageData, bitmapId);
            }
        }
		
		function onAllBitmapsLoaded() : Void
        {
            var bitmaps : Array<Bitmap> = new Array<Bitmap>();
            for (bitmapId in Reflect.fields(idToBitmapMap))
            {
                bitmap = Reflect.field(idToBitmapMap, bitmapId);
                bitmap.name = bitmapId;
                bitmaps.push(bitmap);
            }
            
            var dynamicAtlas : TextureAtlas = AtlasBuilder.build(bitmaps);
            addTextureAtlas(atlasName, dynamicAtlas);
            
            if (onComplete != null) 
            {
                onComplete();
            }
        };
        
        if (bitmapIdsToLoad.length > 0) 
        {
            loadQueue(function(ratio : Float) : Void
                    {
                        if (ratio >= 1.0) 
                        {
                            for (bitmapId in Reflect.fields(bitmapIdsToLoad))
                            {
                                Reflect.setField(idToBitmapMap, bitmapId, new Bitmap(try cast(Reflect.field(m_savedBitmapData, bitmapId), BitmapData) catch(e:Dynamic) null));
                            }
                            
                            onAllBitmapsLoaded();
                        }
                    });
        }
        else 
        {
            onAllBitmapsLoaded();
        }
    }
    
    /**
     * @inheritDoc
     */
    public function addResource(resourceName : String, resource : String) : Void
    {
        addObject(resourceName, resource);
    }
    
    /**
     * @inheritDoc
     */
    public function getResource(resourceName : String) : String
    {
        var resourceObject : Dynamic = this.getObject(resourceName);
        var resourceString : String = haxe.Json.stringify(resourceObject);
        return resourceString;
    }
    
    /**
     * @inheritDoc
     */
    public function resourceExists(resourceName : String) : Bool
    {
        return getResource(resourceName) != null;
    }
    
    /** Disposes all contained textures. */
    public function dispose() : Void
    {
        for (textureName in mTextures)
        mTextures[textureName].dispose();
        
        for (atlasName in mAtlases)
        mAtlases[atlasName].dispose();
    }
    
    /**
     * Get whether a texture for the given name has been created and is available
     * for use.
     */
    public function hasTexture(name : String) : Bool
    {
        return mTextures.exists(name);
    }
    
    /**
     * For any textures that aren't commonly used, use this to get the texture that increments a usage
     * counter so the application can keep track of what textures are currently visible.
     * 
     * Be sure to call the corresponding releaseTextureWithReferenceCount function when the texture
     * is no longer needed. It is important because texture memory is a very limited resource and large
     * textures that are only used is a few places should not be taking up space whenever it is not actually shown.
     */
    public function getTextureWithReferenceCount(name : String) : Texture
    {
        var texture : Texture = getTexture(name);
        if (texture != null) 
        {
            if (!m_textureIdToUsageCount.exists(name)) 
            {
                Reflect.setField(m_textureIdToUsageCount, name, 0);
            }
            
            Reflect.setField(m_textureIdToUsageCount, name, Reflect.field(m_textureIdToUsageCount, name) + 1);
        }
        
        return texture;
    }
    
    /**
     * This should be called whenever a texture called with getTextureWithReferenceCount has been fetched.
     * The purpose is to is to free the limited texture memory from assets that will no longer be needed.
     */
    public function releaseTextureWithReferenceCount(name : String) : Void
    {
        if (m_textureIdToUsageCount.exists(name)) 
        {
            Reflect.setField(m_textureIdToUsageCount, name, Reflect.field(m_textureIdToUsageCount, name) - 1);
            if (Reflect.field(m_textureIdToUsageCount, name) <= 0) 
            {
                removeTexture(name, true);
            }
        }
    }
    
    // retrieving
    private inline static var atlasDelimiter : String = "::";
    /** Returns a texture with a certain name. The method first looks through the directly
     *  added textures; if no texture with that name is found, it scans through all 
     *  texture atlases. */
    public function getTexture(name : String) : Texture
    {
        // This function is modified in that the name of the texture could also
        // have extra data appended to it to point to the texture atlas to use
        // ex.) the name 'button_up::ui_atlas' will attempt to grab the button texture
        // from the ui_atlas.
        var texture : Texture = null;
		var bmpData : BitmapData = Assets.getBitmapData(name);
		if (bmpData != null) texture = Texture.fromBitmapData(bmpData, false);
		
        //if (name.indexOf(atlasDelimiter) != -1) 
        //{
            //var namePieces : Array<Dynamic> = name.split(atlasDelimiter);
            //var textureAtlas : TextureAtlas = this.getTextureAtlas(namePieces[1]);
            //if (textureAtlas != null) 
            //{
                //texture = textureAtlas.getTexture(namePieces[0]);
            //}
        //}
        //// If texture is not present, then check if it refers to a saved bitmap data
        //else if (mTextures.exists(name)) 
        //{
            //texture = Reflect.field(mTextures, name);
        //}
        //else 
        //{
            //for (atlasName in mAtlases)
            //{
                //texture = mAtlases[atlasName].getTexture(name);
                //if (texture != null) 
                //{
                    //break;
                //}
            //}
        //}
        //
        //
        //
        //if (texture == null && m_savedBitmapData.exists(name)) 
        //{
            //texture = Texture.fromBitmapData(try cast(Reflect.field(m_savedBitmapData, name), BitmapData) catch(e:Dynamic) null, false);
            //Reflect.setField(mTextures, name, texture);
        //}
        
        return texture;
    }
    
    /** Returns all textures that start with a certain string, sorted alphabetically
     *  (especially useful for "MovieClip"). */
    public function getTextures(prefix : String = "", result : Array<Texture> = null) : Array<Texture>
    {
        if (result == null)             result = [];
        
        for (name/* AS3HX WARNING could not determine type for var: name exp: ECall(EIdent(getTextureNames),[EIdent(prefix),EIdent(sNames)]) type: null */ in getTextureNames(prefix, sNames))
        result.push(getTexture(name));
        
		// TODO: ask about this
        //as3hx.Compat.setArrayLength(sNames, 0);
        return result;
    }
    
    /** Returns all texture names that start with a certain string, sorted alphabetically. */
    public function getTextureNames(prefix : String = "", result : Array<String> = null) : Array<String>
    {
        result = getDictionaryKeys(mTextures, prefix, result);
        
		var resultVector = new Vector<String>();
		
        for (atlasName in mAtlases)
			mAtlases[atlasName].getNames(prefix, resultVector);
		
		for (e in resultVector) result.push(e);
        
        result.sort(function cmp(s1 : String, s2 : String) : Int {
			s1 = s1.toLowerCase();
			s2 = s2.toLowerCase();
			for (i in 0...Std.int(Math.min(s1.length, s2.length))) {
				var c1 = s1.charCodeAt(i);
				var c2 = s2.charCodeAt(i);
				if (c1 != c2) return c1 - c2;
			}
			
			if (s1.length == s2.length) return 0;
			else if (s1.length < s2.length) return 1;
			else return -1;
		});
        return result;
    }
    
    /** Returns a texture atlas with a certain name, or null if it's not found. */
    public function getTextureAtlas(name : String) : TextureAtlas
    {
        var textureAtlas : TextureAtlas = null;
        if (mAtlases.exists(name)) 
        {
            textureAtlas = try cast(Reflect.field(mAtlases, name), TextureAtlas) catch(e:Dynamic) null;
        }
        // Create the atlas if this is the first request for it
        else if (m_savedEmbeddedAtlasXml.exists(name)) 
        {
            var texture : Texture = Texture.fromBitmapData(try cast(Reflect.field(m_savedBitmapData, name), BitmapData) catch(e:Dynamic) null, false);
            textureAtlas = new TextureAtlas(texture, try cast(Reflect.field(m_savedEmbeddedAtlasXml, name).x, Xml) catch(e:Dynamic) null);
            addTextureAtlas(name, textureAtlas);
        }
        return textureAtlas;
    }
    
    /** Returns a sound with a certain name, or null if it's not found. */
    public function getSound(name : String) : Sound
    {
        return Reflect.field(mSounds, name);
    }
    
    /** Returns all sound names that start with a certain string, sorted alphabetically.
     *  If you pass a result vector, the names will be added to that vector. */
    public function getSoundNames(prefix : String = "", result : Array<String> = null) : Array<String>
    {
        return getDictionaryKeys(mSounds, prefix, result);
    }
    
    /** Generates a new SoundChannel object to play back the sound. This method returns a 
     *  SoundChannel object, which you can access to stop the sound and to control volume. */
    public function playSound(name : String, startTime : Float = 0, loops : Int = 0,
            transform : SoundTransform = null) : SoundChannel
    {
        if (mSounds.exists(name)) 
            return getSound(name).play(startTime, loops, transform)
        else 
			return null;
    }
    
    /** Returns an XML with a certain name, or null if it's not found. */
    public function getXml(name : String) : Fast
    {
		var xml : Fast = null;
		var text : String = Assets.getText(name);
		if (text != null) xml = new Fast(Xml.parse(text));
		return xml;
        //return Reflect.field(mXmls, name);
    }
    
    /** Returns all XML names that start with a certain string, sorted alphabetically. 
     *  If you pass a result vector, the names will be added to that vector. */
    public function getXmlNames(prefix : String = "", result : Array<String> = null) : Array<String>
    {
        return getDictionaryKeys(mXmls, prefix, result);
    }
    
    /** Returns an object with a certain name, or null if it's not found. Enqueued JSON
     *  data is parsed and can be accessed with this method. */
    public function getObject(name : String) : Dynamic
    {
        return Reflect.field(mObjects, name);
    }
    
    /** Returns all object names that start with a certain string, sorted alphabetically. 
     *  If you pass a result vector, the names will be added to that vector. */
    public function getObjectNames(prefix : String = "", result : Array<String> = null) : Array<String>
    {
        return getDictionaryKeys(mObjects, prefix, result);
    }
    
    /** Returns a byte array with a certain name, or null if it's not found. */
    public function getByteArray(name : String) : ByteArray
    {
        return Reflect.field(mByteArrays, name);
    }
    
    /** Returns all byte array names that start with a certain string, sorted alphabetically. 
     *  If you pass a result vector, the names will be added to that vector. */
    public function getByteArrayNames(prefix : String = "", result : Array<String> = null) : Array<String>
    {
        return getDictionaryKeys(mByteArrays, prefix, result);
    }
    
    // direct adding
    
    /** Register a texture under a certain name. It will be available right away. */
    public function addTexture(name : String, texture : Texture) : Void
    {
        log("Adding texture '" + name + "'");
        
        if (mTextures.exists(name)) 
            log("Warning: name was already in use; the previous texture will be replaced.");
        
        Reflect.setField(mTextures, name, texture);
    }
    
    /** Register a texture atlas under a certain name. It will be available right away. */
    public function addTextureAtlas(name : String, atlas : TextureAtlas) : Void
    {
        log("Adding texture atlas '" + name + "'");
        
        if (mAtlases.exists(name)) 
            log("Warning: name was already in use; the previous atlas will be replaced.");
        
        Reflect.setField(mAtlases, name, atlas);
    }
    
    /** Register a sound under a certain name. It will be available right away. */
    public function addSound(name : String, sound : Sound) : Void
    {
        log("Adding sound '" + name + "'");
        
        if (mSounds.exists(name)) 
            log("Warning: name was already in use; the previous sound will be replaced.");
        
        Reflect.setField(mSounds, name, sound);
    }
    
    /** Register an XML object under a certain name. It will be available right away. */
    public function addXml(name : String, xml : Fast) : Void
    {
        log("Adding XML '" + name + "'");
        
        if (mXmls.exists(name)) 
            log("Warning: name was already in use; the previous XML will be replaced.");
        
        Reflect.setField(mXmls, name, xml);
    }
    
    /** Register an arbitrary object under a certain name. It will be available right away. */
    public function addObject(name : String, object : Dynamic) : Void
    {
        log("Adding object '" + name + "'");
        
        if (mObjects.exists(name)) 
            log("Warning: name was already in use; the previous object will be replaced.");
        
        Reflect.setField(mObjects, name, object);
    }
    
    /** Register a byte array under a certain name. It will be available right away. */
    public function addByteArray(name : String, byteArray : ByteArray) : Void
    {
        log("Adding byte array '" + name + "'");
        
        if (Lambda.has(mObjects, name)) 
            log("Warning: name was already in use; the previous byte array will be replaced.");
        
        Reflect.setField(mByteArrays, name, byteArray);
    }
    
    // removing
    
    /** 
     * Removes a certain texture, optionally disposing it.
     * 
     * @param disposeBitmapData
     *      Optionally delete associated bitmap data. Doing so prevents this class from being
     *      able to recreate the texture later. 
     */
    public function removeTexture(name : String, dispose : Bool = true, disposeBitmapData : Bool = false) : Void
    {
        log("Removing texture '" + name + "'");
        
        if (mTextures.exists(name)) 
        {
            if (dispose) 
            {
                Reflect.field(mTextures, name).dispose();
            }
            
            if (disposeBitmapData && m_savedBitmapData.exists(name)) 
            {
                (try cast(Reflect.field(m_savedBitmapData, name), BitmapData) catch(e:Dynamic) null).dispose();
            }
        }
        
        
        ;
    }
    
    /** Removes a certain texture atlas, optionally disposing it. */
    public function removeTextureAtlas(name : String, dispose : Bool = true) : Void
    {
        log("Removing texture atlas '" + name + "'");
        
        if (dispose && mAtlases.exists(name)) 
        {
            var textureAtlas : TextureAtlas = Reflect.field(mAtlases, name);
            textureAtlas.dispose();
            
            if (Std.is(textureAtlas.texture, RenderTexture)) 
            {
                (try cast(textureAtlas.texture, RenderTexture) catch(e:Dynamic) null).clear();
                (try cast(textureAtlas.texture, RenderTexture) catch(e:Dynamic) null).dispose();
            }
            
            if (Std.is(textureAtlas.texture, SubTexture)) 
            {
                (try cast(textureAtlas.texture, SubTexture) catch(e:Dynamic) null).parent.dispose();
            }
        }
        
        ;
    }
    
    /** Removes a certain sound. */
    public function removeSound(name : String) : Void
    {
        log("Removing sound '" + name + "'");
    }
    
    /** Removes a certain Xml object, optionally disposing it. */
    public function removeXml(name : String, dispose : Bool = true) : Void
    {
        log("Removing xml '" + name + "'");
        
        if (dispose && mXmls.exists(name)) 
            Reflect.setField(mXmls, name, null);
    }
    
    /** Removes a certain object. */
    public function removeObject(name : String) : Void
    {
        log("Removing object '" + name + "'");
    }
    
    /** Removes a certain byte array, optionally disposing its memory right away. */
    public function removeByteArray(name : String, dispose : Bool = true) : Void
    {
        log("Removing byte array '" + name + "'");
        
        if (dispose && mByteArrays.exists(name)) 
            Reflect.field(mByteArrays, name).clear();
    }
    
    /** Empties the queue and aborts any pending load operations. */
    public function purgeQueue() : Void
    {
        mIsLoading = false;
		// TODO: ask about this
        //as3hx.Compat.setArrayLength(mQueue, 0);
        //as3hx.Compat.clearTimeout(mTimeoutID);
    }
    
    /** Removes assets of all types, empties the queue and aborts any pending load operations.*/
    public function purge() : Void
    {
        log("Purging all assets, emptying queue");
        purgeQueue();
        
        for (textureName in mTextures)
        mTextures[textureName].dispose();
        
        for (atlasName in mAtlases)
        mAtlases[atlasName].dispose();
        
        mTextures = new Dictionary();
        mAtlases = new Dictionary();
        mSounds = new Dictionary();
        mXmls = new Dictionary();
        mObjects = new Dictionary();
        mByteArrays = new Dictionary();
    }
    
    // queued adding
    
    /** Enqueues one or more raw assets; they will only be available after successfully 
     *  executing the "loadQueue" method. This method accepts a variety of different objects:
     *  
     *  <ul>
     *    <li>Strings containing an URL to a local or remote resource. Supported types:
     *        <code>png, jpg, gif, atf, mp3, xml, fnt, json, binary</code>.</li>
     *    <li>Instances of the File class (AIR only) pointing to a directory or a file.
     *        Directories will be scanned recursively for all supported types.</li>
     *    <li>Classes that contain <code>static</code> embedded assets.</li>
     *    <li>If the file extension is not recognized, the data is analyzed to see if
     *        contains XML or JSON data. If it's neither, it is stored as ByteArray.</li>
     *  </ul>
     *  
     *  <p>Suitable object names are extracted automatically: A file named "image.png" will be
     *  accessible under the name "image". When enqueuing embedded assets via a class, 
     *  the variable name of the embedded object will be used as its name. An exception
     *  are texture atlases: they will have the same name as the actual texture they are
     *  referencing.</p>
     *  
     *  <p>XMLs that contain texture atlases or bitmap fonts are processed directly: fonts are
     *  registered at the TextField class, atlas textures can be acquired with the
     *  "getTexture()" method. All other XMLs are available via "getXml()".</p>
     *  
     *  <p>If you pass in JSON data, it will be parsed into an object and will be available via
     *  "getObject()".</p>
     */
	/* TODO: ask about this function
    public function enqueue() : Void
    {
        for (rawAsset in rawAssets)
        {
            if (Std.is(rawAsset, Array)) 
            {
                enqueue.apply(this, rawAsset);
            }
            else if (Std.is(rawAsset, Class)) 
            {
                var typeXml : FastXML = describeType(rawAsset);
                var childNode : FastXML;
                
                if (mVerbose) 
                    log("Looking for static embedded assets in '" +
                        (typeXml.att.name).split("::").pop() + "'");
                
                for (childNode in FastXML.filterNodes(typeXml.nodes.constant, function(x:FastXML) {
                    if(x.att.type == "Class")
                        return true;
                    return false;

                }))
                enqueueWithName(rawAsset[childNode.att.name], childNode.att.name);
                
                for (childNode in FastXML.filterNodes(typeXml.nodes.variable, function(x:FastXML) {
                    if(x.att.type == "Class")
                        return true;
                    return false;

                }))
                enqueueWithName(rawAsset[childNode.att.name], childNode.att.name);
            }
            else if (Type.getClassName(rawAsset) == "flash.filesystem::File") 
            {
                if (!rawAsset["exists"]) 
                {
                    log("File or directory not found: '" + rawAsset["url"] + "'");
                }
                else if (!rawAsset["isHidden"]) 
                {
                    if (rawAsset["isDirectory"]) 
                        enqueue.apply(this, rawAsset["getDirectoryListing"]())
                    else 
                    enqueueWithName(rawAsset["url"]);
                }
            }
            else if (Std.is(rawAsset, String)) 
            {
                enqueueWithName(rawAsset);
            }
            else 
            {
                log("Ignoring unsupported asset type: " + Type.getClassName(rawAsset));
            }
        }
    }
	*/
    
    /** Enqueues a single asset with a custom name that can be used to access it later. 
     *  If you don't pass a name, it's attempted to generate it automatically.
     *  @returns the name under which the asset was registered. */
    public function enqueueWithName(asset : Dynamic, name : String = null) : String
    {
        if (name == null)             name = getName(asset);
        log("Enqueuing '" + name + "'");
        
        mQueue.push({
                    name : name,
                    asset : asset,

                });
        
        return name;
    }
    
    /** Loads all enqueued assets asynchronously. The 'onProgress' function will be called
     *  with a 'ratio' between '0.0' and '1.0', with '1.0' meaning that it's complete.
     *
     *  @param onProgress: <code>function(ratio:Number):void;</code> 
     */
    public function loadQueue(onProgress : Function) : Void
    {
        if (Starling.current.context == null) 
            throw new Error("The Starling instance needs to be ready before textures can be loaded.");
        
        if (mIsLoading) 
            throw new Error("The queue is already being processed");
        
        var xmls : Array<Fast> = [];
        var numElements : Int = mQueue.length;
        var currentRatio : Float = 0.0;
        
		// TODO: these both rely on the other being declared first
		
		//function processNext() : Void
        //{
            //var assetInfo : Dynamic = mQueue.pop();
            //as3hx.Compat.clearTimeout(mTimeoutID);
            //processRawAsset(assetInfo.name, assetInfo.asset, xmls, progress, resume);
        //};
		
		function processXmls() : Void
        {
            // xmls are processed seperately at the end, because the textures they reference
            // have to be available for other XMLs. Texture atlases are processed first:
            // that way, their textures can be referenced, too.
            
            xmls.sort(function(a : Fast, b : Fast) : Int{
                        return (a.hasNode.resolve("TextureAtlas")) ? -1 : 1;
                    });
            
            for (xml in xmls)
            {
                var name : String;
                var texture : Texture;
                var rootNode : String = xml.name;
                
                if (rootNode == "TextureAtlas") 
                {
                    // Do not create the atlas after load is finished, wait until a request is made
                    name = getName(Std.string(xml.att.imagePath));
                    
                    if (m_savedBitmapData.exists(name)) 
                    {
                        Reflect.setField(m_savedEmbeddedAtlasXml, name, xml);
                    }
                    else 
                    {
                        log("Cannot create atlas: texture '" + name + "' is missing.");
                    }
                }
                else if (rootNode == "font") 
                {
                    name = getName(Std.string(xml.node.pages.node.page.att.file));
                    texture = getTexture(name);
                    
                    if (texture != null) 
                    {
                        log("Adding bitmap font '" + name + "'");
                        TextField.registerBitmapFont(new BitmapFont(texture, xml.x), name);
                        removeTexture(name, false);
                    }
                    else log("Cannot create bitmap font: texture '" + name + "' is missing.");
                }
                else 
                throw new Error("XML contents not recognized: " + rootNode);
            }
        };
		
		function resume() : Void
        {
            if (!mIsLoading) 
                return;
            
			// TODO: ask about this
            //currentRatio = (mQueue.length) ? 1.0 - (mQueue.length / numElements) : 1.0;
            
            //if (mQueue.length) 
            //{
                // Do not set timeout, otherwise embedded assets take far too long to load
                //mTimeoutID = 0;
                //processNext();
            //}
            //else 
            {
                processXmls();
                mIsLoading = false;
            }
            
            if (onProgress != null) 
                onProgress(currentRatio);
        };
		//
        mIsLoading = true;
        resume();
        
        function progress(ratio : Float) : Void
        {
            onProgress(currentRatio + (1.0 / numElements) * Math.min(1.0, ratio) * 0.99);
        };
    }
    
    /**
     *
     * @param onProgress
     * @param onComplete
     *      signature callback():void, called when asset is finished
     */
    private function processRawAsset(name : String, rawAsset : Dynamic, xmls : Array<Fast>,
            onProgress : Function, onComplete : Void->Void) : Void
    {
		function process(asset : Dynamic) : Void
        {
            var texture : Texture;
            var bytes : ByteArray;
            
            if (!mIsLoading) 
            {
                onComplete();
            }
            else if (Std.is(asset, Sound)) 
            {
                addSound(name, try cast(asset, Sound) catch(e:Dynamic) null);
                onComplete();
            }
            else if (Std.is(asset, Bitmap)) 
            {
                // The bitmap data needs to be preserved so it can be used later
                // Do not create texture immediately from it as we don't known when it is
                // going to be used and don't want it using graphics memory
                Reflect.setField(m_savedBitmapData, name, (try cast(asset, Bitmap) catch(e:Dynamic) null).bitmapData);
                onComplete();
            }
            else if (Std.is(asset, ByteArray)) 
            {
                bytes = try cast(asset, ByteArray) catch(e:Dynamic) null;
                
                if (AtfData.isAtfData(bytes)) 
                {
                    texture = Texture.fromAtfData(bytes, mScaleFactor, mUseMipMaps, onComplete);
                    texture.root.onRestore = function() : Void
                            {
                                mNumLostTextures++;
                                loadRawAsset(name, rawAsset, null, function(asset : Dynamic) : Void
                                        {
                                            try{texture.root.uploadAtfData(try cast(asset, ByteArray) catch(e:Dynamic) null, 0, true);
                                            }                                            catch (e : Error){log("Texture restoration failed: " + e.message);
                                            }
                                            
                                            asset.clear();
                                            mNumRestoredTextures++;
                                            
                                            if (mNumLostTextures == mNumRestoredTextures) 
                                                dispatchEventWith(Event.TEXTURES_RESTORED);
                                        });
                            };
                    
                    bytes.clear();
                    addTexture(name, texture);
                }
                else if (byteArrayStartsWith(bytes, "{") || byteArrayStartsWith(bytes, "[")) 
                {
                    addObject(name, haxe.Json.parse(bytes.readUTFBytes(bytes.length)));
                    bytes.clear();
                    onComplete();
                }
                else if (byteArrayStartsWith(bytes, "<")) 
                {
                    process(new Fast(Xml.parse(bytes.toString())));
                    bytes.clear();
                }
                else 
                {
                    addByteArray(name, bytes);
                    onComplete();
                }
            }
            else if (Std.is(asset, Fast)) 
            {
                var xml : Fast = try cast(asset, Fast) catch(e:Dynamic) null;
                var rootNode : String = xml.name;
                
                if (rootNode == "TextureAtlas" || rootNode == "font") 
                    xmls.push(xml)
                else 
                addXml(name, xml);
                
                onComplete();
            }
            // avoid that objects stay in memory (through 'onRestore' functions)
            else if (asset == null) 
            {
                onComplete();
            }
            else 
            {
                log("Ignoring unsupported asset type: " + Type.getClassName(asset));
                onComplete();
            }
            
            
            
            asset = null;
            bytes = null;
        };
		
        loadRawAsset(name, rawAsset, onProgress, process);
    }
    
    private function loadRawAsset(name : String, rawAsset : Dynamic,
            onProgress : Function, onComplete : Function) : Void
    {
        var extension : String = null;
        var urlLoader : URLLoader = null;
        
        if (Std.is(rawAsset, Class)) 
        {
            // Roy-
            // Remove timeout to prevent a delay from occuring for already 'embedded' assets
			// TODO: ask about this function
            //onComplete(new RawAsset());
        }
        else if (Std.is(rawAsset, String)) 
        {
            var url : String = try cast(rawAsset, String) catch(e:Dynamic) null;
            extension = url.split(".").pop().toLowerCase().split("?")[0];
            
            // TODO:
            // For mobile, relative paths are not usuable with a url loader,
            // we need to use the Air file system.
            
            // First check if the path given is a relative path and that the asset manager
            // is configured to translate those paths.
            if (resourcePathBase != null) 
            {
                url = this.stripRelativePartsFromPath(url, this.resourcePathBase);
            }
			
			function onIoError(event : IOErrorEvent) : Void
			{
				// Should somehow propagate errors so other parts of game know that an error has occurred
				// in resource loading so it can at least show a notification to the user.
				
				log("IO error: " + event.text);
				onComplete(null);
			};
			
			function onLoadProgress(event : ProgressEvent) : Void
			{
				if (onProgress != null) 
					onProgress(event.bytesLoaded / event.bytesTotal);
			};
			
			function onLoaderComplete(event : Dynamic) : Void
			{
				urlLoader.data.clear();
				event.target.removeEventListener(Event.COMPLETE, onLoaderComplete);
				onComplete(event.target.content);
			};
			
			function onUrlLoaderComplete(event : Dynamic) : Void
			{
				var bytes : ByteArray = try cast(urlLoader.data, ByteArray) catch(e:Dynamic) null;
				var sound : Sound;
				
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
				urlLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
				
				switch (extension)
				{
					case "mp3":
						sound = new Sound();
						sound.loadCompressedDataFromByteArray(bytes, bytes.length);
						bytes.clear();
						onComplete(sound);
					case "jpg", "jpeg", "png", "gif":
						var loaderContext : LoaderContext = new LoaderContext(mCheckPolicyFile);
						var loader : Loader = new Loader();
						//loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
						loader.loadBytes(bytes, loaderContext);
					default:  // any XML / JSON / binary data  
						onComplete(bytes);
				}
			};
			
            urlLoader = new URLLoader();
            urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
            urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
            urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
            urlLoader.load(new URLRequest(url));
        }
    }
    
    // helpers
    
    /** This method is called by 'enqueue' to determine the name under which an asset will be
     *  accessible; override it if you need a custom naming scheme. Typically, 'rawAsset' is 
     *  either a String or a FileReference. Note that this method won't be called for embedded
     *  assets. */
    public function getName(rawAsset : Dynamic) : String
    {
        var matches : Array<Dynamic> = null;
        var name : String;
        
        if (Std.is(rawAsset, String) || Std.is(rawAsset, FileReference)) 
        {
            name = (Std.is(rawAsset, String)) ? try cast(rawAsset, String) catch(e:Dynamic) null : (try cast(rawAsset, FileReference) catch(e:Dynamic) null).name;
            name = (new EReg('%20', "g")).replace(name, " ");  // URLs use '%20' for spaces  
			// TODO: there doesn't seem to be a haxe equivalent of what was done here
            //matches = new EReg('(.*[\\\\\\/])?(.+)(\\.[\\w]{1,4})', "").exec(name);
            //
            if (matches != null && matches.length == 4)                 return matches[2]
            else throw new ArgumentError("Could not extract name from String '" + rawAsset + "'");
        }
        else 
        {
            name = Type.getClassName(rawAsset);
            throw new ArgumentError("Cannot extract names for objects of type '" + name + "'");
        }
    }
    
    /** This method is called during loading of assets when 'verbose' is activated. Per
     *  default, it traces 'message' to the console. */
    private function log(message : String) : Void
    {
        if (mVerbose)             trace("[AssetManager]", message);
    }
    
    private function byteArrayStartsWith(bytes : ByteArray, char : String) : Bool
    {
        var start : Int = 0;
        var length : Int = bytes.length;
        var wanted : Int = char.charCodeAt(0);
        
        // recognize BOMs
        
        if (length >= 4 &&
            (bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xfe && bytes[3] == 0xff) ||
            (bytes[0] == 0xff && bytes[1] == 0xfe && bytes[2] == 0x00 && bytes[3] == 0x00)) 
        {
            start = 4;
        }
        else if (length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf) 
        {
            start = 3;
        }
        // find first meaningful letter
        else if (length >= 2 &&
            (bytes[0] == 0xfe && bytes[1] == 0xff) || (bytes[0] == 0xff && bytes[1] == 0xfe)) 
        {
            start = 2;
        }
        
        
        
        
        for (i in start...length){
            var byte : Int = bytes[i];
            if (byte == 0 || byte == 10 || byte == 13 || byte == 32)                 continue
            // null, \n, \r, space
            else return byte == wanted;
        }
        
        return false;
    }
    
    private function getDictionaryKeys(dictionary : Dictionary<String, Dynamic>, prefix : String = "",
            result : Array<String> = null) : Array<String>
    {
        if (result == null)             result = [];
        
        for (name in Reflect.fields(dictionary))
        if (name.indexOf(prefix) == 0) 
            result.push(name);
        
        result.sort(function cmp(s1 : String, s2 : String) : Int {
			s1 = s1.toLowerCase();
			s2 = s2.toLowerCase();
			for (i in 0...Std.int(Math.min(s1.length, s2.length))) {
				var c1 = s1.charCodeAt(i);
				var c2 = s2.charCodeAt(i);
				if (c1 != c2) return c1 - c2;
			}
			
			if (s1.length == s2.length) return 0;
			else if (s1.length < s2.length) return 1;
			else return -1;
		});
        return result;
    }
    
    /**
     * Return new url with relative portions striped
     */
    public function stripRelativePartsFromPath(url : String, newBase : String) : String
    {
        // Chop off the relative portion, like ./ or ../ to remove relative references
        // To dumb strip that keeps going until we no longer see a . or /
        var i : Int;
        var numCharacters : Int = url.length;
        var prevCharacter : String = null;
        var indexToStartSubstring : Int = -1;
        for (i in 0...numCharacters){
            var currentCharacter : String = url.charAt(i);
            if (currentCharacter != "/" && currentCharacter != ".") 
            {
                // A character that is not a dot should terminate the search as
                // this indicates there is is no more relative parts to process
                indexToStartSubstring = i;
                break;
            }
            
            prevCharacter = currentCharacter;
        }
        
        var strippedUrl : String = url.substr(indexToStartSubstring);
        if (newBase.charAt(newBase.length - 1) != "/") 
        {
            strippedUrl = "/" + strippedUrl;
        }
        url = newBase + strippedUrl;
        
        return url;
    }
    
    // properties
    
    /** The queue contains one 'Object' for each enqueued asset. Each object has 'asset'
     *  and 'name' properties, pointing to the raw asset and its name, respectively. */
    private function get_queue() : Array<Dynamic>{return mQueue;
    }
    
    /** Returns the number of raw assets that have been enqueued, but not yet loaded. */
    private function get_numQueuedAssets() : Int{return mQueue.length;
    }
    
    /** When activated, the class will trace information about added/enqueued assets. */
    private function get_verbose() : Bool{return mVerbose;
    }
    private function set_verbose(value : Bool) : Bool{mVerbose = value;
        return value;
    }
    
    /** For bitmap textures, this flag indicates if mip maps should be generated when they 
     *  are loaded; for ATF textures, it indicates if mip maps are valid and should be
     *  used. */
    private function get_useMipMaps() : Bool{return mUseMipMaps;
    }
    private function set_useMipMaps(value : Bool) : Bool{mUseMipMaps = value;
        return value;
    }
    
    /** Textures that are created from Bitmaps or ATF files will have the scale factor 
     *  assigned here. */
    private function get_scaleFactor() : Float{return mScaleFactor;
    }
    private function set_scaleFactor(value : Float) : Float{mScaleFactor = value;
        return value;
    }
    
    /** Specifies whether a check should be made for the existence of a URL policy file before
     *  loading an object from a remote server. More information about this topic can be found 
     *  in the 'flash.system.LoaderContext' documentation. */
    private function get_checkPolicyFile() : Bool{return mCheckPolicyFile;
    }
    private function set_checkPolicyFile(value : Bool) : Bool{mCheckPolicyFile = value;
        return value;
    }
}

