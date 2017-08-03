package wordproblem.xp;


import flash.geom.Rectangle;

import starling.animation.Juggler;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.filters.ColorMatrixFilter;
import starling.textures.Texture;

import wordproblem.engine.text.OutlinedTextField;
import wordproblem.resource.AssetManager;

/**
 * This is the ui component to represent how much the player has filled
 * up an experience bar to reach a certain level.
 */
class PlayerXPBar extends Sprite
{
    /**
     * Other classes need to access the fill bar so it gets set to the correct ratio
     */
    private var m_xpBarFillImageSliced : Image;
    
    /**
     * The unsliced version should only be used for very small ratios
     */
    private var m_xpBarFillImageUnsliced : Sprite;
    
    private var m_xpBackgroundFillSliced : Image;
    private var m_xpBackgroundFillUnsliced : Sprite;
    
    /**
     * Container holding the main xp bar and it's filling
     */
    private var m_fillContainer : Sprite;
    
    /**
     * Width of the fill bar when it is 100% full (used to calculate the ratio
     */
    private var m_fillWidthWhenFull : Float;
    
    /**
     * This is the text showing the level the player has achieved
     */
    private var m_playerLevelTextField : OutlinedTextField;
    
    /**
     * Have an icon of a brain to act as the text background
     */
    private var m_brainImage : DisplayObject;
    
    /**
     * This is the container canvas that holds a description of the player level
     * and the brain background behind that text
     */
    private var m_brainImageContainer : Sprite;
    
    /**
     * These are the brain background images that are different colors.
     */
    private var m_brainBackgroundLayers : Array<DisplayObject>;
    
    /**
     * Container holding the background brain layers
     */
    private var m_brainBackgroundContainer : Sprite;
    
    /**
     * List of tweens that create an animated background behind the brain text
     */
    private var m_cycleTweens : Array<Tween>;
    
    private var m_juggler : Juggler;
    
    /**
     * @param maxBarLength
     *      The maximum pixel length of the xp bar
     */
    public function new(assetManager : AssetManager, maxBarLength : Float)
    {
        super();
        
        var fillContainer : Sprite = new Sprite();
        m_fillContainer = fillContainer;
        m_juggler = Starling.current.juggler;
        
        var padding : Float = 10;
        var xpBarBackTexture : Texture = assetManager.getTexture("xp_bar_back.png");
		
		// TODO: this was replaced from a Scale3Texture and may need to be fixed
        var xpBarBackImage : Image = new Image(Texture.fromTexture(
			xpBarBackTexture,
			new Rectangle(padding,
				0,
				xpBarBackTexture.width - 2 * padding,
				xpBarBackTexture.height
			)
		));
        xpBarBackImage.width = maxBarLength;
        fillContainer.addChild(xpBarBackImage);
        
        // The fill bar needs to have padding on the top and bottom
        var fillPaddingTop : Float = 5;
        var fillPaddingLeft : Float = 4;
        m_fillWidthWhenFull = maxBarLength - fillPaddingLeft * 2;
        var xpBarFillTexture : Texture = assetManager.getTexture("xp_bar_fill.png");
        
		// TODO: this was replaced from a Scale3Texture and may need to be fixed
        m_xpBarFillImageSliced = new Image(Texture.fromTexture(
			xpBarFillTexture,
			new Rectangle(padding,
				0,
				xpBarFillTexture.width - 2 * padding,
				xpBarFillTexture.height
			)
		));
        m_xpBarFillImageSliced.x = fillPaddingLeft;
        m_xpBarFillImageSliced.y = fillPaddingTop;
        
        var xpBarFillImageUnsliced : Image = new Image(xpBarFillTexture);
        xpBarFillImageUnsliced.x = fillPaddingLeft;
        xpBarFillImageUnsliced.y = fillPaddingTop;
        
        var clippableContainer : Sprite = new Sprite();
        clippableContainer.addChild(xpBarFillImageUnsliced);
        m_xpBarFillImageUnsliced = clippableContainer;
        
        // Add grayscale filter to make the fill look white
        var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter();
        colorMatrixFilter.adjustSaturation( -1);
		// TODO: this was replaced from a Scale3Texture and may need to be fixed
        m_xpBackgroundFillSliced = new Image(Texture.fromTexture(
			xpBarFillTexture,
			new Rectangle(padding,
				0,
				xpBarFillTexture.width - 2 * padding,
				xpBarFillTexture.height
			)
		));
        m_xpBackgroundFillSliced.x = fillPaddingLeft;
        m_xpBackgroundFillSliced.y = fillPaddingTop;
        m_xpBackgroundFillSliced.filter = colorMatrixFilter;
        
        var unslicedBackgroundImage : Image = new Image(xpBarFillTexture);
        unslicedBackgroundImage.x = fillPaddingLeft;
        unslicedBackgroundImage.y = fillPaddingTop;
        unslicedBackgroundImage.filter = colorMatrixFilter;
        m_xpBackgroundFillUnsliced = new Sprite();
        m_xpBackgroundFillUnsliced.addChild(unslicedBackgroundImage);
        
        // Set up background layers to brain that should animate when being filled
        m_brainBackgroundContainer = new Sprite();
        m_brainBackgroundContainer.y = 0;
        m_brainBackgroundContainer.x = xpBarBackImage.x + xpBarBackImage.width;
        addChild(m_brainBackgroundContainer);
        
        m_brainBackgroundLayers = new Array<DisplayObject>();
        var backgroundNames : Array<String> = ["Art_BrainFrontBgA", "Art_BrainFrontBgB", "Art_BrainFrontBgC"];
        for (backgroundName in backgroundNames)
        {
            var brainBackground : DisplayObject = new Image(assetManager.getTexture(backgroundName));
            brainBackground.pivotX = brainBackground.width * 0.5;
            brainBackground.pivotY = brainBackground.height * 0.5;
            m_brainBackgroundLayers.push(brainBackground);
        }
		
		// Put a single background behind the current brain  
        var brainBackground = m_brainBackgroundLayers[0];
        brainBackground.scaleX = brainBackground.scaleY = 0.8;
        brainBackground.x = 50;
        brainBackground.y = 12;
        m_brainBackgroundContainer.addChild(brainBackground);
        
        // Set up test fill
        addChild(fillContainer);
        setFillRatio(0.0);
        
        // Set up graphics for the brain container
        m_brainImageContainer = new Sprite();
        addChild(m_brainImageContainer);
        m_brainImageContainer.y = 0;
        m_brainImageContainer.x = xpBarBackImage.width;
        
        m_brainImage = new Image(assetManager.getTexture("Art_BrainLargeFront.png"));
        m_brainImage.scaleX = m_brainImage.scaleY = 0.4;
        m_brainImage.pivotX = m_brainImage.width * 0.5;
        m_brainImage.pivotY = m_brainImage.height * 0.5;
        m_brainImage.x = 12;
        m_brainImage.y = -5;
        m_brainImageContainer.addChild(m_brainImage);
        
        m_playerLevelTextField = new OutlinedTextField(100, 80, "Arial", 38, 0x000000, 0xFFFFFF);
        m_playerLevelTextField.setText("1");
        m_playerLevelTextField.pivotX = m_playerLevelTextField.width * 0.5;
        m_playerLevelTextField.pivotY = m_playerLevelTextField.height * 0.5;
        m_playerLevelTextField.x = 50;
        m_playerLevelTextField.y = 10;
        m_brainImageContainer.addChild(m_playerLevelTextField);
        
        m_cycleTweens = new Array<Tween>();
    }
    
