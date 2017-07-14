package;

import haxe.xml.Fast;
//import dragonbox.common.expressiontree.compile.LatexCompiler;
//import wordproblem.engine.level.LevelCompiler;
import wordproblem.resource.AssetManager;

import starling.display.Image;
import starling.display.Sprite;
import starling.display.Quad;

/**
 * ...
 * @author 
 */
class TestApp extends Sprite {

	public function new() {
		super();
		
		// getting an image from the asset manager
		var assetManager = new AssetManager();
		var img : Image = new Image(assetManager.getTexture("assets/card/fantasy/card_chalices.png"));
		addChild(img);
		
		var xml : Fast = assetManager.getXml("assets/levels/bar_model/turk_brainpop/510.xml");
		trace(xml.x.toString());
		
		//var levelCompiler = new LevelCompiler(new LatexCompiler(), 
	}
	
}