package;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.ui.MouseState;
import starling.core.Starling;
import starling.display.Sprite;
import starling.events.EventDispatcher;
import starling.text.TextField;
import wordproblem.AlgebraAdventureConfig;
import wordproblem.engine.GameEngine;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.level.LevelCompiler;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.text.model.DocumentNode;
import wordproblem.engine.text.model.ImageNode;
import wordproblem.engine.text.model.TextNode;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.text.view.TextView;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.saves.DummyCache;

import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarModelView;


/**
 * ...
 * @author 
 */
class TestApp extends Sprite {
	
	public function new() {
		super();
		
		// some setup for level compilation
		var assetManager = new AssetManager();
		var vectorSpace = new RealsVectorSpace();
		var levelCompiler = new LevelCompiler(new LatexCompiler(vectorSpace),
			assetManager.getXml("assets/layout/predefined_layouts.xml").toString());
		var algebraConfig = new AlgebraAdventureConfig();
		var expressionSymbolMap = new ExpressionSymbolMap(assetManager);
		var gameEngine = new GameEngine(new LatexCompiler(vectorSpace),
			assetManager,
			expressionSymbolMap,
			this.width,
			this.height,
			new MouseState(new starling.events.EventDispatcher(),
				new openfl.events.EventDispatcher()
			)
		);
		var scriptParser = new ScriptParser(gameEngine,
			new LatexCompiler(vectorSpace),
			assetManager,
			new PlayerStatsAndSaveData(new DummyCache())
		);
		var textViewFactory = new TextViewFactory(assetManager, expressionSymbolMap);
		
		// compiling levels from the xml, testing that text is parsed correctly
		//var xml = assetManager.getXml("assets/levels/bar_model/turk_brainpop/519.xml");
		//var wordProblemLevelData = levelCompiler.compileWordProblemLevel(xml.firstElement(),
			//"levelTest",
			//0,
			//-1,
			//"genreTest",
			//algebraConfig,
			//scriptParser,
			//new TextParser()
		//);
		
		//var docView = textViewFactory.createView(wordProblemLevelData.m_rootDocumentNode[0]);
		//addChild(docView);
		
		// creating a BarModelData instance
		var barModelData = new BarModelData();
		var data : Dynamic = {
			"vll":[],
			"bwl":[
				{"s":[
					{"d":5, "n":5, "id":"867"},
					{"d":5, "n":5, "id":"868"},
					{"d":5, "n":5, "id":"869"},
					{"d":5, "n":5, "id":"870"},
					{"d":5, "n":5, "id":"871"}
					],
				"id":"866",
				"l":[
					{"e":4, "s":0, "v":"BlackAnts", "id":"880", "o":"bottom"}
					],
				},
				{"s":[
					{"d":5, "n":5, "id":"877"}
					], 
				"id":"876",
				"l":[
					{"e":0, "s":0, "v":"5", "id":"878", "o":"top"}
					],
				}]};
		
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
	
	// Function to trace the leaves in the tree defined by the word problem level data
	private function traceTree(node : DocumentNode) {
		// if it has no children, we've found a leaf, which can be a TextNode or an ImageNode
		if (node.children.length == 0) {
			if (Std.instance(node, TextNode) != null) {
				var castedNode = try cast(node, TextNode) catch (e : Dynamic) null;
				trace(castedNode.getText());
			} else if (Std.instance(node, ImageNode) != null) {
				var castedNode = try cast(node, ImageNode) catch (e : Dynamic) null;
				trace(castedNode.src);
			}
		} else {
			for (child in node.children) {
				traceTree(child);
			}
		}
	}
	
	// helper function for debugging to trace specific properties of the 
	// DocumentView children
	private function traceDocViewComponents(view : DocumentView) {
		trace(view.node.paddingTop);
		if (view.childViews.length == 0) {
		} else {
			for (child in view.childViews) {
				traceDocViewComponents(child);
			}
		}
	}
}