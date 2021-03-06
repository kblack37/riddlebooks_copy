package wordproblem.resource;

import cgs.audio.IAudioResource;
import cgs.levelProgression.util.ICgsLevelResourceManager;
import openfl.Lib;

import haxe.Constraints.Function;
import haxe.xml.Fast;

import openfl.Assets;
import openfl.Vector;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Loader;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.FileReference;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.system.LoaderContext;
import openfl.text.TextField;
import openfl.utils.ByteArray;

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
class AssetManager extends EventDispatcher implements ICgsLevelResourceManager implements IAudioResource
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
    
	private var mBitmapData : Map<String, BitmapData>;
    private var mSounds : Map<String, Sound>;
    private var mXmls : Map <String, Xml>;
    private var mObjects : Map<String, Dynamic>;
    private var mByteArrays : Map<String, ByteArray>;
    
    /**
     * For embedded texture atlas, we have the image and an xml that defines how to segment the image
     * into regions.
     * 
     * We don't want that huge atlas image texture sitting in the limited space of the graphics memory,
     * so we need to potentially load it into there multiple times. This require recreating the
     * TextureAtlas object multiple times, in this case it needs the xml multiple times to segment
     * the image into regions.
     */
    private var m_savedEmbeddedAtlasXml : Map<String, Xml>;
    
    /**
     * Mapping from the id/name used to fetch a resource from this manager to a count of how
     * many times we think it is actively being used at the moment.
     * 
     * The purpose of this is that whenever the count for a particular texture is zero, we can safely dispose
     * the texture (thus freeing it from graphics memory)
     */
    private var m_bitmapDataIdToUsageCount : Dynamic;
	
	/**
	 * Used so that clients of the asset manager can use a short name of an asset instead of the full path
	 */
	private var m_assetNameToPathMap : AssetNameToPathMap;
    
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
        mScaleFactor = (scaleFactor > 0) ? scaleFactor : Lib.application.window.scale;
        mUseMipMaps = useMipmaps;
        mQueue = [];
		mBitmapData = new Map();
        mSounds = new Map();
        mXmls = new Map();
        mObjects = new Map();
        mByteArrays = new Map();
        
        m_savedEmbeddedAtlasXml = new Map();
        m_bitmapDataIdToUsageCount = { };
		
		m_assetNameToPathMap = new AssetNameToPathMap();
        
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
            }  
			
			// This bundle can be loaded by the default Starling AssetManager, we can  
			// just enqueue then loadQueue on it. (Starling knows how to load a class  
            // with static embedded resources already)  
            var className : String = Type.getClassName(Type.getClass(resourceBundle));
            var classObject : Class<Dynamic> = Type.resolveClass(className);
            enqueue([classObject]);
            
            numStarlingLoadableBundles++;
        }  
		
		// All assets that are loadable from starling's default manager are loaded as a single blob,  
        // Thus the total number of bundled resources need to treat the starling assets as only one large bundle 
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
     * @param atlasName
     *      Name that will act as the key to fetch the atlas from starling
     * @param onImagesLoaded
     *      Callback when all images have been loaded, accepts a list
     *      of bitmapdata objects containing the images. They are indexed
     *      in the same order as the list of nodes.
     */
	// TODO: atlases must be redesigned using openfl's Tile API
    public function loadDynamicAtlas(imagesToLoad : Array<Dynamic>,
            imageIds : Array<String>,
            atlasName : String,
            onComplete : Function) : Void
    {
        // Keep track of all images to load in the array.
        // For initial simplicity we load them all in sequential order
        //var bitmapIdsToLoad : Array<String> = new Array<String>();
        //var idToBitmapMap : Map<String, Bitmap> = new Map<String, Bitmap>();
        //var numImages : Int = imagesToLoad.length;
        //var bitmap : Bitmap = null;
        //var bitmapId : String = null;
        //for (i in 0...numImages){
            //var imageData : Dynamic = imagesToLoad[i];
            //bitmapId = imageIds[i];
            //if (Std.is(imageData, Class)) 
            //{
                //// Immediately instantiate the object as a bitmap
                //var imageDataClass : Class<Dynamic> = Type.getClass(imageData);
                //bitmap = try cast(Type.createInstance(imageDataClass, []), Bitmap) catch (e:Dynamic) null;
				//idToBitmapMap.set(bitmapId, bitmap);
            //}
            //else if (Std.is(imageData, String)) 
            //{
                //// Attempt to load the image from the specified url
                //bitmapIdsToLoad.push(bitmapId);
                //enqueueWithName(imageData, bitmapId);
            //}
        //}
		//
		//function onAllBitmapsLoaded() : Void
        //{
            //var bitmaps : Array<Bitmap> = new Array<Bitmap>();
            //for (bitmapId in idToBitmapMap.keys())
            //{
				//bitmap = idToBitmapMap.get(bitmapId);
                //bitmap.name = bitmapId;
                //bitmaps.push(bitmap);
            //}
            //
			//// TODO: design a dynamic openfl Tileset builder from the bitmaps
            ////var dynamicAtlas : TextureAtlas = AtlasBuilder.build(bitmaps);
            ////addTextureAtlas(atlasName, dynamicAtlas);
            //
            //if (onComplete != null) 
            //{
                //onComplete();
            //}
        //};
        //
        //if (bitmapIdsToLoad.length > 0) 
        //{
            //loadQueue(function(ratio : Float) : Void
                    //{
                        //if (ratio >= 1.0) 
                        //{
                            //for (bitmapId in Reflect.fields(bitmapIdsToLoad))
                            //{
                                //Reflect.setField(idToBitmapMap, bitmapId, new Bitmap(try cast(Reflect.field(m_savedBitmapData, bitmapId), BitmapData) catch(e:Dynamic) null));
                            //}
                            //
                            //onAllBitmapsLoaded();
                        //}
                    //});
        //}
        //else 
        //{
            //onAllBitmapsLoaded();
        //}
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
		for (bitmapData in mBitmapData.iterator()) {
			bitmapData.dispose();
		}
    }
    
    /**
     * Get whether a texture for the given name has been created and is available
     * for use.
     */
    public function hasBitmapData(name : String) : Bool
    {
        return mBitmapData.exists(name);
    }
    
    /**
     * For any textures that aren't commonly used, use this to get the texture that increments a usage
     * counter so the application can keep track of what textures are currently visible.
     * 
     * Be sure to call the corresponding releaseTextureWithReferenceCount function when the texture
     * is no longer needed. It is important because texture memory is a very limited resource and large
     * textures that are only used is a few places should not be taking up space whenever it is not actually shown.
     */
    public function getBitmapDataWithReferenceCount(name : String) : BitmapData
    {
        var bitmapData : BitmapData = getBitmapData(name);
        if (bitmapData != null) 
        {
            if (!m_bitmapDataIdToUsageCount.exists(name)) 
            {
                Reflect.setField(m_bitmapDataIdToUsageCount, name, 0);
            }
            
            Reflect.setField(m_bitmapDataIdToUsageCount, name, Reflect.field(m_bitmapDataIdToUsageCount, name) + 1);
        }
        
        return bitmapData;
    }
    
    /**
     * This should be called whenever a texture called with getTextureWithReferenceCount has been fetched.
     * The purpose is to is to free the limited texture memory from assets that will no longer be needed.
     */
    public function releaseBitmapDataWithReferenceCount(name : String) : Void
    {
        if (Reflect.hasField(m_bitmapDataIdToUsageCount, name)) 
        {
            Reflect.setField(m_bitmapDataIdToUsageCount, name, Reflect.field(m_bitmapDataIdToUsageCount, name) - 1);
            if (Reflect.field(m_bitmapDataIdToUsageCount, name) <= 0) 
            {
                removeBitmapData(name, true);
            }
        }
    }
    
    // retrieving
    
	// TODO: texture atlases must be redesigned, most likely with the openfl Tilemap API
    /** Returns a texture atlas with a certain name, or null if it's not found. */
    //public function getTextureAtlas(name : String) : TextureAtlas
    //{
        //var textureAtlas : TextureAtlas = null;
        //if (mAtlases.exists(name)) 
        //{
            //textureAtlas = try cast(Reflect.field(mAtlases, name), TextureAtlas) catch(e:Dynamic) null;
        //}
        //// Create the atlas if this is the first request for it
        //else if (m_savedEmbeddedAtlasXml.exists(name)) 
        //{
            //var texture : Texture = Texture.fromBitmapData(try cast(Reflect.field(m_savedBitmapData, name), BitmapData) catch(e:Dynamic) null, false);
            //textureAtlas = new TextureAtlas(texture, try cast(Reflect.field(m_savedEmbeddedAtlasXml, name).x, Xml) catch(e:Dynamic) null);
            //addTextureAtlas(name, textureAtlas);
        //}
        //return textureAtlas;
    //}
	
	/** Returns bitmap data with a certain name, or null if it's not found. */
    public function getBitmapData(name : String) : BitmapData
    {
		var bmpData : BitmapData = null;
		
		// First check if it's been loaded already; use that if yes
		// Second check if it's embedded; use that if yes
		// If neither of these, return null
		if (mBitmapData.exists(name)) {
			bmpData = mBitmapData.get(name);
		} else {
			if (m_assetNameToPathMap.hasPathForName(name)) {
				bmpData = Assets.getBitmapData(m_assetNameToPathMap.getPathForName(name));
			} else {
				bmpData = Assets.getBitmapData(name);
			}
		}
		
		if (bmpData == null) trace("Couldn't find bitmap data with name " + name);
		
		return bmpData;
    }
	
	/** Returns all bitmap data that start with a certain string, sorted alphabetically
     *  (especially useful for "MovieClip"). */
	public function getBitmapDataStartingWith(prefix : String = "", result : Array<BitmapData> = null) : Array<BitmapData>
	{
		if (result == null) result = [];
		
		for (name in getBitmapDataNames(prefix, sNames))
			result.push(getBitmapData(name));
		
		sNames = new Array<String>();
		
		return result;
	}
	
	/** Returns all bitmap data names that start with a certain string, sorted alphabetically.
     *  If you pass a result vector, the names will be added to that vector. */
	public function getBitmapDataNames(prefix : String = "", result : Array<String> = null) : Array<String>
	{
		return getDictionaryKeys(mBitmapData, prefix, result);
	}
    
    /** Returns a sound with a certain name, or null if it's not found. */
    public function getSound(name : String) : Sound
    {
		var sound : Sound = null;
		if (mSounds.exists(name)) {
			sound = mSounds.get(name);
		} else {
			if (m_assetNameToPathMap.hasPathForName(name)) {
				sound = Assets.getSound(m_assetNameToPathMap.getPathForName(name));
			} else {
				sound = Assets.getSound(name);
			}
		}
		return sound;
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
    public function getXml(name : String) : Xml
    {
		var xml : Xml = null;
		
		// First check if it's been loaded already; use that if yes
		// Second check if it's embedded; use that if yes
		// If neither of these, return null
		if (mXmls.exists(name)) {
			xml = mXmls.get(name);
		} else {
			var rawText : String = null;
			if (m_assetNameToPathMap.hasPathForName(name)) {
				rawText = Assets.getText(m_assetNameToPathMap.getPathForName(name));
			} else {
				rawText = Assets.getText(name);
			}
			
			if (rawText != null) xml = Xml.parse(rawText);
		}
		
		if (xml == null) trace("Couldn't find Xml with name " + name);
		
		return xml;
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
		return mObjects.get(name);
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
		return mByteArrays.get(name);
    }
    
    /** Returns all byte array names that start with a certain string, sorted alphabetically. 
     *  If you pass a result vector, the names will be added to that vector. */
    public function getByteArrayNames(prefix : String = "", result : Array<String> = null) : Array<String>
    {
        return getDictionaryKeys(mByteArrays, prefix, result);
    }
    
    // direct adding
	
	/** Register bitmap data under a certain name. It will be available right away. */
	public function addBitmapData(name : String, bitmapData : BitmapData) : Void
	{
		log("Adding bitmap data '" + name + "'");
		
		if (mBitmapData.exists(name)) 
			log("Warning: name was already in use; the previous bitmap data will be replaced.");
		
		mBitmapData.set(name, bitmapData);
	}
    
	// TODO: Texture Atlases need to be redesigned, most likely using the openfl Tilemap API
    /** Register a texture atlas under a certain name. It will be available right away. */
    //public function addTextureAtlas(name : String, atlas : TextureAtlas) : Void
    //{
        //log("Adding texture atlas '" + name + "'");
        //
        //if (mAtlases.exists(name)) 
            //log("Warning: name was already in use; the previous atlas will be replaced.");
        //
        //Reflect.setField(mAtlases, name, atlas);
    //}
    
    /** Register a sound under a certain name. It will be available right away. */
    public function addSound(name : String, sound : Sound) : Void
    {
        log("Adding sound '" + name + "'");
        
        if (mSounds.exists(name)) 
            log("Warning: name was already in use; the previous sound will be replaced.");
        
        mSounds.set(name, sound);
    }
    
    /** Register an XML object under a certain name. It will be available right away. */
    public function addXml(name : String, xml : Xml) : Void
    {
        log("Adding XML '" + name + "'");
        
        if (mXmls.exists(name)) 
            log("Warning: name was already in use; the previous XML will be replaced.");
        
		mXmls.set(name, xml);
    }
    
    /** Register an arbitrary object under a certain name. It will be available right away. */
    public function addObject(name : String, object : Dynamic) : Void
    {
        log("Adding object '" + name + "'");
        
        if (mObjects.exists(name)) 
            log("Warning: name was already in use; the previous object will be replaced.");
        
		mObjects.set(name, object);
    }
    
    /** Register a byte array under a certain name. It will be available right away. */
    public function addByteArray(name : String, byteArray : ByteArray) : Void
    {
        log("Adding byte array '" + name + "'");
        
        if (Lambda.has(mObjects, name)) 
            log("Warning: name was already in use; the previous byte array will be replaced.");
        
		mByteArrays.set(name, byteArray);
    }
    
    // removing
    
	// TODO: atlases must be redesigned using openfl's Tile API
    /** Removes a certain texture atlas, optionally disposing it. */
    //public function removeTextureAtlas(name : String, dispose : Bool = true) : Void
    //{
        //log("Removing texture atlas '" + name + "'");
        //
        //if (dispose && mAtlases.exists(name)) 
        //{
            //var textureAtlas : TextureAtlas = Reflect.field(mAtlases, name);
            //textureAtlas.dispose();
            //
            //if (Std.is(textureAtlas.texture, RenderTexture)) 
            //{
                //(try cast(textureAtlas.texture, RenderTexture) catch(e:Dynamic) null).clear();
                //(try cast(textureAtlas.texture, RenderTexture) catch(e:Dynamic) null).dispose();
            //}
            //
            //if (Std.is(textureAtlas.texture, SubTexture)) 
            //{
                //(try cast(textureAtlas.texture, SubTexture) catch(e:Dynamic) null).parent.dispose();
            //}
        //}
        //
        //;
    //}
	
	/** Removes a certain bitmap data. */
	public function removeBitmapData(name : String, dispose : Bool = true) : Void {
		log("Remove bitmap data '" + name + "'");
		
		var bitmapData = mBitmapData.get(name);
		if (bitmapData != null) {
			mBitmapData.remove(name);
			
			if (dispose) bitmapData.dispose();
		}
	}
    
    /** Removes a certain sound. */
    public function removeSound(name : String) : Void
    {
        log("Removing sound '" + name + "'");
		
		mSounds.remove(name);
    }
    
    /** Removes a certain Xml object, optionally disposing it. */
    public function removeXml(name : String, dispose : Bool = true) : Void
    {
        log("Removing xml '" + name + "'");
        
        if (dispose && mXmls.exists(name)) 
			mXmls.remove(name);
    }
    
    /** Removes a certain object. */
    public function removeObject(name : String) : Void
    {
        log("Removing object '" + name + "'");
		
		mObjects.remove(name);
    }
    
    /** Removes a certain byte array, optionally disposing its memory right away. */
    public function removeByteArray(name : String, dispose : Bool = true) : Void
    {
        log("Removing byte array '" + name + "'");
        
        if (dispose && mByteArrays.exists(name)) 
            mByteArrays.get(name).clear();
    }
    
    /** Empties the queue and aborts any pending load operations. */
    public function purgeQueue() : Void
    {
        mIsLoading = false;
		mQueue = new Array<Dynamic>();
		mTimeoutID = 0;
    }
    
    /** Removes assets of all types, empties the queue and aborts any pending load operations.*/
    public function purge() : Void
    {
        log("Purging all assets, emptying queue");
        purgeQueue();
        
        for (bitmapData in mBitmapData)
			bitmapData.dispose();
        
        mBitmapData = new Map();
        mSounds = new Map();
        mXmls = new Map();
        mObjects = new Map();
        mByteArrays = new Map();
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
    public function enqueue(rawAsset : Dynamic) : Void
    {
		if (Std.is(rawAsset, Array)) {
			for (asset in try cast(rawAsset, Array<Dynamic>) catch (e : Dynamic) null) {
				enqueue(asset);
			}
		}
        else if (Type.getClassName(rawAsset) == "flash.filesystem::File") 
        {
            if (!Reflect.field(rawAsset, "exists")) 
            {
                log("File or directory not found: '" + Reflect.field(rawAsset, "url") + "'");
            }
            else if (!Reflect.field(rawAsset, "isHidden")) 
            {
                if (Reflect.field(rawAsset, "isDirectory")) 
					enqueue(Reflect.field(rawAsset, "getDirectoryListing"));
                else 
					enqueueWithName(Reflect.field(rawAsset, "url"));
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
    
    /** Enqueues a single asset with a custom name that can be used to access it later. 
     *  If you don't pass a name, it's attempted to generate it automatically.
     *  @returns the name under which the asset was registered. */
    public function enqueueWithName(asset : Dynamic, name : String = null) : String
    {
        if (name == null) name = getName(asset);
        log("Enqueuing '" + name + "'");
        
        mQueue.push({ name : name, asset : asset });
        
        return name;
    }
    
    /** Loads all enqueued assets asynchronously. The 'onProgress' function will be called
     *  with a 'ratio' between '0.0' and '1.0', with '1.0' meaning that it's complete.
     *
     *  @param onProgress: <code>function(ratio:Number):void;</code> 
     */
    public function loadQueue(onProgress : Function) : Void
    {
		if (Lib.application.renderer == null)
            throw new Error("The renderer instance needs to be ready before textures can be loaded.");
        
        if (mIsLoading) 
            throw new Error("The queue is already being processed");
        
        var xmls : Array<Xml> = [];
        var numElements : Int = mQueue.length;
        var currentRatio : Float = 0.0;
        
		function progress(ratio : Float) : Void
        {
            onProgress(currentRatio + (1.0 / numElements) * Math.min(1.0, ratio) * 0.99);
        };
		
		function processXmls() : Void
        {
            // xmls are processed seperately at the end, because the textures they reference
            // have to be available for other XMLs. Texture atlases are processed first:
            // that way, their textures can be referenced, too.
            
            xmls.sort(function(a : Xml, b : Xml) : Int{
						var aFast : Fast = new Fast(a);
                        return (aFast.hasNode.resolve("TextureAtlas")) ? -1 : 1;
                    });
            
            for (xml in xmls)
            {
				var fastXml = new Fast(xml);
                var name : String = null;
                //var texture : Texture = null;
                var rootNode : String = fastXml.name;
                
				// TODO: atlases must be redesigned using openfl's Tile API
                //if (rootNode == "TextureAtlas") 
                //{
                    //// Do not create the atlas after load is finished, wait until a request is made
                    //name = getName(Std.string(fastXml.att.imagePath));
                    //
                    //if (m_savedBitmapData.exists(name)) 
                    //{
						//m_savedEmbeddedAtlasXml.set(name, fastXml.x);
                    //}
                    //else 
                    //{
                        //log("Cannot create atlas: texture '" + name + "' is missing.");
                    //}
                //}
				// TODO: a replacement for Starling Bitmap Fonts is needed
                //else if (rootNode == "font") 
                //{
                    //name = getName(Std.string(fastXml.node.pages.node.page.att.file));
                    //texture = getTexture(name);
                    //
                    //if (texture != null) 
                    //{
                        //log("Adding bitmap font '" + name + "'");
                        //TextField.registerBitmapFont(new BitmapFont(texture, fastXml.x), name);
                        //removeTexture(name, false);
                    //}
                    //else log("Cannot create bitmap font: texture '" + name + "' is missing.");
                //}
                //else 
                //throw new Error("XML contents not recognized: " + rootNode);
            }
        };
		
		function resume() : Void
        {
            if (!mIsLoading) 
                return;
            
            currentRatio = 1.0 - (mQueue.length / numElements);
            
            if (mQueue.length != 0) 
            {
                // Do not set timeout, otherwise embedded assets take far too long to load
                mTimeoutID = 0;
                processNext(xmls, progress, resume);
            }
            else 
            {
                processXmls();
                mIsLoading = false;
            }
            
            if (onProgress != null) 
                onProgress(currentRatio);
        };
		
        mIsLoading = true;
        resume();
    }
	
	private function processNext(xmls : Array<Xml>, progress : Function, resume : Function) : Void
    {
        var assetInfo : Dynamic = mQueue.pop();
		mTimeoutID = 0;
        processRawAsset(assetInfo.name, assetInfo.asset, xmls, progress, resume);
    };
    
    /**
     *
     * @param onProgress
     * @param onComplete
     *      signature callback():void, called when asset is finished
     */
    private function processRawAsset(name : String, rawAsset : Dynamic, xmls : Array<Xml>,
            onProgress : Function, onComplete : Function) : Void
    {
		function process(asset : Dynamic) : Void
		{
            var bytes : ByteArray = null;
            
            if (!mIsLoading) 
            {
                onComplete();
            }
            else if (Std.is(asset, Sound)) 
            {
                addSound(name, try cast(asset, Sound) catch(e:Dynamic) null);
                onComplete();
            }
            else if (Std.is(asset, BitmapData)) 
            {
				addBitmapData(name, try cast(asset, BitmapData) catch (e : Dynamic) null);
                onComplete();
            }
            else if (Std.is(asset, ByteArrayData)) 
            {
                bytes = try cast(asset, ByteArray) catch(e:Dynamic) null;
                
                if (byteArrayStartsWith(bytes, "{") || byteArrayStartsWith(bytes, "[")) 
                {
                    addObject(name, haxe.Json.parse(bytes.readUTFBytes(bytes.length)));
                    bytes.clear();
                    onComplete();
                }
                else if (byteArrayStartsWith(bytes, "<")) 
                {
                    process(Xml.parse(bytes.toString()));
                    bytes.clear();
                }
                else 
                {
                    addByteArray(name, bytes);
                    onComplete();
                }
            }
            else if (Std.is(asset, Xml)) 
            {
                var xml : Xml = try cast(asset, Xml) catch(e:Dynamic) null;
                var rootNode : String = xml.firstElement().nodeName;
                
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
                log("Ignoring unsupported asset type: " + Type.getClassName(Type.getClass(asset)));
                onComplete();
            }
			
			bytes = null;
        };
		
        loadRawAsset(name, rawAsset, onProgress, process);
    }
    
    private function loadRawAsset(name : String, rawAsset : Dynamic,
            onProgress : Function, onComplete : Dynamic->Void) : Void
    {
        if (Std.is(rawAsset, String)) 
        {
            var url : String = try cast(rawAsset, String) catch(e:Dynamic) null;
            var extension = url.split(".").pop().toLowerCase().split("?")[0];
			
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
			
			function onLoadProgress(bytesLoaded : Int, bytesTotal : Int) {
				if (onProgress != null) onProgress(bytesLoaded / bytesTotal);
			}
			
			switch(extension) {
				case "mp3":
					var future = Assets.loadSound(url).onError(onIoError).onProgress(onLoadProgress).onComplete(onComplete);
				case "jpg", "jpeg", "png", "gif":
					var future = Assets.loadBitmapData(url).onError(onIoError).onProgress(onLoadProgress).onComplete(onComplete);
				default:
					var future = Assets.loadBytes(url).onError(onIoError).onProgress(onLoadProgress).onComplete(onComplete);
			}
        }
    }
    
    // helpers
    
    /** This method is called by 'enqueue' to determine the name under which an asset will be
     *  accessible; override it if you need a custom naming scheme. Typically, 'rawAsset' is 
     *  either a String or a FileReference. Note that this method won't be called for embedded
     *  assets. */
    public function getName(rawAsset : Dynamic) : String
    {
        var name : String = null;
        
        if (Std.is(rawAsset, String) || Std.is(rawAsset, FileReference)) 
        {
            name = (Std.is(rawAsset, String)) ? try cast(rawAsset, String) catch(e:Dynamic) null : (try cast(rawAsset, FileReference) catch(e:Dynamic) null).name;
            name = (new EReg('%20', "g")).replace(name, " ");  // URLs use '%20' for spaces
			var matches = new EReg('(.*[\\\\\\/])?(.+)(\\.[\\w]{1,4})', "");
			
            if (matches.match(name) && matchedAllSubgroups(matches, 3)) 
				return matches.matched(2);
            else 
				throw new ArgumentError("Could not extract name from String '" + rawAsset + "'");
        }
        else 
        {
            name = Type.getClassName(rawAsset);
            throw new ArgumentError("Cannot extract names for objects of type '" + name + "'");
        }
    }
	
	private function matchedAllSubgroups(ereg : EReg, numSubgroups : Int) : Bool {
		var matched : Bool = true;
		for (i in 1...(numSubgroups + 1)) {
			try (ereg.matched(i)) catch (e : Dynamic) matched = false;
		}
		return matched;
	}
    
    /** This method is called during loading of assets when 'verbose' is activated. Per
     *  default, it traces 'message' to the console. */
    private function log(message : String) : Void
    {
        if (mVerbose) trace("[AssetManager]", message);
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
    
    private function getDictionaryKeys(dictionary : Map<String, Dynamic>, prefix : String = "",
            result : Array<String> = null) : Array<String>
    {
        if (result == null)             result = [];
        
        for (name in dictionary.keys()) {
			if (name.indexOf(prefix) == 0) 
				result.push(name);
		}
        
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
        var i : Int = 0;
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

