package wordproblem.currency;

import wordproblem.currency.CurrencyParticlesAnimation;

import starling.animation.Juggler;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.OutlinedTextField;
import wordproblem.resource.AssetManager;

/**
 * The animation that plays whenever the player has earned some set of coins
 * 
 * One central coin has the number of new coins earned.
 * A glow and spiral eminate from it.
 * A bunch of smaller coin overflow from the center.
 */
class CurrencyAwardedAnimation extends Sprite
{
    private var m_juggler : Juggler;
    private var m_tweens : Array<Tween>;
    
    private var m_currencyParticles : CurrencyParticlesAnimation;
    
    public function new(amountAwarded : Int,
            assetManager : AssetManager,
            juggler : Juggler)
    {
        super();
        
        m_juggler = juggler;
        m_tweens = new Array<Tween>();
        
        var coinDesiredEndDimension : Float = 60;
        var coinTexture : Texture = assetManager.getTexture("coin");
        var centralCoin : Image = new Image(coinTexture);
        centralCoin.pivotX = coinTexture.width * 0.5;
        centralCoin.pivotY = coinTexture.height * 0.5;
        addChild(centralCoin);
        
        m_currencyParticles = new CurrencyParticlesAnimation(coinTexture, this);
        
        var amountText : OutlinedTextField = new OutlinedTextField(
        coinDesiredEndDimension + 20, 
        coinDesiredEndDimension, 
        GameFonts.DEFAULT_FONT_NAME, 
        20, 0x000000, 0xFFFFFF);
        amountText.setText("+" + amountAwarded);
        amountText.pivotX = amountText.width * 0.5;
        amountText.pivotY = amountText.height * 0.5 + 6;
        
        var starBurst : DisplayObject = new Image(assetManager.getTexture("Art_StarBurst"));
        starBurst.pivotX = starBurst.width * 0.5;
        starBurst.pivotY = starBurst.height * 0.5;
        
        var glow : DisplayObject = new Image(assetManager.getTexture("Art_YellowGlow"));
        glow.pivotX = glow.width * 0.5;
        glow.pivotY = glow.height * 0.5;
        
        // First the coin pops in followed by the burst and glow
        // The text showing the amount earned then fades in
        // At the same time a quick burst of smaller coins explodes as a
        // particle effect
        centralCoin.scaleX = centralCoin.scaleY = 0.0;
        centralCoin.alpha = 0.0;
        var coinAppearTween : Tween = new Tween(centralCoin, 0.5);
        coinAppearTween.fadeTo(1.0);
        coinAppearTween.scaleTo(coinDesiredEndDimension / coinTexture.width);
        coinAppearTween.onComplete = function() : Void
                {
                    amountText.alpha = 0;
                    var textFadeInTween : Tween = new Tween(amountText, 0.5);
                    textFadeInTween.fadeTo(1.0);
                    m_juggler.add(textFadeInTween);
                    m_tweens.push(textFadeInTween);
                    addChild(amountText);
                    
                    m_currencyParticles.start();
                    m_juggler.add(m_currencyParticles);
                };
        m_juggler.add(coinAppearTween);
        m_tweens.push(coinAppearTween);
        
        starBurst.scaleX = starBurst.scaleY = 0.0;
        var burstAppearTween : Tween = new Tween(starBurst, 1);
        burstAppearTween.delay = 0.3;
        burstAppearTween.scaleTo(0.6);
        burstAppearTween.onComplete = function() : Void
                {
                    var burstRotateTween : Tween = new Tween(starBurst, 6);
                    burstRotateTween.repeatCount = 0;
                    burstRotateTween.animate("rotation", Math.PI * 2);
                    m_juggler.add(burstRotateTween);
                    m_tweens.push(burstRotateTween);
                };
        m_juggler.add(burstAppearTween);
        m_tweens.push(burstAppearTween);
        
        glow.scaleX = glow.scaleY = 0.0;
        var glowAppearTween : Tween = new Tween(glow, 0.5);
        glowAppearTween.scaleTo(0.7);
        glowAppearTween.onComplete = function() : Void
                {
                    var glowPulseTween : Tween = new Tween(glow, 1);
                    glowPulseTween.repeatCount = 0;
                    glowPulseTween.reverse = true;
                    glowPulseTween.scaleTo(0.5);
                    m_juggler.add(glowPulseTween);
                    m_tweens.push(glowPulseTween);
                };
        m_juggler.add(glowAppearTween);
        m_tweens.push(glowAppearTween);
        
        addChild(starBurst);
        addChild(glow);
        addChild(centralCoin);
    }
    
    override public function dispose() : Void
    {
        m_juggler.remove(m_currencyParticles);
        
        for (tween in m_tweens)
        {
            m_juggler.remove(tween);
        }
        
        removeChildren(0, -1, true);
        
        super.dispose();
    }
}
