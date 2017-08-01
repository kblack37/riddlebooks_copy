package wordproblem.playercollections.items;


import flash.geom.Rectangle;

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
class PlayerCollectionItemButton extends Sprite
{
    public var selected(never, set) : Bool;

    private var m_normalBackground : Image;
    private var m_selectedBackground : Image;
    
    private var m_itemId : String;
    private var m_locked : Bool;
    
    /**
     * Record the texture name for the item, we need to dispose of it later so we
     * don't cause the texture buffer to run out of memory later
     */
    private var m_itemTextureName : String;
    private var m_assetManager : AssetManager;
    
    public function new(itemTextureName : String,
            itemId : String,
            locked : Bool,
            assetManager : AssetManager,
            width : Float,
            height : Float,
            defaultColor : Int,
            overColor : Int)
    {
        super();
        
        m_itemTextureName = itemTextureName;
        m_itemId = itemId;
        m_locked = locked;
        m_assetManager = assetManager;
        
        var scale9Texture : Texture = Texture.fromTexture(
			assetManager.getTexture("button_white"), 
			new Rectangle(8, 8, 16, 16)
        );
        m_normalBackground = new Image(scale9Texture);
        m_normalBackground.color = defaultColor;
        m_normalBackground.width = width;
        m_normalBackground.height = height;
        
        m_selectedBackground = new Image(scale9Texture);
        m_selectedBackground.color = overColor;
        m_selectedBackground.width = width;
        m_selectedBackground.height = height;
        
        addChild(m_normalBackground);
        
        // The actual item image may need to be scaled down such that when placed on a background
        // there is some padding around it
        var minimumEdgePadding : Float = 15;
        var maxWidth : Float = (width - 2 * minimumEdgePadding);
        var maxHeight : Float = (height - 2 * minimumEdgePadding);
        var texture : Texture = assetManager.getTextureWithReferenceCount(itemTextureName);
        var scaleFactor : Float = 1.0;
        if (texture.width > maxWidth || texture.height > maxHeight) 
        {
            var horizontalScaleFactor : Float = maxWidth / texture.width;
            var verticalScaleFactor : Float = maxHeight / texture.height;
            scaleFactor = Math.min(horizontalScaleFactor, verticalScaleFactor);
        }
        var itemImage : Image = new Image(texture);
        itemImage.scaleX = itemImage.scaleY = scaleFactor;
        itemImage.x = (width - itemImage.width) * 0.5;
        itemImage.y = (height - itemImage.height) * 0.5;
        
        
        var lockTexture : Texture = assetManager.getTexture("Art_LockRed");
        var lockImage : Image = new Image(lockTexture);
        var lockScaleFactor : Float = 1.0;
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
    
    public function getItemId() : String
    {
        return m_itemId;
    }
    
    public function getLocked() : Bool
    {
        return m_locked;
    }
    
    private function set_selected(value : Bool) : Bool
    {
        m_normalBackground.removeFromParent();
        m_selectedBackground.removeFromParent();
        
        var backgroundToUse : DisplayObject = ((value)) ? m_selectedBackground : m_normalBackground;
        addChildAt(backgroundToUse, 0);
        return value;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        m_assetManager.releaseTextureWithReferenceCount(m_itemTextureName);
    }
}
