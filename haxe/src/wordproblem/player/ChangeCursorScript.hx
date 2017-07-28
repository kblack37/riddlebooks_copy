package wordproblem.player;


import flash.display.BitmapData;
import flash.geom.Point;
import flash.ui.Mouse;

import wordproblem.engine.component.Component;
import wordproblem.engine.component.EquippableComponent;
import wordproblem.engine.component.TextureCollectionComponent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseBufferEventScript;

/**
 * Script related to the logic of the player equipping different mouse
 * cursor images.
 * 
 * (Note: Cursor name are all tied to the item id number)
 */
class ChangeCursorScript extends BaseBufferEventScript
{
    private var m_assetManager : AssetManager;
    private var m_playerItemInventory : ItemInventory;
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * Map of all the names that have already been registered with the flash api.
     * This is here to prevent unnecessary re-registration of the cursor data.
     */
    private var m_registeredCursorNames : Dynamic;
    
    public function new(assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        m_assetManager = assetManager;
        m_registeredCursorNames = { };
        
        // The default custom cursor should be present regardless of whether the player
        // has logged into the system.
        registerNewCursor("custom_cursor");
        
        // This is ugly but it would require two separate initialization sequences.
        // The constructor sets up the default.
        // After login occurs we can then setup the custom cursors
        
        // Always start with the custom cursor, changes later after player authentication
        Mouse.cursor = "custom_cursor";
    }
    
    /**
     * HACK:
     * After login, need to reset the cursor to new one used by the player.
     * 
     */
    public function initialize(playerItemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            startingCursorName : String = null) : Void
    {
        // TODO: The equipped cursor is part of the player's save data need to read it from here
        // Need some equip mouse cursor logic (this thing exexutes in the collection screen if the user changes cursors there)
        // Pass alias of registered cursor to have it show up
        m_playerItemInventory = playerItemInventory;
        m_itemDataSource = itemDataSource;
        changeToCursor(startingCursorName);
    }
    
    /**
     * Look at the cursor saved in the user properties and modify the item component to match it
     */
    public function changeToCursor(cursorNameToChangeTo : String = null) : Void
    {
        // HACK: Pre-bake the known default item
        if (cursorNameToChangeTo == null) 
        {
            cursorNameToChangeTo = "136";
        }  // Those not matching should be set to unequipped    // Iterate through all the mouse cursor objects possessed by the player  
        
        
        
        
        
        var equippableObjectsOwned : Array<Component> = m_playerItemInventory.componentManager.getComponentListForType(EquippableComponent.TYPE_ID);
        var i : Int;
        var numEquippablesOwned : Int = equippableObjectsOwned.length;
        for (i in 0...numEquippablesOwned){
            var equippableComponent : EquippableComponent = try cast(equippableObjectsOwned[i], EquippableComponent) catch(e:Dynamic) null;
            if (equippableComponent.equippableType == EquippableComponent.MOUSE) 
            {
                equippableComponent.isEquipped = equippableComponent.entityId == cursorNameToChangeTo;
            }
        }  // After the components are changed, tell the flash api to change to the new cursor  
        
        
        
        if (!m_registeredCursorNames.exists(cursorNameToChangeTo)) 
        {
            // Assume cursor names (other than the default) are ids, in which case we will need
            // to peer into the item db to get what the texture bitmap is
            var textureComponent : TextureCollectionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                    cursorNameToChangeTo, TextureCollectionComponent.TYPE_ID), TextureCollectionComponent) catch(e:Dynamic) null;
            var textureName : String = textureComponent.textureCollection[0].textureName;
            registerNewCursor(cursorNameToChangeTo, textureName);
        }
        
        Mouse.cursor = cursorNameToChangeTo;
    }
    
    
    private function registerNewCursor(registrationName : String, assetName : String = null) : Void
    {
        if (assetName == null) 
        {
            assetName = registrationName;
        }
        
		// TODO: is this function necessary with the way openFL handles custom cursors?
        //var customCursor : BitmapData = m_assetManager.getBitmapData(assetName);
        //var cursorData : MouseCursorData = new MouseCursorData();
        //cursorData.hotSpot = new Point();
        //cursorData.data = [customCursor];
        //Mouse.registerCursor(registrationName, cursorData);
        
        Reflect.setField(m_registeredCursorNames, registrationName, true);
    }
}
