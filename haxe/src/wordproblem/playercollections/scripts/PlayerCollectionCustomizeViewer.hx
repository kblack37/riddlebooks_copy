package wordproblem.playercollections.scripts;

import starling.textures.Texture;
import wordproblem.playercollections.scripts.PlayerCollectionViewer;

import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextFormat;

import cgs.internationalization.StringTable;

import dragonbox.common.ui.MouseState;
import dragonbox.common.util.ListUtil;
import dragonbox.common.util.XColor;

import starling.core.Starling;
import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.TextField;
import starling.utils.HAlign;

import wordproblem.currency.CurrencyChangeAnimation;
import wordproblem.currency.CurrencyCounter;
import wordproblem.currency.PlayerCurrencyModel;
import wordproblem.engine.component.ItemIdComponent;
import wordproblem.engine.component.PriceComponent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.widget.ConfirmationWidget;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.player.ButtonColorData;
import wordproblem.player.ChangeButtonColorScript;
import wordproblem.player.ChangeCursorScript;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.playercollections.items.CustomizableItemButton;
import wordproblem.resource.AssetManager;

/**
 * This screen shows all the customizable parts that the user can purchase or equip.
 */
class PlayerCollectionCustomizeViewer extends PlayerCollectionViewer
{
    // HACK: These match the names in the customize json
    public static inline var CATEGORY_POINTERS : String = "Pointers";
    public static inline var CATEGORY_BUTTON_COLOR : String = "Button Colors";
    
    /**
     * Reference to raw json configuration of items type that are customizable pieces.
     * 
     */
    private var m_customizables : Array<Dynamic>;
    
    /**
     * Used to fetch the properties belonging to an item.
     */
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * Used to figure out which items the player has already acquired.
     * Also needed to save new items purchased
     */
    private var m_playerItemInventory : ItemInventory;
    
    /**
     * Used to determine what items can be purchased
     */
    private var m_playerCurrencyModel : PlayerCurrencyModel;
    
    private var m_currencyCounter : CurrencyCounter;
    private var m_currencyChangeAnimation : CurrencyChangeAnimation;
    
    private var m_playerStatsAndSaveData : PlayerStatsAndSaveData;
    private var m_changeCursorScript : ChangeCursorScript;
    private var m_changeButtonColorScript : ChangeButtonColorScript;
    
    /**
     * List of category names broken down into the viewable pages
     */
    private var m_customizableCategoriesPages : Array<Array<String>>;
    private var m_activeCategoryPageIndex : Int;
    private var m_activeCategoryButtons : Array<Button>;
    
    /**
     * If in the view level of items, need to keep track of the category we are in
     * as that will give us a good filter to determine general behavior when the player
     * clicks on a specific item button
     */
    private var m_selectedCategoryId : String;
    
    /**
     * A list of pages of all item ids belonging to an active category
     */
    private var m_customizableItemIdsPages : Array<Array<String>>;
    
    private var m_activeItemsPageIndex : Int;
    
    /**
     * All buttons of items in the current item page
     */
    private var m_activeItemsButtonsInPage : Array<CustomizableItemButton>;
    
    private var m_globalPointBuffer : Point;
    private var m_boundsBuffer : Rectangle;
    
    /**
     * If not null, the prompt asking the user if they are sure they want to
     * buy the item is shown.
     */
    private var m_confirmationWidget : ConfirmationWidget;
    
    public function new(customizablesInformation : Array<Dynamic>,
            playerItemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            playerCurrencyModel : PlayerCurrencyModel,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            changeCursorScript : ChangeCursorScript,
            changeButtonColorScript : ChangeButtonColorScript,
            canvasContainer : DisplayObjectContainer,
            assetManager : AssetManager,
            mouseState : MouseState,
            buttonColorData : ButtonColorData,
            id : String = null,
            isActive : Bool = true)
    {
        super(canvasContainer, assetManager, mouseState, buttonColorData, id, isActive);
        
        m_customizables = customizablesInformation;
        m_playerItemInventory = playerItemInventory;
        m_itemDataSource = itemDataSource;
        m_playerCurrencyModel = playerCurrencyModel;
        m_playerStatsAndSaveData = playerStatsAndSaveData;
        m_changeCursorScript = changeCursorScript;
        m_changeButtonColorScript = changeButtonColorScript;
        
        m_customizableCategoriesPages = new Array<Array<String>>();
        m_activeCategoryPageIndex = -1;
        m_activeCategoryButtons = new Array<Button>();
        
        m_customizableItemIdsPages = new Array<Array<String>>();
        m_activeItemPageIndex = -1;
        m_activeItemsButtonsInPage = new Array<CustomizableItemButton>();
        
        m_globalPointBuffer = new Point();
        m_boundsBuffer = new Rectangle();
        
        createBackButton();
        
        m_currencyCounter = new CurrencyCounter(assetManager, 180, 50, 50);
    }
    
