package;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.ui.MouseState;
import haxe.xml.Fast;
import openfl.geom.Rectangle;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.EventDispatcher;
import starling.textures.Texture;
import wordproblem.AlgebraAdventureConfig;
import wordproblem.display.DottedRectangle;
import wordproblem.engine.GameEngine;
import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.view.BarComparisonView;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.level.LevelCompiler;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.text.TextParser;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.saves.DummyCache;


/**
 * ...
 * @author 
 */
class TestApp extends Sprite {

	public function new() {
		super();
		
		// getting an image from the asset manager
		var assetManager = new AssetManager();
		var img : Image = new Image(assetManager.getTexture("assets/ui/bar_model/comparison_full.png"));
		//addChild(img);
		
		// getting an xml from the asset manager
		var xml : Xml = assetManager.getXml("assets/levels/bar_model/turk_brainpop/510.xml");
		//trace(xml.toString());
		
		// compiling a level from the xml
		var vectorSpace = new RealsVectorSpace();
		var levelCompiler = new LevelCompiler(new LatexCompiler(vectorSpace), assetManager.getXml("assets/layout/predefined_layouts.xml").toString());
		var algebraConfig = new AlgebraAdventureConfig();
		var gameEngine = new GameEngine(new LatexCompiler(vectorSpace), assetManager, new ExpressionSymbolMap(assetManager), this.width, this.height, new MouseState(new starling.events.EventDispatcher(), new openfl.events.EventDispatcher()));
		var scriptParser = new ScriptParser(gameEngine, new LatexCompiler(vectorSpace), assetManager, new PlayerStatsAndSaveData(new DummyCache()));
		var wordProblemLevelData = levelCompiler.compileWordProblemLevel((new Fast(xml)).node.level.x,
			"levelTest", 0, -1, "genreTest",
			algebraConfig, scriptParser, new TextParser());
			
		//trace(wordProblemLevelData.m_rootDocumentNode.toString());
		
		// creating a BarModelData instance
		var barModelData = new BarModelData();
		var data : Dynamic = {
"vll":[],
"bwl":[
{"s":[{"d":5,"n":5,"id":"867"},{"d":5,"n":5,"id":"868"},{"d":5,"n":5,"id":"869"},{"d":5,"n":5,"id":"870"},{"d":5,"n":5,"id":"871"}],"id":"866","l":[{"e":4,"s":0,"v":"BlackAnts","id":"880"}]},
{"s":[{"d":5, "n":5, "id":"877"}], "id":"876", "l":[{"e":0, "s":0, "v":"5", "id":"878"}]}]};

		
		barModelData.deserialize(data);
		var dataRet : Dynamic = barModelData.serialize();
		for (field in Reflect.fields(dataRet)) {
			trace(field + ": " + Reflect.field(dataRet, field));
		}
		
		// creating a BarModelView instance
		var barModelView = new BarModelView(50, 50, 5, 5, 5, 5, 5, barModelData, new ExpressionSymbolMap(assetManager), assetManager);
		barModelView.setDimensions(500, 500);
		barModelView.redraw();
		addChild(barModelView);
	}
	
}