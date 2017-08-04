package wordproblem.achievements;

import wordproblem.achievements.PlayerAchievementGem;

import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextFormat;

import cgs.internationalization.StringTable;

import dragonbox.common.dispose.IDisposable;

import haxe.Constraints.Function;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

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
    private var m_achievementBackground : Image;
    private var m_achievementName : OutlinedTextField;
    private var m_tweens : Array<Tween>;
    
    public function new(displayParent : DisplayObjectContainer,
            centerX : Float,
            centerY : Float,
            achievementData : Dynamic,
            assetManager : AssetManager,
            onComplete : Function)
    {
        m_tweens = new Array<Tween>();
        
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
        var arch : DisplayObject = new Image(assetManager.getTexture("Art_YellowArch.png"));
        arch.scaleX = arch.scaleY = 1.5;
        var topY : Float = -36;
        var startX : Float = 0;
		// TODO: uncomment once cgs library is finished
        var textA : CurvedText = new CurvedText("", /*StringTable.lookup("new"),*/ new TextFormat("Verdana", 14, 0x000000), 
        new Point(startX, topY + arch.width), new Point(startX, topY), new Point(arch.width + startX, topY), new Point(arch.width + startX, topY + arch.width));
        topY = -20;
        startX = 4;
		// TODO: uncomment once cgs library is finished
        var textB : CurvedText = new CurvedText("", /*StringTable.lookup("achievement"),*/ new TextFormat("Verdana", 14, 0x000000), 
        new Point(startX, topY + arch.width - 7), new Point(startX, topY), new Point(arch.width + startX, topY), new Point(arch.width + startX, topY + arch.width - 7));
        bannerContainer.addChild(arch);
        bannerContainer.addChild(textA);
        bannerContainer.addChild(textB);
        
        // Draw the background image for the achievement name text
        var backgroundTexture : Texture = assetManager.getTexture("button_white.png");
        var textAndBgContainer : Sprite = new Sprite();
        var padding : Float = 8;
        var backgroundHeight : Float = maxHeight * 0.75;
        m_achievementBackground = new Image(Texture.fromTexture(backgroundTexture, 
                new Rectangle(padding, padding, backgroundTexture.width - padding * 2, backgroundTexture.height - padding * 2)));
        
        // Convert string colors to hex
        m_achievementBackground.color = PlayerAchievementData.getDarkHexColorFromString(achievementData.color);
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
        var showGemTween : Tween = new Tween(achievementGem, 0.2);
        showGemTween.scaleTo(endScale);
        showGemTween.fadeTo(1.0);
        showGemTween.onComplete = function() : Void
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
                                var shiftContainerTween : Tween = new Tween(m_displayContainer, backgroundExpandDuration);
                                shiftContainerTween.animate("x", m_displayContainer.x - xDelta);
                                Starling.current.juggler.add(shiftContainerTween);
                                
                                var expandBackgroundTween : Tween = new Tween(m_achievementBackground, backgroundExpandDuration);
                                expandBackgroundTween.animate("width", maxWidth);
                                expandBackgroundTween.onComplete = function() : Void
                                        {
                                            // Fade in the achievement name text here
                                            m_achievementName.x = scaledAchievementWidth * 0.3;
                                            m_achievementName.y -= 10;
                                            textAndBgContainer.addChild(m_achievementName);
                                            
                                            var fadeAwayTween : Tween = new Tween(m_displayContainer, 1);
                                            fadeAwayTween.animate("alpha", 0.0);
                                            fadeAwayTween.delay = 1.0;
                                            fadeAwayTween.onComplete = onComplete;
                                            Starling.current.juggler.add(fadeAwayTween);
                                            m_tweens.push(fadeAwayTween);
                                        };
                                Starling.current.juggler.add(expandBackgroundTween);
                            }
                            );
                };
        Starling.current.juggler.add(showGemTween);
        m_tweens.push(showGemTween);
    }
    
    public function dispose() : Void
    {
        m_displayContainer.removeChildren(0, -1, true);
        m_displayContainer.removeFromParent(true);
        while (m_tweens.length > 0)
        {
            Starling.current.juggler.remove(m_tweens.pop());
        }
    }
}
