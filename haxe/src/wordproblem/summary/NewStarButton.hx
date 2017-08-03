package wordproblem.summary;

import wordproblem.summary.NewStarScreen;

import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.resource.AssetManager;

class NewStarButton extends BaseRewardButton
{
    public function new(maxEdgeLength : Float, rewardData : Dynamic, assetManager : AssetManager)
    {
        super(maxEdgeLength, rewardData, assetManager);
        
        var starTexture : Texture = assetManager.getTexture("level_button_star.png");
        var starImageContainer : Sprite = new Sprite();
        
        var starImage : Image = new Image(starTexture);
        starImage.x = (m_backgroundGlowImage.width - starTexture.width) * 0.5;
        starImage.y = (m_backgroundGlowImage.height - starTexture.height) * 0.5;
        starImageContainer.addChild(starImage);
        
        addChild(starImageContainer);
    }
    
    override public function getRewardDetailsScreen() : Sprite
    {
        return new NewStarScreen(800, 600, m_assetManager);
    }
}
