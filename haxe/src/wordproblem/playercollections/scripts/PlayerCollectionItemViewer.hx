package wordproblem.playercollections.scripts;

import wordproblem.playercollections.scripts.PlayerCollectionViewer;

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
class PlayerCollectionItemViewer extends PlayerCollectionViewer
{
    private static inline var VIEW_LEVEL_CATEGORIES : Int = 0;
    private static inline var VIEW_LEVEL_ITEMS_IN_CATEGORY : Int = 1;
    private static inline var VIEW_LEVEL_SINGLE_ITEM : Int = 2;
    
    /**
     * Keep track of what mode of the screen that the player is looking at.
     * This helps separate what logic for the ui should be active on a given frame.
     */
    private var m_currentViewLevel : Int;
    
    /**
     * Holds raw json configuration data
     * [id:<string name of category>, itemIds:[string item ids], .. other ui settings]
     */
    private var m_collectionInformation : Array<Dynamic>;
    
    /** Used to allow faster lookup of category information */
    private var m_categoryIdToCollectionObjectMap : Dictionary;
    private var m_playerInventory : ItemInventory;
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * When rendering buttons for each category, all categories may not fit on
     * one screen. The current ui will break them up into pages. Each element of this
     * list gives a list of category belonging to a single page
     */
    private var m_collectionCategoriesPages : Array<Array<String>>;
    
    /**
     * The current page of categories currently visible
     */
    private var m_activeCategoryPageIndex : Int;
    
    /**
     * List of active buttons the player clicks on to go into a category
     */
    private var m_activeCategoryButtons : Array<PlayerCollectionCategoryButton>;
    
    /**
     * The items belonging to a category may not fit on the screen all at once so
     * we break them up into pages.
     */
    private var m_collectionItemPages : Array<Array<String>>;
    
    private var m_selectedCategoryId : String;
    
    /**
     * List of active buttons the player can click on to view a specific item belonging to a category
     */
    private var m_activeItemButtons : Array<PlayerCollectionItemButton>;
    
    /**
     * Point to the currently active screen that shows a description of an item.
     */
    private var m_activeItemScreen : PlayerCollectionItemScreen;
    
    private var m_globalMouseBuffer : Point;
    private var m_localMouseBuffer : Point;
    private var m_localBoundsBuffer : Rectangle;
    
    public function new(collectionInformation : Array<Dynamic>,
            playerInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            canvasContainer : DisplayObjectContainer,
            assetManager : AssetManager,
            mouseState : MouseState,
            buttonColorData : ButtonColorData,
            id : String = null,
            isActive : Bool = true)
    {
        super(canvasContainer, assetManager, mouseState, buttonColorData, id, isActive);
        
        m_collectionInformation = collectionInformation;
        m_categoryIdToCollectionObjectMap = new Dictionary();
        m_playerInventory = playerInventory;
        m_itemDataSource = itemDataSource;
        m_collectionCategoriesPages = new Array<Array<String>>();
        m_activeCategoryButtons = new Array<PlayerCollectionCategoryButton>();
        m_collectionItemPages = new Array<Array<String>>();
        m_activeItemButtons = new Array<PlayerCollectionItemButton>();
        
        m_globalMouseBuffer = new Point();
        m_localMouseBuffer = new Point();
        m_localBoundsBuffer = new Rectangle();
        
        createBackButton();
    }
    
