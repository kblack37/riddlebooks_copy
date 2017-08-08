package;

import dragonbox.common.console.Console;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.state.StateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import starling.core.Starling;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.EventDispatcher;
import starling.text.TextField;
import wordproblem.AlgebraAdventureConfig;
import wordproblem.engine.GameEngine;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.level.LevelCompiler;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.text.model.DocumentNode;
import wordproblem.engine.text.model.ImageNode;
import wordproblem.engine.text.model.TextNode;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.text.view.TextView;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.player.ButtonColorData;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.saves.DummyCache;
import wordproblem.state.WordProblemGameState;

import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarModelView;

import wordproblem.scripts.level.GenericBarModelLevelScript;


/**
 * ...
 * @author 
 */
class TestApp extends Sprite {
	
	private var gameState : WordProblemGameState;
	private var time : Time;
	private var mouseState : MouseState;
	
	public function new() {
		super();
	}
	
	public function run() {
		var assetManager = new AssetManager();
		var vectorSpace = new RealsVectorSpace();
		var latexCompiler = new LatexCompiler(vectorSpace);
		var levelCompiler = new LevelCompiler(latexCompiler,
			assetManager.getXml("assets/layout/predefined_layouts.xml").toString());
		var algebraConfig = new AlgebraAdventureConfig();
		var expressionSymbolMap = new ExpressionSymbolMap(assetManager);
		mouseState = new MouseState(this.stage, new openfl.events.EventDispatcher());
		time = new Time();
		var stateMachine = new StateMachine(Starling.current.stage.stageWidth, Starling.current.stage.stageHeight);
		var gameEngine = new GameEngine(latexCompiler,
			assetManager,
			expressionSymbolMap,
			this.width,
			this.height,
			mouseState
		);
		var scriptParser = new ScriptParser(gameEngine,
			latexCompiler,
			assetManager,
			new PlayerStatsAndSaveData(new DummyCache())
		);
		var textViewFactory = new TextViewFactory(assetManager, expressionSymbolMap);
		
		// running the game state
		 gameState = new WordProblemGameState(
			stateMachine,
			gameEngine,
			assetManager,
			latexCompiler,
			expressionSymbolMap,
			algebraConfig,
			new Console(),
			new ButtonColorData()
		);
		
		// compiling levels from the xml, testing that text is parsed correctly
		var xml = assetManager.getXml("assets/levels/bar_model/turk_brainpop/510.xml");
		var wordProblemLevelData = levelCompiler.compileWordProblemLevel(xml.firstElement(),
			"levelTest",
			0,
			-1,
			"genreTest",
			algebraConfig,
			scriptParser,
			new TextParser()
		);
		
		addChild(gameState);
		
		this.addEventListener(Event.ENTER_FRAME, traceLoop);
		
		gameState.enter(null, [wordProblemLevelData]);
		
		// creating a BarModelData instance
		//var barModelData = new BarModelData();
		//var data : Dynamic = {
			//"vll":[
				//{"e":1, "s":0, "v":"vertical", "id":"890", "o":"bottom"}
			//],
			//"bwl":[
				//{"s":[
					//{"d":5, "n":5, "id":"867"},
					//{"d":5, "n":5, "id":"868"},
					//{"d":5, "n":15, "id":"869"},
					//{"d":5, "n":5, "id":"870"},
					//{"d":5, "n":5, "id":"871"}
					//],
				//"id":"866",
				//"l":[
					//{"e":1, "s":0, "v":"BlackAnts", "id":"880", "o":"bottom"},
					//{"e":2, "s":2, "v":"middle", "id":"881", "o":"top"},
					//{"e":4, "s":3, "v":"this label is really really long and will probably overflow the background", "id":"882", "o":"bottom"}
					//],
				//},
				//{"s":[
					//{"d":5, "n":5, "id":"877"}
					//], 
				//"id":"876",
				//"l":[
					//{"e":0, "s":0, "v":"5", "id":"878", "o":"top"}
					//],
				//}]};
				//
		//var data2 = createNumberSegmentBarData(20);
		//
		//barModelData.deserialize(data);
		//var dataRet : Dynamic = barModelData.serialize();
		//for (field in Reflect.fields(dataRet)) {
			//trace(field + ": " + Reflect.field(dataRet, field));
		//}
		//
		//// creating a BarModelView instance
		//var barModelView = new BarModelView(50, 50, 5, 5, 5, 5, 5, barModelData, expressionSymbolMap, assetManager);
		//barModelView.setDimensions(500, 500);
		//barModelView.redraw();
		//addChild(barModelView);
	}
	
	private function traceLoop(e : Event) {
		gameState.update(time, mouseState);
		mouseState.onEnterFrame();
	}
	
	// Function to trace the leaves in the tree defined by the word problem level data
	private function traceDocumentTree(node : DocumentNode) {
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
				traceDocumentTree(child);
			}
		}
	}
	
	private function buildExpressionFromRoot(node : ExpressionNode) : String {
		if (node.isLeaf()) {
			return node.data;
		} else {
			var result = "";
			result += buildExpressionFromRoot(node.left);
			result += node.data;
			result += buildExpressionFromRoot(node.right);
			return result;
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
	
	private function createNumberSegmentBarData(numSegments : Int) : Dynamic {
		var result : Dynamic = {"vll": [],
								"bwl": [
									{"s": [],
									 "id": Std.string(numSegments),
									 "l":{ }
									}
								]
		};
		for (i in 0...numSegments) {
			result.bwl[0].s.push({"d":5, "n":5, "id":Std.string(i)});
		}
		return result;
	}
}