package wordproblem.scripts.level.util
{
    import dragonbox.common.dispose.IDisposable;
    
    import starling.display.Image;
    import starling.textures.Texture;
    
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
    public class TemporaryTextureControl implements IDisposable
    {
        private var m_assetManager:AssetManager;
        
        /**
         * List of all textures accessed since last dispose call that need to be cleaned up
         * at the end.
         */
        private var m_textureNamesToDispose:Vector.<String>;
        
        /**
         * Map from assigned id to an image
         */
        private var m_savedImages:Object;
        
        public function TemporaryTextureControl(assetManager:AssetManager)
        {
            m_assetManager = assetManager;
            m_textureNamesToDispose = new Vector.<String>();
            m_savedImages = {};
        }
        
        /**
         * Warning: Be sure to only access textures that are only used within this level.
         */
        public function getDisposableTexture(textureName:String):Texture
        {
            var disposableTexture:Texture = m_assetManager.getTexture(textureName);
            if (disposableTexture != null && m_textureNamesToDispose.indexOf(textureName) == -1)
            {
                m_textureNamesToDispose.push(textureName);
            }
            
            return disposableTexture;
        }
        
        public function dispose():void
        {
            var i:int;
            for (i = 0; i < m_textureNamesToDispose.length; i++)
            {
                var textureName:String = m_textureNamesToDispose[i];
                m_assetManager.removeTexture(textureName, true);
            }
            
            m_textureNamesToDispose.length = 0;
            
            // Delete all temp image saved within here
            for (var id:String in m_savedImages)
            {
                this.deleteImageWithId(id);
            }
        }
        
        /**
         * Avatars are custom created textures that aren't very re-usable.
         * We need to be careful about how these images are managed
         */
        public function saveImageWithId(id:String, avatarImage:Image):void
        {
            m_savedImages[id] = avatarImage;
        }
        
        /**
         * Get back a saved avatar from the id
         */
        public function getImageWithId(id:String):Image
        {
            return (m_savedImages.hasOwnProperty(id)) ?
                m_savedImages[id] : null;
        }
        
        /**
         * Delete a saved avatar image and properly dispose of the texture made for it.
         */
        public function deleteImageWithId(id:String):void
        {
            if (m_savedImages.hasOwnProperty(id))
            {
                var savedImage:Image = m_savedImages[id] as Image;
                savedImage.removeFromParent(true);
                savedImage.texture.dispose();
                delete m_savedImages[id];
            }
        }
    }
}