    override public function visit() : Int
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
                var categoryButtonIndexContainingPoint : Int = -1;
                var i : Int;
                var numButtons : Int = m_activeCategoryButtons.length;
                for (i in 0...numButtons){
                    var categoryButton : PlayerCollectionCategoryButton = m_activeCategoryButtons[i];
                    categoryButton.getBounds(m_canvasContainer, m_localBoundsBuffer);
                    if (m_localBoundsBuffer.containsPoint(m_localMouseBuffer)) 
                    {
                        categoryButtonIndexContainingPoint = i;
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
                        var categoryInformationObject : Dynamic = m_activeCategoryButtons[categoryButtonIndexContainingPoint].getCategoryInformationObject();
                        clearCategoryView();
                        changeToCategoryItemsView(categoryInformationObject);
                        
                        m_selectedCategoryId = categoryInformationObject.id;
                    }
                }
            }
            else if (m_currentViewLevel == PlayerCollectionItemViewer.VIEW_LEVEL_ITEMS_IN_CATEGORY) 
            {
                var itemButtonIndexContainingPoint : Int = -1;
                numButtons = m_activeItemButtons.length;
                for (i in 0...numButtons){
                    var itemButton : PlayerCollectionItemButton = m_activeItemButtons[i];
                    itemButton.getBounds(m_canvasContainer, m_localBoundsBuffer);
                    if (m_localBoundsBuffer.containsPoint(m_localMouseBuffer)) 
                    {
                        itemButtonIndexContainingPoint = i;
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
                            var itemId : String = itemButton.getItemId();
                            
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
                    changeToCategoryItemsView(Reflect.field(m_categoryIdToCollectionObjectMap, m_selectedCategoryId));
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
                    changeToCategoryItemsView(Reflect.field(m_categoryIdToCollectionObjectMap, m_selectedCategoryId));
                }
            }
        }
        return ScriptStatus.SUCCESS;
    }
    
    override public function show() : Void
    {
        super.show();
        
        m_backButton.x = 58;
        m_backButton.y = 0;
        
        // Do some initial pre-processing of collection type information
        var playerItemIdComponents : Array<Component> = m_playerInventory.componentManager.getComponentListForType(ItemIdComponent.TYPE_ID);
        var i : Int;
        var numCollectionTypes : Int = m_collectionInformation.length;
        var categoryIdList : Array<String> = new Array<String>();
        var collectionCategory : Dynamic;
        for (i in 0...numCollectionTypes){
            collectionCategory = m_collectionInformation[i];
            
            var categoryId : String = collectionCategory.id;
            var itemIds : Array<Dynamic> = collectionCategory.itemIds;
            
            // Compare the item ids in the category to that in the player's inventory
            // This will inform us what items the player has left to earn in a collection
            // In the type map we also cache whether the player has earned that item already
            // in a new array (use the instance id)
            var j : Int;
            var itemIdsEarned : Array<Dynamic> = [];
            var numItemIdsInTypeEarned : Int = 0;
            var numItemIds : Int = itemIds.length;
            for (j in 0...numItemIds){
                var itemId : String = itemIds[j];
                var k : Int;
                var itemIdComponent : ItemIdComponent;
                var numPlayerItemIds : Int = playerItemIdComponents.length;
                for (k in 0...numPlayerItemIds){
                    itemIdComponent = try cast(playerItemIdComponents[k], ItemIdComponent) catch(e:Dynamic) null;
                    if (itemIdComponent.itemId == itemId) 
                    {
                        numItemIdsInTypeEarned++;
                        itemIdsEarned.push(itemIdComponent.entityId);
                        break;
                    }
                }
            }  // Caching instance id directly in the map  
            
            
            
            collectionCategory.itemInstanceIds = itemIdsEarned;
            collectionCategory.numItemsEarned = numItemIdsInTypeEarned;
            
            Reflect.setField(m_categoryIdToCollectionObjectMap, categoryId, collectionCategory);
            categoryIdList.push(categoryId);
        }
        
        m_activeCategoryPageIndex = 0;
        m_activeItemPageIndex = 0;
        
        // Segment all collection categories into pages
        ListUtil.subdivideList(categoryIdList, 5, m_collectionCategoriesPages);
        
        changeToCategoryView();
    }
    
    override public function hide() : Void
    {
        super.hide();
        
        m_backButton.removeFromParent();
        
        // Dispose of all currently visible pieces
        clearCategoryItemsView(true);
        clearCategoryView();
        clearItemView();
        as3hx.Compat.setArrayLength(m_collectionCategoriesPages, 0);
        
        m_currentViewLevel = -1;
    }
    
    /**
     * Draw a set of buttons, each representing a item category type on a specific page
     */
    private function drawCategoryButtonsForPage(pageIndex : Int) : Void
    {
        var buttonWidth : Float = 400;
        var buttonHeight : Float = 70;
        var categoriesForPage : Array<String> = m_collectionCategoriesPages[pageIndex];
        var i : Int;
        var numCategoriesForPage : Int = categoriesForPage.length;
        for (i in 0...numCategoriesForPage){
            var categoryId : String = categoriesForPage[i];
            
            // Get back important information about the category id
            var categoryInformationObject : Dynamic = Reflect.field(m_categoryIdToCollectionObjectMap, categoryId);
            
            var button : PlayerCollectionCategoryButton = new PlayerCollectionCategoryButton(
            categoryInformationObject, m_assetManager, buttonWidth, buttonHeight, m_buttonColorData.getUpButtonColor(), 
            );
            m_activeCategoryButtons.push(button);
        }  // Need to now layout the category buttons  
        
        
        
        var gap : Float = 12;
        var xOffset : Float = (800 - buttonWidth) * 0.5;
        var yOffset : Float = m_titleText.y + m_titleText.height;
        var numButtons : Int = m_activeCategoryButtons.length;
        for (i in 0...numButtons){
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
    private function drawCategoryItemButtonsForPage(categoryId : String, pageIndex : Int) : Void
    {
        if (m_collectionItemPages.length == 0) 
        {
            return;
        }
        
        var categoryItemsForPage : Array<String> = m_collectionItemPages[pageIndex];
        
        var categoryInformationObject : Dynamic = Reflect.field(m_categoryIdToCollectionObjectMap, categoryId);
        var allInstanceIds : Array<Dynamic> = categoryInformationObject.itemInstanceIds;
        var allItemIds : Array<Dynamic> = categoryInformationObject.itemIds;
        
        var typicalWidth : Float = categoryInformationObject.typicalWidth;
        var typicalHeight : Float = categoryInformationObject.typicalHeight;
        
        var i : Int;
        var numItemsForPage : Int = categoryItemsForPage.length;
        for (i in 0...numItemsForPage){
            var itemId : String = categoryItemsForPage[i];
            
            // We assume all item textures are single static pieces
            var textureComponent : TextureCollectionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                    itemId,
                    TextureCollectionComponent.TYPE_ID
                    ), TextureCollectionComponent) catch(e:Dynamic) null;
            
            // HACK: Flash resources need to be drawn then dumped into asset manager manually
            var textureDataObject : Dynamic = textureComponent.textureCollection[0];
            if (textureDataObject.type == "FlashMovieClip") 
            {
                var rigidBodyComponent : RigidBodyComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(itemId, RigidBodyComponent.TYPE_ID), RigidBodyComponent) catch(e:Dynamic) null;
                var textureFromFlash : Texture = FlashResourceUtil.getTextureFromFlashString(textureDataObject.flashId, textureDataObject.params, 1, rigidBodyComponent.boundingRectangle);
                m_assetManager.addTexture(textureDataObject.textureName, textureFromFlash);
            }
            var textureName : String = textureDataObject.textureName;
            
            // Render item differently if the item was earned by player or not (show lock if not)
            var earnedItem : Bool = Lambda.indexOf(allInstanceIds, itemId) >= 0;
            var button : PlayerCollectionItemButton = new PlayerCollectionItemButton(textureName, itemId, !earnedItem, m_assetManager, 
            typicalWidth, typicalHeight, 
            m_buttonColorData.getUpButtonColor(), 
            XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 0.3), 
            );
            m_activeItemButtons.push(button);
        }  // Need to now layout the category buttons  
        
        
        
        var columns : Int = categoryInformationObject.columnsPerPage;
        var rows : Int = categoryInformationObject.rowsPerPage;  // Fill in by column order  
        
        var spanningWidth : Float = 800;
        var spanningHeight : Float = 400;
        var calculatedHorizontalGap : Float = (spanningWidth - columns * typicalWidth) / (columns + 1);
        var calculatedVerticalGap : Float = (spanningHeight - rows * typicalHeight) / (rows + 1);
        
        var yOffset : Float = m_titleText.height;
        var numButtons : Int = m_activeItemButtons.length;
        for (i in 0...numButtons){
            var rowIndex : Int = i / columns;
            var columnIndex : Int = i % columns;
            button = m_activeItemButtons[i];
            button.x = columnIndex * typicalWidth + calculatedHorizontalGap * (columnIndex + 1);
            button.y = rowIndex * typicalHeight + calculatedVerticalGap * (rowIndex + 1) + yOffset;
            m_canvasContainer.addChild(button);
        }
        
        showPageIndicator(pageIndex + 1, m_collectionItemPages.length);
    }
    
    private function changeToCategoryView() : Void
    {
        m_currentViewLevel = PlayerCollectionItemViewer.VIEW_LEVEL_CATEGORIES;
        m_titleText.text = "Collectables";
        m_canvasContainer.addChild(m_titleText);
        
        // Draw a page of categories
        drawCategoryButtonsForPage(m_activeCategoryPageIndex);
        
        // Show scroll buttons if multiple pages
        super.showScrollButtons(m_collectionCategoriesPages.length > 1);
    }
    
    private function clearCategoryView() : Void
    {
        // Clear out the category buttons
        for (categoryButton in m_activeCategoryButtons)
        {
            categoryButton.removeFromParent(true);
        }
        as3hx.Compat.setArrayLength(m_activeCategoryButtons, 0);
    }
    
    private function changeToCategoryItemsView(categoryInformationObject : Dynamic) : Void
    {
        m_currentViewLevel = PlayerCollectionItemViewer.VIEW_LEVEL_ITEMS_IN_CATEGORY;
        
        // Subdivide the list of items belonging to the selected category
        // It requires a vector so push the ids into a temp list
        if (categoryInformationObject != null) 
        {
            // Set title to name of category
            m_titleText.text = categoryInformationObject.id;
            
            var itemsPerPage : Int = categoryInformationObject.columnsPerPage * categoryInformationObject.rowsPerPage;
            var itemIdsInCategory : Array<String> = new Array<String>();
            for (itemId/* AS3HX WARNING could not determine type for var: itemId exp: EField(EIdent(categoryInformationObject),itemIds) type: null */ in categoryInformationObject.itemIds)
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
            for (itemButton in m_activeItemButtons)
            {
                m_canvasContainer.addChild(itemButton);
            }
        }  // Show scroll buttons if multiple pages  
        
        
        
        super.showScrollButtons(m_collectionItemPages.length > 1);
    }
    
    private function clearCategoryItemsView(disposeCurrentPage : Bool) : Void
    {
        if (disposeCurrentPage) 
        {
            // Discard all data related to the items for a particular category
            // (DISPOSE button to release textures if necessary)
            for (itemButton in m_activeItemButtons)
            {
                itemButton.removeFromParent(true);
            }
            as3hx.Compat.setArrayLength(m_activeItemButtons, 0);
            as3hx.Compat.setArrayLength(m_collectionItemPages, 0);
            
            // undo button is no longer needed
            m_backButton.removeFromParent();
        }
        else 
        {
            // Remove item buttons from the screen for now
            for (itemButton in m_activeItemButtons)
            {
                itemButton.removeFromParent();
            }
        }
    }
    
    private function changeToItemView(itemId : String) : Void
    {
        m_currentViewLevel = PlayerCollectionItemViewer.VIEW_LEVEL_SINGLE_ITEM;
        
        // Get all important description components for this item
        var nameComponent : NameComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(itemId, NameComponent.TYPE_ID), NameComponent) catch(e:Dynamic) null;
        var textureComponent : TextureCollectionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(itemId, TextureCollectionComponent.TYPE_ID), TextureCollectionComponent) catch(e:Dynamic) null;
        var descriptionComponent : DescriptionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(itemId, DescriptionComponent.TYPE_ID), DescriptionComponent) catch(e:Dynamic) null;
        
        // HACK: For flash movie clips we need to create the texture AND then insert it into the asset manager
        // Assuming the item texture was drawn in the category screen
        var textureDataObject : Dynamic = textureComponent.textureCollection[0];
        m_activeItemScreen = new PlayerCollectionItemScreen(
                textureDataObject.textureName, 
                nameComponent.name, 
                ((descriptionComponent != null)) ? descriptionComponent.desc : "", 
                600, 
                400, 
                m_assetManager, 
                );
        m_activeItemScreen.x = 100;
        m_activeItemScreen.y = m_titleText.y + m_titleText.height + 10;
        m_canvasContainer.addChild(m_activeItemScreen);
        
        // Make sure scroll arrows hidden
        m_scrollLeftButton.removeFromParent();
        m_scrollRightButton.removeFromParent();
    }
    
    private function clearItemView() : Void
    {
        // Remove the item description screen
        if (m_activeItemScreen != null) 
        {
            m_activeItemScreen.removeFromParent(true);
            m_activeItemScreen = null;
        }
    }
}
