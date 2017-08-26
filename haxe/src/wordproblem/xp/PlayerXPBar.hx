package wordproblem.xp;


import dragonbox.common.util.XColor;
import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;
import openfl.geom.Rectangle;
import wordproblem.display.DisposableSprite;
import wordproblem.display.PivotSprite;
import wordproblem.display.Scale9Image;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.filters.ColorMatrixFilter;

import wordproblem.engine.text.OutlinedTextField;
import wordproblem.resource.AssetManager;

/**
 * This is the ui component to represent how much the player has filled
 * up an experience bar to reach a certain level.
 */
class PlayerXPBar extends DisposableSprite
{
    /**
     * Other classes need to access the fill bar so it gets set to the correct ratio
     */
    private var m_xpBarFillImageSliced : Bitmap;
    
    /**
     * The unsliced version should only be used for very small ratios
     */
    private var m_xpBarFillImageUnsliced : Sprite;
    
    private var m_xpBackgroundFillSliced : Bitmap;
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
    private var m_brainImage : PivotSprite;
    
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
     * @param maxBarLength
     *      The maximum pixel length of the xp bar
     */
    public function new(assetManager : AssetManager, maxBarLength : Float)
    {
        super();
        
        var fillContainer : Sprite = new Sprite();
        m_fillContainer = fillContainer;
        
        var padding : Float = 10;
        var xpBarBackBitmapData : BitmapData = assetManager.getBitmapData("xp_bar_back");
		
        var xpBarBackImage : Scale9Image = new Scale9Image(xpBarBackBitmapData, new Rectangle(padding,
			0,
			xpBarBackBitmapData.width - 2 * padding,
			xpBarBackBitmapData.height));
        xpBarBackImage.width = maxBarLength;
        fillContainer.addChild(xpBarBackImage);
        
        // The fill bar needs to have padding on the top and bottom
        var fillPaddingTop : Float = 5;
        var fillPaddingLeft : Float = 4;
        m_fillWidthWhenFull = maxBarLength - fillPaddingLeft * 2;
        var xpBarFillBitmapData : BitmapData = assetManager.getBitmapData("xp_bar_fill");
        
        m_xpBarFillImageSliced = new Scale9Image(xpBarFillBitmapData, new Rectangle(padding,
			0,
			xpBarFillBitmapData.width - 2 * padding,
			xpBarFillBitmapData.height));
        m_xpBarFillImageSliced.x = fillPaddingLeft;
        m_xpBarFillImageSliced.y = fillPaddingTop;
        
        var xpBarFillImageUnsliced : Bitmap = new Bitmap(xpBarFillBitmapData);
        xpBarFillImageUnsliced.x = fillPaddingLeft;
        xpBarFillImageUnsliced.y = fillPaddingTop;
        
        var clippableContainer : Sprite = new Sprite();
        clippableContainer.addChild(xpBarFillImageUnsliced);
        m_xpBarFillImageUnsliced = clippableContainer;
        
        // Add grayscale filter to make the fill look white
        var colorMatrixFilter : ColorMatrixFilter = XColor.getGrayscaleFilter();
		
        m_xpBackgroundFillSliced = new Scale9Image(xpBarFillBitmapData, new Rectangle(padding,
			0,
			xpBarFillBitmapData.width - 2 * padding,
			xpBarFillBitmapData.height));
        m_xpBackgroundFillSliced.x = fillPaddingLeft;
        m_xpBackgroundFillSliced.y = fillPaddingTop;
		var filters = new Array<BitmapFilter>();
		filters.push(colorMatrixFilter);
        m_xpBackgroundFillSliced.filters = filters;
        
        var unslicedBackgroundImage : Bitmap = new Bitmap(xpBarFillBitmapData);
        unslicedBackgroundImage.x = fillPaddingLeft;
        unslicedBackgroundImage.y = fillPaddingTop;
        unslicedBackgroundImage.filters = filters;
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
            var brainBackground : PivotSprite = new PivotSprite();
			brainBackground.addChild(new Bitmap(assetManager.getBitmapData(backgroundName)));
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
        
        m_brainImage = new PivotSprite();
		m_brainImage.addChild(new Bitmap(assetManager.getBitmapData("Art_BrainLargeFront")));
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
		Actuate.tween(layerA, cycleDuration, { scaleX: endScale, scaleY: endScale, alpha: 0.55 }).repeat().onRepeat(function() : Void
                {
                    m_brainBackgroundContainer.addChild(layerA);
                });
        
        var layerB : DisplayObject = m_brainBackgroundLayers[1];
        layerB.x = startingX;
        layerB.y = startingY;
        startScale = getTargetScale(layerB, targetBackgroundStartWidth);
        layerB.scaleX = layerB.scaleY = startScale;
        endScale = getTargetScale(layerB, targetBackgroundEndWidth);
		Actuate.tween(layerB, cycleDuration, { scaleX: endScale, scaleY: endScale, alpha: 0.55 }).repeat().delay(0.5).onRepeat(function() : Void
                {
                    m_brainBackgroundContainer.addChild(layerB);
                });
        m_brainBackgroundContainer.addChild(layerB);
        
        var layerC : DisplayObject = m_brainBackgroundLayers[2];
        layerC.x = startingX;
        layerC.y = startingY;
        startScale = getTargetScale(layerC, targetBackgroundStartWidth);
        layerC.scaleX = layerC.scaleY = startScale;
        endScale = getTargetScale(layerC, targetBackgroundEndWidth);
		Actuate.tween(layerC, cycleDuration, { scaleX: endScale, scaleY: endScale, alpha: 0.55 }).repeat().delay(1.0).onRepeat(function() : Void
                {
                    m_brainBackgroundContainer.addChild(layerC);
                });
        m_brainBackgroundContainer.addChild(layerC);
    }
    
