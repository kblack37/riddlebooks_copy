package wordproblem.player;


import wordproblem.engine.component.Component;
import wordproblem.engine.component.EquippableComponent;
import wordproblem.engine.component.TextureCollectionComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;

/**
 * This should be the only script that modifies the value of the color data
 */
class ChangeButtonColorScript extends ScriptNode
{
    private var m_buttonColorData : ButtonColorData;
    
    private var m_playerItemInventory : ItemInventory;
    private var m_itemDataSource : ItemDataSource;
    
    public function new(buttonColorData : ButtonColorData,
            playerItemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_buttonColorData = buttonColorData;
        m_playerItemInventory = playerItemInventory;
        m_itemDataSource = itemDataSource;
        
        // Set to the default button color
        changeToButtonColor(null);
    }
    
    public function changeToButtonColor(buttonColorName : String) : Void
    {
        // Change to default if not specified
        if (buttonColorName == null) 
        {
            buttonColorName = "144";
        }
        
        var texturesComponent : TextureCollectionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                buttonColorName, TextureCollectionComponent.TYPE_ID), TextureCollectionComponent) catch(e:Dynamic) null;
        if (texturesComponent != null) 
        {
            m_buttonColorData.setActiveUpColor(Std.parseInt(texturesComponent.textureCollection[0].color));
        }
		
		// Those not matching should be set to unequipped
		// Iterate through all the mouse cursor objects possessed by the player  
        var equippableObjectsOwned : Array<Component> = m_playerItemInventory.componentManager.getComponentListForType(EquippableComponent.TYPE_ID);
        var i : Int = 0;
        var numEquippablesOwned : Int = equippableObjectsOwned.length;
        for (i in 0...numEquippablesOwned){
            var equippableComponent : EquippableComponent = try cast(equippableObjectsOwned[i], EquippableComponent) catch(e:Dynamic) null;
            if (equippableComponent.equippableType == EquippableComponent.BUTTON_COLOR) 
            {
                equippableComponent.isEquipped = equippableComponent.entityId == buttonColorName;
            }
        }
    }
}
