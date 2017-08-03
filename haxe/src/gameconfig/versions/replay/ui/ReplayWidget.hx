package gameconfig.versions.replay.ui;


import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import feathers.controls.Button;
import feathers.controls.TextInput;
import feathers.controls.text.TextFieldTextEditor;
import feathers.core.ITextEditor;

import gameconfig.versions.replay.events.ReplayEvents;

import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.TextField;

import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

/**
 * Encapsulates all the ui related to controlling a replay
 */
class ReplayWidget extends Sprite
{
    private var m_prevActionButton : Button;
    private var m_nextActionButton : Button;
    
    private var m_goToActionIndexInput : TextInput;
    private var m_goToActionIndexButton : Button;
    
    /**
     * Current action that is being displayed
     */
    private var m_currentQuestActionIndex : Int;
    
    private var m_actions : Array<Dynamic>;
    
    private var m_actionDescription : TextField;
    private var m_actionCounter : TextField;
    
    public function new(assetManager : AssetManager, actions : Array<Dynamic>)
    {
        super();
        
        m_actions = actions;
        
        var totalWidth : Float = 500;
        var totalHeight : Float = 150;
        
        var optionsBackground : Image = new Image(getTexture("summary_background.png"));
        optionsBackground.width = totalWidth;
        optionsBackground.height = totalHeight;
        addChild(optionsBackground);
        
        var color : Int = 0xFF0000;
        m_prevActionButton = WidgetUtil.createGenericColoredButton(
                        assetManager, color, null, null);
        m_prevActionButton.width = 42;
        m_prevActionButton.height = 42;
        m_prevActionButton.label = "PREV";
        m_prevActionButton.addEventListener(Event.TRIGGERED, onPrevActionClicked);
        addChild(m_prevActionButton);
        
        m_actionCounter = new TextField(100, m_prevActionButton.height, "", "Verdana", 12, 0xCCCCCC);
        m_actionCounter.x = m_prevActionButton.x + m_prevActionButton.width;
        addChild(m_actionCounter);
        
        m_nextActionButton = WidgetUtil.createGenericColoredButton(
                        assetManager, color, null, null);
        m_nextActionButton.width = 42;
        m_nextActionButton.height = 42;
        m_nextActionButton.label = "NEXT";
        m_nextActionButton.addEventListener(Event.TRIGGERED, onNextActionClicked);
        m_nextActionButton.x = m_actionCounter.x + m_actionCounter.width;
        addChild(m_nextActionButton);
        
        m_actionDescription = new TextField(totalWidth, totalHeight - m_nextActionButton.height, "", "Verdana", 16, 0xCCCCCC);
        m_actionDescription.y = m_nextActionButton.height;
        m_actionDescription.border = true;
        addChild(m_actionDescription);
        
        var inputWidth : Float = 100;
        var inputHeight : Float = m_nextActionButton.height;
        m_goToActionIndexInput = new TextInput();
        m_goToActionIndexInput.textEditorFactory = function() : ITextEditor
                {
                    var editor : TextFieldTextEditor = new TextFieldTextEditor();
                    editor.textFormat = new TextFormat("Verdana", 14, 0x0, null, null, null, null, null, TextFormatAlign.CENTER);
                    editor.embedFonts = false;
                    return editor;
                };
        m_goToActionIndexInput.backgroundSkin = new Quad(inputWidth, inputHeight, 0xFFFFFF);
        m_goToActionIndexInput.width = inputWidth;
        m_goToActionIndexInput.height = inputHeight;
        m_goToActionIndexInput.x = m_nextActionButton.x + m_nextActionButton.width + 30;
        m_goToActionIndexInput.y = m_nextActionButton.y;
        addChild(m_goToActionIndexInput);
        
        m_goToActionIndexButton = WidgetUtil.createGenericColoredButton(
                        assetManager, color, null, null);
        m_goToActionIndexButton.width = 42;
        m_goToActionIndexButton.height = 42;
        m_goToActionIndexButton.label = "Go To";
        m_goToActionIndexButton.addEventListener(Event.TRIGGERED, onGoToActionClicked);
        m_goToActionIndexButton.x = m_goToActionIndexInput.x + m_goToActionIndexInput.width;
        addChild(m_goToActionIndexButton);
        
        m_currentQuestActionIndex = 0;
        goToActionAtCurrentIndex();
    }
    
    public function setActionDescription(description : String) : Void
    {
        m_actionDescription.text = description;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_prevActionButton.removeEventListener(Event.TRIGGERED, onPrevActionClicked);
        m_nextActionButton.removeEventListener(Event.TRIGGERED, onNextActionClicked);
    }
    
    private function onPrevActionClicked() : Void
    {
        m_currentQuestActionIndex--;
        if (m_currentQuestActionIndex < 0) 
        {
            m_currentQuestActionIndex = 0;
        }
        goToActionAtCurrentIndex();
    }
    
    private function onNextActionClicked() : Void
    {
        m_currentQuestActionIndex++;
        if (m_currentQuestActionIndex >= m_actions.length) 
        {
            m_currentQuestActionIndex = m_actions.length - 1;
        }
        goToActionAtCurrentIndex();
    }
    
    private function onGoToActionClicked() : Void
    {
        var indexToGoTo : Int = parseInt(m_goToActionIndexInput.text);
        if (!Math.isNaN(indexToGoTo)) 
        {
            if (indexToGoTo >= 0 && indexToGoTo < m_actions.length) 
            {
                m_currentQuestActionIndex = indexToGoTo;
                goToActionAtCurrentIndex();
            }
        }
    }
    
    private function goToActionAtCurrentIndex() : Void
    {
        dispatchEventWith(ReplayEvents.GO_TO_ACTION_AT_INDEX, false, {
                    actionIndex : m_currentQuestActionIndex

                });
        m_actionCounter.text = m_currentQuestActionIndex + "/" + (m_actions.length - 1);
    }
}
