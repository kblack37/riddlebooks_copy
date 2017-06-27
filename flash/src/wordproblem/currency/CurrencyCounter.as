package wordproblem.currency
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.display.Sprite3D;
    import starling.textures.Texture;
    
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
    public class CurrencyCounter extends Sprite
    {
        /**
         * Text showing the amount of currency currently possessed
         */
        private var m_currencyText:OutlinedTextField;
        
        /**
         * This is the animation that plays showing the coin flipping.
         * Reference so we can control the number of times it flips
         */
        private var m_flipTween:Tween;
        
        private var m_threeDimensionalCoin:Sprite3D;
        
        public function CurrencyCounter(assetManager:AssetManager, 
                                        textMaxWidth:Number=300, 
                                        textMaxHeight:Number=100, 
                                        coinEdgeLength:Number=150)
        {
            super();
            
            var scale9Padding:Number = 8;
            var textBackgroundTexture:Texture = assetManager.getTexture("button_white");
            var currencyTextBackground:Scale9Image = new Scale9Image(
                new Scale9Textures(textBackgroundTexture, 
                    new Rectangle(
                        scale9Padding, 
                        scale9Padding, 
                        textBackgroundTexture.width - 2 * scale9Padding, 
                        textBackgroundTexture.height - 2 * scale9Padding))
            );
            currencyTextBackground.width = textMaxWidth;
            currencyTextBackground.height = textMaxHeight;
            currencyTextBackground.color = 0xC2A100;
            addChild(currencyTextBackground);
            
            var coinTexture:Texture = assetManager.getTexture("coin");
            var coinImage:Image = new Image(coinTexture);
            var scaleFactor:Number = coinEdgeLength / coinTexture.width;
            coinImage.scaleX = coinImage.scaleY = scaleFactor;
            
            var threeDimensionalCoin:Sprite3D = new Sprite3D();
            threeDimensionalCoin.pivotX = coinImage.width * 0.5;
            threeDimensionalCoin.pivotY = coinImage.height * 0.5;
            
            // Re-adjust so the top-left of the coin is at origin relative to this container
            threeDimensionalCoin.x = threeDimensionalCoin.pivotX;
            threeDimensionalCoin.y = threeDimensionalCoin.pivotY;
            threeDimensionalCoin.addChild(coinImage);
            addChild(threeDimensionalCoin);
            m_threeDimensionalCoin = threeDimensionalCoin;
            
            // The text should appear to the right of the coin
            currencyTextBackground.x = threeDimensionalCoin.pivotX;
            currencyTextBackground.y = (coinEdgeLength - textMaxHeight) * 0.5;
            
            // The text should appear centered on the part of the background that is not
            // hidden by the coin.
            // Font size should just barey fit the given dimensions
            var textfieldWidth:Number = textMaxWidth - threeDimensionalCoin.pivotX;
            var textfieldHeight:Number = textMaxHeight;
            var textFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0x000000);
            var measuringText:MeasuringTextField = new MeasuringTextField();
            measuringText.defaultTextFormat = textFormat;
            var targetSize:int = measuringText.resizeToDimensions(textfieldWidth, textfieldHeight, "" + int.MAX_VALUE);
            m_currencyText = new OutlinedTextField(textfieldWidth, textfieldHeight, 
                textFormat.font, targetSize, textFormat.color as uint, 0xFFFFFF);
            
            // Add another layer
            var extraBackgroundPadding:Number = textMaxHeight * 0.1;
            var extraCurrencyTextBackground:Scale9Image = new Scale9Image(
                new Scale9Textures(textBackgroundTexture, 
                    new Rectangle(
                        scale9Padding, 
                        scale9Padding, 
                        textBackgroundTexture.width - 2 * scale9Padding, 
                        textBackgroundTexture.height - 2 * scale9Padding))
            );
            extraCurrencyTextBackground.width = textfieldWidth - 2 * extraBackgroundPadding;
            extraCurrencyTextBackground.height = textMaxHeight - 2 * extraBackgroundPadding;
            extraCurrencyTextBackground.color = 0xF7CD00;
            extraCurrencyTextBackground.x = currencyTextBackground.x + threeDimensionalCoin.pivotX + extraBackgroundPadding;
            extraCurrencyTextBackground.y = (textMaxHeight - extraCurrencyTextBackground.height) * 0.5 + currencyTextBackground.y;
            addChild(extraCurrencyTextBackground)
            
            m_currencyText.x = currencyTextBackground.x + threeDimensionalCoin.pivotX;
            m_currencyText.y = currencyTextBackground.y;
            addChild(m_currencyText);
        }
        
        /**
         * Set the number of coins visible
         */
        public function setValue(value:int):void
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
        public function startAnimateCoinFlip(numFlips:int, rotationalVelocity:Number):void
        {
            var duration:Number = Math.PI * 2 / rotationalVelocity;
            m_flipTween = new Tween(m_threeDimensionalCoin, duration);
            m_flipTween.animate("rotationY", Math.PI * 2);
            m_flipTween.repeatCount = numFlips;
            Starling.juggler.add(m_flipTween);
            
            m_flipTween.onComplete = function():void
            {
                
            };
        }
        
        /**
         *
         * @param smoothStop
         *      If the flip is playing, only stop the animation after it
         *      reaches a smooth stopping point (i.e. the face of the coins is
         *      rotated 0 or PI radians along the y axis)
         *      If false just immediately terminate the rotation
         */
        public function stopAnimateCoinFlip(smoothStop:Boolean):void
        {
            if (m_flipTween != null)
            {
                m_threeDimensionalCoin.rotationY = 0;
                Starling.juggler.remove(m_flipTween);
                m_flipTween = null;
            }
        }
    }
}