    public function startCycleAnimation() : Void
    {
        var targetBackgroundStartWidth : Float = m_brainImage.width - 30;
        var targetBackgroundEndWidth : Float = 170;
        var startingX : Float = 50;
        var startingY : Float = 12;
        var cycleDuration : Float = 1.5;
        
        // The cycle animation is just a set of tweens that should constantly repeat
        var layerA : DisplayObject = m_brainBackgroundLayers[0];
        var startScale : Float = getTargetScale(layerA, targetBackgroundStartWidth);
        layerA.scaleX = layerA.scaleY = startScale;
        var endScale : Float = getTargetScale(layerA, targetBackgroundEndWidth);
        var layerATween : Tween = new Tween(layerA, cycleDuration);
        layerATween.repeatCount = 0;
        layerATween.animate("scaleX", endScale);
        layerATween.animate("scaleY", endScale);
        layerATween.animate("alpha", 0.55);
        layerATween.onRepeat = function() : Void
                {
                    m_brainBackgroundContainer.addChild(layerA);
                };
        m_juggler.add(layerATween);
        m_cycleTweens.push(layerATween);
        
        var layerB : DisplayObject = m_brainBackgroundLayers[1];
        layerB.x = startingX;
        layerB.y = startingY;
        startScale = getTargetScale(layerB, targetBackgroundStartWidth);
        layerB.scaleX = layerB.scaleY = startScale;
        endScale = getTargetScale(layerB, targetBackgroundEndWidth);
        var layerBTween : Tween = new Tween(layerB, cycleDuration);
        layerBTween.repeatCount = 0;
        layerBTween.delay = 0.5;
        layerBTween.animate("scaleX", endScale);
        layerBTween.animate("scaleY", endScale);
        layerBTween.animate("alpha", 0.55);
        layerBTween.onRepeat = function() : Void
                {
                    m_brainBackgroundContainer.addChild(layerB);
                };
        m_brainBackgroundContainer.addChild(layerB);
        m_juggler.add(layerBTween);
        m_cycleTweens.push(layerBTween);
        
        var layerC : DisplayObject = m_brainBackgroundLayers[2];
        layerC.x = startingX;
        layerC.y = startingY;
        startScale = getTargetScale(layerC, targetBackgroundStartWidth);
        layerC.scaleX = layerC.scaleY = startScale;
        endScale = getTargetScale(layerC, targetBackgroundEndWidth);
        var layerCTween : Tween = new Tween(layerC, cycleDuration);
        layerCTween.repeatCount = 0;
        layerCTween.delay = 1.0;
        layerCTween.animate("scaleX", endScale);
        layerCTween.animate("scaleY", endScale);
        layerCTween.animate("alpha", 0.55);
        layerCTween.onRepeat = function() : Void
                {
                    m_brainBackgroundContainer.addChild(layerC);
                };
        m_brainBackgroundContainer.addChild(layerC);
        m_juggler.add(layerCTween);
        m_cycleTweens.push(layerCTween);
    }
    
