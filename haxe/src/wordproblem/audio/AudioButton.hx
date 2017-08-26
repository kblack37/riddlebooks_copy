package wordproblem.audio;


import openfl.display.Bitmap;
import openfl.events.MouseEvent;
import openfl.net.SharedObject;
import openfl.text.TextFormat;
import wordproblem.display.DisposableSprite;

import openfl.display.BitmapData;
import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;

import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

class AudioButton extends DisposableSprite
{
    public var button(get, never) : LabelButton;

    private var m_mainButton : LabelButton;
    
    private var m_defaultSkinOn : DisplayObject;
    private var m_overSkinOn : DisplayObject;
    
    private var m_defaultSkinOff : DisplayObject;
    private var m_overSkinOff : DisplayObject;
    private var m_localSharedObject : SharedObject;
    
    private var m_onIcon : DisplayObject;
    private var m_offIcon : DisplayObject;
    
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
        
        var onIconBitmapData : BitmapData = assetManager.getBitmapData("correct");
        var iconScaleFactor : Float = height / onIconBitmapData.height * 0.65;
        var onIcon : Bitmap = new Bitmap(onIconBitmapData);
        onIcon.scaleX = onIcon.scaleY = iconScaleFactor;
        m_onIcon = onIcon;
        
        var offIconBitmapData : BitmapData = assetManager.getBitmapData("wrong");
        iconScaleFactor = height / offIconBitmapData.height * 0.65;
        var offIcon : Bitmap = new Bitmap(offIconBitmapData);
        offIcon.scaleX = offIcon.scaleY = iconScaleFactor;
        m_offIcon = offIcon;
        
        m_mainButton.width = width;
        m_mainButton.height = height;
		// TODO: openfl buttons don't have many features; this will need to be fixed
        m_mainButton.label = labelValue;
        //m_mainButton.iconPosition = Button.ICON_POSITION_RIGHT;
        m_mainButton.addEventListener(MouseEvent.CLICK, onClick);
        //m_mainButton.iconOffsetX = onIcon.width * -1;
        
        var preferencesSharedObject : SharedObject = SharedObject.getLocal("preferences");
        m_localSharedObject = preferencesSharedObject;
    }
    
    private function get_button() : LabelButton
    {
        return m_mainButton;
    }
    
    override public function dispose() : Void
    {
		super.dispose();
		
        m_mainButton.removeEventListener(MouseEvent.CLICK, onClick);
    }
    
    private function handleClick() : Void
    {
    }
    
    private function redrawLabel(value : Bool) : Void
    {
        if (value) 
        {
            m_mainButton.upState = m_onIcon;
        }
        else 
        {
            m_mainButton.upState = m_offIcon;
        }
    }
    
    private function onClick(event : Dynamic) : Void
    {
        handleClick();
    }
}
