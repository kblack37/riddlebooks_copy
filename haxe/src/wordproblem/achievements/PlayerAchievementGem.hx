package wordproblem.achievements;


import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.resource.AssetManager;

/**
 * This is the display object representing the main gem graphic for an achievement
 */
class PlayerAchievementGem extends Sprite
{
    private var m_filledImage : Image;
    private var m_emptyImage : Image;
    private var m_centerImage : Image;
    private var m_trophyImage : Image;
    
    private var m_gemContainer : Sprite;
    
    public function new(colorName : String,
            trophyName : String,
            isFilledInitially : Bool,
            assetManager : AssetManager)
    {
        super();
        
        m_gemContainer = new Sprite();
        
        // Since we want to perform scaling operation on several of the pieces,
        // we need to readjust the pivot of these items
        var filledImage : Image = getCenteredImage(colorName, "Filled", assetManager);
        var fillXOffset : Float = 0;
        var fillYOffset : Float = 0;
        if (colorName == "Blue") 
        {
            fillYOffset = -1.5;
        }
        else if (colorName == "Green") 
        {
            fillYOffset = -0.5;
            fillXOffset = 1;
        }
        filledImage.y = fillYOffset;
        filledImage.x = fillXOffset;
        m_filledImage = filledImage;
        var emptyImage : Image = getCenteredImage(colorName, "Blank", assetManager);
        m_emptyImage = emptyImage;
        var centerImage : Image = getCenteredImage(colorName, "Center", assetManager);
        m_centerImage = centerImage;
        
        // The orientation of each of these textures depends on the color type
        m_gemContainer.x = emptyImage.width * 0.5;
        m_gemContainer.y = emptyImage.height * 0.5;
        m_gemContainer.addChild(emptyImage);
        m_gemContainer.addChild(centerImage);
        addChild(m_gemContainer);
        
        var trophyTexture : Texture = assetManager.getTexture(trophyName);
        m_trophyImage = new Image(trophyTexture);
        m_trophyImage.scaleX = m_trophyImage.scaleY = 0.7;
        m_trophyImage.pivotX = trophyTexture.width * 0.5;
        m_trophyImage.pivotY = trophyTexture.height * 0.5;
        
        if (isFilledInitially) 
        {
            m_gemContainer.addChild(filledImage);
            m_gemContainer.addChild(m_trophyImage);
        }
    }
    
    /**
     * This is an animation where the filled in part of the gem pops in. Useful for achievement unlocked animation.
     */
    public function startFillAnimation(duration : Float, onComplete : Function) : Void
    {
        // Animation where the center shrinks to nothing and the filled image pops in fully
        var centerShrink : Tween = new Tween(m_centerImage, duration * 0.5);
        centerShrink.scaleTo(0);
        centerShrink.onComplete = function() : Void
                {
                    m_filledImage.scaleX = m_filledImage.scaleY = 0.0;
                    m_gemContainer.addChild(m_filledImage);
                    m_gemContainer.removeChild(m_centerImage);
                    var expandDuration : Float = duration * 0.5;
                    var fillExpand : Tween = new Tween(m_filledImage, expandDuration, Transitions.EASE_OUT_BOUNCE);
                    fillExpand.scaleTo(1);
                    Starling.juggler.add(fillExpand);
                    
                    m_trophyImage.scaleX = m_trophyImage.scaleY = 0.0;
                    m_gemContainer.addChild(m_trophyImage);
                    var trophyExpand : Tween = new Tween(m_trophyImage, expandDuration, Transitions.EASE_OUT_BOUNCE);
                    trophyExpand.scaleTo(1);
                    trophyExpand.onComplete = onComplete;
                    Starling.juggler.add(trophyExpand);
                };
        Starling.juggler.add(centerShrink);
    }
    
    private function getCenteredImage(colorName : String, suffix : String, assetManager : AssetManager) : Image
    {
        var texture : Texture = assetManager.getTexture("Art_Gem" + colorName + suffix);
        var image : Image = new Image(texture);
        image.pivotX = texture.width * 0.5;
        image.pivotY = texture.height * 0.5;
        return image;
    }
}