    public function endCycleAnimation() : Void
    {
        for (tween in m_cycleTweens)
        {
            m_juggler.remove(tween);
        }  // Restore the background to it's previous state  
        
        
        
        var startingX : Float = 50;
        var startingY : Float = 12;
        var startingScale : Float = 0.8;
        var layerA : DisplayObject = m_brainBackgroundLayers[0];
        layerA.x = startingX;
        layerA.y = startingY;
        layerA.scaleX = layerA.scaleY = startingScale;
        var layerB : DisplayObject = m_brainBackgroundLayers[1];
        layerB.removeFromParent();
        var layerC : DisplayObject = m_brainBackgroundLayers[2];
        layerC.removeFromParent();
        
		m_cycleTweens = new Array<Tween>();
    }
    
    private function getTargetScale(layer : DisplayObject, desiredWidth : Float) : Float
    {
        var originalScale : Float = layer.scaleX;
        layer.scaleX = layer.scaleY = 1.0;
        var endScale : Float = desiredWidth / layer.width;
        layer.scaleX = layer.scaleY = originalScale;
        return endScale;
    }
    
    public function getPlayerLevelTextField() : OutlinedTextField
    {
        return m_playerLevelTextField;
    }
    
    public function setFillRatio(ratio : Float) : Void
    {
        m_xpBarFillImageSliced.removeFromParent();
        m_xpBarFillImageUnsliced.removeFromParent();
        
        var newFillWidth : Float = m_fillWidthWhenFull * ratio;
        var imageToUse : DisplayObject = m_xpBarFillImageSliced;
        if (newFillWidth < m_xpBarFillImageSliced.texture.width) 
        {
            imageToUse = m_xpBarFillImageUnsliced;
            
            // If the width is too small for the 3-slice image to work, we instead
            // use a mask on the fill. This keeps the smooth rounded edge that gets lost
            // if just using scaling.
            var unslicedImage : Image = (try cast(m_xpBarFillImageUnsliced.getChildAt(0), Image) catch(e:Dynamic) null);
            m_xpBarFillImageUnsliced.clipRect = new Rectangle(
                unslicedImage.x,
				unslicedImage.y,
				newFillWidth,
				unslicedImage.texture.height
            );
        }
        else 
        {
            imageToUse.width = newFillWidth;
        }
        
        m_fillContainer.addChild(imageToUse);
    }
    
    /**
     * Get back the background fill image used
     */
    public function setBackgroundFillRatio(ratio : Float) : DisplayObject
    {
        var newFillWidth : Float = m_fillWidthWhenFull * ratio;
        var imageToUse : DisplayObject = m_xpBackgroundFillSliced;
        if (newFillWidth < m_xpBarFillImageSliced.texture.width) 
        {
            imageToUse = m_xpBackgroundFillUnsliced;
            
            // If the width is too small for the 3-slice image to work, we instead
            // use a mask on the fill. This keeps the smooth rounded edge that gets lost
            // if just using scaling.
            var unslicedImage : Image = (try cast(m_xpBackgroundFillUnsliced.getChildAt(0), Image) catch(e:Dynamic) null);
            m_xpBackgroundFillUnsliced.clipRect = new Rectangle(
                unslicedImage.x,
				unslicedImage.y,
				newFillWidth,
				unslicedImage.texture.height
            );
        }
        else 
        {
            imageToUse.width = newFillWidth;
        }
        
        m_fillContainer.addChildAt(imageToUse, 0);
        return imageToUse;
    }
    
    public function removeBackgroundFill() : Void
    {
        m_xpBackgroundFillSliced.removeFromParent();
        m_xpBackgroundFillUnsliced.removeFromParent();
    }
}
