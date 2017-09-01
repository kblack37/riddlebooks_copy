package wordproblem.summary;

import wordproblem.summary.NewItemScreen;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.engine.component.RewardIconComponent;
import wordproblem.items.ItemDataSource;
import wordproblem.resource.AssetManager;

class NewItemButton extends BaseRewardButton
{
    public static var presentColors : Array<Dynamic> = ["blue", "pink", "purple", "yellow"];
    
    public static function getRandomPresentColor() : String
    {
        var presentColor : String = presentColors[Math.floor(Math.random() * presentColors.length)];
        return presentColor;
    }
    
    public static function createPresentContainer(presentColor : String, assetManager : AssetManager) : Sprite
    {
        var presentContainer : Sprite = new Sprite();
        var presentBottom : Image = new Image(assetManager.getTexture("present_bottom_" + presentColor));
        presentContainer.addChild(presentBottom);
        var presentTop : Image = new Image(assetManager.getTexture("present_top_" + presentColor));
        presentContainer.addChild(presentTop);
        
        presentBottom.y = presentTop.height * 0.35;
        presentBottom.x = 6;
        
        return presentContainer;
    }
    
    private var m_itemDataSource : ItemDataSource;
    
    public function new(maxEdgeLength : Float, rewardData : Dynamic, itemDataSource : ItemDataSource, assetManager : AssetManager)
    {
        super(maxEdgeLength, rewardData, assetManager);
        
        m_itemDataSource = itemDataSource;
        
        // Generate a random present color if the item is hidden
        var itemId : String = rewardData.id;
        var mainDisplayObject : DisplayObject = null;
        if (rewardData.hidden) 
        {
            if (!rewardData.exists("presentColor")) 
            {
                rewardData.presentColor = NewItemButton.getRandomPresentColor();
            }
            
            var presentContainer : DisplayObject = NewItemButton.createPresentContainer(rewardData.presentColor, m_assetManager);
            mainDisplayObject = presentContainer;
        }
        else 
        {
            // Draw the item directly
            var rewardIconComponent : RewardIconComponent = try cast(itemDataSource.getComponentFromEntityIdAndType(
                    itemId,
                    RewardIconComponent.TYPE_ID
                    ), RewardIconComponent) catch(e:Dynamic) null;
            var rewardIconTexture : Texture = assetManager.getBitmapDataWithReferenceCount(rewardIconComponent.textureName);
            mainDisplayObject = new Image(rewardIconTexture);
        }
        
        var scaleFactor : Float = Math.min(maxEdgeLength * 0.75 / mainDisplayObject.width, maxEdgeLength * 0.75 / mainDisplayObject.height);
        mainDisplayObject.scaleX = mainDisplayObject.scaleY = scaleFactor;
        mainDisplayObject.x = (m_backgroundGlowImage.width - mainDisplayObject.width) * 0.5;
        mainDisplayObject.y = (m_backgroundGlowImage.height - mainDisplayObject.height) * 0.5;
        addChild(mainDisplayObject);
    }
    
    override public function getRewardDetailsScreen() : Sprite
    {
        return new NewItemScreen(800, 600, this.data, m_itemDataSource, m_assetManager);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_assetManager.releaseBitmapDataWithReferenceCount(this.data.textureName);
    }
}
