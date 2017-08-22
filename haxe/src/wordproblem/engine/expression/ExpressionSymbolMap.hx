package wordproblem.engine.expression;


import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import wordproblem.display.Scale9Image;

import wordproblem.display.PivotSprite;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.level.CardAttributes;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.resource.AssetManager;

/**
	 * This is the visualization storage for all possible symbols that can be represented in an expression
 * 
 * This is where all cards AND operators are stored on a level.
 * When a level starts you need to bind symbols first, when it ends they must be cleared
	 */
class ExpressionSymbolMap
{
    /**
     * Key: symbol value
     * Value: struct data
     */
    private var m_idToSymbolDataMap : Map<String, SymbolData>;
    
    /**
     * Map to deal with cases where we need to create symbols generated as the level
     * is being played. This is useful for dealing with numbers that are created as
     * the player is simplifying an equation.
     * 
     * Key: symbol value
     * Value: the texture for that value
     */
    private var m_idToDynamicBitmapDataMap : Map<String, BitmapData>;
    
    /**
     * Name of the positive background texture to use for cards
     */
    private var m_defaultCardAttributes : CardAttributes;
    
    private var m_assetManager : AssetManager;
    
    private var m_measuringTextField : MeasuringTextField;
    
    public function new(assetManager : AssetManager)
    {
        // Asset manager stores the sprite sheet for all possible icons as a
        // sprite sheet
        m_assetManager = assetManager;
        
        m_idToSymbolDataMap = new Map();
        m_idToDynamicBitmapDataMap = new Map();
        
        m_measuringTextField = new MeasuringTextField();
        m_measuringTextField.defaultTextFormat = new TextFormat();
		
		m_defaultCardAttributes = CardAttributes.DEFAULT_CARD_ATTRIBUTES;
    }
    
    public function getSymbolDataFromValue(value : String) : SymbolData
    {
        // If symbol data does not exist for a requested value,
        // then create one with defaults
        if (!m_idToSymbolDataMap.exists(value)) 
        {
            this.createDefaultSymbolDataForValue(value);
        }
        return try cast(m_idToSymbolDataMap.get(value), SymbolData) catch(e:Dynamic) null;
    }
    
    /**
     * Setup the default style properties for cards to be used for an upcoming levels
     * These parameters are valid up until the next call to clear()
     * 
     * HACK: Should this even exist, defaults can just be part of the constructor
     */
    public function setConfiguration(defaultCardAttributes : CardAttributes) : Void
    {
        m_defaultCardAttributes = defaultCardAttributes;
    }
    
    /**
     * Clear all previously bound textures and reset all style properties.
     * A new configuration must be setup after this has been called.
     */
    public function clear() : Void
    {
        var operatorNames : Array<String> = ["+", "/", "=", "*", "-"];
        
        // Dispose the dynamic textures
        var dynamicBitmapDataKeys = m_idToDynamicBitmapDataMap.keys();
        for (key in dynamicBitmapDataKeys)
        {
            var bitmapData : BitmapData = m_idToDynamicBitmapDataMap.get(key);
            
            // Do not dispose texture if its part of the asset manager since other things might be using it
            // This is only for the operators
            if (Lambda.indexOf(operatorNames, key) == -1) 
            {
                bitmapData.dispose();
            }
            m_idToDynamicBitmapDataMap.remove(key);
        }
        
        m_idToSymbolDataMap = new Map();
    }
    
    /**
     * Bind a collection of symbols to a dynamically generated texture atlas.
     * For performance reasons try to put as many symbols as needed for a level
     * into this call.
     * 
     * IMPORTANT: This always needs to be called to at least bind the operator images to the atlas.
     * 
     * @param symbol
     *      List of symbol information to create the cards that go into the atlas.
     *      Generally this should include the positive and negative representations
     *      of a term.
     */
    public function bindSymbolsToAtlas(symbols : Array<SymbolData>) : Void
    {
        // We key the cards in the atlas by their toString values
        for (i in 0...symbols.length){
            var symbolStruct : SymbolData = symbols[i];
            
            // Add textures here to dynamic map, this is a bit of a hack as the call to get a card display
            // will also create a new texture
            m_idToSymbolDataMap.set(symbolStruct.value, symbolStruct);
        }  
		
		// Add in operator symbols to the atlas if they haven't already been specified  
        // The defaults are to use a single embedded static image
        var operatorNames : Array<String> = ["+", "/", "=", "*", "-"];
        var operatorTextures : Array<String> = ["plus",
			"divide_bar",
			"equal",
			"multiply_x",
			"subtract"
		];
        for (i in 0...operatorNames.length){
            var operatorName : String = operatorNames[i];
            if (!m_idToSymbolDataMap.exists(operatorName)) 
            {
                // Create dummy data for the operator values
                var operatorData : SymbolData = new SymbolData(operatorName, operatorName, 
                null, operatorTextures[i], null, 0xFFFFFF, null);
                m_idToSymbolDataMap.set(operatorName, operatorData);
            }
        }  
		
		// TODO: This atlas is causing us to run out of texture memory after several level skips are  
		// performed. (Go to 10 generated levels and skip them, eventually get Error #3691 Resource limit reached)
		// The easy fix is to just avoid creating these atlases 
		// The wierd thing is that disposing atlas at this point seems to free memory fine.
		// It is disposing it later that does not have desired effect.
	}
    
