package wordproblem.creator.scripts
{
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    import feathers.controls.Button;
    
    import starling.events.Event;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.creator.EditableTextArea;
    import wordproblem.creator.ProblemCreateData;
    import wordproblem.creator.ProblemCreateEvent;
    import wordproblem.creator.ScrollOptionsPicker;
    import wordproblem.creator.TestCreatedLevelScreen;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.creator.WordProblemCreateUtil;
    import wordproblem.engine.level.LevelCompiler;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    
    public class TestProblemScript extends BaseProblemCreateScript
    {
        private var m_mouseState:MouseState;
        private var m_time:Time;
        
        private var m_testProblemButton:Button;
        
        /**
         * Screen for the user to play their just created level.
         */
        private var m_testCreatedLevelScreen:TestCreatedLevelScreen;
        
        public function TestProblemScript(createState:WordProblemCreateState, 
                                          assetManager:AssetManager,
                                          mouseState:MouseState,
                                          time:Time,
                                          levelCompiler:LevelCompiler,
                                          config:AlgebraAdventureConfig,
                                          playerStatsAndSaveData:PlayerStatsAndSaveData,
                                          id:String=null, 
                                          isActive:Boolean=true)
        {
            super(createState, assetManager, id, isActive);
            
            m_mouseState = mouseState;
            m_time = time;
            
            m_testCreatedLevelScreen = new TestCreatedLevelScreen(assetManager, levelCompiler, config, playerStatsAndSaveData, mouseState);
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_isReady)
            {
                m_testCreatedLevelScreen.removeEventListener(ProblemCreateEvent.TEST_LEVEL_EXIT, bufferEvent);
                m_testProblemButton.removeEventListener(Event.TRIGGERED, onTestProblemClicked);
                if (value)
                {
                    m_testCreatedLevelScreen.addEventListener(ProblemCreateEvent.TEST_LEVEL_EXIT, bufferEvent);
                    m_testProblemButton.addEventListener(Event.TRIGGERED, onTestProblemClicked);
                }
            }
        }
        
        override public function visit():int
        {
            if (m_isReady && m_isActive)
            {
                super.visit();
                
                if (m_testCreatedLevelScreen.parent != null)
                {
                    m_testCreatedLevelScreen.update(m_time, m_mouseState)
                }
            }
            
            return ScriptStatus.FAIL;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Bind listener to the button
            m_testProblemButton = m_createState.getWidgetFromId("testProblemButton") as Button;
            
            setIsActive(m_isActive);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == ProblemCreateEvent.TEST_LEVEL_EXIT)
            {
                m_testCreatedLevelScreen.stopLevel();
                m_testCreatedLevelScreen.removeFromParent();
                
                var editableTextArea:EditableTextArea = m_createState.getWidgetFromId("editableTextArea") as EditableTextArea;
                editableTextArea.toggleEditMode(true);
            }
        }
        
        private function onTestProblemClicked():void
        {
            // Need to make sure all the restrictions for each value have been met before the problem
            // can be tested.
            // Have some general function that checks for errors for a given
            
            // Need to tell the main application to start the new level
            var editableTextArea:EditableTextArea = m_createState.getWidgetFromId("editableTextArea") as EditableTextArea;
            editableTextArea.toggleEditMode(false);
            editableTextArea.stage.addChild(m_testCreatedLevelScreen);
            
            // Get the parameters for the level
            var createLevelData:ProblemCreateData = m_createState.getCurrentLevel();
            
            var idToAlias:Object = {};
            for (var elementId:String in createLevelData.elementIdToDataMap)
            {
                idToAlias[elementId] = createLevelData.elementIdToDataMap[elementId].value;
            }
            var saveableText:String = WordProblemCreateUtil.createSaveableXMLFromTextfieldText(editableTextArea.getHtmlText(), idToAlias);
            
            // Background id is whatever the currently selected part of the scroller is
            var backgroundPicker:ScrollOptionsPicker = m_createState.getWidgetFromId("backgroundPicker") as ScrollOptionsPicker;
            var selectedBackgroundData:Object = backgroundPicker.getCurrentlySelectedOptionData();
            m_testCreatedLevelScreen.startLevel(createLevelData.barModelType, "user_created", saveableText, selectedBackgroundData.text);
        }
    }
}