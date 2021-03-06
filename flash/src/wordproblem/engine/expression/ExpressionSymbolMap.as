package wordproblem.engine.expression
{
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	
	import dragonbox.common.system.Map;
	
	import feathers.display.Scale9Image;
	import feathers.textures.Scale9Textures;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.text.TextField;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	
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
	public class ExpressionSymbolMap
	{	
        /**
         * Key: symbol value
         * Value: struct data
         */
		private var m_idToSymbolDataMap:Map;
        
        /**
         * Map to deal with cases where we need to create symbols generated as the level
         * is being played. This is useful for dealing with numbers that are created as
         * the player is simplifying an equation.
         * 
         * Key: symbol value
         * Value: the texture for that value
         */
        private var m_idToDynamicTextureMap:Map;
		
        /**
         * Name of the positive background texture to use for cards
         */
        private var m_defaultCardAttributes:CardAttributes;
        
        private var m_assetManager:AssetManager;
        
        private var m_measuringTextField:MeasuringTextField;
        
		public function ExpressionSymbolMap(assetManager:AssetManager)
		{
            // Asset manager stores the sprite sheet for all possible icons as a
            // sprite sheet
            m_assetManager = assetManager;
            
			m_idToSymbolDataMap = new Map();
            m_idToDynamicTextureMap = new Map();
            
            m_measuringTextField = new MeasuringTextField();
            m_measuringTextField.defaultTextFormat = new TextFormat();
		}
        
        public function getSymbolDataFromValue(value:String):SymbolData
        {
            // If symbol data does not exist for a requested value,
            // then create one with defaults
            if (!m_idToSymbolDataMap.contains(value))
            {
                this.createDefaultSymbolDataForValue(value);
            }
            return m_idToSymbolDataMap.get(value) as SymbolData;
        }
        
        /**
         * Setup the default style properties for cards to be used for an upcoming levels
         * These parameters are valid up until the next call to clear()
         * 
         * HACK: Should this even exist, defaults can just be part of the constructor
         */
        public function setConfiguration(defaultCardAttributes:CardAttributes):void
        {
            m_defaultCardAttributes = defaultCardAttributes;
        }
        
        /**
         * Clear all previously bound textures and reset all style properties.
         * A new configuration must be setup after this has been called.
         */
        public function clear():void
        {
            var operatorNames:Vector.<String> = Vector.<String>(["+", "/", "=", "*", "-"]);
            
            // Dispose the dynamic textures
            var dynamicTextureKeys:Array = m_idToDynamicTextureMap.getKeys();
            for each (var key:String in dynamicTextureKeys)
            {
                var texture:Texture = m_idToDynamicTextureMap.get(key);
                
                // Do not dispose texture if its part of the asset manager since other things might be using it
                // This is only for the operators
                if (operatorNames.indexOf(key) == -1)
                {
                    texture.dispose();
                }
                m_idToDynamicTextureMap.remove(key);
            }
            
            m_idToSymbolDataMap.clear();
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
        public function bindSymbolsToAtlas(symbols:Vector.<SymbolData>):void
        {
            // We key the cards in the atlas by their toString values
            for (var i:int = 0; i < symbols.length; i++)
            {
                var symbolStruct:SymbolData = symbols[i];
                
                // Add textures here to dynamic map, this is a bit of a hack as the call to get a card display
                // will also create a new texture
                m_idToSymbolDataMap.put(symbolStruct.value, symbolStruct);
            }
            
            // Add in operator symbols to the atlas if they haven't already been specified
            // The defaults are to use a single embedded static image
            var operatorNames:Vector.<String> = Vector.<String>(["+", "/", "=", "*", "-"]);
            var operatorTextures:Vector.<String> = Vector.<String>(["add", "divide_bar", "equal", "multiply_x", "subtract"]);
            for (i = 0; i < operatorNames.length; i++)
            {
                var operatorName:String = operatorNames[i];
                if (!m_idToSymbolDataMap.contains(operatorName))
                {
                    // Create dummy data for the operator values
                    var operatorData:SymbolData = new SymbolData(operatorName, operatorName,
                        null, operatorTextures[i], null, 0xFFFFFF, null);
                    m_idToSymbolDataMap.put(operatorName, operatorData);
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
        public function addSymbol(symbolData:SymbolData):void
        {
            m_idToSymbolDataMap.put(symbolData.value, symbolData);
        }
        
		/**
		 * Get the level-assigned name for the card
         * 
         * @param uid
         *      The id of the symbol WITHOUT any negative sign in front
         * @return
		 * 		null if the name does not exist, else the textual name of the object
		 */
		public function getSymbolName(uid:String):String
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
        public function getCardFromSymbolValue(value:String):DisplayObject
        {
            var cardObject:DisplayObject = null;
            
            // First check if the value was dynamically created as the level was running
            // it would be present in the special reserved texture map
            var cardTexture:Texture;
            if (m_idToDynamicTextureMap.contains(value))
            {
                cardTexture = m_idToDynamicTextureMap.get(value) as Texture;
            }
            // Next check if the level file had defined specific parameters for the symbol
            // These symbols are created at the start of the level
            else
            {
                // We need to create that symbol on the fly with default settings
                if (!m_idToSymbolDataMap.contains(value))
                {
                    this.createDefaultSymbolDataForValue(value);
                }
                
                var symbolData:SymbolData = m_idToSymbolDataMap.get(value);
                cardObject = this.createCard(symbolData, m_measuringTextField);
                
                // Create the new texture and immediately add it to the map
                var renderTexture:RenderTexture = new RenderTexture(
                    cardObject.width,
                    cardObject.height
                );
                
                renderTexture.draw(cardObject);
                m_idToDynamicTextureMap.put(value, renderTexture);
                cardTexture = renderTexture;
            }
            cardObject = new Image(cardTexture);
            cardObject.pivotX = cardObject.width / 2;
            cardObject.pivotY = cardObject.height / 2;
            
            return cardObject;
        }
        
        /**
         * Sometimes we want to take all the custom symbols for a term but
         * modify a few of the properties later.
         */
        public function clone():ExpressionSymbolMap
        {
            var clone:ExpressionSymbolMap = new ExpressionSymbolMap(m_assetManager);
            
            // Go through all existing symbol data objects in this original and copy them over
            // into the clone;
            var idValues:Array = m_idToSymbolDataMap.getKeys();
            var i:int;
            var numValues:int = idValues.length;
            var symbolsToCopy:Vector.<SymbolData> = new Vector.<SymbolData>();
            for (i = 0; i < numValues; i++)
            {
                var symbolData:SymbolData = m_idToSymbolDataMap.get(idValues[i]);
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
        private function createCard(symbolData:SymbolData, 
                                   measuringTextField:MeasuringTextField):DisplayObject
        {
            var cardContainer:Sprite = new Sprite();
            
            // If text name is specified then create a stylized textfield on top of everything
            var scaleBackgroundToFitTextWidth:Number = -1;
            if (symbolData.abbreviatedName != null)
            {
                var textFormat:TextFormat = measuringTextField.defaultTextFormat;
                textFormat.font = symbolData.fontName;
                textFormat.size = symbolData.fontSize;
                textFormat.color = symbolData.fontColor;
                measuringTextField.defaultTextFormat = textFormat;
                measuringTextField.embedFonts = GameFonts.getFontIsEmbedded(symbolData.fontName);
                measuringTextField.text = symbolData.abbreviatedName;
                
                var symbolTextField:TextField = new TextField(
                    measuringTextField.textWidth + 20, 
                    measuringTextField.textHeight + 10, 
                    symbolData.abbreviatedName, 
                    symbolData.fontName, 
                    symbolData.fontSize, 
                    symbolData.fontColor
                );
                symbolTextField.hAlign = HAlign.CENTER;
                
                cardContainer.addChild(symbolTextField);
                scaleBackgroundToFitTextWidth = symbolTextField.width;
            }
            
            // Draw the background
            if (symbolData.backgroundTextureName != null)
            {
                var backgroundTexture:Texture = m_assetManager.getTexture(symbolData.backgroundTextureName);
                var backgroundOriginalWidth:Number = backgroundTexture.width;
                var backgroundOriginalHeight:Number = backgroundTexture.height;
                var backgroundImage:DisplayObject;
                if (scaleBackgroundToFitTextWidth > backgroundOriginalWidth)
                {
                    // If the background needs to be expanded, then we need to do a nine-slice on the background
                    var nineScalePadding:Number = 8;
                    var scale9Background:Scale9Image = new Scale9Image(new Scale9Textures(
                            backgroundTexture, 
                            new Rectangle(nineScalePadding, nineScalePadding, backgroundOriginalWidth - 2 * nineScalePadding, backgroundOriginalHeight - 2 * nineScalePadding)
                    ));
                    scale9Background.color = symbolData.backgroundColor;
                    scale9Background.width = scaleBackgroundToFitTextWidth;
                    backgroundImage = scale9Background;
                }
                else
                {
                    var unScaledBackground:Image = new Image(backgroundTexture);
                    unScaledBackground.color = symbolData.backgroundColor;
                    backgroundImage = unScaledBackground;
                }
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
                var symbolTexture:Texture = m_assetManager.getTexture(symbolData.symbolTextureName);
                var symbolImage:Image = new Image(symbolTexture);
                
                // Attempt to center on top of the background if it exists
                if (symbolData.backgroundTextureName != null)
                {
                    symbolImage.x = Math.floor((cardContainer.width - symbolTexture.width) * 0.5);
                    symbolImage.y = Math.floor((cardContainer.height - symbolTexture.height) * 0.5)
                }
                
                // Apply tint to the symbol image if specified
                if (symbolData.useSymbolTextureColor)
                {
                    symbolImage.color = symbolData.symbolTextureColor;
                }
                
                cardContainer.addChild(symbolImage);
            }
            
            // Render text will cut off drawing parts of the card if any part of the
            // visible graphic is outside the rect whose top left is at (0,0) so
            // we need to shift the entire object over
            const rect:Rectangle = cardContainer.getBounds(cardContainer);
            
            const wrapper:Sprite = new Sprite();
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
        public function resetTextureForValue(value:String):void
        {
            if (m_idToDynamicTextureMap.contains(value))
            {
                // Need to be very careful with disposing textures, possible the game still
                // has this image displayed somewhere. Need to be sure no extra display parts
                // are still trying to use this texture.
                (m_idToDynamicTextureMap.get(value) as Texture).dispose();
                m_idToDynamicTextureMap.remove(value);
            }
        }
        
        public function createDefaultSymbolDataForValue(value:String):void
        {
            // Have a default fallback value for the backgrounds for cards in this level
            // For the symbol check if the background image is first needed
            // at all. This is done on a per symbol basis or can be specified
            var isNegative:Boolean = (value.charAt(0) == "-");
            var backgroundToUse:String = (isNegative) ? m_defaultCardAttributes.defaultNegativeCardBgId : m_defaultCardAttributes.defaultPositiveCardBgId;
            
            // Create new symbol data for the dummy object
            var symbolData:SymbolData = new SymbolData(
                value, 
                value,
                value,
                null,
                backgroundToUse,
                0xFFFFFF,
                m_defaultCardAttributes.defaultFontName
            );
            symbolData.fontColor = (isNegative) ? m_defaultCardAttributes.defaultNegativeTextColor : m_defaultCardAttributes.defaultPositiveTextColor;
            symbolData.fontSize = m_defaultCardAttributes.defaultFontSize;
            m_idToSymbolDataMap.put(value, symbolData);
        }
	}
}