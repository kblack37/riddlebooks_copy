package wordproblem.achievements;

import dragonbox.common.util.XColor;
import motion.Actuate;
import openfl.display.Bitmap;
import wordproblem.achievements.PlayerAchievementGem;
import wordproblem.display.Scale9Image;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

import cgs.internationalization.StringTable;

import dragonbox.common.dispose.IDisposable;

import haxe.Constraints.Function;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;

import wordproblem.display.CurvedText;
import wordproblem.engine.text.OutlinedTextField;
import wordproblem.resource.AssetManager;

/**
 * Animation for a new achievement being earned
 * 
 * An empty gem quickly pops in.
 * The center shrinks and the filled in portion then expands out
 * The gem shifts over to reveal text saying achievement earned
 * The name of the achievement shows up
 * The entire display fades away at the end
 */
class AchievementUnlockedAnimation implements IDisposable
{
    private var m_displayContainer : Sprite;
    private var m_achievementGem : PlayerAchievementGem;
    private var m_achievementBackground : Scale9Image;
    private var m_achievementName : OutlinedTextField;
    private var m_animationObjects : Array<DisplayObject>;
    
    public function new(displayParent : DisplayObjectContainer,
            centerX : Float,
            centerY : Float,
            achievementData : Dynamic,
            assetManager : AssetManager,
            onComplete : Function)
    {
        m_animationObjects = new Array<DisplayObject>();
        
        var maxWidth : Float = 250;
        var maxHeight : Float = 100;
        
        m_displayContainer = new Sprite();
        m_displayContainer.x = centerX;
        m_displayContainer.y = centerY;
        displayParent.addChild(m_displayContainer);
        
        // When the achievement name text expands both the gem and background must shift
        // over so the entire display looks like its still centered
        var xDelta : Float = maxWidth * 0.5;
        
        var achievementColor : String = achievementData.color;
        var achievementGem : PlayerAchievementGem = new PlayerAchievementGem(
			achievementData.color, 
			achievementData.trophyName, 
			false, 
			assetManager
        );
        achievementGem.pivotX = achievementGem.width * 0.5;
        achievementGem.pivotY = achievementGem.height * 0.5;
        m_achievementGem = achievementGem;
        var endScale : Float = (maxHeight / achievementGem.height);
        var scaledAchievementWidth : Float = achievementGem.width * endScale;
        
        // Create a banner to indicate an achievement was earned
        var bannerContainer : Sprite = new Sprite();
        var arch : DisplayObject = new Bitmap(assetManager.getBitmapData("Art_YellowArch"));
        arch.scaleX = arch.scaleY = 1.5;
        var topY : Float = -36;
        var startX : Float = 0;
		// TODO: uncomment once cgs library is finished
        var textA : CurvedText = new CurvedText("", /*StringTable.lookup("new"),*/ new TextFormat("Verdana", 14, 0x000000), 
			new Point(startX, topY + arch.width),
			new Point(startX, topY),
			new Point(arch.width + startX, topY),
			new Point(arch.width + startX, topY + arch.width));
        topY = -20;
        startX = 4;
		// TODO: uncomment once cgs library is finished
        var textB : CurvedText = new CurvedText("", /*StringTable.lookup("achievement"),*/ new TextFormat("Verdana", 14, 0x000000), 
			new Point(startX, topY + arch.width - 7),
			new Point(startX, topY),
			new Point(arch.width + startX, topY),
			new Point(arch.width + startX, topY + arch.width - 7));
        bannerContainer.addChild(arch);
        bannerContainer.addChild(textA);
        bannerContainer.addChild(textB);
        
        // Draw the background image for the achievement name text
        var backgroundBitmapData : BitmapData = assetManager.getBitmapData("button_white");
        var textAndBgContainer : Sprite = new Sprite();
        var padding : Float = 8;
        var backgroundHeight : Float = maxHeight * 0.75;
        m_achievementBackground = new Scale9Image(backgroundBitmapData, new Rectangle(padding, padding, backgroundBitmapData.width - padding * 2, backgroundBitmapData.height - padding * 2));
        
        // Convert string colors to hex
		m_achievementBackground.transform.colorTransform = XColor.rgbToColorTransform(achievementData.color);
        m_achievementBackground.height = backgroundHeight;
        m_achievementBackground.width = 0;
        textAndBgContainer.addChild(m_achievementBackground);
        
        m_achievementName = new OutlinedTextField(maxWidth, backgroundHeight, "Verdana", 18, 0xFFFFFF, PlayerAchievementData.getDarkHexColorFromString(achievementData.color));
        m_achievementName.setText(achievementData.name);
        
        // Background should appear just left of the gem
        textAndBgContainer.y = -backgroundHeight * 0.5;
        
        m_displayContainer.addChild(achievementGem);
        achievementGem.scaleX = achievementGem.scaleY = 0.0;
        achievementGem.alpha = 0.0;
		Actuate.tween(achievementGem, 0.2, { scaleX: endScale, scaleY: endScale, alpha: 1}).onComplete(function() : Void
                {
                    bannerContainer.x -= bannerContainer.width * 0.5;
                    bannerContainer.y = -bannerContainer.height;
                    m_displayContainer.addChild(bannerContainer);
                    achievementGem.startFillAnimation(0.7, function() : Void
                            {
                                // Have the achievement gem slide to the left to make room for the background
                                // as it is expanding
                                m_displayContainer.addChildAt(textAndBgContainer, 0);
                                var backgroundExpandDuration : Float = 0.7;
								Actuate.tween(m_displayContainer, backgroundExpandDuration, { x: m_displayContainer.x - xDelta });
                                
								Actuate.tween(m_achievementBackground, backgroundExpandDuration, { width: maxWidth }).onComplete(function() : Void
                                        {
                                            // Fade in the achievement name text here
                                            m_achievementName.x = scaledAchievementWidth * 0.3;
                                            m_achievementName.y -= 10;
                                            textAndBgContainer.addChild(m_achievementName);
                                            
											Actuate.tween(m_displayContainer, 1, { alpha: 0 }).delay(1).onComplete(onComplete);
                                            m_animationObjects.push(m_displayContainer);
                                        });
                            }
                            );
                });
        m_animationObjects.push(achievementGem);
    }
    
    public function dispose() : Void
    {
		m_achievementBackground.dispose();
        m_displayContainer.removeChildren(0, -1);
		if (m_displayContainer.parent != null) m_displayContainer.parent.removeChild(m_displayContainer);
        while (m_animationObjects.length > 0)
        {
			Actuate.stop(m_animationObjects.pop());
        }
    }
}
