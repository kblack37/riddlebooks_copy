package wordproblem.summary
{
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.engine.component.TextureCollectionComponent;
    import wordproblem.items.ItemDataSource;
    import wordproblem.resource.AssetManager;
    
    public class ChangedItemButton extends BaseRewardButton
    {
        private var m_itemDataSource:ItemDataSource;
        
        public function ChangedItemButton(maxEdgeLength:Number, 
                                          rewardData:Object, 
                                          itemDataSource:ItemDataSource,
                                          assetManager:AssetManager)
        {
            super(maxEdgeLength, rewardData, assetManager);
            
            m_itemDataSource = itemDataSource;
            
            var itemId:String = rewardData.id;
            var textureCollectionComponent:TextureCollectionComponent = itemDataSource.getComponentFromEntityIdAndType(
                itemId, 
                TextureCollectionComponent.TYPE_ID
            ) as TextureCollectionComponent;
            var itemTexture:Texture = null;
            if (rewardData.hidden)
            {
                // If hidden should draw the item in its olds state
                var previousStageIndex:int = rewardData.prevStage;
                var previousTextureName:String =  textureCollectionComponent.textureCollection[previousStageIndex].textureName;
                itemTexture = assetManager.getTexture(previousTextureName);
            }
            else
            {
                // If player has already seen the item, draw it in its new state
                var currentStageIndex:int = rewardData.currentStage;
                var currentTextureName:String = textureCollectionComponent.textureCollection[currentStageIndex].textureName;
                itemTexture = assetManager.getTexture(currentTextureName);
            }
            
            var changedItemIcon:DisplayObject = new Image(itemTexture);
            var scaleToChange:Number = maxEdgeLength / changedItemIcon.height * 0.75;
            changedItemIcon.scaleX = changedItemIcon.scaleY = scaleToChange;
            changedItemIcon.x = (maxEdgeLength - changedItemIcon.width) * 0.5;
            changedItemIcon.y = (maxEdgeLength - changedItemIcon.height) * 0.5;
            addChild(changedItemIcon);
        }
        
        override public function getRewardDetailsScreen():Sprite
        {
            return new ChangedItemScreen(800, 600, this.data, m_itemDataSource, m_assetManager);
        }
    }
}