    /**
     * Used if for whatever reason we need to add symbols after level initialization
     */
    public function addSymbol(symbolData : SymbolData) : Void
    {
        m_idToSymbolDataMap.set(symbolData.value, symbolData);
    }
    
    /**
		 * Get the level-assigned name for the card
     * 
     * @param uid
     *      The id of the symbol WITHOUT any negative sign in front
     * @return
		 * 		null if the name does not exist, else the textual name of the object
		 */
    public function getSymbolName(uid : String) : String
    {
        return this.getSymbolDataFromValue(uid).name;
    }
    
    /**
     * Get back a display object of the image
     * (MUST CALL BIND SYMBOLS TO ATLAS BEFOREHAND)
     * 
     * If the texture was not found in the atlas then we will need to create and store it
     * within a separate texture map.
     * Note that this is slow so it is best to try to bind as many symbols as reasonably possible
     * within the level config
     * 
     * By default the returned object will have its registration point at the center of the card.
     */
    public function getCardFromSymbolValue(value : String) : DisplayObject
    {
        // First check if the value was dynamically created as the level was running
        // it would be present in the special reserved texture map
        var cardBitmapData : BitmapData = null;
        if (m_idToDynamicBitmapDataMap.exists(value)) 
        {
            cardBitmapData = m_idToDynamicBitmapDataMap.get(value);
        }
        // Next check if the level file had defined specific parameters for the symbol
        // These symbols are created at the start of the level
        else 
        {
            // We need to create that symbol on the fly with default settings
            if (!m_idToSymbolDataMap.exists(value)) 
            {
                this.createDefaultSymbolDataForValue(value);
            }
            
            var symbolData : SymbolData = m_idToSymbolDataMap.get(value);
            var cardObject = this.createCard(symbolData, m_measuringTextField);
            
            // Create the new texture and immediately add it to the map
            var renderBitmapData : BitmapData = new BitmapData(
				Std.int(cardObject.width), 
				Std.int(cardObject.height),
				true,
				0x00000000
            );
			
            renderBitmapData.draw(cardObject, null, null, BlendMode.NORMAL);
            m_idToDynamicBitmapDataMap.set(value, renderBitmapData);
            cardBitmapData = renderBitmapData;
			
			// Dispose of the scale9Image in the card object
			//(try cast((try cast((try cast(cardObject, DisplayObjectContainer) catch (e : Dynamic) null).getChildAt(0), DisplayObjectContainer) catch (e : Dynamic) null).getChildAt(0), Scale9Image) catch (e : Dynamic) null).dispose();
        }
        var cardObject = new PivotSprite();
		cardObject.addChild(new Bitmap(cardBitmapData));
        cardObject.pivotX = cardObject.width / 2;
        cardObject.pivotY = cardObject.height / 2;
        
        return cardObject;
    }
    
