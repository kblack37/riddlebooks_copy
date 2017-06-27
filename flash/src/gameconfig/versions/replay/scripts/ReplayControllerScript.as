package gameconfig.versions.replay.scripts
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import cgs.server.logging.actions.QuestAction;
    import cgs.server.logging.data.QuestData;
    import cgs.server.logging.data.QuestStartEndData;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import gameconfig.versions.replay.events.ReplayEvents;
    import gameconfig.versions.replay.ui.ReplayWidget;
    
    import starling.display.DisplayObject;
    import starling.events.Event;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * This script manage the ui related to executing the actions of a replay
     */
    public class ReplayControllerScript extends BaseGameScript
    {
        /**
         * Data used to execute the replay
         */
        private var m_questData:QuestData;
        
        private var m_replayWidget:ReplayWidget;
        private var m_replayWidgetBoundsBuffer:Rectangle;
        private var m_isDraggingWidget:Boolean;
        private var m_mouseBuffer:Point;
        
        private var m_barModelAreaWidget:BarModelAreaWidget;
        
        public function ReplayControllerScript(gameEngine:IGameEngine, 
                                               expressionCompiler:IExpressionTreeCompiler, 
                                               assetManager:AssetManager,
                                               questData:QuestData,
                                               id:String=null, 
                                               isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_questData = questData;
            m_barModelAreaWidget = null;
            m_mouseBuffer = new Point();
            
            // TODO:
            // Some actions may not be useful (for example generic button press, they should be stripped out)
            var actions:Array = m_questData.actions;
            m_replayWidget = new ReplayWidget(assetManager, actions);
            m_replayWidget.addEventListener(ReplayEvents.GO_TO_ACTION_AT_INDEX, onGoToActionAtIndex);
            m_gameEngine.getSprite().stage.addChild(m_replayWidget);
            m_replayWidgetBoundsBuffer = new Rectangle();
            m_isDraggingWidget = false;
            
            // Process the replay data
            var questId:int = m_questData.questId;
            var dqid:String = m_questData.dqid;
            var questStartData:QuestStartEndData = m_questData.startData;
            var questEndData:QuestStartEndData = m_questData.endData;
            
            var numActions:int = actions.length;
            trace("Replaying: qid=" + questId + ", dqid=" + dqid + ", num actions=" + numActions);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Set the bar model area
            var barModelWidgets:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget);
            if (barModelWidgets.length > 0)
            {
                m_barModelAreaWidget = barModelWidgets[0] as BarModelAreaWidget;
            }
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            // Clean up the event listeners
            m_replayWidget.removeEventListener(ReplayEvents.GO_TO_ACTION_AT_INDEX, onGoToActionAtIndex);
            m_replayWidget.removeFromParent(true);
        }
        
        override public function visit():int
        {
            if (m_ready)
            {
                // Allow user to drag the replay controls away
                var mouseState:MouseState = m_gameEngine.getMouseState();
                m_replayWidget.getBounds(m_replayWidget.parent, m_replayWidgetBoundsBuffer);
                if (mouseState.leftMousePressedThisFrame && m_replayWidgetBoundsBuffer.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y))
                {
                    m_isDraggingWidget = true;
                    
                    m_mouseBuffer.x = mouseState.mousePositionThisFrame.x;
                    m_mouseBuffer.y = mouseState.mousePositionThisFrame.y;
                }
                else if (mouseState.leftMouseReleasedThisFrame)
                {
                    m_isDraggingWidget = false;
                }
                
                if (m_isDraggingWidget)
                {
                    if (mouseState.leftMouseDraggedThisFrame)
                    {
                        m_replayWidget.x += mouseState.mousePositionThisFrame.x - m_mouseBuffer.x;
                        m_replayWidget.y += mouseState.mousePositionThisFrame.y - m_mouseBuffer.y;
                    }
                    
                    m_mouseBuffer.x = mouseState.mousePositionThisFrame.x;
                    m_mouseBuffer.y = mouseState.mousePositionThisFrame.y;
                }
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        private function onGoToActionAtIndex(event:Event, params:Object):void
        {
            var actionIndex:int = params.actionIndex;
            showActionAtIndex(actionIndex);
        }
        
        private function showActionAtIndex(actionIndex:int):void
        {
            var actions:Array = m_questData.actions;
            var numActions:int = actions.length;
            
            var action:QuestAction = actions[actionIndex];
            var actionId:int = action.actionId;
            var actionsDetails:Object = action.detailObject;
            
            // The action id tells us what transformation should be applied to the game state
            
            // Details describing the bar model state should modify the bar model area
            var indexContainsBarModel:Boolean = false;
            
            // If an action DOES NOT have a bar model snapshot, we look for the previous snapshot.
            // This is so we can 'undo' changes that did not appear at that index
            var trackerIndex:int = actionIndex;
            while (trackerIndex >= 0 && !indexContainsBarModel)
            {
                var prevActionDetails:Object = actions[trackerIndex].detailObject;
                if (prevActionDetails != null && prevActionDetails.hasOwnProperty("barModel"))
                {
                    indexContainsBarModel = setNewBarModel(prevActionDetails["barModel"]);
                }
                trackerIndex--;
            }
            
            // Clear everything if bar model not set
            if (!indexContainsBarModel)
            {
                m_barModelAreaWidget.getBarModelData().clear();
                m_barModelAreaWidget.redraw(false);
            }
            
            // Details describing the equation should modify the term areas
            var indexContainsEquation:Boolean = false;

            // Like the bar model, the equation needs to track back to a previous snapshot
            trackerIndex = actionIndex;
            while (trackerIndex >= 0 && !indexContainsEquation)
            {
                prevActionDetails = actions[trackerIndex].detailObject;
                if (prevActionDetails != null && prevActionDetails.hasOwnProperty("equation"))
                {
                    indexContainsEquation = true;
                    setNewEquation(prevActionDetails);
                }
                trackerIndex--;
            }
            
            // Clear everything if equation not set
            if (!indexContainsEquation)
            {
                m_gameEngine.setTermAreaContent("leftTermArea", "");
                m_gameEngine.setTermAreaContent("rightTermArea", "");
            }
            
            // Might want some extra information to be displayed about this action
            var descriptionInfo:String = "";
            if (actionId == 1)
            {
                var textPicked:String = actionsDetails.rawText;
                descriptionInfo = "Pick up words in text. " + textPicked;
            }
            else if (actionId == 2)
            {
                textPicked = actionsDetails.rawText;
                descriptionInfo = "Drop words from text. " + textPicked;
            }
            else if (actionId == 3)
            {
                var expressionPicked:String = actionsDetails.expressionName;
                descriptionInfo = "Pickup expression from deck '" + expressionPicked + "'";
            }
            else if (actionId == 4)
            {
                descriptionInfo = "Dropped expression from deck";
            }
            else if (actionId == 5)
            {
                isCorrect = actionsDetails.isCorrect;
                descriptionInfo = "Validate equation, was correct=" + isCorrect;
            }
            else if (actionId == 6)
            {
                descriptionInfo = "Found expression";
            }
            else if (actionId == 7)
            {
                descriptionInfo = "All expressions found";
            }
            else if (actionId == 8)
            {
                descriptionInfo = "Negate expression";
            }
            else if (actionId == 9)
            {
                descriptionInfo = "Equation changed";
            }
            else if (actionId == 10)
            {
                descriptionInfo = "Button pressed";
            }
            else if (actionId == 11)
            {
                descriptionInfo = "Completed level";
            }
            else if (actionId == 12)
            {
                descriptionInfo = "Expression validate clicked";
            }
            else if (actionId == 13)
            {
                descriptionInfo = "Tutorial progress";
            }
            else if (actionId == 14)
            {
                descriptionInfo = "Undo clicked";
            }
            else if (actionId == 15)
            {
                descriptionInfo = "";
            }
            else if (actionId == 16)
            {
                descriptionInfo = "Reset clicked";
            }
            else if (actionId == 17)
            {
                var value:String = actionsDetails.value;
                descriptionInfo = "Add new bar with '" + value + "'";
            }
            else if (actionId == 18)
            {
                value = actionsDetails.value;
                descriptionInfo = "Add new comparison with '" + value + "'";
            }
            else if (actionId == 19)
            {
                value = actionsDetails.value;
                descriptionInfo = "Add new bar segment '" + value + "'";
            }
            else if (actionId == 20)
            {
                value = actionsDetails.value;
                descriptionInfo = "Add horizontal bracket '" + value + "'";
            }
            else if (actionId == 21)
            {
                value = actionsDetails.value;
                descriptionInfo = "Add vertical bracket '" + value + "'";
            }
            else if (actionId == 22)
            {
                value = actionsDetails.value;
                descriptionInfo = "Add unit bar '" + value + "'";
            }
            else if (actionId == 23)
            {
                descriptionInfo = "Remove comparison";
            }
            else if (actionId == 24)
            {
                descriptionInfo = "Remove bar segment";
            }
            else if (actionId == 25)
            {
                descriptionInfo = "Remove horizontal label";
            }
            else if (actionId == 26)
            {
                descriptionInfo = "Remove vertical label";
            }
            else if (actionId == 27)
            {
                descriptionInfo = "Resize comparison";
            }
            else if (actionId == 28)
            {
                descriptionInfo = "Resize horizontal label";
            }
            else if (actionId == 29)
            {
                descriptionInfo = "Resize vertical label";
            }
            else if (actionId == 30)
            {
                value = actionsDetails.value;
                descriptionInfo = "Split bar with '" + value + "'";
            }
            else if (actionId == 31)
            {
                var isCorrect:Boolean = actionsDetails.isCorrect;
                descriptionInfo = "Validate model, was correct=" + isCorrect;
            }
            else if (actionId == 32)
            {
                descriptionInfo = "Undo bar model";
            }
            else if (actionId == 33)
            {
                var hintContent:String = actionsDetails.descriptionContent;
                descriptionInfo = "Hint requested: " + hintContent;
            }
            else
            {
                trace("Unknown aid " + actionId);
            }
            
            m_replayWidget.setActionDescription(descriptionInfo);
        }
        
        private function setNewBarModel(serializedBarModelData:Object):Boolean
        {
            var setNewBarModelSuccess:Boolean = false;
            if (serializedBarModelData.hasOwnProperty("bwl"))
            {
                var barModelData:BarModelData = m_barModelAreaWidget.getBarModelData();
                barModelData.clear();
                barModelData.deserialize(serializedBarModelData);
                
                m_barModelAreaWidget.redraw(false);
                setNewBarModelSuccess = true;
            }
            
            return setNewBarModelSuccess;
        }
        
        private function setNewEquation(serialedEquationData:Object):void
        {
            var equation:String = serialedEquationData["equation"];
            var leftExpression:String = "";
            var rightExpression:String = "";
            if (equation.length > 0)
            {
                var parts:Array = equation.split("=");
                leftExpression = parts[0];
                rightExpression = parts[1];
            }
            m_gameEngine.setTermAreaContent("leftTermArea", leftExpression);
            m_gameEngine.setTermAreaContent("rightTermArea", rightExpression);
        }
    }
}