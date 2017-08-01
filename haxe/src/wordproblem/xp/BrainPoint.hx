package wordproblem.xp;


import flash.geom.Point;
import flash.text.TextFormat;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;

import wordproblem.display.CurvedText;
import wordproblem.resource.AssetManager;

/**
 * A brain point is the small icon of a brain that pops up whenver the player earns enough experience
 */
class BrainPoint extends Sprite
{
    private var m_tweens : Array<Tween>;
    
    public function new(text : String, assetManager : AssetManager)
    {
        super();
        
        m_tweens = new Array<Tween>();
        
        var brain : DisplayObject = new Image(assetManager.getTexture("Art_Brain"));
        brain.pivotX = brain.width * 0.5;
        brain.pivotY = brain.height * 0.5;
        
        var starBurst : DisplayObject = new Image(assetManager.getTexture("Art_StarBurst"));
        starBurst.pivotX = starBurst.width * 0.5;
        starBurst.pivotY = starBurst.height * 0.5;
        
        var arch : DisplayObject = new Image(assetManager.getTexture("Art_YellowArch"));
        arch.scaleX = arch.scaleY = 1.00;
        arch.y = -(arch.height * 0.6);
        arch.pivotX = arch.width * 0.5;
        arch.pivotY = arch.height * 0.5;
        
        var glow : DisplayObject = new Image(assetManager.getTexture("Art_YellowGlow"));
        glow.pivotX = glow.width * 0.5;
        glow.pivotY = glow.height * 0.5;
        glow.scaleX = glow.scaleY = 0.0;
        glow.alpha = 0.0;
        
        addChild(starBurst);
        addChild(glow);
        addChild(arch);
        addChild(brain);
        
        /*
        The desired animation.
        
        The brain and the arch are already visible
        The glow back fades in, expands then fades away
        The star should rotate around
        */
        starBurst.scaleX = starBurst.scaleY = 0.3;
        var fadeInStarBurst : Tween = new Tween(starBurst, 0.5);
        fadeInStarBurst.animate("scaleX", 1.0);
        fadeInStarBurst.animate("scaleY", 1.0);
        fadeInStarBurst.onComplete = function() : Void
                {
                    var rotateStarBurst : Tween = new Tween(starBurst, 8);
                    rotateStarBurst.repeatCount = 0;
                    rotateStarBurst.animate("rotation", 2 * Math.PI);
                    Starling.current.juggler.add(rotateStarBurst);
                };
        Starling.current.juggler.add(fadeInStarBurst);
        m_tweens.push(fadeInStarBurst);
        
        var delayedGlow : Tween = new Tween(glow, 0.5);
        delayedGlow.delay = 0.5;
        delayedGlow.animate("alpha", 1.0);
        delayedGlow.animate("scaleX", 1.25);
        delayedGlow.animate("scaleY", 1.25);
        delayedGlow.onComplete = function() : Void
                {
                    var shrinkGlow : Tween = new Tween(glow, 0.5);
                    shrinkGlow.delay = 0.5;
                    shrinkGlow.animate("scaleX", 0.7);
                    shrinkGlow.animate("scaleY", 0.7);
                    Starling.current.juggler.add(shrinkGlow);
                    m_tweens.push(shrinkGlow);
                };
        Starling.current.juggler.add(delayedGlow);
        m_tweens.push(delayedGlow);
        
        var bannerText : CurvedText = new CurvedText(text, new TextFormat("Arial", 10, 0x000000), 
        new Point(0, 20), new Point(25, 0), new Point(65, 0), new Point(90, 20));
        bannerText.y = arch.y - arch.pivotY + 7;
        bannerText.x = arch.x - arch.pivotX + 12;
        addChild(bannerText);
        
        this.touchable = false;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        for (tween in m_tweens)
        {
            Starling.current.juggler.remove(tween);
        }
    }
}
