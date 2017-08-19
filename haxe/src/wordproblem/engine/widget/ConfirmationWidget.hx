package wordproblem.engine.widget;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextFormat;

import cgs.audio.Audio;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;

import wordproblem.display.Layer;
import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * A dialog that pops up asking the player do confirm a selection.
 * 
 * This is used for any action that may drastically alter the game state or data,
 * like signing out or resetting the save data.
 * 
 * HACK: Remade so that it can double as a notification that just says something like OK
 */
class ConfirmationWidget extends Layer
{
    private var m_confirmButton : LabelButton;
    private var m_confirmCallback : Function;
    private var m_declineButton : LabelButton;
    private var m_declineCallback : Function;
    
    /**
     *
     * @param customMessageFactory
     *      If not null, this function should return a DisplayObject for a custom
     *      visualization to be pasted in the confirmation.
     * @param isNotification
     *      If true, this ui only shows the confirm button so it acts more as a notification
     *      than a confirmation
     */
    public function new(width : Float,
            height : Float,
            customMessageFactory : Function,
            confirmCallback : Function,
            declineCallback : Function,
            assetManager : AssetManager,
            buttonColor : Int,
            confirmText : String,
            declineText : String,
            isNotification : Bool = false)
    {
        super();
        
        var blockingQuad : Bitmap = new Bitmap(new BitmapData(Std.int(width), Std.int(height), false, 0x000000));
        blockingQuad.alpha = 0.7;
        addChild(blockingQuad);
        
        var backgroundContainer : Sprite = new Sprite();
        addChild(backgroundContainer);
        
        var bitmapData : BitmapData = assetManager.getBitmapData("summary_background");
        var background : Bitmap = new Bitmap(bitmapData);
        var backgroundWidth : Float = width * 0.5;
        var backgroundHeight : Float = height * 0.5;
        background.width = backgroundWidth;
        background.height = backgroundHeight;
        backgroundContainer.addChild(background);
        backgroundContainer.x = (width - backgroundWidth) * 0.5;
        backgroundContainer.y = (height - backgroundHeight) * 0.5;
        
        var contentDisplay : DisplayObject = customMessageFactory();
        contentDisplay.x = (background.width - contentDisplay.width) * 0.5;
        contentDisplay.y = (background.height - contentDisplay.height) * 0.5;
        backgroundContainer.addChild(contentDisplay);
        
        var buttonWidth : Float = 150;
        var buttonHeight : Float = 60;
        var combinedButtonWidth : Float = ((isNotification)) ? buttonWidth : buttonWidth * 2 + 30;
        m_confirmButton = WidgetUtil.createGenericColoredButton(
                        assetManager,
                        buttonColor,
                        confirmText,
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 26, 0xFFFFFF),
                        null
                        );
        m_confirmButton.width = buttonWidth;
        m_confirmButton.height = buttonHeight;
        m_confirmButton.x = (backgroundWidth - combinedButtonWidth) * 0.5;
        m_confirmButton.y = backgroundHeight - buttonHeight - 10;
        backgroundContainer.addChild(m_confirmButton);
        m_confirmCallback = confirmCallback;
        m_confirmButton.addEventListener(MouseEvent.CLICK, onConfirmClick);
        
        if (!isNotification) 
        {
            m_declineButton = WidgetUtil.createGenericColoredButton(
                            assetManager,
                            buttonColor,
                            declineText,
                            new TextFormat(GameFonts.DEFAULT_FONT_NAME, 26, 0xFFFFFF),
                            null
                            );
            m_declineButton.width = buttonWidth;
            m_declineButton.height = buttonHeight;
            m_declineButton.x = m_confirmButton.x + combinedButtonWidth - buttonWidth;
            m_declineButton.y = m_confirmButton.y;
            backgroundContainer.addChild(m_declineButton);
            m_declineCallback = declineCallback;
            m_declineButton.addEventListener(MouseEvent.CLICK, onDeclineClick);
        }
    }
    
    private function onConfirmClick(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        if (m_confirmCallback != null) 
        {
            m_confirmCallback();
        }
    }
    
    private function onDeclineClick(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        if (m_declineCallback != null) 
        {
            m_declineCallback();
        }
    }
}
