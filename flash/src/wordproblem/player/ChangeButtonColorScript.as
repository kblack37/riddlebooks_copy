package wordproblem.player
{
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.EquippableComponent;
    import wordproblem.engine.component.TextureCollectionComponent;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.items.ItemDataSource;
    import wordproblem.items.ItemInventory;
    
    /**
     * This should be the only script that modifies the value of the color data
     */
    public class ChangeButtonColorScript extends ScriptNode
    {
        private var m_buttonColorData:ButtonColorData;
        
        private var m_playerItemInventory:ItemInventory;
        private var m_itemDataSource:ItemDataSource;
        
        public function ChangeButtonColorScript(buttonColorData:ButtonColorData,
                                                playerItemInventory:ItemInventory, 
                                                itemDataSource:ItemDataSource, 
                                                id:String=null, 
                                                isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_buttonColorData = buttonColorData;
            m_playerItemInventory = playerItemInventory;
            m_itemDataSource = itemDataSource;
            
            // Set to the default button color
            changeToButtonColor(null);
        }
        
        public function changeToButtonColor(buttonColorName:String):void
        {
            // Change to default if not specified
            if (buttonColorName == null)
            {
                buttonColorName = "144";
            }
            
            var texturesComponent:TextureCollectionComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                buttonColorName, TextureCollectionComponent.TYPE_ID) as TextureCollectionComponent;
            if (texturesComponent != null)
            {
                m_buttonColorData.setActiveUpColor(parseInt(texturesComponent.textureCollection[0].color, 16));
            }
            
            // Iterate through all the mouse cursor objects possessed by the player
            // Those not matching should be set to unequipped
            var equippableObjectsOwned:Vector.<Component> = m_playerItemInventory.componentManager.getComponentListForType(EquippableComponent.TYPE_ID);
            var i:int;
            var numEquippablesOwned:int = equippableObjectsOwned.length;
            for (i = 0; i < numEquippablesOwned; i++)
            {
                var equippableComponent:EquippableComponent = equippableObjectsOwned[i] as EquippableComponent;
                if (equippableComponent.equippableType == EquippableComponent.BUTTON_COLOR)
                {
                    equippableComponent.isEquipped = equippableComponent.entityId == buttonColorName;
                }
            }
        }
    }
}