    override public function show() : Void
    {
        super.show();
        
        m_titleText.text = "Buy and Change Options";
        m_canvasContainer.addChild(m_titleText);
        
        var customizableTypeIds : Array<String> = new Array<String>();
        var numCustomizables : Int = m_customizables.length;
        var i : Int = 0;
        for (i in 0...numCustomizables){
            var customizableTypeData : Dynamic = m_customizables[i];
            customizableTypeIds.push(customizableTypeData.id);
        }
        
        ListUtil.subdivideList(customizableTypeIds, 5, m_customizableCategoriesPages);
        m_activeCategoryPageIndex = 0;
        changeToCategoryView();
        
        // Show coins at the bottom
        m_currencyCounter.setValue(m_playerCurrencyModel.totalCoins);
        m_currencyCounter.x = 50;
        m_currencyCounter.y = 600 - m_currencyCounter.height * 2;
        m_canvasContainer.addChild(m_currencyCounter);
        m_currencyChangeAnimation = new CurrencyChangeAnimation(m_currencyCounter);
    }
    
    override public function hide() : Void
    {
        super.hide();
        
        // Clear out all the different subviews
        clearCategoryViewsInCurrentPage();
        clearItemsViewsInCurrentPage();
        m_backButton.removeFromParent();
        
        m_currencyCounter.removeFromParent();
        Starling.current.juggler.remove(m_currencyChangeAnimation);
    }
    
    override public function visit() : Int
    {
        if (m_isActive) 
        {
            if (m_backButtonClickedLastFrame) 
            {
                m_backButtonClickedLastFrame = false;
                
                // Back can only occur at the item screen level, clear the items
                clearItemsViewsInCurrentPage();
                changeToCategoryView();
            }  // ui components    // Need to do custom picking of the customize item button since they are handwritten  
            
            
            
            
            
            if (m_confirmationWidget == null) 
            {
                m_globalPointBuffer.x = m_mouseState.mousePositionThisFrame.x;
                m_globalPointBuffer.y = m_mouseState.mousePositionThisFrame.y;
                var numItemButtons : Int = m_activeItemsButtonsInPage.length;
                var i : Int = 0;
                for (i in 0...numItemButtons){
                    var button : CustomizableItemButton = m_activeItemsButtonsInPage[i];
                    button.getBounds(m_canvasContainer.stage, m_boundsBuffer);
                    if (m_boundsBuffer.containsPoint(m_globalPointBuffer)) 
                    {
                        if (m_mouseState.leftMousePressedThisFrame) 
                        {
                            onItemsViewSelected(button);
                        }
                    }
                }
            }
        }
        return ScriptStatus.FAIL;
    }
    
    private function changeToCategoryView() : Void
    {
        drawCategoryButtonsForPage(m_activeCategoryPageIndex);
        
        m_backButton.removeFromParent();
    }
    
