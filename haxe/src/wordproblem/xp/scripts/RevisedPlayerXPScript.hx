package wordproblem.xp.scripts;


import cgs.internationalization.StringTable;
import motion.Actuate;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.ui.MouseState;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.DecomposedBarModelData;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.LevelStatistics;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.level.LevelNodeCompletionValues;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseBufferEventScript;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.xp.BrainPoint;

/**
 * This is a revision of how brain points are awarded.
 * Feedback generally indicated a great deal of confusion with the previous system that
 * attempted to reward 'effort' while keeping the conditions opaque.
 * For many it seemed random.
 * 
 * Go for a more straight forward approach here:
 * 
 * The largest share of points will be earned just by solving the problem. Bonus for solving a brand new
 * problem so a player can just replay old ones.
 * 
 * Get points for cumulative active time across all levels.
 * Get points for each action that performs a meaningful change to either the equation or bar model
 */
class RevisedPlayerXPScript extends BaseBufferEventScript
{
    private var m_gameEngine : IGameEngine;
    private var m_assetManager : AssetManager;
    
    private var m_playerActionsEquationModeling : Array<String>;
    private var m_playerActionsBarModeling : Array<String>;
    
    private var m_xpToAwardNextFrame : Int;
    
    /**
     * This is a running count of all actions performed by the player which we interpret as
     * effort. Mostly this is just the number of times they add or change a part in either the
     * bar model or the equation model.
     */
    private var m_uniqueActionCounter : Int;
    private var m_uniqueActionCountThreshold : Int = 2;
    
    private var m_decomposedBarModelHistory : Array<DecomposedBarModelData>;
    private var m_decomposedBarModelMinThreshold : Int = 1;
    private var m_decomposedBarModelMaxThreshold : Int = 12;
    
    private var m_equationModelHistory : Array<ExpressionNode>;
    private var m_equationModelMinThreshold : Int = 1;
    private var m_equationModelMaxThreshold : Int = 12;
    
    private var m_maxNumberOfTermsInTheExpressionForCurrentLevel : Int;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_gameEngine = gameEngine;
        m_assetManager = assetManager;
        
