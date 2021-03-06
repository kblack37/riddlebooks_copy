package wordproblem.xp.scripts
{
    import cgs.internationalization.StringTable;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.ui.MouseState;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.DecomposedBarModelData;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.level.LevelStatistics;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseBufferEventScript;
    import wordproblem.xp.BrainPoint;
    
    /**
     * This script is the logic for awarding of xp points during the course
     * of the level. (Note that this is created once for the duration of time
     * the application is running)
     */
    public class PlayerXPScript extends BaseBufferEventScript
    {
        /**
         * Number of actions accumulated in the counter before new xp is awarded
         */
        private var m_actionCounterThreshold:int = 10;
        
        /**
         * Have a running count of any gestures the player can perform that would
         * indicate that they are exerting 'effort'
         * 
         * The only actions we care about are the building of the equation and the bar mdoel.
         */
        private var m_actionCounter:int;
        
        /**
         * Number of instances where a player used a dragged expression in a new bar model
         * gesture before new xp is awarded.
         */
        private var m_newGestureForExpressionThreshold:int = 3;
        
        /**
         * Have a running count of the instances where the player has performed a new 
         * bar model action using any dragged expression value.
         */
        private var m_newGestureForExpressionValueCounter:int;
        
        /**
         * One measurement of effort might be seeing if the player using a particular
         * expression value in a 'new way'.
         * 
         * For example using the variable x as a box then as name would qualify as two
         * different usages.
         */
        private var m_expressionValueToGestureMap:Object;
        
        /**
         * Another measure of effort would be attempting to create a bar model that
         * looks sufficiently different from one the player has created before.
         * 
         * Main idea:
         * keep track of the last X unique bar model snap shots the player has created.
         * 
         * Only starts triggering pointing if the player has populated the history with some
         * minimal number of snapshots (this is to prevent giving points for early actions which
         * would always be different from the empty screen) and only add new snapshots if it is
         * sufficiently different from every model in this list.
         */
        private var m_decomposeBarModelHistory:Vector.<DecomposedBarModelData>;
        
        /**
         * Distinct snapshots should automatically get added to the history without triggering
         * brain points until the length of the history passes this threshold.
         */
        private var m_decomposeBarModelMinThreshold:int = 3;
        
        /**
         * The number of distinct snapshots in the history should not exceed this value,
         * to prevent degenerate case where it would take too long to compare the new snapshot
         * with previous entries.
         */
        private var m_decomposeBarModelMaxThreshold:int = 12;
        
        /**
         * Similar to the bar model history, we keep track of the history of expression snapshots.
         * The idea is that any built expression that is 'different' enough from previous
         * constructs should award the player with points.
         */
        private var m_builtExpressionHistory:Vector.<ExpressionNode>;
        
        /**
         * Distinct expression snapshots should automatically get added to the history without
         * triggering brain points until the length of the history passes this threshold.
         */
        private var m_builtExpressionMinThreshold:int = 2;
        
        /**
         * The number of distinct expression in the history should not exceed this value.
         */
        private var m_builtExpressionMaxThreshold:int = 8;
        
        /**
         * We keep a recent history of the last N actions taken by the player.
         * Actions have a type and extra data.
         * 
         * The reason for this is that it is possible that the player repeat some actions over and over
         * again (like clicking to change the operator in the equation or stacking new boxes) that would
         * increment the various counters but are not good indicators for productive effort.
         */
        private var m_actionHistory:Vector.<Object>;
        
        /**
         * During any given frame several triggers might be fired on the same frame.
         * We buffer the total that should have been given.
         */
        private var m_xpToGiveOnFrame:int;
        
        /**
         * List of all events related to adding new components to the bar model
         */
        private var m_barModelAddGestures:Vector.<String>;
        
        /**
         * List of all events related to modifying/removing existing components of the model
         */
        private var m_barModelModifyExistingGestures:Vector.<String>;
        
        private var m_gameEngine:IGameEngine;
        
        /**
         * Used to fetch the  textures to draw all the brain points related graphics.
         */
        private var m_assetManager:AssetManager;
        
        /**
         * Has the player created a different enough bar model
         */
        private var m_rewardForDifferentBarModelTriggered:Boolean;
        
        /**
         * Has the player created a different enough equation
         */
        private var m_rewardForDifferentEquationTriggered:Boolean;
        
        public function PlayerXPScript(gameEngine:IGameEngine,
                                       assetManager:AssetManager, 
                                       id:String=null, 
                                       isActive:Boolean=true)
        {
            super(id, isActive);
            m_gameEngine = gameEngine;
            m_assetManager = assetManager;
            m_decomposeBarModelHistory = new Vector.<DecomposedBarModelData>();
            m_builtExpressionHistory = new Vector.<ExpressionNode>();
            m_actionHistory = new Vector.<Object>();
            
            m_gameEngine.addEventListener(GameEvent.LEVEL_READY, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.ADD_NEW_BAR_MODEL, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.ADD_NEW_EQUATION, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.ADD_TERM_ATTEMPTED, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.CHANGED_OPERATOR, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.REMOVE_TERM, bufferEvent);
            
            // For now we are piggy-backing off logging events to get at the bar model gestures
            m_barModelAddGestures = Vector.<String>([
                AlgebraAdventureLoggingConstants.ADD_NEW_BAR,
                AlgebraAdventureLoggingConstants.ADD_NEW_BAR_COMPARISON,
                AlgebraAdventureLoggingConstants.ADD_NEW_BAR_SEGMENT,
                AlgebraAdventureLoggingConstants.ADD_NEW_HORIZONTAL_LABEL,
                AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR,
                AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL
            ]);
            for each (var addGestureName:String in m_barModelAddGestures)
            {
                m_gameEngine.addEventListener(addGestureName, bufferEvent);
            }
            
            m_barModelModifyExistingGestures = Vector.<String>([
                AlgebraAdventureLoggingConstants.REMOVE_BAR_COMPARISON,
                AlgebraAdventureLoggingConstants.REMOVE_BAR_SEGMENT,
                AlgebraAdventureLoggingConstants.REMOVE_HORIZONTAL_LABEL,
                AlgebraAdventureLoggingConstants.REMOVE_VERTICAL_LABEL,
                AlgebraAdventureLoggingConstants.RESIZE_BAR_COMPARISON,
                AlgebraAdventureLoggingConstants.RESIZE_HORIZONTAL_LABEL,
                AlgebraAdventureLoggingConstants.RESIZE_VERTICAL_LABEL
            ]);
            for each (var modifyGestureName:String in m_barModelModifyExistingGestures)
            {
                m_gameEngine.addEventListener(modifyGestureName, bufferEvent);
            }
        }
        
        override public function dispose():void
        {
            m_gameEngine.removeEventListener(GameEvent.LEVEL_READY, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.ADD_NEW_BAR_MODEL, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.ADD_NEW_EQUATION, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.ADD_TERM_ATTEMPTED, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.CHANGED_OPERATOR, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.REMOVE_TERM, bufferEvent);
            
            for each (var addGestureName:String in m_barModelAddGestures)
            {
                m_gameEngine.removeEventListener(addGestureName, bufferEvent);
            }
            
            for each (var modifyGestureName:String in m_barModelModifyExistingGestures)
            {
                m_gameEngine.removeEventListener(modifyGestureName, bufferEvent);
            }
        }
        
        override public function visit():int
        {
            var scriptStatus:int = super.visit();
            
            // Some combination of triggers need to fire simultaneously before points are awarded
            // On each frame see which conditions have been locked in.
            // If two are checked off, reset all counters
            // Amount of points depends on what triggers matched
            var numTriggersActivated:int = 0;
            var totalXpFromTriggers:int = 0;
            if (m_rewardForDifferentBarModelTriggered)
            {
                numTriggersActivated++;
                totalXpFromTriggers += 5;
            }
            
            if (m_rewardForDifferentEquationTriggered)
            {
                numTriggersActivated++;
                totalXpFromTriggers += 5;
            }
            
            // Reward points for just doing any action
            if (m_actionCounter >= m_actionCounterThreshold)
            {
                numTriggersActivated++;
                totalXpFromTriggers += 1;
            }
            
            // Reward points for trying different gestures with the actions
            if (m_newGestureForExpressionValueCounter >= m_newGestureForExpressionThreshold)
            {
                numTriggersActivated++;
                totalXpFromTriggers += 3;
            }
            
            // Reset ALL triggers
            if (numTriggersActivated > 1)
            {
                m_rewardForDifferentBarModelTriggered = false;
                m_rewardForDifferentEquationTriggered = false;
                m_actionCounter = 0;
                m_newGestureForExpressionValueCounter = 0;
                m_xpToGiveOnFrame = totalXpFromTriggers;
            }
            
            // After processing all buffered events, we can now appropriately add the xp all at once
            // on this frame.
            if (m_xpToGiveOnFrame > 0)
            {
                addXp(m_xpToGiveOnFrame);
                m_xpToGiveOnFrame = 0;
            }
            
            return scriptStatus;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            // At the start of a new level reset all important parameters
            if (eventType == GameEvent.LEVEL_READY)
            {
                // Reset all the temporary variables for the start of a new level
                m_actionCounter = 0;
                m_newGestureForExpressionValueCounter = 0;
                m_expressionValueToGestureMap = {};
                m_xpToGiveOnFrame = 0;
                m_decomposeBarModelHistory.length = 0;
                m_builtExpressionHistory.length = 0;
                m_actionHistory.length = 0;
            }
            else if (eventType == GameEvent.ADD_NEW_BAR_MODEL)
            {
                
            }
            else if (eventType == GameEvent.ADD_NEW_EQUATION)
            {
                
            }
            else if (eventType == GameEvent.ADD_TERM_ATTEMPTED || eventType == GameEvent.CHANGED_OPERATOR || eventType == GameEvent.REMOVE_TERM)
            {
                m_actionCounter++;
                
                // Create a snapshot of the expression that was created
                var expressionSnapshot:ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
                var isExpressionDifferentEnough:Boolean = true;
                
                var numExpressions:int = m_builtExpressionHistory.length;
                for (i = 0; i < numExpressions; i++)
                {
                    var expressionInHistory:ExpressionNode = m_builtExpressionHistory[i];
                    var expressionScore:int = getExpressionEquivalencyScore(expressionSnapshot, expressionInHistory);
                    if (expressionScore <= 2)
                    {
                        isExpressionDifferentEnough = false;
                        break;
                    }
                }
                
                if (isExpressionDifferentEnough)
                {
                    if (m_builtExpressionHistory.length >= m_builtExpressionMinThreshold)
                    {
                        m_rewardForDifferentEquationTriggered = true;
                    }
                    
                    if (m_builtExpressionHistory.length >= m_builtExpressionMaxThreshold)
                    {
                        m_builtExpressionHistory.pop();
                    }
                    m_builtExpressionHistory.push(expressionSnapshot);
                }
            }
            
            var playerExplicitlyAlteredModel:Boolean = false;
            
            // Detect an add type event in the bar model
            var expressionValueForGesture:String = null;
            var newGestureForExpression:Boolean = true;
            if (m_barModelAddGestures.indexOf(eventType) > -1)
            {
                playerExplicitlyAlteredModel = true;
                m_actionCounter++;
                
                // For each add gesture, we check the value that was used.
                // Find in the map whether that value was used in that same way at some point earlier
                // in the level
                if (param.hasOwnProperty("value"))
                {
                    expressionValueForGesture = param.value;
                }
            }
            // Detect an add type event in the equation model
            else if (eventType == GameEvent.ADD_TERM_ATTEMPTED)
            {
                if (param.success && param.widget != null)
                {
                    expressionValueForGesture = (param.widget as BaseTermWidget).getNode().data;
                }
            }
            else if (eventType == GameEvent.REMOVE_TERM)
            {
                if (param.widget != null)
                {
                    expressionValueForGesture = (param.widget as BaseTermWidget).getNode().data;
                }
            }
            
            // Append gesture for the expression,
            if (expressionValueForGesture != null)
            {
                if (m_expressionValueToGestureMap.hasOwnProperty(expressionValueForGesture))
                {
                    var barModelGesturesForValue:Vector.<String> = m_expressionValueToGestureMap[expressionValueForGesture];
                    if (barModelGesturesForValue.indexOf(eventType) > -1)
                    {
                        newGestureForExpression = false;
                    }
                    else
                    {
                        barModelGesturesForValue.push(eventType);
                    }
                }
                else
                {
                    m_expressionValueToGestureMap[expressionValueForGesture] = Vector.<String>([eventType]);
                }
                
                // Increase counter once new gesture is detected for that expression value
                if (newGestureForExpression)
                {
                    m_newGestureForExpressionValueCounter++;
                }
            }
            
            if (m_barModelModifyExistingGestures.indexOf(eventType) > -1)
            {
                playerExplicitlyAlteredModel = true;
                m_actionCounter++;
            }
            
            // If the event involved the player performing a gesture to alter the model,
            // we need to look at a snapshot of the model and check if the construct is different
            // from previous model snapshots
            if (playerExplicitlyAlteredModel)
            {
                var barModelWidget:BarModelAreaWidget = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
                var currentSnapshot:DecomposedBarModelData = new DecomposedBarModelData(barModelWidget.getBarModelData());
                
                // If history isn't big enough then we will not award points for the latest gesture
                // We still need to check that the snapshot looks different enough
                var i:int;
                var numSnapshots:int = m_decomposeBarModelHistory.length;
                var isCurrentDifferentEnough:Boolean = true;
                for (i = 0; i < numSnapshots; i++)
                {
                    var previousSnapshot:DecomposedBarModelData = m_decomposeBarModelHistory[i];
                    var equivalencyScore:int = previousSnapshot.getEquivalencyScore(currentSnapshot);
                    if (equivalencyScore <= 3)
                    {
                        isCurrentDifferentEnough = false;
                        break;
                    }
                }
                
                if (isCurrentDifferentEnough)
                {
                    // Do not give points if the history is not big enough
                    if (m_decomposeBarModelHistory.length >= m_decomposeBarModelMinThreshold)
                    {
                        m_rewardForDifferentBarModelTriggered = true;
                    }
                    
                    // If the history is sufficiently large, then award the player xp for trying
                    // a new construct
                    if (m_decomposeBarModelHistory.length >= m_decomposeBarModelMaxThreshold)
                    {
                        m_decomposeBarModelHistory.pop();
                    }
                    
                    // Add new snapshot
                    m_decomposeBarModelHistory.push(currentSnapshot);
                }
            }
        }
        
        /**
         *
         * @return
         *      A value of 0 indicates the two expressions
         */
        private function getExpressionEquivalencyScore(nodeA:ExpressionNode, 
                                                       nodeB:ExpressionNode):int
        {
            // If neither is null we can compare the data stored inside the nodes
            var equivalencyScore:int = 0;
            if (nodeA != null && nodeB != null)
            {
                // If data is not equal, how 'different' they are can be determined by the
                // types of value.
                if (nodeA.data != nodeB.data)
                {
                    var aIsOperator:Boolean = nodeA.isOperator();
                    var bIsOperator:Boolean = nodeB.isOperator();
                    // Both are different operators
                    if (aIsOperator && bIsOperator)
                    {
                        equivalencyScore += 2;
                    }
                    // Both are different number/variables
                    else if (!aIsOperator && !bIsOperator)
                    {
                        equivalencyScore += 2;
                    }
                    // One node is operator and the other is a number/variable
                    else
                    {
                        equivalencyScore += 5;   
                    }
                }
                
                // This is imperfect in that in non-communative operators the order does matter
                // To check the children
                var firstComboScore:int = getExpressionEquivalencyScore(nodeA.left, nodeB.left) + 
                    getExpressionEquivalencyScore(nodeA.right, nodeB.right);
                
                // Check the other combo only if the first combo isn't equal already
                if (firstComboScore > 0)
                {
                    var secondComboScore:int = getExpressionEquivalencyScore(nodeA.left, nodeB.right) +
                        getExpressionEquivalencyScore(nodeA.right, nodeB.left);
                    equivalencyScore += Math.min(firstComboScore, secondComboScore);
                }
            }
            // If one is null and the other is not, we add to the difference
            // The amount may need to be proportional to the number of remaining nodes
            // in the non-null node
            else if ((nodeA != null && nodeB == null) || (nodeA == null && nodeB != null))
            {
                var nodeToCount:ExpressionNode = (nodeA != null) ? nodeA : nodeB;
                equivalencyScore += ExpressionUtil.nodeCount(nodeToCount);
            }
            
            return equivalencyScore;
        }
        
        private function addXp(amountToAdd:uint):void
        {
            // Need to increment the amount of xp earned for a level
            // based on when certain triggers fire
            var levelStats:LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
            levelStats.xpEarnedForLevel += amountToAdd;
            
            var mouseState:MouseState = m_gameEngine.getMouseState();
            var brainPointDisplay:BrainPoint = new BrainPoint("+" + amountToAdd + " " + StringTable.lookup("brain_points"), m_assetManager);
            brainPointDisplay.x = mouseState.mousePositionThisFrame.x;
            brainPointDisplay.y = mouseState.mousePositionThisFrame.y - 50;
            m_gameEngine.getSprite().addChild(brainPointDisplay);
            
            var fadeUpAndOut:Tween = new Tween(brainPointDisplay, 1.0);
            fadeUpAndOut.animate("alpha", 0.0);
            fadeUpAndOut.animate("y", brainPointDisplay.y - 50);
            fadeUpAndOut.delay = 1.0;
            fadeUpAndOut.onComplete = function():void
            {
                brainPointDisplay.removeFromParent(true);
                Starling.juggler.remove(fadeUpAndOut);
            };
            Starling.juggler.add(fadeUpAndOut);
        }
    }
}