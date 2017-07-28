package wordproblem.scripts.level.save;


import cgs.levelProgression.nodes.ICgsLevelNode;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.LevelEndTypes;
import wordproblem.engine.level.LevelStatistics;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.event.CommandEvent;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.scripts.BaseBufferEventScript;
import wordproblem.state.WordProblemGameState;

/**
 * This script handles updating and saving contents of a level at a particular instance in time
 */
class UpdateAndSaveLevelDataScript extends BaseBufferEventScript
{
    private var m_gameState : WordProblemGameState;
    private var m_gameEngine : IGameEngine;
    private var m_levelManager : WordProblemCgsLevelManager;
    
    public function new(gameState : WordProblemGameState,
            gameEngine : IGameEngine,
            levelManager : WordProblemCgsLevelManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_gameState = gameState;
        m_gameState.addEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
        m_gameState.addEventListener(CommandEvent.LEVEL_SKIP, bufferEvent);
        
        m_gameEngine = gameEngine;
        m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        
        m_levelManager = levelManager;
    }
    
    override public function dispose() : Void
    {
        m_gameState.removeEventListener(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION, bufferEvent);
        m_gameState.removeEventListener(CommandEvent.LEVEL_SKIP, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        var level : WordProblemLevelData = m_gameEngine.getCurrentLevel();
        var levelStatistics : LevelStatistics = level.statistics;
        var endLevelType : String = null;
        if (eventType == CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION) 
        {
            endLevelType = LevelEndTypes.QUIT_BEFORE_SOLVING;
        }
        else if (eventType == CommandEvent.LEVEL_SKIP) 
        {
            endLevelType = LevelEndTypes.SKIPPED;
        }
        else if (eventType == GameEvent.LEVEL_SOLVED) 
        {
            if (levelStatistics.usedBarModelCheatHint || levelStatistics.usedEquationModelCheatHint) 
            {
                endLevelType = LevelEndTypes.SOLVED_USING_CHEAT;
            }
            else 
            {
                endLevelType = LevelEndTypes.SOLVED_ON_OWN;
            }
        }
        
        if (endLevelType != null) 
        {
            levelStatistics.endType = endLevelType;
            
            // If the played level does not have a node for it
            // (which can happen if it is a user created level loaded later)
            // then finishing the level should just kick the user back to the level select
            var levelName : String = level.getName();
            var levelNode : ICgsLevelNode = m_levelManager.getNodeByName(levelName);
            
            if (levelNode != null) 
            {
                levelStatistics.previousCompletionStatus = Std.int(levelNode.completionValue);
                m_levelManager.endLevel(levelName, levelStatistics);
            }
            else 
            { };
        }
    }
}
