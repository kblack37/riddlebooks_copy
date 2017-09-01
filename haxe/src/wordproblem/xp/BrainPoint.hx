package wordproblem.xp;


import motion.Actuate;
import openfl.geom.Point;
import openfl.text.TextFormat;
import wordproblem.display.DisposableSprite;
import wordproblem.display.PivotSprite;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Sprite;

import wordproblem.display.CurvedText;
import wordproblem.resource.AssetManager;

/**
 * A brain point is the small icon of a brain that pops up whenver the player earns enough experience
 */
class BrainPoint extends DisposableSprite
{
	private var m_tweenObjects : Array<DisplayObject>;
	
    public function new(text : String, assetManager : AssetManager)
    {
        super();
		
		m_tweenObjects = new Array<DisplayObject>();
        
        var brain : PivotSprite = new PivotSprite();
		brain.addChild(new Bitmap(assetManager.getBitmapData("Art_Brain")));
        brain.pivotX = brain.width * 0.5;
        brain.pivotY = brain.height * 0.5;
        
        var starBurst : PivotSprite = new PivotSprite();
		starBurst.addChild(new Bitmap(assetManager.getBitmapData("Art_StarBurst")));
        starBurst.pivotX = starBurst.width * 0.5;
        starBurst.pivotY = starBurst.height * 0.5;
        
        var arch : PivotSprite = new PivotSprite();
		arch.addChild(new Bitmap(assetManager.getBitmapData("Art_YellowArch")));
        arch.scaleX = arch.scaleY = 1.00;
        arch.y = -(arch.height * 0.6);
        arch.pivotX = arch.width * 0.5;
        arch.pivotY = arch.height * 0.5;
        
        var glow : PivotSprite = new PivotSprite();
		glow.addChild(new Bitmap(assetManager.getBitmapData("Art_YellowGlow")));
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
		Actuate.tween(starBurst, 0.5, { scaleX: 1, scaleY: 1 }).onComplete(function() : Void
                {
					Actuate.tween(starBurst, 8, { rotation: 360 }).repeat().smartRotation();
                });
		m_tweenObjects.push(starBurst);
		
        Actuate.tween(glow, 0.5, { alpha: 1, scaleX: 1.25, scaleY: 1.25 }).delay(0.5).onComplete(function() : Void
                {
					Actuate.tween(glow, 0.5, { scaleX: 0.7, scaleY: 0.7 }).delay(0.5);
                });
		m_tweenObjects.push(glow);
        
        var bannerText : CurvedText = new CurvedText(text, new TextFormat("Arial", 10, 0x000000), 
        new Point(0, 20), new Point(25, 0), new Point(65, 0), new Point(90, 20));
        bannerText.y = arch.y - arch.pivotY + 7;
        bannerText.x = arch.x - arch.pivotX + 12;
        addChild(bannerText);
        
        this.mouseEnabled = false;
    }
    
    override public function dispose() : Void
    {
		super.dispose();
		
        for (object in m_tweenObjects)
        {
			Actuate.stop(object);
        }
    }
}
