package wordproblem.audio;


import flash.net.SharedObject;
import flash.text.TextFormat;

import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.textures.Texture;

import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

class AudioButton extends Sprite
{
    public var button(get, never) : Button;

    private var m_mainButton : Button;
    
    private var m_defaultSkinOn : DisplayObject;
    private var m_overSkinOn : DisplayObject;
    
    private var m_defaultSkinOff : DisplayObject;
    private var m_overSkinOff : DisplayObject;
    private var m_localSharedObject : SharedObject;
    
    private var m_onIcon : Image;
    private var m_offIcon : Image;
    
    public function new(width : Float,
            height : Float,
            textFormatUp : TextFormat,
            textFormatHover : TextFormat,
            assetManager : AssetManager,
            labelValue : String,
            color : Int)
    {
        super();
        
        m_mainButton = WidgetUtil.createGenericColoredButton(assetManager, color,
                        "", textFormatUp, textFormatHover);
        this.addChild(m_mainButton);
        
        var onIconTexture : Texture = assetManager.getTexture("correct.png");
        var iconScaleFactor : Float = height / onIconTexture.height * 0.65;
        var onIcon : Image = new Image(onIconTexture);
        onIcon.scaleX = onIcon.scaleY = iconScaleFactor;
        m_onIcon = onIcon;
        
        var offIconTexture : Texture = assetManager.getTexture("wrong.png");
        iconScaleFactor = height / offIconTexture.height * 0.65;
        var offIcon : Image = new Image(offIconTexture);
        offIcon.scaleX = offIcon.scaleY = iconScaleFactor;
        m_offIcon = offIcon;
        
        m_mainButton.width = width;
        m_mainButton.height = height;
        m_mainButton.text = labelValue;
		// TODO: this was replaced from the feathers library button and
		// will probably have to be fixed
        //m_mainButton.iconPosition = Button.ICON_POSITION_RIGHT;
        m_mainButton.addEventListener(Event.TRIGGERED, onClick);
        //m_mainButton.iconOffsetX = onIcon.width * -1;
        
        var preferencesSharedObject : SharedObject = SharedObject.getLocal("preferences");
        m_localSharedObject = preferencesSharedObject;
    }
    
    private function get_button() : Button
    {
        return m_mainButton;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_mainButton.removeEventListener(Event.TRIGGERED, onClick);
    }
    
    private function handleClick() : Void
    {
    }
    
    private function redrawLabel(value : Bool) : Void
    {
        if (value) 
        {
            m_mainButton.upState = m_onIcon.texture;
        }
        else 
        {
            m_mainButton.upState = m_offIcon.texture;
        }
    }
    
    private function onClick() : Void
    {
        handleClick();
    }
}
