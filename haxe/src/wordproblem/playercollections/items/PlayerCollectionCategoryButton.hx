package wordproblem.playercollections.items;


import flash.geom.Rectangle;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import starling.textures.Texture;

import dragonbox.common.util.XColor;
import dragonbox.common.util.XTextField;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;

import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * Simple button representing a cateogry for a collection item.
 */
class PlayerCollectionCategoryButton extends Sprite
{
    public var selected(never, set) : Bool;

    private var m_categoryInformationObject : Dynamic;
    
    private var m_normalBackground : Image;
    private var m_selectedBackground : Image;
    
    public function new(categoryInformationObject : Dynamic,
            assetManager : AssetManager,
            width : Float,
            height : Float,
            upColor : Int)
    {
        super();
        
        m_categoryInformationObject = categoryInformationObject;
        
        var scale9Texture : Texture = Texture.fromTexture(
			assetManager.getTexture("button_white.png"), 
			new Rectangle(8, 8, 16, 16)
        );
        m_normalBackground = new Image(scale9Texture);
        m_normalBackground.color = upColor;
        
        m_selectedBackground = new Image(scale9Texture);
        m_selectedBackground.color = XColor.shadeColor(upColor, 0.3);
        
        var totalWidth : Float = width;
        var totalHeight : Float = height;
        m_normalBackground.width = totalWidth;
        m_normalBackground.height = totalHeight;
        m_selectedBackground.width = totalWidth;
        m_selectedBackground.height = totalHeight;
        this.selected = false;
        
        var categoryNameImage : Image = XTextField.createWordWrapTextfield(
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER),
                categoryInformationObject.id,
                width * 0.5, height, true
                );
        addChild(categoryNameImage);
        
        var itemsEarned : Int = categoryInformationObject.numItemsEarned;
        var itemsTotal : Int = categoryInformationObject.itemIds.length;
        var categoryProgressTextfield : TextField = new TextField(170, Std.int(height), itemsEarned + "/" + itemsTotal, GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
        categoryProgressTextfield.x = categoryNameImage.x + categoryNameImage.width;
        addChild(categoryProgressTextfield);
    }
    
    public function getCategoryInformationObject() : Dynamic
    {
        return m_categoryInformationObject;
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
        // Clear out the background textures
        m_normalBackground.removeFromParent(true);
        m_selectedBackground.removeFromParent(true);
        
        super.dispose();
    }
}
