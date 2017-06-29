package wordproblem.summary;


import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

class NewStarScreen extends Sprite
{
    public function new(totalScreenWidth : Float, totalScreenHeight : Float, assetManager : AssetManager)
    {
        super();
        
        var starText : TextField = new TextField(400, 60, "Finished New Level!", GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
        starText.x = (totalScreenWidth - starText.width) * 0.5;
        starText.y = totalScreenHeight * 0.15;
        addChild(starText);
        
        var starTexture : Texture = assetManager.getTexture("level_button_star");
        var starImage : Image = new Image(starTexture);
        starImage.pivotX = starTexture.width * 0.5;
        starImage.pivotY = starTexture.height * 0.5;
        
        var desiredWidth : Float = 200;
        var targetScale : Float = desiredWidth / starTexture.width;
        starImage.scaleX = starImage.scaleY = targetScale;
        starImage.x = totalScreenWidth * 0.5;
        starImage.y = totalScreenHeight * 0.5;
        addChild(starImage);
        
        // Have star slowly rotate back and forth
        var rotateDuration : Float = 20;
        var starRotateTween : Tween = new Tween(starImage, rotateDuration);
        starRotateTween.animate("rotation", Math.PI * 2);
        starRotateTween.reverse = false;
        starRotateTween.repeatCount = 0;
        Starling.juggler.add(starRotateTween);
    }
}
