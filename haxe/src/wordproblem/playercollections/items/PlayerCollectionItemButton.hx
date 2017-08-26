package wordproblem.playercollections.items;


import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import wordproblem.display.DisposableSprite;
import wordproblem.display.Scale9Image;

import openfl.display.DisplayObject;
import openfl.display.Sprite;

import wordproblem.resource.AssetManager;

/**
 * Simple button that represents a collectable item.
 * 
 * It should show the texture or some locked icon
 */
class PlayerCollectionItemButton extends DisposableSprite
{
    public var selected(never, set) : Bool;

    private var m_normalBackground : Scale9Image;
    private var m_selectedBackground : Scale9Image;
    
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
        
		var scale9Rect = new Rectangle(8, 8, 16, 16);
        var backgroundBitmapData : BitmapData = assetManager.getBitmapData("button_white");
		
        m_normalBackground = new Scale9Image(backgroundBitmapData, scale9Rect);
		m_normalBackground.transform.colorTransform = XColor.rgbToColorTransform(defaultColor);
        m_normalBackground.width = width;
        m_normalBackground.height = height;
        
        m_selectedBackground = new Scale9Image(backgroundBitmapData, scale9Rect);
		m_selectedBackground.transform.colorTransform = XColor.rgbToColorTransform(overColor);
        m_selectedBackground.width = width;
        m_selectedBackground.height = height;
        
        addChild(m_normalBackground);
        
        // The actual item image may need to be scaled down such that when placed on a background
        // there is some padding around it
        var minimumEdgePadding : Float = 15;
        var maxWidth : Float = (width - 2 * minimumEdgePadding);
        var maxHeight : Float = (height - 2 * minimumEdgePadding);
		// TODO: revisit this when AssetManager is fully implemented
        var bitmapData : BitmapData = null;// assetManager.getTextureWithReferenceCount(itemTextureName);
        var scaleFactor : Float = 1.0;
        if (bitmapData.width > maxWidth || bitmapData.height > maxHeight) 
        {
            var horizontalScaleFactor : Float = maxWidth / bitmapData.width;
            var verticalScaleFactor : Float = maxHeight / bitmapData.height;
            scaleFactor = Math.min(horizontalScaleFactor, verticalScaleFactor);
        }
        var itemImage : Bitmap = new Bitmap(bitmapData);
        itemImage.scaleX = itemImage.scaleY = scaleFactor;
        itemImage.x = (width - itemImage.width) * 0.5;
        itemImage.y = (height - itemImage.height) * 0.5;
        
        
        var lockBitmapData : BitmapData = assetManager.getBitmapData("Art_LockRed");
        var lockImage : Bitmap = new Bitmap(lockBitmapData);
        var lockScaleFactor : Float = 1.0;
        if (lockBitmapData.width > maxWidth || lockBitmapData.height > maxHeight) 
        {
            lockScaleFactor = Math.min(maxWidth / lockBitmapData.width, maxHeight / lockBitmapData.height);
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
        if (m_normalBackground.parent != null) m_normalBackground.parent.removeChild(m_normalBackground);
        if (m_selectedBackground.parent != null) m_selectedBackground.parent.removeChild(m_selectedBackground);
        
        var backgroundToUse : DisplayObject = ((value)) ? m_selectedBackground : m_normalBackground;
        addChildAt(backgroundToUse, 0);
        return value;
    }
    
    override public function dispose() : Void
    {
		super.dispose();
		
        m_assetManager.releaseTextureWithReferenceCount(m_itemTextureName);
		
		m_normalBackground.dispose();
		
		m_selectedBackground.dispose();
    }
}