    private function drawCategoryButtonsForPage(pageIndex : Int) : Void
    {
        var buttonWidth : Float = 400;
        var buttonHeight : Float = 70;
        var gap : Float = 15;
        
        var categoryIdsForPage : Array<String> = m_customizableCategoriesPages[pageIndex];
        var numCategories : Int = categoryIdsForPage.length;
        var i : Int = 0;
        var xOffset : Float = (800 - buttonWidth) * 0.5;
        var yOffset : Float = m_titleText.y + m_titleText.height;
        var nineSliceRectangle : Rectangle = new Rectangle(8, 8, 16, 16);
        var scale9Texture : Texture = Texture.fromTexture(m_assetManager.getTexture("button_white.png"), nineSliceRectangle);
        for (i in 0...numCategories){
            var defaultBackground : Image = new Image(scale9Texture);
            defaultBackground.color = m_buttonColorData.getUpButtonColor();
            var categoryButton : Button = new Button(defaultBackground.texture, categoryIdsForPage[i]);
            
            var hoverBackground : Image = new Image(scale9Texture);
            hoverBackground.color = XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.3);
            categoryButton.overState = hoverBackground.texture;
            
            categoryButton.downState = hoverBackground.texture;
            
            categoryButton.width = buttonWidth;
            categoryButton.height = buttonHeight;
            categoryButton.x = xOffset;
            categoryButton.y = yOffset;
            categoryButton.addEventListener(Event.TRIGGERED, onCategorySelected);
            m_canvasContainer.addChild(categoryButton);
            m_activeCategoryButtons.push(categoryButton);
            
            yOffset += buttonHeight + gap;
        }
        
