package wordproblem.playercollections.items;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import wordproblem.display.DisposableSprite;
import wordproblem.display.Scale9Image;

import dragonbox.common.util.XColor;
import dragonbox.common.util.XTextField;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;

import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * Simple button representing a cateogry for a collection item.
 */
class PlayerCollectionCategoryButton extends DisposableSprite
{
    public var selected(never, set) : Bool;

    private var m_categoryInformationObject : Dynamic;
    
    private var m_normalBackground : Scale9Image;
    private var m_selectedBackground : Scale9Image;
    
    public function new(categoryInformationObject : Dynamic,
            assetManager : AssetManager,
            width : Float,
            height : Float,
            upColor : Int)
    {
        super();
        
        m_categoryInformationObject = categoryInformationObject;
        
		var scale9Rect = new Rectangle(8, 8, 16, 16);
        var bitmapData : BitmapData = assetManager.getBitmapData("button_white");
        m_normalBackground = new Scale9Image(bitmapData, scale9Rect);
		m_normalBackground.transform.colorTransform = XColor.rgbToColorTransform(upColor);
        
        m_selectedBackground = new Bitmap(bitmapData, scale9Rect);
		m_selectedBackground.transform.colorTransform = XColor.rgbToColorTransform(XColor.shadeColor(upColor, 0.3));
        
        var totalWidth : Float = width;
        var totalHeight : Float = height;
        m_normalBackground.width = totalWidth;
        m_normalBackground.height = totalHeight;
        m_selectedBackground.width = totalWidth;
        m_selectedBackground.height = totalHeight;
        this.selected = false;
        
        var categoryNameImage : DisplayObject = XTextField.createWordWrapTextfield(
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER),
                categoryInformationObject.id,
                width * 0.5, height, true
                );
        addChild(categoryNameImage);
        
        var itemsEarned : Int = categoryInformationObject.numItemsEarned;
        var itemsTotal : Int = categoryInformationObject.itemIds.length;
        var categoryProgressTextfield : TextField = new TextField();
		categoryProgressTextfield.width = 170;
		categoryProgressTextfield.height = height;
		categoryProgressTextfield.text = itemsEarned + "/" + itemsTotal;
		categoryProgressTextfield.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF));
        categoryProgressTextfield.x = categoryNameImage.x + categoryNameImage.width;
        addChild(categoryProgressTextfield);
    }
    
    public function getCategoryInformationObject() : Dynamic
    {
        return m_categoryInformationObject;
    }
    
    private function set_selected(value : Bool) : Bool
    {
        if (m_normalBackground.parent != null) m_normalBackground.parent.removeChild(m_normalBackground);
        if (m_selectedBackground.parent != null) m_selectedBackground.parent.removeChild(m_selectedBackground);
        
        var backgroundToUse : DisplayObject = ((value)) ? m_selectedBackground : m_normalBackground;
        addChildAt(backgroundToUse, 0);
        return value;
    }
}