    /**
     * Sometimes we want to take all the custom symbols for a term but
     * modify a few of the properties later.
     */
    public function clone() : ExpressionSymbolMap
    {
        var clone : ExpressionSymbolMap = new ExpressionSymbolMap(m_assetManager);
        
        // Go through all existing symbol data objects in this original and copy them over
        // into the clone;
        var idValues = m_idToSymbolDataMap.keys();
        var symbolsToCopy : Array<SymbolData> = new Array<SymbolData>();
        for (idValue in idValues) {
            var symbolData : SymbolData = m_idToSymbolDataMap.get(idValue);
            if (symbolData != null) 
            {
                symbolsToCopy.push(symbolData.clone());
            }
        }
        clone.bindSymbolsToAtlas(symbolsToCopy);
        return clone;
    }
    
    
    /**
     * The only case where we are concerned with distinguishing between positve and negative
     * is adding a negative symbol next to a picture
     */
    private function createCard(symbolData : SymbolData,
            measuringTextField : MeasuringTextField) : DisplayObject
    {
        var cardContainer : Sprite = new Sprite();
		var symbolTextField : TextField = null;
        
        // If text name is specified then create a stylized textfield on top of everything
        var scaleBackgroundToFitTextWidth : Float = -1;
        if (symbolData.abbreviatedName != null) 
        {
            var textFormat : TextFormat = measuringTextField.defaultTextFormat;
            textFormat.font = symbolData.fontName;
            textFormat.size = symbolData.fontSize;
            textFormat.color = symbolData.fontColor;
            measuringTextField.defaultTextFormat = textFormat;
            measuringTextField.embedFonts = GameFonts.getFontIsEmbedded(symbolData.fontName);
            measuringTextField.text = symbolData.abbreviatedName;
            
            symbolTextField = new TextField();
			symbolTextField.width = Std.int(measuringTextField.textWidth + 20);
			symbolTextField.height = Std.int(measuringTextField.textHeight + 10); 
			symbolTextField.text = symbolData.abbreviatedName;
			symbolTextField.setTextFormat(new TextFormat(
				symbolData.fontName,
				symbolData.fontSize,
				symbolData.fontColor,
				null,
				null,
				null,
				null,
				null,
				TextFormatAlign.CENTER
			));
            
            cardContainer.addChild(symbolTextField);
            scaleBackgroundToFitTextWidth = symbolTextField.width;
        }  
		
		// Draw the background  
        if (symbolData.backgroundTextureName != null) 
        {
            var backgroundBitmapData : BitmapData = m_assetManager.getBitmapData(symbolData.backgroundTextureName);
            var backgroundOriginalWidth : Float = backgroundBitmapData.width;
            var backgroundOriginalHeight : Float = backgroundBitmapData.height;
            var backgroundImage : DisplayObject = null;
            if (scaleBackgroundToFitTextWidth > backgroundOriginalWidth) 
            {
                // If the background needs to be expanded, then we need to do a nine-slice on the background
                var nineScalePadding : Float = 8;
				backgroundImage = new Scale9Image(backgroundBitmapData, new Rectangle(nineScalePadding,
					nineScalePadding,
					backgroundOriginalWidth - 2 * nineScalePadding,
					backgroundOriginalHeight - 2 * nineScalePadding
				));
                backgroundImage.width = scaleBackgroundToFitTextWidth;
            } 
			else 
			{
				backgroundImage = new Bitmap(backgroundBitmapData);
			}
			backgroundImage.transform.colorTransform = XColor.rgbToColorTransform(symbolData.backgroundColor);
            cardContainer.addChildAt(backgroundImage, 0);
            
            // Reposition the text base on the background size
            if (symbolTextField != null) 
            {
                symbolTextField.x = Math.floor((backgroundImage.width - symbolTextField.width) * 0.5);
                symbolTextField.y = Math.floor((backgroundImage.height - symbolTextField.height) * 0.5);
            }
        }  
		
		// Get the texture for the symbol if it exists, otherwise we rely just on  
        // the text as the only distinguishing feature for the card 
        if (symbolData.symbolTextureName != null) 
        {
            // IMPORTANT: The symbol atlas if more for prototype levels
            // We assume all symbols are part of a special symbol atlas.
            // The texture name passed in the level must match the kay in the atlas xml
            var symbolBitmapData : BitmapData = m_assetManager.getBitmapData(symbolData.symbolTextureName);
            var symbolImage : Bitmap = new Bitmap(symbolBitmapData);
            
            // Attempt to center on top of the background if it exists
            if (symbolData.backgroundTextureName != null) 
            {
                symbolImage.x = Math.floor((cardContainer.width - symbolBitmapData.width) * 0.5);
                symbolImage.y = Math.floor((cardContainer.height - symbolBitmapData.height) * 0.5);
            }  
			
			// Apply tint to the symbol image if specified  
            if (symbolData.useSymbolTextureColor) 
            {
				symbolImage.transform.colorTransform.concat(XColor.rgbToColorTransform(symbolData.symbolTextureColor));
            }
            
            cardContainer.addChild(symbolImage);
        }  
		
		// Render text will cut off drawing parts of the card if any part of the  
		// visible graphic is outside the rect whose top left is at (0,0) so 
        // we need to shift the entire object over
        var rect : Rectangle = cardContainer.getBounds(cardContainer);
        
        var wrapper : Sprite = new Sprite();
        cardContainer.x -= rect.x;
        cardContainer.y -= rect.y;
        wrapper.addChild(cardContainer);
        
        return wrapper;
    }
    
    /**
     * If we alter one of the visual properties of a card (like its displayed name
     * or background color) while the application is running, we want to update
     * the appearance
     * 
     * MUST make sure that the old texture being used has been fully removed from
     * the display being calling this
     */
    public function resetTextureForValue(value : String) : Void
    {
        if (m_idToDynamicBitmapDataMap.exists(value)) 
        {
            // Need to be very careful with disposing textures, possible the game still
            // has this image displayed somewhere. Need to be sure no extra display parts
            // are still trying to use this texture.
            m_idToDynamicBitmapDataMap.get(value).dispose();
            m_idToDynamicBitmapDataMap.remove(value);
        }
    }
    
    public function createDefaultSymbolDataForValue(value : String) : Void
    {
        // Have a default fallback value for the backgrounds for cards in this level
        // For the symbol check if the background image is first needed
        // at all. This is done on a per symbol basis or can be specified
        var isNegative : Bool = (value.charAt(0) == "-");
        var backgroundToUse : String = isNegative ? m_defaultCardAttributes.defaultNegativeCardBgId : m_defaultCardAttributes.defaultPositiveCardBgId;
        
        // Create new symbol data for the dummy object
        var symbolData : SymbolData = new SymbolData(
			value, 
			value, 
			value, 
			null, 
			backgroundToUse, 
			0xFFFFFF, 
			m_defaultCardAttributes.defaultFontName
        );
        symbolData.fontColor = isNegative ? m_defaultCardAttributes.defaultNegativeTextColor : m_defaultCardAttributes.defaultPositiveTextColor;
        symbolData.fontSize = m_defaultCardAttributes.defaultFontSize;
        m_idToSymbolDataMap.set(value, symbolData);
    }
}
