package wordproblem.creator.scripts;


import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import wordproblem.display.LabelButton;
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

class TestProblemScript extends BaseProblemCreateScript
{
    private var m_mouseState : MouseState;
    private var m_time : Time;
    
    private var m_testProblemButton : LabelButton;
    
    /**
     * Screen for the user to play their just created level.
     */
    private var m_testCreatedLevelScreen : TestCreatedLevelScreen;
    
    public function new(createState : WordProblemCreateState,
            assetManager : AssetManager,
            mouseState : MouseState,
            time : Time,
            levelCompiler : LevelCompiler,
            config : AlgebraAdventureConfig,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            id : String = null,
            isActive : Bool = true)
    {
        super(createState, assetManager, id, isActive);
        
        m_mouseState = mouseState;
        m_time = time;
        
        m_testCreatedLevelScreen = new TestCreatedLevelScreen(assetManager, levelCompiler, config, playerStatsAndSaveData, mouseState);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_isReady) 
        {
            m_testCreatedLevelScreen.removeEventListener(ProblemCreateEvent.TEST_LEVEL_EXIT, bufferEvent);
            m_testProblemButton.removeEventListener(MouseEvent.CLICK, onTestProblemClicked);
            if (value) 
            {
                m_testCreatedLevelScreen.addEventListener(ProblemCreateEvent.TEST_LEVEL_EXIT, bufferEvent);
                m_testProblemButton.addEventListener(MouseEvent.CLICK, onTestProblemClicked);
            }
        }
    }
    
    override public function visit() : Int
    {
        if (m_isReady && m_isActive) 
        {
            super.visit();
            
            if (m_testCreatedLevelScreen.parent != null) 
            {
                m_testCreatedLevelScreen.update(m_time, m_mouseState);
            }
        }
        
        return ScriptStatus.FAIL;
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        // Bind listener to the button
        m_testProblemButton = try cast(m_createState.getWidgetFromId("testProblemButton"), Button) catch(e:Dynamic) null;
        
        setIsActive(m_isActive);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == ProblemCreateEvent.TEST_LEVEL_EXIT) 
        {
            m_testCreatedLevelScreen.stopLevel();
            if (m_testCreatedLevelScreen.parent != null) m_testCreatedLevelScreen.parent.removeChild(m_testCreatedLevelScreen);
            
            var editableTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
            editableTextArea.toggleEditMode(true);
        }
    }
    
    private function onTestProblemClicked() : Void
    {
        // Need to make sure all the restrictions for each value have been met before the problem
        // can be tested.
        // Have some general function that checks for errors for a given
        
        // Need to tell the main application to start the new level
        var editableTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        editableTextArea.toggleEditMode(false);
        editableTextArea.stage.addChild(m_testCreatedLevelScreen);
        
        // Get the parameters for the level
        var createLevelData : ProblemCreateData = m_createState.getCurrentLevel();
        
        var idToAlias : Dynamic = { };
        for (elementId in Reflect.fields(createLevelData.elementIdToDataMap))
        {
            Reflect.setField(idToAlias, elementId, createLevelData.elementIdToDataMap[elementId].value);
        }
        var saveableText : String = WordProblemCreateUtil.createSaveableXMLFromTextfieldText(editableTextArea.getHtmlText(), idToAlias);
        
        // Background id is whatever the currently selected part of the scroller is
        var backgroundPicker : ScrollOptionsPicker = try cast(m_createState.getWidgetFromId("backgroundPicker"), ScrollOptionsPicker) catch(e:Dynamic) null;
        var selectedBackgroundData : Dynamic = backgroundPicker.getCurrentlySelectedOptionData();
        m_testCreatedLevelScreen.startLevel(createLevelData.barModelType, "user_created", saveableText, selectedBackgroundData.text);
    }
}
