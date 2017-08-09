package;

import dragonbox.common.console.Console;
import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.state.StateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import starling.core.Starling;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.EventDispatcher;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.engine.GameEngine;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.level.LevelCompiler;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.player.ButtonColorData;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.saves.DummyCache;
import wordproblem.state.WordProblemGameState;

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
		Starling.current.stage.stageWidth = 800;
		Starling.current.stage.stageHeight = 600;
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
		var xml = assetManager.getXml("assets/levels/bar_model/turk_brainpop/511.xml");
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
	}
	
	private function traceLoop(e : Event) {
		gameState.update(time, mouseState);
		mouseState.onEnterFrame();
	}
}