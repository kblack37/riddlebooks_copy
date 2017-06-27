package wordproblem.playercollections.items
{
    import flash.geom.Rectangle;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.resource.AssetManager;
    
    /**
     * Simple button that represents a collectable item.
     * 
     * It should show the texture or some locked icon
     */
    public class PlayerCollectionItemButton extends Sprite
    {
        private var m_normalBackground:Scale9Image;
        private var m_selectedBackground:Scale9Image;
        
        private var m_itemId:String;
        private var m_locked:Boolean;
        
        /**
         * Record the texture name for the item, we need to dispose of it later so we
         * don't cause the texture buffer to run out of memory later
         */
        private var m_itemTextureName:String;
        private var m_assetManager:AssetManager;
        
        public function PlayerCollectionItemButton(itemTextureName:String,
                                                   itemId:String,
                                                   locked:Boolean,
                                                   assetManager:AssetManager, 
                                                   width:Number, 
                                                   height:Number, 
                                                   defaultColor:uint, 
                                                   overColor:uint)
        {
            super();
            
            m_itemTextureName = itemTextureName
            m_itemId = itemId;
            m_locked = locked;
            m_assetManager = assetManager;
            
            var scale9Texture:Scale9Textures = new Scale9Textures(
                assetManager.getTexture("button_white"),
                new Rectangle(8, 8, 16, 16)
            );
            m_normalBackground = new Scale9Image(scale9Texture);
            m_normalBackground.color = defaultColor;
            m_normalBackground.width = width;
            m_normalBackground.height = height;
            
            m_selectedBackground = new Scale9Image(scale9Texture);
            m_selectedBackground.color = overColor;
            m_selectedBackground.width = width;
            m_selectedBackground.height = height;
            
            addChild(m_normalBackground);
            
            // The actual item image may need to be scaled down such that when placed on a background
            // there is some padding around it
            var minimumEdgePadding:Number = 15;
            var maxWidth:Number = (width - 2 * minimumEdgePadding);
            var maxHeight:Number = (height - 2 * minimumEdgePadding);
            var texture:Texture = assetManager.getTextureWithReferenceCount(itemTextureName);
            var scaleFactor:Number = 1.0;
            if (texture.width > maxWidth || texture.height > maxHeight)
            {
                var horizontalScaleFactor:Number = maxWidth / texture.width;
                var verticalScaleFactor:Number = maxHeight / texture.height;
                scaleFactor = Math.min(horizontalScaleFactor, verticalScaleFactor);
            }
            var itemImage:Image = new Image(texture);
            itemImage.scaleX = itemImage.scaleY = scaleFactor;
            itemImage.x = (width - itemImage.width) * 0.5;
            itemImage.y = (height - itemImage.height) * 0.5;
            
            
            var lockTexture:Texture = assetManager.getTexture("Art_LockRed");
            var lockImage:Image = new Image(lockTexture);
            var lockScaleFactor:Number = 1.0;
            if (lockTexture.width > maxWidth || lockTexture.height > maxHeight)
            {
                lockScaleFactor = Math.min(maxWidth / lockTexture.width, maxHeight / lockTexture.height);
            }
            lockImage.scaleX = lockImage.scaleY = lockScaleFactor;
            lockImage.x = (width - lockImage.width) * 0.5;
            lockImage.y = (height - lockImage.height) * 0.5;
            
            if (locked)
            {
                addChild(lockImage);
            }
            else
            {
                addChild(itemImage);
            }
        }
        
        public function getItemId():String
        {
            return m_itemId;
        }
        
        public function getLocked():Boolean
        {
            return m_locked;
        }
        
        public function set selected(value:Boolean):void
        {
            m_normalBackground.removeFromParent();
            m_selectedBackground.removeFromParent();
            
            var backgroundToUse:DisplayObject = (value) ? m_selectedBackground : m_normalBackground;
            addChildAt(backgroundToUse, 0);
        }
        
        override public function dispose():void
        {
            super.dispose();
            m_assetManager.releaseTextureWithReferenceCount(m_itemTextureName);
        }
    }
}