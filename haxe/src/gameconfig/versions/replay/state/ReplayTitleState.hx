package gameconfig.versions.replay.state;


import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;

import feathers.controls.Button;
import feathers.controls.TextInput;
import feathers.controls.text.TextFieldTextEditor;
import feathers.core.ITextEditor;

import gameconfig.versions.replay.events.ReplayEvents;

import starling.display.Image;
import starling.display.Quad;
import starling.events.Event;

import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

class ReplayTitleState extends BaseState
{
    private var m_assetManager : AssetManager;
    private var m_dqidInput : TextInput;
    
    public function new(stateMachine : IStateMachine,
            assetManager : AssetManager)
    {
        super(stateMachine);
        
        m_assetManager = assetManager;
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        addChild(new Image(m_assetManager.getTexture("login_background")));
        
        var screenWidth : Float = 800;
        
        /*
        Add ui elements to allow entering specific dqids or getting a list of dqids for a
        particular user.
        */
        var inputWidth : Float = 300;
        var inputHeight : Float = 50;
        var dqidInput : TextInput = new TextInput();
        dqidInput.textEditorFactory = function() : ITextEditor
                {
                    var editor : TextFieldTextEditor = new TextFieldTextEditor();
                    editor.textFormat = new TextFormat("Verdana", 14, 0x0, null, null, null, null, null, TextFormatAlign.CENTER);
                    editor.embedFonts = false;
                    return editor;
                };
        dqidInput.backgroundSkin = new Quad(inputWidth, inputHeight, 0xFFFFFF);
        dqidInput.width = inputWidth;
        dqidInput.height = inputHeight;
        dqidInput.x = (screenWidth - dqidInput.width) * 0.5;
        dqidInput.y = 200;
        addChild(dqidInput);
        m_dqidInput = dqidInput;
        
        var submitDqidButton : Button = WidgetUtil.createGenericColoredButton(
                m_assetManager, 0xCCCCCC, null, null);
        submitDqidButton.width = 120;
        submitDqidButton.height = 42;
        submitDqidButton.label = "Submit DQID";
        submitDqidButton.addEventListener(Event.TRIGGERED, onSubmitDqidClicked);
        submitDqidButton.x = dqidInput.x + (dqidInput.width - submitDqidButton.width) * 0.5;
        submitDqidButton.y = dqidInput.y + dqidInput.height;
        addChild(submitDqidButton);
    }
    
    private function onSubmitDqidClicked() : Void
    {
        var dqid : String = m_dqidInput.text;
        dispatchEventWith(ReplayEvents.GO_TO_REPLAY_FOR_DQID, false, {
                    dqid : dqid

                });
    }
}
