package wordproblem.achievements;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import wordproblem.achievements.PlayerAchievementGem;
import wordproblem.display.DisposableSprite;
import wordproblem.display.Scale9Image;

import openfl.geom.Rectangle;
import openfl.text.TextFormat;

import openfl.display.Sprite;
import openfl.text.TextField;

import wordproblem.engine.text.MeasuringTextField;
import wordproblem.resource.AssetManager;

/**
 * A simple achievement container holder a main gem and showing various text descriptors
 * about the achievement
 */
class PlayerAchievementButton extends DisposableSprite
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
        var bgBitmapData : BitmapData = assetManager.getBitmapData("button_white");
        var bgImage : Scale9Image = new Scale9Image(bgBitmapData, new Rectangle(scale9Padding,
				scale9Padding,
				bgBitmapData.width - scale9Padding * 2,
				bgBitmapData.height - scale9Padding * 2));
        bgImage.width = width;
        bgImage.height = height;
        addChild(bgImage);
        
        var achievementCompleted : Bool = achievementData.isComplete;
        var achievementColor : String = achievementData.color;
        var trophyName : String = achievementData.trophyName;
        
        bgImage.transform.colorTransform.concat(XColor.rgbToColorTransform(achievementCompleted ? 
                PlayerAchievementData.getDarkHexColorFromString(achievementData.color) : 0xB3B4B4));
        
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
            var lockBitmapData : BitmapData = assetManager.getBitmapData("Art_LockGrey");
            var lockScaleFactor : Float = (height * 0.4) / lockBitmapData.height;
            var lockImage : Bitmap = new Bitmap(lockBitmapData);
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
        var newFontSize : Int = Std.int(measuringText.resizeToDimensions(width - achievementGem.width - 20, height * 0.5, achievementData.name));
        
        var titleText : TextField = new TextField();
		titleText.width = width - achievementGem.width;
		titleText.height = measuringText.textHeight + 10; 
		titleText.text = achievementData.name;
		titleText.setTextFormat(new TextFormat(m_titleTextFormat.font, newFontSize, textColor));
        titleText.x = achievementGem.width;
        addChild(titleText);
        
        measuringText.defaultTextFormat = m_descriptionTextFormat;
        measuringText.text = achievementData.description;
        var descriptionText : TextField = new TextField();
		descriptionText.width = width - achievementGem.width;
		descriptionText.height = measuringText.textHeight + 5; 
		descriptionText.text = achievementData.description; 
		descriptionText.setTextFormat(new TextFormat(m_descriptionTextFormat.font, m_descriptionTextFormat.size, textColor));
        descriptionText.x = titleText.x;
        descriptionText.y = titleText.y + titleText.height;
        addChild(descriptionText);
    }
}
