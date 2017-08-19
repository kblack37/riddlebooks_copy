package wordproblem.achievements;

import haxe.Constraints.Function;

import motion.Actuate;

import motion.easing.Bounce;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

import wordproblem.display.PivotSprite;
import wordproblem.resource.AssetManager;



/**
 * This is the display object representing the main gem graphic for an achievement
 */
class PlayerAchievementGem extends PivotSprite
{
    private var m_filledImage : PivotSprite;
    private var m_emptyImage : PivotSprite;
    private var m_centerImage : PivotSprite;
    private var m_trophyImage : PivotSprite;
    
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
        var filledImage : PivotSprite = getCenteredImage(colorName, "Filled", assetManager);
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
        var emptyImage : PivotSprite = getCenteredImage(colorName, "Blank", assetManager);
        m_emptyImage = emptyImage;
        var centerImage : PivotSprite = getCenteredImage(colorName, "Center", assetManager);
        m_centerImage = centerImage;
        
        // The orientation of each of these textures depends on the color type
        m_gemContainer.x = emptyImage.width * 0.5;
        m_gemContainer.y = emptyImage.height * 0.5;
        m_gemContainer.addChild(emptyImage);
        m_gemContainer.addChild(centerImage);
        addChild(m_gemContainer);
        
        var trophyBitmapData : BitmapData = assetManager.getBitmapData(trophyName);
        m_trophyImage = new PivotSprite();
		m_trophyImage.addChild(new Bitmap(trophyBitmapData));
        m_trophyImage.scaleX = m_trophyImage.scaleY = 0.7;
        m_trophyImage.pivotX = trophyBitmapData.width * 0.5;
        m_trophyImage.pivotY = trophyBitmapData.height * 0.5;
        
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
		Actuate.tween(m_centerImage, duration * 0.5, { scaleX: 0, scaleY: 0 }).onComplete(function() : Void
                {
                    m_filledImage.scaleX = m_filledImage.scaleY = 0.0;
                    m_gemContainer.addChild(m_filledImage);
                    m_gemContainer.removeChild(m_centerImage);
                    var expandDuration : Float = duration * 0.5;
					Actuate.tween(m_filledImage, expandDuration, { scaleX: 1, scaleY: 1 }).ease(Bounce.easeOut);
                    
                    m_trophyImage.scaleX = m_trophyImage.scaleY = 0.0;
                    m_gemContainer.addChild(m_trophyImage);
					Actuate.tween(m_trophyImage, expandDuration, { scaleX: 1, scaleY: 1}).ease(Bounce.easeOut).onComplete(onComplete);
                });
    }
    
    private function getCenteredImage(colorName : String, suffix : String, assetManager : AssetManager) : PivotSprite
    {
        var bitmapData : BitmapData = assetManager.getBitmapData("Art_Gem" + colorName + suffix);
        var image : PivotSprite = new PivotSprite();
		image.addChild(new Bitmap(bitmapData));
        image.pivotX = bitmapData.width * 0.5;
        image.pivotY = bitmapData.height * 0.5;
        return image;
    }
}