        m_gameEngine.addEventListener(GameEvent.LEVEL_READY, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        
        m_playerActionsEquationModeling = [
                        GameEvent.CHANGED_OPERATOR, 
                        GameEvent.ADD_TERM_ATTEMPTED, 
                        GameEvent.REMOVE_TERM];
        for (actionName in m_playerActionsEquationModeling)
        {
            m_gameEngine.addEventListener(actionName, bufferEvent);
        }
        
        m_playerActionsBarModeling = [
                        AlgebraAdventureLoggingConstants.ADD_NEW_BAR, 
                        AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON, 
                        AlgebraAdventureLoggingConstants.ADD_NEW_BAR_SEGMENT, 
                        AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL, 
                        AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR, 
                        AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL, 
                        AlgebraAdventureLoggingConstants.MULTIPLY_BAR, 
                        AlgebraAdventureLoggingConstants.SPLIT_BAR_SEGMENT, 
                        AlgebraAdventureLoggingConstants.ADD_LABEL_ON_BAR_SEGMENT, 
                        AlgebraAdventureLoggingConstants.REMOVE_BAR_COMPARISON, 
                        AlgebraAdventureLoggingConstants.REMOVE_BAR_SEGMENT, 
                        AlgebraAdventureLoggingConstants.REMOVE_HORIZONTAL_LABEL, 
                        AlgebraAdventureLoggingConstants.REMOVE_VERTICAL_LABEL, 
                        AlgebraAdventureLoggingConstants.RESIZE_HORIZONTAL_LABEL, 
                        AlgebraAdventureLoggingConstants.RESIZE_VERTICAL_LABEL];
        for (actionName in m_playerActionsBarModeling)
        {
            m_gameEngine.addEventListener(actionName, bufferEvent);
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_gameEngine.removeEventListener(GameEvent.LEVEL_READY, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        
        for (actionName in m_playerActionsEquationModeling)
        {
            m_gameEngine.removeEventListener(actionName, bufferEvent);
        }
        
        for (actionName in m_playerActionsBarModeling)
        {
            m_gameEngine.removeEventListener(actionName, bufferEvent);
        }
    }
    
    override public function visit() : Int
    {
        var scriptStatus : Int = super.visit();
        
        if (m_uniqueActionCounter > m_uniqueActionCountThreshold) 
        {
            m_xpToAwardNextFrame += 1;
            m_uniqueActionCounter = 0;
        }
        
        if (m_xpToAwardNextFrame > 0) 
        {
            addXp(m_xpToAwardNextFrame);
            m_xpToAwardNextFrame = 0;
        }
        
        return scriptStatus;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.LEVEL_READY) 
        {
            // TODO: A 'restart' level wipes out all previous effort
            m_xpToAwardNextFrame = 0;
            m_uniqueActionCounter = 0;
            m_maxNumberOfTermsInTheExpressionForCurrentLevel = -1;
            m_decomposedBarModelHistory = new Array<DecomposedBarModelData>();
            m_equationModelHistory = new Array<ExpressionNode>();
        }
        else if (eventType == GameEvent.LEVEL_SOLVED) 
        {
            // More difficult problems should give more points
            // Tutorial levels should ignore the action based brain points
            var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
            var isTutorial : Bool = currentLevel.tags != null && currentLevel.tags.indexOf("tutorial") >= 0;
            
            var difficultyMultiplier : Float = 1.0;
            if (currentLevel.difficulty >= 0) 
            {
                if (currentLevel.difficulty < 1) 
                {
                    difficultyMultiplier = 0.75;
                }
                else if (currentLevel.difficulty < 2) 
                {
                    difficultyMultiplier = 1.0;
                }
                else if (currentLevel.difficulty < 3) 
                {
                    difficultyMultiplier = 1.5;
                }
                else if (currentLevel.difficulty < 4) 
                {
                    difficultyMultiplier = 2.0;
                }
                else 
                {
                    difficultyMultiplier = 3.0;
                }
            } 
			
			// Give bonus points if player has solved a level they did not complete previously  
            if (currentLevel.previousCompletionStatus != LevelNodeCompletionValues.PLAYED_SUCCESS) 
            {
                // Tutorial should give fixed amount that is much less than other problem types
                if (isTutorial) 
                {
                    m_xpToAwardNextFrame = 5;
                }
                else 
                {
                    m_xpToAwardNextFrame = Math.floor(10 * difficultyMultiplier);
                }
            }
            // Replayed a prior completed level, do not give points if tutorial is replayed
            else 
            {
                if (!isTutorial) 
                {
                    m_xpToAwardNextFrame = Math.floor(5 * difficultyMultiplier);
                }
            }
        }
        else if (Lambda.indexOf(m_playerActionsEquationModeling, eventType) >= 0) 
        {
            // Equation modeling does not have the same limits as bar modeling, prevent the case where
            // the user can create different looking expression by just adding a bunch of new nodes to one
            // side. One simple method is to throw out player models where the number of terms far exceeds
            // what would be expected in the solution. Get the reference solution and count the expected terms and
            // use this as a limit
            if (m_maxNumberOfTermsInTheExpressionForCurrentLevel < 0) 
            {
                var validateEquationModel : ModelSpecificEquation = try cast(m_gameEngine.getCurrentLevel().getScriptRoot().getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
                if (validateEquationModel != null) 
                {
                    for (expressionComponent in validateEquationModel.getEquations())
                    {
                        m_maxNumberOfTermsInTheExpressionForCurrentLevel = Std.int(Math.max(ExpressionUtil.nodeCount(expressionComponent.root), m_maxNumberOfTermsInTheExpressionForCurrentLevel));
                    }
                }
            }  
			
			// Check whether the equation created by the user is sufficiently different from previous  
            // ones they had created  
            var expressionSnapshot : ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
            var numNodesInSnapshot : Int = ExpressionUtil.nodeCount(expressionSnapshot);
            if (numNodesInSnapshot <= m_maxNumberOfTermsInTheExpressionForCurrentLevel) 
            {
                var isExpressionDifferentEnough : Bool = true;
                var numExpressions : Int = m_equationModelHistory.length;
                for (i in 0...numExpressions){
                    var expressionInHistory : ExpressionNode = m_equationModelHistory[i];
                    var expressionScore : Int = getExpressionEquivalencyScore(expressionSnapshot, expressionInHistory);
                    if (expressionScore == 0) 
                    {
                        isExpressionDifferentEnough = false;
                        break;
                    }
                }
                
                if (isExpressionDifferentEnough) 
                {
                    m_uniqueActionCounter++;
                    
                    if (m_equationModelHistory.length >= m_equationModelMinThreshold) 
                        { }
                    
                    if (m_equationModelHistory.length >= m_equationModelMaxThreshold) 
                    {
                        m_equationModelHistory.shift();
                    }
                    m_equationModelHistory.push(expressionSnapshot);
                }
            }
        }
        else if (Lambda.indexOf(m_playerActionsBarModeling, eventType) >= 0) 
        {
            var barModelWidget : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
            var currentSnapshot : DecomposedBarModelData = new DecomposedBarModelData(barModelWidget.getBarModelData());
            
            // If history isn't big enough then we will not award points for the latest gesture
            // We still need to check that the snapshot looks different enough
            var i : Int = 0;
            var numSnapshots : Int = m_decomposedBarModelHistory.length;
            var isCurrentDifferentEnough : Bool = true;
            for (i in 0...numSnapshots){
                var previousSnapshot : DecomposedBarModelData = m_decomposedBarModelHistory[i];
                var equivalencyScore : Int = previousSnapshot.getEquivalencyScore(currentSnapshot);
                if (equivalencyScore == 0) 
                {
                    isCurrentDifferentEnough = false;
                    break;
                }
            }
            
            if (isCurrentDifferentEnough) 
            {
                m_uniqueActionCounter++;
                
                // Do not give points if the history is not big enough
                if (m_decomposedBarModelHistory.length >= m_decomposedBarModelMinThreshold) 
                    { }
					
				// If the history is sufficiently large, then award the player xp for trying  
				// a new construct 
                if (m_decomposedBarModelHistory.length >= m_decomposedBarModelMaxThreshold) 
                {
                    m_decomposedBarModelHistory.shift();
                }
				
				// Add new snapshot  
                m_decomposedBarModelHistory.push(currentSnapshot);
            }
        }
        else if (eventType == GameEvent.BAR_MODEL_CORRECT) 
        {
            m_xpToAwardNextFrame += 2;
        }
    }
    
    private function addXp(amountToAdd : Int) : Void
    {
        // Need to increment the amount of xp earned for a level
        // based on when certain triggers fire
        var levelStats : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
        levelStats.xpEarnedForLevel += amountToAdd;
        
        var mouseState : MouseState = m_gameEngine.getMouseState();
		// TODO: uncomment when cgs library is finished
        var brainPointDisplay : BrainPoint = new BrainPoint("+" + amountToAdd + " " + "" /*StringTable.lookup("brain_points")*/, m_assetManager);
        brainPointDisplay.x = mouseState.mousePositionThisFrame.x;
        brainPointDisplay.y = mouseState.mousePositionThisFrame.y - 50;
        m_gameEngine.getSprite().addChild(brainPointDisplay);
		
		Actuate.tween(brainPointDisplay, 1.0, { alpha: 0, y: brainPointDisplay.y - 50 }).delay(1.0).onComplete(function() : Void
                {
					if (brainPointDisplay.parent != null) brainPointDisplay.parent.removeChild(brainPointDisplay);
					brainPointDisplay.dispose();
                });
    }
    
    /**
     *
     * @return
     *      A value of 0 indicates the two expressions at equivalent
     */
    private function getExpressionEquivalencyScore(nodeA : ExpressionNode,
            nodeB : ExpressionNode) : Int
    {
        // If neither is null we can compare the data stored inside the nodes
        var equivalencyScore : Int = 0;
        if (nodeA != null && nodeB != null) 
        {
            // If data is not equal, how 'different' they are can be determined by the
            // types of value.
            if (nodeA.data != nodeB.data) 
            {
                var aIsOperator : Bool = nodeA.isOperator();
                var bIsOperator : Bool = nodeB.isOperator();
                // Both are different operators
                if (aIsOperator && bIsOperator) 
                {
                    equivalencyScore++;
                }
                // Both are different number/variables
                else if (!aIsOperator && !bIsOperator) 
                {
                    equivalencyScore++;
                }
                // One node is operator and the other is a number/variable
                else 
                {
                    equivalencyScore++;
                }
            }
			
			// This is imperfect in that in non-communative operators the order does matter  
			// To check the children    
            var firstComboScore : Int = getExpressionEquivalencyScore(nodeA.left, nodeB.left) +
            getExpressionEquivalencyScore(nodeA.right, nodeB.right);
            
            // Check the other combination only if the first one did not look equal, we are trying
            // to find the minimum score
            if (firstComboScore > 0) 
            {
                var secondComboScore : Int = getExpressionEquivalencyScore(nodeA.left, nodeB.right) +
                getExpressionEquivalencyScore(nodeA.right, nodeB.left);
                equivalencyScore += Std.int(Math.min(firstComboScore, secondComboScore));
            }
        }
        // If one is null and the other is not, we add to the difference
        // The amount may need to be proportional to the number of remaining nodes
        // in the non-null node
        else if ((nodeA != null && nodeB == null) || (nodeA == null && nodeB != null)) 
        {
            var nodeToCount : ExpressionNode = ((nodeA != null)) ? nodeA : nodeB;
            equivalencyScore += ExpressionUtil.nodeCount(nodeToCount);
        }
        
        return equivalencyScore;
    }
}
