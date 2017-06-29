package wordproblem.achievements;

import wordproblem.achievements.PlayerAchievementGem;

import flash.geom.Rectangle;
import flash.text.TextFormat;

import feathers.display.Scale9Image;
import feathers.textures.Scale9Textures;

import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.text.MeasuringTextField;
import wordproblem.resource.AssetManager;

/**
 * A simple achievement container holder a main gem and showing various text descriptors
 * about the achievement
 */
class PlayerAchievementButton extends Sprite
{
    /**
     * Styling for the title of the achievement in the summary screen
     */
    public static var m_titleTextFormat : TextFormat = new TextFormat("Verdana", 28, 0x0, true);
    
    /**
     * Styling for the small description under the title
     */
    public static var m_descriptionTextFormat : TextFormat = new TextFormat("Verdana", 18, 0x0);
    
    public function new(achievementData : Dynamic,
            width : Float,
            height : Float,
            assetManager : AssetManager)
    {
        super();
        
        var scale9Padding : Float = 8;
        var bgTexture : Texture = assetManager.getTexture("button_white");
        var bgImage : Scale9Image = new Scale9Image(new Scale9Textures(bgTexture, new Rectangle(scale9Padding, scale9Padding, bgTexture.width - scale9Padding * 2, bgTexture.height - scale9Padding * 2)));
        bgImage.width = width;
        bgImage.height = height;
        addChild(bgImage);
        
        var achievementCompleted : Bool = achievementData.isComplete;
        var achievementColor : String = achievementData.color;
        var trophyName : String = achievementData.trophyName;
        
        bgImage.color = ((achievementCompleted)) ? 
                PlayerAchievementData.getDarkHexColorFromString(achievementData.color) : 0xB3B4B4;
        
        // The gem needs to be scaled such that it barely fits in side the background
        var achievementGem : PlayerAchievementGem = new PlayerAchievementGem(achievementColor, trophyName, achievementCompleted, assetManager);
        var verticalScaleAmount : Float = height / achievementGem.height;
        achievementGem.scaleX = achievementGem.scaleY = verticalScaleAmount;
        addChild(achievementGem);
        
        // Gems might be of different sizes, we want the center of the gem to be at a fixed value
        // on the button. This ensures the gems look like they line up vertically
        var desiredX : Float = width * 0.1;
        var achievementGemCenterX : Float = achievementGem.width * 0.5;
        var achievementGemCenterY : Float = achievementGem.height * 0.5;
        achievementGem.x += (desiredX - achievementGemCenterX);
        
        // If not completed we want to show a lock on the front of the gem
        if (!achievementCompleted) 
        {
            var lockTexture : Texture = assetManager.getTexture("Art_LockGrey");
            var lockScaleFactor : Float = (height * 0.4) / lockTexture.height;
            var lockImage : Image = new Image(lockTexture);
            lockImage.scaleX = lockImage.scaleY = lockScaleFactor;
            
            // Offset for the lock depends on the gem color
            var additionalYOffset : Float = 0;
            if (achievementColor == "Blue" || achievementColor == "Orange") 
            {
                additionalYOffset = -height * 0.1;
            }
            
            lockImage.x = (achievementGem.width - lockImage.width) * 0.5 + achievementGem.x;
            lockImage.y = (achievementGem.height - lockImage.height) * 0.5 + additionalYOffset;
            addChild(lockImage);
        }
        
        var textColor : Int = ((achievementCompleted)) ? 
        PlayerAchievementData.getLightHexColorFromString(achievementData.color) : 0x666666;
        var measuringText : MeasuringTextField = new MeasuringTextField();
        measuringText.defaultTextFormat = m_titleTextFormat;
        measuringText.text = achievementData.name;
        var newFontSize : Int = measuringText.resizeToDimensions(width - achievementGem.width - 20, height * 0.5, achievementData.name);
        
        var titleText : TextField = new TextField(
        width - achievementGem.width, 
        measuringText.textHeight + 10, 
        achievementData.name, 
        m_titleTextFormat.font, newFontSize, textColor);
        titleText.x = achievementGem.width;
        addChild(titleText);
        
        measuringText.defaultTextFormat = m_descriptionTextFormat;
        measuringText.text = achievementData.description;
        var descriptionText : TextField = new TextField(
        width - achievementGem.width, measuringText.textHeight + 5, 
        achievementData.description, 
        m_descriptionTextFormat.font, Std.parseInt(m_descriptionTextFormat.size), textColor);
        descriptionText.x = titleText.x;
        descriptionText.y = titleText.y + titleText.height;
        addChild(descriptionText);
    }
}
