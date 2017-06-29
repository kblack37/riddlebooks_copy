package gameconfig.versions.copilot;


import cgs.server.responses.CgsUserResponse;
import cgs.user.CgsUserProperties;

import dragonbox.common.expressiontree.WildCardNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;

import starling.events.Event;

import wordproblem.copilot.AlgebraAdventureCopilotService;
import wordproblem.engine.GameEngine;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.text.TextParser;
import wordproblem.event.CommandEvent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.scripts.level.save.UpdateAndSaveLevelDataScript;
import wordproblem.scripts.performance.PerformanceAndStatsScript;
import wordproblem.scripts.state.GameStateNavigationCopilot;
import wordproblem.state.CopilotScreenState;
import wordproblem.state.WordProblemGameState;
import wordproblem.summary.scripts.SummaryScript;
import wordproblem.xp.PlayerXpModel;
import wordproblem.WordProblemGameBase;

class WordProblemGameCopilot extends WordProblemGameBase
{
    /**
     * Game specific Copilot Service, for running Copilot related functions and relaying messages.
     */
    private var m_algebraAdventureCopilotService : AlgebraAdventureCopilotService;
    
    // HACK: On authenticate split up code/objects that only need to run once
    // and ones that need to reset
    private var m_setUpClassAlready : Bool = false;
    
    public function new()
    {
        super();
    }
    
    override public function stopCurrentLevel() : Void
    {
        if (isLevelRunning()) 
        {
            m_stateMachine.changeState(CopilotScreenState);
        }
    }
    
    override private function onStartingResourcesLoaded() : Void
    {
        super.onStartingResourcesLoaded();
        
        m_levelManager = new WordProblemCgsLevelManager(
                m_logger.getCgsApi().userManager, 
                m_assetManager, 
                onStartLevel, 
                onNoNextLevel, 
                !m_config.unlockAllLevels, 
                );
        
        // Start up the copilot
        var copilotProps : CgsUserProperties = m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey());
        copilotProps.completeCallback = function userPropsCompleteCallbackForCopilot(userResponse : CgsUserResponse) : Void
                {
                    // Register user
                    if (userResponse.success) 
                    {
                        onUserAuthenticated();
                    }
                };
        m_algebraAdventureCopilotService = new AlgebraAdventureCopilotService(
                m_logger.getCgsApi(), 
                copilotProps, 
                this, m_levelManager, m_logger, 
                );
        
        // Setup Copilot start screen
        var copilotScreenState : CopilotScreenState = new CopilotScreenState(
        m_stateMachine, 
        m_assetManager, 
        );
        m_stateMachine.register(copilotScreenState);
        m_stateMachine.changeState(copilotScreenState);
    }
    
    override private function onUserAuthenticated() : Void
    {
        // HACK: Should not be executing this function multiple times anyways
        // If the level manager already exists then we have already run this function, lets not do it again.
        if (!m_setUpClassAlready) 
        {
            m_playerStatsAndSaveData =new PlayerStatsAndSaveData(null)  // Read in definitions for all items  ;
            
            
            
            var rawItemData : Dynamic = m_assetManager.getObject("items_db");
            var itemDataSource : ItemDataSource = new ItemDataSource(Reflect.field(rawItemData, "items"));
            
            // Read initial items from an xml to be given to a player
            // (mostly for debugging purposes as the reward script can figure out from level progress
            // which rewards were given and at what stage the rewards should be in)
            var playerItemInventory : ItemInventory = new ItemInventory(null, itemDataSource);
            
            // Initialize all the objects related to the game state
            // As it also has a dependency on the fixed set of items belonging to the player,
            // which can only be fetched after some authentication phase.
            var expressionSymbolMap : ExpressionSymbolMap = new ExpressionSymbolMap(m_assetManager);
            var expressionCompiler : IExpressionTreeCompiler = new LatexCompiler(new RealsVectorSpace());
            expressionCompiler.setDynamicVariableInformation(WildCardNode.WILD_CARD_SYMBOLS, WildCardNode.createWildCardNode);
            
            // Game engine is the object that plays and renders the levels
            this.gameEngine = new GameEngine(
                    expressionCompiler, 
                    m_assetManager, 
                    expressionSymbolMap, 
                    width, 
                    height, 
                    m_mouseState, 
                    );
            
            m_scriptParser = new ScriptParser(gameEngine, expressionCompiler, m_assetManager, new PlayerStatsAndSaveData(null));
            m_textParser = new TextParser();
            
            var wordProblemGameState : WordProblemGameState = new WordProblemGameState(
            m_stateMachine, 
            gameEngine, 
            m_assetManager, 
            expressionCompiler, 
            expressionSymbolMap, 
            m_config, 
            m_console, 
            m_playerStatsAndSaveData.buttonColorData.getUpButtonColor(), 
            );
            wordProblemGameState.addEventListener(CommandEvent.WAIT_HIDE, onWaitHide);
            wordProblemGameState.addEventListener(CommandEvent.WAIT_SHOW, onWaitShow);
            m_stateMachine.register(wordProblemGameState);
            
            // Go directly to the copilot wait state
            m_stateMachine.changeState(CopilotScreenState, null);
            
            // Add scripts that have logic that operate across several levels.
            // This deals with things like handing out rewards or modifying rewards
            // We need to make sure the reward script comes before the advance stage otherwise the item won't even exist
            var playerXpModel : PlayerXpModel = new PlayerXpModel(null);
            m_fixedGlobalScript.pushChild(new PerformanceAndStatsScript(gameEngine));
            m_fixedGlobalScript.pushChild(new UpdateAndSaveLevelDataScript(wordProblemGameState, gameEngine, m_levelManager, playerXpModel));
            m_fixedGlobalScript.pushChild(new SummaryScript(
                    wordProblemGameState, 
                    gameEngine, 
                    m_levelManager, 
                    m_assetManager, 
                    playerItemInventory, 
                    itemDataSource, 
                    playerXpModel, 
                    false, 
                    "SummaryScript")
                    );
            m_fixedGlobalScript.pushChild(new GameStateNavigationCopilot(wordProblemGameState, m_stateMachine, m_levelManager));
            m_fixedGlobalScript.pushChild(m_logger);
            m_fixedGlobalScript.pushChild(m_algebraAdventureCopilotService);
            m_setUpClassAlready = true;
            
            // Link logging events to game engine
            m_logger.setGameEngine(this.gameEngine, wordProblemGameState);
        }
    }
    
    override private function onEnterFrame(event : Event) : Void
    {
        if (m_algebraAdventureCopilotService == null || !m_algebraAdventureCopilotService.isPaused) 
        {
            super.onEnterFrame(event);
        }
    }
    
    override private function onNoNextLevel() : Void
    {
        if (m_config.getIsCopilotBuild()) 
        {
            m_stateMachine.changeState(CopilotScreenState);
        }
    }
}