    public function endCycleAnimation() : Void
    {
        for (layer in m_brainBackgroundLayers)
        {
			Actuate.stop(layer);
        }
		
		// Restore the background to it's previous state  
        var startingX : Float = 50;
        var startingY : Float = 12;
        var startingScale : Float = 0.8;
        var layerA : DisplayObject = m_brainBackgroundLayers[0];
        layerA.x = startingX;
        layerA.y = startingY;
        layerA.scaleX = layerA.scaleY = startingScale;
        var layerB : DisplayObject = m_brainBackgroundLayers[1];
        if (layerB.parent != null) layerB.parent.removeChild(layerB);
        var layerC : DisplayObject = m_brainBackgroundLayers[2];
        if (layerC.parent != null) layerC.parent.removeChild(layerC);
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
        if (m_xpBarFillImageSliced.parent != null) m_xpBarFillImageSliced.parent.removeChild(m_xpBarFillImageSliced);
        if (m_xpBarFillImageUnsliced.parent != null) m_xpBarFillImageUnsliced.parent.removeChild(m_xpBarFillImageUnsliced);
        
        var newFillWidth : Float = m_fillWidthWhenFull * ratio;
        var imageToUse : DisplayObject = m_xpBarFillImageSliced;
        if (newFillWidth < m_xpBarFillImageSliced.bitmapData.width) 
        {
            imageToUse = m_xpBarFillImageUnsliced;
            
            // If the width is too small for the 3-slice image to work, we instead
            // use a mask on the fill. This keeps the smooth rounded edge that gets lost
            // if just using scaling.
            var unslicedImage : Bitmap = (try cast(m_xpBarFillImageUnsliced.getChildAt(0), Bitmap) catch(e:Dynamic) null);
            m_xpBarFillImageUnsliced.scrollRect = new Rectangle(
                unslicedImage.x,
				unslicedImage.y,
				newFillWidth,
				unslicedImage.bitmapData.height
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
        if (newFillWidth < m_xpBarFillImageSliced.bitmapData.width) 
        {
            imageToUse = m_xpBackgroundFillUnsliced;
            
            // If the width is too small for the 3-slice image to work, we instead
            // use a mask on the fill. This keeps the smooth rounded edge that gets lost
            // if just using scaling.
            var unslicedImage : Bitmap = (try cast(m_xpBackgroundFillUnsliced.getChildAt(0), Bitmap) catch(e:Dynamic) null);
            m_xpBackgroundFillUnsliced.scrollRect = new Rectangle(
                unslicedImage.x,
				unslicedImage.y,
				newFillWidth,
				unslicedImage.bitmapData.height
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
        if (m_xpBackgroundFillSliced.parent != null) m_xpBackgroundFillSliced.parent.removeChild(m_xpBackgroundFillSliced);
        if (m_xpBackgroundFillUnsliced.parent != null) m_xpBackgroundFillUnsliced.parent.removeChild(m_xpBackgroundFillUnsliced);
    }
}
