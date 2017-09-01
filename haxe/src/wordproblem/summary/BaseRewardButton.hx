package wordproblem.summary;


import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import wordproblem.display.DisposableSprite;
import wordproblem.display.PivotSprite;

import wordproblem.resource.AssetManager;

/**
 * Base display representing a single reward shown on the summary screen
 */
class BaseRewardButton extends DisposableSprite
{
    public var data : Dynamic;
    
    private var m_assetManager : AssetManager;
    
    private var m_backgroundGlowImage : PivotSprite;
    
    public function new(maxEdgeLength : Float, rewardData : Dynamic, assetManager : AssetManager)
    {
        super();
        
        this.data = rewardData;
        m_assetManager = assetManager;
        
        // Create a general glow background for every button
        var backgroundGlowBitmapData : BitmapData = assetManager.getBitmapData("Art_YellowGlow");
        var backgroundGlowImage : PivotSprite = new PivotSprite();
		backgroundGlowImage.addChild(new Bitmap(backgroundGlowBitmapData));
        backgroundGlowImage.pivotX = backgroundGlowBitmapData.width * 0.5;
        backgroundGlowImage.pivotY = backgroundGlowBitmapData.height * 0.5;
        backgroundGlowImage.width = backgroundGlowImage.height = maxEdgeLength;
        backgroundGlowImage.x = maxEdgeLength * 0.5;
        backgroundGlowImage.y = maxEdgeLength * 0.5;
        addChild(backgroundGlowImage);
        m_backgroundGlowImage = backgroundGlowImage;
        
        var originalScale : Float = m_backgroundGlowImage.scaleX;
        var newScale : Float = originalScale * 1.1;
		Actuate.tween(m_backgroundGlowImage, 2, { scaleX: newScale, scaleY: newScale, alpha: 0.8 }).repeat().reflect();
    }
    
    /**
     * Subclasses should override this.
     * 
     * Each reward button type has a unique way of drawing the details screen related
     * to that particular reward.
     */
    public function getRewardDetailsScreen() : Sprite
    {
        return null;
    }
    
    override public function dispose() : Void
    {
		super.dispose();
		
		Actuate.stop(m_backgroundGlowImage);
    }
}
