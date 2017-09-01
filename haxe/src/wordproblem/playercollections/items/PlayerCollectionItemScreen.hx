package wordproblem.playercollections.items;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.text.TextFormat;
import wordproblem.display.DisposableSprite;

import dragonbox.common.util.XTextField;

import openfl.display.Sprite;

import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.resource.AssetManager;

/**
 * This is a simple screen that shows details about a single item
 */
class PlayerCollectionItemScreen extends DisposableSprite
{
    private var m_nameImage : Bitmap;
    private var m_descriptionImage : Bitmap;
    
    public function new(textureName : String,
            itemName : String,
            itemDescription : String,
            width : Float,
            height : Float,
            assetManager : AssetManager)
    {
        super();
        
        var imageContainerWidth : Float = 250;
        var imageContainerHeight : Float = 300;
        
        // Stretch the item so it fits one of the minimum bounds
        var minimumWidth : Float = 200;
        var minimumHeight : Float = 200;
        var scaleFactor : Float = 1.0;
        var bitmapData : BitmapData = assetManager.getBitmapData(textureName);
        if (bitmapData.width < minimumWidth && bitmapData.height < minimumHeight) 
        {
            var horizontalScaleFactor : Float = minimumWidth / bitmapData.width;
            var verticalScaleFactor : Float = minimumHeight / bitmapData.height;
            scaleFactor = Math.max(horizontalScaleFactor, verticalScaleFactor);
        }
        
        var textFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
        var measuringTextField : MeasuringTextField = new MeasuringTextField();
        measuringTextField.defaultTextFormat = textFormat;
        measuringTextField.text = itemName;
        var nameImage : DisplayObject = XTextField.createWordWrapTextfield(
                textFormat,
                itemName, measuringTextField.textWidth + 15, 60
                );
        nameImage.x = (width - nameImage.width) * 0.5;
        nameImage.y = 0;
        addChild(nameImage);
        m_nameImage = nameImage;
        
        var image : Bitmap = new Bitmap(bitmapData);
        image.scaleX = image.scaleY = scaleFactor;
        image.x = (width - image.width) * 0.5;  //(imageContainerWidth - image.width) * 0.5;  
        image.y = (imageContainerHeight - image.height) * 0.5 + nameImage.height + nameImage.y;
        addChild(image);
        
        var descriptionImage : DisplayObject = XTextField.createWordWrapTextfield(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF), itemDescription, 300, 300);
        descriptionImage.x = Math.max(imageContainerWidth, image.width);
        descriptionImage.y = nameImage.height + 10;
        //addChild(descriptionImage);
        m_descriptionImage = descriptionImage;
    }
    
    override public function dispose() : Void
    {
		super.dispose();
		
        // Get rid of dynamically created texture
		if (m_descriptionImage.parent != null) m_descriptionImage.parent.removeChild(m_descriptionImage);
		m_descriptionImage.bitmapData.dispose();
		m_descriptionImage = null;
        
		if (m_nameImage.parent != null) m_nameImage.parent.removeChild(m_nameImage);
		m_nameImage.bitmapData.dispose();
		m_nameImage = null;
    }
}
