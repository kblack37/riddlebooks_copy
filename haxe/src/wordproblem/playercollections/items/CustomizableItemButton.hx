package wordproblem.playercollections.items;


import dragonbox.common.util.XColor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.text.TextField;

import wordproblem.display.DisposableSprite;
import wordproblem.display.Scale9Image;
import wordproblem.engine.component.EquippableComponent;
import wordproblem.engine.component.ItemIdComponent;
import wordproblem.engine.component.PriceComponent;
import wordproblem.engine.component.TextureCollectionComponent;
import wordproblem.engine.text.GameFonts;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.playercollections.scripts.PlayerCollectionCustomizeViewer;
import wordproblem.resource.AssetManager;

/**
 * Button composed of a name at the top, an icon in the middle, and then
 * some indicator or price or whether the item is equipped
 */
class CustomizableItemButton extends DisposableSprite
{
    // HACK:
    // This button knows how to redraw itself for all different cases
    private var m_itemId : String;
    private var m_categoryId : String;
    private var m_itemDataSource : ItemDataSource;
    private var m_playerItemInventory : ItemInventory;
    private var m_assetManager : AssetManager;
    
    private var m_totalWidth : Float;
    private var m_totalHeight : Float;
    
    /**
     * The main rectangle background for the button keep a reference so it is easy to color
     * it depending on state changes on the item
     */
    private var m_mainBackground : Scale9Image;
    
    /**
     * Display component showing the price of an item. (Only used in some cases)
     */
    private var m_priceContainer : DisposableSprite;
    
    /**
     * Display component showing if item is equipped. (Only used in some cases)
     */
    private var m_equippedNotice : DisplayObject;
    
    private var m_defaultColor : Int;
    private var m_selectedColor : Int;
    
    public function new(itemId : String,
            categoryId : String,
            itemDataSource : ItemDataSource,
            playerItemInventory : ItemInventory,
            assetManager : AssetManager,
            totalWidth : Float,
            totalHeight : Float,
            defaultColor : Int,
            selectedColor : Int)
    {
        super();
        
        m_itemId = itemId;
        m_categoryId = categoryId;
        m_itemDataSource = itemDataSource;
        m_playerItemInventory = playerItemInventory;
        m_assetManager = assetManager;
        m_totalWidth = totalWidth;
        m_totalHeight = totalHeight;
        setDefaultColor(defaultColor);
        setSelectedColor(selectedColor);
        
        var backgroundImage : Scale9Image = new Scale9Image(assetManager.getBitmapData("button_white"), new Rectangle(8, 8, 16, 16));
        backgroundImage.width = totalWidth;
        backgroundImage.height = totalHeight;
        addChild(backgroundImage);
        m_mainBackground = backgroundImage;
        
        var icon : DisplayObject = createItemIcon();
        icon.x = (totalWidth - icon.width) * 0.5;
        icon.y = (totalHeight - icon.height) * 0.5;
        addChild(icon);
        
        refresh();
    }
    
    public function setDefaultColor(value : Int) : Void
    {
        m_defaultColor = value;
    }
    
    public function setSelectedColor(value : Int) : Void
    {
        m_selectedColor = value;
    }
    
