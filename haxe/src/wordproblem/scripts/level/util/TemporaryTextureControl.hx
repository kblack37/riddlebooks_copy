package wordproblem.scripts.level.util;


import dragonbox.common.dispose.IDisposable;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import wordproblem.resource.AssetManager;

/**
 * This class handles the access of textures that we only want to temporarily store
 * in the graphics memory.
 * 
 * For example a level might need pictures of animals, we load the textures for those images but need
 * to remember to release them when the level terminates since they may never be needed again in this session.
 * This class makes it easier to remember which textures need to be cleaned out.
 * 
 * A bit ugly but we also have this double up as temporary storage for image we want to save
 * so we don't have to recreate. Useful for images made from custom rendered textures like avatars and other things
 * built from flash assets
 */
class TemporaryTextureControl implements IDisposable
{
    private var m_assetManager : AssetManager;
    
    /**
     * List of all textures accessed since last dispose call that need to be cleaned up
     * at the end.
     */
    private var m_bitmapDataNamesToDispose : Array<String>;
    
    /**
     * Map from assigned id to an image
     */
    private var m_savedImages : Dynamic;
    
    public function new(assetManager : AssetManager)
    {
        m_assetManager = assetManager;
        m_bitmapDataNamesToDispose = new Array<String>();
        m_savedImages = { };
    }
    
    /**
     * Warning: Be sure to only access textures that are only used within this level.
     */
    public function getDisposableTexture(bitmapDataName : String) : BitmapData
    {
        var disposableBitmapData : BitmapData = m_assetManager.getBitmapData(bitmapDataName);
        if (disposableBitmapData != null && Lambda.indexOf(m_bitmapDataNamesToDispose, bitmapDataName) == -1) 
        {
            m_bitmapDataNamesToDispose.push(bitmapDataName);
        }
        
        return disposableBitmapData;
    }
    
    public function dispose() : Void
    {
        var i : Int = 0;
        for (i in 0...m_bitmapDataNamesToDispose.length){
            var bitmapDataName : String = m_bitmapDataNamesToDispose[i];
            m_assetManager.removeBitmapData(bitmapDataName, true);
        }
        
		m_bitmapDataNamesToDispose = new Array<String>();
        
        // Delete all temp image saved within here
        for (id in Reflect.fields(m_savedImages))
        {
            this.deleteImageWithId(id);
        }
    }
    
    /**
     * Avatars are custom created textures that aren't very re-usable.
     * We need to be careful about how these images are managed
     */
    public function saveImageWithId(id : String, avatarImage : Bitmap) : Void
    {
        Reflect.setField(m_savedImages, id, avatarImage);
    }
    
    /**
     * Get back a saved avatar from the id
     */
    public function getImageWithId(id : String) : Bitmap
    {
        return ((m_savedImages.exists(id))) ? 
			Reflect.field(m_savedImages, id) : null;
    }
    
    /**
     * Delete a saved avatar image and properly dispose of the texture made for it.
     */
    public function deleteImageWithId(id : String) : Void
    {
        if (m_savedImages.exists(id)) 
        {
            var savedImage : Bitmap = try cast(Reflect.field(m_savedImages, id), Bitmap) catch (e:Dynamic) null;
			if (savedImage.parent != null) savedImage.parent.removeChild(savedImage);
			savedImage.bitmapData.dispose();
        }
    }
}
