package wordproblem.scripts.performance;


import cgs.levelProgression.nodes.ICgsLevelNode;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.LevelStatistics;
import wordproblem.engine.objectives.BaseObjective;
import wordproblem.level.LevelNodeSaveKeys;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.level.nodes.WordProblemLevelLeaf;
import wordproblem.scripts.BaseBufferEventScript;

/**
 * For the adaptive level progression to function correctly we need to keep track of various
 * actions that the player has performed during the playthrough.
 * 
 * We need to record that information so we can evaluate later whether a player has satisfactorily
 * completed a particular level.
 */
class PerformanceAndStatsScript extends BaseBufferEventScript
{
    private var m_gameEngine : IGameEngine;
    
    /**
     * Keep track of the time since the player first performed some action.
     * (If less than 0, then the start time was never recorded, i.e. the player never performed
     * a relevant action.)
     */
    private var m_levelStartTime : Float;
    
    private var m_wordProblemLevelManager : WordProblemCgsLevelManager;
    
    public function new(gameEngine : IGameEngine,
            wordProblemLevelManager : WordProblemCgsLevelManager = null,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_gameEngine = gameEngine;
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, onBarModelFail);
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_FAIL, onEquationModeledFail);
        m_gameEngine.addEventListener(GameEvent.GET_NEW_HINT, onGetNewHint);
        m_gameEngine.addEventListener(GameEvent.LEVEL_READY, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.PRESS_TEXT_AREA, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.SELECT_DECK_AREA, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, bufferEvent);
        
        m_levelStartTime = 0;
        m_wordProblemLevelManager = wordProblemLevelManager;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.LEVEL_SOLVED) 
        {
            var levelStatistics : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
            
            // Set the time upon completion of a level
            if (m_levelStartTime > 0) 
            {
                levelStatistics.totalMillisecondsPlayed = Date.now().getTime() - m_levelStartTime;
            }
            onLevelSolved(null);
            m_levelStartTime = -1;
        }
        else if (eventType == GameEvent.LEVEL_READY) 
        {
            m_levelStartTime = -1;
        }
        else if (eventType == GameEvent.PRESS_TEXT_AREA || eventType == GameEvent.SELECT_DECK_AREA || eventType == GameEvent.BAR_MODEL_AREA_CHANGE) 
        {
            // We assume that these actions are the very first things that a player can do
            if (m_levelStartTime <= 0) 
            {
                m_levelStartTime = Date.now().getTime();
            }
        }
    }
    
    override public function dispose() : Void
    {
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, onBarModelFail);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_FAIL, onEquationModeledFail);
        m_gameEngine.removeEventListener(GameEvent.GET_NEW_HINT, onGetNewHint);
        m_gameEngine.removeEventListener(GameEvent.LEVEL_READY, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.PRESS_TEXT_AREA, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.SELECT_DECK_AREA, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_AREA_CHANGE, bufferEvent);
    }
    
    private function onBarModelFail(event : Dynamic) : Void
    {
        var levelStatistics : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
        levelStatistics.barModelFails++;
        flushPerformanceStateToNode();
    }
    
    private function onEquationModeledFail(event : Dynamic) : Void
    {
        var levelStatistics : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
        levelStatistics.equationModelFails++;
        flushPerformanceStateToNode();
    }
    
    private function onGetNewHint(event : Dynamic) : Void
    {
        var levelStatistics : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
        levelStatistics.additionalHintsUsed++;
        flushPerformanceStateToNode();
    }
    
    private function onLevelSolved(event : Dynamic) : Void
    {
        // Once a level is 'solved' there is nothing more that a player can do.
        // At this point we can terminate any further recording of the objectives
        // in the level.
        var objectives : Array<BaseObjective> = m_gameEngine.getCurrentLevel().objectives;
        var objective : BaseObjective = null;
        var i : Int = 0;
        var numObjectives : Int = objectives.length;
        for (i in 0...numObjectives){
            objective = objectives[i];
            objective.end(m_gameEngine.getCurrentLevel().statistics);
        }  
		
		// Each objective is responsible for calculating the end grade  
        // We also need to combine all of them for a final level grade.  
        var totalObjectiveGradePointsEarned : Int = 0;
        var totalPossibleGradePoints : Int = 0;
        for (i in 0...numObjectives){
            objective = objectives[i];
            if (objective.useInSummary) 
            {
                totalObjectiveGradePointsEarned += objective.getGrade();
                totalPossibleGradePoints += 100;
            }
        }
		
		// Record the data into the level stats blob  
        var levelStatistics : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
        if (totalPossibleGradePoints > 0) 
        {
            var normalizedLevelGrade : Int = Math.floor(totalObjectiveGradePointsEarned * 100.0 / totalPossibleGradePoints);
            levelStatistics.gradeFromSummaryObjectives = normalizedLevelGrade;
        }
    }
    
    /**
     * While the level is playing we need to sometimes save the performance state
     */
    private function flushPerformanceStateToNode() : Void
    {
        if (m_wordProblemLevelManager != null) 
        {
            var nodeName : String = m_gameEngine.getCurrentLevel().getName();
            var levelNode : ICgsLevelNode = m_wordProblemLevelManager.getNodeByName(nodeName);
            if (levelNode != null && Std.is(levelNode, WordProblemLevelLeaf)) 
            {
                var wordProblemNode : WordProblemLevelLeaf = try cast(levelNode, WordProblemLevelLeaf) catch(e:Dynamic) null;
                if (wordProblemNode.getSavePerformanceStateAcrossInstances()) 
                {
                    var saveData : Dynamic = { };
					Reflect.setField(saveData, LevelNodeSaveKeys.PERFORMANCE_STATE, m_gameEngine.getCurrentLevel().statistics.serialize());
                    wordProblemNode.updateNode(wordProblemNode.nodeLabel, saveData);
                }
            }
        }
    }
}