		// TODO: replace when we have a suitable button replacement
        //function categoryLabelFactory() : ITextRenderer
        //{
            //var renderer : TextFieldTextRenderer = new TextFieldTextRenderer();
            //var fontName : String = GameFonts.DEFAULT_FONT_NAME;
            //renderer.embedFonts = GameFonts.getFontIsEmbedded(fontName);
            //renderer.textFormat = new TextFormat(fontName, 24, 0xFFFFFF);
            //return renderer;
        //};
    }
    
    private function clearCategoryViewsInCurrentPage() : Void
    {
        for (categoryButton in m_activeCategoryButtons)
        {
            categoryButton.removeEventListener(Event.TRIGGERED, onCategorySelected);
            categoryButton.removeFromParent(true);
        }
		m_activeCategoryButtons = new Array<Button>();
    }
    
    private function onCategorySelected(event : Event) : Void
    {
        // Need to find the appropriate category and then open up the
        // items belonging to it
        var targetButton : Button = try cast(event.currentTarget, Button) catch(e:Dynamic) null;
        var indexOfButton : Int = Lambda.indexOf(m_activeCategoryButtons, targetButton);
        if (indexOfButton > -1) 
        {
            var categoryIdsInPage : Array<String> = m_customizableCategoriesPages[m_activeCategoryPageIndex];
            var selectedCategoryId : String = categoryIdsInPage[indexOfButton];
            
            // From the category id, switch to a view that shows the 'items' belonging to
            // that category.
            for (customizableCategoryData in m_customizables)
            {
                if (customizableCategoryData.id == selectedCategoryId) 
                {
                    m_selectedCategoryId = selectedCategoryId;
                    clearCategoryViewsInCurrentPage();
                    changeToItemsView(customizableCategoryData);
                    break;
                }
            }
        }
    }
    
    /**
     *
     * @param itemsData
     *      The json formatted data blob with all the info related to a single category
     *      (Look in the game_items.json file for format)
     */
    private function changeToItemsView(customizableCategoryData : Dynamic) : Void
    {
        var itemsPerPage : Int = Std.int(customizableCategoryData.columnsPerPage * customizableCategoryData.rowsPerPage);
        var customizableCategoryDataItemIds : Array<Dynamic> = try cast(customizableCategoryData.itemIds, Array<Dynamic>) catch (e : Dynamic) null;
		var itemIdsInCategory : Array<String> = new Array<String>();
        for (itemId in customizableCategoryDataItemIds)
        {
            itemIdsInCategory.push(itemId);
        }
        ListUtil.subdivideList(itemIdsInCategory, itemsPerPage, m_customizableItemIdsPages);
        m_activeItemPageIndex = 0;
        drawItemButtonsForPage(m_activeItemPageIndex, customizableCategoryData);
        
        m_canvasContainer.addChild(m_backButton);
    }
    
    private function drawItemButtonsForPage(pageIndex : Int, customizableCategoryData : Dynamic) : Void
    {
        var categoryId : String = customizableCategoryData.id;
        var buttonWidth : Float = customizableCategoryData.typicalWidth;
        var buttonHeight : Float = customizableCategoryData.typicalHeight;
        var columns : Int = customizableCategoryData.columnsPerPage;
        var rows : Int = customizableCategoryData.rowsPerPage;
        
        var itemIdsForPage : Array<String> = m_customizableItemIdsPages[pageIndex];
        var numItems : Int = itemIdsForPage.length;
        var i : Int = 0;
        var yOffset : Float = 60;
        var spanningWidth : Float = 800;
        var spanningHeight : Float = 400;
        var calculatedHorizontalGap : Float = (spanningWidth - columns * buttonWidth) / (columns + 1);
        var calculatedVerticalGap : Float = (spanningHeight - rows * buttonHeight) / (rows + 1);
        for (i in 0...itemIdsForPage.length){
            var itemId : String = itemIdsForPage[i];
            
            // Button appearance will differ if the item was already purchased or if it is currently equipped.
            // The logic to change this is all baked inside the button class
            var itemButton : CustomizableItemButton = new CustomizableItemButton(itemId, 
				categoryId, m_itemDataSource, m_playerItemInventory, m_assetManager, buttonWidth, buttonHeight, 
				m_buttonColorData.getUpButtonColor(), 
				XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.4)
            );
            
            var rowIndex : Int = Std.int(i / columns);
            var columnIndex : Int = i % columns;
            itemButton.x = columnIndex * buttonWidth + calculatedHorizontalGap * (columnIndex + 1);
            itemButton.y = rowIndex * buttonHeight + calculatedVerticalGap * (rowIndex + 1) + yOffset;
            
            m_canvasContainer.addChild(itemButton);
            m_activeItemsButtonsInPage.push(itemButton);
        }
    }
    
    private function clearItemsViewsInCurrentPage() : Void
    {
        for (itemButton in m_activeItemsButtonsInPage)
        {
            itemButton.removeFromParent(true);
        }
        
		m_activeItemsButtonsInPage = new Array<CustomizableItemButton>();
        
        // Delete the pagination of items, gets reconstructed the next time we enter an item
		m_customizableItemIdsPages = new Array<Array<String>>();
    }
    
    private function onItemsViewSelected(targetButton : CustomizableItemButton) : Void
    {
        // Need to remap to the item id and view several properties
        var indexOfButton : Int = Lambda.indexOf(m_activeItemsButtonsInPage, targetButton);
        
        var itemsIdsInPage : Array<String> = m_customizableItemIdsPages[m_activeItemsPageIndex];
        var itemIdSelected : String = itemsIdsInPage[indexOfButton];
        
        // The effect of clicking also depends on the category type.
        // For cursors the mouse needs to change immediately
        // For button colors, some property of how the buttons are drawn need to
        
        // We just use the category id to differentiate, and consider it safe to assume every item
        // in a category will have similar and known sets of properties
        var playerOwnsItem : Bool = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                itemIdSelected, ItemIdComponent.TYPE_ID) != null;
        if (playerOwnsItem) 
        {
            switchToItem(itemIdSelected);
            refreshItemButtons();
        }
        else 
        {
            // Pressing on any un-owned item should trigger a prompt asking for purchase
            var priceComponent : PriceComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(itemIdSelected, PriceComponent.TYPE_ID), PriceComponent) catch(e:Dynamic) null;
            var itemCost : Int = priceComponent.price;
            if (itemCost <= m_playerCurrencyModel.totalCoins) 
            {
                // Display a confirmation screen
                m_confirmationWidget = new ConfirmationWidget(800, 600, 
					function() : DisplayObject
					{
						var mainDisplayContainer : Sprite = new Sprite();
						
						var textFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
						var measuringText : MeasuringTextField = new MeasuringTextField();
						measuringText.defaultTextFormat = textFormat;
						// TODO: uncomment when cgs library is finished
						measuringText.text = "";// StringTable.lookup("buy_for") + " ";
						
						var askText : TextField = new TextField(Std.int(measuringText.textWidth + 10), 
							Std.int(measuringText.textHeight + 10),
							measuringText.text,
							textFormat.font,
							textFormat.size,
							try cast(textFormat.color, Int) catch(e:Dynamic) 0);
						askText.hAlign = HAlign.LEFT;
						mainDisplayContainer.addChild(askText);
						
						var priceIndicatorHeight : Float = 40;
						var coin : Image = new Image(m_assetManager.getTexture("coin.png"));
						coin.scaleX = coin.scaleY = priceIndicatorHeight / coin.height;
						coin.x = askText.x + askText.width;
						mainDisplayContainer.addChild(coin);
						
						var displayedPrice : String = itemCost + "?";
						measuringText.text = displayedPrice;
						var priceText : TextField = new TextField(Std.int(measuringText.textWidth + 10),
							Std.int(measuringText.textHeight + 10),
							displayedPrice, 
							textFormat.font,
							textFormat.size,
							try cast(textFormat.color, Int) catch(e:Dynamic) 0);
						priceText.x = coin.x + coin.width + 10;
						mainDisplayContainer.addChild(priceText);
						
						// Add the icon below
						var itemIcon : DisplayObject = targetButton.createItemIcon();
						itemIcon.x = (mainDisplayContainer.width - itemIcon.width) * 0.5;
						itemIcon.y = askText.y + askText.height + 10;
						mainDisplayContainer.addChild(itemIcon);
						
						return mainDisplayContainer;
					}, 
					function() : Void
					{
						// Subtract item cost from the player's current coins
						var newCoinValue : Int = m_playerCurrencyModel.totalCoins - itemCost;
						m_currencyChangeAnimation.start(m_playerCurrencyModel.totalCoins, newCoinValue);
						Starling.current.juggler.add(m_currencyChangeAnimation);
						m_playerCurrencyModel.totalCoins = newCoinValue;
						m_playerCurrencyModel.save(true);
						
						// Add the item to the player's inventory and then save
						m_playerItemInventory.createItemFromBlueprint(itemIdSelected, itemIdSelected);
						m_playerItemInventory.save();
						discardConfirmation();
						
						// Immediately equip the item that was just selected
						switchToItem(itemIdSelected);
						
						refreshItemButtons();
					}, 
					discardConfirmation, 
					m_assetManager, 
					// TODO: uncomment when cgs library is finished
					m_buttonColorData.getUpButtonColor(), "", ""// StringTable.lookup("yes"), StringTable.lookup("no")
                );
            }
            else 
            {
                m_confirmationWidget = new ConfirmationWidget(800, 600, 
                    function() : DisplayObject
                    {
                        var contentTextField : TextField = new TextField(
							400, 
							200, 
							// TODO: uncomment when cgs library is finished
							"",//StringTable.lookup("not_enough_coins"), 
							GameFonts.DEFAULT_FONT_NAME, 
							30,
							0xFFFFFF
                        );
                        return contentTextField;
                    }, 
                    discardConfirmation, 
                    null, 
                    m_assetManager, 
                    m_buttonColorData.getUpButtonColor(), 
					// TODO: uncomment when cgs library is finished
                    "" /*StringTable.lookup("ok")*/, null, true
                );
            }
            m_canvasContainer.stage.addChild(m_confirmationWidget);
        }
    }
    
    private function switchToItem(itemIdSelected : String) : Void
    {
        // Switching to an owned pointer should just modify the currently displayed pointer
        if (m_selectedCategoryId == PlayerCollectionCustomizeViewer.CATEGORY_POINTERS) 
        {
            // Need to introduce several ugly dependencies to perform the pointer change
            m_playerStatsAndSaveData.setCursorName(itemIdSelected);
            m_changeCursorScript.changeToCursor(itemIdSelected);
        }
        else if (m_selectedCategoryId == PlayerCollectionCustomizeViewer.CATEGORY_BUTTON_COLOR) 
        {
            m_playerStatsAndSaveData.setButtonColorName(itemIdSelected);
            
            // The change button color script will need to tranlate the item id to the actual color
            // values that several other parts will need to use
            m_changeButtonColorScript.changeToButtonColor(itemIdSelected);
            
            // Also need to adjust the color of the buttons on the current page
            for (button in m_activeItemsButtonsInPage)
            {
                button.setDefaultColor(m_buttonColorData.getUpButtonColor());
                button.setSelectedColor(XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.3));
            }
        }
    }
    
    private function refreshItemButtons() : Void
    {
        // For simplicity, just refresh every button on the screen
        for (button in m_activeItemsButtonsInPage)
        {
            button.refresh();
        }
    }
    
    private function discardConfirmation() : Void
    {
        m_confirmationWidget.removeFromParent(true);
        m_confirmationWidget = null;
    }
}
