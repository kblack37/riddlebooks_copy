package wordproblem.achievements.scripts
{
    import cgs.levelProgression.nodes.ICgsLevelNode;
    
    import starling.display.DisplayObjectContainer;
    
    import wordproblem.achievements.AchievementUnlockedAnimation;
    import wordproblem.achievements.PlayerAchievementsModel;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.component.ItemIdComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.items.ItemInventory;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseBufferEventScript;
    import wordproblem.scripts.items.BaseGiveRewardScript;
    import wordproblem.xp.PlayerXpModel;
    
    /**
     * This script is responsible for updating the completion status for all achievements defined in this
     * version of the application.
     */
    public class UpdateAndSaveAchievements extends BaseBufferEventScript
    {
        private var m_gameEngine:IGameEngine;
        private var m_assetManager:AssetManager;
        
        /**
         * Backing data representing all the equations to check
         */
        private var m_achievementsModel:PlayerAchievementsModel;
        
        /**
         * This is a queue of the achievement ids where we should pop up some display
         * saying a new achievement was earned.
         */
        private var m_achievementIdsToShowNotificationsFor:Vector.<String>;
        
        /**
         * If not null, then there is an achievement unlocked animation currently playing
         */
        private var m_currentAchievementUnlockedAnimation:AchievementUnlockedAnimation;
        
        /**
         * Level manager is needed so we can poll data related to the number and types of levels
         * the player has attempted.
         */
        private var m_levelManager:WordProblemCgsLevelManager;
        
        /**
         * XP model used to determine which the level player is at
         */
        private var m_xpModel:PlayerXpModel;
        
        /**
         * The items that the user has collected
         */
        private var m_playerItemInventory:ItemInventory;
        
        /**
         * Container to paste the achievment animation on top of
         */
        private var m_achievementCanvas:DisplayObjectContainer;
        
        private var m_masteryIdToNodeName:Object;
        
        public function UpdateAndSaveAchievements(gameEngine:IGameEngine,
                                                  assetManager:AssetManager,
                                                  achievementsModel:PlayerAchievementsModel,
                                                  levelManager:WordProblemCgsLevelManager,
                                                  xpModel:PlayerXpModel,
                                                  playerItemInventory:ItemInventory,
                                                  masteryIdToNodeName:Object,
                                                  achievementCanvas:DisplayObjectContainer,
                                                  id:String=null, 
                                                  isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_gameEngine = gameEngine;
            m_assetManager = assetManager;
            m_achievementsModel = achievementsModel;
            m_levelManager = levelManager;
            m_xpModel = xpModel;
            m_playerItemInventory = playerItemInventory;
            m_masteryIdToNodeName = masteryIdToNodeName;
            m_achievementCanvas = achievementCanvas;
            m_achievementIdsToShowNotificationsFor = new Vector.<String>();
            
            // A bit of a hack, we assume each portion of the achievement model has a string function name
            // We replace the string value to the actual function object
            var achievementIds:Vector.<String> = m_achievementsModel.getAchievementIds();
            var numAchievements:int = achievementIds.length;
            var i:int;
            for (i = 0; i < numAchievements; i++)
            {
                var achievementData:Object = m_achievementsModel.getAchievementDetailsFromId(achievementIds[i]);
                
                // Public function are properties just like a variable
                var completionFunction:Function = this[achievementData["function"]];
                
                // Replace string name with actual function object
                achievementData["function"] = completionFunction;
                
                // At the very start of the game we do an intial pass through every achievement and see which
                // ones we should mark as complete.
                // However, we do not want to show the notification on the screen
                achievementData.isComplete = completionFunction.apply(null, achievementData.params);
            }
            
            gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, bufferEvent);
        }
        
        override public function visit():int
        {
            iterateThroughBufferedEvents();
            
            // Look through the achievements to be displayed
            if (m_achievementIdsToShowNotificationsFor.length > 0 && m_currentAchievementUnlockedAnimation == null)
            {
                var achievementId:String = m_achievementIdsToShowNotificationsFor.shift();
                var achievementData:Object = m_achievementsModel.getAchievementDetailsFromId(achievementId);
                m_currentAchievementUnlockedAnimation = new AchievementUnlockedAnimation(
                    m_achievementCanvas,
                    400, 80,
                    achievementData,
                    m_assetManager,
                    onAchievementUnlockedComplete
                );
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.LEVEL_SOLVED)
            {
                updateStatusOfAllAchievements();    
            }
            
        }
        
        private function updateStatusOfAllAchievements():void
        {
            var achievementIds:Vector.<String> = m_achievementsModel.getAchievementIds();
            var numAchievements:int = achievementIds.length;
            var i:int;
            for (i = 0; i < numAchievements; i++)
            {
                var achievementData:Object = m_achievementsModel.getAchievementDetailsFromId(achievementIds[i]);
                
                // Use the completion function mapped earlier for all achievements that are not already marked as
                // complete
                if (!achievementData["isComplete"])
                {
                    var completionFunction:Function = achievementData["function"];
                    var params:Array = achievementData["params"];
                    var result:Boolean = completionFunction.apply(this, params);
                    
                    achievementData["isComplete"] = result;
                    
                    // Add this achievement to list 
                    if (result)
                    {
                        m_achievementIdsToShowNotificationsFor.push(achievementData.id);
                    }
                }
            }
        }
        
        private function onAchievementUnlockedComplete():void
        {
            m_currentAchievementUnlockedAnimation.dispose();
            m_currentAchievementUnlockedAnimation = null;
        }
        
        /*
        List of possible helper functions that return true if the achievement condition is satisfied
        */
        
        /**
         * Determine whether the player has completed any n number of levels
         * 
         * @param target
         *      Total number of levels need
         */
        public function nLevelsCompleted(target:int):Boolean
        {
            return m_levelManager.currentLevelProgression.numLevelLeafsCompleted >= target;
        }
        
        /**
         * Determine whether the player has gained enough total xp to reach player level n
         * 
         * @param target
         *      The player level
         */
        public function reachPlayerLevelN(target:int):Boolean
        {
            var totalXpForTarget:uint = m_xpModel.getTotalXpForLevel(target);
            return totalXpForTarget <= m_xpModel.totalXP;
        }
        
        /**
         * Determine whether the player has completed a specific node in the level progression.
         * This is a hack way for a mastery achievement since mastery can be saved as a level pack
         * node being marked as completed.
         */
        public function levelNodeCompleted(name:String):Boolean
        {
            var level:ICgsLevelNode = m_levelManager.getNodeByName(name);
            return (level != null && level.isComplete);
        }
        
        public function allLevelsCompleted():Boolean
        {
            return m_levelManager.numLevelLeafsCompleted == m_levelManager.numTotalLevelLeafs;
        }
        
        public function allCollectablesEarned():Boolean
        {
            var missingCollectable:Boolean = false;
            var requiredRewardIds:Vector.<String> = BaseGiveRewardScript.LEVEL_UP_REWARDS;
            var i:int;
            var numRewardIds:int = requiredRewardIds.length;
            for (i = 0; i < numRewardIds; i++)
            {
                if (m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(requiredRewardIds[i], ItemIdComponent.TYPE_ID) == null)
                {
                    missingCollectable = true;
                    break;
                }
            }
            
            return !missingCollectable;
        }
        
        public function masteryAchieved(masteryId:String):Boolean
        {
            // We can use the completion value of certain nodes to figure out mastery.
            // Since the names of these nodes might change depending on the grade or other
            // settings they cannot be baked in the achievements data file. Instead we can pass in a mapping
            var masteryAchieved:Boolean = false;
            if (m_masteryIdToNodeName != null && m_masteryIdToNodeName.hasOwnProperty(masteryId))
            {
                var nodeName:String = m_masteryIdToNodeName[masteryId];
                masteryAchieved = levelNodeCompleted(nodeName);
            }
            return masteryAchieved;
        }
    }
}