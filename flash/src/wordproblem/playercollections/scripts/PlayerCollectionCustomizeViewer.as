package wordproblem.playercollections.scripts
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    
    import cgs.internationalization.StringTable;
    
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.ListUtil;
    import dragonbox.common.util.XColor;
    
    import feathers.controls.Button;
    import feathers.controls.text.TextFieldTextRenderer;
    import feathers.core.ITextRenderer;
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.core.Starling;
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
    public class PlayerCollectionCustomizeViewer extends PlayerCollectionViewer
    {
        // HACK: These match the names in the customize json
        public static const CATEGORY_POINTERS:String = "Pointers";
        public static const CATEGORY_BUTTON_COLOR:String = "Button Colors";
        
        /**
         * Reference to raw json configuration of items type that are customizable pieces.
         * 
         */
        private var m_customizables:Array;
        
        /**
         * Used to fetch the properties belonging to an item.
         */
        private var m_itemDataSource:ItemDataSource;
        
        /**
         * Used to figure out which items the player has already acquired.
         * Also needed to save new items purchased
         */
        private var m_playerItemInventory:ItemInventory;
        
        /**
         * Used to determine what items can be purchased
         */
        private var m_playerCurrencyModel:PlayerCurrencyModel;
        
        private var m_currencyCounter:CurrencyCounter;
        private var m_currencyChangeAnimation:CurrencyChangeAnimation;
        
        private var m_playerStatsAndSaveData:PlayerStatsAndSaveData;
        private var m_changeCursorScript:ChangeCursorScript;
        private var m_changeButtonColorScript:ChangeButtonColorScript;
        
        /**
         * List of category names broken down into the viewable pages
         */
        private var m_customizableCategoriesPages:Vector.<Vector.<String>>;
        private var m_activeCategoryPageIndex:int;
        private var m_activeCategoryButtons:Vector.<Button>;
        
        /**
         * If in the view level of items, need to keep track of the category we are in
         * as that will give us a good filter to determine general behavior when the player
         * clicks on a specific item button
         */
        private var m_selectedCategoryId:String;
        
        /**
         * A list of pages of all item ids belonging to an active category
         */
        private var m_customizableItemIdsPages:Vector.<Vector.<String>>;
        
        private var m_activeItemsPageIndex:int;
        
        /**
         * All buttons of items in the current item page
         */
        private var m_activeItemsButtonsInPage:Vector.<CustomizableItemButton>;
        
        private var m_globalPointBuffer:Point;
        private var m_boundsBuffer:Rectangle;
        
        /**
         * If not null, the prompt asking the user if they are sure they want to
         * buy the item is shown.
         */
        private var m_confirmationWidget:ConfirmationWidget;
        
        public function PlayerCollectionCustomizeViewer(customizablesInformation:Array,
                                                        playerItemInventory:ItemInventory,
                                                        itemDataSource:ItemDataSource,
                                                        playerCurrencyModel:PlayerCurrencyModel,
                                                        playerStatsAndSaveData:PlayerStatsAndSaveData,
                                                        changeCursorScript:ChangeCursorScript,
                                                        changeButtonColorScript:ChangeButtonColorScript,
                                                        canvasContainer:DisplayObjectContainer, 
                                                        assetManager:AssetManager, 
                                                        mouseState:MouseState,
                                                        buttonColorData:ButtonColorData,
                                                        id:String=null, 
                                                        isActive:Boolean=true)
        {
            super(canvasContainer, assetManager, mouseState, buttonColorData, id, isActive);
            
            m_customizables = customizablesInformation;
            m_playerItemInventory = playerItemInventory;
            m_itemDataSource = itemDataSource;
            m_playerCurrencyModel = playerCurrencyModel;
            m_playerStatsAndSaveData = playerStatsAndSaveData;
            m_changeCursorScript = changeCursorScript;
            m_changeButtonColorScript = changeButtonColorScript;
            
            m_customizableCategoriesPages = new Vector.<Vector.<String>>();
            m_activeCategoryPageIndex = -1;
            m_activeCategoryButtons = new Vector.<Button>();
            
            m_customizableItemIdsPages = new Vector.<Vector.<String>>();
            m_activeItemPageIndex = - 1;
            m_activeItemsButtonsInPage = new Vector.<CustomizableItemButton>();
            
            m_globalPointBuffer = new Point();
            m_boundsBuffer = new Rectangle();
            
            createBackButton();
            
            m_currencyCounter = new CurrencyCounter(assetManager, 180, 50, 50);
        }
        
        override public function show():void
        {
            super.show();
            
            m_titleText.text = "Buy and Change Options";
            m_canvasContainer.addChild(m_titleText);
            
            var customizableTypeIds:Vector.<String> = new Vector.<String>();
            var numCustomizables:int = m_customizables.length;
            var i:int;
            for (i = 0; i < numCustomizables; i++)
            {
                var customizableTypeData:Object = m_customizables[i];
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
        
        override public function hide():void
        {
            super.hide();
            
            // Clear out all the different subviews
            clearCategoryViewsInCurrentPage();
            clearItemsViewsInCurrentPage();
            m_backButton.removeFromParent();
            
            m_currencyCounter.removeFromParent();
            Starling.juggler.remove(m_currencyChangeAnimation);
        }
        
        override public function visit():int
        {
            if (m_isActive)
            {
                if (m_backButtonClickedLastFrame)
                {
                    m_backButtonClickedLastFrame = false;
                    
                    // Back can only occur at the item screen level, clear the items
                    clearItemsViewsInCurrentPage();
                    changeToCategoryView();
                }
                
                // Need to do custom picking of the customize item button since they are handwritten
                // ui components
                if (m_confirmationWidget == null)
                {
                    m_globalPointBuffer.x = m_mouseState.mousePositionThisFrame.x;
                    m_globalPointBuffer.y = m_mouseState.mousePositionThisFrame.y;
                    var numItemButtons:int = m_activeItemsButtonsInPage.length;
                    var i:int;
                    for (i = 0; i < numItemButtons; i++)
                    {
                        var button:CustomizableItemButton = m_activeItemsButtonsInPage[i];
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
        
        private function changeToCategoryView():void
        {
            drawCategoryButtonsForPage(m_activeCategoryPageIndex);
            
            m_backButton.removeFromParent();
        }
        
        private function drawCategoryButtonsForPage(pageIndex:int):void
        {
            var buttonWidth:Number = 400;
            var buttonHeight:Number = 70;
            var gap:Number = 15;
            
            var categoryIdsForPage:Vector.<String> = m_customizableCategoriesPages[pageIndex];
            var numCategories:int = categoryIdsForPage.length;
            var i:int;
            var xOffset:Number = (800 - buttonWidth) * 0.5;
            var yOffset:Number = m_titleText.y + m_titleText.height;
            var nineSliceRectangle:Rectangle = new Rectangle(8, 8, 16, 16);
            var scale9Texture:Scale9Textures = new Scale9Textures(m_assetManager.getTexture("button_white"), nineSliceRectangle);
            for (i = 0; i < numCategories; i++)
            {
                var categoryButton:Button = new Button();
                var defaultBackground:Scale9Image = new Scale9Image(scale9Texture);
                defaultBackground.color = m_buttonColorData.getUpButtonColor();
                categoryButton.defaultSkin = defaultBackground;
                
                categoryButton.label = categoryIdsForPage[i];
                categoryButton.labelFactory = categoryLabelFactory;
                
                var hoverBackground:Scale9Image = new Scale9Image(scale9Texture);
                hoverBackground.color = XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.3);
                categoryButton.hoverSkin = hoverBackground;
                
                categoryButton.downSkin = hoverBackground;
                
                categoryButton.width = buttonWidth;
                categoryButton.height = buttonHeight;
                categoryButton.x = xOffset;
                categoryButton.y = yOffset;
                categoryButton.addEventListener(Event.TRIGGERED, onCategorySelected);
                m_canvasContainer.addChild(categoryButton);
                m_activeCategoryButtons.push(categoryButton);
                
                yOffset += buttonHeight + gap;
            }
            
            function categoryLabelFactory():ITextRenderer
            {
                var renderer:TextFieldTextRenderer = new TextFieldTextRenderer();
                var fontName:String = GameFonts.DEFAULT_FONT_NAME;
                renderer.embedFonts = GameFonts.getFontIsEmbedded(fontName);
                renderer.textFormat = new TextFormat(fontName, 24, 0xFFFFFF);
                return renderer;
            }
        }
        
        private function clearCategoryViewsInCurrentPage():void
        {
            for each (var categoryButton:Button in m_activeCategoryButtons)
            {
                categoryButton.removeEventListener(Event.TRIGGERED, onCategorySelected);
                categoryButton.removeFromParent(true);
            }
            m_activeCategoryButtons.length = 0;
        }
        
        private function onCategorySelected(event:Event):void
        {
            // Need to find the appropriate category and then open up the
            // items belonging to it
            var targetButton:Button = event.currentTarget as Button;
            var indexOfButton:int = m_activeCategoryButtons.indexOf(targetButton);
            if (indexOfButton > -1)
            {
                var categoryIdsInPage:Vector.<String> = m_customizableCategoriesPages[m_activeCategoryPageIndex];
                var selectedCategoryId:String = categoryIdsInPage[indexOfButton];
                
                // From the category id, switch to a view that shows the 'items' belonging to
                // that category.
                for each (var customizableCategoryData:Object in m_customizables)
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
        private function changeToItemsView(customizableCategoryData:Object):void
        {
            var itemsPerPage:int = customizableCategoryData.columnsPerPage * customizableCategoryData.rowsPerPage;
            var itemIdsInCategory:Vector.<String> = new Vector.<String>();
            for each (var itemId:String in customizableCategoryData.itemIds)
            {
                itemIdsInCategory.push(itemId);
            }
            ListUtil.subdivideList(itemIdsInCategory, itemsPerPage, m_customizableItemIdsPages);
            m_activeItemPageIndex = 0;
            drawItemButtonsForPage(m_activeItemPageIndex, customizableCategoryData);
            
            m_canvasContainer.addChild(m_backButton);
        }
        
        private function drawItemButtonsForPage(pageIndex:int, customizableCategoryData:Object):void
        {
            var categoryId:String = customizableCategoryData.id;
            var buttonWidth:Number = customizableCategoryData.typicalWidth;
            var buttonHeight:Number = customizableCategoryData.typicalHeight;
            var columns:int = customizableCategoryData.columnsPerPage;
            var rows:int = customizableCategoryData.rowsPerPage;
            
            var itemIdsForPage:Vector.<String> = m_customizableItemIdsPages[pageIndex];
            var numItems:int = itemIdsForPage.length;
            var i:int;
            var yOffset:Number = 60;
            var spanningWidth:Number = 800;
            var spanningHeight:Number = 400;
            var calculatedHorizontalGap:Number = (spanningWidth - columns * buttonWidth) / (columns + 1);
            var calculatedVerticalGap:Number = (spanningHeight - rows * buttonHeight) / (rows + 1);
            for (i = 0; i < itemIdsForPage.length; i++)
            {
                var itemId:String = itemIdsForPage[i];
                
                // Button appearance will differ if the item was already purchased or if it is currently equipped.
                // The logic to change this is all baked inside the button class
                var itemButton:CustomizableItemButton = new CustomizableItemButton(itemId, 
                    categoryId, m_itemDataSource, m_playerItemInventory, m_assetManager, buttonWidth, buttonHeight,
                    m_buttonColorData.getUpButtonColor(),
                    XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.4)
                );
                
                var rowIndex:int = i / columns;
                var columnIndex:int = i % columns;
                itemButton.x = columnIndex * buttonWidth + calculatedHorizontalGap * (columnIndex + 1);
                itemButton.y = rowIndex * buttonHeight + calculatedVerticalGap * (rowIndex + 1) + yOffset;
                
                m_canvasContainer.addChild(itemButton);
                m_activeItemsButtonsInPage.push(itemButton);
            }
        }
        
        private function clearItemsViewsInCurrentPage():void
        {
            for each (var itemButton:CustomizableItemButton in m_activeItemsButtonsInPage)
            {
                itemButton.removeFromParent(true);
            }
            
            m_activeItemsButtonsInPage.length = 0;
            
            // Delete the pagination of items, gets reconstructed the next time we enter an item
            m_customizableItemIdsPages.length = 0;
        }
        
        private function onItemsViewSelected(targetButton:CustomizableItemButton):void
        {
            // Need to remap to the item id and view several properties
            var indexOfButton:int = m_activeItemsButtonsInPage.indexOf(targetButton);
            
            var itemsIdsInPage:Vector.<String> = m_customizableItemIdsPages[m_activeItemsPageIndex];
            var itemIdSelected:String = itemsIdsInPage[indexOfButton];
            
            // The effect of clicking also depends on the category type.
            // For cursors the mouse needs to change immediately
            // For button colors, some property of how the buttons are drawn need to
            
            // We just use the category id to differentiate, and consider it safe to assume every item
            // in a category will have similar and known sets of properties
            var playerOwnsItem:Boolean = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                itemIdSelected, ItemIdComponent.TYPE_ID) != null;
            if (playerOwnsItem)
            {
                switchToItem(itemIdSelected);
                refreshItemButtons();
            }
            else
            {
                // Pressing on any un-owned item should trigger a prompt asking for purchase
                var priceComponent:PriceComponent = m_itemDataSource.getComponentFromEntityIdAndType(itemIdSelected, PriceComponent.TYPE_ID) as PriceComponent;
                var itemCost:int = priceComponent.price;
                if (itemCost <= m_playerCurrencyModel.totalCoins)
                {
                    // Display a confirmation screen
                    m_confirmationWidget = new ConfirmationWidget(800, 600, 
                        function():DisplayObject
                        {
                            var mainDisplayContainer:Sprite = new Sprite();
                            
                            var textFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
                            var measuringText:MeasuringTextField = new MeasuringTextField();
                            measuringText.defaultTextFormat = textFormat;
                            measuringText.text = StringTable.lookup("buy_for") + " ";
                            
                            var askText:TextField = new TextField(measuringText.textWidth + 10,
                                measuringText.textHeight + 10, measuringText.text, textFormat.font, textFormat.size as int, textFormat.color as uint);
                            askText.hAlign = HAlign.LEFT
                            mainDisplayContainer.addChild(askText);
                            
                            var priceIndicatorHeight:Number = 40;
                            var coin:Image = new Image(m_assetManager.getTexture("coin"));
                            coin.scaleX = coin.scaleY = priceIndicatorHeight / coin.height;
                            coin.x = askText.x + askText.width;
                            mainDisplayContainer.addChild(coin);
                            
                            var displayedPrice:String = itemCost + "?";
                            measuringText.text = displayedPrice;
                            var priceText:TextField = new TextField(measuringText.textWidth + 10, measuringText.textHeight + 10, displayedPrice,
                                textFormat.font, textFormat.size as int, textFormat.color as uint);
                            priceText.x = coin.x + coin.width + 10;
                            mainDisplayContainer.addChild(priceText);
                            
                            // Add the icon below
                            var itemIcon:DisplayObject = targetButton.createItemIcon();
                            itemIcon.x = (mainDisplayContainer.width - itemIcon.width) * 0.5;
                            itemIcon.y = askText.y + askText.height + 10;
                            mainDisplayContainer.addChild(itemIcon);
                            
                            return mainDisplayContainer;
                        }, 
                        function():void
                        {
                            // Subtract item cost from the player's current coins
                            var newCoinValue:int = m_playerCurrencyModel.totalCoins - itemCost;
                            m_currencyChangeAnimation.start(m_playerCurrencyModel.totalCoins, newCoinValue);
                            Starling.juggler.add(m_currencyChangeAnimation);
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
                        m_buttonColorData.getUpButtonColor(), StringTable.lookup("yes"), StringTable.lookup("no")
                    );
                }
                else
                {
                    m_confirmationWidget = new ConfirmationWidget(800, 600, 
                        function():DisplayObject
                        {
                            var contentTextField:TextField = new TextField(
                                400,
                                200,
                                StringTable.lookup("not_enough_coins"), 
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
                        StringTable.lookup("ok"), null, true
                    );
                }
                m_canvasContainer.stage.addChild(m_confirmationWidget);
            }
        }
        
        private function switchToItem(itemIdSelected:String):void
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
                for each (var button:CustomizableItemButton in m_activeItemsButtonsInPage)
                {
                    button.setDefaultColor(m_buttonColorData.getUpButtonColor());
                    button.setSelectedColor(XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.3));
                }
            }
        }
        
        private function refreshItemButtons():void
        {
            // For simplicity, just refresh every button on the screen
            for each (var button:CustomizableItemButton in m_activeItemsButtonsInPage)
            {
                button.refresh();
            }
        }
        
        private function discardConfirmation():void
        {
            m_confirmationWidget.removeFromParent(true);
            m_confirmationWidget = null;
        }
    }
}