    /**
     * If something about the state of the item has changed, this should be called so the button
     * can properly redraw itself and reflect the new state.
     * 
     * For example if a player buys an item, the price indicator should be removed
     */
    public function refresh() : Void
    {
        var backgroundColor : Int = m_defaultColor;
        if (m_priceContainer != null) 
        {
            if (m_priceContainer.parent != null) m_priceContainer.parent.removeChild(m_priceContainer);
        }
        
        if (m_equippedNotice != null) 
        {
            if (m_equippedNotice.parent != null) m_equippedNotice.parent.removeChild(m_equippedNotice);
        }
        
        var playerHasItemAlready : Bool = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(m_itemId, ItemIdComponent.TYPE_ID) != null;
        if (!playerHasItemAlready) 
        {
            // If player has not purchased the item, the price should show up for it
            if (m_priceContainer == null) 
            {
                var priceComponent : PriceComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(m_itemId, PriceComponent.TYPE_ID), PriceComponent) catch(e:Dynamic) null;
                var price : String = priceComponent.price + "";
                
                m_priceContainer = new Sprite();
                
                var priceIndicatorHeight : Float = m_totalHeight * 0.25;
                var coin : Image = new Image(m_assetManager.getTexture("coin"));
                coin.scaleX = coin.scaleY = priceIndicatorHeight / coin.height;
                m_priceContainer.addChild(coin);
                
                var priceText : TextField = new TextField(Std.int(m_totalWidth - coin.width),
					Std.int(priceIndicatorHeight),
					price, 
					GameFonts.DEFAULT_FONT_NAME,
					20,
					0xFFFFFF
				);
                priceText.x = coin.x + coin.width;
                m_priceContainer.addChild(priceText);
                
                m_priceContainer.y = m_totalHeight - priceIndicatorHeight;
            }
            addChild(m_priceContainer);
        }
        else 
        {
            // If player has item, check if it is equipped
            var equippableComponent : EquippableComponent = try cast(m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(m_itemId, EquippableComponent.TYPE_ID), EquippableComponent) catch(e:Dynamic) null;
            if (equippableComponent != null && equippableComponent.isEquipped) 
            {
                if (m_equippedNotice == null) 
                {
                    var equippedTextHeight : Float = m_totalHeight * 0.25;
                    var equippedText : TextField = new TextField(Std.int(m_totalWidth),
						Std.int(equippedTextHeight),
						"Equipped", 
						GameFonts.DEFAULT_FONT_NAME,
						20,
						XColor.DARK_GREEN
					);
                    equippedText.y = m_totalHeight - equippedTextHeight;
                    m_equippedNotice = equippedText;
                }
                addChild(m_equippedNotice);
                
                backgroundColor = m_selectedColor;
            }
        }
        
        m_mainBackground.color = backgroundColor;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        // Custom cleanup here if necessary
        if (m_priceContainer != null) 
        {
			m_priceContainer.parent.removeChild(m_priceContainer);
			m_priceContainer.dispose();
        }
		
		m_mainBackground.dispose();
    }
    
    public function createItemIcon() : DisplayObject
    {
        var icon : DisplayObject = null;
        var texturesComponent : TextureCollectionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                m_itemId, TextureCollectionComponent.TYPE_ID), TextureCollectionComponent) catch(e:Dynamic) null;
        if (m_categoryId == PlayerCollectionCustomizeViewer.CATEGORY_POINTERS) 
        {
            // Pointers have a very small icon which we need to expand
            var textureName : String = texturesComponent.textureCollection[0].textureName;
            var pointerIcon : Image = new Image(m_assetManager.getTexture(textureName));
            pointerIcon.scaleX = pointerIcon.scaleY = 1.7;
            icon = pointerIcon;
        }
        else if (m_categoryId == PlayerCollectionCustomizeViewer.CATEGORY_BUTTON_COLOR) 
        {
            var buttonColor : Int = Std.parseInt(texturesComponent.textureCollection[0].color);
            var buttonTexture : Texture = Texture.fromTexture(m_assetManager.getTexture("button_white"), new Rectangle(8, 8, 16, 16));
            var buttonImageBack : Image = new Image(buttonTexture);
            buttonImageBack.color = 0x000000;
            var buttonImageFront : Image = new Image(buttonTexture);
            buttonImageFront.color = buttonColor;
            
            var buttonContainer : Sprite = new Sprite();
            var totalButtonWidth : Float = 60;
            var padding : Float = 8;
            buttonImageBack.width = buttonImageBack.height = totalButtonWidth;
            buttonImageFront.width = buttonImageFront.height = totalButtonWidth - padding;
            buttonImageFront.x = padding * 0.5;
            buttonImageFront.y = padding * 0.5;
            buttonContainer.addChild(buttonImageBack);
            buttonContainer.addChild(buttonImageFront);
            icon = buttonContainer;
        }
        
        return icon;
    }
}
