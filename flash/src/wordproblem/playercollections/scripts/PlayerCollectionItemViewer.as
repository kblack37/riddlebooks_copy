package wordproblem.playercollections.scripts
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.ListUtil;
    import dragonbox.common.util.XColor;
    
    import starling.display.DisplayObjectContainer;
    import starling.textures.Texture;
    
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.DescriptionComponent;
    import wordproblem.engine.component.ItemIdComponent;
    import wordproblem.engine.component.NameComponent;
    import wordproblem.engine.component.RigidBodyComponent;
    import wordproblem.engine.component.TextureCollectionComponent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.items.ItemDataSource;
    import wordproblem.items.ItemInventory;
    import wordproblem.player.ButtonColorData;
    import wordproblem.playercollections.items.PlayerCollectionCategoryButton;
    import wordproblem.playercollections.items.PlayerCollectionItemButton;
    import wordproblem.playercollections.items.PlayerCollectionItemScreen;
    import wordproblem.resource.AssetManager;
    import wordproblem.resource.FlashResourceUtil;
    
    /**
     * This script handles rendering the screen showing all the collectables available to the player.
     * 
     * There are two levels of screens, one shows the categories of the collectables and how many total
     * the player has earned for each category.
     * 
     * The other shows individual items earned for that item.
     */
    public class PlayerCollectionItemViewer extends PlayerCollectionViewer
    {
        private static const VIEW_LEVEL_CATEGORIES:int = 0;
        private static const VIEW_LEVEL_ITEMS_IN_CATEGORY:int = 1;
        private static const VIEW_LEVEL_SINGLE_ITEM:int = 2;
        
        /**
         * Keep track of what mode of the screen that the player is looking at.
         * This helps separate what logic for the ui should be active on a given frame.
         */
        private var m_currentViewLevel:int;
        
        /**
         * Holds raw json configuration data
         * [id:<string name of category>, itemIds:[string item ids], .. other ui settings]
         */
        private var m_collectionInformation:Array;
        
        /** Used to allow faster lookup of category information */
        private var m_categoryIdToCollectionObjectMap:Dictionary;
        private var m_playerInventory:ItemInventory;
        private var m_itemDataSource:ItemDataSource;
        
        /**
         * When rendering buttons for each category, all categories may not fit on
         * one screen. The current ui will break them up into pages. Each element of this
         * list gives a list of category belonging to a single page
         */
        private var m_collectionCategoriesPages:Vector.<Vector.<String>>;
        
        /**
         * The current page of categories currently visible
         */
        private var m_activeCategoryPageIndex:int;
        
        /**
         * List of active buttons the player clicks on to go into a category
         */
        private var m_activeCategoryButtons:Vector.<PlayerCollectionCategoryButton>;
        
        /**
         * The items belonging to a category may not fit on the screen all at once so
         * we break them up into pages.
         */
        private var m_collectionItemPages:Vector.<Vector.<String>>;
        
        private var m_selectedCategoryId:String;
        
        /**
         * List of active buttons the player can click on to view a specific item belonging to a category
         */
        private var m_activeItemButtons:Vector.<PlayerCollectionItemButton>;
        
        /**
         * Point to the currently active screen that shows a description of an item.
         */
        private var m_activeItemScreen:PlayerCollectionItemScreen;
        
        private var m_globalMouseBuffer:Point;
        private var m_localMouseBuffer:Point;
        private var m_localBoundsBuffer:Rectangle;
        
        public function PlayerCollectionItemViewer(collectionInformation:Array,
                                                   playerInventory:ItemInventory,
                                                   itemDataSource:ItemDataSource,
                                                   canvasContainer:DisplayObjectContainer,
                                                   assetManager:AssetManager,
                                                   mouseState:MouseState,
                                                   buttonColorData:ButtonColorData,
                                                   id:String=null, 
                                                   isActive:Boolean=true)
        {
            super(canvasContainer, assetManager, mouseState, buttonColorData, id, isActive);
            
            m_collectionInformation = collectionInformation;
            m_categoryIdToCollectionObjectMap = new Dictionary();
            m_playerInventory = playerInventory;
            m_itemDataSource = itemDataSource;
            m_collectionCategoriesPages = new Vector.<Vector.<String>>();
            m_activeCategoryButtons = new Vector.<PlayerCollectionCategoryButton>();
            m_collectionItemPages = new Vector.<Vector.<String>>();
            m_activeItemButtons = new Vector.<PlayerCollectionItemButton>();
            
            m_globalMouseBuffer = new Point();
            m_localMouseBuffer = new Point();
            m_localBoundsBuffer = new Rectangle();
            
            createBackButton();
        }
        
        override public function visit():int
        {
            if (m_isActive)
            {
                // There are three 'levels' for the collection viewer, the first is viewing the categories,
                // the second is viewing all items in one category, the last is viewing details about a
                // particular item.
                m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
                m_canvasContainer.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_CATEGORIES)
                {
                    var categoryButtonIndexContainingPoint:int = -1;
                    var i:int;
                    var numButtons:int = m_activeCategoryButtons.length;
                    for (i = 0; i < numButtons; i++)
                    {
                        var categoryButton:PlayerCollectionCategoryButton = m_activeCategoryButtons[i];
                        categoryButton.getBounds(m_canvasContainer, m_localBoundsBuffer);
                        if (m_localBoundsBuffer.containsPoint(m_localMouseBuffer))
                        {
                            categoryButtonIndexContainingPoint = i
                            categoryButton.selected = true;
                        }
                        else
                        {
                            categoryButton.selected = false;
                        }
                    }
                    
                    if (categoryButtonIndexContainingPoint != -1)
                    {
                        // If player clicked on a category, then the view mode should switch to showing all the items
                        // in that category. (Need some back button to go back to the category screen)
                        if (m_mouseState.leftMousePressedThisFrame)
                        {
                            var categoryInformationObject:Object = m_activeCategoryButtons[categoryButtonIndexContainingPoint].getCategoryInformationObject();
                            clearCategoryView();
                            changeToCategoryItemsView(categoryInformationObject);
                            
                            m_selectedCategoryId = categoryInformationObject.id;
                        }
                    }
                }
                else if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_ITEMS_IN_CATEGORY)
                {
                    var itemButtonIndexContainingPoint:int = -1;
                    numButtons = m_activeItemButtons.length;
                    for (i = 0; i < numButtons; i++)
                    {
                        var itemButton:PlayerCollectionItemButton = m_activeItemButtons[i];
                        itemButton.getBounds(m_canvasContainer, m_localBoundsBuffer);
                        if (m_localBoundsBuffer.containsPoint(m_localMouseBuffer))
                        {
                            itemButtonIndexContainingPoint = i
                            itemButton.selected = true;
                        }
                        else
                        {
                            itemButton.selected = false;
                        }
                    }
                    
                    if (itemButtonIndexContainingPoint != -1)
                    {
                        if (m_mouseState.leftMousePressedThisFrame)
                        {
                            itemButton = m_activeItemButtons[itemButtonIndexContainingPoint];
                            if (!itemButton.getLocked())
                            {
                                itemButton.selected = false;
                                var itemId:String = itemButton.getItemId();
                                
                                clearCategoryItemsView(false);
                                changeToItemView(itemId);
                            }
                        }
                    }
                }
                else
                {
                    // The final view is just looking at a single item.
                    // There is nothing the player can do here other than look at a bigger version of the
                    // picture and read the description
                }
                
                if (m_backButtonClickedLastFrame)
                {
                    m_backButtonClickedLastFrame = false;
                    if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_ITEMS_IN_CATEGORY)
                    {
                        // Back out to the category view
                        clearCategoryItemsView(true);
                        changeToCategoryView();
                        m_activeItemPageIndex = 0;
                    }
                    else if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_SINGLE_ITEM)
                    {
                        // Back out to the items in category view
                        clearItemView();
                        changeToCategoryItemsView(null);
                    }
                }
                
                if (m_scrollLeftClickedLastFrame)
                {
                    m_scrollLeftClickedLastFrame = false;
                    
                    if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_CATEGORIES)
                    {
                        m_activeCategoryPageIndex--;
                        if (m_activeCategoryPageIndex < 0)
                        {
                            m_activeCategoryPageIndex = m_collectionCategoriesPages.length - 1;
                        }
                        
                        clearCategoryView();
                        changeToCategoryView();
                    }
                    else if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_ITEMS_IN_CATEGORY)
                    {
                        m_activeItemPageIndex--;
                        if (m_activeItemPageIndex < 0)
                        {
                            m_activeItemPageIndex = m_collectionItemPages.length - 1;
                        }
                        
                        clearCategoryItemsView(true);
                        changeToCategoryItemsView(m_categoryIdToCollectionObjectMap[m_selectedCategoryId]);
                    }
                }
                
                if (m_scrollRightClickedLastFrame)
                {
                    m_scrollRightClickedLastFrame = false;
                    
                    if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_CATEGORIES)
                    {
                        m_activeCategoryPageIndex++;
                        if (m_activeCategoryPageIndex >= m_collectionCategoriesPages.length)
                        {
                            m_activeCategoryPageIndex = 0;
                        }
                        
                        clearCategoryView();
                        changeToCategoryView();
                    }
                    else if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_ITEMS_IN_CATEGORY)
                    {
                        m_activeItemPageIndex++;
                        if (m_activeItemPageIndex >= m_collectionItemPages.length)
                        {
                            m_activeItemPageIndex = 0;
                        }
                        
                        clearCategoryItemsView(true);
                        changeToCategoryItemsView(m_categoryIdToCollectionObjectMap[m_selectedCategoryId]);
                    }
                }
            }
            return ScriptStatus.SUCCESS;
        }
        
        override public function show():void
        {
            super.show();
            
            m_backButton.x = 58;
            m_backButton.y = 0;
            
            // Do some initial pre-processing of collection type information
            var playerItemIdComponents:Vector.<Component> = m_playerInventory.componentManager.getComponentListForType(ItemIdComponent.TYPE_ID);
            var i:int;
            var numCollectionTypes:int = m_collectionInformation.length;
            var categoryIdList:Vector.<String> = new Vector.<String>();
            var collectionCategory:Object;
            for (i = 0; i < numCollectionTypes; i++)
            {
                collectionCategory = m_collectionInformation[i];
                
                var categoryId:String = collectionCategory.id;
                var itemIds:Array = collectionCategory.itemIds;
                
                // Compare the item ids in the category to that in the player's inventory
                // This will inform us what items the player has left to earn in a collection
                // In the type map we also cache whether the player has earned that item already
                // in a new array (use the instance id)
                var j:int;
                var itemIdsEarned:Array = [];
                var numItemIdsInTypeEarned:int = 0;
                var numItemIds:int = itemIds.length;
                for (j = 0; j < numItemIds; j++)
                {
                    var itemId:String = itemIds[j];
                    var k:int;
                    var itemIdComponent:ItemIdComponent;
                    var numPlayerItemIds:int = playerItemIdComponents.length;
                    for (k = 0; k < numPlayerItemIds; k++)
                    {
                        itemIdComponent = playerItemIdComponents[k] as ItemIdComponent;
                        if (itemIdComponent.itemId == itemId)
                        {
                            numItemIdsInTypeEarned++;
                            itemIdsEarned.push(itemIdComponent.entityId);
                            break;
                        }
                    }
                }
                
                // Caching instance id directly in the map
                collectionCategory.itemInstanceIds = itemIdsEarned;
                collectionCategory.numItemsEarned = numItemIdsInTypeEarned;
                
                m_categoryIdToCollectionObjectMap[categoryId] = collectionCategory;
                categoryIdList.push(categoryId);
            }
            
            m_activeCategoryPageIndex = 0;
            m_activeItemPageIndex = 0;
            
            // Segment all collection categories into pages
            ListUtil.subdivideList(categoryIdList, 5, m_collectionCategoriesPages);
            
            changeToCategoryView();
        }
        
        override public function hide():void
        {
            super.hide();
            
            m_backButton.removeFromParent();
            
            // Dispose of all currently visible pieces
            clearCategoryItemsView(true);
            clearCategoryView();
            clearItemView();
            m_collectionCategoriesPages.length = 0;
            
            m_currentViewLevel = -1;
        }
        
        /**
         * Draw a set of buttons, each representing a item category type on a specific page
         */
        private function drawCategoryButtonsForPage(pageIndex:int):void
        {
            var buttonWidth:Number = 400;
            var buttonHeight:Number = 70;
            var categoriesForPage:Vector.<String> = m_collectionCategoriesPages[pageIndex];
            var i:int;
            var numCategoriesForPage:int = categoriesForPage.length;
            for (i = 0; i < numCategoriesForPage; i++)
            {
                var categoryId:String = categoriesForPage[i];
                
                // Get back important information about the category id
                var categoryInformationObject:Object = m_categoryIdToCollectionObjectMap[categoryId];
                
                var button:PlayerCollectionCategoryButton = new PlayerCollectionCategoryButton(
                    categoryInformationObject, m_assetManager, buttonWidth, buttonHeight, m_buttonColorData.getUpButtonColor()
                );
                m_activeCategoryButtons.push(button);
            }
            
            // Need to now layout the category buttons
            var gap:Number = 12;
            var xOffset:Number = (800 - buttonWidth) * 0.5;
            var yOffset:Number = m_titleText.y + m_titleText.height;
            var numButtons:int = m_activeCategoryButtons.length;
            for (i = 0; i < numButtons; i++)
            {
                button = m_activeCategoryButtons[i];
                button.x = xOffset;
                button.y = yOffset;
                m_canvasContainer.addChild(button);
                
                yOffset += button.height + gap;
            }
            
            showPageIndicator(pageIndex + 1, m_collectionCategoriesPages.length);
        }
        
        /**
         * Draw a set of buttons, each representing a item on a specific page
         */
        private function drawCategoryItemButtonsForPage(categoryId:String, pageIndex:int):void
        {
            if (m_collectionItemPages.length == 0)
            {
                return;
            }
            
            var categoryItemsForPage:Vector.<String> = m_collectionItemPages[pageIndex];
            
            var categoryInformationObject:Object = m_categoryIdToCollectionObjectMap[categoryId];
            var allInstanceIds:Array = categoryInformationObject.itemInstanceIds;
            var allItemIds:Array = categoryInformationObject.itemIds;
            
            var typicalWidth:Number = categoryInformationObject.typicalWidth;
            var typicalHeight:Number = categoryInformationObject.typicalHeight;
            
            var i:int;
            var numItemsForPage:int = categoryItemsForPage.length;
            for (i = 0; i < numItemsForPage; i++)
            {
                var itemId:String = categoryItemsForPage[i];
                
                // We assume all item textures are single static pieces
                var textureComponent:TextureCollectionComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                    itemId, 
                    TextureCollectionComponent.TYPE_ID
                ) as TextureCollectionComponent;
                
                // HACK: Flash resources need to be drawn then dumped into asset manager manually
                var textureDataObject:Object = textureComponent.textureCollection[0];
                if (textureDataObject.type == "FlashMovieClip")
                {
                    var rigidBodyComponent:RigidBodyComponent = m_itemDataSource.getComponentFromEntityIdAndType(itemId, RigidBodyComponent.TYPE_ID) as RigidBodyComponent;
                    var textureFromFlash:Texture = FlashResourceUtil.getTextureFromFlashString(textureDataObject.flashId, textureDataObject.params, 1, rigidBodyComponent.boundingRectangle);
                    m_assetManager.addTexture(textureDataObject.textureName, textureFromFlash);
                }
                var textureName:String = textureDataObject.textureName;
                
                // Render item differently if the item was earned by player or not (show lock if not)
                var earnedItem:Boolean = allInstanceIds.indexOf(itemId) >= 0;
                var button:PlayerCollectionItemButton = new PlayerCollectionItemButton(textureName, itemId, !earnedItem, m_assetManager, 
                    typicalWidth, typicalHeight,
                    m_buttonColorData.getUpButtonColor(),
                    XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.3)
                );
                m_activeItemButtons.push(button);
            }
            
            // Need to now layout the category buttons
            var columns:int = categoryInformationObject.columnsPerPage;
            var rows:int = categoryInformationObject.rowsPerPage;   // Fill in by column order
            
            var spanningWidth:Number = 800;
            var spanningHeight:Number = 400;
            var calculatedHorizontalGap:Number = (spanningWidth - columns * typicalWidth) / (columns + 1);
            var calculatedVerticalGap:Number = (spanningHeight - rows * typicalHeight) / (rows + 1);
            
            var yOffset:Number = m_titleText.height;
            var numButtons:int = m_activeItemButtons.length;
            for (i = 0; i < numButtons; i++)
            {
                var rowIndex:int = i / columns;
                var columnIndex:int = i % columns;
                button = m_activeItemButtons[i];
                button.x = columnIndex * typicalWidth + calculatedHorizontalGap * (columnIndex + 1);
                button.y = rowIndex * typicalHeight + calculatedVerticalGap * (rowIndex + 1) + yOffset;
                m_canvasContainer.addChild(button);
            }
            
            showPageIndicator(pageIndex + 1, m_collectionItemPages.length);
        }
        
        private function changeToCategoryView():void
        {
            m_currentViewLevel = PlayerCollectionItemViewer.VIEW_LEVEL_CATEGORIES;
            m_titleText.text = "Collectables";
            m_canvasContainer.addChild(m_titleText);
            
            // Draw a page of categories
            drawCategoryButtonsForPage(m_activeCategoryPageIndex);
            
            // Show scroll buttons if multiple pages
            super.showScrollButtons(m_collectionCategoriesPages.length > 1);
        }
        
        private function clearCategoryView():void
        {
            // Clear out the category buttons
            for each (var categoryButton:PlayerCollectionCategoryButton in m_activeCategoryButtons)
            {
                categoryButton.removeFromParent(true);
            }
            m_activeCategoryButtons.length = 0;
        }
        
        private function changeToCategoryItemsView(categoryInformationObject:Object):void
        {
            m_currentViewLevel = PlayerCollectionItemViewer.VIEW_LEVEL_ITEMS_IN_CATEGORY;
            
            // Subdivide the list of items belonging to the selected category
            // It requires a vector so push the ids into a temp list
            if (categoryInformationObject != null)
            {
                // Set title to name of category
                m_titleText.text = categoryInformationObject.id;
                
                var itemsPerPage:int = categoryInformationObject.columnsPerPage * categoryInformationObject.rowsPerPage;
                var itemIdsInCategory:Vector.<String> = new Vector.<String>();
                for each (var itemId:String in categoryInformationObject.itemIds)
                {
                    itemIdsInCategory.push(itemId);
                }
                ListUtil.subdivideList(itemIdsInCategory, itemsPerPage, m_collectionItemPages);
                this.drawCategoryItemButtonsForPage(categoryInformationObject.id, m_activeItemPageIndex);
                
                // Make sure the backout button is added
                m_canvasContainer.addChild(m_backButton);
            }
            else
            {
                for each (var itemButton:PlayerCollectionItemButton in m_activeItemButtons)
                {
                    m_canvasContainer.addChild(itemButton);
                }
            }
            
            // Show scroll buttons if multiple pages
            super.showScrollButtons(m_collectionItemPages.length > 1);
        }
        
        private function clearCategoryItemsView(disposeCurrentPage:Boolean):void
        {
            if (disposeCurrentPage)
            {
                // Discard all data related to the items for a particular category
                // (DISPOSE button to release textures if necessary)
                for each (itemButton in m_activeItemButtons)
                {
                    itemButton.removeFromParent(true);
                }
                m_activeItemButtons.length = 0;
                m_collectionItemPages.length = 0;
                
                // undo button is no longer needed
                m_backButton.removeFromParent();
            }
            else
            {
                // Remove item buttons from the screen for now
                for each (var itemButton:PlayerCollectionItemButton in m_activeItemButtons)
                {
                    itemButton.removeFromParent();
                }
            }
        }
        
        private function changeToItemView(itemId:String):void
        {
            m_currentViewLevel = PlayerCollectionItemViewer.VIEW_LEVEL_SINGLE_ITEM;
            
            // Get all important description components for this item
            var nameComponent:NameComponent = m_itemDataSource.getComponentFromEntityIdAndType(itemId, NameComponent.TYPE_ID) as NameComponent;
            var textureComponent:TextureCollectionComponent = m_itemDataSource.getComponentFromEntityIdAndType(itemId, TextureCollectionComponent.TYPE_ID) as TextureCollectionComponent;
            var descriptionComponent:DescriptionComponent = m_itemDataSource.getComponentFromEntityIdAndType(itemId, DescriptionComponent.TYPE_ID) as DescriptionComponent;
            
            // HACK: For flash movie clips we need to create the texture AND then insert it into the asset manager
            // Assuming the item texture was drawn in the category screen
            var textureDataObject:Object = textureComponent.textureCollection[0];
            m_activeItemScreen = new PlayerCollectionItemScreen(
                textureDataObject.textureName,
                nameComponent.name,
                (descriptionComponent != null) ? descriptionComponent.desc : "",
                600,
                400,
                m_assetManager
            );
            m_activeItemScreen.x = 100;
            m_activeItemScreen.y = m_titleText.y + m_titleText.height + 10;
            m_canvasContainer.addChild(m_activeItemScreen);
            
            // Make sure scroll arrows hidden
            m_scrollLeftButton.removeFromParent();
            m_scrollRightButton.removeFromParent();
        }
        
        private function clearItemView():void
        {
            // Remove the item description screen
            if (m_activeItemScreen != null)
            {
                m_activeItemScreen.removeFromParent(true);
                m_activeItemScreen = null;
            }
        }
    }
}