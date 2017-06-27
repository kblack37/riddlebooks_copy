package wordproblem.summary
{
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.engine.component.RewardIconComponent;
    import wordproblem.items.ItemDataSource;
    import wordproblem.resource.AssetManager;

    public class NewItemButton extends BaseRewardButton
    {
        public static var presentColors:Array = ["blue", "pink", "purple", "yellow"];
        
        public static function getRandomPresentColor():String
        {
            var presentColor:String = presentColors[Math.floor(Math.random() * presentColors.length)];
            return presentColor;
        }
        
        public static function createPresentContainer(presentColor:String, assetManager:AssetManager):Sprite
        {
            var presentContainer:Sprite = new Sprite();
            var presentBottom:Image = new Image(assetManager.getTexture("present_bottom_" + presentColor));
            presentContainer.addChild(presentBottom);
            var presentTop:Image = new Image(assetManager.getTexture("present_top_" + presentColor));
            presentContainer.addChild(presentTop);
            
            presentBottom.y = presentTop.height * 0.35;
            presentBottom.x = 6;
            
            return presentContainer;
        }
        
        private var m_itemDataSource:ItemDataSource;
        
        public function NewItemButton(maxEdgeLength:Number, rewardData:Object, itemDataSource:ItemDataSource, assetManager:AssetManager)
        {
            super(maxEdgeLength, rewardData, assetManager);
            
            m_itemDataSource = itemDataSource;
            
            // Generate a random present color if the item is hidden
            var itemId:String = rewardData.id;
            var mainDisplayObject:DisplayObject;
            if (rewardData.hidden)
            {
                if (!rewardData.hasOwnProperty("presentColor"))
                {
                    rewardData.presentColor = NewItemButton.getRandomPresentColor();
                }
                
                var presentContainer:DisplayObject = NewItemButton.createPresentContainer(rewardData.presentColor, m_assetManager);
                mainDisplayObject = presentContainer;
            }
            else
            {
                // Draw the item directly
                var rewardIconComponent:RewardIconComponent = itemDataSource.getComponentFromEntityIdAndType(
                    itemId, 
                    RewardIconComponent.TYPE_ID
                ) as RewardIconComponent;
                var rewardIconTexture:Texture = assetManager.getTextureWithReferenceCount(rewardIconComponent.textureName);
                mainDisplayObject = new Image(rewardIconTexture);
            }
            
            var scaleFactor:Number = Math.min(maxEdgeLength * 0.75 / mainDisplayObject.width, maxEdgeLength * 0.75 / mainDisplayObject.height);
            mainDisplayObject.scaleX = mainDisplayObject.scaleY = scaleFactor;
            mainDisplayObject.x = (m_backgroundGlowImage.width - mainDisplayObject.width) * 0.5;
            mainDisplayObject.y = (m_backgroundGlowImage.height - mainDisplayObject.height) * 0.5;
            addChild(mainDisplayObject);
        }
        
        override public function getRewardDetailsScreen():Sprite
        {
            return new NewItemScreen(800, 600, this.data, m_itemDataSource, m_assetManager);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_assetManager.releaseTextureWithReferenceCount(this.data.textureName);
        }
    }
}