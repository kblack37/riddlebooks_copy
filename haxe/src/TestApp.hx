package;

import cgs.audio.Audio;
import dragonbox.common.console.Console;
import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.state.StateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.Sprite;
import openfl.events.Event;

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
		addEventListener(Event.ADDED_TO_STAGE, run);
	}
	
	public function run(event : Event) {
		removeEventListener(Event.ADDED_TO_STAGE, run);
		
		var assetManager = new AssetManager();
		var vectorSpace = new RealsVectorSpace();
		var latexCompiler = new LatexCompiler(vectorSpace);
		var levelCompiler = new LevelCompiler(latexCompiler,
			assetManager.getXml("assets/layout/predefined_layouts.xml").toString());
		var algebraConfig = new AlgebraAdventureConfig();
		var expressionSymbolMap = new ExpressionSymbolMap(assetManager);
		mouseState = new MouseState(stage);
		time = new Time();
		var stateMachine = new StateMachine(stage.stageWidth, stage.stageHeight);
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
		
		assetManager.enqueue(["assets/levels/bar_model/turk_brainpop/856.xml"]);
		assetManager.loadQueue(function(ratio : Float) {
			if (ratio >= 1.0) {
				var xml = assetManager.getXml("856");
				
				var wordProblemLevelData = levelCompiler.compileWordProblemLevel(xml.firstElement(),
					"levelTest",
					0,
					-1,
					"genreTest",
					algebraConfig,
					scriptParser,
					new TextParser()
				);
				
				assetManager.enqueue(wordProblemLevelData.getImagesToLoad());
				assetManager.loadQueue(function(ratio : Float) {
					if (ratio >= 1.0) {
						addChild(gameState);
						
						this.addEventListener(Event.ENTER_FRAME, gameLoop);
						
						gameState.enter(null, [wordProblemLevelData]);
					}
				});
			}
		});
	}
	
	private function gameLoop(e : Dynamic) {
		gameState.update(time, mouseState);
		mouseState.onEnterFrame(null);
	}
}