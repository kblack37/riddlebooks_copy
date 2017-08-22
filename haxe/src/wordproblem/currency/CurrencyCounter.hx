package wordproblem.currency;


import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

import openfl.display.Sprite;

import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.text.OutlinedTextField;
import wordproblem.resource.AssetManager;

/**
 * Display to show the number of coins the player has earned.
 * 
 * Also has a built in animation to do a simple 3d spin of the coin.
 * Can do this periodically or continuously for something an indication that
 * the counter is increasing
 */
// TODO: revisit animation once more basic display elements are working properly
class CurrencyCounter extends Sprite
{
    /**
     * Text showing the amount of currency currently possessed
     */
    private var m_currencyText : OutlinedTextField;
    
    /**
     * This is the animation that plays showing the coin flipping.
     * Reference so we can control the number of times it flips
     */
    //private var m_flipTween : Tween;
    
    //private var m_threeDimensionalCoin : Sprite3D;
    
    public function new(assetManager : AssetManager,
            textMaxWidth : Float = 300,
            textMaxHeight : Float = 100,
            coinEdgeLength : Float = 150)
    {
        super();
        
        var scale9Padding : Float = 8;
		var textBackgroundBitmapData : BitmapData = assetManager.getBitmapData("button_white");
		// TODO: change the bitmaps with scale9Grids to Scale9Images
        var currencyTextBackground : Bitmap = new Bitmap(assetManager.getBitmapData("button_white"));
		currencyTextBackground.scale9Grid = new Rectangle(
			scale9Padding, 
			scale9Padding, 
			textBackgroundBitmapData.width - 2 * scale9Padding, 
			textBackgroundBitmapData.height - 2 * scale9Padding
        );
        currencyTextBackground.width = textMaxWidth;
        currencyTextBackground.height = textMaxHeight;
		currencyTextBackground.transform.colorTransform.concat(XColor.rgbToColorTransform(0xC2A100));
        addChild(currencyTextBackground);
        
        var coinBitmapData : BitmapData = assetManager.getBitmapData("coin");
        var coinImage : Bitmap = new Bitmap(coinBitmapData);
        var scaleFactor : Float = coinEdgeLength / coinBitmapData.width;
        coinImage.scaleX = coinImage.scaleY = scaleFactor;
        
        //var threeDimensionalCoin : Sprite3D = new Sprite3D();
        //threeDimensionalCoin.pivotX = coinImage.width * 0.5;
        //threeDimensionalCoin.pivotY = coinImage.height * 0.5;
        
        // Re-adjust so the top-left of the coin is at origin relative to this container
        //threeDimensionalCoin.x = threeDimensionalCoin.pivotX;
        //threeDimensionalCoin.y = threeDimensionalCoin.pivotY;
        //threeDimensionalCoin.addChild(coinImage);
        //addChild(threeDimensionalCoin);
        //m_threeDimensionalCoin = threeDimensionalCoin;
        
        // The text should appear to the right of the coin
        //currencyTextBackground.x = threeDimensionalCoin.pivotX;
        //currencyTextBackground.y = (coinEdgeLength - textMaxHeight) * 0.5;
        
        // The text should appear centered on the part of the background that is not
        // hidden by the coin.
        // Font size should just barey fit the given dimensions
        //var textfieldWidth : Float = textMaxWidth - threeDimensionalCoin.pivotX;
        //var textfieldHeight : Float = textMaxHeight;
        //var textFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0x000000);
        //var measuringText : MeasuringTextField = new MeasuringTextField();
        //measuringText.defaultTextFormat = textFormat;
        //var targetSize : Int = Std.int(measuringText.resizeToDimensions(textfieldWidth, textfieldHeight, "" + Std.int(Math.pow(2, 3))));
        //m_currencyText = new OutlinedTextField(textfieldWidth, textfieldHeight, 
                //textFormat.font, targetSize, try cast(textFormat.color, Int) catch(e:Dynamic) 0, 0xFFFFFF);
        
        // Add another layer
        var extraBackgroundPadding : Float = textMaxHeight * 0.1;
        var extraCurrencyTextBackground : Bitmap = new Bitmap(textBackgroundBitmapData);
		extraCurrencyTextBackground.scale9Grid = new Rectangle(
			scale9Padding, 
			scale9Padding, 
			textBackgroundBitmapData.width - 2 * scale9Padding, 
			textBackgroundBitmapData.height - 2 * scale9Padding
        );
        //extraCurrencyTextBackground.width = textfieldWidth - 2 * extraBackgroundPadding;
        extraCurrencyTextBackground.height = textMaxHeight - 2 * extraBackgroundPadding;
		extraCurrencyTextBackground.transform.colorTransform.concat(XColor.rgbToColorTransform(0xF7CD00));
        //extraCurrencyTextBackground.x = currencyTextBackground.x + threeDimensionalCoin.pivotX + extraBackgroundPadding;
        extraCurrencyTextBackground.y = (textMaxHeight - extraCurrencyTextBackground.height) * 0.5 + currencyTextBackground.y;
        addChild(extraCurrencyTextBackground);
        
        //m_currencyText.x = currencyTextBackground.x + threeDimensionalCoin.pivotX;
        m_currencyText.y = currencyTextBackground.y;
        addChild(m_currencyText);
    }
    
    /**
     * Set the number of coins visible
     */
    public function setValue(value : Int) : Void
    {
        m_currencyText.setText(value + "");
    }
    
    /**
     * Start the animation of the coin flipping in the counter. Treat a flip as
     * a full 360 degree spin
     * 
     * @param numFlips
     *      The number of times the flip should occur
     * @param rotationVelocity
     *      Radians per second
     */
    public function startAnimateCoinFlip(numFlips : Int, rotationalVelocity : Float) : Void
    {
        var duration : Float = Math.PI * 2 / rotationalVelocity;
        //m_flipTween = new Tween(m_threeDimensionalCoin, duration);
        //m_flipTween.animate("rotationY", Math.PI * 2);
        //m_flipTween.repeatCount = numFlips;
        //Starling.current.juggler.add(m_flipTween);
        //
        //m_flipTween.onComplete = function() : Void
                //{
                //};
    }
    
    /**
     *
     * @param smoothStop
     *      If the flip is playing, only stop the animation after it
     *      reaches a smooth stopping point (i.e. the face of the coins is
     *      rotated 0 or PI radians along the y axis)
     *      If false just immediately terminate the rotation
     */
    public function stopAnimateCoinFlip(smoothStop : Bool) : Void
    {
        //if (m_flipTween != null) 
        //{
            //m_threeDimensionalCoin.rotationY = 0;
            //Starling.current.juggler.remove(m_flipTween);
            //m_flipTween = null;
        //}
    }
}
